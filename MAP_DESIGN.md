# Larger existing maps and smoother walking

Owner revision, 16 November 2026. Branch: feature/expanded-natural-maps.

## Scope

Enlarge and improve the existing three skirmishes and two story battlefields. The campaign still has two missions, the same rescue and the same saved progression. New missions are deferred. Subsequent priorities remain mines, combat/audio/UI polish and species abilities.

## Reference study and map ideas

Reviewed [Team17's W.M.D design retrospective](https://www.team17.com/news/team17s-100-games-part-seventeen-2016-overcooked-worms-w-m-d-and-more) and its linked [terrain illustration](https://www.team17.com/hs-fs/hubfs/Imported_Blog_Media/5de8d546228585_5b52126e94890-2.jpg?height=942&name=5de8d546228585_5b52126e94890-2.jpg&width=1400). The illustration combines a tall landmark, side shelves and an arch with lower ground. The developers describe assembling landscapes from authored components. Our application is original curved landmasses, differing elevations and destructible cover that create local decisions. The [official W.M.D page](https://www.team17.com/games/worms-w-m-d) also identifies terrain shelter as a tactical feature.

These are visual/design references, not a recreation of their maps or exact physics. The retrieved illustration was inspected locally and is kept under ignored .godot. It is not a game asset. Full gameplay videos were not reviewed, and an attempted store screenshot retrieval failed; no screenshot/video analysis beyond the inspected illustration is claimed.

| Existing map | Layout and tactical intent |
| --- | --- |
| River Outposts | Three unequal river banks, a central high arch and a traversable lower passage. Trade exposed high ground for shelter; narrow water gaps remain deliberate jumps. |
| Split Ridgeline | Offset summits, a central covered passage and an eroded ravine. Crests interrupt direct shots; high arcs and changes in position matter. |
| Broken Causeway | Four differently shaped landmasses, short gaps and a thin destructible connector. Blasting the connector can change the route. |
| First Signal | Longer rolling approach to Scout, then a separated lookout ridge and a further bank. Existing rescue objective; no additional mission or recruit. |
| Ferry Landing | Uneven shore, a covered central bank and a raised far landing. Existing allies and enemies occupy distinct elevations across the larger battlefield. |

## Implemented foundation

- Simulation capacity grows from 32 x 16 to **64 x 24 world units**, at the same 0.125-cell resolution and character size. Every battle silhouette spans more than 60 units horizontally. Characters and shots are not scaled down.
- Shared BattleMaps definitions author curved profiles, irregular undersides and carved passages. Skirmish and story spawns use actual supporting terrain height.
- Terrain rendering and dirty rebuilds derive chunk counts from the grid. Destruction works beyond the old right edge. Scenery and water extend across the new width; premade landmark props differentiate layouts.
- Walking automatically clears grounded rises up to **two cells (0.25 units)** when the path, body clearance and landing support permit it. Small descending steps retain ground contact. Larger walls, low ceilings, water gaps, airborne motion and knockback retain their physical consequences.
- CPU plans use the same updated movement/collision rules. No accuracy buff, perfect release or new ML system was introduced.
- Camera panning follows the larger bounds while retaining the close starting view and existing mouse aiming/zoom controls.

## Verification and playtest priorities

All eleven behavior suites passed: terrain_lab, terrain_contour, match, solo, aim, supply, campaign, skirmish_maps, shotgun, camera and walking. Map checks cover footprint, asymmetry, elevation variety, supported spawns, actual covered passages and attack plans for both enemy positions. Contour checks include craters beyond the old width. Both mission loops still complete with mouse-aimed shots, saves, shelter upgrades and retries.

Tests with fixed old map coordinates were updated to use actual unit positions or terrain-derived bounds. A seeded CPU miss is valid; tests still require a completed turn and the broader hit/miss distribution. Walking checks cover both ascent directions, descent, tall walls, low ceilings, knockback and gaps.

Next owner playtest: walk across shallow slopes without jumping, jump the intentional gaps, try the river underpass, damage the causeway, pan to the far units and complete the existing missions. Tune traversal distances, cover density and local sightlines from that feedback. Bigger maps alone do not establish good balance or final art quality.

## Delivery after this checkpoint

1. Refine these map routes, landmark composition and terrain surfaces from playtesting.
2. Add the planned mine behavior and CPU avoidance with clear arming/trigger rules.
3. Improve sound, reactions, weapon/status UI and feedback.
4. Add distinct animal support abilities and deepen the existing upgrade screens.
5. Revisit campaign expansion only when the owner requests it.

Publish task branches and merge tested work into development_branch. Main promotion is manual and belongs to the owner.
