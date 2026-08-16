# Peel Calm reference convergence checkpoint 43

Date: 2026-08-16
Branch: `spike/mpfb-grip-helper-authoring-overlay-v86`
Production baseline remains: `main@769d6452e75112084f537af99be90721c2629cd5`
Previous checkpoint head: `1da9942ccb5906703b5383820c6ffcaffb1a5647`
Previously verified Godot Check: run `31930209685` — PASS
Previously verified Godot runtime artifact: `peel-calm-reference-frames`, artifact id `9259049698`
Previously verified MPFB v86 authoring overlay: run `31930209650` — PASS
Editable authoring/evidence artifact: `mpfb-grip-helper-authoring-overlay-v86`, artifact id `9259096773`

## Purpose of this checkpoint

This loop did **not** mutate the pose and did not create a new semantic-value candidate. The current automation environment still has no interactive Blender/3D posing connector, and plugin discovery returned no Blender/rigging/model-editing connector that could safely perform the checkpoint-42 direct-visual edit.

Instead, the v86 artifact was downloaded and the actual full-resolution `v86-authoring-overlay-anatomy.png`, `v86-authoring-overlay-wire.png`, `v86-authoring-overlay-thumbnail.png`, and unchanged opaque Macro frame were re-inspected directly. The purpose is to turn the current visual mismatch into a precise artist brief so the next real viewport edit does not regress into indiscriminate all-finger curl or another numeric sweep.

The locked acceptance target remains `bar_v1` / `market_v1`. ContactPose remains anatomy guidance only.

## New direct visual diagnosis

### Macro — unchanged opaque frame remains FAIL

The 192x108 opaque-vessel frame still does not read in one glance as a stable human bottle grip. The hand is present only as fragmented near-side contours rather than a coherent palm-plus-opposing-digits enclosure. R1 therefore remains open.

### Meso — the digit errors are asymmetric

The full v86 wire/anatomy view makes the remaining mismatch more specific than checkpoint 42:

1. **Index is the strongest structural miss.** Its current chain remains too near-side/open relative to the cyan real-human trajectory. It needs the largest coherent far-side/depth change, not simply more visible screen-space curl.
2. **Middle is the next major enclosure miss.** It should follow index into a deeper far-side arc while remaining anatomically separated rather than collapsing into the same clump.
3. **Ring also needs additional far-side depth**, but less indiscriminately than index. Its target is a progressive continuation of the enclosure, not a parallel duplicate.
4. **Thumb is already a distinct chain but its opposition is visually weak in the final vessel context.** The whole thumb/palm relationship must become readable against the opposite four-digit group; the goal is not merely to reduce its ~40 mm landmark discrepancy.
5. **Pinky is the closest fingertip landmark geometrically (~23.78 mm) and should be treated as the least-aggressive edit.** Previous failures repeatedly over-curled or displaced pinky. Do not use pinky as the driver for another global grip increase.
6. **Whole-palm placement still matters.** The hand currently reads as descending over/along the near side of the cylinder. The final silhouette must place the palm beside the vessel so the four digits can disappear progressively toward the far contour while thumb remains on the opposing near/upper side.

This ordering is consistent with the v86 measured fingertip discrepancies:

- index ~56.87 mm
- middle ~45.76 mm
- ring ~42.66 mm
- thumb ~40.47 mm
- pinky ~23.78 mm

The distances are diagnostic only; they are not optimization targets.

## Exact artist brief for the next true interactive edit

Start from `peel-calm-grip-helper-authoring-overlay-v86.blend` and make exactly one coherent whole-hand edit using only:

- `wrist.R`
- `right_master_grip`
- `right_finger1_grip` … `right_finger5_grip`

Use the cyan ContactPose ghost, wire vessel and colored arrows only as visual context.

Edit intent, in priority order:

1. First establish the **palm beside the bottle**, not hanging over the near face.
2. Move the **index trajectory most strongly toward the far-side/depth arc** while keeping it the lightest overall closure.
3. Give **middle then ring progressively deeper enclosure**, with visible separation and smooth knuckle flow.
4. Preserve pinky unless required for continuity; do not use it to force a global grip.
5. Adjust the **whole thumb opposition** so its silhouette clearly reads against the four-finger group in the opaque-vessel frame.
6. Hide every ghost/wire/arrow overlay before acceptance judgment.

Pass remains strictly visual:

- 192x108 opaque-vessel Macro immediately reads as a natural human bottle grip;
- palm sits beside the vessel;
- thumb clearly opposes the other digits;
- index is lightest, middle/ring/pinky progressively enclose toward the far contour/depth;
- unobstructed anatomy preserves web space, separated digit arcs, natural knuckle flow and no obvious self-intersection.

If that one candidate fails, reject it. Do not convert this ordered artist brief into a parameter sweep, optimizer, target-distance minimizer, or automatic ContactPose retarget.

## Tool-capability audit

A fresh plugin search for Blender / 3D / rigging / animation / model-editing capability returned no installable connector. Therefore this run did not pretend that headless scripts were equivalent to a direct viewport artist edit.

A temporary empty branch `spike/mpfb-grip-helper-authoring-panel-v87` was created while evaluating whether more authoring infrastructure would help, but no implementation was committed there. Do not treat it as a pose candidate or production branch. The highest-value next action remains the direct visual edit already defined above, not additional numeric authoring infrastructure.

## Current reds

### R1 — true direct-visual whole-hand support grasp

Still highest priority. Use the ordered artist brief above in a real interactive native GameEngine-rig viewport.

### R2 — Godot bar/market product-camera proof

Blocked on R1. Once the direct-visual candidate passes Macro and Meso, export the same-rig pose and compare against the current XR baseline in exact product-camera and interaction-step frames.

### R3 — peel-hand label pinch

Blocked behind support-hand convergence.

### Micro fidelity

Skin PBR, paper fibers, glass/liquid/condensation detail remain frozen.

## Do not repeat

Continue to forbid:

- CCD / endpoint chasing;
- contact or surface servo;
- raw phalanx Euler/axis tables;
- whole-hand orbit sweeps;
- automatic/exact ContactPose retarget;
- source-direction copying;
- semantic-value sweeps;
- converting discrepancy arrows/distances into optimizer targets;
- indiscriminate all-finger curl;
- moving the locked vessel/camera to make the hand look better;
- accepting wire/ghost/overlay diagnostics as the final image;
- equating green CI with visual acceptance.

## Next exact action

Open the v86 authoring `.blend` in a true interactive Blender/native-rig environment and produce exactly one candidate according to the ordered brief: palm placement first, then index depth, middle/ring progressive enclosure, minimal pinky disturbance, then readable thumb opposition. Hide all guides; render opaque 192x108 Macro and unobstructed Meso anatomy. Only a candidate that visibly passes both gates may proceed to Godot product-camera integration and independent Challenger review.
