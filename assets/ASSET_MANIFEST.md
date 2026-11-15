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
