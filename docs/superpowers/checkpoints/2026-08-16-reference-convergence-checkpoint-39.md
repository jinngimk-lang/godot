# Peel Calm reference convergence checkpoint 39

Date: 2026-08-16

Production main baseline: `769d6452e75112084f537af99be90721c2629cd5`

Staging branch: `spike/contactpose-guided-artist-v82`
Verified candidate head before this checkpoint: `d3a14f5e89d8ab30d148ad92ff4e985c394710ee`

Godot Check: run `31922356023` — PASS
Godot runtime reference-frame artifact: `9256750508`

MPFB ContactPose Guided Artist v82: run `31922356076` — PASS
MPFB visual artifact: `9256800662`

## Locked acceptance target

The acceptance target remains the user-approved `bar_v1` / `market_v1` support-hand intent: a believable human support hand visibly encloses the slender bottle, with a readable opposing thumb and progressively layered index/middle/ring/pinky closure. Staging renders and ContactPose annotations remain evidence/guidance only and do not replace the locked acceptance references.

## What v82 tested

v81 closed the authoring-capability gap by embedding a real-human ContactPose `water_bottle / full6_use / hand 1` 21-joint skeleton as a cyan guide in the native GameEngine-rig authoring scene without modifying the actual pose.

v82 then tested exactly **one** direct artist-authored four-finger gesture derived from visually comparing that guide against the current v77/v74 seed. It intentionally did not copy guide joint coordinates and did not run a solver.

Frozen:

- wrist;
- the verified v74 thumb seed;
- whole-hand placement;
- vessel proxy;
- fixed authoring camera/crop.

Edited:

- the twelve non-thumb pose bones only.

The v82 gesture compressed the rejected v78 screen-space finger fan and increased camera-depth wrap progressively from index to pinky.

Contract remained:

- `automatic_retarget_used = false`;
- `parameter_sweep_used = false`;
- `ccd_used = false`;
- `endpoint_optimizer_used = false`;
- `contact_servo_used = false`;
- `root_orbit_motion_used = false`;
- frozen wrist/thumb matrix delta `<= 1e-6`;
- technical PASS cannot auto-promote the visual pose.

## Visual verdict — REJECT

The exact v82 artifact was inspected at both 192×108 Macro scale and unobstructed Meso anatomy scale.

### Macro

FAIL.

The new pose is more curled than the v77 seed, but first-glance silhouette still reads as a near-side claw / curled finger mass instead of a natural human bottle enclosure. The fingers do not convincingly disappear around the far contour of the cylinder, and the frozen thumb does not form a clean opposing grasp silhouette with the four-finger side.

### Meso

FAIL.

The unobstructed anatomy view shows the distal chains bunching together into a compact curled cluster with visible overlap/self-intersection. The index→middle→ring→pinky chains do not preserve the real-human layered depth ordering visible in the ContactPose ghost. The result is not suitable for product-camera staging.

### Micro

Not evaluated. Skin/PBR, paper fibers, glass highlights and condensation remain frozen while Macro/Meso hand structure fails.

## Falsified hypothesis

> A single manually authored screen-space gesture, using the real-human ContactPose ghost only as visual guidance while increasing progressive camera-depth wrap, would be sufficient to turn the current native-rig seed into a readable bottle enclosure.

This hypothesis is false for v82.

The failure confirms that the remaining problem is not lack of a real-human anatomical guide and not lack of a reproducible authoring/ingest path. The unresolved gap is **actual direct native-rig visual posing quality**: finger chains need to be shaped interactively as one hand around the cylinder rather than encoded as another fixed handle table.

## Do not repeat

Do not turn the v82 handle values into v83/v84 parameter sweeps.

Do not return to:

- CCD;
- endpoint chasing;
- contact servo;
- scalar joint-angle sweeps;
- whole-hand orbit sweeps;
- exact ContactPose automatic retarget;
- source-direction copying;
- repeated screen-space handle tuning.

Do not loosen the acceptance gate because the technical workflow passed.

## Capability check

A plugin search for Blender / 3D / rigging / pose / animation returned no installable plugin in the current connected-tool environment. The reusable native-rig `.blend`, real-human ghost guide, durable same-rig pose format, fixed camera, and automated ingest/validation pipeline all exist; what is still missing is a true interactive pose-editing surface in this execution environment.

This is a tooling boundary, not an ambiguity in the product target.

## Current red ranking

### R1 — direct native-rig whole-hand support grasp

Highest priority. Produce one visually authored hand whose 192×108 silhouette clearly encloses the bottle and whose unobstructed anatomy preserves separated, progressively wrapped finger chains plus readable thumb opposition.

### R2 — Godot product-camera proof

Only after R1 passes staging: compare MPFB candidate vs current XR baseline in real bar/market Godot cameras and interaction states.

### R3 — peel-hand pinch

After support-hand replacement direction is proven, author thumb/index flap contact with the same Macro/Meso discipline.

### R4+ — Micro polish

Skin response, paper fibers, residue breakup, glass/condensation, and other high-frequency polish remain frozen.

## Next exact action

1. Start from the v81/v82 native GameEngine authoring `.blend` and real-human ContactPose ghost guide.
2. Use a **true interactive Blender/native-rig pose editing surface** when available; manipulate the twelve non-thumb finger bones as one whole hand, not via another numeric handle sweep.
3. Keep wrist, v74 thumb, vessel, camera and whole-hand placement frozen initially.
4. Author exactly one candidate.
5. Gate it first at 192×108: human bottle enclosure must read immediately.
6. Then inspect unobstructed oblique anatomy for progressive depth ordering, web spaces, knuckle flow, self-intersection and distal kinks.
7. Only if both pass: save durable same-rig pose, run existing artist-ingest gate, move immediately to real Godot bar/market product-camera comparison against XR baseline, then run independent Challenger.
8. Keep production `main` untouched until that evidence exists.
