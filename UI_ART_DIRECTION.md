# Ranger clubhouse interface

Updated 16 November 2026. Branch: feature/cozy-interface-shelter.

## Direction and sources

Follow the approved upright cartoon-animal direction: warm wood, cream paper, rounded lettering, coral action buttons and quieter teal scenery. Large character previews carry the home screen. Controls and progression stay recognizable across menus, battle HUD, shelter and upgrades.

The [Wild Ones fan gallery](https://wildonesgames.com/wild-ones-gallery/) was consulted for its catalog of pet, shop and inventory screens. Its inventory image download failed; no close visual review of that image or full-video review is claimed. The concrete art reference inspected for this pass was Kenney's Adventure UI preview/sample and Furniture Kit sample. This is an original arrangement of freely licensed assets rather than a copy of a Wild Ones screen.

- [Kenney Adventure UI, creator upload](https://opengameart.org/content/ui-pack-adventure): selected PNG panels, buttons, progress bars, icons and patterns, CC0. Source license retained in assets/kenney/ui_adventure/License.txt.
- [Kenney Furniture Kit, creator upload](https://opengameart.org/content/furniture-kit): selected original OBJ/MTL room, furniture and decoration sources, CC0. License retained in assets/kenney/furniture/License.txt.
- [Fredoka, Google Fonts source](https://github.com/google/fonts/tree/main/ofl/fredoka): unchanged variable font under SIL OFL 1.1, included with its license. InterfaceSkin.face uses numeric OpenType tags for reliable weight selection in Godot.
- [Godot FontVariation documentation](https://docs.godotengine.org/en/stable/classes/class_fontvariation.html) informed variable-weight configuration; [Environment documentation](https://docs.godotengine.org/en/stable/classes/class_environment.html) confirmed explicit color ambient lighting for the shelter.

## Implemented

1. Home screen: two columns, large animated Mara/Eli preview, grouped practice/settings controls, skirmish selector and a prominent Continue action when progress exists.
2. Shared InterfaceSkin theme: licensed paper/wood art, readable dark text, rounded font weights, coral primary actions, focus borders, themed sliders, checkboxes, tabs, popups and tooltips.
3. Campaign panels: distinct mission status cards and a portrait matching the selected character's upgrade tab. The existing costs, upgrades and two-mission progression are preserved.
4. Shelter: imported tables, desk, bookcase, chair, lamps, rug, plants, coat rack, windows and room shell replace the box-built room. The three existing walk/interact stations keep their positions and behavior.
5. Stronger teal tint for distant battle trees, sky and water. Foreground terrain and animal colors retain their existing values. Decorative UI layers ignore mouse input.
6. Character preview viewports use local anti-aliasing. Preview world updates continue while menus pause the game; the home viewport renders when visible.

## Validation

The twelve suites passed, including the new interface checks for actual pointer navigation, settings save/reload, Continue layout at 720p, station map access, selected recruit portrait, pause and rematch. Existing aiming/camera/campaign checks cover the input and progression paths after the menu restructuring.

Forward+ inspection captures cover home with/without Continue, settings, wardrobe, battle, shelter, team upgrades, individual upgrades, mission map, pause and result at 1280x720, plus home at 1920x1080. These are controlled inspection scenes; they do not substitute for owner playtesting of the art direction or a full manual balance review.

## Continue with this standard

- Use dark ink on paper, light type on coral/teal, clear focus indication and large input targets.
- Give new actions the PrimaryButton variation; keep Back/secondary actions on paper buttons.
- Keep scenery subdued behind the animals. Do not place an opaque dimming layer over the playable characters.
- Retain the separate team/individual upgrade screens and the larger existing maps. New campaign missions stay deferred.
- Next larger work remains map surface/landmark refinement, mines, audio/reaction polish and species abilities. Final animation/weapon-pose polish remains open.

All completed work integrates through its feature branch into development_branch. Main promotion remains manual.


## 16 November — Miska/Nova and next visual delivery
The leads are now Miska and Nova, both cats. The owner prefers the current UI direction; retain it.
VISUAL_ADVANCEMENT_PLAN.md is the current detailed handoff: shelter composition/interaction first,
then cat identity/animation, existing-map surfaces/landmarks, and combat/audio/UI polish.
These packages are planned, not delivered. Campaign expansion remains deferred.

## 16 November — shelter composition checkpoint
The shelter now uses orthographic cutaway framing, cream upper walls with teal paneling, wood trim and
separate floor planks. Three named station anchors own furniture/display positions and proximity checks.
Original map/kit/paw diagrams on licensed paper panels identify expedition, team and crew work.
Rescue/equipment/progress update from CampaignRun; nearby plaques highlight, and the bottom prompt exposes
the bound key plus a matching pointer action. Nova/Scout idle poses continue; window-side plant motion is subtle.
The room preserves a clear front walking lane. Added CC0 Kenney paneling, pillow, boxes, side table, small plant
and ceiling lamp from the existing licensed source archive. No new restricted models.
Owner acceptance is pending; see ONBOARDING.md and the latest PROJECT_LOG for validation and handoff.
