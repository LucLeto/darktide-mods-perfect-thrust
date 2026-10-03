# darktide-mods-perfect-thrust
Perfect Thrust adds a small ring around the crosshair that shows when a charged heavy attack has received the full benefit of your charge-dependent effects - the **Thrust** blessing, the built-in windup bonus some weapons have, and the Ogryn talent that builds damage and stagger while charging. These effects reach their maximum well before the weapon releases the attack on its own, and the game gives no feedback for that moment. The ring fills while the effects build and turns green once **all** of them are capped, so you can release immediately instead of holding until the forced release.

The mod is purely visual. It never releases attacks, changes timings, simulates input or alters buffs.

## Display

The ring sits at the centre of the screen, around the crosshair, and is only drawn while you charge a heavy attack with at least one relevant effect active:

| State | Ring |
| --- | --- |
| Idle, light attacks, no relevant effect | Hidden |
| Charging, effects building | Amber segments fill clockwise from the top |
| READY - every tracked effect is at its maximum | Fully green, with a brief pulse |
| Released, cancelled, weapon switched, downed | Hidden immediately |

The ring appears once the first stack of an effect has arrived, which is shortly after the attack has become a heavy attack, so light attacks never make it flicker. After READY it stays full for as long as you keep charging; holding longer gains nothing from these effects, but you can of course keep charging for other reasons.

With `Display` set to `READY only` the ring stays hidden while charging and only appears at READY.

## What it tracks

Nothing is hard-coded per weapon. When a windup starts, the mod looks through your active buffs once and picks every effect whose buff template gains stacks from the game's windup trigger (`on_windup_trigger`) and has a child buff with a stack limit. Effects tied to the weapon slot you are *not* holding are ignored. This covers today's effects and any future blessing or talent built the same way:

| Source | Buff template | Max stacks | Counts when |
| --- | --- | --- | --- |
| Thrust blessing | `weapon_trait_bespoke_<weapon>_windup_increases_power_parent` | 3 | Always while charging |
| Weapon windup bonus | `windup_increases_power_default_parent` | 3 | Always while charging |
| Weapon windup bonus (three steps) | `windup_increases_power_default_three_steps_parent` | 3 | Always while charging |
| Weapon windup bonus (four steps) | `windup_increases_power_default_four_steps_parent` | 4 | Always while charging |
| Weapon windup bonus (special) | `windup_increases_special_power_default_parent` | 4 | Only while the weapon special is active |
| Weapon windup bonus (sprint) | `windup_increases_damage_on_sprint_parent` | 3 | Only on sprinting heavy attacks |
| Ogryn talent (`ogryn_fully_charged_attacks_gain_damage_and_stagger`) | `ogryn_windup_increases_power_parent` | 4 | Always while charging |

The built-in windup bonuses are part of the weapon templates `crowbar_p1_m1`, `thunderhammer_2h_p1_m1/m2`, `ogryn_hammer_2h_p1_m1`, `powersword_p3_m1` and `powersword_2h_p1_m1/m2`. Both melee windups and shield block-windups (`ActionWindup`, `ActionBlockWindup`) are supported.

An effect only counts once it has actually started stacking during the current charge. Conditional effects whose condition is not met (a sprint-only bonus on a standing heavy, a special-only bonus with the special off) therefore never hold back READY. Stacks left over from the previous attack are ignored until the game has cleared them.

### How the stacks build

The first stack is granted when the heavy attack becomes available, then one more each proc interval - 0.25 s by default, shorter on many weapons. A 3-stack effect is therefore capped two intervals after the heavy threshold, and a 4-stack effect three intervals after it. With several effects, READY waits for the slowest one.

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
| Ring size | 32 | 12-150 px radius at 1080p |
| Ring thickness | 3 | 1-10 px per segment at 1080p |
| Horizontal offset | 0 | -960 to 960 px from the screen centre |
| Vertical offset | 0 | -540 to 540 px from the screen centre |
| Opacity | 100 % | 20-100 % |
| READY pulse | On | Briefly enlarges the ring segments at READY |
| Debug output | Off | Prints charge-state transitions to chat |

The ring scales with your resolution like the game's own crosshair and ignores the HUD scale option. Disabling the mod through the standard mod toggle hides the ring and stops all tracking.

### Debug output

With `Debug output` enabled, every windup writes its transitions to your own chat, which makes it easy to check what the mod detects for a given weapon and build:

```text
[Perfect Thrust] windup action_melee_start_left: first trigger 0.50s, step 0.25s, effects: <child buff> 0/3
[Perfect Thrust] <child buff> confirmed at 1/3 after 0.62s (1 triggers)
[Perfect Thrust] READY after 1.00s (3 triggers, predicted): <child buff> 2/3
[Perfect Thrust] end (released) after 1.40s, 4 triggers, ready=true: <child buff> 3/3
```

A windup without any relevant effect logs a single `no charge-dependent effect` line. In the example above, the predicted READY lands before the third stack has arrived from the server - that gap is the network delay Predicted mode removes.

## Limitations

* **Predicted mode assumes every trigger after the first stack grants another one.** That holds for all effects listed above while their condition stays true. If a conditional effect loses its condition mid-charge - for example you stop sprinting during a sprint heavy - Predicted mode can show READY before that effect is actually capped. Use `Server-confirmed` if this matters to you.
* **Very high ping.** Effects are counted once their first stack has arrived. Above roughly 250-500 ms, a second effect's first stack may not have arrived yet when another effect is capped, which can make a predicted READY early.
* **The ring appears about one ping after the heavy threshold**, in both modes, because an effect is only shown once its first stack has arrived from the server. Its fill is already correct when it appears.
* **The ring stays at the screen centre plus your offset.** It does not follow the crosshair's small recoil and sway drift, which melee weapons barely have.
* **Only effects that stack from the windup trigger are detected.** An effect that builds while charging in some other way, or has no child buff with a stack limit, is not recognised. At most four effects are tracked per charge.
* **Ranged charging is not covered.** Plasma guns, force staves and other charged ranged weapons use a separate charge mechanic that the game's own crosshair already displays.
* **No Custom HUD integration.** Position the ring with the offset settings.
* The mod reads a few internal fields of the game's weapon actions and buffs. A game update that renames them disables the ring until the mod is updated; it does not affect gameplay.
