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
4. Press **F6/F5** (or the Run Project button).

The repository is designed to be the complete runnable project. You should not need Blender, an AI model service, private environment variables, or manual path repair for the first playable slice.

## V1 interaction target

The vertical slice focuses on one high-quality interaction: catch the edge of a generic printed cup label, pull against resistance, peel it progressively, hear/see the release, complete the peel, receive a score, then reset to a fresh cup.

Current feature work is on `feat/peel-vertical-slice-v1` until independently verified and merged.

## Verification

GitHub Actions uses the official Godot 4.7.1 Linux x86_64 release, verifies its published checksum, imports the project headlessly, and runs repository tests/smoke checks when present.

A green CI run proves project/script/resource correctness; it does **not** prove that peel resistance, hand animation, audio or material feel is satisfying. Those remain local experiential playtest items.
