# Visual advancement handoff: Miska and Nova
Updated 19 November 2026. Implementation handoff for the next agent.
Packages A and B are tested playable checkpoints. Package C is next, followed by D and separate gameplay deliveries.
This is the current visual priority order. Historical plans remain context, not permission to expand scope.

## Product and preserved decisions
Miska and Nova are the two cat leads and partners. Scout remains the rescued dog.
Use upright, expressive cartoon animals, oversized heads and soft shapes. Wild Ones is a genre/art-direction reference, not the game's name or a source of reusable art.
Keep the newly approved paper/wood UI, Fredoka typography, coral actions and subdued teal backgrounds.
The owner likes this UI direction but wants a substantially better shelter and a more coherent game.
Preserve the two existing missions and three skirmish maps. No new campaign chapters.
Preserve drag-to-fire (LMB hold/pull/release), RMB cancel, camera pan (MMB or Shift+LMB), wheel zoom and Home reset.
Keep imperfect CPU aiming, destructible terrain and small-step walking.
Keep separate team and individual upgrades, appearance choices and fresh-run skill resets.
Only freely licensed assets. Raw Plumberry sources stay local/ignored under the existing explicit exception; never publish them.
Do not reset user saves or settings. Existing saves use roster indices, so the new lead names do not require a migration.

## Read and inspect before editing
1. AGENTS.md, latest PROJECT_LOG.md entries, this file.
2. UI_ART_DIRECTION.md: accepted interface language and existing source evidence.
3. CARTOON_ASSET_SETUP.md and assets/ASSET_MANIFEST.md: local setup, fallback and redistribution boundaries.
4. MAP_DESIGN.md, then STEP_ONE.md and REFERENCE_DESIGN_RESEARCH.md for history.
5. WILD_ONES_MVP_PLAN.md for long-term vision only; campaign expansion stays deferred.
6. Run the current build; inspect home, wardrobe, First Signal, shelter and all three stations.
7. Read scripts/campaign/campaign_shelter.gd, scripts/presentation/clubhouse_decor.gd,
   scripts/presentation/campaign_actor.gd, scripts/presentation/menu_crew.gd,
   scripts/ui/interface_skin.gd, scripts/ui/campaign_panel.gd and scripts/ui/main.gd.
8. Before terrain work read scripts/presentation/battlefield.gd, terrain_mesh.gd,
   earth.gdshader, water.gdshader and scripts/match/match_arena.gd.
Use rg to find simulation/profile ownership before changing terrain; visuals must not become a second collision model.

## Existing checkpoint versus remaining work
Implemented: licensed furniture shelter, animated home previews, shared UI theme, stronger teal scenery,
three weapons, five larger asymmetric maps, contoured destructible terrain, camera navigation,
two-mission rescue/shelter/upgrade loop and automatic small steps.
Renamed leads and cat model selection apply to story, menus, shelter and battle, including fallback assets.
The shelter has three furnished stations and save-aware crew and progress displays.
The cat leads have distinct outfits and poses, and the upright actors grip equipped weapons at paw sockets.
New owner feedback on these checkpoints can be handled in a focused follow-up.
Basic generated audio exists; this is not a completed licensed audio pass.
No claim that visual polish, balance or the full MVP is finished.

## Delivery order and boundaries
A: shelter composition and interaction (first playable delivery).
B: cat identity and animation consistency.
C: terrain surfaces and landmarks across existing maps.
D: combat feedback, sound and final UI cohesion.
Continue with C and D as separate playable deliveries.
Mines and support abilities follow visual/readability acceptance; they are separate gameplay work.
Do not add chapters, online play, ML opponents or new species during these packages.

## A. Shelter checkpoint implemented; owner review next

Completed in feature/shelter-living-clubhouse: cutaway framing, wall/floor/trim surfaces, three imported furnished
zones, shared station anchors, original route/crew/kit displays, highlighted proximity plaques and bound-key
action prompts, modal input handling, living crew poses, saved progress details and completed-route skirmish.
Added isolated tools/preview_shelter.gd and shelter_checks.gd. Shelter/interface/campaign/aim/camera suites passed.
Inspect fresh, rescued and complete states before further visual changes. This is an implemented checkpoint,
not a claim of final art or owner acceptance. Original A1-A6 acceptance specification below remains for review.
Suggested branch: feature/shelter-living-clubhouse.
Goal: a cozy cutaway ranger clubhouse with three unmistakable stations, visible cats and an obvious next action.
Keep side-view walking and current station functions. Improve the room, not just its panel colors.

### A1. Baseline and composition
- Capture current shelter at 1280x720 and 1920x1080, before and after rescuing Scout.
- Record camera framing, character height on screen, station positions and blocked sightlines.
- Establish three zones: left expedition/map table, central supply workbench, right crew/portrait corner.
- Keep the walkable lane visibly continuous. Tall objects stay behind it; avoid foreground furniture hiding paws or faces.
- Start with current station coordinates (-4.6, 0, 4.55) and interaction radius 1.25.
- If moving a station improves composition, change its visual location and interaction anchor together.
- Prefer named station anchors over duplicated magic coordinates; use one source for marker and proximity checks.
- Make the camera show the full walkable lane and all three functional destinations at both resolutions.
Acceptance: a screenshot without UI labels still shows three different work areas; no actor is concealed by scenery.

### A2. Room surfaces and furnishing
- Reuse licensed Furniture Kit assets first. Inspect proportions before introducing new packs.
- Remove obvious wall seams, stretched floor appearance and floating/intersecting furniture.
- Add a coherent floor treatment, base trim and window framing from compatible premade assets.
- Use large readable forms: map/tools on table, supply crates or kit on workbench, portraits/cards at roster corner.
- Replace the blank map paper with an original schematic of the two existing destinations, not a newly promised campaign.
- Add small personal touches for two cats: paired mugs/cushions or shared photo, using licensed assets where available.
- Limit decorative density. Props should explain the room or fill a specific composition gap.
- Preserve the continuous walking lane; decorative geometry must not introduce unexpected movement obstacles.
- For new assets record creator URL, exact license, retained files and scale/material adjustments in ASSET_MANIFEST.
Acceptance: no prop visibly floats, cuts through a cat or blocks a station; surfaces hold up in normal gameplay view.

### A3. Lighting, depth and motion
- Warm interior key light, quieter cool window background; avoid bright windows behind cat faces.
- Keep face/coat colors readable and preserve both cats against walls/furniture.
- Use restrained contact shadows where supported; check the actual Forward+ renderer rather than headless output.
- Add at most a few subtle ambient motions (plant movement, lamp glow or distant weather), with shared timing ownership.
- Keep motion behind actors and avoid flashing or permanent camera movement.
- Compare before/after at normal exposure; reject changes that make furniture attractive but characters harder to find.
Acceptance: both cats immediately visible, no blown-out light fur, no distracting flicker; record screenshots.

### A4. Station discovery and interaction
- Show a small persistent shape/icon for each station, with only the nearby station emphasized.
- On approach show its name, purpose and actual bound interact key plus a clickable action.
- Preserve keyboard interaction and existing StationAction behavior; click and key invoke the same action path.
- Opening a panel stops shelter movement/input; closing returns to the same place and restores input once.
- Do not let station UI clicks trigger movement, shots or a second activation underneath.
- Keep disabled upgrades legible and explain why (insufficient supplies, maxed, unavailable).
- Mark next mission clearly without a giant overlay hiding the room.
Acceptance: test entry, walk to each station, open/close with pointer and keyboard, repeat without stuck input.

### A5. Crew presence and progress
- Miska walks; Nova occupies a readable resting/work spot. Scout appears only after rescue.
- Give stationary actors valid idle poses; avoid synchronized identical motion where possible.
- Add a small visible rescue/progress change (Scout's place, one pinned completed-mission card).
- Derive changes from CampaignRun; do not create a parallel progress save.
- Keep the finished two-mission state honest: replay/skirmish options, no locked third mission teaser.
Acceptance: fresh run, rescued state and completed state render correctly after save/reopen.

### A6. Validation and handoff for A
- Extend interface/campaign tests only for meaningful station/input/progress behavior.
- Run interface_checks, campaign_checks, aim_checks and camera_checks.
- Manually inspect both resolutions and all three shelter states using isolated saves.
- Walk from end to end, interact repeatedly and return to battle; verify mouse firing and pan still work.
- Record changed files, asset licenses, screenshots and what was manually tested in PROJECT_LOG.
- Commit/publish feature branch, merge tested work into development_branch, verify integrated head.
- Provide owner an actual tested launch command; do not claim a game window opened without verifying it.
- Stop for owner visual feedback after A; do not silently implement B-D in the same delivery.

## B. Distinct cat leads and weapon poses

Delivered on feature/cat-character-polish. Miska retains the warm coat. Nova has a cooler
base coat and an original bow that follows the head. The existing wardrobe tints apply over
each lead's base appearance. The home and wardrobe use similar lighting, with a small shared
fill on the upright faces. Battle labels identify the leads and retain the active turn arrow.

- Upright rigs: loop idle/walk. Play jump, pain and celebration once. Arm posing handles aim
  and fire. Hurt interrupts a held pose, then the character returns to the current locomotion.
- Rocket, grenade and shotgun follow the paw nearer the camera. The long guns face up the aim
  line on either side. Recoil retains the weapon and direction at release.
- The older CC0 rigs use idle/walk, small procedural reactions and an approximate weapon mount.
- Victory plays while the result panel owns the pause. All motion is cosmetic.

Validation: character presentation, aim, match, campaign, interface, shelter, camera, solo and
shotgun suites passed. The headless presentation suite checks both facings, aim limits,
muzzle clearance, reactions and recovery. A fresh public asset fixture passed presentation
and match checks. A short scripted 720p Forward+ run opened the wardrobe and a skirmish, selected
the shotgun, jumped and fired by dragging. The wardrobe and aiming views were inspected.
Owner art review remains open.

## C. Battlefield surface and landmark pass
Suggested branch: feature/battlefield-surface-polish. Depends on established palette.
1. Preserve all five larger terrain layouts, physics occupancy, destructibility and two-cell step behavior.
2. Start with River Outposts as a material/landmark pilot; compare terrain to the actual collision boundary.
3. Refine earth.gdshader/material treatment: broad soil layers, gentle variation and readable grass edge.
   Avoid noisy tiling or pixel-small details. No opaque grass carpet bridging a real hole.
4. Maintain terrain_mesh chunk seams and excavation continuity; blast holes must visibly remain open.
5. Place a small number of recognizable premade landmarks at tactical regions; support must come from terrain.
6. Separate distant silhouettes, midground scenery and playable terrain using contrast, scale and tint.
   Do not dim characters to make backgrounds quieter. Reuse the approved stronger teal atmosphere.
7. Give each existing map a related but distinct identity:
   River Outposts: riverbank camps and broken posts;
   Split Ridgeline: rocky high ground and woodland hollows;
   Broken Causeway: ruined crossing with separated banks;
   First Signal: ranger post/rescue landmark;
   Ferry Landing: dock/boat-route markers.
8. Decorative landmarks have no invisible collision. Any proposed new cover belongs in a separate simulation change.
9. After blasts remove unsupported decorations without leaving floating trees, grass sheets or light patches.
10. Check near view, maximum zoom-out, both ends of map and crater-heavy scenes.
11. Measure frame time and terrain rebuild cost on the same machine before/after; record measurements, not guesses.
Acceptance: terrain still predicts walk/shot collision, maps differ visibly, and scenery does not hide enemies or supply pickups.
Validation: terrain_lab, terrain_contour, skirmish_maps, walking, camera and supply suites; inspect all five maps.
Do not shrink maps or change weapon reach to disguise an art/readability problem.

## D. Feedback, sound and UI completion
Suggested branch: feature/combat-presentation-pass. Depends on B/C stable presentation.
1. Build a compact weapon feedback specification for rocket, grenade and shotgun: icon, held silhouette, muzzle/launch,
   travel, impact and unique sound. Keep existing damage, range and turn rules unless separately approved.
2. Use brief readable impact effects; debris is cosmetic, pooled/bounded and does not hide aiming or damage numbers.
3. Add clear selected-unit/turn-start cues, health change, pickup collection and victory/defeat feedback.
4. Replace or complement generated tones with compatible freely licensed effects; retain attribution/license files.
5. Route audio through buses so master volume and mute affect every sound; only add separate category sliders if implemented end-to-end.
6. Prevent duplicate sounds from overlapping event paths; test simultaneous shotgun hits and quick retries.
7. Preserve shared paper/wood UI; improve icon consistency, spacing, tooltips and disabled/focused states rather than redesigning it.
8. Keep decorative layers mouse-transparent. Test dragged aim/camera release across HUD and modal boundaries.
9. Provide reduced-motion control if adding screen shake/flashes; default effects restrained and never compulsory delays.
10. Inspect small text, focus navigation, overlay stacking and Continue layout at both resolutions.
Acceptance: player can tell who acted, what weapon fired, what was hit and what reward arrived without reading debug output.
Validation: affected simulation/input/UI suites, audio volume/mute manual check, full two-mission loop and one skirmish.

## Later gameplay work, deliberately separate
After visual acceptance: implement one mine with arming/trigger/friendly-fire rules and CPU awareness;
then one support ability per relevant character/species with visible cooldown/cost and balanced CPU use.
Define those mechanics and tests before coding. Do not turn a visual branch into weapon/balance/campaign expansion.

## Definition of done for every delivery
- Re-read latest owner feedback before applying old plans.
- Descriptive feature branch from current development_branch; no edits/pushes to main.
- Existing behavior preserved, relevant checks pass, visuals actually inspected.
- Use isolated saves and a brief in-game check of the changed behavior. Capture only what helps.
- Record implemented versus pending separately, include honest visual/performance limitations.
- Public repository contains only redistributable assets. Local restricted model setup documented.
- Owner commit identity, no assistant credit; PR into development_branch and integrated verification.
- Give concise achieved/remaining report and specific owner playtest route.

## Copyable next-agent instruction
Use the maintained prompt in [ONBOARDING.md](ONBOARDING.md#11-copyable-next-agent-prompt).
Read AGENTS.md and the latest PROJECT_LOG first. A and B are implemented. Take the newest owner
feedback, then continue with C from development_branch. Start with River Outposts and compare the
visible ground to collision, including a crater. Main promotion remains manual.
Maintain ONBOARDING.md, this plan and the log at every handoff and provide the prompt in chat.
