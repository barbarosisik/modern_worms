# Modern Worms project log

## 2026-11-09 | Research baseline

- Completed the release and mechanics comparison. [Mechanics research](MECHANICS_RESEARCH.md) records the source evidence, the proposed simulation model, the measurement protocol, and the acceptance scenarios.
- Selected the Steam PC release of *Worms W.M.D.* as the first physics reference. *Worms Across Worlds* is the newer released turn-based entry identified in the official series history. Use *Revolution* and *Battlegrounds* to investigate in-match purchasing. Use *Reloaded* to distinguish campaign-earned currency from in-match funds.
- Recorded the first milestone as a side-view, two-team local match with temporary shapes, timed movement and aim, destructible ground, and two complementary projectiles. Gameplay code and hands-on calibration are pending.
- At the research baseline, open decisions included the final characters, movement meter versus turn timer, economy and reset rules, and engine/platform. The combat simulation should work with neutral `unit`, `team`, and `weapon` concepts so the final theme can be chosen separately.

## 2026-11-09 | Godot and development plan

- The owner chose Godot for the project. The first build targets Windows using Godot 4.7.2 Standard and typed GDScript. The scene renders in real 3D from the side while the simulation runs on one vertical plane.
- Added [the development plan](plan.md). It defines six milestones and gives M1 a branch, scene and script names, a reference fixture, controls, and acceptance checks. M3 is the first complete match against the computer.
- The first implementation task is `feature/destructible-terrain`. Its fixture checks that a rocket destroys a ledge, the target loses support, and an identical shot passes through the opening. The initial physics settings are prototype inputs pending reference measurements.
- The owner authorized this planning update directly on `main`. Development work resumes through the task branch workflow below.

## Branch workflow

1. `main` holds the approved baseline. Bring the planning update into `development_branch` before starting M1. Fast-forward when the branches share that baseline and `development_branch` has no independent work.
2. Start each later task from the current `development_branch`. Use a scoped branch name such as `research/reference-measurements`, `feature/turn-simulation`, `feature/destructible-terrain`, or `fix/projectile-collision`.
3. Push each task branch and open its pull request against `development_branch`. Multiple task branches can be integrated there. Run the relevant checks on the combined development head and record the exact commit and results in this log.
4. Open a pull request from `development_branch` to `main` after integration testing. Merge it after the repository owner approves the tested changes. Subsequent work goes through task branches and pull requests.
5. Use descriptive commit subjects and the repository owner's configured GitHub identity. Keep assistant attribution and co-author trailers out of commits and project files.

## 2026-11-09 | M1 terrain lab and menus

- Built the playable lab on `feature/destructible-terrain` from the planning baseline `742b591`. The project opens to a main menu with Start terrain lab, Settings, and Quit. Pause freezes the active simulation and offers Resume, Settings, and Main menu.
- Added the lab HUD, manual aim and charge, the repeatable shot, reset, and a collision outline. Fullscreen and master volume apply in the running game and save locally. Firing and impact play audible cues.
- Verified with Godot 4.7.2 Standard on Windows. The Forward+ run rendered the home, settings, pause, and arena views and switched between fullscreen and windowed. The first rocket struck the ledge at approximately `(12.00, 6.67)` and dropped the target. The same shot reached the rear wall at `(24.00, 4.97)`.
- The headless checks covered repeatability, thin-wall and corner sweeps, neighbor chunks, projectile escape, reset during flight, manual firing, the collision overlay, pause and resume, and loading settings in a new game instance. These are fixture values for M1. Reference calibration and the complete solo match are separate milestones.

## 2026-11-09 | M2 local match

- Built `feature/turn-simulation` from `fa8c80c`. **Play local match** starts a two-team match on one keyboard. Each side has two units, 30 seconds per turn, and a choice of a wind-sensitive rocket or a timed grenade. The turn advances after the shot and moving units settle. Eliminated units are skipped.
- Units walk, jump, aim, take blast damage and knockback, and are eliminated in water. A crater immediately changes collision and what can support a unit. The HUD shows turn, team health, wind, weapon, and charge. Pause and settings work in both modes. The match ends with a winner or draw and a rematch option. The terrain lab remains accessible from the main menu.
- Controls are A and D or Left and Right to move, W to jump, Q to face the other way, Up and Down to aim, 1 and 2 to select a weapon, hold and release Space to fire, P to pass, and Escape to pause.
- Verified on Godot 4.7.2 Standard for Windows. Both headless suites passed. In a Forward+ run at 1280 × 720, the opening rocket damaged the far team and cut a crater, control passed to the next surviving unit, and a match reached its result using only regular inputs. Rematch restored the original arena, clock, and units.
- The physics values are prototype tuning. The next gameplay milestone is the computer opponent, and comparison against the Steam reference remains open.

## 2026-11-09 | M3 solo match

- Built `feature/solo-opponent` from `946483d`. **Play vs Computer** gives Blue to the player and Orange to the CPU. Local play and the terrain lab remain available. A solo rematch starts with a fresh arena and preserves solo mode.
- The opponent uses a bounded rule-based search. It checks short walks on a copy of the current arena, samples angles and charge for rockets and grenades, then resolves its best candidates through the real combat rules. Its score rewards enemy damage, eliminations, and lost footing, with a penalty for damage or lost footing on its own side. A boxed-in unit can pass.
- The match shows when the computer is choosing, moving, and aiming. Its shots use the same launch parameters, wind, collision, and turn resolution as player shots. Pause freezes its actions, and player combat input is disabled on the CPU's turn.
- Godot 4.7.2 passed the solo, local match, and terrain lab headless checks. A Windows Forward+ run began at the main menu, observed the CPU walk and fire a grenade, reached an Orange victory through normal match rules, and started a fresh solo rematch.
- The solo MVP uses one arena and one CPU difficulty. Prototype balance and reference measurement remain open.

## 2026-11-09 | M3a mouse aim and CPU balance

- Built `feature/mouse-aim-and-cpu-balance` from `9ca4110`. The cursor maps onto the combat plane. Hold the left mouse button or Space to charge and release to fire. Power ticks one point at a time from 0 to 100 and back. Keyboard aim and facing still work. Pause, focus loss, and turn expiry cancel the held shot.
- Blue sees six fading dots based on the selected weapon, current charge, terrain, and wind. Orange plays without dots in both solo and local matches. The terrain lab can cycle through 6, 9, 12, 15, and 18 dots with G. Earned character upgrades are an M4 task.
- The rule-based CPU considers short safe walks and fewer shot samples, scores three finalists, and can choose among near-equal options. It commits one angle and charge error per shot. The starting bounds scale from ±2° and ±3 percentage points at four world units to ±13° and ±32 points at eighteen. Near the top of the power meter, a late release loses power. The CPU rejects forecast allied eliminations and passes when it cannot find a useful attack.
- On the stock arena after Blue passed, the previous CPU's opening removed 100 Blue HP. The revised CPU averaged 41.3 Blue HP damage across 24 seeded runs. Four shots did no Blue damage and one removed 100 HP. The boxed-in CPU passed on all 24 seeds, and the close one-on-one fixture with a one-HP target ended in an Orange win on all 24. These are fixture results. Solo playtesting will determine the final charge pace and difficulty.
- Verified in Godot 4.7.2 on Windows with the terrain lab, match, solo, and aim headless suites. A seeded stock-arena run let Blue pass, observed the CPU walk and win, and started a clean rematch. In a Forward+ run at 1280 × 720, verified the six-dot match guide, the 18-dot lab tier, the power percentage, and GUI clicks during a match.

## 2026-11-09 | M4 drag aiming, supplies, and arena backdrop

- Built `feature/drag-aim-pickups-and-arena` from `6a61fbb`. Mouse aim and power now come from pulling back from the click point. Pull farther for more power, shorten the pull to reduce power, and release to fire. A short click cancels. Space keeps the keyboard charge behavior.
- Raised the base Blue guide from six to twelve dots after playtesting feedback. The lab previews caps of 12, 15, 18, and 20. Terrain can shorten the visible path.
- Added one supply at a random supported site between sufficiently separated living opponents. If the slot is empty, the match tries again at the start of the next full round. The active unit, a rocket, or a grenade can collect it by crossing it. Projectiles keep going after collection and respect cover. Both teams use the same rules and show their supply count in the HUD. Supplies reset on rematch.
- Added a Lake Chelan photo behind the 3D playfield. Courtesy of North Cascades National Park Service Complex. [Photo and rights](assets/backgrounds/CREDITS.md)
- Verified five headless suites in Godot 4.7.2 on Windows. The Forward+ check confirmed pull-back input, HUD power, both guide lengths, and the photographic backdrop at 1280 × 720.
- Added the draft *Signal Fires* campaign to [the plan](plan.md). It follows two customizable human lovers through ten increasingly difficult rescue levels. Rescued friends and pets join the queue after the leads. A walkable shelter connects the map table, team upgrades, and per-character upgrade tabs.

## 2026-11-09 | M6 playable Signal Fires chapter

- Built `feature/signal-fires-first-chapter` from `b42c129`. The title screen opens New Story and Continue Story alongside skirmish and the Terrain Lab. Mara and Eli have selectable jacket colors and live 3D previews.
- **First Signal** requires walking to Scout and defeating the lookout. Either order works. The rescue moved into the first mission so Scout can take a full turn in **Ferry Landing**. The second mission adds a wider battlefield, stronger wind, and two more accurate opponents. Turn rotation now follows the living members of each side's roster.
- The ranger shelter has a map table, a supply bench, and a roster board. Walk to a station and press E or click its prompt. Two supplies are earned on each clear, plus what the rescuers collect in combat. The bench sells a team field kit for +15 starting HP, and the board has individual trajectory training for Mara, Eli, and Scout.
- A local checkpoint stores chapter progress, supplies, training, the kit, and outfits. Retry uses the saved loadout and a fresh battlefield. New Story starts progress and upgrades over with the selected outfits.
- Verified both missions with real drag shots, the rescue before and after the lookout falls, Scout's turn, team and individual purchases, save and reload, retry, and the new-story reset. Checked the wardrobe, arena HUD, shelter, and roster in Windows Forward+.

## 2026-11-10 | Wild Ones direction and proposed MVP overhaul

- The owner confirmed **Wild Ones** as the intended reference and rejected the current visual quality and limited campaign experience. The current two-mission slice is a mechanics prototype, not the requested polished game.
- Inspected `development_branch` at `bb82258d307a1ba78e3061298a27d458c448e971`. The campaign contains only First Signal and Ferry Landing and intentionally stops after two clears. A separate report of being unable to continue after the first mission is still un-reproduced; diagnosis is the first proposed implementation task.
- Added [WILD_ONES_MVP_PLAN.md](WILD_ONES_MVP_PLAN.md) on `docs/wild-ones-mvp-plan`. It defines stable task IDs, dependencies, branches, asset selection and licensing, terrain/collision work, controls, eight tools, CPU tactics, ownership, saves/migration, three mission layouts, supporters, upgrades, UI/settings, validation and release criteria. The full ten-level campaign remains a separate explicitly tracked deliverable after the polished three-mission MVP.
- Retained the owner's human lovers, rescue supporters, individual/team progression, 12-to-20-dot guide and pull-back aiming. Wild Ones is the primary gameplay/presentation reference; replacing the leads with animals has not been requested.
- Proposed replacing the photographic background and geometric actors with a cohesive asset-based world. Asset packs remain candidates pending a real-camera visual and animation check; no assets were bought or imported in this documentation change.
- Updated the old plan to point to the new proposed delivery order. This publication changes documentation only; no gameplay fix, additional mission or visual overhaul is claimed. Validation is limited to document structure, references, task/dependency consistency and the three-file diff.
- Gameplay implementation is paused pending the owner's revisions or explicit **go**. The documentation goes through the existing task-branch workflow into `development_branch`; `main` requires separate owner approval.

## 2026-11-10 | Step One work in progress and handoff

- The owner approved starting the cumulative first delivery. [STEP_ONE.md](STEP_ONE.md) prioritizes campaign navigation, a stylized battlefield built from premade assets, readable characters/weapons, camera and aim feedback, and a compact combat HUD. Signal Fires remains a working title. Wild Ones is the reference.
- Started `feature/stylized-first-playable` from `5edc51f`. The baseline campaign check reached both existing missions. The reported block after the first mission remains unreproduced. Direct shelter map access and honest content labels are pending.
- Imported selected Kenney and Quaternius models with sources in the [asset manifest](assets/ASSET_MANIFEST.md). Reworked the actor wrapper for imported humans, Scout and separate animation clips. Drafted arena dressing and earth/water shaders. Scene wiring, camera/HUD work and rendered verification remain pending.
- Godot headless import and the existing campaign suite passed after the actor change. The branch is a handoff checkpoint. Finish and test it before integrating into `development_branch`.

## Next session

- [ ] Continue the existing feature branch using [STEP_ONE.md](STEP_ONE.md). Finish campaign access, wire the art into both battles, and complete the camera, aiming feedback and HUD.
- [ ] Run the Godot behavior suites and a rendered Windows playthrough. Save evidence and update this log before integrating the feature into `development_branch`.
- [ ] Follow the remaining priorities in [WILD_ONES_MVP_PLAN.md](WILD_ONES_MVP_PLAN.md), beginning with the four-weapon checkpoint. Expand the campaign after the visual and combat foundation is playable.

For each new log entry, record the date, branch or commit, completed work, verification performed, open questions, and the next concrete action.


## 2026-11-15 — animal cast, integrated battlefield and skirmish variety

Resumed `feature/stylized-first-playable` from published checkpoint `523888c`. Verified the staged checkpoint tree matched the fetched remote before aligning the local branch; retained new working edits. No main changes.

Owner explicitly selected an all-animal cast. Imported licensed Quaternius cat/wolf models alongside the existing dog. Added animation selection, idle-pose sizing and per-surface coat tinting; preserved names, story relationship, save version, roster order and progression. Corrected the dog's initial floating/undersized placement by measuring its animated idle pose in Forward+ and storing those bounds for consistent headless rendering behavior.

Connected forest/lake scene, soil/grass shader and destruction-aware scenery; equipped guns, projectile meshes and imported supply crate. Added right-click cancellation, mouse-wheel zoom/Home reset, drag-camera lock, pull tether, clickable weapon buttons, direct shelter map access and truthful two-mission end message. Added three selectable skirmish layouts with supported unit spawns. No extra weapon behavior or species skill is claimed yet.

Validation: terrain_lab, match, solo, aim, supply and campaign suites passed after integration. Expanded aim checks cover cancellation/zoom locking/reset; campaign reopening uses the new MapShortcut. New skirmish_maps suite passes for all three layouts, supplies and CPU plans. Windows Vulkan Forward+ wardrobe and battle screenshots reviewed at 1280x720. Rendered review found/fixed dog placement and excessive background/water contrast. Temporary screenshots/source archive live only under ignored `.godot`. Original user save paths were not overwritten by tests.

Next: four-weapon behavior slice (shotgun/mine), animal support abilities, third story mission and rescue, combat feedback and full manual resolution/balance review. Exact priorities and acceptance scope in STEP_ONE.md. Full eight-tool/ten-level vision is unfinished.


## 2026-11-15 — surface appearance test handoff

Owner requested less pointed geometry and believable-looking surfaces, with a playtest before more feature work. Replaced the battle's pointed pine silhouettes with imported broad-canopy oak models; removed oversized faceted mountain silhouettes. Added CC0 ambientCG soil/moss color and normal maps to terrain, including newly exposed crater faces. Physics occupancy and gameplay remain unchanged. Added imported-canopy normal smoothing. Source details are in assets/ASSET_MANIFEST.md.

This is a local visual revision awaiting owner testing. Existing low-poly animal models and grid-defined ground silhouettes still need further art work; this does not claim a final art direction. Pause implementation after launching the test build. Collect feedback on surface scale, angular silhouettes, readability and aiming before proposing the next delivery.


## 2026-11-15 — cartoon direction correction

Owner rejected the realistic surface direction and requested a unified cartoon style inspired by Wild Ones. Photographed ground materials are now disconnected; terrain uses clean warm earth bands and green turf, with toon shading. Broad-canopy scenery and animals use toon diffuse lighting, water is brighter and non-metallic, and the home/shelter photo backdrop is replaced by a flat palette background. Added presentation-only breathing, walking bounce/squash and recoil on top of animal clips. Collision and trajectory physics remain unchanged.

Rendered battle checked in Forward+; match behavior suite passes. This is a local style iteration for owner testing, not final character art. Animal models retain their current quadruped anatomy: expressive faces, exaggerated cartoon proportions, bespoke rigs and polished UI are still pending. Await visual feedback before further feature expansion.


## 2026-11-15 — mouse regression correction and character-art rejection

Owner reported mouse firing no longer worked and rejected the remaining realistic animal bodies. Root cause: the newly created full-screen ColorRect backdrop kept its default mouse filter and intercepted pointer events. Set it to MOUSE_FILTER_IGNORE and added a regression assertion; aim_checks passes, including drag/release shot behavior. Space was an existing fallback, not an intended replacement.

The current quadruped meshes are not accepted cartoon character art. Shading and squash/bounce do not satisfy the requested silhouette change. Before further presentation work, confirm upright oversized-head animal proportions versus exaggerated quadrupeds, source appropriate licensed models/rigs, and review the actual character silhouette at gameplay scale. Do not report this art requirement as completed.


## 2026-11-15 — upright cartoon preview and local asset workflow approved

Owner approved upright cartoon animals with oversized heads, small rounded bodies, short limbs and expressive eyes, then explicitly approved keeping free source-restricted models local while publishing code/setup instructions. Plumberry Plains Vol. 1 replaces the local cat/dog/wolf presentation. The pack is free for commercial games but is NOT CC0: its raw source files cannot be redistributed. assets/local_plumberry/ is ignored; CARTOON_ASSET_SETUP.md documents reproducible installation and the older CC0 fallback for fresh clones.

Rendered wardrobe and battle previews inspected in Forward+. Aim, match and campaign behavior suites passed with the upright models installed. Mouse drag is retained; backdrop mouse interception remains fixed. Current adapter supports idle/walk/run/jump and weapon recoil. Additional facial/impact/celebration reactions and final character/weapon pose polish remain pending, as does owner visual acceptance. No new gameplay scope before the requested playtest.

## 2026-11-16 — contoured terrain, shotgun and combat feedback

Owner requested reference research and automatic implementation after the cartoon preview. See REFERENCE_DESIGN_RESEARCH.md for sources, evidence limits and ordered next acceptance tasks.

Implemented rounded platform layouts and marching-squares terrain caps with extruded boundaries and neighboring-chunk refresh. Softened imported oak canopy geometry, cached generated meshes, reduced backdrop density/lighting contrast and disabled water shadows. Added a third distinct weapon: five-pellet short-range shotgun with spread control, damage falloff, terrain/unit interception, friendly fire and projectile supply collection. CPU evaluates the actual behavior on isolated snapshots. Added tracers, projectile trails, floating damage numbers, hit reactions, recoil and three selectable weapon buttons. LMB hold/pull/release and RMB cancellation remain intact.

Reduced rocket/grenade blast radii after eight opening-turn probes exposed overly lethal starts. This changes damage reach as well as crater size; maximum damage is unchanged. Updated the campaign shot fixture for the new radius and replaced a brittle one-seed miss assertion with a 16-seed hit/miss distribution check.

Validation: terrain_lab, terrain_contour, match, solo, aim, supply, campaign, skirmish_maps and shotgun suites passed. Rendered Forward+ battle inspected at 1280x720, including a controlled shotgun-hit fixture showing tracers and 33 damage. A 1920x1080 capture was generated; this does not constitute a full manual playthrough at both resolutions. Terrain tests compare dirty rebuilds to full rebuilds and check a crater stays visually open. Shotgun checks cover falloff, cover, range, allies, turn ownership and CPU snapshot isolation. Tests use isolated saves.

Still pending: authored environment landmarks and finer surfaces, camera/readability polish, mine behavior, audio, complete character reactions, species abilities and mission three. Terrain grass is still grid-influenced; this is a measurable gameplay/presentation checkpoint, not final art or the complete MVP. Next delivery is detailed in REFERENCE_DESIGN_RESEARCH.md. Restricted local model sources remain excluded from publication. Feature branch only; main unchanged.

## 2026-11-16 — character visibility and opening camera

Owner requested only a slightly dimmer background, a closer opening view toward their characters and visible zoom instructions. Darkened distant tree colors by 12% and sky/water colors by 10%; foreground characters, terrain, lighting and mechanics retain their existing values. Battle opening FOV is now 23 degrees instead of 27, with horizontal framing toward the player's team. Home restores that opening view. Added a persistent mouse-transparent HUD hint: wheel up zooms in, wheel down zooms out, Home resets.

Validation: aim_checks and campaign_checks passed. Aim checks cover opening player visibility, the non-blocking zoom hint, zoom in/out, drag locking and reset to the new camera. Forward+ opening views inspected at 1280x720 and 1920x1080, including First Signal at 720p. No other gameplay or content changes. Next planned work remains authored environment landmarks/surfaces, mines, audio/reactions, species abilities and mission three; these were not started in this revision. Published on the existing feature branch for owner testing.

## 2026-11-16 — map camera panning

Added camera exploration requested by the owner: middle-mouse drag or Shift + left-mouse drag grabs and moves the map horizontally/vertically. View-centre bounds keep exploration within the 32 x 16 gameplay area. Panning, zoom and Home reset work during human turns, CPU turns and shot resolution. Camera controls stay locked while aiming; pan gestures cannot start a shot. Drag releases remain captured across HUD crossings and Shift release. Pause, focus loss, Home and new matches clear an active pan. Updated the visible HUD instructions.

Validation: camera_checks, aim_checks and solo_checks passed. New camera suite exercises world-point tracking, revealing an off-screen enemy, map limits, both pan gestures, GUI/aim ownership, CPU/resolving access and cancellation. Reviewed a Forward+ 1280x720 capture after dragging to the enemy side. This revision changes camera navigation and its hint only; no weapons, characters, art, balance or campaign content changes. Feature branch publication; main still awaits owner approval.
