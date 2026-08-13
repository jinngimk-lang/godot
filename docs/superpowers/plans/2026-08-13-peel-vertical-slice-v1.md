# Coffee Label Peel ASMR — V1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development when subagents are available; otherwise execute inline task-by-task with RED→GREEN evidence and review checkpoints.

**Goal:** Deliver a Godot 4.7.1 project that can be cloned or downloaded from GitHub, opened directly via `project.godot`, and run into a first playable PC mouse peel interaction with touch-ready input boundaries.

**Architecture:** Keep deterministic peel progression separate from rendering. A device-neutral pointer adapter feeds a peel controller; the controller drives a small peel model and updates lightweight 3D presentation (cup, label strip, simple hands, UI and audio). The first slice uses no third-party Godot plugin and no required external model generator.

**Tech Stack:** Godot 4.7.1 stable, GDScript, built-in PrimitiveMesh/ArrayMesh/ImmediateMesh where useful, GitHub Actions using the official Godot Linux x86_64 release binary.

## Global Constraints

- Canonical runnable source is `jinngimk-lang/godot`.
- Engine baseline is exactly Godot 4.7.1 stable.
- First platform is PC mouse; gameplay logic must remain portable to touch without rewrite.
- No branded Starbucks/Luckin assets or trade dress.
- No required third-party Godot plugins, Blender, AI model service, private environment variables, or absolute local paths.
- CI green does not prove tactile quality; feel remains an experiential acceptance item.
- Behavioral code follows RED → GREEN with exact failing and passing heads recorded.

---

## File Map

- `project.godot` — engine/project settings and main scene.
- `scenes/peel_lab/peel_lab.tscn` — runnable vertical-slice scene.
- `scripts/peel/peel_model.gd` — deterministic adhesion/progress math with no scene dependencies.
- `scripts/input/pointer_state.gd` — device-neutral pointer state value object.
- `scripts/input/pointer_adapter.gd` — maps mouse/touch events into pointer state.
- `scripts/peel/peel_controller.gd` — interaction state machine and scene-facing orchestration.
- `scripts/peel/label_visual.gd` — lightweight procedural label strip/curl visualization.
- `scripts/hands/hand_visual.gd` — damped right-hand proxy and stable left-hand proxy.
- `scripts/audio/peel_audio.gd` — procedural/parameter-driven development audio without external assets.
- `scripts/scoring/score_model.gd` — completion/continuity score calculation.
- `scripts/peel_lab.gd` — scene composition, reset/next-cup loop and HUD wiring.
- `tests/test_runner.gd` — deterministic test entrypoint.
- `tests/test_peel_model.gd` — peel threshold/progress/completion/extreme-input tests.
- `tests/test_pointer_state.gd` — pointer contract tests.
- `tests/test_score_model.gd` — score math tests.
- `tests/smoke_scene.gd` — project/scene instantiation smoke test.
- `.github/workflows/godot-check.yml` — official Godot 4.7.1 download, import, unit and smoke checks.
- `README.md` — clone/ZIP → import → run instructions and controls.

## Task 1: Runnable Godot/CI scaffold

**Deliverable:** Fresh repository branch is a valid Godot 4.7.1 project with a minimal main scene and CI bootstrap. This task is configuration/scaffolding only and does not introduce gameplay behavior.

- [ ] Create `project.godot`, `.gitignore`, `.gitattributes`, `README.md`, and a minimal `scenes/peel_lab/peel_lab.tscn`.
- [ ] Add `.github/workflows/godot-check.yml` that downloads the official `Godot_v4.7.1-stable_linux.x86_64.zip`, verifies the published SHA256 `c7ff14fd28472c8d4f193043de30278dcf7e5241a1dcf7566b02e27addaa33ba`, imports headlessly, then conditionally runs test/smoke scripts when present.
- [ ] Push scaffold and confirm CI can import/load the minimal project before behavioral work.

## Task 2: RED for deterministic peel contract

**Interfaces to prove:**

```gdscript
PeelModel.new(config: Dictionary = {})
reset() -> void
step(tension: float, pull_speed: float, peel_angle: float, delta: float) -> Dictionary
get_progress() -> float
is_complete() -> bool
```

`step()` returns at least `{ "progress": float, "released": float, "completed_now": bool }`.

- [ ] Add tests proving below-threshold tension does not progress; above-threshold tension progresses; progress clamps to `[0,1]`; completion fires once; zero/extreme/INF-like sanitized input remains finite; release cannot reverse progress.
- [ ] Commit tests without `peel_model.gd` on the dedicated RED branch.
- [ ] Run CI and record the exact failing SHA/reason: missing production contract.

## Task 3: GREEN peel model + scoring + pointer value contract

**Interfaces:**

```gdscript
PointerState.new() # fields pressed, position, relative, velocity, released_this_frame
ScoreModel.score(base_area: float, completion: float, continuity: float) -> int
```

- [ ] Add equivalent tests to the feature branch.
- [ ] Implement minimal deterministic `PeelModel` with clamped parameters, thresholded incremental release, hysteresis-like speed/angle modifiers, monotonic progress and one-shot completion.
- [ ] Implement `PointerState` and `ScoreModel` only to the tested contract.
- [ ] Run unit tests green in CI.

## Task 4: Input adapter + interaction controller

**Controller states:** `IDLE`, `EDGE_HOVER`, `EDGE_LIFT`, `PINCHED`, `PEELING`, `RELEASED`, `COMPLETE`.

- [ ] Add tests/smoke assertions that a simulated pointer sequence can move the controller from edge acquisition into peeling and completion without depending on a physical mouse.
- [ ] Implement `PointerAdapter` accepting mouse button/motion and screen touch/drag events into the same state object.
- [ ] Implement `PeelController` with explicit state transitions, edge grab radius, filtered hand target, solver stepping, release/regrip, and exactly-one completion signal.
- [ ] Verify controller test green.

## Task 5: 3D peel lab presentation

- [ ] Add a calm 3D tabletop, generic procedural cup, rectangular label and camera/light rig using built-in Godot primitives so no external asset is required.
- [ ] Implement `LabelVisual` as a lightweight segmented strip: adhered points follow a cylindrical cup surface; detached points interpolate from peel front toward grip with controlled curl/sag. It should look paper-like rather than stretch like rubber.
- [ ] Implement simple stylized hands from built-in meshes; right hand follows filtered grip with damping, left hand stabilizes cup.
- [ ] Wire pointer ray/viewport mapping to the visible label edge and update HUD instructions.
- [ ] Add scene smoke test that instantiates all required nodes/scripts and exits cleanly headlessly.

## Task 6: Audio, completion reward and reset loop

- [ ] Implement development audio procedurally with `AudioStreamGenerator` so a fresh clone has audible state-responsive feedback without binary asset dependencies: slow peel noise, faster brighter peel noise, release tick and completion pop.
- [ ] Drive audio intensity/pitch/filter parameters from peel speed/tension/release rate.
- [ ] On complete, compute score once, show `CLEAN PEEL +<score>`, hold briefly, then reset a fresh cup/label. Add keyboard `R` reset.
- [ ] Add automated assertion that completion reward is emitted once and reset returns progress to zero.

## Task 7: Full verification, PR and mainline proof

- [ ] Run/inspect GitHub Actions on exact feature head: SHA verification, headless import, all unit tests, scene smoke.
- [ ] Review full branch diff against the approved design: no hard-coded local paths, no missing resources, no third-party runtime dependencies, no branded assets, main scene configured.
- [ ] Open PR with RED SHA, GREEN SHA, test evidence, limitations and local experiential checklist.
- [ ] Re-run checks on exact reviewed head; merge only that head.
- [ ] Fetch merged `main` SHA and verify main CI/import/test/smoke again.
- [ ] README must document: clone/ZIP, Godot 4.7.1 import, F6/F5 run, mouse controls, reset, and that tactile feel still needs local owner playtest.

## Acceptance Evidence Ledger

The implementation is not called complete until the PR records:

- exact RED SHA + expected failure;
- exact GREEN/reviewed head SHA;
- GitHub Actions run/check evidence;
- post-merge main SHA + green verification;
- known unverified experiential items (resistance feel, hand naturalness, sound pleasantness, GPU-specific presentation).
