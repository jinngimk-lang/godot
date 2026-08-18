# Object-Only Peel Calm Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild Peel Calm as a fully real-time, no-hands, mouse-direct label peeling game whose Godot runtime matches the owner-approved object-only mockup across five product scenes.

**Architecture:** Keep the existing peel simulation, label deformation, residue, audio, inspection, and screenshot CI as gameplay authority. Delete the visible hand/forearm/choreography stack, project pointer position directly into `LabelVisual`, add a repository-owned hand-shaped cursor, expand session/product presentation to five hero objects, and rebuild the HUD/scene rail to match the reference.

**Tech Stack:** Godot 4.7.1, GDScript, StandardMaterial3D/ShaderMaterial, procedural meshes, custom SVG cursor, GitHub Actions screenshot capture.

**Spec:** `docs/superpowers/specs/2026-08-18-realtime-reference-rebuild-v2-design.md`

## Global Constraints

- No visible hand/arm models.
- No full-screen still/video playback.
- Pointer path is `mouse -> projected grip -> label simulation` with no hidden hand proxy.
- Controls: LMB peel, RMB rotate, Wheel zoom, R reset, 1/2/3/4/5 scene select, Esc pause.
- Five scene order: Coffee Shop, Jar, Tin Can, Supermarket, Can.
- Exact-head Godot screenshots are the visual acceptance gate.
- Delete obsolete hand/reference-playback files after runtime references are gone.

---

### Task 1: Lock new contracts with RED tests

**Files:**
- Modify: `tests/test_realtime_render_authority.gd`
- Modify: `tests/test_input_reference_contract.gd`
- Modify: `tests/test_reference_profiles.gd`
- Modify: `tests/test_product_presentation.gd`
- Modify: `tests/test_hud_chrome_presentation.gd`
- Modify: `tests/test_guided_journey_presentation.gd`
- Modify: `tests/test_runner.gd`

**Interfaces:**
- Produces contract methods `PeelLab.get_visual_interaction_contract()` and `PeelLab.get_control_contract()`.
- Requires product kinds `paper_cup`, `sauce_jar`, `tin_can`, `clear_bottle`, `soda_can`.

- [ ] Add assertions that the scene has no `LeftHand`, `RightHand`, `CinematicHandPresentation`, `HandChoreographyPresentation`, `HandSurfaceSmoothing`, `ForearmPresentation`, or `CrumpleHandStaging` nodes.
- [ ] Require visual contract `{visible_hands:false, pointer_grip:"mouse_direct", cursor:"hand"}`.
- [ ] Require control contract to include `zoom:"Wheel"` and `scenes:"1/2/3/4/5"`.
- [ ] Require five variants in the fixed scene/kind order.
- [ ] Require `ProductPresentation` to build semantic nodes for jar, tin can, and soda can.
- [ ] Require the scene rail to have five buttons and remain visible during a mid-peel state.
- [ ] Commit tests only and run CI; expected result is RED because the current runtime still has visible hands and only three variants.

---

### Task 2: Remove the hand proxy and make pointer grip direct

**Files:**
- Modify: `scripts/peel_lab.gd`
- Modify: `scenes/peel_lab/peel_lab.tscn`
- Create: `assets/ui/peel_cursor.svg`

**Interfaces:**
- `get_visual_interaction_contract() -> Dictionary`
- `_screen_to_plane(screen_pos: Vector2, plane_z: float) -> Vector3`
- `LabelVisual.set_peel(progress: float, grip_local: Vector3)` receives pointer-derived grip directly.

- [ ] Delete `_left_hand` / `_right_hand` variables and hand construction from `_build_world()`.
- [ ] Replace pinch-anchor flow in `_process()` with direct screen projection -> `get_effective_grip()` -> `set_peel()`.
- [ ] Remove support-hand updates from inspection/reset.
- [ ] Install the custom hand cursor in `_ready()` and keep its hotspot at the fingertip.
- [ ] Add mouse-wheel zoom bounded to the reference-safe camera range.
- [ ] Update key handling to 1–5 and R reset.
- [ ] Remove hand/forearm/choreography nodes from `peel_lab.tscn`.
- [ ] Run CI; pointer/scene/control tests must pass before proceeding.

---

### Task 3: Replace three variants with the five object set

**Files:**
- Modify: `scripts/session/session_model.gd`
- Modify: `scripts/peel/label_print.gd`
- Modify: `scripts/presentation/reference_composition.gd`
- Modify: `scripts/presentation/reference_backdrop.gd`
- Modify: `scripts/presentation/reference_lighting.gd`
- Modify: `scripts/presentation/venue_presentation.gd`

**Interfaces:**
- `SessionModel.VARIANTS` fixed order: Coffee Shop, Jar, Tin Can, Supermarket, Can.
- Container profile kinds match the spec.

- [ ] Define five scene/profile dictionaries with product-specific label size, material behavior, copy, and backdrop/lighting IDs.
- [ ] Make all five post-peel actions `inspect`; no squeeze/crumple stage is part of the north star.
- [ ] Extend label-print copy for Tomato Basil, Golden Peaches, Yuzu Sparkling, and Lemon Sparkling Soda.
- [ ] Map pantry/tin/can scene IDs to appropriate backdrop families and tuned lighting.
- [ ] Tune FOV per kind so hero objects occupy 55–70% viewport height.
- [ ] Run profile and label tests.

---

### Task 4: Add real-time jar, tin can, and soda can geometry

**Files:**
- Modify: `scripts/presentation/product_presentation.gd`
- Test: `tests/test_product_presentation.gd`

**Interfaces:**
- `ProductPresentation.apply_profile(profile)` accepts five semantic kinds.
- Semantic nodes: `JarGlass`, `TinCanBody`, `SodaCanBody`.

- [ ] Build `sauce_jar` from a continuous glass cylinder/lathe, red sauce interior, metal lid, and contact shadow.
- [ ] Build `tin_can` from brushed-metal cylindrical body plus rolled top/bottom rims.
- [ ] Build `soda_can` from an aluminum body with shoulder taper, top/bottom rims, and condensation.
- [ ] Keep meshes static between scene changes and rotate the entire presentation with inspection yaw.
- [ ] Run product tests and scene smoke.

---

### Task 5: Rebuild HUD to the approved object-only mockup

**Files:**
- Modify: `scripts/presentation/hud_chrome_presentation.gd`
- Modify: `scripts/presentation/guided_journey_presentation.gd`

**Interfaces:**
- Named nodes: `ProgressPanel`, `ControlsPanel`, `HowToPanel`, `JourneyRail`.
- Rail contains `Scene0` … `Scene4`.

- [ ] Upper-left: scene title, peel progress percentage, gold progress bar.
- [ ] Left control stack: LMB / RMB / Wheel / R / 1–5 / Esc.
- [ ] Right tutorial: four numbered steps matching the mockup and no hand-model wording.
- [ ] Bottom rail: five persistent scene buttons with gold active state.
- [ ] Keep rail visible during active peel and keep center contact zone clear.
- [ ] Run HUD tests and capture smoke.

---

### Task 6: Remove obsolete hand and legacy presentation files

**Files to delete once unreferenced:**
- `scripts/hands/hand_visual.gd`
- `scripts/presentation/cinematic_hand_presentation.gd`
- `scripts/presentation/hand_choreography_presentation.gd`
- `scripts/presentation/hand_surface_smoothing.gd`
- `scripts/presentation/crumple_hand_staging.gd`
- `scripts/presentation/forearm_presentation.gd` if no non-hand runtime responsibility remains
- `scripts/presentation/reference_peel_playback.gd`
- hand-specific deterministic/smoke tests
- `assets/models/hands/hand_left.glb`
- `assets/models/hands/hand_right.glb`
- hand attribution files if no hand asset remains

- [ ] Confirm code search/tree references are gone.
- [ ] Delete dead files and remove deleted suites from `tests/test_runner.gd` / workflow if necessary.
- [ ] Run import/parse and full deterministic tests after deletion.

---

### Task 7: Expand exact-head visual evidence to five scenes

**Files:**
- Modify: `tests/capture_reference_frames.gd`
- Modify: `.github/workflows/godot-check.yml` only if artifact filenames need expansion.

**Interfaces:**
- Expected captures: `coffee.png`, `coffee_peel38.png`, `jar.png`, `jar_peel49.png`, `tin.png`, `tin_peel41.png`, `market.png`, `market_peel45.png`, `can.png`, `can_peel33.png`.

- [ ] Stage each real label directly at a representative progress and pointer grip.
- [ ] Assert no hand presentation nodes and no reference playback before capture.
- [ ] Capture all ten frames from exact PR head.
- [ ] Upload one artifact and inspect every frame.

---

### Task 8: Visual convergence loop

**Files:**
- Modify only the presentation/profile files implicated by screenshot evidence.
- Maintain checkpoint: `docs/superpowers/checkpoints/2026-08-18-object-only-north-star.md`.

- [ ] Compare Coffee Shop first against the approved mockup: hero scale, label curl/residue, cursor contact, left/right/bottom UI geometry, table integration, backdrop color/depth.
- [ ] Fix the highest-value visual mismatch, run exact-head CI, inspect screenshot, and record the result in the checkpoint.
- [ ] Repeat for Jar, Tin Can, Supermarket, and Can.
- [ ] Do not merge while any Visual RED condition from the spec remains.

---

### Task 9: Final verification and merge

- [ ] Exact head parses and launches on Godot 4.7.1.
- [ ] All deterministic and smoke tests pass.
- [ ] Ten screenshot evidence frames exist and were inspected.
- [ ] No visible hands, no playback overlay, no dead hand files.
- [ ] PR title/body describe the object-only architecture.
- [ ] Mark PR ready and squash-merge only after the visual gate passes.
