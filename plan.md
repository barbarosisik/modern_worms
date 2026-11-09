# Modern Worms development plan

Updated 9 November 2026. Start with a Windows single-player artillery game built in Godot 4.7.2 Standard and typed GDScript. Show a real 3D battlefield from the side. Keep movement, aiming, shots, and terrain collision on a single vertical plane. The first playable milestone is one complete match against the computer, using original placeholder shapes until the setting and characters are chosen.

[Mechanics research](MECHANICS_RESEARCH.md) records the reference behavior and the measurements to collect from the Steam PC version of *Worms W.M.D.*. The values in the first prototype below are test inputs. Replace or tune them against recorded gameplay once the reference build and scheme are pinned.

## Roadmap

| Milestone | Task branches | Exit check |
| --- | --- | --- |
| **M1 · Destructible terrain lab** | `feature/destructible-terrain` | Start the lab from the menu, pause and resume it, and apply persistent display and audio settings. From a side camera, a rocket destroys a 3D ledge, a target falls, and a repeat shot reaches the rear wall. |
| **M2 · Movement, turns, and weapons** | `feature/turn-simulation`, `feature/unit-movement`, `feature/weapon-behavior`, `research/reference-measurements` | Two test teams can walk, jump, aim, fire a rocket or timed grenade, take damage, and hand off turns after the action settles. Reference captures inform the tuning. |
| **M3 · Playable solo match** | `feature/solo-opponent`, `feature/match-flow`, `feature/match-ui` | One person can start, finish, and restart a match against the computer on one arena. The HUD shows the active team, turn timer, health, wind, selected weapon, and shot power. The result screen offers a rematch and a return to the main menu. |
| **M3a · Mouse aim and CPU balance** | `feature/mouse-aim-and-cpu-balance` | Aim with the cursor and release a looping charge. Blue sees a short fading guide. The CPU can hit, miss, or pass under the same combat rules. Tune the default through solo playtests. |
| **M4 · Drag aiming and pickups** | `feature/drag-aim-pickups-and-arena`, `feature/match-economy` | Blue starts with a 12-dot guide. Pull back to set aim and power. A unit or projectile can collect a random supply between separated opposing units. Playtest pickup value and placement before setting prices. |
| **M5 · Characters and presentation** | `art/character-direction`, `feature/character-customization`, `feature/arena-presentation` | Replace the capsules with two customizable human leads. Check that silhouettes, shots, and crater edges remain readable against the landscape. |
| **M6 · Campaign and hub slice** | `feature/campaign-flow`, `feature/campaign-hub`, `feature/supporter-roster`, `feature/campaign-upgrades` | Play the first two levels end to end, rescue one supporter, return to a walkable room, and spend supplies through distinct team and character upgrade screens. |
| **M7 · Ten-level story** | `feature/campaign-levels`, `feature/cpu-difficulty-profiles` | The player completes an original ten-level story. Arenas grow, AI becomes more capable, and rescued friends and pets join the turn queue. |
| **M8 · Polish and release** | Scope per feature after the campaign slice | Playtest onboarding, UI scaling, accessibility, progression balance, and Windows export and performance. |

M3 is the single-match MVP. M6 is the first playable story slice. Rope traversal, vehicles, terrain generation, and multiplayer are separate design topics. Browser export is a separate platform decision because it affects the choice of renderer. [Godot renderer guide](https://docs.godotengine.org/en/4.7/tutorials/rendering/renderers.html)

## M4 · Solo playtest

- Press anywhere in the play area, pull opposite the intended shot, and release. Drag distance sets power, so a player can hold a power level or shorten the pull. Aim and power update together, with a dead zone for accidental clicks. Blue's fading guide has up to 12 dots, with prototype upgrade limits of 15, 18, and 20.
- Test a supply that appears at one randomly selected supported spot between living opponents with enough room. Moving through it or passing a rocket or grenade through it credits the team. Watch whether firing for supplies crowds out walking, and tune placement before the campaign depends on supplies.
- Use a real misty lake photograph to establish the arena's mood. Tune its contrast around aim dots, pickups, units, and the HUD. [Backdrop credit](assets/backgrounds/CREDITS.md)

## Campaign direction

**Working title** *Signal Fires*. Two volunteer rescuers, a man and a woman in love, return to their mountain valley after a flood. An armed salvage crew has seized the relay that would let isolated towns call for help. The couple crosses flooded routes, rescues neighbors and animals, and works its way back to the relay. Short conversations back at their shelter show how they make decisions together and what the valley means to them.

- Before level one, let the player customize each lead's appearance independently, starting with hair, clothing, and colors. Treat appearance as cosmetic and keep it separate from combat stats.
- Give each rescued friend or pet a stable place in the player turn queue after the two leads, in rescue order. Complete a rescue objective to unlock that supporter. Skip defeated units and keep the queue visible once the roster grows. Prototype with one supporter before expanding the party.
- After each cleared level, return to a walkable shelter using the same 3D side view. Approach the **map table** to see chapter progress and choose the next mission. Approach the **supply bench** for the team upgrade screen and the **roster board** for individual upgrades. Give each recruited character a subtab. Use proximity prompts and an interact key, and keep menus accessible with keyboard or mouse.
- Team upgrades affect the whole roster. Individual upgrades apply to one lead or supporter. Try an individual trajectory upgrade first, then use playtesting to price it and choose a first team upgrade. Proposed reset rule for the first slice: keep earned upgrades between levels during one campaign, clear temporary combat effects each battle, and reset skills and earned upgrades when starting a new campaign or standalone match. Retain cosmetic preferences separately. Restore the pre-level state on retry.
- Use short, increasingly distinct stages as in the original *Angry Birds*. Use a room with physical interaction points to pace missions, inspired by the House of Hades. [Rovio's original-level examples](https://www.rovio.com/articles/bringing-back-2012-dev-diary-3-progress-update/) · [Supergiant's House of Hades notes](https://www.supergiantgames.com/blog/6/)

| Level | Story beat and tactical step |
| --- | --- |
| 1 · First Signal | The couple reunites at the flooded lakeshore. Learn movement and the pull-back shot against a slow scout on the smallest arena. |
| 2 · Ferry Landing | Clear a route to the ferry and rescue a dog. Introduce the supply tradeoff and the first supporter turn. |
| 3 · Through the Pines | Use cover to reach an old friend cut off in a forest outpost. The CPU starts moving to improve firing positions. |
| 4 · Switchback | Cross a larger vertical arena and recover a battery for the relay. Enemies use cover and arcing shots more often. |
| 5 · Broken Bridge | Reopen a route for evacuees. The CPU compares more firing positions and uses craters to threaten crossings. |
| 6 · Waterline | Retrieve medicine near the rising lake. Both teams have longer shots and more contested supplies. |
| 7 · Radio Ridge | Escort a radio operator out of a winding ridgeline. The CPU plans around cover and protects vulnerable allies. |
| 8 · Blackout | Secure the relay power station. A larger arena introduces split routes and harder target choices. |
| 9 · Last Ascent | Climb to the relay with the full rescue crew. Stronger opponents apply pressure across several lanes. |
| 10 · Light the Valley | Retake the relay and guide the valley's evacuation. Use the largest arena and the toughest CPU profile. End with the couple and rescued crew sending the signal together. |

Build and playtest levels one and two before committing to later layouts. Give the CPU more time to compare positions, smarter target priorities, and smaller aim errors as difficulty rises. Keep its physics and turn rules consistent across the campaign.

## M1 · Destructible terrain lab

**Branch** `feature/destructible-terrain` from `development_branch`, after it has the planning baseline from `main`. Keep this first slice small enough to run from the Godot editor and review as one pull request. Deliver one scene, one stationary launcher, one gravity-driven target, one rocket, and one repeatable shot sequence. The purpose is to see the same opening in the terrain mesh and in collision.

### M1.1 · Bootstrap and project layout

- [ ] Open a new Godot 4.7.2 Standard project. Record the exact editor version and renderer in the project log. Set Forward+ for the Windows prototype and run the empty scene on the development machine before adding systems. If the renderer cannot run on that machine, record the failure and test Compatibility as the fallback. [Godot 4.7.2 download](https://godotengine.org/download/archive/4.7.2-stable/) · [Renderer guide](https://docs.godotengine.org/en/4.7/tutorials/rendering/renderers.html)
- [ ] Set the prototype physics tick rate to 60 Hz and use Godot's Input Map for `aim_up`, `aim_down`, `fire`, `fixture_shot`, `reset_lab`, and `toggle_collision_overlay`. Run `main.tscn` on startup with the lab as a child scene. Add a minimal `.gitignore` for Godot's generated `.godot/` directory and local export output. Commit project and source assets together.
- [ ] Use snake_case for files, Godot input actions, variables, and methods. Use PascalCase for named types and scene nodes. Keep IDs and code nouns neutral, such as `unit`, `team`, `rocket`, and `terrain`.

| Planned path | Responsibility |
| --- | --- |
| `project.godot` | Project settings, physics tick rate, input actions, and entry scene. |
| `scenes/main.tscn`, `scripts/ui/main.gd` | Main menu, pause, settings, lab HUD, and saved options. |
| `scenes/terrain_lab.tscn` | Camera, lighting, and simple actors. |
| `scripts/lab/terrain_lab.gd` | Set up the fixture, route input and physics ticks, and present simulation results. |
| `scripts/simulation/terrain_grid.gd` | Occupancy, queries, first terrain contact, blast cuts, and which chunks changed. |
| `scripts/simulation/ballistics.gd` | Advance a rocket and determine impact or escape using the terrain grid. |
| `scripts/simulation/terrain_simulation.gd` | Own the fixture, rocket state, impact, and target support. Share it with the lab and tests. |
| `scripts/presentation/terrain_mesh.gd` | Generate and replace the visible mesh for terrain chunks. |
| `tests/terrain_lab_checks.gd` | Run the repeat-shot and reset checks with Godot in headless mode. |

### M1.2 · Set up one arena and its camera

- [ ] Map simulation coordinates `(x, y)` directly onto the rendered plane `z = 0`. Use Y up. Put the camera on the positive-Z side and give the terrain depth on both sides of the plane. Use simple matte materials and directional lighting so an edge and the inside of a crater read clearly.
- [ ] Start with a near side-on perspective camera with a narrow field of view. Adjust the angle just enough to see depth. Keep the view fixed for the lab and put the launcher, target, opening, and rear wall in frame. Preview the same scene with an orthographic camera if perspective makes the firing plane hard to judge. [Camera3D reference](https://docs.godotengine.org/en/4.7/classes/class_camera3d.html)
- [ ] Use the following fixture as the starting shape. Build the terrain from a generated grid and spawn the target by its feet position. Keep fixture values together so any change to the baseline can be reviewed and recorded.

| Input | Starting value in world units |
| --- | --- |
| Arena bounds and grid | `32 × 16`, with `0.125` units per cell and `32 × 32` cells per render chunk. |
| Terrain | Floor across the arena up to `y = 2`. Launch shelf at `x = 2–6`, `y = 5.5–6.25`. Target ledge at `x = 12–14`, `y = 6–7`. Rear wall at `x = 24–25`, `y = 2–10`. Treat upper rectangle bounds as exclusive. |
| Launcher and target | Fixture muzzle at `(4, 7)`. Target feet at `(13, 7)` with a simple narrow collision shape. |
| Fixture rocket | Initial velocity `(20, 0)`, downward acceleration `4`, wind `0`, blast radius `2.5`. |
| Visual thickness | `1.0` along Z as a starting point. The collision grid remains in the firing plane. |

### M1.3 · Make the grid authoritative

- [ ] Store one solid or empty value per cell. Use one world-to-cell convention at boundaries. Give the lab explicit bounds for occupancy queries and rocket escape. Check target support and rocket collision against this same grid.
- [ ] Apply a blast by clearing cells whose centers lie inside the radius. Clamp the affected cell range to the map. Report only chunks with changed cells, plus adjacent chunks where a changed cell touches a shared edge. This lets the mesh reveal faces that had been covered by a neighbor.
- [ ] Generate the front and back surfaces and exposed edge walls of the solid terrain with `ArrayMesh`. Read neighboring cells across chunk borders so the mesh has no internal walls or missing edge faces. Build all chunks on load, then replace only affected chunks after a cut. Derive mesh coordinates and collision boundaries from the same cell size. [Godot ArrayMesh guide](https://docs.godotengine.org/en/4.7/tutorials/3d/procedural_geometry/arraymesh.html)
- [ ] Inspect a cut across a chunk boundary from a shallow camera angle. Check both adjacent chunks for gaps, stale faces, or holes that disagree with the collision overlay. Start with straightforward meshing and measure remesh cost before deciding whether to merge faces or smooth the edges.

### M1.4 · Add firing, impact, and falling

- [ ] Add an aim line and charge indicator. Hold and release `Space` to fire at the selected angle with the current charge, use Up and Down to aim, press `F` for the preset shot, and `R` to reset. Accept one rocket at a time. Display the current control hints and show when the rocket is still active.
- [ ] Advance the rocket at a fixed simulation tick. Sweep the segment from the previous position to the next through the grid to find the first solid cell. Resolve corner ties consistently. At impact, apply the blast once, report the impact point, and end the projectile. Retire any rocket that leaves the arena or reaches the flight limit. [Godot fixed-step processing](https://docs.godotengine.org/en/4.7/tutorials/scripting/idle_and_physics_processing.html)
- [ ] Recheck target support after the grid changes. A target that loses support falls under gravity and settles on the floor. Update the view from the simulation position. Keep the lab target driven by support and gravity so the effect of removing the ledge can be seen directly.
- [ ] Reset the terrain, target, rocket, aim, charge, and debug state in one action. Show the last impact position and which chunks were rebuilt. Use `F1` to toggle a firing-plane overlay when investigating a disagreement between the visible mesh and collision.

### M1.5 · Menus and settings

- [ ] Start at a main menu with Start terrain lab, Settings, and Quit. Give the lab a HUD with the controls, current aim angle, charge, and last impact.
- [ ] Open pause with Escape or the HUD button. Freeze the simulation and allow Resume, Settings, or Main menu. Settings should return to the screen that opened them.
- [ ] Apply windowed or fullscreen display and master volume. Play cues for firing and impact so volume can be checked. Save applied values locally and reload them on launch. Back discards edits made since the last application. Check navigation with the mouse and keyboard.

### M1.6 · Verify and hand off

- [ ] **First shot**. In a fresh lab, press `F`. Confirm that the rocket hits the ledge, the cut appears on the front face and along the terrain's depth, and the target falls to the floor.
- [ ] **Second shot**. Press `F` again. Confirm that the same trajectory crosses the old impact point and reaches the rear wall. Confirm that the floor away from the impact remains solid.
- [ ] **Reset and boundary checks**. Press `R` and repeat both shots. Verify that reset works while a rocket is in flight and that the first impact returns to the original ledge. Include a fast sweep through a thin barrier and a shot that leaves the arena.
- [ ] Run the scripted fixture checks with `godot --headless --path . --script res://tests/terrain_lab_checks.gd`, using the pinned Godot executable. Return a nonzero exit code if a check fails. Check the first hit, occupancy change, support loss, second hit, and reset. Compare the same fixed input sequence twice in one runtime. [Godot command-line guide](https://docs.godotengine.org/en/4.7/tutorials/editor/command_line_tutorial.html)
- [ ] Run the scene interactively on Windows. Confirm that the angle, thickness, and crater are legible during both shots. Record the build, controls, exact commit, results, and remaining issues in `PROJECT_LOG.md`. Open a pull request into `development_branch` and repeat the fixture on the combined branch before proposing a release merge to `main`.

## Decisions to revisit after M1

- **Reference tuning**. Record the *W.M.D.* PC build and local scheme. Measure turn handoff, movement, impact timing, and crater size before changing the physics targets for M2. Use the experiment IDs and method in the research file.
- **Turn design**. Begin with a turn timer, then decide whether a separate movement budget helps the game. Measure the retreat window and time allowed for secondary effects before locking handoff rules.
- **Opponent**. Start by trying a bounded set of angles and charge levels against the same simulation. Use player-visible damage, exposure, and safety to score candidates. Test that the opponent finishes its turn even when no good shot is available.
- **Progression**. After a complete solo match, decide whether coins and abilities are earned and spent within the match, across rounds, or as persistent unlocks. Start with the smallest economy that changes a tactical choice.
- **Theme and platform**. Choose the characters, world, and visual direction after the prototype shows how much screen space and depth the arena needs. Revisit platform targets before relying on renderer-specific effects.

Use [the project log](PROJECT_LOG.md) to record what shipped, how it was verified, and the next concrete task. Keep milestone branches based on `development_branch`. Merge into `main` through an owner-approved pull request after integration testing.
