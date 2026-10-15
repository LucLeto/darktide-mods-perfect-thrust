# darktide-mods-perfect-thrust
Perfect Thrust adds a small ring around the crosshair that shows when a charged heavy attack has received the full benefit of your charge-dependent effects - the **Thrust** and **Slow and Steady** blessings, the Ogryn talent **Crunch!**, and the built-in windup bonus some weapons have. These effects reach their maximum well before the weapon releases the attack on its own, and the game gives no feedback for that moment. The ring fills while the effects build and turns green once **all** of them are capped, so you can release immediately instead of holding until the forced release.

By default the ring also marks the moment a charge counts as a heavy attack: it turns lime there while the effects keep building, and without any of these effects it simply turns green there (see [Heavy attack threshold](#heavy-attack-threshold)).

The same ring also works while you aim down sights with the ranged blessings **Surgical** and **Pinpointing Target**, which build stacks while aiming: it fills as the stacks build and turns green once they are all at their maximum (see [Aiming blessings](#aiming-blessings)).

The mod is purely visual. It never releases attacks, changes timings, simulates input or alters buffs.

## Display

The ring sits around the crosshair. With `Follow crosshair` on (the default) it moves with the crosshair when the game's camera sway shifts it while you charge and move; otherwise it stays at the centre of the screen. With `Show heavy attack threshold` on (the default) it is drawn from the moment you start charging an attack; with it off, only while a charge-dependent effect is building (colors shown are the defaults, see [Colors](#colors)):

| State | Ring |
| --- | --- |
| Idle | Hidden |
| Charging | Amber segments fill clockwise from the top |
| Heavy attack available, effects still building | The lit segments turn lime with a brief pulse, and the ring keeps filling |
| READY - every tracked effect is at its maximum, or, without effects, the attack counts as a heavy attack | Fully green, with a brief pulse |
| Released, cancelled, weapon switched, downed | Hidden immediately |

With effects, one ring spans the whole expected charge. With Thrust on a combat axe, for example, a release counts as a heavy attack from 0.35 s and Thrust is capped at 0.90 s, so the ring turns lime a little over a third of the way round and green when it is full. Without effects the ring ends at the heavy attack threshold and turns green there. After READY the ring stays full for as long as you keep charging; holding longer gains nothing, but you can of course keep charging for other reasons.

In `Progress + READY` mode the ring starts filling as soon as you press attack, so a light attack briefly shows a partially filled ring until it is released. With `Show heavy attack threshold` off, the ring only appears once the first stack of an effect has arrived, shortly after the attack has become a heavy attack, so light attacks never make it flicker.

With `Display` set to `READY only` the ring stays hidden while charging, including the lime phase, and only appears at READY.

## What it tracks

Nothing is hard-coded per weapon. When you start charging, the mod looks through your active buffs once and picks every effect that gains stacks while a heavy attack is charged. Effects tied to the weapon you are *not* holding are ignored. This covers all of today's effects and any future blessing or talent that works the same way:

| Effect | Type | Weapons | Max stacks | Per stack | Counts when |
| --- | --- | --- | --- | --- | --- |
| Thrust | Blessing | Bully Clubs, Chainaxes, Cleavers, Combat Axes, Crushers, Duelling Swords, Heavy Swords, Latrine Shovels, Pickaxes, Power Swords, Sapper Shovels, Shock Mauls, Thunder Hammers | 3 | +5 / 10 / 15 / 20 % Strength by blessing tier (Thunder Hammers: +5 / 7.5 / 10 / 12.5 %) | Always |
| Slow and Steady | Blessing | Cruncher, Pickaxes | 3 | 5 / 6 / 7 / 8 % of max Toughness by blessing tier, replenished when the attack hits | Always |
| Crunch! | Ogryn talent | Any Ogryn melee weapon | 4 | +7.5 % damage and +7.5 % stagger (impact) | Always |
| Windup bonus | Built into the weapon | Crowbar | 3 | +7.5 % Strength | Always |
| Windup bonus | Built into the weapon | Thunder Hammers | 3 | +12.5 % Strength | Always |
| Windup bonus | Built into the weapon | Cruncher | 4 | +10 % Strength | Always |
| Windup bonus | Built into the weapon | Mechanicus Power Sword | 4 | +12.5 % Strength | Only while the weapon special is active |
| Windup bonus | Built into the weapon | Relic Blades | 3 | +8 % heavy melee damage | Only on heavy attacks charged while sprinting |

Blessing, talent and weapon names follow kuli's guides (see [Credits & Sources](#credits--sources)); the built-in windup bonuses are taken from the game's weapon templates. Shield heavy attacks that charge from a block are supported as well.

<details>
<summary>Buff templates (for modders)</summary>

The mod picks every buff whose template procs on `on_windup_trigger` and adds stacks of a child buff with a `max_stacks` limit - either through `child_buff_template` with `add_child_proc_events`, or through the `*_parent` / `*_child` naming convention for proc buffs that add their child themselves.

| Effect | Buff template | Max stacks |
| --- | --- | --- |
| Thrust | `weapon_trait_bespoke_<weapon>_windup_increases_power_parent` | 3 |
| Slow and Steady | `weapon_trait_bespoke_<weapon>_toughness_on_hit_based_on_charge_time` | 3 |
| Crunch! | `ogryn_windup_increases_power_parent` | 4 |
| Windup bonus (Crowbar) | `windup_increases_power_default_parent` | 3 |
| Windup bonus (Thunder Hammers) | `windup_increases_power_default_three_steps_parent` | 3 |
| Windup bonus (Cruncher) | `windup_increases_power_default_four_steps_parent` | 4 |
| Windup bonus (Mechanicus Power Sword) | `windup_increases_special_power_default_parent` | 4 |
| Windup bonus (Relic Blades) | `windup_increases_damage_on_sprint_parent` | 3 |

Weapon templates with a built-in windup bonus: `crowbar_p1_m1`, `thunderhammer_2h_p1_m1/m2`, `ogryn_hammer_2h_p1_m1`, `powersword_p3_m1`, `powersword_2h_p1_m1/m2`. Charging is read from `ActionWindup` and `ActionBlockWindup`.

When a charge starts, each buff's own proc conditions are checked the way `ProcBuff` does for the `on_windup_trigger` event - `conditional_proc_func`, then `specific_check_proc_funcs.on_windup_trigger` or else `check_proc_func`, with the windup's `action_settings` as the event parameter. Of today's effects, only two have a condition beyond the weapon being wielded: the Relic Blades' bonus needs a sprint windup (`is_sprint_windup`) while sprinting, and the Mechanicus Power Sword's bonus needs the weapon special to be active.

</details>

Conditional effects are checked when you start charging: an effect whose condition is not met at that moment - the Relic Blades' sprint-only bonus on a heavy attack charged without sprinting, the Mechanicus Power Sword's bonus with the special off - cannot stack during this charge and is left out. If no other effect is active, the ring follows the [heavy attack threshold](#heavy-attack-threshold) alone. An effect that is kept only counts for READY once it has actually started stacking during the current charge. Stacks left over from the previous attack are ignored until the game has cleared them.

### How the stacks build

The first stack is granted at the charging action's latest chain time - on most weapons the moment the heavy swing can start, shortly after a release already counts as a heavy attack - then one more each interval. According to kuli's guides the interval is 0.25 s on most weapons and 0.2 s on Pickaxes, Thunder Hammers and the Chainaxe Mk IV; attack speed buffs change neither the first stack nor the interval. A 3-stack effect is therefore capped two intervals after its first stack, and a 4-stack effect such as Crunch! three intervals after it. With several effects, READY waits for the slowest one - with Thrust and Crunch! on an Ogryn, READY follows Crunch!.

## Heavy attack threshold

With `Show heavy attack threshold` on (the default), the ring also marks the earliest moment you can let go and still get a heavy attack:

* **Without charge-dependent effects** the ring fills up to that moment and turns green. This also covers flat heavy attack bonuses that do not depend on how long you charge, such as heavy attack damage talents, and the heavy bashes and stabs of ranged weapons. Holding longer than READY adds no damage.
* **With charge-dependent effects** the lit segments turn lime at that moment, with a brief pulse, and the ring keeps filling until every effect is capped and it turns green. Letting go during the lime phase gives a heavy attack without the full bonus.

Turn the setting off to show the ring only while the effects above build, as in earlier versions.

The threshold is read from the game for each charge, never hard-coded. The game decides light or heavy when you let go: once the weapon's heavy attack input has been held for its hold time (0.25 to 0.45 s depending on the weapon), a release is queued as a heavy attack. The charging action then starts the heavy swing at its own `chain_time`, which differs between weapons, marks and combo steps. A queued heavy waits for that moment for up to its buffer time (0.5 s), so:

* The threshold is the end of the heavy attack input's hold. On most weapons this is before the heavy swing can start, so the ring can turn lime or green shortly before the swing begins after you let go - the attack is the same as if you had held on.
* The game starts the hold timer when you press attack. In an attack chain that is often while the previous swing still runs, so part of the hold - or all of it - is done before the new charge even starts. The mod reads that timer from the game's input handling, so the threshold comes correspondingly earlier, or right at the start of the charge.
* Only if the action's `chain_time` (divided by the action's time scale, like the game does) comes more than the buffer time after the end of the hold, the threshold waits until releasing is within the buffer time of it. No current weapon needs this.

Melee attack speed buffs, such as Maniac with Martyrdom stacks, speed up the swings but not the charge. The game applies attack speed to the light and heavy swing actions, while the charging action keeps its normal speed (debug output shows `time scale 1.00`) and the hold is measured in real time. Neither the heavy attack threshold nor the charge-dependent effects move with attack speed; a faster swing only brings you to the next charge sooner.

The threshold runs entirely on your client's own windup timer, as no server stacks are involved, so `READY timing` does not apply to it: the lime phase starts at the same moment in both modes. If no threshold can be resolved for a charge, a charge without effects shows no ring, and a charge with effects shows the ring as with the setting off.

The effects always decide READY. The choice is made when you start charging: if any effect can stack during this charge, READY follows that effect, even while its first stack has not arrived yet - until then the ring waits in lime. Effects whose condition is not met when you start charging do not count, so a Relic Blade heavy attack charged without sprinting, or a Mechanicus Power Sword heavy attack with the special off, shows the heavy attack threshold alone.

With effects, the ring spans the expected charge up to the slowest effect's cap, and the lime phase starts at the threshold's share of it. In `Predicted` mode the ring fills at a steady pace all the way round; in `Server-confirmed` mode the part after the threshold steps as the stacks arrive from the server.

## READY timing

All of these effects are granted by the server. A multiplayer client only sees each new stack after a network round trip, so reading the stacks alone would always show READY about one ping late. The `READY timing` setting chooses the source:

* **Predicted** (default) - READY follows your client's own windup timer, the same timer the server uses to grant the stacks. The mod reads the game's trigger counter rather than re-deriving the formula, so READY appears on the frame the stacks are capped. Releasing from that frame on gets the full bonus, because the server applies your release at the same point in the windup. Which effects count is still decided by the real stacks arriving from the server.
* **Server-confirmed** - READY waits until the stacks reported by the server reach their maximum. It is never early, but it is about one ping late and the fill steps as stacks arrive.

In solo play the server runs locally, so there is no network delay and both modes behave practically the same.

## Aiming blessings

With `Show aiming blessings` on (the default), the ring is also shown while you aim down sights with a ranged weapon that carries one of these blessings. The stacks build while you keep aiming and are lost when you fire or stop aiming, so the ring answers the same question as for melee: when has holding on paid off completely?

| Blessing | Weapons | Max stacks | Per stack | Interval T1 / T2 / T3 / T4 | Full after (T4) |
| --- | --- | --- | --- | --- | --- |
| Surgical | Boltguns, Heavy Stubbers, Kickback, Thugshot, Vigilant Autoguns | 10 | +10 % Critical Chance | 0.35 / 0.3 / 0.25 / 0.2 s | 2.0 s |
| Surgical | Bolt Pistols, Helbore Lasguns, Shotpistol & Shield, Stub Revolvers | 10 | +10 % Critical Chance | 0.45 / 0.4 / 0.35 / 0.3 s | 3.0 s |
| Surgical | Phosphor Blast Pistol | 10 | +10 % Critical Chance | 0.45 / 0.4 / 0.35 / 0.325 s | 3.25 s |
| Pinpointing Target | Galvanic Rifle | 5 | +1 / 1.5 / 2 / 2.5 % Strength | 0.4 s | 2.0 s |
| Pinpointing Target | Phosphor Blast Pistol | 5 | +1 / 2 / 3 / 4 % Strength | 0.4 s | 2.0 s |
| Pinpointing Target | Grenadier Gauntlet, Shotpistol & Shield | 5 | +5 / 6 / 7 / 8 % Strength | 0.4 s | 2.0 s |

Values are taken from the game's blessing definitions and kuli's guides; the mod itself reads the interval and the number of stacks of your blessing's tier from the game for each aim, so nothing is hard-coded per weapon.

| State | Ring |
| --- | --- |
| Aiming, stacks building | Amber segments fill clockwise from the top, reaching each stack exactly when the game grants it |
| READY - every aiming blessing on the weapon is at its maximum | Fully green, with a brief pulse; it stays green while you keep aiming |
| Shot fired while still aiming | The ring starts over from empty, as the stacks do, and pulses again at the next READY |
| Stopped aiming, reloaded, switched weapons, staggered, pushed with the Shotpistol & Shield, downed | Hidden immediately |

* **Both blessings on one weapon** (Phosphor Blast Pistol, Shotpistol & Shield): READY waits for the slower one. With a T4 Surgical and Pinpointing Target on the Phosphor Blast Pistol, Pinpointing Target is full after 2.0 s, but READY comes at 3.25 s.
* **Only the weapon in your hands counts.** Blessings of a holstered weapon are ignored, as the game ignores them too.
* **Melee charges come first.** If you start a melee charge while aiming, such as the Shotpistol & Shield's bash from a raised shield, the ring shows that charge until it ends. The push itself ends the aim and removes the stacks, so a new aim starts from empty.
* **Its own look.** The aiming ring has its own display mode, size, thickness, position, READY pulse and colors in the `Aiming indicator` settings group, so it can differ from the melee ring - for example larger, or in `READY only` mode while the melee ring shows its progress. By default it looks exactly like the melee ring. It has no heavy attack available color, as aiming never shows that state.

`READY timing` does not apply to aiming. Unlike the melee effects, these blessings have no stack count that the server sends to your client: the game computes their stacks from how long you have been aiming since you started or last fired, using the same aim timer on your client and on the server. The ring follows that timer directly, so it is on time in both solo and multiplayer, with no network delay to wait for.

<details>
<summary>Buff templates (for modders)</summary>

Every weapon's blessing is a clone of one of two base buff templates in `base_weapon_trait_buff_templates.lua` and keeps its `start_func`, which the mod uses to recognise it:

| Blessing | Base template | Buff class | Steps |
| --- | --- | --- | --- |
| Surgical (`weapon_trait_bespoke_<weapon>_crit_chance_based_on_aim_time`) | `chance_based_on_aim_time` | `stepped_stat_buff` | `floor(time_lapsed / duration_per_stack)`, limited by `min_max_step_func` (0-10) |
| Pinpointing Target (`weapon_trait_bespoke_<weapon>_increases_power_while_aiming`) | `power_level_on_aim_time` | `proc_buff` with a lerped stat | `min(floor(time_lapsed / duration_per_step), num_steps_for_max_stat)` |
| Pinpointing Target, Grenadier Gauntlet (`weapon_trait_bespoke_ogryn_gauntlet_p1_windup_increases_power`) | clone of `chance_based_on_aim_time` with its own step functions | `stepped_stat_buff` | as Surgical, limited to 0-5 |

`time_lapsed` is `FixedFrame.get_latest_fixed_time()` minus the later of `alternate_fire_component.start_t` and `action_shoot_component.fire_last_t`, and only counts while `alternate_fire_component.is_active`. The interval and step count come from the blessing tier's trait override (`duration_per_stack`, or `duration_per_step` and `num_steps_for_max_stat`) and otherwise from the template. The mod scans your buffs once when an aim starts and then evaluates that formula on your own components each frame; it never calls a buff's step function or writes to a buff.

</details>

## Settings

`Charge indicator` group:

| Setting | Default | Range / options |
| --- | --- | --- |
| Display | Progress + READY | Progress + READY / READY only |
| READY timing | Predicted | Predicted / Server-confirmed |
| Show heavy attack threshold | On | Shows the ring from the start of every charge and marks the heavy attack threshold |
| Follow crosshair | On | Moves the ring with the crosshair as the game's camera sway shifts it while you charge and move; the offsets then count from the crosshair. With the game's `Camera Sway Intensity` at 0 % the crosshair, and so the ring, stays centred. Off keeps the ring at the screen centre |
| Ring size | 32 | 12-150 px radius at 1080p |
| Ring thickness | 3 | 1-10 px per segment at 1080p |
| Horizontal offset | 0 | -960 to 960 px from the screen centre, or from the crosshair with `Follow crosshair` on |
| Vertical offset | 0 | -540 to 540 px from the screen centre, or from the crosshair with `Follow crosshair` on |
| READY pulse | On | Briefly enlarges the ring segments at READY and when the lime phase starts |
| Unfilled segment color | RGB `70, 82, 86`, alpha `80` (faint grey) | Any color and opacity |
| Charging progress color | RGB `240, 190, 90`, alpha `235` (amber) | Any color and opacity |
| Heavy attack available color | RGB `233, 255, 90`, alpha `229` (lime) | Any color and opacity, shown while the effects build after the heavy attack threshold |
| READY color | RGB `120, 225, 140`, alpha `255` (green) | Any color and opacity |
| READY pulse color | RGB `120, 225, 140`, alpha `255` (same as READY) | Any color and opacity, shown only during the READY pulse |

`Aiming indicator` group, for the ring shown while aiming down sights (see [Aiming blessings](#aiming-blessings)):

| Setting | Default | Range / options |
| --- | --- | --- |
| Show aiming blessings | On | Shows the ring while aiming with Surgical or Pinpointing Target |
| Display | Progress + READY | Progress + READY / READY only |
| Follow crosshair | On | Moves the ring with the crosshair - the point your shots go to - as weapon sway, recoil and camera sway move it; the offsets then count from the crosshair. Like the game's crosshair, it does not follow the weapon model's own bobbing and kick animations, so the sights can drift slightly around it. Off keeps it at the screen centre |
| Ring size, Ring thickness, Horizontal offset, Vertical offset | 32, 3, 0, 0 | As for the melee ring |
| READY pulse | On | Briefly enlarges the ring segments at READY |
| Unfilled segment color, Aiming progress color, READY color, READY pulse color | As for the melee ring | Any color and opacity |

The two rings are set independently; changing one never changes the other.

`Miscellaneous` group (`Sonstiges` in German), for settings that apply to both rings:

| Setting | Default | Range / options |
| --- | --- | --- |
| Debug output | Off | Writes charge and aim state transitions to the game's log file (see [Debug output](#debug-output)) |

The ring scales with your resolution like the game's own crosshair and ignores the HUD scale option. Disabling the mod through the standard mod toggle hides the ring and stops all tracking.

### Colors

Each ring state has its own color picker with an alpha channel, so color and opacity are set per state, separately for the melee and the aiming ring. Alpha runs from 0 (invisible) to 255 (fully opaque); by default the unfilled segments are faint (80), the charging (235) and heavy attack available (229) segments nearly opaque and READY fully opaque (255).

`READY pulse color` is used only while the existing READY pulse runs, the 0.25-second enlargement of the segments when READY is first reached; the ring then switches to `READY color` for as long as you keep charging. With `READY pulse` off, the ring turns to `READY color` immediately and the pulse color is never shown. Because the pulse color defaults to the READY color, the pulse only changes the segment size unless you pick a different color. The pulse at the start of the lime phase keeps `Heavy attack available color`.

Color changes apply immediately, without reloading. Resetting a color setting restores the default listed above.

**Updating from 1.0.0:** the separate `Opacity` setting has been replaced by the alpha of the colors. On the first start after the update, your old `Opacity` value is applied once to the alpha of every color - at 50 %, for example, the defaults become 40, 117, 114, 127 and 127 - so the ring looks exactly as before. After that the old setting is removed, and you adjust each color's alpha directly.

### Debug output

With `Debug output` enabled, every windup writes its transitions to the game's log file, which makes it easy to check what the mod detects for a given weapon and build without filling your chat. The log files are in `%APPDATA%\Fatshark\Darktide\console_logs`; the lines are written as DMF info messages, `[MOD][PerfectThrust][INFO] [Perfect Thrust] ...`, so they also follow DMF's own logging settings:

```text
[Perfect Thrust] windup action_melee_start_left: first trigger 0.40s, step 0.25s, effects: <child buff> 0/3
[Perfect Thrust] heavy threshold 0.35s (heavy_attack hold 0.35s, held 0.00s, chain 0.40s, time scale 1.00, buffer 0.50s), expected READY 0.90s
[Perfect Thrust] heavy attack available after 0.35s
[Perfect Thrust] <child buff> confirmed at 1/3 after 0.47s (1 triggers)
[Perfect Thrust] READY after 0.90s (3 triggers, predicted): <child buff> 2/3
[Perfect Thrust] end (released) after 1.20s, 4 triggers, ready=true: <child buff> 3/3
```

With `Show heavy attack threshold` off, the `heavy threshold` and `heavy attack available` lines are missing. A windup without any relevant effect logs a single `no charge-dependent effect` line, or, with the setting on, tracks the heavy attack threshold alone:

```text
[Perfect Thrust] windup action_melee_start_left: regular heavy, threshold 0.35s (heavy_attack hold 0.35s, held 0.00s, chain 0.40s, time scale 1.00, buffer 0.50s)
[Perfect Thrust] READY after 0.35s (regular heavy)
[Perfect Thrust] end (new_interrupting_action) after 0.55s, ready=true (regular heavy)
```

`held` is how much of the heavy attack input's hold was already done when the charge started - above 0 in attack chains where you pressed during the previous swing. It shows `released` when you had already let go before the charge started, typically a quick tap during the previous swing that turns into a light attack right away, and `?` when the game's input handling could not be read; in both cases the hold is counted from the start of the charge. If no heavy attack threshold can be resolved for a windup, it logs `no charge-dependent effect, no heavy attack threshold`. An effect left out because its condition is not met logs `<child buff> skipped: its condition is not met in this windup` before the windup line. In the first example above, the predicted READY lands before the third stack has arrived from the server - that gap is the network delay Predicted mode removes.

Aiming with `Show aiming blessings` on writes `ADS` lines. The times count from the start of the aim or the last shot, whichever is later; `10 x 0.2s` is the step count and interval of your blessing's tier:

```text
[Perfect Thrust] ADS slot_secondary: expected READY 2.00s, blessings: weapon_trait_bespoke_bolter_p1_crit_chance_based_on_aim_time 10 x 0.2s
[Perfect Thrust] READY after 2.00s (ADS): weapon_trait_bespoke_bolter_p1_crit_chance_based_on_aim_time 10/10
[Perfect Thrust] ADS shot after 2.63s, ready=true: weapon_trait_bespoke_bolter_p1_crit_chance_based_on_aim_time 10/10
[Perfect Thrust] ADS end (left ADS) after 0.87s, 1 shots, ready=false: weapon_trait_bespoke_bolter_p1_crit_chance_based_on_aim_time 4/10
```

An aim with a weapon that has no aiming blessing logs a single `ADS slot_secondary: no aiming blessing` line. The end reason is `left ADS`, `ADS restarted` (a new aim began before the previous end was seen, for example while a Shotpistol & Shield bash held the ring), `weapon switched` or `player unit changed`. A blessing whose interval or step count cannot be read logs `<buff> skipped: its interval or step count could not be resolved`.

## Limitations

* **Predicted mode assumes every trigger after the first stack grants another one.** That holds for all effects listed above while their condition stays true. If a conditional effect loses its condition mid-charge - for example you stop sprinting during a sprint heavy - Predicted mode can show READY before that effect is actually capped. Use `Server-confirmed` if this matters to you.
* **Conditions are checked once, when you start charging.** If a conditional effect loses its condition before its first stack - for example you stop sprinting right after starting a Relic Blade sprint heavy - READY does not come for that charge: the ring waits in lime (or stays hidden with `Show heavy attack threshold` off) instead of turning green at the heavy attack threshold.
* **Very high ping.** Effects are counted once their first stack has arrived. Above roughly 250-500 ms, a second effect's first stack may not have arrived yet when another effect is capped, which can make a predicted READY early.
* **With `Show heavy attack threshold` off, the ring of a charge with effects appears about one ping after the heavy threshold**, in both modes, because an effect is only shown once its first stack has arrived from the server. Its fill is already correct when it appears.
* **The hold timer comes from game internals.** The mod reads the heavy attack input's hold timer from the game's input handling. If a game update changes it, the mod counts the hold from the start of the charge instead, which is never early but can make the threshold late in attack chains; debug output then shows `held ?`. Conditions the game checks for a few heavy attacks themselves, such as the weapon special still being active or not aiming with the shield shotpistol, are not evaluated.
* **The rings follow the crosshair, not the weapon model.** With `Follow crosshair` on, each ring follows the game's crosshair - your aim point, which camera sway, weapon sway and recoil move on screen - not the bobbing and kick animations of the weapon model, so the sights can drift slightly around the aiming ring.
* **"Fully charged" effects are not tracked.** Effects that need an attack held until the weapon releases it on its own, such as the Unstoppable Force blessing, do not build stacks. READY does not mean the attack counts as fully charged for them.
* **Only effects that stack from the windup trigger are detected.** An effect that builds while charging in some other way, or has no child buff with a stack limit, is not recognised. At most four effects are tracked per charge.
* **Ranged charging is not covered.** Plasma guns, force staves and other charged ranged weapons use a separate charge mechanic that the game's own crosshair already displays. Of the ranged blessings, only Surgical and Pinpointing Target, which build stacks over aim time, are tracked.
* **The Grenadier Gauntlet keeps its stacks briefly after a shot.** Its Pinpointing Target holds the stacks from before the shot for 0.8 s, so the grenade in flight keeps them, and then continues as if it had restarted at the shot. The ring restarts at the shot, which is when the stacks for the next shot start building; READY comes at the same moment as the game's maximum.
* **Pinpointing Target pauses during a shot's own start.** On the server its stacks freeze from the start of a shot until the shot fires, which on most weapons is the same moment. The ring keeps counting during that short gap and restarts when the shot fires.
* **No Custom HUD integration.** Position the ring with the offset settings.
* The mod reads a few internal fields of the game's weapon actions and buffs. A game update that renames them disables the ring until the mod is updated; it does not affect gameplay.

## Credits & Sources

Blessing, talent and weapon names and values are taken from the excellent guides by [kuli](https://steamcommunity.com/id/kulii):

* [\[1.13.x\] Melee Weapon Blessings & Mechanics](https://steamcommunity.com/sharedfiles/filedetails/?id=3286161222)
* [\[1.13.x\] Ogryn Talents & Mechanics](https://steamcommunity.com/sharedfiles/filedetails/?id=3094034467)
* [Ranged Weapon Blessings & Mechanics](https://steamcommunity.com/sharedfiles/filedetails/?id=3293278399)

Tracking of the aiming blessings was requested by [Rymdkapsel](https://next.nexusmods.com/profile/Rymdkapsel) on [Nexus Mods](https://www.nexusmods.com/warhammer40kdarktide/mods/1402?tab=posts).
