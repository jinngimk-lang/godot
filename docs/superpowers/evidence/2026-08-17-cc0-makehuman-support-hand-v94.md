# CC0 MakeHuman support-hand v94 — structural candidate gate

Date: 2026-08-17
Base product main: `90d225fcd124cbd80f2fe2d84222584ee4324a3a`
Initial candidate binary commit: `5d586b52cfe94df04cc8e15df21a860f9717a997`
Reference-envelope rescale commit: `8f12fe57c835e03f85a0177a75722e03b95f5355`
Measured-frame aligned candidate: `9b78bb14758e9d5987027b04b2d48dd48c30de29`
Authoring branch: `spike/cc0-makehuman-support-hand-v94`

## Why this spike exists

The locked Café reference still has one dominant Macro mismatch: the support hand should visibly wrap the paper cup with palm volume, four-finger enclosure, and thumb opposition. The existing Godot-XR-derived support hand remained open / side-contacting. Checkpoint 72 rejected a rig-preserving subdivision of that old hand because it improved smoothing only and did not improve the support-grasp anatomy.

This v94 spike changes the *source structure* rather than tuning the old pose. It uses a rights-safe CC0 MakeHuman-derived FPS arm rig whose native Blender controls were independently inspected and whose fixed native frame 20 produced a semantic cup-proxy preview with palm contact, finger enclosure, and thumb opposition.

## Non-negotiable stop condition

This spike does not authorize CCD, endpoint chasing, wrist/orbit/yaw/translation sweeps, per-finger numeric grids, or other disguised pose search. One fixed source-rig Cup pose is tested in the current runtime. A single evidence-driven structural frame correction is permitted when a runtime capture proves the source frame is not mapped to the existing cup frame; a grid is not.

## Build / failure / correction receipts

### Structural source build

The first successful source-normalization build produced a left-only GLB with:

- selected substantial source component: 2,049 vertices / 2,038 polygons;
- 1,621 vertices / 1,609 polygons after the original spatial arm-side crop;
- 50-bone armature;
- semantic actions `Default pose`, `Pinch Up`, `Cup`, `Pinch Tight`;
- 20 real fingertip polygons on `HandNail`.

The first Godot candidate passed import, default launch, and deterministic unit tests, including the authored-hand asset contract, but failed `Scene smoke`: runtime support-hand mesh extent was `1.719`, above the existing `<=1.40` hero-hand presentation envelope. The tests were not changed.

### One scale-only correction

The source scale was corrected once from measured mesh envelope data, without changing pose/position/rotation/finger values. That rebuilt GLB passed the complete Godot 4.7.1 machine gate and produced nine fresh runtime frames in run `32020404963`, artifact `9285129666`.

The visual gate **rejected** that machine-green candidate. Fresh `cafe.png` showed two Macro failures:

1. a large bare source forearm crossed the hero composition despite the intended wrist crop;
2. the fixed frame-20 hand curled around empty air on the cup's right side instead of enclosing the cup.

Machine green was therefore not treated as visual acceptance.

### Structural root cause 1 — crop semantics

The spatial `z` crop was removed. The aligned builder now deletes vertices only when they have no non-trivial skin membership in the real left `hand.L`, palm, thumb, index, middle, ring, or pinky deform groups. Build run `32021039608` reports:

- source component: 2,049 vertices / 2,038 polygons;
- 1,657 vertices retained by actual hand/finger skin bones;
- 392 vertices removed as forearm-only;
- final hand mesh: 1,657 vertices / 1,632 polygons;
- 20 real fingertip polygons remain assigned to `HandNail`.

No spatial wrist threshold is involved in this crop.

### Structural root cause 2 — semantic Cup frame mismatch

A one-off Godot diagnostic measured the actual Café cup target directly in `LeftHand/AuthoredHand` local space at run `32020753168`. The pinned measurement is `tools/support_hand_cafe_target_v94.json`:

- cup center: `(-0.0764426, 0.00385927, -0.0127513)`;
- cup axis: `(0.686103, 0.686103, -0.241922)`;
- cup radial from semantic wrist: `(0.262142, 0.0770450, 0.961949)`.

This diagnostic also exposed a legacy presentation detail that the earlier evidence text had simplified incorrectly: `HandVisual` initially sets authored scale `2.25`, but `ForearmPresentation` subsequently sets the runtime authored-hand scale to `4.15`. The aligned candidate therefore keeps the previously machine-green asset scale fixed instead of attempting another scale optimization. This pass changes only crop semantics and one rigid frame mapping.

`tools/build_cc0_support_hand_aligned.py` reconstructs the source frame-20 semantic Cup frame from the native Blender rig (palm center, four finger roots/tips, palm-to-finger radial, and cross-product cup axis), canonicalizes it, then computes exactly one orthonormal rigid transform from that source frame to the measured Godot frame. There is no search loop and no candidate sweep.

Aligned build run `32021039608` / artifact `9285359168` proves the algebraic mapping:

- center error: `6.13e-08`;
- radial dot target: `1.00000009`;
- cup-axis dot target: `1.00000008`;
- semantic actions preserved: `Default pose`, `Pinch Up`, `Cup`, `Pinch Tight`;
- output GLB: 278,292 bytes.

The bot committed the aligned binary as `9b78bb14758e9d5987027b04b2d48dd48c30de29`. This evidence update intentionally triggers the exact-head Godot recheck for that binary.

## Machine gate

The exact candidate head must pass the existing Godot 4.7.1 contract without weakening it:

1. project import / parse guard;
2. configured default launch;
3. deterministic unit suite;
4. authored hand asset contract (`PackedScene`, `Skeleton3D`, `AnimationPlayer`, semantic actions, non-empty renderable mesh, `HandSkin`, `HandNail`);
5. reference / café / forearm / reset / pause / input smokes;
6. fresh nine-frame runtime capture.

Any importer, animation-name, skeleton, semantic-material, or runtime error is a candidate defect. Do not change the tests merely to accept the asset.

## Visual gate — locked Café reference

At minimum inspect fresh `cafe.png`, `cafe_peel38.png`, and `cafe_crumple55.png` against the locked Café reference.

### Accept structurally only if all are true

- the left palm visibly contacts the cup rather than floating beside it;
- index/middle/ring/pinky read as wrapping around the vessel silhouette rather than an open side-contact pose;
- thumb opposition is visually legible;
- hand scale is human relative to the cup;
- bare source forearm no longer crosses the composition;
- wrist/sleeve transition is not a new dominant Macro defect;
- the new source materially reduces the support-enclosure mismatch.

### Reject if any are true

- the hand is mirrored, inverted, exploded, off-screen, or obviously wrong scale;
- fingers still wrap empty air / remain open beside the cup;
- a bare source forearm remains the dominant hero shape;
- the apparent improvement is only mesh quality while enclosure remains wrong;
- the sleeve/wrist seam becomes a larger Macro defect;
- machine contract is weakened to accommodate the asset.

## What a structural pass would mean

A structural pass would *not* complete Stage 1. It would only prove a better support-hand source. Remaining high-value work would include material/skin realism, semantic wrist-to-sleeve integration, and the peel-hand pinch/contact lane. Final completion still requires locked-reference convergence and owner playtest.
