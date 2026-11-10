# Wild Ones-inspired MVP implementation plan

Date: 10 November 2026

Status: Proposed for owner review. Publishing this document does not authorize gameplay implementation. Wait for revisions or an explicit **go**.

Inspected baseline: `development_branch` at `bb82258d307a1ba78e3061298a27d458c448e971`.

Planning branch: `docs/wild-ones-mvp-plan`.

### Reading guide

Start with sections 1-4 for scope, baseline and delivery order. Sections 5-14 are the implementation backlog, section 15 is verification, section 16 is the release gate, and sections 17-20 cover risks, the full campaign and the first session after approval. Task IDs are unique and remain stable during review.

## 1. What we are making

A Windows single-player artillery game in Godot: colorful, expressive characters take turns moving, selecting tools, aiming and altering a destructible battlefield. **Wild Ones is the primary experience reference.** The player should enjoy finding a good firing position, choosing an unusual weapon, making a satisfying shot and adapting to the resulting destruction.

Use actual 3D characters, scenery, lighting and terrain depth viewed from the side. Gameplay remains on one vertical plane. Use premade art assets selected for a consistent style; replace the photographic background and primitive character presentation. Preserve the useful simulation already built, while changing the presentation and interaction wherever they fail the playtest.

The desired outcome is recognizable genre quality: readable silhouettes, playful weapon designs, varied tactical maps, responsive controls, strong audiovisual feedback and meaningful choices. An increased mission count alone is not completion.

This document takes precedence over the old milestone ordering in [plan.md](plan.md). [MECHANICS_RESEARCH.md](MECHANICS_RESEARCH.md) remains historical reference material; its W.M.D-first approach is no longer the product direction. [PROJECT_LOG.md](PROJECT_LOG.md) records implementation history and future evidence. An unchecked task below is planned, not shipped.

### 1.1 Requirements already supplied by the owner

- Godot, Windows first, single-player against CPU opponents.
- 3D presentation with side-view movement and combat.
- Wild Ones as the main inspiration for overall quality, character expression, weapons and maps.
- Use compatible premade characters, objects, weapons and environment assets.
- Mouse pull-back aiming: click, hold, drag to set direction and power, release to fire. Greater drag distance means greater power. Keep the existing opposite-drag convention unless playtesting changes it.
- Human player's guide starts at up to **12 fading dots** and upgrades through **15, 18 and 20**. CPU and the opposing local player do not display this assistance.
- Collect supplies by walking through them or passing an owned projectile through them. Random placements should be between sufficiently separated opponents.
- Keep the two customizable human lovers, Mara and Eli, and the rescue campaign unless the owner changes this choice. Confirming Wild Ones as the reference does not automatically replace them with animals.
- Friends and pets are recruited through rescue, join the player's turn order after the leads, and have individual progression.
- Separate team and individual upgrade screens, with character tabs, in a walkable shelter between levels.
- Ten increasingly challenging missions in the complete campaign. Larger maps must add useful routes and tactical situations.
- A new story resets skills, campaign money and recruitment; cosmetic preferences and settings may persist. A new mission within the same story does not reset earned upgrades.
- Task branches feed `development_branch`; `main` changes only with owner approval. Keep local project work outside SharePoint/OneDrive. Use the owner's configured identity without assistant attribution.

### 1.2 Scope proposal and explicit boundaries

| Delivery | Included | Completion meaning |
| --- | --- | --- |
| First visual/combat checkpoint | One rebuilt arena, production-candidate art, responsive input, four polished weapons, useful HUD, effects and audio | A complete match can be played and judged for appearance and feel. This is a checkpoint, not the complete MVP. |
| First polished MVP | Three distinct connected missions, eight combat tools, three CPU profiles, both leads, Scout, one rescued friend, a functional shelter, saves and upgrades, replayable skirmish, Windows export | A player can finish the three-mission arc, use the recruit in a follow-up skirmish, reopen the game and resume or replay without confusion. |
| Complete initial campaign | All ten missions, additional encounters and progression tuning using the established systems | The promised full campaign. Do not describe the three-mission MVP as the ten-level game. |
| Later candidates | Network multiplayer, ropes, vehicles, dynamic liquid simulation, procedural maps, extra biomes, extensive clothing collections, crafting and challenge modes | Separate scope decisions after the core loop works. Existing local play should keep working, but online play is not an MVP dependency. |

No paid purchases are assumed. Asset shortlist and final visual quality are unresolved until tested in Godot. The working title and story remain provisional. No claim is made that original Wild Ones physics constants or source code have been recovered.

## 2. What exists, what is missing, and what can be reused

The baseline was inspected in code. Previous log entries report tests; those reports are not new playtest evidence for this plan.

| Area | Observed baseline | Planned treatment |
| --- | --- | --- |
| Campaign | `CampaignRun.MISSIONS` contains only First Signal and Ferry Landing; `finished()` stops progression after two clears | Replace index-based progression with explicit mission IDs and availability. Reproduce the reported first-mission problem separately. |
| Characters | `campaign_actor.gd` assembles boxes and ellipsoids, with minimal procedural posing | Replace visible actors with imported animated models and configurable appearances; keep simulation hit shapes separate. |
| World | Real lake photograph, flat-color generated blocks, sparse decoration | Replace with one cohesive stylized environment and textured destructible ground. |
| Weapons | `ArtilleryShot.Weapon` contains rocket and grenade | Introduce data definitions, ownership and per-behavior handling before extending the arsenal. |
| Physics | Fixed 60 Hz simulation, swept projectiles, terrain cuts, falling, knockback, water elimination | Preserve and test these foundations. Tune feel deliberately; do not rewrite everything to change visuals. |
| Terrain | Fixed `256 x 128` occupancy grid; `0.125` unit cells; generated chunk meshes | Keep authoritative occupancy initially, improve surface materials/contours, then make dimensions instance-configurable for larger stages. |
| Input | Pull-back aiming and keyboard charging; 12/15/18/20-dot guide | Add clearer feedback, cancellation, camera/drag isolation, sensitivity and resolution checks. |
| CPU | Bounded candidate search over short walks and two weapons, with release error | Extend to real tactical choices and tool-specific actions. Retain equal physics and deliberate imperfection. |
| Progression | Supplies, one team HP upgrade, per-character guide training, fixed roster arrays | Generalize definitions and stable IDs; preserve earned values through a tested save migration. |
| UI | Functional menus and text-heavy HUD; shelter stations | Rebuild hierarchy and visual components, retaining accessible actions and real settings behavior. |
| Tests | Terrain, match, solo, aim, supply and campaign suites | Keep meaningful regression coverage; add new checks as behaviors change. Visual quality and fun need interactive review. |

## 3. Reference study before tuning

### 3.1 Evidence and interpretation

The contemporary [Wild Ones review](https://www.gamezebo.com/reviews/wild-ones-review/) describes varied terrain, movement tools and weapons with different tactical uses. This supports the experience direction; it does not establish exact damage, speed or economy values. Original visual references should be recorded as linked screenshots or videos with timestamps during implementation, not reconstructed from memory.

[Worms Revolution's developer retrospective](https://www.team17.com/news/team17s-100-games-part-thirteen-2011-2012-worms-crazy-golf-worms-for-facebook-and-more) is a secondary reference for side-view 3D presentation. [Worms W.M.D](https://www.team17.com/games/worms-w-m-d) is a secondary reference for readable artillery combat and weapon variety. Our chosen mouse controls, lovers, shelter and story progression are project requirements, not claims about Wild Ones.

- [ ] **REF-01** Create `docs/reference_observations.md` with a source table: URL, access date, game/version when known, timestamp/image, observed behavior, confidence and design implication.
- [ ] **REF-02** Inspect at least three representative Wild Ones battles covering open terrain, vertical cover and different weapons. Record shots, movement, camera behavior, HUD, character scale and impact feedback. If only archived footage is available, label that limitation.
- [ ] **REF-03** Build a compact reference board for background layers, foreground surfaces, characters, weapon silhouettes, explosions and inventory. Link original materials; use licensed original assets for the shipped game.
- [ ] **REF-04** Record relative measurements where visible: character screen height, jump height in character units, travel time, time from impact to next turn and approximate map width in jump distances. Include uncertainty; do not label estimates exact.
- [ ] **REF-05** List what transfers: expressive readable actors, playful weapons, meaningful terrain, fast feedback and tactical movement. List project differences: 3D side view, human leads, CPU campaign and pull-back aiming.
- [ ] **REF-06** Turn observations into a short tuning sheet. Lack of access to the original servers must not block development; use accessible evidence and explicit proposed values.

**Exit:** reference board and observation notes can explain the proposed visual and combat choices. No implementation relies on unsupported claims of perfect replication.

## 4. Delivery order, branches and completion gates

Relative size is planning guidance: S = contained change; M = several connected systems; L = substantial content/integration work; spike = feasibility work whose output determines the next approach. These are not calendar promises.

| Order | Branch | Deliverable | Depends on | Size / evidence |
| --- | --- | --- | --- | --- |
| P0 | `fix/campaign-navigation` | Diagnose progression, clear next-step UI, save-safe navigation | Approved plan | M; reproduce and pass a real continuation test |
| P1 | `art/wild-ones-direction` | Reference board, asset manifest, imported style sample | Approved plan; alongside P0 if useful | M; playable-scale screenshots and animation check |
| P2 | `feature/stylized-battlefield` | One complete arena with terrain materials, background layers, props, camera and actors | P1 and terrain feasibility spike | L; coherent moving scene and crater closeups |
| P3 | `feature/combat-controls-and-feedback` | Input rules, turn states, camera behavior, sound/VFX and core HUD | P0, P2 | M; full two-weapon match through ordinary controls |
| P4 | `feature/weapon-system` then `feature/shotgun-and-mines` | Stable weapon definitions, ammo/actions, four polished weapons | P3 | L; each weapon has a useful distinct role |
| P5 | `feature/tactical-tools` and `feature/cpu-tactics` | Eight tools, fair CPU profiles, supply integration | P4 | L; tool tests and seeded behavior comparison |
| P6 | `feature/campaign-data-and-saves` | Mission/roster definitions, migration, rewards and progression | P0; integrate with P5 | M; migration and duplicate-reward checks |
| P7 | `feature/three-mission-campaign` and `feature/shelter-and-upgrades` | Three designed missions, both rescues, shelter, supporter actions, customization | P2, P5, P6 | L; complete run with save/reload and purchases |
| P8 | `feature/mvp-release-polish` | Full UI/settings, balance, performance and Windows package | P7 | M; exported build passes the release checklist |

P0 is intentionally narrow. P6 performs the broader campaign refactor after the blocking behavior is understood. P4 may introduce small weapon definitions earlier if that makes P3 cleaner; do not turn the project into a generic framework before it has a good match.

Each branch records changed behavior, relevant verification and remaining issues in the project log. Integrate through PRs into `development_branch`, then verify the combined build. Development merges are not owner approval for release to `main`.

## 5. P0: campaign access and truthful progress

### 5.1 Diagnose before changing the save

- [ ] **FLOW-01** Record launched executable/project path, branch SHA, visible build label, checkpoint location and saved progression. Do not print private machine paths or save contents into public documentation.
- [ ] **FLOW-02** Preserve the existing checkpoint before debugging. Use separate test data for New Story and migration tests; never reset the owner's campaign just to reproduce a problem.
- [ ] **FLOW-03** Reproduce these routes: fresh New Story -> clear First Signal -> shelter -> map -> Ferry Landing; quit after first clear -> Continue -> Ferry Landing; clear Ferry Landing -> explicit content-end screen.
- [ ] **FLOW-04** Separate three possibilities in the issue record: only two missions exist; next mission is available but the shelter interaction hides it; an actual state/save/launch defect prevents access. Record the reproduced cause instead of guessing.
- [ ] **FLOW-05** Add a visible build/version label to the title screen and a simple launch instruction so an old export and the development project are distinguishable.

### 5.2 Correct the player-facing flow

- [ ] **FLOW-06** After victory, show rewards, the rescued character and a prominent Continue to Shelter action. In the shelter show **Next mission: [name]** and a direct Open Map button alongside walk-up interaction.
- [ ] **FLOW-07** Mission cards have explicit Available, Locked, Cleared and Not Included in This Build states. Locked cards explain their prerequisite. Unimplemented cards never look playable.
- [ ] **FLOW-08** Distinguish mission completion, three-mission MVP completion and full campaign completion in labels. The prototype's two-level ending must not suggest that more missions are currently playable.
- [ ] **FLOW-09** Continue returns to the correct checkpoint context. Loss offers retry without duplicate rewards; draw has an explicit result. Returning home cannot award a clear.
- [ ] **FLOW-10** Test the real buttons and shelter route, not just `CampaignRun.complete()`. Capture the first-to-second transition and reload path.

**Exit:** the first two existing missions are accessible through clear UI, the current content limit is honest, and the owner's original checkpoint is preserved.

## 6. P1-P2: cohesive art and a finished battlefield

### 6.1 Art specification and premade asset selection

Proposed direction: a colorful stylized rescue adventure with rounded, expressive characters; oversized readable tools; grassy earth/rock islands; wooden outposts; misty forest/mountain depth; warm characters against quieter scenery. Preserve the playful combat energy of Wild Ones. Keep the background photographic-free in the new battle presentation.

- [ ] **ART-01** Write `docs/art_direction.md`: palette, material roughness, light direction, camera pitch, character proportions, outline policy, water style, HUD typography and three example composition references.
- [ ] **ART-02** Shortlist compatible packs for humans, a dog, environment props, weapon models, effects, UI/icons and sound. Evaluate at gameplay size, not just vendor preview size. No purchasing without owner authorization.
- [ ] **ART-03** Test [Kenney Nature Kit](https://kenney.nl/assets/nature-kit) and [Blaster Kit](https://kenney.nl/assets/blaster-kit) as candidates; both publisher pages list CC0. Neither settles character choice or guarantees the desired art quality.
- [ ] **ART-04** For each asset actually chosen, record author, source URL, pack/version, download date, license text, modifications and allowed source redistribution in `assets/ASSET_MANIFEST.md`. Public-repo redistribution must be permitted; a license allowing only inclusion in a compiled game is insufficient for committing raw assets.
- [ ] **ART-05** Select a human rig supporting both leads and enemy variations, plus a compatible animal rig. Required human clips: idle, walk, jump/fall, land, aim/fire, hit and defeat. Check animation coverage before importing a large collection.
- [ ] **ART-06** Import a minimal sample through Godot's 3D pipeline, preferably GLB/glTF with explicit textures. Wrap imported models in game-owned scenes so asset reimport does not overwrite gameplay setup. Follow [Godot's import documentation](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_3d_scenes/index.html).
- [ ] **ART-07** Normalize scale, feet pivot, forward axis, weapon attachment and material palette. Verify both facing directions; do not mirror skeletons blindly and break attachments.
- [ ] **ART-08** Assemble one sample containing two leads, one enemy, Scout, two held weapons, grass/soil ground, a tree, a crate, water, the background and a small HUD section under the actual game camera.
- [ ] **ART-09** Review at 1280 x 720 and 1920 x 1080. Characters must be identifiable, the walkable surface obvious and weapons visible. If the sample still looks like unrelated asset packs, revise selection/materials before dressing more maps.

### 6.2 Background, scene depth and lighting

- [ ] **WORLD-01** Build separate sky, distant mountain, middle forest and near scenery layers with coherent color and lighting. Use premade models or licensed stylized layers; avoid another unrelated stock photograph.
- [ ] **WORLD-02** Use atmospheric contrast: distant scenery softer and lower contrast, playable terrain strongest edge definition, pickups and actors clearly separated. Test guide dots over sky, foliage and ground.
- [ ] **WORLD-03** Put decorative geometry outside the combat plane. A rock that looks like cover within the play area must have simulation collision; purely decorative rocks belong behind it.
- [ ] **WORLD-04** Add restrained water movement, grass/tree motion and ambient particles. Effects cannot obscure aim dots or resemble hazards unless they are hazards.
- [ ] **WORLD-05** Use one shared lighting/material configuration for characters, props and terrain. Check shadows, contact with ground, silhouette readability and depth from the side camera.
- [ ] **WORLD-06** Keep scenery within a measured performance budget. Add distance simplification or cheaper materials only where profiling shows a need.

### 6.3 Terrain surface and destruction feasibility

Premade scenery and destructible ground solve different problems. A downloaded platform mesh is not automatically cuttable. The simulation remains the source of truth; the terrain surface must be generated from it and decorated with matching materials and assets.

- [ ] **GROUND-01** Run a bounded spike on one chunk: earth front face, grass top, rock detail, exposed crater wall and visible extrusion. Compare textured cell boundaries with contour-generated geometry. Capture before/after blasts.
- [ ] **GROUND-02** Preserve occupancy queries and projectile sweeps. Add material/region information only where necessary for grass, soil, rock and supported props; no new structural simulation in this MVP.
- [ ] **GROUND-03** Preferred visual route: extract occupied boundaries, simplify collinear edges without moving collision boundaries, triangulate front/back surfaces including holes, and extrude exposed edges. Test isolated islands, tunnels, chunk edges and repeated overlapping cuts.
- [ ] **GROUND-04** Do not visually smooth across solid cells without an agreed collision update. Any rounding must remain within a documented tolerance of the authoritative shape. If contour triangulation is unreliable, ship matching textured grid-aligned geometry while continuing the bounded investigation; do not label a broken smooth mesh finished.
- [ ] **GROUND-05** Map textures consistently in world space or stable UVs so neighboring chunks and repeated cuts do not stretch or reset the terrain pattern. New crater interiors need appropriate soil/rock surfaces.
- [ ] **GROUND-06** Rebuild only dirty chunks and required neighbors; reuse unchanged resources. Measure worst-case cuts and chained explosions.
- [ ] **GROUND-07** Define surface-support anchors for grass, fences, crates and scenery attached to terrain. Unsupported decorative props fall briefly or disappear with debris; simulated props follow their explicit gameplay rules.
- [ ] **GROUND-08** Keep floating solid islands static in the MVP unless directly destroyed. Only units, pickups and configured props fall. Full collapsing terrain is deferred and must not be implied by the visuals/tutorial.
- [ ] **GROUND-09** Replace broad rectangular layout blocks with designed silhouettes, elevations and cover. Add terrain authoring through scene markers/polygons or an occupancy mask imported at build/load time, with the result feeding the same grid.
- [ ] **GROUND-10** Make grid size an instance property before expanding beyond current bounds. Audit every `TerrainGrid.SIZE`, `WORLD_SIZE`, shot bound, camera bound, snapshot and chunk loop. Retain cell scale initially and validate several map dimensions.

**Exit:** one arena looks consistent before and after destruction; rendered ground and collision agree; debris and removed support do not leave scenery hanging; no background photograph or primitive placeholder actor remains in the reviewed scene.

## 7. P3: movement, aiming, turns and camera

### 7.1 Proposed rules to implement and tune

| Rule | Initial proposal | Important boundary |
| --- | --- | --- |
| Turn budget | 30 seconds for normal play; optional untimed training | Movement and aiming share the budget. No extra movement meter for this MVP. |
| Turn order | Alternate teams; next living member of that team acts in roster order | Player roster order is Mara, Eli, then supporters in rescue order. Show the actual interleaved upcoming queue. |
| Action budget | One weapon or support action per turn | Selecting/canceling does not consume it; valid release/placement does. |
| Retreat | Up to 3 seconds after committing an action | Active unit may move while the projectile resolves, but cannot take another action. If defeated, retreat ends. |
| Handoff | Wait for retreat and active effects to finish and units to settle | Add a bounded resolution watchdog and explicit handling for stuck/resting entities. |
| Defeat | Water elimination; HP depletion; explicit mission failure conditions | Individual defeat lasts for this attempt. Survivors and defeated recruits recover for the next mission; no permanent roster loss. |
| Wind | Visible, constant during an individual turn | Same value for guide, CPU forecasts and actual projectiles; update only at documented turn boundaries. |
| New-story reset | Reset progression, skills, money, recruits and mission unlocks | Retain settings and cosmetic selections. Never reset progress on ordinary mission transitions. |

These values are starting proposals, not measurements from Wild Ones. Record tuning changes with the reason and comparison result.

### 7.2 Movement and action state

- [ ] **CTRL-01** Define authoritative phases: turn start, player/CPU control, committed action with retreat, resolution, result. Permit damage/death during retreat and cancel input immediately when the active unit is no longer eligible.
- [ ] **CTRL-02** Validate walking, slopes/steps, jumping, landing and facing against the actual terrain. Add small jump buffering and edge forgiveness only if it improves feel without bypassing gaps; expose values in tuning data.
- [ ] **CTRL-03** Use the same movement/action commands for player and CPU. Rendering animation must not move the authoritative unit or change collision timing.
- [ ] **CTRL-04** Tune jump range against map gaps and character height. No initial mission requires a pixel-perfect jump or an unavailable movement tool.
- [ ] **CTRL-05** Remove a unit's turn cleanly if it dies during movement, mine detonation or retreat. Simultaneous eliminations produce a stable winner/draw without another active turn.
- [ ] **CTRL-06** Define pause/focus behavior: freeze solo play, cancel held aim, discard the release after resuming, and prevent clicks from menus entering combat. Resume never fires an old shot.

### 7.3 Drag targeting and assistance

- [ ] **AIM-01** Keep a fixed screen-space press anchor. With drag vector `d = anchor - cursor`, direction follows the projected vector on the gameplay plane. Power is `100 * clamp((length(d) - dead_zone) / (full_pull - dead_zone), 0, 1)`.
- [ ] **AIM-02** Scale full-pull distance with viewport dimensions and the saved sensitivity setting. Evaluate the current 24% of the shorter viewport dimension as the baseline. A small click below the dead zone cancels rather than firing.
- [ ] **AIM-03** Show an anchor marker, pull tether, direction cue and compact numeric/meter power feedback while dragging. Clearly teach that pulling away from the target launches toward it.
- [ ] **AIM-04** Release over the battlefield commits the shown valid shot. Right-click cancels. Escape cancels and opens pause. Weapon changes, focus loss, turn expiry and opening a modal cancel the drag. Clicking UI must never begin it.
- [ ] **AIM-05** Freeze camera auto-tracking and zoom while dragging so the screen-to-world mapping does not shift. Clamp angles only where necessary and show the clamped direction in the guide and held weapon.
- [ ] **AIM-06** Preview with the production trajectory integrator, selected weapon, actual wind and power. Show up to 12/15/18/20 fading dots; stop at the first relevant obstruction. More tiers extend the visible horizon at the same spacing, not just density on the same short arc.
- [ ] **AIM-07** For grenades, the MVP guide ends at first collision rather than promising an exact bounce sequence. Shotgun displays a short dotted direction and spread cone; placement tools display valid/invalid placement, not a fake ballistic arc.
- [ ] **AIM-08** CPU and the opposing local player receive no trajectory dots. Guide information belongs only to the assisted human side; effects and projectile trails may still be visible to everyone.
- [ ] **AIM-09** Keyboard aim/power remains a fallback, with bindings shown in controls. Update help text so the old looping mouse-charge instruction is gone.
- [ ] **AIM-10** Test both firing directions, low/high power, both viewport sizes, window resizing, high display scaling, UI overlap, viewport edges, pause, focus loss and camera return. Ensure release consumes ammo once.

### 7.4 Camera composition

- [ ] **CAM-01** Start with a side-on orthographic camera with a modest fixed depth-revealing angle. Compare a narrow-FOV perspective sample only if it materially improves depth without confusing aim.
- [ ] **CAM-02** Make the active character readable at normal aim zoom; target roughly 60-90 pixels of character height at 720p for the sample, then adjust to actual models and aiming needs. Overview may be wider.
- [ ] **CAM-03** Provide wheel zoom, middle-drag pan and an explicit refocus action. Clamp camera to authored bounds and keep HUD independent of world zoom.
- [ ] **CAM-04** On release, frame shooter and projectile when possible, then follow the projectile/impact with bounded smooth motion. Return to the next active unit after effects settle. Do not allow camera movement to conceal retreat control.
- [ ] **CAM-05** Supply optional shake with off/reduced settings. Labels and UI remain stable; long arcs, chained blasts and teleport cannot cause abrupt camera oscillation.

**Exit:** a new player can move, aim, cancel, fire, understand the impact and identify the next unit. The same deliberate drag produces the same launch at a given state regardless of frame rate or camera zoom.

### 7.5 Authoritative physics and damage rules

- [ ] **PHYS-01** Centralize gravity, launch speed range, movement acceleration/speed, jump impulse, air control, wind coefficient, fuse and restitution in tuning data. Start from the working simulation; change one related parameter group at a time against the same test layout.
- [ ] **PHYS-02** Keep fixed-step integration shared by preview, actual shots and forecasts. For the current semi-implicit scheme, `velocity += acceleration * dt`, then sweep from the old position to `position + velocity * dt`. Include projectile radius where the selected model requires it; do not merely check its endpoint.
- [ ] **PHYS-03** Map normalized drag power to a documented launch-speed curve, initially linear between configured minimum/maximum speed after the input dead zone. Show the same clamped value in the HUD and simulation. Tune wind relative to travel time, not an arbitrary visual offset.
- [ ] **PHYS-04** Define blast damage as configurable distance falloff within a radius. Proposed baseline is `base_damage * max(0, 1 - distance / radius)`, multiplied by exposed-body fraction. Sample consistent body points against terrain immediately before that blast's terrain edit, with robust handling of an impact lying on the terrain surface. Fully covered units take no direct blast damage but may lose footing when the terrain is cut.
- [ ] **PHYS-05** Compute all victims of one blast from the same snapshot before applying results, preventing iteration order from changing exposure. Damage and impulse have independent tuning curves; track the attacker for UI/ownership even after that attacker dies. Friendly fire applies equally to both teams.
- [ ] **PHYS-06** Resolve terrain cut, unit impulse, support loss, falling and later chain reactions in a documented stable order. Simultaneous sources have event IDs; one source cannot damage the same unit twice accidentally. Tests cover a victim behind cover, at the blast edge, near the impact and above removed ground.
- [ ] **PHYS-07** Tune grenade normal restitution and tangential damping separately; use rest thresholds and contact offsets to prevent jitter. Fuse age advances during rest and does not restart on bounce. Decide and expose whether a given projectile is removed or detonates on entering water; apply the same rule in prediction.
- [ ] **PHYS-08** Use a consistent character collision footprint independent of cosmetic model variations. Validate step-up height, narrow ledges, head clearance and multiple units touching; prevent models from walking through each other when their simulation bodies cannot.
- [ ] **PHYS-09** Add fall damage only through an explicit landing-speed threshold and capped curve, with visible feedback and matching CPU evaluation. Initially test the campaign with it disabled, then keep it only if it improves tactics without making ordinary jumps punishing. Water remains an explicit elimination hazard.
- [ ] **PHYS-10** Bound projectile lifetimes and active resolution time. A stuck effect is retired safely with a diagnostic; unresolved units use a documented recovery/failure rule, never silently teleport to a favorable attack position. Ensure a turn cannot wait forever for decorative debris.

**Exit:** identical seeded commands give repeatable results in the same build; collision, guide, damage and wind are explainable; actual frame rate and cosmetic changes do not alter combat rules.

## 8. P4-P5: weapons, tools and audiovisual impact

### 8.1 Weapon architecture

- [ ] **WEAPON-01** Add `WeaponDefinition` resources with stable ID, display name, icon, held/projectile scene, targeting mode, behavior ID, ammo policy, damage, blast size, impulse, wind/gravity coefficients, fuse, sounds and effect references.
- [ ] **WEAPON-02** Keep mutable ammunition, cooldowns and action ownership in match state, separate from shared definitions. Default to team-shared consumable ammunition so larger rosters do not multiply explosive stock.
- [ ] **WEAPON-03** Add one validated action entry point: confirm phase, actor, weapon access, ammo and legal target; commit once; emit simulation events; consume the action/ammo once. Invalid placement returns a reason without a cost.
- [ ] **WEAPON-04** Replace the single-shot assumption with an owned projectile/effect collection before cluster bombs. Every child projectile carries team, actor and action IDs. Limit simultaneous entities and resolve child events in a stable order.
- [ ] **WEAPON-05** Add persistent placed devices for mines and explosives. Distinguish dormant devices from active resolution work so a resting mine does not block the turn forever.
- [ ] **WEAPON-06** Route damage, knockback, terrain edits, pickups and chain reactions through simulation events. Audio/VFX observe events and cannot apply damage themselves.
- [ ] **WEAPON-07** Snapshot ammo, devices, cooldowns, ownership and pending effects for CPU forecasts. Forecasts must never mutate the real match or consume its random sequence.

### 8.2 Initial arsenal and constraints

Quantities below are starting balance values. Standard skirmish exposes all tools; campaign unlocks follow section 12. No weapon requires money to continue playing: basic rocket and grenade remain available.

| Tool | Targeting and behavior | Starting stock per mission | Definition of useful/done |
| --- | --- | --- | --- |
| Rocket launcher | Pull-back ballistic shot, wind affected, impact explosion | Unlimited | Predictable general-purpose damage and crater creation; muzzle, held launcher, trail and impact align. |
| Timed grenade | Pull-back throw, terrain bounce, visible fuse cue; start with current fixed fuse | Unlimited | Can hit behind cover by an arc/bounce; fuse, rest state and water behavior are unambiguous. |
| Shotgun | Aim direction plus spread; fixed shot strength, one short-range blast | 3 | Strong close-range choice with falloff/knockback; pellet rays stop at cover and cannot hit twice through a wall. |
| Mine | Preview and place on nearby supported ground | 2 | Arms after the placing unit's retreat window, triggers for either team, can be detonated by damage, never awards duplicate effects. |
| Cluster bomb | Ballistic parent with timed burst, bounded child count | 1 | Broader coverage than grenade, lower per-fragment damage; cover still protects; child ownership/pickups work. |
| Placed explosive | Close placement with short visible fuse and immediate retreat opportunity | 1 | Rewards approaching safely, makes a large local crater and can hurt the placer; no remote placement through terrain. |
| Bridge tool | Preview a limited-length platform between supported anchors | 1 | Creates reachable solid ground without overlapping units, hazards or existing solids; shape enters the same terrain grid and can be destroyed. |
| Teleport beacon | Limited-range destination selection with valid landing preview | 1 | Relocates only the active unit to unoccupied supported space; ends its action, cannot collect along the teleport path, can collect at destination. |

- [ ] **WEAPON-08** Polish rocket/grenade models, ownership, targeting and feedback before adding more behaviors.
- [ ] **WEAPON-09** Implement shotgun with deterministic seeded spread or a fixed documented pattern, range falloff and total-damage cap. Proposed mouse behavior: use drag direction; show **Fixed power** so distance does not falsely imply extra damage.
- [ ] **WEAPON-10** Implement mine placement, arming, proximity, detonation, terrain support loss and chain-reaction limits. Surface placement range is measured in world/character units and shown before commit.
- [ ] **WEAPON-11** Ship and review the four-weapon checkpoint. Test real cases where each is preferable; change balance if rocket dominates every case.
- [ ] **WEAPON-12** Implement cluster splitting and child sweeps. Enforce a maximum child count and once-only event IDs; children cannot tunnel through cover or overcount one pickup.
- [ ] **WEAPON-13** Implement the placed explosive and retreat timing together; verify the explosion still occurs if the placer dies first.
- [ ] **WEAPON-14** Implement bridge validation and terrain insertion. Limit size/angle, require anchors, reject self-entombment, and ensure occupied bridge cells support units identically to ground.
- [ ] **WEAPON-15** Implement teleport validation and feedback. An invalid destination stays uncommitted; destinations beyond boundaries or inside another unit are rejected.
- [ ] **WEAPON-16** Show tool name, stock, targeting instructions, role and limitations in the inventory. Empty tools are visibly disabled and explained; selection never resets the turn clock.

### 8.3 Feedback and sound

- [ ] **FX-01** Give every weapon a recognizable held silhouette, icon, shot/placement cue and impact signature. Do not count differently colored copies of the same projectile as different finished weapons.
- [ ] **FX-02** Connect character aim/fire/recoil animations and muzzle effects to authoritative action events. Ensure the shot originates where the player sees the muzzle, with a valid obstruction check near the shooter.
- [ ] **FX-03** Add licensed trails, smoke, sparks, dirt/rock debris and explosion effects appropriate to the style. Reduce scale or opacity if they hide units or the next action.
- [ ] **FX-04** Add floating damage, HP changes, hit reaction, knockback, landing and water elimination feedback. Distinguish terrain-only hits, shielded/blocked attacks if later added, and no-damage misses.
- [ ] **FX-05** Add footsteps, jump/land, weapon selection/fire, fuse, impact, pickup, rescue, turn start, victory and defeat sounds. Separate Master, Music, Effects and UI buses; no dialogue voice production required for MVP.
- [ ] **FX-06** Add one suitable licensed ambient/music loop per battle/shelter mood with fades and limits on simultaneous loud effects. Prevent duplicated sound from multiple observers of one event.
- [ ] **FX-07** Test mute and volume persistence, fast chained blasts, zoom changes and reduced effects. Disable camera shake without changing simulation behavior.

**Exit:** eight functioning tools at MVP completion, four already polished at the earlier checkpoint. Each has real art, targeting, stock rules, CPU support or an explicitly tested CPU policy, useful feedback and a scenario demonstrating its purpose.

## 9. P5: fair opponents with tactical choices

Use a bounded rule-based planner over the existing simulation, not machine learning. This supports inspectable decisions, controllable difficulty and reliable iteration without a training pipeline. Difficulty changes reasoning budget, risk preferences, weapon selection and execution error; CPU health/damage bonuses are not the default difficulty mechanism.

### 9.1 Candidate generation and selection

- [ ] **AI-01** Define a difficulty resource: candidate budget, planning-time cap, target preferences, move/jump options, allowed tools, aim/power error and risk tolerance. All tools still obey stock and turn rules.
- [ ] **AI-02** Enumerate bounded legal actions: shoot from current position, walk/jump to a reachable perch, place a device, bridge a useful crossing, teleport to a valid safe position, collect a supply, use support, or pass.
- [ ] **AI-03** Derive walkable surface segments and short jump connections from current terrain. Rebuild affected reachability after destruction; use movement simulation to validate a candidate rather than assuming a model-based path is executable.
- [ ] **AI-04** Predict candidates using the same physics and collision rules. Score damage, eliminations, friendly harm, water risk, improvement of cover/firing position, supplies, objective progress, ammo cost and exposure after the action.
- [ ] **AI-05** Start with normalized terms in `score = enemy_damage + elimination_value + position_value + objective_value + pickup_value - friendly_damage_penalty - fall_risk - exposure - ammo_cost`. Keep weights in tuning resources and report them in a debug-only decision trace.
- [ ] **AI-06** Evaluate a small number of likely outcomes around imperfect aim for expensive/self-dangerous shots. Easy CPU may make suboptimal choices, but should not habitually kill allies because uncertainty was ignored.
- [ ] **AI-07** Select among sufficiently good alternatives, then sample execution error once. Do not resample until a hit appears, secretly correct the shot mid-flight, read the player's future input or alter wind to help the CPU.
- [ ] **AI-08** Represent cautious, aggressive and supply-seeking tendencies through score weights. A personality cannot bypass safety, ownership or ammunition rules.
- [ ] **AI-09** Chunk planning across frames with a strict total budget. Proposed visible thinking interval is roughly 0.5-2 seconds, bounded at 2.5 seconds on the test machine; use the best completed candidate or a safe fallback when time expires.
- [ ] **AI-10** Show brief Moving/Aiming/Thinking status without a trajectory guide. If interrupted by falling or a mine, revalidate the action and resolve safely.

### 9.2 Difficulty and evaluation

| Profile | Intended behavior | Must remain true |
| --- | --- | --- |
| Relaxed | Shorter search, simple target choices, noticeable bounded error, generous openings | Can hit easy close shots; does not become a random suicide bot. |
| Standard | Uses cover, reachable perches and appropriate tools; moderate distance-dependent error | Can miss and choose a reasonable but nonoptimal action. |
| Challenging | Wider candidate comparison, better resource use and positional planning, smaller error | Still uses the same world information, ammunition, movement and nonzero execution uncertainty. |

- [ ] **AI-11** Support a player-selected difficulty modifier plus authored per-mission progression. Later levels become more tactically demanding without forcing every user onto near-perfect aim.
- [ ] **AI-12** Build seeded fixtures for open shots, high cover, nearby allies, unsafe edges, distant pickups, blocked routes, empty ammo, mine hazards and no useful shot.
- [ ] **AI-13** Run at least 30 fixed seeds per representative combat fixture. Report damage distribution, no-damage shots, self/friendly damage, move/pass frequency, tool use and planner latency. Record regressions against the baseline; do not equate bot-vs-bot scores with human enjoyment.
- [ ] **AI-14** Use interactive sessions to tune the first mission so a learner has time to understand and recover from a miss. Reject repeated unavoidable first-turn defeat. Log participant experience and sample size before claiming a win-rate target was met.

**Exit:** the CPU visibly moves and makes understandable tactical choices, uses the relevant arsenal and completes its turns within budget. No difficulty profile depends on perfect ballistic execution.

## 10. Supplies, ownership and match economy

- [ ] **LOOT-01** Keep shared campaign supplies as the MVP currency. Add clearly marked health and ammo crates only after supply behavior is stable; distinguish currency pickups from usable in-match items.
- [ ] **LOOT-02** Select random supported candidate positions between separated living opposing units, with minimum distance from spawns, other pickups, mines, rescue markers and water. If no valid contested position exists, skip the spawn rather than forcing an unsafe item.
- [ ] **LOOT-03** Initially allow one contested pickup slot per full round with a configurable cap. Define a full round as each living participant from a round-start snapshot receiving or losing its scheduled turn; avoid simple modulo logic that breaks after eliminations.
- [ ] **LOOT-04** Detect walking collection with swept unit movement. Detect projectile collection along its actual swept segment up to the first blocking collision; a pickup behind a wall cannot be collected through it.
- [ ] **LOOT-05** Credit the projectile owner's team even after a bounce or the shooter's death. Cluster children inherit ownership. Each pickup has an ID and may be awarded once, even if several fragments arrive in the same tick.
- [ ] **LOOT-06** Collecting does not stop a projectile. Explosion proximity alone does not award a pickup in the MVP. Shotgun pellets also collect when their swept ray/segment crosses a pickup before a blocking hit, preserving the owner's bullet-collection requirement; multiple pellets award it only once.
- [ ] **LOOT-07** Recheck support after terrain changes. A pickup falls to a valid surface or is lost in water. Its visual location and collision location must stay synchronized.
- [ ] **LOOT-08** For health/ammo crates, apply the advertised benefit to the collecting unit or owning team according to the crate definition. Never grant an unrelated persistent upgrade from a combat pickup.
- [ ] **LOOT-09** Keep an attempt ledger separate from the checkpoint wallet. Victory banks eligible supplies once; failure/retry discards unbanked pickups; opponent collections do not increase the player's wallet.
- [ ] **LOOT-10** Keep prices and mission rewards in data. The existing two-supply reward and one-supply upgrades are provisional; balance after measuring available supplies and upgrade effect across three missions.

**Exit:** the same pickup can be collected fairly by movement or an eligible projectile, ownership is correct, and retries/replays cannot duplicate campaign rewards.

## 11. P6: maintainable content and safe saves

### 11.1 Data responsibilities

Use small Godot resources and scenes for authored content. Stable IDs identify missions, characters, weapons and upgrades; display names and list positions must not be save keys. Preserve working systems while extracting only the responsibilities needed for these features.

| Proposed resource/system | Responsibility | Existing integration point |
| --- | --- | --- |
| `MissionDefinition` | ID, title, prerequisites, arena scene, bounds, spawns, objectives, reward, unlocked tools and CPU profile | Replace the two-way switch in `campaign_mission.gd` and parallel arrays in `campaign_run.gd` |
| `CharacterDefinition` | ID, role, portrait, model scene, appearance slots, base stats and support action | Replace name-based actor types and fixed roster arrays |
| `WeaponDefinition` | Immutable weapon data and presentation references | Extend `ballistics.gd` through bounded behavior handlers |
| `UpgradeDefinition` | ID, team/character scope, tiers, costs, prerequisites and stat effects | Existing kits and trajectory training |
| `DifficultyProfile` | AI budget, error and tactical weights | Existing `computer_opponent.gd` |
| `CampaignRun` | Cleared IDs, current mission, wallet, recruits, upgrades, looks and first-clear rewards | Existing local checkpoint |
| `MatchSimulation` | Units, terrain, turn state, devices, projectiles, supplies and attempt outcomes | Existing simulation remains authoritative |
| Arena presentation | Actors, scenery, camera, particles and event-driven feedback | Split out growing responsibilities from `match_arena.gd` as needed |

- [ ] **DATA-01** Add a catalog validator: unique IDs, valid references, existing assets, reachable campaign prerequisites, nonnegative costs/ammo, valid spawn locations and valid bounds.
- [ ] **DATA-02** Build per-mission state from definitions without mutating shared resources. Enemy composition, wind and rewards must not be hard-coded into UI strings.
- [ ] **DATA-03** Separate recruited roster from deployed roster. MVP deploys all four unlocked player characters; later deployment limits require an explicit design decision rather than silently excluding recruits.
- [ ] **DATA-04** Store supporter order explicitly by recruitment event. Rescuing a friend unlocks them after mission completion; they do not appear mid-round and receive an accidental extra turn.
- [ ] **DATA-05** Cap level population deliberately. Three-mission target: 2-4 player units and 1-3 enemies. Do not add six enemies merely to make a level harder and lengthen waiting.

### 11.2 Checkpoints and migration

- [ ] **SAVE-01** Introduce a versioned save schema using IDs. Map old `cleared=0/1/2` to the existing mission IDs; map the three guide tiers and two outfit choices to Mara, Eli and Scout. A previously completed two-level save must unlock mission three once implemented.
- [ ] **SAVE-02** Validate migration before replacing the source save and retain one backup. Reject unsupported future versions with a readable message; malformed files must not crash or silently overwrite progress.
- [ ] **SAVE-03** Save on new story, confirmed mission completion, purchases and appearance changes. Use a staged file and verified replacement; surface write failures with a retry action.
- [ ] **SAVE-04** A checkpoint is before a mission or in the shelter, not a mid-projectile snapshot. Continue after quitting mid-mission restarts that attempt with checkpoint loadout; explain this in the exit prompt.
- [ ] **SAVE-05** Bank mission completion as one transaction: clear flag, first-clear reward, attempt loot, recruitment, tool unlocks and next mission access. A repeated result callback cannot apply any part twice.
- [ ] **SAVE-06** Allow replay of cleared missions with the current roster for practice, but award no additional persistent currency/recruits/first-clear rewards. Display Practice Replay on entry and results; pickups can still have in-match effects.
- [ ] **SAVE-07** Purchases spend and apply atomically. Failed writes leave an explicit unsaved state and retry path; repeated clicks never buy the same tier twice.
- [ ] **SAVE-08** New Story asks for confirmation if a run exists, resets run data and keeps settings/appearance preferences. Use isolated save files for automated tests and preserve user data during QA.
- [ ] **SAVE-09** Test fresh save, old two-level completion, old first-clear save, missing optional fields, malformed data, write failure, repeated result, retry, replay, quit/relaunch and new-story reset.

**Exit:** old progress migrates predictably, mission three opens for a completed old chapter, and reward/recruitment updates are durable and once-only.

## 12. P7: three designed missions and a playable loop

### 12.1 Common level design requirements

- [ ] **LEVEL-01** Design each map with a top-level tactical question, authored player/enemy spawns, at least two useful positions/routes, a distinct landmark, pickup candidates and readable hazards.
- [ ] **LEVEL-02** Build reusable level scenes for grassy ledges, stone cover, wooden outposts, bridges, crates and background groups. Clearly mark which pieces are destructible ground, simulated props or scenery.
- [ ] **LEVEL-03** Validate routes in character/jump units. A rescue required for victory must be reachable with guaranteed available tools; optional ammo or a random pickup cannot be the only way through.
- [ ] **LEVEL-04** Test the map after representative craters, not only at load. Record potential traps, dominant firing positions, inaccessible targets and situations requiring teleport/bridge recovery.
- [ ] **LEVEL-05** Keep rescue targets visibly distinct and anchored to valid ground. They may fall if support disappears; losing a required target causes a clear, immediate failure explanation and retry.
- [ ] **LEVEL-06** Mandatory rescue and enemy-clear objectives can be completed in either order. If all enemies die first, continue player turns to finish a reachable rescue without awarding victory prematurely.
- [ ] **LEVEL-07** Add one environmental interaction to the slice, such as an explosive barrel, with explicit health/damage rules and a recognizable warning design. Optional interactions must not make the tutorial's opening unavoidable lethal.
- [ ] **LEVEL-08** Set initial target duration around 5-10 minutes per mission, with the first shorter. Measure actual beginner playtime and CPU waiting before locking target lengths.

### 12.2 Mission briefs

| Mission | Tactical layout | Tools and opposition | Objective, reward and transition |
| --- | --- | --- | --- |
| 1: First Signal | Compact lakeshore, broad connected walking route, one shallow elevation change, safe firing area, obvious Scout marker; roughly 18-22 units wide as an initial layout | Rocket/grenade; one relaxed lookout with a forgiving position | Reach Scout and defeat the lookout in either order. Teach drag/cancel, movement and rescue. First-clear reward recruits Scout, unlocks shotgun/mine and opens the shelter/ferry mission. |
| 2: Ferry Landing | Roughly 26-32 units; dock structures, two useful elevations, a route around cover, contested supply and one optional explosive prop; no mandatory consumable crossing | Four polished weapons; two standard-profile enemies with different positions | Clear the dock. Scout has a real support action. Unlock advanced tools with safe practice access and open mission three; return to shelter. |
| 3: Through the Pines | Roughly 32-40 units after variable bounds are ready; forest outpost with upper firing perch, lower covered route, recoverable gap and a protected rescue pocket | Eight tools available; up to three enemies using cover and movement, difficulty adjusted by selected profile | Rescue an old friend and clear the outpost. Recruit the friend, return to shelter and show the three-mission MVP ending with replay/skirmish options. Mission four is visibly not implemented. |

Sizes are layout proposals, not a reason to enlarge empty space. Match the level to actual jump range, weapon reach, camera behavior and resolution budgets.

- [ ] **LEVEL-09** Rebuild First Signal using the accepted environment kit and an unobtrusive first-shot tutorial. Teach one concept at a time, with repeatable help and a skip option.
- [ ] **LEVEL-10** Rebuild Ferry Landing as a visibly different dock encounter using the same art family. Demonstrate why grenade/shotgun/mine choice matters; avoid simply scaling First Signal wider.
- [ ] **LEVEL-11** Implement Through the Pines using new mission data, broader terrain bounds and the rescue objective system. Ensure a low-resource player can complete it without purchasing a specific upgrade.
- [ ] **LEVEL-12** After the third rescue, provide a training/skirmish entry using the recruited roster so the new friend's ability can actually be tried in this MVP. Do not deliver a recruit with no playable turn until a future release.
- [ ] **LEVEL-13** Complete all three missions from a fresh run without debug damage, forced victory, direct state edits or perfect AI-generated player shots. Also verify reload between every mission and one intentional loss/retry.

### 12.3 Supporters and identity

- [ ] **CHAR-01** Use stable character IDs. Mara and Eli keep their independent appearances and stats. Their relationship appears through short optional shelter dialogue; it must not interrupt every turn.
- [ ] **CHAR-02** Scout's proposed unique action is **Fetch**: preview a safe route to one visible pickup within a limited reachable radius, traverse it through ordinary movement collision, collect it and return if the route remains safe. It consumes his action. Invalid/unreachable pickup cancels before commitment; mines and hazards still apply.
- [ ] **CHAR-03** Give Scout a small compatible launcher/harness and selected common projectile actions so his turn remains useful when no pickup exists. Use animal-specific animations and attachment points; do not attach a human two-handed pose to the dog.
- [ ] **CHAR-04** The rescued friend is provisionally a field medic. Their **First Aid** action heals one nearby ally within clear range, capped at max HP, with one use per mission initially. It consumes the turn action and cannot revive a defeated unit. Name and final appearance remain editable content.
- [ ] **CHAR-05** Recruits join after the leads in rescue order. Their own upgrades and cooldowns remain isolated. Show locked portraits with rescue requirements; supporters cannot be bought from a shop.
- [ ] **CHAR-06** Expose each character's allowed arsenal clearly. Humans can use the full common arsenal; Scout uses an explicit supported subset plus Fetch. CPU validation and UI share the same availability rules.

**Exit:** three missions have different tactical identities; both rescues change the playable roster; the new friend can act before the MVP ends; the next mission is always explicit.

## 13. P7: shelter, upgrades and appearance

### 13.1 Walkable shelter

- [ ] **HUB-01** Replace geometric station placeholders with matching premade shelter props: map table, supply workbench and roster/notice board. Retain the side-view camera and walking.
- [ ] **HUB-02** Add readable proximity highlight and E/click interaction. Provide persistent Map, Team and Characters shortcuts so navigation is accessible without precise positioning.
- [ ] **HUB-03** Map shows mission progress, objectives, rewards, available tools, selected difficulty and a clear Start action. At content end, show Play Skirmish/Replay/Return Home instead of a dead next-mission button.
- [ ] **HUB-04** Display earned supplies, rescued supporters and one short story exchange on return; allow skipping. Do not require an upgrade purchase to leave.
- [ ] **HUB-05** Returning from any upgrade tab restores the shelter context. Opening menus stops character movement; closing them does not resume a held movement/aim input.

### 13.2 Separate progression screens

Proposed MVP upgrades are deliberately limited to effects we can explain and test. Their costs are editable and must be simulated over the three-mission economy before implementation is called balanced.

| Scope | Upgrade | Proposed limit/effect |
| --- | --- | --- |
| Team | Field kit | One tier; retain the current +15 starting HP baseline for evaluation. |
| Team | Utility pouch | One tier; +1 starting mine per mission once mines are unlocked. Does not unlock a missing tool. |
| Individual | Trajectory training | Three tiers; 12 -> 15 -> 18 -> 20 dots for that character's supported ballistic guide. |
| Individual | Movement training | One modest capped movement improvement, initially +10% walking speed; no additional turn time. |
| Individual supporter | Role training | Scout: bounded Fetch range increase; medic: bounded healing increase. No infinite scaling. |

Initial economy fixture: retain 2 guaranteed supplies per first clear, let a supply pickup add 1, price field kit and first guide tier at 1 each, utility pouch and movement training at 2 each, later guide tiers at 2 and 3, and role training at 2. This gives a real spend/save choice after mission one and avoids assuming random loot is guaranteed. These are proposed fixture values to test, not final balance. No-upgrade completion remains mandatory.

- [ ] **UPGRADE-01** Build distinct Team and Characters screens with shared style. Characters screen has stable per-character subtabs, portrait, current stats and ability explanation.
- [ ] **UPGRADE-02** Show current value, next value, cost, prerequisites, purchase availability and a reason when disabled. A purchase visibly updates the selected character/team and wallet.
- [ ] **UPGRADE-03** Apply derived stats from base definitions and owned upgrades at mission start. Never mutate a shared base resource or compound an upgrade again on reload/retry.
- [ ] **UPGRADE-04** Test every tier for the correct scope: Mara's guide never changes Eli's; team HP affects each eligible deployed member once; role training cannot be purchased by another role.
- [ ] **UPGRADE-05** Model guaranteed first-clear income separately from random pickups. Players must be able to finish all three missions with zero upgrades and still afford at least one meaningful choice after the first clear.
- [ ] **UPGRADE-06** Compare upgrade paths for runaway advantage. Avoid stacking HP and movement so the default campaign becomes trivial; tune enemies through positions and tactics as well as stats.
- [ ] **UPGRADE-07** Unlock tools through mission progress for the MVP; replenish mission stock from definitions. A full ammo shop/crafting economy is deferred to avoid a softlock where an unlucky player cannot afford to play.

### 13.3 Customization

- [ ] **LOOK-01** Provide separate Mara/Eli previews with rotation or suitable framing, lighting matching gameplay and reset-to-default.
- [ ] **LOOK-02** Target at least three clothing colors, two compatible hair/head options and selectable skin tones for each lead, subject to the chosen rig supporting them. If the selected free pack cannot support this, revise the asset selection or document a concrete alternative before calling customization complete.
- [ ] **LOOK-03** Appearance has no statistical advantage and does not change collision size. Keep team indicators readable regardless of clothing color.
- [ ] **LOOK-04** Save preferences independently from run progression. Restore the same appearance in preview, shelter, battle and portrait; new story keeps the player's choices.

**Exit:** the shelter is understandable, all displayed purchases work and persist, character customization is visible in combat, and progression never prevents starting the next mission.

## 14. P3-P8: UI, onboarding and settings

### 14.1 Screen inventory

| Screen | Required controls and information |
| --- | --- |
| Main menu | New Story, Continue with progress, Skirmish, Settings, Quit; visible build identifier. Keep developer lab out of the primary player flow. |
| New Story / looks | Two lead previews and separate appearance controls, reset behavior warning, start/back. |
| Battle HUD | Active portrait/name, individual HP, team identity, timer, actual upcoming turn queue, wind direction/strength, objective, selected weapon/stock, compact power and contextual control hint. |
| Weapon inventory | Icons, names, counts, role/tooltips, targeting hint, keyboard shortcuts and clear selected/disabled states. |
| Pause | Resume, Controls/Settings, Restart Attempt with confirmation where needed, Return Home explaining checkpoint behavior. |
| Mission result | Win/loss reason, rewards actually banked, recruit/unlock, save status, Continue or Retry. |
| Shelter/map | Chapter progress and explicit next mission, replay availability, story and upgrade access. |
| Team upgrades | Team effects, current/next values, costs and buy feedback. |
| Character upgrades | All recruited tabs, locked rescue hints, stats, ability and individual tiers. |
| Settings | Real display, audio, aiming and accessibility options with apply/cancel/reset and persistence. |
| MVP completion | Explicit three-mission ending, recruited-roster skirmish, replay, return home; future missions labeled unavailable. |

- [ ] **UI-01** Build a reusable Godot theme: licensed font, panel/button styles, icons, focus/hover/pressed/disabled states, spacing and readable text contrast. Avoid giant panels taking most of the aiming area.
- [ ] **UI-02** Replace redundant instruction paragraphs with contextual prompts and optional help. Player-critical state stays visible during aim, action resolution and CPU turns.
- [ ] **UI-03** Reserve safe screen areas for the HUD and actor labels. Prevent overlapping health labels, objectives and trajectories when units cluster or camera zoom changes.
- [ ] **UI-04** Ensure keyboard focus, mouse interactions, Escape/back behavior and tab navigation work across all screens. Color alone must not identify teams, placement validity or disabled states.
- [ ] **UI-05** Add a short interactive tutorial in mission one: move, jump, drag, cancel, shoot, collect, rescue and continue. Teach tools when unlocked, with a practice route and replayable control help.
- [ ] **UI-06** Tool inventory does not pause the combat clock in normal matches; pause/settings do. Make this behavior consistent and cancel aiming on menu entry. Training can be untimed.
- [ ] **UI-07** Confirm controller support is deferred; do not show inactive controller prompts. Keep existing keyboard fallback documented.

### 14.2 Functional settings matrix

- [ ] **SET-01** Windowed/fullscreen and supported window size; preserve a recovery route if display changes are unusable. Test Apply/Cancel and reopen persistence.
- [ ] **SET-02** Master, music, effects and UI volume, with a preview sound where useful. Muting stops the relevant bus immediately and persists.
- [ ] **SET-03** Drag sensitivity/full-pull distance, key rebinding with conflict handling, and restore controls. Gameplay hints update to current bindings.
- [ ] **SET-04** UI scale, reduced camera shake, reduced effects and camera follow preference. Test readable HUD at minimum supported window size and Windows display scaling.
- [ ] **SET-05** Quality preset for shadows/particles and VSync, only if implemented and measurable. Never display a setting that does nothing.
- [ ] **SET-06** Persist settings independently of campaign saves. Back/Cancel discards pending edits; Apply commits them; New Story leaves them intact.

**Exit:** each listed screen has a clear purpose and working navigation; settings change real behavior; a first-time player can discover the core controls without external explanation.

## 15. P8: validation, performance and Windows delivery

### 15.1 Automated behavior checks

Keep tests focused on meaningful rules, especially interactions between new systems. Simple art replacements need import and visual checks, not tests that merely assert a node exists.

| Test area | Required scenarios |
| --- | --- |
| Terrain/ballistics | Repeat shot through crater, thin wall at high velocity, hole/island, chunk boundary, varied map dimensions, terrain addition, grenade resting/fuse, visual/collision comparison. |
| Input/actions | Drag direction/power, cancel, exact-once release/ammo, focus/pause/timeout, UI exclusion, target mode switching, invalid placement without cost. |
| Turn resolution | Retreat while shot flies, death during retreat, simultaneous deaths, mine chain reaction, no active effects before handoff, growing roster, eliminated actors skipped. |
| Weapons | Individual behavior plus interactions: fragments and cover, mine support loss, explosive ownership after death, bridge blocking/occupancy, teleport destination validation. |
| Pickups | Swept movement, swept projectile before/after terrain contact, owner credit, duplicate fragments, support loss, no valid spawn and full-round behavior after elimination. |
| CPU | Legal movement and tool use, ammo limits, forecast isolation, bounded decision time, nonzero error, safe fallback, changed terrain invalidating a move. |
| Campaign | Three-mission navigation, rescue/clear in either order, target loss, recruit order, new supporter action, no mandatory upgrade and exact-once rewards. |
| Saves/upgrades | Old-save migration, corrupted/unsupported version, interrupted write, restart/retry/replay, independent character tiers, no repeated stat application, New Story reset. |

- [ ] **QA-01** Run the six existing suites before changing simulation to record the baseline; investigate actual failures rather than assuming old log results still apply.
- [ ] **QA-02** Add focused fixtures alongside the relevant implementation, using fixed seeds and isolated save paths. New systems get reproducible failure cases before integration.
- [ ] **QA-03** Run a Godot headless import/parse check after asset or script changes. Check missing references, resource IDs, warnings promoted to errors and import failures.
- [ ] **QA-04** Run relevant suites on each feature branch and the combined integration branch. Run all behavior suites for changes touching common turn state, terrain, ownership or saves.

### 15.2 Interactive and visual acceptance

- [ ] **PLAY-01** Capture the same gameplay compositions at the baseline and revised checkpoint: overview, aiming, impact crater, close character/weapon, weapon menu, shelter, upgrades and result.
- [ ] **PLAY-02** Play a full match using ordinary controls. Automated firing through a perfect planner is useful for regression coverage but does not establish human usability.
- [ ] **PLAY-03** Run one fresh three-mission story, one migrated old chapter, a loss/retry, a practice replay and a skirmish with the new friend. Quit/relaunch between missions in at least one run.
- [ ] **PLAY-04** Record shot attempts, accidental shots/cancels, weapon choices, time spent moving/aiming/waiting, unexplained damage, blocked routes and points where the player does not know what to do next. Keep logs local unless needed for an anonymized tuning report.
- [ ] **PLAY-05** Ask the owner to assess the actual visual/combat checkpoint before replicating it across all levels. Owner feedback is a quality gate, not a substitute for our own review or testing.
- [ ] **PLAY-06** Use additional novice playtests when available, without inventing participants or outcomes. Record sample size and experience. Tune based on both observations and the owner's feedback.
- [ ] **PLAY-07** Check that each early tool gets used for a reason, losses are understandable, and at least two routes/tactics are viable in missions two and three. Adjust dominant positions or pointless tools before adding content.

### 15.3 Performance budget and measurement

Initial target: smooth 60 FPS at 1280 x 720 on the owner's development machine with the chosen preset. Also test 1920 x 1080 and document the result. These are targets to measure, not current guarantees.

- [ ] **PERF-01** Record exact hardware, renderer, editor/export build, resolution and quality settings in the QA report. Measure at least 60 seconds of active combat including a large cut, cluster burst and AI planning.
- [ ] **PERF-02** Measure median and p95 frame time, worst visible hitches, terrain rebuild cost, AI slices, active effect count and memory. Initial target: p95 frame time at or below 16.7 ms on the primary preset; investigate action-induced stalls above 50 ms.
- [ ] **PERF-03** Keep physics fixed at 60 Hz and use render interpolation where needed. Changing frame rate must not change shot travel, ammo, turn duration or damage outcomes for identical seeded commands.
- [ ] **PERF-04** Bound debris, particles, cluster children, mine chains and audio voices. Pool effects only when measured churn justifies it; release completed instances and imported scene references correctly.
- [ ] **PERF-05** Run several consecutive matches and shelter transitions to identify accumulating resources. Terrain deformation and larger maps must remain within tested limits.
- [ ] **PERF-06** Add a lower-cost preset if necessary, then verify it still preserves guide visibility, hazard readability and intended art direction. Do not solve performance by hiding important feedback.

### 15.4 Export and handoff

- [ ] **BUILD-01** Pin the actual installed Godot build and export templates; the prior implementation reports 4.7.2 Standard. Verify the executable before documenting the release. Do not combine an engine upgrade with this art/combat overhaul without a separate need.
- [ ] **BUILD-02** Produce a Windows export in an ignored local build directory and package a clearly named version. Check whether export templates are present before relying on editor-only success.
- [ ] **BUILD-03** Start the export outside the Godot editor. Verify all assets, fonts, audio, shaders, input, save paths, settings and three-mission continuation in that build.
- [ ] **BUILD-04** Provide a short `README.md` with exact project-open, editor-run, exported-run and relevant test commands, controls, save behavior, build/version, known limitations and asset credits. Commands must match the actual exported filename and installed executable.
- [ ] **BUILD-05** Update the project log with branch/commit, shipped behavior, tests actually run, screenshots/build evidence and unresolved issues. Do not mark a gate passed based only on planned tests.
- [ ] **BUILD-06** Push each scoped branch and integrate through a PR to `development_branch`. Verify the combined version; prepare a release PR to `main` only after the owner approves the build.

## 16. MVP definition of done

Every item below must be met or explicitly revised by the owner. A visually incomplete build with these systems in code is still a prototype.

- [ ] **DONE-01** The owner can identify the intended Wild Ones-inspired direction in a playable scene: coherent stylized scenery, visible expressive characters, recognizable tools and satisfying effects.
- [ ] **DONE-02** No photographic battle background, temporary geometric actor or unstyled ground block remains in the three player-facing missions. Debug scenes may retain fixtures.
- [ ] **DONE-03** Movement, drag aiming, cancellation, guide upgrades and camera behavior pass the input matrix; no accidental firing from menus or pause.
- [ ] **DONE-04** Eight tools work, have distinct roles and complete presentation, and respect ownership, collision, ammo and action budgets.
- [ ] **DONE-05** Terrain looks and behaves consistently after repeated cuts/additions; players can use changed terrain tactically; unsupported scenery is handled.
- [ ] **DONE-06** Three CPU profiles use legal actions, make visible tactical choices, can miss and do not routinely stall or deliver unavoidable opening defeats.
- [ ] **DONE-07** All three missions are reachable in sequence after fresh start, save/reload and migration from the old two-mission build. Unimplemented missions are explicitly unavailable.
- [ ] **DONE-08** Scout and the friend are rescued through gameplay, join in the promised order and have usable distinct actions. The friend is playable in the post-chapter skirmish.
- [ ] **DONE-09** Shelter, team upgrades, individual tabs, customization and first-clear economy work; retry/replay cannot duplicate progress and no purchase is mandatory.
- [ ] **DONE-10** Menus/settings are fully functional and persistent. HUD is legible at supported sizes; relevant accessibility controls change behavior.
- [ ] **DONE-11** Meaningful automated checks pass and the exported Windows build completes the interactive acceptance run with recorded results.
- [ ] **DONE-12** The owner has reviewed the playable result. Remaining limitations, performance and actual content count are described honestly before proposing a `main` merge.

## 17. Risks, decisions and practical fallback routes

| Risk | Early test | Response if it fails |
| --- | --- | --- |
| Free asset packs do not form a coherent style | P1 mixed-scene sample under the real camera | Narrow to one art family, revise palette/materials or present a specific replacement pack. Do not quietly return to primitive characters. |
| Human/dog rig lacks usable animations or attachments | Import one actor with held weapon and a full action cycle | Choose a more complete compatible rig; reduce optional outfit variants before compromising core movement/fire animation. |
| Attractive terrain meshing breaks collision or holes | P2 crater/contour spike across chunk boundaries | Retain accurate grid-aligned geometry with proper materials while resolving contour issues. Record the remaining visual limit and review it explicitly. |
| Larger maps make units tiny and turns slow | Camera and route test before dressing mission three | Improve camera/route design, add useful cover and reduce empty distance or population. Width alone is not progression. |
| Eight tools become a large integration risk | Four-weapon checkpoint before advanced tools | Ship that checkpoint for feedback, keep remaining tools listed as incomplete, then continue. Do not rename it the completed MVP without a scope revision. |
| AI looks perfect or foolish despite error | Seeded outcome distributions plus normal play | Tune planning quality, decision diversity and error together. Do not rely on larger random errors alone. |
| Supporter growth makes the game too slow | Four-member roster and actual interleaved queue test | Improve pacing and enemy count first. Any future deployment cap is an owner-visible design change. |
| Save changes strand current users | Version-one fixtures and migration run before release | Preserve backup, repair migration and keep the old build usable; never require silent deletion of user progress. |
| Campaign reward/upgrade loop becomes trivial or punishing | Spreadsheet/simple simulation of guaranteed income and several purchase paths | Change costs/effects and encounter design; keep no-upgrade completion possible. No separate analytics infrastructure required. |
| Art polish hides poor control feel | Complete match at P3 and P4 | Fix input/camera/turn feedback before producing more missions. |

Proposed defaults are documented so implementation can proceed after **go** without repeatedly asking about routine details. Decisions that materially change the product remain explicit: replacing humans with animal leads, buying assets, removing requested systems, reducing the MVP scope or releasing to `main`.

## 18. Full ten-mission campaign after the MVP

The existing story names remain a useful outline. These are subsequent milestones, not implemented content. Every later mission must pass the same route, destruction, save and readable-objective checks as the MVP.

| Mission | New tactical purpose | Dependency and completion evidence |
| --- | --- | --- |
| 4: Switchback | Vertical movement and battery recovery | Existing friend participates in story combat; multiple safe ascent choices; camera handles height without hiding landings. |
| 5: Broken Bridge | Build/remove crossings and control access | Bridge/teleport choices change routes; mission remains solvable without purchased bonuses. |
| 6: Waterline | Medicine retrieval with water-edge risk | Use static water and authored hazards first; moving water is separate scope. Supplies create an optional risk/reward route. |
| 7: Radio Ridge | Rescue a radio operator through cover | Add recruit only with a defined role, animations and queue implications; avoid an untested escort system hidden inside a content task. |
| 8: Blackout | Multiple positions around a power station | Reuse tested objective interactions; require relocation and tool choice rather than just extra enemy HP. |
| 9: Last Ascent | Combine movement, cover and resource pressure | Test longer encounters and full roster pacing; no unavoidable opening kills. |
| 10: Light the Valley | Final relay operation and campaign resolution | Final objective chain, ending, complete save state, replay and New Story reset; one full ten-level playthrough after integration. |

- [ ] **FULL-01** After MVP feedback, revise the campaign difficulty/reward curve using measured session length and available upgrades.
- [ ] **FULL-02** Author missions four/five as one content checkpoint, six/seven as the next, then eight through ten. Keep each individually playable and testable.
- [ ] **FULL-03** Introduce additional weapon types only where the mission or character creates a clear tactical need. Candidate later additions: drill projectile, grappling/rope tool, unusual guided weapon and shield. Each needs its own control/AI/destruction acceptance work.
- [ ] **FULL-04** Expand shelter dialogue, cosmetic options and biome dressing after the full campaign route works. Preserve the two leads and supporters' individual identities.
- [ ] **FULL-05** Review multiplayer only as a separate architecture and product milestone. Do not imply the fixed-step solo simulation already provides cross-machine deterministic networking.

## 19. First implementation session after approval

This is the immediate executable sequence; it prevents another session from drifting straight into a fourth mission while the existing experience remains weak.

1. Read this plan, current log, any owner revisions and branch state. Confirm no user edits are overwritten. Start `fix/campaign-navigation` from current `development_branch`.
2. Preserve the user's save and record the current build. Run the existing import/behavior baseline with isolated test saves. Reproduce the first-clear continuation and the known two-mission ending through actual UI.
3. Fix the reproduced defect or discoverability issue, add visible mission availability and honest content-end wording, then verify fresh/continued first-to-second transitions. Log evidence and integrate the scoped fix.
4. Start `art/wild-ones-direction`. Gather the specific Wild Ones references, create the art specification and asset manifest, and import a minimum character/environment/weapon sample.
5. Build the real-camera style sample plus the bounded terrain material/contour spike. Capture it at supported resolutions and demonstrate an animated character holding/firing a real asset weapon.
6. Report the navigation result, show the actual visual sample, state unresolved asset/terrain issues and obtain the owner's visual feedback before duplicating the style across missions. Continue only with authorized independent work while that feedback is pending.
7. Proceed through P2-P8 in dependency order, completing and testing reviewable branches. Update the log after every completed increment and report which acceptance criteria actually passed.

The next implementation handoff should therefore contain a tangible progression fix and a real asset-based visual checkpoint. It must not claim the entire overhaul is finished because a document, import or new mission exists.

## 20. Review and tracking protocol

- Every checkbox has a stable task ID. Revisions can cite IDs, such as `AIM-04` or `WEAPON-15`, instead of ambiguous paragraphs.
- On **go**, approved proposals become the implementation baseline. Record owner-requested changes in this file and the log before executing affected tasks.
- Mark a task complete only with code/content and relevant evidence. Link its PR/test/visual result in a short milestone record rather than filling this plan with unverified success claims.
- If a task proves larger than expected, report the concrete obstacle, completed part and next bounded action. Do not silently remove it or count a placeholder as the finished feature.
- At a checkpoint, report: what changed for the player, where to run it, what was tested, what remains incomplete, and the next step. Main-branch release remains a separate owner decision.
- **Current state: planning only. No gameplay implementation is authorized by publication of this file. Wait for owner revisions or the command go.**
