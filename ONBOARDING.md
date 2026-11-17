# Project onboarding and current handoff

Updated 16 November 2026. Start here together with AGENTS.md.
This is the canonical maintained handoff. Read recent PROJECT_LOG.md entries for subsequent changes.
Current delivery: feature/shelter-living-clubhouse, integrated through development_branch.
Verify the actual remote head and working tree; do not assume old conversation hashes are current.

## 1. Product and accepted direction

A Windows single-player artillery game in Godot 4.7.2 Standard, typed GDScript.
The battlefield is real 3D seen from the side; gameplay is in the XY plane.
Worms and Wild Ones inform turns, destructible environments, readable characters and playful presentation.
Wild Ones is a reference, not the game's name or permission to copy its artwork/code.
Working title: Signal Fires. Repository: https://github.com/barbarosisik/modern_worms .

The leads are **Miska and Nova, both cats and partners**. Scout is a rescued dog.
Use upright cartoon animals: oversized expressive heads, small rounded bodies and short limbs.
The owner rejected realistic bodies and approved the newer paper/wood UI.
Deliver visible, playable improvements. Distinguish inspected screenshots from manual playtesting.

## 2. Standing decisions

- Branch from current development_branch using a descriptive feature/fix name.
- Publish completed work through a PR into development_branch, merge after relevant checks,
  and verify the integrated branch. Main promotion is manual, owned by the user.
- Owner commit identity only; no assistant credit or Co-authored-by trailers.
- Keep the existing hidden local checkout outside SharePoint. Do not create competing copies.
- Preserve LMB hold/pull/release shooting, RMB cancel, MMB or Shift+LMB pan, wheel zoom and Home reset.
- Preserve imperfect CPU aiming, destructible terrain, small-step walking and saves/settings.
- Separate team upgrades from individual training; preserve outfits and fresh-run skill resets.
- Keep the two existing missions and three skirmish maps. Campaign expansion is deferred.
- Keep the accepted paper/wood UI, Fredoka type, coral actions and subdued teal backgrounds.
- Freely licensed assets only. Owner expressly allowed local-only Plumberry models under their
  no-source-redistribution license. Never force-add assets/local_plumberry.
- No multiplayer, ML opponents, new chapters or species inside visual-polish branches.
- **At every handoff:** maintain this file with actual progress, checks, limits and next tasks;
  update plan/log too, and give a copyable onboarding prompt in chat. Owner request, 16 November 2026.

## 3. Reading order and authority

1. AGENTS.md — workflow and scope.
2. Latest PROJECT_LOG.md entries — actual delivered work and validation.
3. VISUAL_ADVANCEMENT_PLAN.md — current ordered packages and detailed acceptance tasks.
4. UI_ART_DIRECTION.md — approved style and source evidence.
5. CARTOON_ASSET_SETUP.md and assets/ASSET_MANIFEST.md — setup, licenses and fallback.
6. MAP_DESIGN.md — existing larger maps and movement rules.
7. STEP_ONE.md and REFERENCE_DESIGN_RESEARCH.md — implementation history and research.
8. WILD_ONES_MVP_PLAN.md, plan.md and MECHANICS_RESEARCH.md — historical/long-term context.

Latest user instructions and current scope supersede old third-mission/ten-level plans.
Check the running build rather than repeating old completion claims.

## 4. Local setup and exact launch commands

This Windows workstation uses the following location and adjacent engine installation.
Use task-specific variables; do not repurpose system environment variables as scratch paths.

~~~powershell
$projectRoot = Join-Path $env:USERPROFILE 'Documents\Codex\.local-projects\modern_worms'
$engineRoot = Join-Path $env:USERPROFILE 'Documents\Codex\.local-projects\godot-4.7.2'
$consoleEngine = Join-Path $engineRoot 'Godot_v4.7.2-stable_win64_console.exe'
$gameEngine = Join-Path $engineRoot 'Godot_v4.7.2-stable_win64.exe'
$env:APPDATA = Join-Path $engineRoot 'runtime_data'
Set-Location -LiteralPath $projectRoot
& $gameEngine --path $projectRoot
~~~

Editor: run the same executable with --editor --path $projectRoot, or import project.godot.
project.godot is inside modern_worms, not directly inside .local-projects.
On another machine install matching Godot Standard and adjust executable paths.

Before editing check git status --short, branch, remotes and latest development head.
Preserve unrelated work. If identity is absent, use the verified owner:
Barbaros IŞIK <57237644+barbarosisik@users.noreply.github.com>.

A sandbox GUI previously disappeared after returning a PID. When asked to open the game,
launch by an available permitted native path and verify a responding window.
A PID alone is not evidence that the owner can see the game.

### Disposable shelter playtest

~~~powershell
& $gameEngine --path $projectRoot --script res://tools/preview_shelter.gd -- --stage=rescued
~~~

Use --stage=fresh for two cats before rescue; --stage=complete for both expeditions cleared.
This developer preview uses isolated settings/progress; it does not load the owner's campaign.
A/D walks Miska; E or the bottom button opens the nearby station.
Escape closes panels or opens pause. Closing a panel returns to the same walker position.
Preview scratch configurations are removed when its app exits normally.

### Character asset setup

Read CARTOON_ASSET_SETUP.md. The local folder uses maple-the-cat.glb, ollie-the-terrier.glb,
ziggy-the-wolf.glb plus source terms. Miska/Nova use the cat, Scout the smaller terrier,
opponents the wolf. Keep installed local assets; never republish them.
A clean public clone uses older CC0 Quaternius quadrupeds. This fallback runs, but is not the
approved upright silhouette. Install local models before evaluating final character proportions.
Kenney furniture/UI and Fredoka are redistributable with their included licenses.

## 5. Architecture and code entry points

| Area | Start with | Ownership / boundary |
| --- | --- | --- |
| Navigation / settings | scripts/ui/main.gd; scenes/main.tscn | Screen state, pause, settings, campaign transitions, HUD wiring. Modal screens pause gameplay. |
| Shared UI | scripts/ui/interface_skin.gd | Theme, numeric OpenType font weights, home/shelter layout. Decorations ignore mouse events. |
| Campaign data | scripts/campaign/campaign_run.gd | Missions, roster, supplies, outfits, kits, guide tiers, checkpoint. Names are not save keys. |
| Mission setup | scripts/campaign/campaign_mission.gd | Existing maps, spawns, rescue target and difficulty values. |
| Campaign panels | scripts/ui/campaign_panel.gd | Wardrobe, map, team purchases, individual training, completed-route skirmish. |
| Shelter | scripts/campaign/campaign_shelter.gd; scenes/campaign_shelter.tscn | Walking, station anchors/proximity, crew/progress display, camera/lights. |
| Shelter props | scripts/presentation/clubhouse_decor.gd | Imported architecture/furniture, palette, three station displays. |
| Characters | scripts/presentation/campaign_actor.gd | Species/models, bounds, outfits, animations/poses, weapon pivots. Cosmetics never change simulation. |
| Home preview | scripts/presentation/menu_crew.gd | Separate showcase world and lighting. |
| Match controller | scripts/match/match_arena.gd | Input/camera, simulation presentation, weapon HUD, CPU execution, effects. |
| Rules | scripts/simulation/match_simulation.gd; match_unit.gd; terrain_simulation.gd | Turns, health, movement/collision, rescue, supplies and results. |
| Terrain data | scripts/simulation/terrain_grid.gd; battle_maps.gd | 512x192 occupancy, 0.125 cell, 64x24 world, five authored layouts. |
| Terrain visuals | scripts/presentation/terrain_mesh.gd; earth.gdshader | Contours, extrusion, materials and dirty chunk rebuilds must match occupancy. |
| Scenery | scripts/presentation/battlefield.gd; water.gdshader | Premade scenery, terrain support after blasts, teal depth separation. |
| CPU / shots | scripts/simulation/computer_opponent.gd; ballistics.gd | Bounded sampled plans on isolated snapshots, physics and imperfect release. |
| Preview | tools/preview_shelter.gd | Isolated fresh/rescued/complete hub. |
| Checks | tests/*_checks.gd | Executable SceneTree suites using --script. |

## 6. Existing playable foundation

- Contoured destructible terrain, swept projectiles, walk/jump, automatic small grounded steps,
  health/knockback, water deaths, turns and local/CPU skirmishes.
- Three distinct weapons: rocket, timed bouncing grenade, short-range five-pellet shotgun.
- Three larger asymmetric skirmishes: River Outposts, Split Ridgeline, Broken Causeway.
- Two story maps: First Signal (rescue Scout), Ferry Landing. Scout joins the player queue.
- Shelter, team/individual purchases, retry, save/reopen and fresh-run reset.
- Human-only fading aiming guide, drag power, camera exploration, damage/tracers.
- Paper/wood UI, working settings, wardrobe, home showcase, selected recruit portrait.
- Stronger teal distant scenery; playable characters are not covered by a dimming overlay.

## 7. Latest shelter checkpoint: package A

Implemented:
- Orthographic cutaway framing, cream upper walls, teal wainscot, wood trim and individual planks.
- Three furnished imported-model zones behind a continuous front walking lane.
- Original two-destination schematic; distinct map, kit and paw station symbols.
- Named station anchors own proximity and furniture locations; nearby plaque highlights.
- Bottom prompt exposes purpose, bound interaction key, movement keys and a clickable equivalent.
- Nova/Scout idle poses advance separately; restrained plant sway.
- Crew cards, Scout mat, route and equipment display derive from saved CampaignRun.
- Disabled purchases explain insufficient, locked, maxed, equipped and completed states.
- Completed map offers a working solo-skirmish action; no third-mission teaser.
- Remaining uppercase old names on home and stale character setup text corrected.

Validation: shelter, interface, campaign, aim and camera suites passed.
Both mission loops pass with mouse shots, rescue, purchases, saves and retries.
Forward+ room states inspected at 1280x720 and 1920x1080; station panels inspected at 1080p.
Automated layout checks also cover the 720p station panels, including locked explanations.
Controlled inspection is not a full manual playthrough or proof of fun/balance.
**Owner visual acceptance is pending.** This is a playable art checkpoint, not final art.
Textures, bespoke prop details and character identity/poses still have room for refinement.

## 8. Next task and delivery order

Read the newest owner message first. Do not redo A because an older instruction still says to start it.

- Shelter feedback: make a narrow follow-up first and retest the station loop.
- If the owner asks to advance, that authorizes the next package; do not ask again for the same permission.
- Next package B: distinct, expressive cats. Follow VISUAL_ADVANCEMENT_PLAN.md.
- Then C: surfaces/landmarks across existing maps.
- Then D: combat effects, licensed audio/volume behavior and final UI/turn/pickup feedback.
- Mines and support abilities follow visual acceptance. Campaign expansion remains deferred.

### Package B implementation checklist
1. Audit installed rig clips and attachment transforms before assuming animations exist.
2. Differentiate Miska/Nova through default palettes plus a non-color identity cue/name treatment.
   Preserve appearance choices and upright cartoon silhouettes.
3. Match model scale, face lighting and materials across home, wardrobe, shelter and battle.
4. Define idle/walk/airborne/aim/fire/hurt/win priorities and clip fallbacks.
   One-shot reactions must finish and return to idle/walk.
5. Align weapons and muzzle positions to paws in both directions and at aim extremes.
6. Keep cosmetic motion separate from collision, damage timing and turn ownership.
7. Verify local cartoon/fallback paths, save compatibility and gameplay-scale visibility.
8. Deliver a tested playable checkpoint and update handoff, plan and log.

For C, preserve terrain occupancy/collision/mesh continuity; decorations must not bridge holes or float after blasts.
For D, preserve weapon rules and input; audio settings must affect every sound path.
Use separate descriptive branches/checkpoints, not one rewrite containing all future work.

## 9. Verification commands and evidence

~~~powershell
# First import / after adding assets or global script classes:
& $consoleEngine --headless --path $projectRoot --editor --import --quit

# Replace suite name as appropriate:
& $consoleEngine --headless --path $projectRoot --fixed-fps 60 --quit-after 12000 --script res://tests/shelter_checks.gd
~~~

Shelter/UI suites: shelter_checks, interface_checks, campaign_checks, aim_checks, camera_checks.
Other suites: terrain_lab_checks, terrain_contour_checks, match_checks, solo_checks,
supply_checks, skirmish_maps_checks, shotgun_checks, walking_checks.

Require PASS and inspect errors: Godot can exit 0 after a script error or quit-after timeout.
Inspect real Forward+ renders; headless tests cannot approve art. Use isolated saves/settings.
For UI changes test pointer navigation, disabled reasons, focus, modal stacking and input release.
For visual changes inspect both resolutions and relevant map/character states.
Scratch review captures/scripts under ignored .godot are machine-local, not guaranteed on another checkout.
Use the tracked preview for reproducible shelter inspection. Never publish restricted model sources.

## 10. Publication and handoff checklist

1. Check current development head and working tree. Preserve unrelated files.
2. Use descriptive task branch and owner identity, no assistant credit.
3. Complete authorized scope and relevant checks; record actual results/remaining limitations.
4. Publish task branch, PR into development_branch, merge and verify integrated files.
5. Leave main unchanged; no force-pushes or overwriting remote changes.
6. If native git push authenticates as barbaros-GHS and fails, the connected GitHub account
   has been the successful alternative. Do not ask the owner to repeatedly log in or print credentials.
7. Connector Git-object publication uses canonical committed bytes; remote tree must match local.
8. Exclude local_plumberry, .godot, user configs and unnecessary generated/import churn.
9. Update ONBOARDING.md, VISUAL_ADVANCEMENT_PLAN.md and PROJECT_LOG.md at every handoff.
   Update older planning entry points when they could misdirect the next agent.
10. Report achieved/pending work, evidence and an exact launch route. Give the prompt below in chat too.

## 11. Copyable next-agent prompt

You are continuing barbarosisik/modern_worms, a Godot 4.7.2 side-view 3D artillery game inspired by Worms/Wild Ones.
Read AGENTS.md, ONBOARDING.md, latest PROJECT_LOG.md, VISUAL_ADVANCEMENT_PLAN.md, UI_ART_DIRECTION.md,
CARTOON_ASSET_SETUP.md and assets/ASSET_MANIFEST.md before editing. Then inspect the running build.

Use %USERPROFILE%\Documents\Codex\.local-projects\modern_worms and the adjacent godot-4.7.2 engine.
ONBOARDING.md has exact PowerShell setup/run/test commands.
Miska and Nova are upright cartoon cats; Scout is the rescued dog.
Keep installed local Plumberry models ignored and never publish them.
Preserve names, appearance choices, saves, imperfect CPU, drag-to-fire and camera controls.

Package A shelter work is implemented as a tested checkpoint; owner visual acceptance is pending.
Inspect fresh/rescued/complete states with tools/preview_shelter.gd without changing owner progress.
Apply newest shelter feedback first. When asked to advance, implement package B: cat identity,
animation priorities/fallbacks, consistent materials/lighting/scale and weapon/paw positioning.
Then C (existing-map surfaces/landmarks) and D (combat/audio/UI feedback), one tested delivery at a time.
Do not redo A blindly or expand the current two missions/three skirmish maps.

Use a descriptive branch from current development_branch and preserve unrelated changes.
Run relevant suites, require PASS without script errors, and inspect Forward+ at 1280x720 and 1920x1080.
Use isolated saves and distinguish controlled captures from manual playtests.
Publish completed work through a PR into development_branch and verify integration; main releases are manual.
Use owner git identity without assistant attribution.
At every delivery/handoff update ONBOARDING.md, the visual plan and PROJECT_LOG.md, and give a current
copyable onboarding prompt in chat. Complete the authorized work; ask concise questions only for unresolved
material product choices, continuing independent work while waiting.
