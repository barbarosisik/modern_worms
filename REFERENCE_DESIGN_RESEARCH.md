# Cartoon artillery: reference findings and delivery plan

Updated 2026-11-16. Wild Ones is a reference, not the final game name. This document complements WILD_ONES_MVP_PLAN.md and STEP_ONE.md; it does not replace the larger campaign plan.

Owner revision, 16 November: defer campaign expansion and improve the existing maps first. MAP_DESIGN.md records the map references, larger layouts and walking changes delivered after this document's original checkpoint. Earlier requests for mission three are superseded for current development.

## Evidence and limits

- [Team17's WMD development retrospective](https://www.team17.com/news/team17s-100-games-part-seventeen-2016-overcooked-worms-w-m-d-and-more): the developers describe returning to Armageddon's mechanical foundations while changing scale and presentation. They describe authored terrain pieces and templates rather than relying solely on a repeated texture and edge fringe. This supports an authored environment pipeline for our next art milestone.
- [Worms WMD official product page](https://www.team17.com/games/worms-w-m-d): weapons, buildings and vehicles give a battlefield several kinds of tactical interaction. For our small single-player game, prioritize distinct weapon decisions and cover before vehicles or crafting.
- [Wild Ones fan gallery](https://wildonesgames.com/wild-ones-gallery/): inspected the Hot and Spicy map screenshot. Visible features include separate ledges, a central landmark, bright walkable edges, darker terrain interiors, a quieter distant background and compact unit markers. The archive is a secondary visual reference, not an authoritative source for original damage or AI formulas. Its video links were discovered, but full videos have NOT been watched; no frame-by-frame gameplay analysis is claimed.
- [Original Armageddon manual archive](https://ftp.zx.net.nz/pub/archive/ftp.team17.com/pub/t17/manuals/Worms_Armageddon.pdf): retrieved the index identifying weapon selection, time/wind/team displays, crates and training. The complete manual was not reviewed. Do not treat it as proof of undocumented mechanics.

No reference artwork has been copied into game assets. Scratch reference images remain ignored. Recommendations below are our design decisions, not claims about the originals' exact implementation.

## What makes the current build feel unfinished

1. Rounded geometry alone does not create a finished environment. Terrain still has broad plain earth bands, repetitive trees and too little authored detail. Grass edges remain grid-influenced.
2. At the default camera scale, character expressions and weapon silhouettes are small. Camera framing needs a deliberate readability pass.
3. The arsenal needs tactical roles, not many reskins. Three behaviors now exist; area denial is still missing.
4. Better reactions need a complete anticipation, shot, hit, recovery and victory sequence, plus sound. Current recoil, trails and damage numbers are only a foundation.
5. Two story missions do not satisfy the planned ten-level campaign. Progression must be tested through actual mission transitions, not hidden behind a cosmetic chapter list.

## Delivered in this checkpoint

- Contoured/extruded terrain rendering replaces exposed cell cubes. Rounded initial platforms and neighboring-chunk rebuilds keep craters coherent.
- Imported oak canopy geometry is subdivided and softened with cached meshes. Reduced background density and lighting contrast; water no longer receives detached black shadows.
- Third weapon: a short-range five-pellet shotgun. Pull distance tightens spread; damage falls with distance. Cover and the first unit block each pellet, including allies. It can collect supplies but does not carve terrain.
- CPU evaluates shotgun outcomes using isolated simulation snapshots and retains execution error.
- Projectile trails, short shotgun tracers, floating damage numbers, hit reactions and weapon-specific recoil.
- Three clickable weapon buttons, number-key selection and contextual tooltips. Mouse hold/pull/release remains the primary firing control; right-click cancels.
- Reduced explosive crater radii after opening-turn probes exposed excessive early elimination. Eight deterministic opening probes improved, but this is not a completed balance study.

## Next delivery: authored forest battlefield and fourth tactical weapon

### A. Environment and readability first

1. Establish one forest style sheet: rounded silhouettes, controlled palette, readable bright walking surface, quieter background, consistent material scale.
2. Select free licensed prefabs for rocks, roots, stumps, bridges and shelter props. Record origin and redistribution terms before adding files. Keep restricted Plumberry sources local according to CARTOON_ASSET_SETUP.md.
3. Build three reusable landmark arrangements, each with distinct cover and movement decisions. Place them on the existing three skirmish layouts rather than duplicating decorative clutter.
4. Separate decoration from collision. Remove unsupported props after blasts; never let a visually empty space block a shot.
5. Review default camera framing at 1280x720 and 1920x1080. Active animal, weapon, aim guide and target health must remain readable; preserve zoom and drag-camera locking.
6. Capture normal battle views and a cratered battlefield. Compare composition, surface detail and readability with references, without copying their assets.

### B. Mine behavior and feedback

1. Define placement range, arming delay, trigger radius, explosion damage, inventory and friendly-fire policy in data.
2. Add placement preview, cancel, legal-position checks and visible armed state.
3. Resolve triggers during movement and explosions; guard against duplicate damage and endless chain reactions.
4. Teach CPU to avoid known mines and value area denial without knowledge of hidden information.
5. Add meaningful tests: trigger ownership, ally interaction, terrain removal and chain termination.

### C. Complete the presentation loop

1. Add licensed launch/impact/UI audio with independently working volume controls.
2. Connect available hurt/celebration animations and clear turn-start/end cues; retain an obvious skip/reduced-motion path where effects delay play.
3. Distinguish weapon icons, status effects and supply types using shape as well as color.
4. Play a complete match using only mouse aiming and on-screen weapon selection. Check pause, retry and settings in the same session.

### D. Then deepen existing maps and roster abilities

1. Playtest and tune routes, cover and pickups across the existing three skirmishes and two mission maps. Keep the existing rescue and shelter transitions working; do not add a third mission yet.
2. One readable support ability per species before adding more species. Keep team upgrades and individual upgrades separate.
3. Keep the ten-level outline deferred until the owner resumes campaign expansion. Improve enemy decisions without granting perfect aim.
4. Continue appearance selection, saved rescue state and new-run skill reset checks.

## Acceptance and branch workflow

Run relevant simulation, aiming, terrain and campaign checks. Inspect real Forward+ renders and record what was actually played. Automated checks cannot establish that the game is fun. Publish on feature/stylized-first-playable, integrate tested work through development_branch, and keep main behind owner approval. Do not report the full MVP, final art or ten-level story complete while these sections remain unfinished.
