# Asset sources

These premade assets support the first stylized playable checkpoint. Bundled licenses are kept with the selected files. CC0 1.0 permits copying and adapting these source assets in the public project. Godot import metadata records engine import settings.

| Location | Creator and pack | Source and license |
| --- | --- | --- |
| `kenney/characters/` | Kenney, Animated Characters Bundle 4.0. Selected character rig, separate animation clips, survivor and military skins, and accessory models. | [Pack mirror and original license](https://github.com/series-ai/jam-ready-assets/tree/main/kenney-animated-characters-bundle/3D/characters). Bundled `License.txt` states CC0. |
| `kenney/nature/` | Kenney, Nature Kit 2.1. Selected forest, rock, foliage and camp models. | [Creator's OpenGameArt upload](https://opengameart.org/content/nature-kit) and bundled `License.txt`, CC0. |
| `kenney/weapons/` | Kenney, Blaster Kit 2.1. Selected launchers, grenade, projectile, crate and referenced colormap. | [Creator's OpenGameArt upload](https://opengameart.org/content/blaster-kit) and bundled `License.txt`, CC0. |
| `quaternius/dog.fbx`, `cat.fbx`, `wolf.fbx` | Quaternius, Animal Pack Vol. 2. Dog, cat and wolf with idle/walk animations. Cat and wolf added 15 November 2026 from the same creator archive. | [Creator's OpenGameArt upload](https://opengameart.org/content/animated-animales-low-poly), CC0. |
| `backgrounds/lake_chelan.jpg` | North Cascades National Park Service Complex. Existing prototype backdrop. | [Photo credit and rights](backgrounds/CREDITS.md). |

Selected packs were acquired on 10 November 2026. The imported model sources are unmodified. Runtime scale, palette and animation selection live in the presentation code. See the [CC0 1.0 deed](https://creativecommons.org/publicdomain/zero/1.0/).

Animal meshes retain their original vertex colors and surface materials. Idle-pose bounds measured in Forward+ are cached in `campaign_actor.gd` to give consistent grounding in rendered and headless runs. The human assets remain archived, but the playable cast and wardrobe now use animals.

## 15 November surface revision

- `surfaces/Ground037_1K-JPG_*`: ambientCG Ground037, photographed moss/forest ground. Source: https://ambientcg.com/view?id=Ground037 .
- `surfaces/Ground048_1K-JPG_*`: ambientCG Ground048, ground surface. Source: https://ambientcg.com/view?id=Ground048 .
- Both texture sets distributed under CC0: https://docs.ambientcg.com/license/ . Color and OpenGL normal maps drive the terrain material; roughness sources are retained for later material tuning.
- `kenney/nature/tree_oak.glb`: same Nature Kit 2.1 archive and bundled CC0 license as the existing scenery. Runtime smoothing adjusts shading only.

## Current cartoon direction

The photographed surface maps above are unused experiments, retained only locally. Active terrain uses a cartoon shader. Upright cartoon characters are optional local Plumberry Plains Vol. 1 files: **not redistributed here**. See ../CARTOON_ASSET_SETUP.md for the creator, licensing and installation. Existing Quaternius quadrupeds are the redistributable fallback only.

## 16 November 2026 — clubhouse and interface

- `kenney/ui_adventure/`: selected 2× PNG panels, buttons, checkbox/arrow/progress pieces and pattern from Kenney's **UI Pack - Adventure 1.1**. [Creator's upload](https://opengameart.org/content/ui-pack-adventure); downloaded archive `kenney_ui-pack-adventure.zip`. CC0, original license included. Runtime nine-slice scaling and tinting are in `interface_skin.gd`.
- `kenney/furniture/`: 15 selected original OBJ/MTL sources from Kenney's **Furniture Pack 1.0**: architectural wall/floor/window pieces, table, desk, chair, bookcase, books, lamps, plants, rug, bench, radio and coat rack. [Creator's upload](https://opengameart.org/content/furniture-kit); archive `kenney_furniturePack.zip`. CC0, original license included. Runtime sizing, material treatment and placement are in `clubhouse_decor.gd`.
- `fonts/Fredoka.ttf`: unchanged variable font from [Google Fonts](https://github.com/google/fonts/tree/main/ofl/fredoka), font source Git blob `349b6ecef8a358ede29b7bf74a08196be5d71b25`. SIL OFL 1.1; copyright/license retained in `Fredoka-OFL.txt`. OpenType weights are selected at runtime.

Kenney preview/sample images were inspected locally but are not included as game assets. The unrelated Plumberry no-source-redistribution rule remains unchanged; that directory stays ignored.
