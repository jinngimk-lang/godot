# Sensory Cup + Contained Ice V6 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make unlocked cups visibly distinct in silhouette and add one bounded, deterministic ice-content sensory layer without introducing free rigid-body chaos or touching peel/label authority.

**Architecture:** `SessionModel` remains the sensory-profile source of truth. Existing `cup_dimensions` drive real live-cup silhouettes. `CupContentsPresentation` consumes `contents_profile` plus the live cup dimensions and owns presentation-only ice meshes. Ice motion is deterministic and bounded by crumple progress/side/pulse; no ice node is a physics body and contents never influence peel, cup-surface, label lifecycle, score, or ritual authority.

**Tech Stack:** Godot 4.7.1, GDScript, existing `SessionModel`, `PeelLab`, `CupCrumplePresentation`, canonical headless CI plus X11/OpenGL 1280×720 visual capture.

## Global Constraints

- Preserve the pressure-free loop: no timers, fail states, grind pressure, or parallel economy.
- Preserve current Foley; do not replace the peel/crumple sound stack wholesale.
- Keep `LabelLifecycle` and peel/cup-surface math authoritative; contents are presentation-only.
- No `RigidBody3D`, `SoftBody3D`, general physics, or random calls for ice in V6.
- Ice must be finite, resettable, deterministic, and laterally contained; a filled iced cup may let cube tops peek slightly above the open paper rim for fixed-camera readability.
- Only the final unlocked profile exposes ice; warm/silky remain visually quiet and lidded.
- Machine gates prove contracts, not subjective pleasantness. Owner playtest remains the final comfort/aesthetic gate.

---

### Task 1: Sensory profile contract for real cup silhouettes and ice — COMPLETE

**Files:** `scripts/session/session_model.gd`, `tests/test_session_model.gd`

- [x] RED: Godot Check `31773222737` failed Unit Tests only because the final profile had no ice.
- [x] GREEN: `82846ce66ab99c6b96654baaa5546685c212b67e`, Godot Check `31773259711` passed all then-existing canonical gates.
- [x] Final silhouettes: warm `0.54/0.45/1.48`, silky `0.50/0.41/1.58`, crisp `0.58/0.47/1.38` (top/bottom/height).
- [x] Final crisp contents: 3 deterministic ice cubes, size `0.145`, motion gain `0.55`.

---

### Task 2: Deterministic contained ice presentation — COMPLETE

**Files:** `scripts/presentation/cup_contents_presentation.gd`, `tests/smoke_cup_contents_presentation.gd`, `.github/workflows/godot-check.yml`

- [x] Valid isolated RED: `f04c99c9b1e4107493a52c9ab0246206e740a9f8`, Godot Check `31773464688` reached the new smoke after older gates passed and failed exactly `CONTENTS_PRESENTATION_RED: missing bounded cup contents presentation`.
- [x] Initial GREEN: `3895ade00c7821ab6b07f77a64fd1f8befe95580`, Godot Check `31773540310` SUCCESS.
- [x] Presentation owns only `MeshInstance3D` ice under `IceContents`; no rigid/soft bodies, no random motion.
- [x] Ice positions and crumple movement remain finite, deterministic, resettable, and bounded.
- [x] Visual RED #1 proved mathematically contained ice was hidden low in the cup.
- [x] Visual RED #2 proved an opaque lid/cap still hid contents even after lifting them.
- [x] Visual RED #3 proved the low fixed camera needed rim-surface/back-half staging, not merely an open top.
- [x] Final contents smoke requires rim-readable staging, at least two cubes in the camera-readable back half, bounded max-pulse motion, and exact reset transforms.

---

### Task 3: Wire contents into the real ritual lifecycle — COMPLETE

**Files:** `scenes/peel_lab/peel_lab.tscn`, `scripts/peel_lab.gd`, `tests/smoke_scene.gd`, `tests/smoke_reset_loop.gd`

- [x] Valid production wiring RED: `3289f9a5046f4f6353b715738be9288f02cc9b42`, Godot Check `31773674283` failed Scene Smoke only on missing production `CupContentsPresentation`.
- [x] `PeelLab` owns `_contents_presentation`, forwards current variant, forwards real crumple progress/side/pulse, and resets the presentation through the existing ritual reset path.
- [x] Fifth completed ritual + deliberate next reaches `crisp_seal` with exactly 3 ice meshes.
- [x] Real `_process_crumple_pointer()` changes the ice transforms; Shift+R returns to warm/no ice without duplication or stale contents.
- [x] Iced crisp cup exposes an open top and hides runtime/cafe opaque lid layers; warm/silky restore the closed lid presentation.

---

### Task 4: Cross-profile geometry regression + real-frame visual handoff — COMPLETE PENDING PR MERGE-TREE REVIEW

- [x] Real visual capture first exposed a V6 regression: `LabelVisual` cached warm_paper's frustum, so silky floated and crisp sank inside the new cup silhouette.
- [x] Converted that defect into a three-profile `smoke_label_cup_surface.gd` RED. Godot Check `31774241948` failed with `silky_long` radial error `0.04154 m` against a `0.004 m` limit.
- [x] `LabelVisual` now synchronizes against the live `Cup` frustum whenever tactile dimensions change. Subsequent canonical gates pass warm/silky/crisp surface and taper-normal checks.
- [x] Separate open-top verifier `31774529771` proved iced crisp still sealed behind a cap before the visibility fix.
- [x] Final feature head `421bde4f47843ab679e2c7e1c4fdd71ae85f80fd` passed canonical Godot Check `31775089087`: import, configured default launch, units, scene, all presentation smokes, all-three cup-surface checks, ritual, repeated reset, pause isolation, and reset isolation.
- [x] Final fixed-camera X11/OpenGL capture run `31775174612` succeeded. Fresh crisp frame visibly shows all three ice cubes at the open rim while the label remains attached to the wider live cup; mid-crumple keeps cubes near the rim rather than flying free.
- [x] Capture log confirms final fresh crisp state: `lid_visible=false`, `cap_top=false`, contents `3`, local ice positions approximately `(-0.184,0.675,-0.077)`, `(0.000,0.670,-0.107)`, `(0.184,0.675,-0.077)`.
- [ ] Open PR against latest `main`, validate GitHub's exact merge tree including PR #43's V5 repeated-squeeze correctness repair, and hand it to PRIMARY for independent attack.

## Evidence boundary

Machine-proven: deterministic profiles, three distinct live cup silhouettes, live-frustum label binding, bounded physics-free ice, open/closed top restoration, real crumple forwarding, exact reset behavior, canonical Godot 4.7.1 regression gates.

Real-frame-proven: the fixed camera can visibly distinguish warm/silky/crisp silhouette changes; fresh crisp visibly exposes three ice blocks; crisp label no longer disappears inside the wider cup.

Not machine-proven: whether the final ice material, amount, hand/cup staging, crumple feel, and eventual ice-rattle audio are subjectively soothing. Those remain owner playtest gates.
