# Peel Calm

Peel Calm is a PC-first, touch-ready Godot 4.7.1 tactile/ASMR game about peeling real-time paper labels from everyday containers, inspecting the adhesive imprint, and rubbing the remaining glue and fibers clean with the mouse.

The current approved presentation is object-only. The product remains the visual authority; there are no rendered hands or arms and no still-image/video layer pretending to be gameplay.

## Run locally

1. Install Godot **4.7.1 stable**.
2. Clone the repository or download its ZIP.
3. Import `project.godot` in Godot Project Manager.
4. Press **F5**.

No third-party Godot plugin, runtime AI service, private secret, Blender installation, or external asset download is required to play.

## Current playable loop

1. Move the small hand cursor to the raised label corner.
2. Hold **LMB** and apply outward movement. The paper loads against the adhesive before the initial breakaway.
3. Continue pulling. Progress only comes from new outward pointer work; holding still cannot create free peel progress.
4. At 100%, the complete paper sheet curls, holds briefly, and settles away from the hero product.
5. The HUD switches from `Peel Progress` to `Residue Clean`. Hold **LMB** over the old label footprint and rub back and forth.
6. Adhesive traces and torn fibers fade as the residue-cleaning pass advances.
7. At 100% clean, Continue unlocks and the next product can be selected.

## Controls

- **LMB drag** — peel label; after release, rub residue clean.
- **RMB drag** — rotate/inspect the product.
- **Mouse wheel** — zoom.
- **R** — reset the current scene and interaction.
- **1 / 2 / 3 / 4 / 5** — switch directly between showcase scenes.
- **Esc** — pause/resume.

Held input is quarantined across pause, reset, detach, cleanup completion, and scene changes. A fresh press is required after each boundary.

## Five showcase scenes

1. **Coffee Shop** — kraft takeaway cup, molded black lid, thermal order label, warm café window.
2. **Jar** — glass food jar, sauce volume and meniscus, rustic paper, warm pantry/kitchen mood.
3. **Tin Can** — manufactured metal body and chimes, grocery wrap, cooler merchandising environment.
4. **Supermarket** — clear bottle, liquid volume and punt, coated commercial label, refrigerated retail lighting.
5. **Can** — aluminum beverage can, shoulder/top details, thin compliant wrap, convenience/drink-display mood.

Each scene has its own product silhouette, material response, environment plate, lighting profile, label dimensions, adhesive parameters, bend stiffness, backing thickness, and residue behavior.

## Current implementation baseline

- Large centered real-time hero composition with compact left progress/controls, four-step right tutorial, and persistent five-scene rail.
- One continuous high-density printed-paper mesh with localized upper-corner peel, bounded stretch, rounded hinge, opaque fibrous backing, and visible thickness.
- Paper material with coarse/fine fiber breakup, pore normal response, high roughness, and scene-specific backing/adhesive colors.
- Lifecycle: `ATTACHED -> PEELING -> DETACHING -> HELD -> SETTLING -> RESOLVED -> RUB_RESIDUE -> CLEAN -> NEXT_READY`.
- Deterministic post-peel rubbing model: pressed movement inside the residue footprint advances cleaning, reversal motion receives tactile weighting, hovering/holding still/outside motion does not clean.
- Persistent irregular glue streaks and paper islands that remain on the vessel after peel and disappear only through the cleaning pass.
- Repository-local peel Foley and hand-shaped software cursor.

## Verification

The canonical `Godot Check` workflow uses the official Godot 4.7.1 Linux build and verifies:

- fresh import and script parse/load;
- configured default F5 entrypoint;
- deterministic peel, input, lifecycle, paper, material, residue, and scrub tests;
- real object-only grab → load → peel → settle → rub → clean → next-scene flow;
- all five product/environment bundles;
- pause/reset input isolation;
- attached, peel, release, settle, dirty residue, partial scrub, and clean captures for every scene.

Automation proves deterministic behavior and machine-observable rendering contracts. It cannot prove that resistance, rubbing duration, Foley balance, or visual taste feels ideal to the owner; those remain local playtest gates.

## Repository guidance for agents

Every new local or cloud agent must start with:

1. `.agents/PROJECT_NORTH_STAR.md`
2. `.agents/PROJECT_KNOWLEDGE.md`
3. `.agents/skills/peel-calm-reference-realism/CURRENT_HANDOFF.md`
4. `docs/superpowers/checkpoints/2026-08-20-reference-fidelity-final.md`
5. current `main`, tests, workflow results, and newest runtime captures

Historical hand/forearm/crumple documents and tests are not authority for the current object-only direction.

## Next direction

Future work should improve the current loop without replacing or regressing it:

1. Owner playtest and tune breakaway force, per-substrate drag distance, scrub duration, and cursor feedback.
2. Add spatial/local cleaning so the exact rubbed area clears first, with restrained glue-roll/paper-crumb feedback and matching Foley.
3. Continue product realism: higher-quality silhouettes, glass/metal edge response, contact shadows, paper microdetail, and better backdrop/live-surface integration.
4. Improve tear-edge variation and release curl while preserving printed-copy readability and bounded paper stretch.
5. Add settings/accessibility and touch-device validation only after the PC mouse loop is stable.

Do not reintroduce visible hands/arms, fake full-screen gameplay playback, timer pressure, or score grinding without explicit owner direction.
