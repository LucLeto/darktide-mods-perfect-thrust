local mod = get_mod("PerfectThrust")
local BuffSettings = require("scripts/settings/buff/buff_settings")
local BuffTemplates = require("scripts/settings/buff/buff_templates")

local math_abs = math.abs
local math_ceil = math.ceil
local math_floor = math.floor
local math_huge = math.huge
local string_format = string.format
local string_gsub = string.gsub
local table_concat = table.concat
local table_clear = table.clear
    or function (t)
        for k in pairs(t) do
            t[k] = nil
        end
    end
local type = type

local ON_WINDUP_TRIGGER = BuffSettings.proc_events.on_windup_trigger
-- Same fallback ActionWindup / ActionBlockWindup use when an action sets no proc_time_interval.
local PROC_INTERVAL_DEFAULT = 0.25
local MAX_EFFECTS = 4
local NEARLY_FULL = 0.999
local TIMING_MODE_CONFIRMED = "confirmed"
local DEBUG_PREFIX = "[Perfect Thrust] "

local Tracker = {}

-- Template name -> descriptor, or false when the template does not build stacks while charging.
local descriptor_cache = {}
local effects = {}
local debug_parts = {}

for i = 1, MAX_EFFECTS do
    effects[i] = {
        child_name = nil,
        offset = 0,
        cap = 1,
        needed = 1,
        predictable = false,
        observed = 0,
        start_observed = 0,
        armed = false,
        confirmed = false
    }
end

local state = {
    active = false,
    action = nil,
    unit = nil,
    action_name = nil,
    start_t = 0,
    first_trigger_t = 0,
    interval = PROC_INTERVAL_DEFAULT,
    triggers = 0,
    time_in_action = 0,
    buff_extension = nil,
    weapon_action_component = nil,
    effect_count = 0,
    fill = 0,
    ready = false
}

local function _resolve_descriptor(template)
    local proc_events = template.proc_events
    local proc_chance = proc_events and proc_events[ON_WINDUP_TRIGGER]

    if not proc_chance then
        return false
    end

    local child_name = template.child_buff_template
    local per_trigger
    local uses_parent_override = false

    if child_name then
        -- Parent proc buffs (blessings, weapon windup keywords) add child stacks per windup trigger.
        local add_child_proc_events = template.add_child_proc_events

        per_trigger = add_child_proc_events and add_child_proc_events[ON_WINDUP_TRIGGER]
        uses_parent_override = true
    else
        -- Proc buffs that add their child from a proc function (e.g. the Ogryn Thrust talent)
        -- follow the *_parent / *_child naming convention.
        local name = template.name
        local candidate = name and (string_gsub(name, "_parent$", "_child"))

        if candidate and candidate ~= name and BuffTemplates[candidate] then
            child_name = candidate
            per_trigger = 1
        end
    end

    local child_template = child_name and BuffTemplates[child_name]
    local cap = child_template and child_template.max_stacks

    if type(per_trigger) ~= "number" or per_trigger < 1 or type(cap) ~= "number" or cap < 1 then
        return false
    end

    return {
        child_name = child_name,
        offset = math_abs(child_template.stack_offset or 0),
        cap = cap,
        per_trigger = per_trigger,
        uses_parent_override = uses_parent_override,
        predictable = type(proc_chance) == "number" and proc_chance >= 1 and not template.cooldown_duration
    }
end

local function _descriptor(template)
    local name = template.name

    if not name then
        return false
    end

    local descriptor = descriptor_cache[name]

    if descriptor == nil then
        descriptor = _resolve_descriptor(template)
        descriptor_cache[name] = descriptor
    end

    return descriptor
end

local function _has_effect(count, child_name)
    for i = 1, count do
        if effects[i].child_name == child_name then
            return true
        end
    end

    return false
end

local function _observed_stacks(buff_extension, effect)
    local observed = buff_extension:current_stacks(effect.child_name) - effect.offset

    return observed > 0 and observed or 0
end

local function _reset_state()
    state.active = false
    state.action = nil
    state.unit = nil
    state.action_name = nil
    state.buff_extension = nil
    state.weapon_action_component = nil
    state.effect_count = 0
    state.triggers = 0
    state.time_in_action = 0
    state.fill = 0
    state.ready = false
end

local function _debug_effects()
    table_clear(debug_parts)

    for i = 1, state.effect_count do
        local effect = effects[i]

        debug_parts[i] = string_format("%s %d/%d", effect.child_name, effect.observed, effect.cap)
    end

    return table_concat(debug_parts, ", ")
end

local function _debug_finish(reason)
    if not mod._settings.debug_logging then
        return
    end

    mod:echo(DEBUG_PREFIX .. "end (%s) after %.2fs, %d triggers, ready=%s: %s", tostring(reason), state.time_in_action, state.triggers, tostring(state.ready), _debug_effects())
end

Tracker.on_windup_start = function (action, t)
    if not action._is_local_unit or not action._is_human_controlled then
        return
    end

    if state.active then
        _debug_finish("restarted")
        _reset_state()
    end

    local first_trigger_t = action._proc_trigger_time

    if not first_trigger_t or first_trigger_t == math_huge then
        return
    end

    local buff_extension = action._buff_extension
    local weapon_action_component = action._weapon_action_component
    local inventory_component = action._inventory_component
    local buffs = buff_extension and buff_extension.buffs and buff_extension:buffs()

    if not buffs or not weapon_action_component or not inventory_component then
        return
    end

    local wielded_slot = inventory_component.wielded_slot
    local count = 0

    for i = 1, #buffs do
        local buff_instance = buffs[i]
        local template = buff_instance:template()
        local descriptor = template and _descriptor(template)

        if descriptor then
            local item_slot_name = buff_instance:item_slot_name()
            local child_name = descriptor.child_name

            if (item_slot_name == nil or item_slot_name == wielded_slot) and not _has_effect(count, child_name) then
                local cap = descriptor.cap

                if descriptor.uses_parent_override then
                    -- Mirrors WeaponTraitParentProcBuff: an instance override of max_stacks caps the children.
                    local override_data = buff_instance._template_override_data
                    local override_max_stacks = type(override_data) == "table" and override_data.max_stacks

                    if type(override_max_stacks) == "number" and override_max_stacks >= 1 then
                        cap = override_max_stacks
                    end
                end

                count = count + 1

                local effect = effects[count]

                effect.child_name = child_name
                effect.offset = descriptor.offset
                effect.cap = cap
                effect.needed = math_ceil(cap / descriptor.per_trigger)
                effect.predictable = descriptor.predictable
                effect.observed = _observed_stacks(buff_extension, effect)
                effect.start_observed = effect.observed
                -- Stacks left over from the previous attack are ignored until they are seen cleared
                -- or rising again, so a late-replicated old stack count can never confirm an effect.
                effect.armed = effect.observed == 0
                effect.confirmed = false

                if count == MAX_EFFECTS then
                    break
                end
            end
        end
    end

    local action_settings = action._action_settings
    local action_name = weapon_action_component.current_action_name

    if count == 0 then
        if mod._settings.debug_logging then
            mod:echo(DEBUG_PREFIX .. "windup %s: no charge-dependent effect", tostring(action_name))
        end

        return
    end

    state.active = true
    state.action = action
    state.unit = action._player_unit
    state.action_name = action_name
    state.start_t = t
    state.first_trigger_t = first_trigger_t
    state.interval = action_settings and action_settings.proc_time_interval or PROC_INTERVAL_DEFAULT
    state.triggers = 0
    state.time_in_action = 0
    state.buff_extension = buff_extension
    state.weapon_action_component = weapon_action_component
    state.effect_count = count
    state.fill = 0
    state.ready = false

    if mod._settings.debug_logging then
        mod:echo(DEBUG_PREFIX .. "windup %s: first trigger %.2fs, step %.2fs, effects: %s", tostring(action_name), first_trigger_t, state.interval, _debug_effects())
    end
end

Tracker.on_windup_update = function (action, time_in_action)
    if action ~= state.action then
        return
    end

    state.time_in_action = time_in_action

    -- The action advances _proc_trigger_time by one interval each time it fires on_windup_trigger,
    -- so this reads the game's own trigger count (and follows server corrections that reset it).
    local proc_trigger_time = action._proc_trigger_time

    if proc_trigger_time then
        local triggers = math_floor((proc_trigger_time - state.first_trigger_t) / state.interval + 0.5)

        state.triggers = triggers > 0 and triggers or 0
    end
end

Tracker.on_windup_finish = function (action, reason)
    if action ~= state.action then
        return
    end

    _debug_finish(reason)
    _reset_state()
end

-- Called by the HUD element every frame while a tracked windup is running.
-- Returns visible, fill fraction (0..1), ready.
Tracker.refresh = function (timing_mode)
    if not state.active then
        return false, 0, false
    end

    local weapon_action_component = state.weapon_action_component
    local alive_units = ALIVE

    if weapon_action_component.current_action_name ~= state.action_name or weapon_action_component.start_t ~= state.start_t or not alive_units or not alive_units[state.unit] then
        _debug_finish("action ended")
        _reset_state()

        return false, 0, false
    end

    local buff_extension = state.buff_extension
    local predicted = timing_mode ~= TIMING_MODE_CONFIRMED
    local triggers = state.triggers
    local interval = state.interval
    local fill_start_t = state.first_trigger_t - interval
    local time_since_fill_start = state.time_in_action - fill_start_t
    local fill = 1
    local confirmed_count = 0

    for i = 1, state.effect_count do
        local effect = effects[i]
        local observed = _observed_stacks(buff_extension, effect)

        effect.observed = observed

        if not effect.confirmed then
            if observed == 0 then
                effect.armed = true
            elseif effect.armed or observed > effect.start_observed then
                effect.confirmed = true

                if mod._settings.debug_logging then
                    mod:echo(DEBUG_PREFIX .. "%s confirmed at %d/%d after %.2fs (%d triggers)", effect.child_name, observed, effect.cap, state.time_in_action, triggers)
                end
            end
        end

        if effect.confirmed then
            confirmed_count = confirmed_count + 1

            local cap = effect.cap
            local fraction

            if observed >= cap then
                fraction = 1
            elseif predicted and effect.predictable then
                if triggers >= effect.needed then
                    fraction = 1
                else
                    -- Smooth fill that reaches k / needed exactly when the game fires trigger k.
                    fraction = time_since_fill_start / (effect.needed * interval)

                    if fraction > NEARLY_FULL then
                        fraction = NEARLY_FULL
                    end
                end
            else
                fraction = observed / cap
            end

            if fraction < fill then
                fill = fraction
            end
        end
    end

    if confirmed_count == 0 then
        state.fill = 0

        return false, 0, false
    end

    if state.ready then
        fill = 1
    elseif fill >= 1 then
        fill = 1
        state.ready = true

        if mod._settings.debug_logging then
            mod:echo(DEBUG_PREFIX .. "READY after %.2fs (%d triggers, %s): %s", state.time_in_action, triggers, predicted and "predicted" or "confirmed", _debug_effects())
        end
    elseif fill < 0 then
        fill = 0
    end

    state.fill = fill

    return true, fill, state.ready
end

Tracker.is_charging_heavy_attack = function ()
    return state.active
end

-- Returns the preallocated effect pool and the number of entries in use for the current windup.
Tracker.get_relevant_charge_buffs = function ()
    return effects, state.effect_count
end

Tracker.are_charge_buffs_maxed = function ()
    return state.ready
end

Tracker.fill = function ()
    return state.fill
end

Tracker.reset = function ()
    _reset_state()
end

return Tracker
