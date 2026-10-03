local mod = get_mod("PerfectThrust")

mod.version = mod.get_metadata and mod:get_metadata("version") or "unknown"

local settings = {
    display_mode = "progress",
    timing_mode = "predicted",
    ring_radius = 32,
    ring_thickness = 3,
    offset_x = 0,
    offset_y = 0,
    ring_opacity = 100,
    ready_pulse = true,
    debug_logging = false
}

local SETTING_IDS = {
    "display_mode",
    "timing_mode",
    "ring_radius",
    "ring_thickness",
    "offset_x",
    "offset_y",
    "ring_opacity",
    "ready_pulse",
    "debug_logging"
}

local CACHED_SETTING_IDS = {}

for i = 1, #SETTING_IDS do
    CACHED_SETTING_IDS[SETTING_IDS[i]] = true
end

mod._settings = settings
mod._settings_version = 0

local function refresh_settings()
    for i = 1, #SETTING_IDS do
        local setting_id = SETTING_IDS[i]
        local value = mod:get(setting_id)

        if value ~= nil then
            settings[setting_id] = value
        end
    end

    mod._settings_version = mod._settings_version + 1
end

refresh_settings()

mod.on_setting_changed = function (setting_id)
    if setting_id == nil then
        refresh_settings()

        return
    end

    if not CACHED_SETTING_IDS[setting_id] then
        return
    end

    local value = mod:get(setting_id)

    if value ~= nil then
        settings[setting_id] = value
    end

    mod._settings_version = mod._settings_version + 1
end

mod._tracker = mod:io_dofile("PerfectThrust/scripts/mods/PerfectThrust/PerfectThrust_tracker")

local Tracker = mod._tracker

local function on_windup_start(self, action_settings, t)
    Tracker.on_windup_start(self, t)
end

local function on_windup_fixed_update(self, dt, t, time_in_action)
    Tracker.on_windup_update(self, time_in_action)
end

mod:hook_safe(CLASS.ActionWindup, "start", on_windup_start)
mod:hook_safe(CLASS.ActionWindup, "fixed_update", on_windup_fixed_update)
mod:hook_safe(CLASS.ActionWindup, "finish", function (self, reason)
    Tracker.on_windup_finish(self, reason)
end)

-- ActionBlockWindup inherits finish from ActionBlock; instead of hooking that shared base method,
-- its end is caught by the tracker's per-frame weapon_action check.
mod:hook_safe(CLASS.ActionBlockWindup, "start", on_windup_start)
mod:hook_safe(CLASS.ActionBlockWindup, "fixed_update", on_windup_fixed_update)

mod.on_game_state_changed = function (status, state_name)
    if state_name == "StateGameplay" then
        Tracker.reset()
    end
end

mod.on_enabled = function ()
    refresh_settings()

    Tracker.reset()
end

mod.on_disabled = function ()
    Tracker.reset()
end

mod:register_hud_element({
    class_name = "HudElementPerfectThrust",
    filename = "PerfectThrust/scripts/mods/PerfectThrust/ui/PerfectThrust_hud_element",
    use_hud_scale = false,
    visibility_groups = {
        "alive",
        "player_in_danger_zone"
    }
})

return mod
