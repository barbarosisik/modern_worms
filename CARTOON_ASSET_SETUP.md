# Upright cartoon character setup

The owner approved free local character assets on 15 November 2026. The public repository contains code and setup instructions; it does not redistribute these models.

## Download and install

1. Download **Plumberry Plains Vol. 1** from https://chibipup.itch.io/plumberry-plains-free-3d-cozy-game-animal-characters using its free download option.
2. Read the archive's `TERMS.md`. It permits use/modification in commercial games and distribution embedded in compiled/packaged projects, but prohibits redistributing raw or modified source assets. The pack is free of charge, not CC0. The creator discloses AI-assisted graphics.
3. Create `assets/local_plumberry/` inside this project.
4. Copy these files from the archive into it: `maple-the-cat.glb`, `ollie-the-terrier.glb`, `ziggy-the-wolf.glb`, `TERMS.md`, `README.md`.
5. Open/import `project.godot` in Godot. The models and generated import files stay ignored by Git. Never force-add this directory.

Miska and Nova both use the cat, Scout uses a smaller terrier, and opponents use the wolf. The adapter retains existing character names, outfits and saves. Idle, walk/run and jump clips are selected from the imported animations, with presentation recoil. Other supplied clips are not yet connected to game reactions.

Without the local files the game falls back to the older CC0 quadrupeds so a fresh clone still runs. That fallback is not the intended final character appearance. Install the files above to see the approved upright direction.

## Test

Use New Story to inspect the characters without starting/resetting a save until Begin Story is pressed. Use Solo vs CPU for a disposable match. LMB hold/pull/release fires; RMB cancels. Test movement, jumping, aiming, turning and the wardrobe appearance. Owner visual acceptance is pending.
