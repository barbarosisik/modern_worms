# Modern Worms project log

## 2026-11-09 | Research baseline

- Completed the release and mechanics comparison. [Mechanics research](MECHANICS_RESEARCH.md) records the source evidence, the proposed simulation model, the measurement protocol, and the acceptance scenarios.
- Selected the Steam PC release of *Worms W.M.D.* as the first physics reference. *Worms Across Worlds* is the newer released turn-based entry identified in the official series history. Use *Revolution* and *Battlegrounds* to investigate in-match purchasing. Use *Reloaded* to distinguish campaign-earned currency from in-match funds.
- Recorded the first milestone as a side-view, two-team local match with temporary shapes, timed movement and aim, destructible ground, and two complementary projectiles. Gameplay code and hands-on calibration are pending.
- Open decisions include the final characters, movement meter versus turn timer, economy and reset rules, and engine/platform. The combat simulation should work with neutral `unit`, `team`, and `weapon` concepts so the final theme can be chosen separately.

## Branch workflow

1. The initial research delivery seeds `main`. Base `development_branch` on that initial research baseline.
2. Start each later task from the current `development_branch`. Use a scoped branch name such as `research/reference-measurements`, `feature/turn-simulation`, `feature/destructible-terrain`, or `fix/projectile-collision`.
3. Push each task branch and open its pull request against `development_branch`. Multiple task branches can be integrated there. Run the relevant checks on the combined development head and record the exact commit and results in this log.
4. Open a pull request from `development_branch` to `main` after integration testing. Merge it after the repository owner approves the tested changes. Subsequent work goes through task branches and pull requests.
5. Use descriptive commit subjects and the repository owner's configured GitHub identity. Keep assistant attribution and co-author trailers out of commits and project files.

## Next session

- [ ] On `research/reference-measurements`, confirm access to a playable Steam PC build. Record its build ID, local scheme, map, units, capture settings, and input method before collecting measurements.
- [ ] Capture the turn sequence, time-limited movement, ballistic trajectories, crater and damage profiles, and settlement timing using the research protocol. Record repeatability, estimated error, and unresolved behavior. Save derived measurements and original fixture data with the project.
- [ ] Pin the first prototype's turn rules and physics parameters. Resolve the movement-budget question with the owner if the reference and desired feel differ. Keep economy work separate until the basic combat loop has been played end to end.
- [ ] Pick the prototype runtime against the simulation needs. Implement and integrate the turn, movement, terrain, projectile, and damage slices on focused branches. Validate the complete local match on `development_branch` before seeking approval for `main`.

For each new log entry, record the date, branch or commit, completed work, verification performed, open questions, and the next concrete action.
