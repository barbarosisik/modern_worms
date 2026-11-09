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

## Next session

- [ ] Start `feature/destructible-terrain` from the current `development_branch`. Verify the Godot editor and renderer on Windows, then build and run the ledge fixture in the plan.
- [ ] Record the repeat-shot, chunk boundary, and reset checks. Test M1 on `development_branch` after integration. Record the exact commit and any fixes still needed.
- [ ] On `research/reference-measurements`, confirm access to the Steam PC reference and record its build ID, scheme, map, and capture setup. Collect measurements for turn handoff, movement, shot arcs, and impacts before tuning M2. Save derived measurements, repeatability, and uncertainty with the project.
- [ ] Decide whether the turn clock alone supplies the desired movement constraint. Revisit the economy and original character direction once the match can be played end to end.

For each new log entry, record the date, branch or commit, completed work, verification performed, open questions, and the next concrete action.
