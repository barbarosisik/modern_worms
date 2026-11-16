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


## 15 November continuation: animal cast and playable battle integration

Owner decision: **make the whole cast animals**. This supersedes human-lead visual requirements in this file and earlier plans. Mara is currently a cat, Eli and Scout dogs, and the salvage opponents wolves. Names, relationship, roster order and save schema remain compatible. Species choices are an initial implementation, not a locked final roster.

Delivered in this continuation:
- Battlefield scenery and water are wired into match reset. Battle uses a color environment instead of the photo; the photo remains in home/shelter.
- Earth shader, grass surface, imported scenery, terrain-support checks after blasts.
- Imported animated animal cast throughout wardrobe, shelter and matches; equipped weapon models, recoil, projectile models, supply crate model.
- Mission-map shortcut in shelter and explicit two-mission completion message.
- Right-click cancels a pull without firing on later release; visible pull tether and power text; mouse-wheel zoom and Home framing reset; camera zoom freezes while dragging.
- Clickable rocket/grenade buttons with tooltips. Their two existing behaviors remain unchanged.
- Three selectable skirmish terrains: River Outposts, Split Ridgeline, Broken Causeway. Campaign terrain remains fixed.
- Seven passing headless suites, including new skirmish terrain checks and expanded input/navigation checks. Forward+ captures reviewed for battle and wardrobe at 1280x720. No claim of full manual balancing or 1920x1080 review.

### Next delivery, in priority order
1. Four tactically distinct weapons: retain rocket/grenade, add short-range shotgun and persistent proximity mine. Define damage, falloff, terrain effect, ammo, friendly fire, turn resolution and preview rules before coding. Test cover occlusion, close shots, mine placement/trigger ownership, and CPU evaluation.
2. Animal identity: species-specific support abilities with visible cooldown/use limits; model attachment and turn portraits; retain visual customization separately from stats. Avoid automatic accuracy bonuses for CPU. Ask the owner about preferred personality/style if needed.
3. Third mission, Through the Pines: authored terrain with alternative routes, a new animal rescue, the rescued ally joining turn order, clear map unlock and compatible save migration. Do not imply an unbuilt level is available.
4. Combat readability: short projectile trails, damage feedback, impact sound/VFX, selected-weapon state and ammo display, camera framing across resolutions, clearer team markers on animals.
5. Broader progression: team versus individual upgrades, enemy archetypes, and three-mission tuning before expanding to ten. Skills reset on a new story; cosmetics remain selectable.

Still unfinished from the initial slice: projectile trails, final UI/art polish, complete rendered playthrough at both target resolutions, manual fun/balance review, and development integration. This is improved playable work, not completion of the larger MVP.


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
