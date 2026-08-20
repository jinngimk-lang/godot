# Reference Fidelity Final Checkpoint — 2026-08-20

## Workspace

- Branch: `feat/reference-fidelity-20260820`
- Base commit: `e2d7cae18830f3ce78b41535a528931fbb07259f`
- Engine: Godot `4.7.1.stable.official.a13da4feb`
- Runtime authority: realtime Godot scene; no composited gameplay screenshot

## Delivered result

- Reframed the presentation around the object-only reference: a large centered product, warm defocused venue, compact left controls/progress, four-step right tutorial, and a five-scene bottom rail.
- Added five materially distinct heroes: paper coffee cup, sauce jar, tin can, clear supermarket bottle, and soda can.
- Rebuilt the visible peel as one continuous high-density paper mesh with a localized corner lift, bounded stretch, a rounded crease, fibrous backing, adhesive traces, and an arc-length-preserving released curl.
- Added tactile phase separation: breakaway, peeling, held release, settling, resolved residue, mouse rubbing, clean completion, reset, and next-scene readiness.
- Replaced broad residue bands with deterministic scattered paper islands and irregular glue/fiber streaks that remain readable against dark scenes.
- Added full-release clearing so the detached label leaves the hero while residue remains available for inspection.
- Added the requested post-peel interaction: after the sheet settles, Continue remains gated while the small hand cursor displays `RUB ↔`; held back-and-forth LMB motion inside the old label footprint fades glue and fibers, switches the HUD to `Residue Clean`, and unlocks Continue at 100%.

## Reference comparison

### Macro

- Hero scale, framing, warm background, left/right chrome, and five-tab rail now follow the supplied Coffee Shop gameplay composition.
- All five scenes keep the entire product visible and use venue-specific lighting/background treatments.

### Meso

- At the reference 38% state, most printed copy stays attached and readable while only the grabbed upper-right region lifts.
- At 100% peel, the sheet holds briefly as curled paper, settles away, and exposes adhesive and torn fibers. The second progress pass then makes those layers visibly fade under mouse rubbing until the object is clean.

### Micro

- Paper has coarse/fine fiber breakup, pore-scale normal response, high roughness, edge thickness, backing color, and adhesive translucency.
- Product silhouettes gained molded lid highlights, jar liquid/meniscus detail, tin chimes, bottle punt/meniscus, and can shoulder/opening detail.

The implementation is procedural realtime rendering, so it does not reproduce every pixel of the offline concept render. The major controllable mismatches in composition, label behavior, lifecycle, material separation, residue, and navigation have been addressed.

## Fresh verification

- `--headless --path . --script res://tests/test_runner.gd` — PASS: all deterministic object-only tests.
- `smoke_object_only_complete_flow.gd` — PASS: mouse grab → load → peel → settle → rub residue → clean → next scene, including exact-once completion and RUB cursor feedback.
- `smoke_scene.gd` — PASS: complete playable object-only scene.
- `smoke_reference_scene.gd` — PASS: persistent five-scene journey and localized corner peel.
- `smoke_label_cup_surface.gd` — PASS: all five labels follow product surfaces within `0.004 m`.
- `smoke_cafe_presentation.gd` — PASS: Coffee Shop hero, label, backdrop, and HUD.
- Reset/pause input-isolation and reset-loop smoke suites — PASS.
- Default project boot via `--headless --path . --quit-after 5` — exit `0`, no runtime error.
- `capture_reference_frames.gd` — PASS: 35 attached/peel/release/settle/resolved/scrub/clean frames across five scenes.
- `git diff --check` — PASS.

The legacy hand/crumple ritual smoke is intentionally outside this gate because the project north star and supplied reference require object-only interaction with no rendered hands or arms.
