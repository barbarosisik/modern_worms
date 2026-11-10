# Step one: a recognizable playable game

Approved to begin on 10 November 2026. Branch: `feature/stylized-first-playable`.
Wild Ones is an experience reference, not the game's name. Signal Fires remains a working title.

This cumulative first delivery prioritizes the presentation and usability tasks from the larger MVP plan. It does not claim all 221 tasks or the eight-tool/three-mission MVP are complete.

| Order | Work selected from the MVP plan | Delivery check |
| --- | --- | --- |
| 1 | FLOW-03/06/07/08/10: campaign access | Direct map access in the shelter, next-mission label, explicit two-mission content limit, continuation regression check. |
| 2 | ART-02/04/06/07/08: premade assets | Licensed imported humans, dog, scenery and weapons; credits and source manifest; animations under the actual camera. |
| 3 | WORLD-01/02/03/05 and GROUND-01/05/07 | Stylized forest/lake depth, earthy terrain and grass surface, imported props whose support is rechecked after destruction. |
| 4 | CAM-01/02/03 and AIM-03/04/05 | Readable battle framing, zoom/refocus, pull tether and power feedback, right-click cancellation, frozen camera during drag. |
| 5 | WEAPON-08, FX-01/02/03 and UI-01/02 | Recognizable rocket/grenade assets, clickable weapon selection, trails/impact feedback and compact HUD. |
| 6 | QA-03/04, PLAY-01/02/03, BUILD-05 | Import and behavior suites, Windows rendered checks and screenshots, updated log and tested development integration. |

Retain current campaign saves, both existing missions, the two current weapon behaviors, 12/15/18/20 guide tiers, pickups and CPU rules. The next delivery adds weapon behavior variety and mission three after this visual/control foundation is reviewed. Keep unfinished larger-plan tasks unchecked.

## Handoff checkpoint

This branch is a work in progress based on `development_branch` at `5edc51f`. Complete the table in order and record the actual results in the project log. Keep the branch separate until the slice is playable and tested.

- The first-mission continuation problem was reported by the owner. The existing `campaign_checks.gd` suite passed on the baseline with an isolated save, including the first-to-second transition. The exact reported failure remains unreproduced. The current build contains two missions. Make the route through the shelter obvious and explain the content boundary.
- Premade humans, animation clips, skins, Scout, props and weapon models are imported. See [asset manifest](assets/ASSET_MANIFEST.md). `campaign_actor.gd` has a first implementation of imported actors and weapon presentation. Check rig transforms, animation playback, outfit readability, facing, feet placement and weapon alignment in Forward+ before treating this as finished.
- `battlefield.gd`, `earth.gdshader` and `water.gdshader` are drafted. Integrate the battlefield into `scenes/match_arena.tscn` and `scripts/match/match_arena.gd`. Hook its terrain dressing to match reset and its support update to actual craters. Give the terrain mesh distinct grass and exposed earth surfaces using authoritative occupancy. The current scene still contains the old water, projectile and impact presentation. The photo is still connected to the main scene.
- Implement shelter map access and completion messaging in `main.gd`, `main.tscn` and `campaign_panel.gd`. Preserve the existing checkpoint and exercise both missions through normal controls and a relaunch.
- Finish camera framing/zoom/refocus, drag tether/cancel, weapon selection and combat effects in the match scene and HUD. Keep the human guide, pickup ownership and simulation results consistent. Review at 1280 × 720 and 1920 × 1080. Inspect campaign wardrobe, battles, shelter and result screens.
- Godot headless import and the existing campaign suite passed at the handoff with the imported actor code. Run all six behavior suites and a Windows rendered playthrough after wiring the scene. Add focused checks for new input/navigation paths. Record which checks actually passed.

## Finish and continue

1. Check the live feature branch and save-safe baseline. Finish campaign navigation and the visual battle slice before adding a mission.
2. Review the revised look and controls in playable matches. Update this file and `PROJECT_LOG.md` with concrete results and limitations.
3. Integrate the tested feature through a PR to `development_branch`. Keep release to `main` as a separate owner approval.
4. Resume [the detailed MVP plan](WILD_ONES_MVP_PLAN.md). Prioritize four polished weapons with shotgun and mine, then the larger arsenal and CPU tactics. Build Through the Pines with a second rescue and Scout's support action as part of the three-mission MVP. Continue toward ten missions after the three-mission loop passes review.
