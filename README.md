# Peel Calm

Peel Calm is a PC-first, touch-ready Godot relaxation game about peeling café-style production labels cleanly from cups. The current complete-playable candidate focuses on a short, replayable ASMR ritual rather than timers or difficulty pressure.

## Engine

- Godot **4.7.1 stable**
- GDScript
- No required third-party Godot plugins
- No runtime AI service, private secret, Blender install, or external asset download required

## Run locally

1. Clone this repository or use **Download ZIP** on GitHub.
2. Open Godot 4.7.1 Project Manager.
3. Import/select the repository's `project.godot`.
4. Press **F5** (or the Run Project button).

The repository is the complete runnable project. A fresh clone/ZIP is intended to run without manual path repair.

## How to play

- Move the pointer to the small warm/gold peel-edge dot.
- Hold the **left mouse button** and pull gently away from the cup.
- Pull tension must overcome the current label's adhesive resistance before the peel advances.
- The right hand follows with damping rather than snapping directly to the cursor.
- Releasing early preserves peel progress; re-grab the current gold edge to continue.
- At 100%, the last adhesive bond releases over a short detach transition. The printed label becomes a free object held by the right hand and is no longer anchored to the cup.
- After a clean detach, the game awards score/stamps and automatically presents the next item.

Controls:

- **Esc** — pause / resume
- **R** — reset the current label without erasing run progression
- **Shift+R** — restart the whole run, including score/stamps/unlocks
- Close the game window normally when finished.

Mouse is the current primary control. The input boundary also accepts touch event shapes, while mobile export and phone haptics remain deferred until the PC tactile experience is validated.

## Replayable tactile progression

The run starts with one tactile profile and unlocks two more through clean peels. These are not text-only variants: each profile changes real peel parameters and presentation dimensions.

- **Warm Paper** — balanced adhesive and medium paper length; available immediately.
- **Silky Long** — longer label, lighter adhesive, stronger speed response; unlocks after 2 clean peels.
- **Crisp Seal** — shorter label with firmer catch, larger release steps, and stronger angle response; unlocks after 5 clean peels.

Successful labels increase score and stamps without making elapsed time the primary pressure mechanic. Unlocked tactile profiles rotate into subsequent items automatically.

## Tactile presentation baseline

The current runtime preserves the owner-reported V1 fixes:

- **True detach:** `DETACHING -> HELD` removes the final cup anchor instead of stretching the label into an infinite ribbon.
- **Bounded paper geometry:** mouse travel cannot make the label longer than its physical representation.
- **Print stays on the paper:** order/drink graphics are rendered into the label texture and leave the cup with the label.
- **Authored hands by default:** normal runtime uses repository-local rigged CC0 hand GLBs. The left hand uses a cup-holding pose and the right hand uses a pinch-oriented peel pose. The procedural five-finger implementation is only a fallback.
- **Real Foley:** repository-local CC0-derived WAV assets provide slow/fast adhesive texture, paper flex, micro releases and final release. Interaction state drives which layer responds.

Hand-model provenance and license material are stored under `assets/models/hands/`. Audio source/license provenance is recorded in `assets/audio/ATTRIBUTION.md`.

## Verification

GitHub Actions uses the official Godot 4.7.1 Linux x86_64 release and verifies its published checksum. The automated gate covers:

- headless project import and explicit parser/load guard;
- deterministic peel/input/score/lifecycle/geometry/hand/Foley tests;
- deterministic session progression and real tactile-variant parameter tests;
- main-scene smoke requiring authored hand assets, printed-label wiring and repository-local Foley;
- repeated in-process reset and `complete -> next -> unlock -> pause -> restart` flow.

A green CI run proves project/script/resource contracts and machine-observable gameplay behavior. It does **not** prove that resistance feels pleasant, hand placement looks natural enough on a particular display, Foley balance is relaxing on a particular speaker/headphone setup, or the visual style matches the owner's taste. Those remain experiential playtest items and should be judged by running the final `main` build locally.

## Asset and runtime boundary

Cup and peel geometry are repository-local/procedural. Normal hand presentation is repository-local authored GLB with a procedural fallback. External assets committed to the repository must have auditable redistribution/license metadata. The playable game does not depend on repository AI-agent availability or any cloud service at runtime.
