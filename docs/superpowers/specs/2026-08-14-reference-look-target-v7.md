# Peel Calm V7 Reference-Look Target

Owner visual references (2026-08-14) define the next presentation target. This file translates them into implementation constraints without claiming pixel-identical reproduction.

## Visual target

The playable close-up should read like a polished cozy mobile/PC tactile game rather than a debug diorama:

- foreground cup occupies the visual center and remains the highest-contrast object;
- hands enter naturally from frame edges and should not be dominated by long sleeves/forearms;
- cup/label/ice materials read as paper, printed adhesive, plastic/ice rather than smooth primitive meshes;
- lighting is warm, soft and high-key enough to preserve skin/cup detail; avoid crushed chocolate-black background values;
- background clearly suggests a real café/worktop environment through large, low-contrast shapes (window/light panel, counter/shelf/props) while staying de-emphasized;
- table reads as warm wood/stone rather than a dark flat slab;
- ice is visibly translucent/light-catching when the iced profile is active;
- composition is intimate: cup roughly 35–55% of frame height, with hands supporting the action rather than filling the frame;
- no UI/debug element should visually dominate the tactile scene.

## Rendering constraints

Current project uses `gl_compatibility`; Godot depth-of-field is not supported there. V7 therefore starts with a compatibility-safe approximation: low-frequency background geometry, soft light/value hierarchy, intentionally de-emphasized distant props and soft bokeh-style presentation. Changing the project renderer is a separate decision and must be justified by measured visual gain and regression/performance evidence.

## Interaction target

Presentation changes must preserve the existing input/ritual authority:

- `PointerAdapter`, `PeelController`, `LabelLifecycle`, `CupCrumpleModel`, `RitualFlow` stay authoritative;
- camera/presentation tuning must keep peel edge acquisition, re-grab, touch/mouse ownership and crumple gestures functional;
- no presentation node becomes score/progression/peel authority;
- visual polish must not add free rigid-body chaos or frame-rate dependent simulation.

## V7 iteration gates

1. Capture a real 1280×720 X11/OpenGL frame from the exact PRIMARY integration head before changing presentation.
2. Reject flat/dark-background candidates even if CI passes.
3. Require a dedicated cafe presentation smoke to prove background hierarchy, prop existence, warm table material and bounded lighting values.
4. Recapture fresh warm + iced profile after each production visual batch.
5. Compare visually for: background readability, cup contrast, hand/cup hierarchy, material readability, visible ice, no new occlusion/clipping.
6. Keep subjective beauty/comfort as owner-playtest evidence; machine tests only enforce gross non-regression and scene contracts.

## Initial non-overlapping scope

CHALLENGER owns only:
- `scripts/presentation/cafe_presentation.gd`
- `tests/smoke_cafe_presentation.gd`
- verifier-only capture files/workflows
- optional new presentation-only assets under `assets/presentation/reference_v7/`

PRIMARY currently owns the V6 12-path cup/contents/session/peel integration set. CHALLENGER must not rewrite those production paths in parallel.