# Modern Worms mechanics research

Research snapshot dated 9 November 2026. The project goal is an original 2D artillery game whose movement, firing, impacts, and turn rhythm can be tuned independently of the character design. This is a public-source baseline for behavioral reverse engineering. Exact PC reference values remain a measurement task.

## Which Worms game fits?

| Reference | What it explains |
| --- | --- |
| **Worms Across Worlds (2025)** | The newest released turn-based Worms title identified in the official series history. It launched on Apple Arcade on 7 August 2025 and includes a campaign and local multiplayer. The listing describes weapon unlocks. The in-match coin shop in the brief remains unverified for this title. [Official series history][history] · [Apple launch][across-launch] · [App Store listing][across] |
| **Worms W.M.D. (2016)** | The working reference for classic 2D artillery on PC. It combines alternating team turns and destructible land with crafting, vehicles, buildings, and a classic-style rope. Team17 describes adapting the *Armageddon* physics feel and retuning for a different scale. Its documented in-match upgrade system uses ingredients and dismantling. [Steam release][wmd-steam] · [Team17 retrospective][retrospective] · [Crafting reveal][crafting] |
| **Worms Revolution (2012) and Worms Battlegrounds (2014)** | Stronger leads for collecting coins and buying weapons during a match. For *Revolution*, contemporary player reports describe collecting coin crates and spending in the weapon-panel shop. For *Battlegrounds*, a community achievement guide documents a purchase and the coin-crate setup. The official series history links *Battlegrounds* to *Clan Wars*. Mode and platform matter. [Revolution publisher page][revolution] · [Contemporary coin reports][revolution-coins] · [Battlegrounds shop evidence][battlegrounds-shop] · [Official series history][history] |
| **Worms Reloaded (2010)** | A direct match if the remembered money came from completing single-player missions and was spent later. The publisher lists weapons and other unlocks that can be purchased with campaign-earned currency. [Steam listing][reloaded] |
| **Worms W.M.D. Mobilize (2023) and Worms Armageddon: Anniversary Edition (2024)** | A mobile adaptation of *W.M.D.* and a modern console edition of the older *Armageddon*. The detailed Mobilize guide is useful for generating PC tests. Team17 explicitly lists crafting as absent in Mobilize. [Mobilize guide][mobilize] · [Official series history][history] |
| **Worms Rumble (2020) and announced projects** | *Rumble* uses real-time combat and its earned coins purchase customization. *Galactic Tactics* is an announced 3D turn-based roguelike listed for 2027. Team17 also announced a separate classic-style *Worms* project in development. [Rumble FAQ][rumble] · [Galactic Tactics listing][galactic] · [Team17 announcement][announcement] |

The exact title in the brief is uncertain. Start by measuring *W.M.D.* on Steam PC for the combat model and compare *Revolution* or *Battlegrounds* for the economy. The movement limit in a classic scheme is most plausibly the turn clock. Treat a literal movement-point budget and money awarded at the end of each multiplayer round as open product decisions. [Mobilize guide][mobilize] · [Armageddon PC manual, playing the game and game options][armageddon]

## Documented behavior and evidence limits

| System | Public evidence | What to confirm on the Steam PC reference |
| --- | --- | --- |
| Turn loop | *W.M.D.* is turn-based across teams. Mobilize documents a turn clock, a round clock, and rising water in sudden death. The *Armageddon* manual describes optional unit selection, retreat timers, and waiting for bodies and mines to stop moving. | Team order and within-team rotation, rules for skipping eliminated units, when a turn clock stops, and handoff timing after a delayed hit, self-damage, or timeout. |
| Movement | Mobilize documents walking, two jump types, and midair directional influence. The *Armageddon* manual describes walking, jumps, and a scheme with movement disabled. | Walk speed, reversals, step and slope limits, jump profiles, midair steering, fall damage, when aiming and shooting are allowed, and whether any action ends movement before the clock does. |
| Weapons | Mobilize documents charged shots, wind affecting some items, timed fuses, targeted strikes, melee, movement utilities, and a firearm with two shots per turn. The *Armageddon* manual separately documents wind-sensitive rockets and fuse/bounce settings for some grenades. | Per-weapon wind response, angle bounds, charge curve, muzzle position, projectile collision size, fuse presets, grenade restitution, owner collision, and behavior when the fuse or impact happens on the same frame as another event. |
| Terrain and damage | The desktop listing describes changing terrain by attacks and tunneling. Mobilize documents death by depleted health or drowning, exploding barrels, and proximity mines. Team17 patch notes show that weapon parameters, object behavior, and schemes changed during updates. | Crater dimensions and clipping, thin ground and overhangs, blast shielding, damage versus distance, knockback direction and strength, fall damage, death timing, and what happens on a last-team trade. |
| Pickups and inventory | Team17 documents ingredients from crafting crates, dismantling stock, and crafting during opposing turns in *W.M.D.* A historical patch removed crafting crate drops from its Pro/Ranked scheme and adjusted starting materials. In-match coin purchases have separate supporting evidence for *Revolution* and *Battlegrounds*. | Which scheme permits each drop, pickup eligibility while moving or airborne, when contents enter inventory, and when crafting/purchases become usable. Separately test wallet ownership and round/match resets in the economy reference. |

Sources for the table by role. Use the desktop listing and patches for desktop claims, the official mobile guide for mobile rules, and the original manual for documented classic options. [W.M.D. on Steam][wmd-steam] · [Mobilize guide][mobilize] · [Armageddon PC manual][armageddon] · [Liberation patch notes][liberation] · [W.M.D. v1.2 patch notes][patch] · [Crafting reveal][crafting] · [Revolution coin reports][revolution-coins] · [Battlegrounds shop evidence][battlegrounds-shop]

The public sources establish player-visible features and several historical changes. Gravity, simulation rate, collision masks, the damage curve, and event order for the selected PC build remain unknown. The model below is a proposed independent implementation. Use observed gameplay, original fixtures, and derived measurements as inputs.

## Proposed first simulation

### Turn ownership and time

Use two local teams with two units each, one hand-built test map, and a visible turn clock. Keep team order and each team's unit rotation as separate cursors. Store stable team and unit IDs, skip dead units and empty teams, and keep inactive units physically responsive to damage and falling. The initial round can use one attack action per turn. Later weapons can define several stages within that action, such as a two-shot attack or a remote trigger.

| Phase | Inputs and transition |
| --- | --- |
| `turn_start` | Choose the next eligible team and unit, load the turn timer, and set any per-turn wind. Enter `active`. |
| `active` | Accept movement, jump, aim, charge, weapon selection, fire, and pass from the active team. The selected attack consumes its stock once at commit and changes the accepted inputs. Timeout or pass starts resolution. Start with a time limit as the movement constraint. |
| `retreat` | If the action and scheme permit, accept only retreat movement for the short retreat window while the world continues to simulate. End on window expiry, loss of the active unit, or any tested interruption rule. |
| `resolve` | Process pending projectiles, fuses, explosions, falls, and eliminations. Keep the same attack turn open while consequential motion or delayed events remain. Static hazards can persist into the next turn. |
| `turn_end` | Evaluate surviving teams after the action resolves. Advance the queue and apply scheduled turn-boundary changes, or finish the round. Use a draw as the first rule for simultaneous elimination. |

Define one stable event order for equal ticks, including fire at timeout, fuse at impact, contact with water, chain reactions, and kills that occur during retreat. Keep the retreat rule, early turn loss from damage, wind-change timing, and match scoring configurable until observed or decided. Test settling with consecutive ticks under a speed threshold, a grounded/contact test, and a check for unresolved fuses. Define escape rules for out-of-bounds projectiles so a turn can finish even when a shot leaves the arena.

### Movement and mutable ground

Use a side-view world with fixed simulation units, positive Y upward, and a fixed simulation step independent of render FPS. Record time in ticks and keep physics units consistent. A prototype rate such as 60 ticks per second is a tuning choice. The renderer reads simulation state, so unit art, screen resolution, zoom, and animation frames can change without changing collision geometry.

- Give units a small stable collision shape and grounded/airborne movement states. Walking should probe support and clearance, permit a bounded step up, and drop a unit into free fall when support disappears. Use horizontal input and initial jump impulses, then tune air control, landing, and fall damage separately.
- Start with an occupancy mask as the terrain authority. Clear cells in a configurable blast footprint. A mask represents overhangs, tunnels, and isolated islands, which a single height per column cannot represent. Projectile sweeps, unit support checks, and terrain rendering should all see the same terrain revision. Use local dirty regions when updating collision/render data. Define the behavior of isolated terrain explicitly and include a fixture with a disconnected island.
- Sweep moving projectiles between tick positions and pick the earliest contact, with a stable tie rule for terrain and unit hits. Specify collision behavior at spawn, when firing adjacent to a wall, and when moving through a narrow crater edge. Use the same technique or bounded movement steps for fast unit knockback.
- Treat water and world bounds as explicit rule surfaces. The first map needs a lethal lower boundary and clear rules for side or top escape. Add water rise or dynamic water only if a later scheme requires it.

### Projectile and blast model

Build a wind-sensitive impact rocket and a timed bouncing grenade. Together they exercise precision, charge, wind, bank shots, delayed damage, terrain removal, and post-fire timing.

- Convert normalized charge `q` to launch speed with a tunable function `speed(q)`. Start with `v0 = speed(q) * (cos(angle), sin(angle))` and a muzzle offset from the unit origin. For the first flight model use `accel = (wind * wind_response, -gravity)`, update velocity by `accel * dt`, then sweep to the next position using that velocity. Fit the charge curve and per-weapon wind response from separate trials.
- Detonate the rocket on its first qualifying impact. For the grenade, let the fuse run during flight, bounce, and rest. Reflect the incoming normal velocity at contact with a restitution factor and damp the tangential component with friction. Snap tiny bounces to rest using an explicit threshold. Test grazing collisions and impacts on corners and slopes.
- For each detonation, record the blast center, candidate units, and distances. Use independent parameters for crater size, damage, and impulse. An initial radial damage curve can use `max_damage * clamp(1 - distance / damage_radius, 0, 1)` with explicit rounding. Try directional impulse with its own falloff and define a reproducible upward fallback for zero distance. These formulas are starting hypotheses. Use direct-hit, near-edge, shielded, and equal-distance fixtures to choose target behavior and when the terrain revision is sampled for line of sight.
- Apply the event once and update the terrain and affected bodies before subsequent events. Queue secondary explosions and elimination effects in stable order. Measure damage from the blast separately from subsequent fall or drowning. Use the same event path for self-hits and friendly fire when the scheme permits them.

### Economy as a separate layer

Keep weapon stock, health pickups, and currency as distinct data. For the first complete match, use team ammunition and a simple optional pickup. A later economy branch can compare an in-match team wallet, post-round rewards inside a match, and persistent unlocks. Decide which of these the design needs after observing the source behavior and testing the basic combat.

For an in-match shop, specify spawn timing and weights, who can collect during active or knockback states, wallet scope, allowed purchase phases, and stock availability after a purchase. A pickup grants its reward once. A purchase checks turn and item eligibility and funds, then debits the wallet and grants the item as one operation. Decide explicitly what resets between turns, rounds, and matches. Crafting can use separate ingredient and recipe rules if selected. Keep all resource grants and spends in the simulation event log so test replays can reproduce them.

### Simulation boundaries

Store the map, scheme, ordered teams, weapon definitions, random seed, and a tick-stamped input stream with a replay. Keep authoritative turn time and randomness inside the simulation. Compare repeated outcomes in the same runtime using turn-end snapshots, including units, health, terrain digest, inventory, and pending events. Cross-platform determinism and networking can be evaluated once the local rules are stable. Use original placeholder geometry, names, and maps in the prototype.

## Reference measurement plan

1. Pin a playable Steam PC *W.M.D.* build, platform, local scheme, map, controls, viewport, and capture frame rate. Use a fixed local map and two human-controlled teams so AI or network timing stays out of the capture. Prefer a flat calibration strip, a known slope, a wall, a ledge, and an open drop. If the reference map cannot be controlled precisely, use reproducible starts and document the uncertainty.
2. Capture high-frame-rate video with fixed zoom and camera when possible. Otherwise track static landmarks to remove camera motion. Use seconds and a reference unit width or calibrated world scale. Label screen pixels as screen pixels. Record the first visible response, input duration, and dropped or duplicate frames. Repeat at least three times for each condition and report the median and range. Use more trials for random drops.
3. Fit parameters on some observations and validate on held-out shots and map layouts. For flight, track projectile centers on unobstructed frames and fit `x(t)` and `y(t)` before collision. Compare apex, flight time, and impact position. Separate charge duration, aim, and wind. Fit the grenade's pre/post-contact velocity on a flat surface before trying angled walls. Sample blast HP changes at controlled distances and read crater width and depth from aligned before/after frames.
4. Record edition, build, map, scheme, trial, action timing, aim, charge, wind, coordinates and units, frame timestamps, HP changes, observed event order, and uncertainty for every fixture. Keep source observations, fitted parameters, and prototype tuning in separate fields. Tag observations as documented, measured, inferred, or proposed.

| ID | Controlled experiment | Record |
| --- | --- | --- |
| `TURN-01` | Use two units per team. Pass, time out, fire with a fuse, lose the active unit, then eliminate a team. | Activation order, clock transitions, when control ends, retreat window, last motion and handoff frames, and round result. |
| `MOVE-01` | Walk across flat ground, slopes, and steps. Jump from flat ground with no input and with left/right air input. Repeat after a controlled drop. | Speed, acceleration, walkable rise, takeoff and landing positions, jump apex/time, air-control effect, and fall-damage threshold. |
| `SHOT-01` | Fire rockets at several held charge times and angles, in calm or comparable wind and then opposing wind. Repeat toward a thin wall and at close range. | Launch speed curve, apparent gravity, wind response, first-hit ordering, and camera-corrected trajectories. |
| `SHOT-02` | Bounce grenades on level ground and a slope, including a grenade that stops before its fuse expires. | Fuse origin and presets, rebound normal and tangential speed, resting threshold, and detonation location. |
| `BLAST-01` | Detonate at direct hit, several offsets, behind a wall, and underneath a unit's ledge. Include a self-hit and a drop into water. | Crater geometry, HP delta, launch vector, shielding, loss of support, fall damage, drowning, and resolution order. |
| `CHAIN-01` | Start with an explosive object beside the target, then repeat with both teams' last units in range. | Chain timing, settlement condition, simultaneous elimination behavior, and next turn or result. |
| `LOOT-01` | In a coin-enabled *Revolution* or *Battlegrounds* scheme, collect a crate, spend part of the balance, and progress through the next turn, round, and match. Compare with an ingredient pickup in *W.M.D.* | Pickup size and recipient, where purchases happen, funds and stock timing, and each reset boundary. |

## Prototype acceptance checks

1. Two teams complete a local match. Only the current side can issue battle commands. Dead units leave the rotation, and an elimination caused by a late event is resolved before the winner or draw is declared.
2. A charged rocket and a timed grenade use visibly distinct rules. Changing wind changes the rocket trajectory as configured. A timed grenade can bounce and explode at rest. A fast shot collides with a thin wall between ticks.
3. A crater changes later walking and projectile collision on the same map. Removing support causes a fall. A near miss and a direct hit can produce different HP and displacement. A fall into the lethal boundary can eliminate a unit independently of HP.
4. An attack spends stock once and the next team cannot act before the previous action settles. Cover timeout during charge, early self-elimination, no-hit shots that leave the arena, and a delayed explosive that hits both teams.
5. Replay the same inputs and seed in the same runtime under different render rates. Turn-end snapshots agree. After reference capture, add measured comparison bands for launch speed, impact position, bounce, crater size, damage, and handoff timing based on the uncertainty of the measurements.

Once those checks pass, compare an economy-enabled match and a basic match with the same combat rules. Rope, vehicles, buildings, larger weapon catalogs, procedural maps, AI, and online multiplayer can be scoped after the first local match establishes the feel.

[history]: https://www.officialworms.com/history
[across-launch]: https://www.apple.com/uk/newsroom/2025/07/apple-arcade-launches-four-new-games-in-august/
[across]: https://apps.apple.com/us/app/worms-across-worlds/id6475792950
[wmd-steam]: https://store.steampowered.com/app/327030/Worms_WMD/
[retrospective]: https://www.team17.com/news/team17s-100-games-part-seventeen-2016-overcooked-worms-w-m-d-and-more
[crafting]: https://www.team17.com/news/worms-w-m-d-crafting-reveal
[revolution]: https://www.team17.com/games/worms-revolution
[revolution-coins]: https://steamcommunity.com/app/200170/discussions/0/613958868358677725/
[battlegrounds-shop]: https://achievementguides.com/guides/worms-battlegrounds#big-spender
[reloaded]: https://store.steampowered.com/app/22600/Worms_Reloaded/
[mobilize]: https://www.team17.com/news/worms-w-md-mobilize-out-now-on-apple-android
[rumble]: https://www.team17.com/news/worms-rumble-faq
[galactic]: https://store.steampowered.com/app/3278930/Worms_Galactic_Tactics/
[announcement]: https://www.gamespress.com/en-US/INCOMING-THE-WORMS-ARE-RETURNING-IN-A-BRAND-NEW-ADVENTURE-IN-WORMS-GAL
[armageddon]: https://ftp.zx.net.nz/pub/archive/ftp.team17.com/pub/t17/manuals/Worms_Armageddon.pdf
[liberation]: https://www.team17.com/news/worms-w-m-d-liberation-update-available-now
[patch]: https://www.team17.com/news/worms-w-m-d-update-v1-2
