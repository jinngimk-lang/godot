# CC0 MakeHuman support-hand v94 — structural candidate gate

Date: 2026-08-17
Base product main: `90d225fcd124cbd80f2fe2d84222584ee4324a3a`
Initial candidate binary commit: `5d586b52cfe94df04cc8e15df21a860f9717a997`
Reference-envelope rescale commit: `8f12fe57c835e03f85a0177a75722e03b95f5355`
Authoring branch: `spike/cc0-makehuman-support-hand-v94`

## Why this spike exists

The locked Café reference still has one dominant Macro mismatch: the support hand should visibly wrap the paper cup with palm volume, four-finger enclosure, and thumb opposition. The existing Godot-XR-derived support hand remained open / side-contacting. Checkpoint 72 rejected a rig-preserving subdivision of that old hand because it improved smoothing only and did not improve the support-grasp anatomy.

This v94 spike changes the *source structure* rather than tuning the old pose. It uses a rights-safe CC0 MakeHuman-derived FPS arm rig whose native Blender controls were independently inspected and whose fixed native frame 20 produced a semantic cup-proxy preview with palm contact, finger enclosure, and thumb opposition.

## Non-negotiable stop condition

This spike does not authorize CCD, endpoint chasing, wrist/orbit/yaw/translation sweeps, per-finger numeric grids, or other disguised pose search. One fixed source-rig Cup pose is tested in the current runtime. If the source normalization is clearly mirrored or axis-inverted, one evidence-driven structural sign/basis correction is allowed; a grid is not.

## Build receipts before Godot visual acceptance

### Structural source build

The successful source-normalization build produced a left-only GLB with:

- selected substantial source component: 2,049 vertices / 2,038 polygons;
- 1,621 vertices / 1,609 polygons after arm-side crop;
- 50-bone armature;
- semantic actions `Default pose`, `Pinch Up`, `Cup`, `Pinch Tight`;
- 20 real fingertip polygons on `HandNail`;
- maximum distal-bone-tail to selected real fingertip-surface distance about `0.028423` source units.

The first Godot candidate passed import, default launch, and deterministic unit tests, including the authored-hand asset contract, but failed `Scene smoke`: runtime support-hand mesh extent was `1.719`, above the existing `<=1.40` hero-hand presentation envelope. The tests were not changed.

### One structural scale correction

The candidate was not position/rotation/finger tuned. `tools/build_cc0_support_hand.py` was changed once to derive export scale from the actual cropped mesh envelope:

- fixed `HandVisual` authored-root multiplier: `2.25`;
- cropped source max extent before export scale: `2.0975327491760254`;
- target runtime max extent: `1.20`;
- derived export pre-scale: `0.2542669875084634`;
- predicted runtime extent after the fixed 2.25× presentation multiplier: `1.20`.

The target is deliberately below the existing `1.40` smoke ceiling and below the Café cup height (~`1.40`), matching the locked composition where the visible support hand is shorter than the cup. No pose, position, rotation, CCD, endpoint, or per-finger values changed in this correction.

The rebuilt GLB was committed at `8f12fe57c835e03f85a0177a75722e03b95f5355`. This document update exists to trigger the exact-head Godot 4.7.1 recheck after the bot-authored binary commit.

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

At minimum inspect fresh `cafe.png`, `cafe_peel38.png`, and `cafe_crumple55.png` against `art/acceptance_refs/v1/cafe_v1` / the locked original Café reference.

### Accept structurally only if all are true

- the left palm visibly contacts the cup rather than floating beside it;
- at least the index/middle/ring/pinky read as wrapping around the vessel silhouette instead of an open XR pose;
- thumb opposition is visually legible on the other side / front plane of the cup;
- hand scale is human relative to the cup and not catastrophically oversized/undersized;
- wrist/sleeve transition is not more distracting than the previous runtime;
- the new source materially reduces the Macro support-enclosure mismatch, even if skin/material detail remains below final reference quality.

### Reject if any are true

- the hand is mirrored, inverted, exploded, off-screen, or obviously wrong scale;
- fingers still read as an open side-contact pose;
- the apparent improvement is only smoother skin / denser geometry while enclosure remains wrong;
- the sleeve/wrist seam becomes a larger Macro defect;
- machine contract is weakened to accommodate the asset.

## What a pass would mean

A structural pass would *not* complete Stage 1. It would only prove a better support-hand source. Remaining high-value work would include material/skin realism, final support grasp authoring if needed, and the peel-hand pinch/contact lane. Final completion still requires locked-reference convergence and owner playtest.
