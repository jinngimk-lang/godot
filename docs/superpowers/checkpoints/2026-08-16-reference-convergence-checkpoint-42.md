# Peel Calm reference convergence checkpoint 42

Date: 2026-08-16
Branch: `spike/mpfb-grip-helper-authoring-overlay-v86`
Production baseline remains: `main@769d6452e75112084f537af99be90721c2629cd5`
Verified v86 infrastructure head before this checkpoint: `b59316bd275e9f25d1ebb8782eeadb3d4b7f726a`
Godot Check: run `31930209685` — PASS
Godot runtime artifact: `peel-calm-reference-frames`, artifact id `9259049698`
MPFB Grip Helper Authoring Overlay v86: run `31930209650` — PASS
Editable authoring/evidence artifact: `mpfb-grip-helper-authoring-overlay-v86`, artifact id `9259096773`

## Locked acceptance target

The support-hand acceptance target remains the user-approved `bar_v1` and `market_v1` reference families. ContactPose remains anatomy guidance only. Runtime screenshots, MPFB staging renders, wire vessel guides, ghost bones, and v86 discrepancy arrows are evidence/authoring aids and may not replace the locked acceptance references.

## What this loop changed

Checkpoint 41 correctly stopped parameter/search-based support-pose iteration and required a true visual whole-hand edit. The current automation environment still has no interactive Blender viewport, so this loop did not fabricate a v86 semantic-value pose candidate.

Instead it closed a narrower authoring-capability gap without touching the pose:

- added `tools/build_mpfb_grip_helper_authoring_overlay_v86.py`;
- added `.github/workflows/mpfb-grip-helper-authoring-overlay-v86.yml`;
- rebuilt the v85 native MPFB Default-rig authoring scene;
- retained the same seven editable semantic controls (`wrist.R`, master grip, five finger grips);
- retained the locked vessel, camera and ContactPose `water_bottle / full6_use / hand1` read-only ghost;
- added a non-selectable, authoring-only colored arrow for each digit from the current fingertip to the corresponding mapped real-human ContactPose fingertip landmark;
- stored the five discrepancy distances in the machine-readable build report;
- generated wire-vessel and unobstructed anatomy authoring renders plus an unchanged opaque 192x108 Macro render.

The overlay is explicitly a visual landmark, **not** an optimizer target. Artists must not mechanically snap fingertips to arrow endpoints; the final gate remains human silhouette, web space, knuckle flow, depth ordering and the locked reference intent.

## Hard non-mutation evidence

The workflow verifies:

- `automatic_retarget_used == false`;
- `parameter_sweep_used == false`;
- `overlay_is_optimizer == false`;
- `production_candidate == false`;
- `visual_verdict == PENDING_DIRECT_ARTIST_EDIT`;
- the seven authoring controls have maximum matrix delta `0.0` after creating the v86 overlay;
- vessel and camera stay locked;
- reopening the saved `.blend` preserves the authoring-only boundary.

Therefore v86 is an authoring-infrastructure improvement, not a support-pose change and not a production candidate.

## Current real-human fingertip discrepancy at the unchanged v85 seed

Measured in the shared staging world frame:

- thumb: ~40.47 mm
- index: ~56.87 mm
- middle: ~45.76 mm
- ring: ~42.66 mm
- pinky: ~23.78 mm

These values explain where the seed differs from the real-human grasp, but they are diagnostic only. A lower distance does not imply a better visual grip.

## Visual inspection

### Authoring wire / anatomy views — KEEP as editing guidance

The new colored discrepancy arrows make the remaining structural mismatch easier to read in one frame. The current seed and the cyan real-human ghost occupy visibly different depth/enclosure trajectories; the largest current tip gaps are index, middle, ring and thumb, while pinky is already geometrically closer. This is useful guidance for a future direct artist edit because it discourages another indiscriminate all-finger curl.

### Unchanged opaque 192x108 Macro — still FAIL

The overlay is hidden for the final Macro context. The unchanged seed still does not read immediately as a stable human bottle grip. Only fragments of the hand oppose around the opaque vessel; there is still no clear, reference-like whole-hand enclosure.

Therefore **R1 is not closed** and v86 must not enter Godot product-camera integration as a hero-hand replacement.

## Current reds

### R1 — true direct-visual whole-hand support grasp

Use the v86 `.blend` in a real interactive Blender/native-rig visual posing environment. Make exactly one whole-hand edit using only the seven semantic controls. The ghost, wire vessel and discrepancy arrows are guides only.

Pass gates remain:

1. final opaque-vessel 192x108 frame immediately reads as a natural stable human bottle grip;
2. palm sits beside the vessel rather than floating in front of it;
3. thumb clearly opposes the four fingers;
4. index is lighter while middle/ring/pinky progressively wrap to the far contour/depth;
5. unobstructed anatomy preserves web space, natural knuckle flow, separated digit arcs and no obvious self-intersection.

If this one visual candidate fails, reject it. Do not convert v86 arrows/distances into a numerical solver or semantic-value sweep.

### R2 — Godot bar/market product-camera proof

Blocked on R1. Once R1 passes, export the same-rig candidate and compare it against current XR baseline in the exact product camera and interaction-step frames.

### R3 — peel-hand label pinch

Blocked behind the support-hand pipeline.

### Micro fidelity

Skin PBR, paper fibers, glass/liquid/condensation microdetail remain frozen while R1 is still a dominant Macro/Meso mismatch.

## Do not repeat

Do not re-enter:

- CCD or endpoint chasing;
- contact/surface servo;
- raw phalanx Euler/axis tables;
- whole-hand orbit sweeps;
- automatic/exact ContactPose retarget;
- source-direction copying;
- master/finger semantic-value sweeps;
- treating discrepancy arrows as optimization targets;
- moving the locked vessel/camera to make the pose look better;
- using wire/ghost/overlay diagnostics as the final acceptance image;
- equating green CI with visual acceptance.

## Next exact action

Open `peel-calm-grip-helper-authoring-overlay-v86.blend` in a true interactive Blender/native GameEngine-rig environment. Use the cyan real-human ghost, wire vessel and colored discrepancy arrows only as visual context; author exactly one coherent whole-hand grasp through `wrist.R`, `right_master_grip`, and `right_finger1_grip..right_finger5_grip`. Then hide all authoring overlays and render the unchanged opaque 192x108 Macro plus unobstructed Meso anatomy. Only if both pass should the project proceed to Godot bar/market product-camera integration and independent Challenger review.
