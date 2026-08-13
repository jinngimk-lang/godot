# Peel Calm

A PC-first, touch-ready Godot relaxation prototype about peeling café-style production labels cleanly from cups.

## Engine

- Godot **4.7.1 stable**
- GDScript
- No required third-party Godot plugins

## Run locally

1. Clone this repository or use **Download ZIP** on GitHub.
2. Open Godot 4.7.1 Project Manager.
3. Import/select the repository's `project.godot`.
4. Press **F5** (or the Run Project button). `F6` also works when `peel_lab.tscn` is the open scene.

The repository is the complete runnable project. The current slice does not require Blender, an AI model service, private environment variables, an internet connection at runtime, or manual path repair.

## Controls

- Move the pointer to the small warm/gold peel-edge dot.
- Hold the **left mouse button** and pull away from the current edge.
- Pull tension must overcome adhesion before the label advances. The visible right hand is damped rather than snapping directly to the cursor.
- Releasing early keeps the peeled progress; grab the current edge again to continue.
- Press **R** to reset immediately.
- At 100%, the last adhesive bond releases over a short detach transition. The whole printed label then becomes a free object held by the right hand; it is no longer anchored to the cup.
- A `CLEAN PEEL` reward appears after the true detach, then the scene resets to a fresh label.

The input boundary already accepts mouse and touch event shapes, but mobile export and phone haptics remain deferred until PC tactile feel is validated.

## Tactile V2

V2 is specifically aimed at the first local playtest failures:

- **No rubber ribbon at 100%:** peel geometry has a bounded physical length and switches to a cup-independent held-label representation after detachment.
- **Print stays on the paper:** order/drink graphics are rendered into the label texture instead of floating as a separate world-space text node.
- **Authored hands by default:** normal runtime uses repository-local rigged CC0 hand GLBs derived from the Godot XR Tools hand models. The left hand uses the authored `Cup` pose and the right hand switches into `Pinch Tight` for the peel grip. Peel Calm owns the damping/grip contract; no Godot XR Tools addon is required at runtime. A procedural five-finger hand remains only as a fallback if an authored asset fails to load.
- **Real Foley:** the normal sound path uses repository-local CC0-derived tape/paper WAV assets for slow/fast adhesive texture, paper flex, micro releases and the final release. Source/license provenance is recorded in `assets/audio/ATTRIBUTION.md`.

Hand model provenance and the upstream CC0 license are stored under `assets/models/hands/`.

## Verification

GitHub Actions uses the official Godot 4.7.1 Linux x86_64 release, verifies its published checksum, imports the project headlessly, runs deterministic tests, and performs a scene smoke test that requires both authored hand GLBs, their runtime wrapper, the V2 lifecycle, printed-label node and local Foley streams.

A green CI run proves project/script/resource contracts and scene loadability. It does **not** prove that resistance feels pleasant, the authored hand placement looks natural enough on the player's display, or the Foley is relaxing rather than annoying. Those remain experiential playtest items.

## Asset boundary

The cup and peel mesh remain repository-local procedural geometry, while the normal hand presentation is now repository-local authored GLB with a procedural fallback. A fresh clone remains deterministic and dependency-free. Future cup/hand upgrades can replace presentation assets through the existing interfaces. External assets committed to the repository must have auditable redistribution/license metadata.
