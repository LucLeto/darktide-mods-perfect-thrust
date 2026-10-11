# darktide-mods-perfect-thrust
Perfect Thrust adds a small ring around the crosshair that shows when a charged heavy attack has received the full benefit of your charge-dependent effects - the **Thrust** and **Slow and Steady** blessings, the Ogryn talent **Crunch!**, and the built-in windup bonus some weapons have. These effects reach their maximum well before the weapon releases the attack on its own, and the game gives no feedback for that moment. The ring fills while the effects build and turns green once **all** of them are capped, so you can release immediately instead of holding until the forced release.

Without any of these effects, the ring shows by default when a regular attack has been charged long enough to count as a heavy attack (see [Regular heavy attacks](#regular-heavy-attacks)).

The mod is purely visual. It never releases attacks, changes timings, simulates input or alters buffs.

## Display

The ring sits at the centre of the screen, around the crosshair, and is only drawn while you charge a heavy attack with at least one relevant effect active, or, with `Show regular heavy attack readiness` on, while you charge an attack without any (colors shown are the defaults, see [Colors](#colors)):

| State | Ring |
| --- | --- |
| Idle | Hidden |
| No relevant effect, `Show regular heavy attack readiness` off | Hidden |
| Charging, effects building | Amber segments fill clockwise from the top |
| READY - every tracked effect is at its maximum | Fully green, with a brief pulse |
| Charging without relevant effects | Amber segments fill until the attack counts as a heavy attack |
| READY - the attack counts as a heavy attack | Fully green, with a brief pulse |
| Released, cancelled, weapon switched, downed | Hidden immediately |

With relevant effects, the ring appears once the first stack of an effect has arrived, which is shortly after the attack has become a heavy attack, so light attacks never make it flicker. After READY it stays full for as long as you keep charging; holding longer gains nothing from these effects, but you can of course keep charging for other reasons.

With `Display` set to `READY only` the ring stays hidden while charging and only appears at READY.

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

Conditional effects are checked when you start charging: an effect whose condition is not met at that moment - the Relic Blades' sprint-only bonus on a heavy attack charged without sprinting, the Mechanicus Power Sword's bonus with the special off - cannot stack during this charge and is left out. If no other effect is active, the charge shows the [regular heavy attack](#regular-heavy-attacks) ring instead. An effect that is kept only counts once it has actually started stacking during the current charge. Stacks left over from the previous attack are ignored until the game has cleared them.

### How the stacks build

The first stack is granted when the heavy attack becomes available, then one more each interval. According to kuli's guides the interval is 0.25 s on most weapons and 0.2 s on Pickaxes, Thunder Hammers and the Chainaxe Mk IV; attack speed buffs do not change it. A 3-stack effect is therefore capped two intervals after the heavy threshold, and a 4-stack effect such as Crunch! three intervals after it. With several effects, READY waits for the slowest one - with Thrust and Crunch! on an Ogryn, READY follows Crunch!.

## Regular heavy attacks

When none of the effects above is active, the ring falls back to the regular heavy attack: it fills while you charge and turns green at the earliest moment you can let go and still get a heavy attack. This also covers flat heavy attack bonuses that do not depend on how long you charge, such as heavy attack damage talents, and the heavy bashes and stabs of ranged weapons. Holding longer than READY adds no damage. Turn `Show regular heavy attack readiness` off to show the ring only for the effects above, as in earlier versions.

The threshold is read from the game for each charge, never hard-coded. The game decides light or heavy when you let go: once the weapon's heavy attack input has been held for its hold time (0.25 to 0.45 s depending on the weapon), a release is queued as a heavy attack. The charging action then starts the heavy swing at its own `chain_time`, which differs between weapons, marks and combo steps and is shortened by attack speed. A queued heavy waits for that moment for up to its buffer time (0.5 s), so:

* READY appears at the heavy attack input's hold time. On most weapons this is before the heavy swing can start, so the ring can turn green shortly before the swing begins after you let go - the attack is the same as if you had held on.
* Only if the action's `chain_time` (divided by the attack speed time scale, like the game does) comes more than the buffer time after the hold time, READY waits until releasing is within the buffer time of it. No current weapon needs this.

Charges with no resolvable heavy attack threshold show no ring. The fallback runs entirely on your client's own windup timer, as no server stacks are involved, so `READY timing` does not apply to it.

The effects above always take priority. The choice is made when you start charging: if any effect can stack during this charge, the ring follows that effect, even while its first stack has not arrived yet. Effects whose condition is not met when you start charging do not count, so a Relic Blade heavy attack charged without sprinting, or a Mechanicus Power Sword heavy attack with the special off, shows the regular heavy attack ring.

In `Progress + READY` mode the ring starts filling as soon as you press attack, so a light attack briefly shows a partially filled ring until it is released. Use `READY only` if you prefer the ring to appear only at READY.

## READY timing

All of these effects are granted by the server. A multiplayer client only sees each new stack after a network round trip, so reading the stacks alone would always show READY about one ping late. The `READY timing` setting chooses the source:

* **Predicted** (default) - READY follows your client's own windup timer, the same timer the server uses to grant the stacks. The mod reads the game's trigger counter rather than re-deriving the formula, so READY appears on the frame the stacks are capped. Releasing from that frame on gets the full bonus, because the server applies your release at the same point in the windup. Which effects count is still decided by the real stacks arriving from the server.
* **Server-confirmed** - READY waits until the stacks reported by the server reach their maximum. It is never early, but it is about one ping late and the fill steps as stacks arrive.

In solo play the server runs locally, so there is no network delay and both modes behave practically the same.

## Settings

`Charge indicator` group:

| Setting | Default | Range / options |
| --- | --- | --- |
| Display | Progress + READY | Progress + READY / READY only |
| READY timing | Predicted | Predicted / Server-confirmed |
| Show regular heavy attack readiness | On | Shows the ring for heavy attacks without charge-dependent effects |
| Ring size | 32 | 12-150 px radius at 1080p |
| Ring thickness | 3 | 1-10 px per segment at 1080p |
| Horizontal offset | 0 | -960 to 960 px from the screen centre |
| Vertical offset | 0 | -540 to 540 px from the screen centre |
| READY pulse | On | Briefly enlarges the ring segments at READY |
| Unfilled segment color | RGB `70, 82, 86`, alpha `80` (faint grey) | Any color and opacity |
| Charging progress color | RGB `240, 190, 90`, alpha `235` (amber) | Any color and opacity |
| READY color | RGB `120, 225, 140`, alpha `255` (green) | Any color and opacity |
| READY pulse color | RGB `120, 225, 140`, alpha `255` (same as READY) | Any color and opacity, shown only during the READY pulse |
| Debug output | Off | Prints charge-state transitions to chat |

The ring scales with your resolution like the game's own crosshair and ignores the HUD scale option. Disabling the mod through the standard mod toggle hides the ring and stops all tracking.

### Colors

Each ring state has its own color picker with an alpha channel, so color and opacity are set per state. Alpha runs from 0 (invisible) to 255 (fully opaque); by default the unfilled segments are faint (80), the charging segments nearly opaque (235) and READY fully opaque (255).

`READY pulse color` is used only while the existing READY pulse runs, the 0.25-second enlargement of the segments when READY is first reached; the ring then switches to `READY color` for as long as you keep charging. With `READY pulse` off, the ring turns to `READY color` immediately and the pulse color is never shown. Because the pulse color defaults to the READY color, the pulse only changes the segment size unless you pick a different color.

Color changes apply immediately, without reloading. Resetting a color setting restores the default listed above.

**Updating from 1.0.0:** the separate `Opacity` setting has been replaced by the alpha of the four colors. On the first start after the update, your old `Opacity` value is applied once to the alpha of every color - at 50 %, for example, the defaults become 40, 117, 127 and 127 - so the ring looks exactly as before. After that the old setting is removed, and you adjust each color's alpha directly.

### Debug output

With `Debug output` enabled, every windup writes its transitions to your own chat, which makes it easy to check what the mod detects for a given weapon and build:

```text
[Perfect Thrust] windup action_melee_start_left: first trigger 0.50s, step 0.25s, effects: <child buff> 0/3
[Perfect Thrust] <child buff> confirmed at 1/3 after 0.62s (1 triggers)
[Perfect Thrust] READY after 1.00s (3 triggers, predicted): <child buff> 2/3
[Perfect Thrust] end (released) after 1.40s, 4 triggers, ready=true: <child buff> 3/3
```

A windup without any relevant effect logs a single `no charge-dependent effect` line, or, with `Show regular heavy attack readiness` on, tracks the regular heavy attack instead:

```text
[Perfect Thrust] windup action_melee_start_left: regular heavy, threshold 0.35s (heavy_attack hold 0.35s, chain 0.40s, time scale 1.00, buffer 0.50s)
[Perfect Thrust] READY after 0.35s (regular heavy)
[Perfect Thrust] end (new_interrupting_action) after 0.55s, ready=true (regular heavy)
```

If no heavy attack threshold can be resolved for a windup, it logs `no charge-dependent effect, no heavy attack threshold`. An effect left out because its condition is not met logs `<child buff> skipped: its condition is not met in this windup` before the windup line. In the first example above, the predicted READY lands before the third stack has arrived from the server - that gap is the network delay Predicted mode removes.

## Limitations

* **Predicted mode assumes every trigger after the first stack grants another one.** That holds for all effects listed above while their condition stays true. If a conditional effect loses its condition mid-charge - for example you stop sprinting during a sprint heavy - Predicted mode can show READY before that effect is actually capped. Use `Server-confirmed` if this matters to you.
* **Conditions are checked once, when you start charging.** If a conditional effect loses its condition before its first stack - for example you stop sprinting right after starting a Relic Blade sprint heavy - the ring stays hidden for that charge instead of falling back to the regular heavy attack ring.
* **Very high ping.** Effects are counted once their first stack has arrived. Above roughly 250-500 ms, a second effect's first stack may not have arrived yet when another effect is capped, which can make a predicted READY early.
* **With charge-dependent effects, the ring appears about one ping after the heavy threshold**, in both modes, because an effect is only shown once its first stack has arrived from the server. Its fill is already correct when it appears.
* **Regular heavy READY can be slightly late in attack chains.** The heavy attack input's hold time is counted from the start of the charge, although the game starts counting it when you press attack, which can be earlier when you press during the previous swing. Conditions the game checks for a few heavy attacks themselves, such as the weapon special still being active or not aiming with the shield shotpistol, are not evaluated.
* **The ring stays at the screen centre plus your offset.** It does not follow the crosshair's small recoil and sway drift, which melee weapons barely have.
* **"Fully charged" effects are not tracked.** Effects that need an attack held until the weapon releases it on its own, such as the Unstoppable Force blessing, do not build stacks. READY does not mean the attack counts as fully charged for them.
* **Only effects that stack from the windup trigger are detected.** An effect that builds while charging in some other way, or has no child buff with a stack limit, is not recognised. At most four effects are tracked per charge.
* **Ranged charging is not covered.** Plasma guns, force staves and other charged ranged weapons use a separate charge mechanic that the game's own crosshair already displays.
* **No Custom HUD integration.** Position the ring with the offset settings.
* The mod reads a few internal fields of the game's weapon actions and buffs. A game update that renames them disables the ring until the mod is updated; it does not affect gameplay.

## Credits & Sources

Blessing, talent and weapon names and values are taken from the excellent guides by [kuli](https://steamcommunity.com/id/kulii):

* [\[1.13.x\] Melee Weapon Blessings & Mechanics](https://steamcommunity.com/sharedfiles/filedetails/?id=3286161222)
* [\[1.13.x\] Ogryn Talents & Mechanics](https://steamcommunity.com/sharedfiles/filedetails/?id=3094034467)
