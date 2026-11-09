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

## Next session

- [ ] On `research/reference-measurements`, confirm access to the Steam PC reference and record its build ID, scheme, map, and capture setup. Collect measurements for turn handoff, movement, shot arcs, and impacts before tuning M2. Save derived measurements, repeatability, and uncertainty with the project.
- [ ] For M3, start `feature/solo-opponent` from the integrated local-match baseline. Let the CPU use the same turn clock, movement, aim, and weapon rules. Give its shot search a time limit and cover blocked shots, skipped turns, and rematches.
- [ ] Decide whether the turn clock alone supplies the desired movement constraint. Revisit the economy and original character direction once the match can be played end to end.

For each new log entry, record the date, branch or commit, completed work, verification performed, open questions, and the next concrete action.
