# Peel Calm

A PC-first, touch-ready Godot relaxation game prototype about peeling café-style production labels cleanly from cups.

## Engine

- Godot **4.7.1 stable**
- GDScript
- No required third-party Godot plugins

## Run locally

1. Clone this repository or use **Download ZIP** on GitHub.
2. Open Godot 4.7.1 Project Manager.
3. Import/select the repository's `project.godot`.
4. Press **F5** (or the Run Project button). `F6` also works when `peel_lab.tscn` is the open scene.

The repository is designed to be the complete runnable project. You should not need Blender, an AI model service, private environment variables, or manual path repair for the first playable slice.

## Controls

- Move the pointer to the **gold peel-edge dot** on the label.
- Hold the **left mouse button**.
- Pull away from the current edge. The visible hand is intentionally damped and the label advances only when pull tension exceeds adhesion.
- Releasing early keeps the already-peeled progress; grab the current edge again to continue.
- Press **R** to reset immediately.
- Completing the full label awards a `CLEAN PEEL` score and automatically resets to a fresh cup after a short pause.

The input boundary already accepts mouse and touch event shapes, but mobile export and phone haptics are deliberately deferred until the PC peel feel is validated.

## V1 interaction target

The vertical slice focuses on one high-quality interaction: catch the edge of a generic printed cup label, pull against resistance, peel it progressively, hear/see the release, complete the peel, receive a score, then reset to a fresh cup.

## Verification

GitHub Actions uses the official Godot 4.7.1 Linux x86_64 release, verifies its published checksum, imports the project headlessly, and runs deterministic tests plus a scene smoke test.

A green CI run proves project/script/resource correctness; it does **not** prove that peel resistance, hand animation, audio or material feel is satisfying. Those remain local experiential playtest items on the player's actual display/audio hardware.

## Current visual scope

The first slice intentionally uses repository-local procedural/basic Godot geometry for the cup, label and hands. This keeps the project directly runnable without model-tool dependencies while the peel interaction is being validated. Higher-quality authored/generated models can replace these presentation assets later without changing the peel contract.
