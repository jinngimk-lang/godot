# Peel Calm reference convergence checkpoint 28

Date: 2026-08-16
Production baseline: `main@769d6452e75112084f537af99be90721c2629cd5`
Acceptance set: `cafe_v1`, `bar_v1`, `market_v1` (LOCKED)
Active staging branch: `spike/mpfb-hero-limb-reference-grasp-v65`
Authored candidate head: `6122d21dc31bfd6574923eb6f932f5c103ad73ee`
Evidence bot head: `3044d06c262a380797b3bede45ad08a027fe3204`

## Exact-head verification

- Godot Check: run `31901353671` — PASS
- Godot runtime frame artifact: `peel-calm-reference-frames`, id `9251170480`
- MPFB Reference Grasp v65: run `31901353701` — PASS
- MPFB artifact: `mpfb-reference-grasp-v65`, id `9251221332`

v65 changes the pose derivation layer rather than continuing to tune the rejected wine-glass source pose. It authors a deterministic cylindrical support grasp directly on a sacrificial native MPFB canonical `default` rig, bakes the deformation to static geometry, applies the proven anatomical crop gate, and deletes the rig before evidence/export.

Boundary facts:

- no external pose source;
- no CCD;
- no endpoint optimizer;
- no contact-distance/tolerance sweep;
- no whole-hand orbit sweep;
- production GameEngine rig untouched;
- two outputs A/B differ only by the sign of the ambiguous canonical palm normal, not by grasp strength/angle search.

Both candidates retain 1,747 baked vertices and pass the anatomical coverage gate. A has palm coverage 1,297 / min segment coverage 67; B has palm coverage 1,442 / min segment coverage 61.

## Frames inspected

Persisted under `docs/superpowers/evidence/mpfb-v65/`:

- `support-wrap-A-with-vessel.png`
- `support-wrap-A-thumbnail.png`
- `support-wrap-A-anatomy-oblique.png`
- `support-wrap-A-anatomy-thumbnail.png`
- `support-wrap-B-with-vessel.png`
- `support-wrap-B-thumbnail.png`
- `support-wrap-B-anatomy-oblique.png`
- `support-wrap-B-anatomy-thumbnail.png`
- `reference-grasp-v65.json`

## Visual verdict

### Candidate A — REJECT

**Macro FAIL.** A is still an open C-shaped hand beside/around the cylinder. The thumb remains long and extended and the fingers do not create a compact support-grip silhouette.

**Meso FAIL.** The unobstructed oblique view shows a large thumb/finger opening and weak opposition. Do not reuse palmar sign A.

### Candidate B — STRUCTURAL IMPROVEMENT, NOT YET ACCEPTED

**Macro: first meaningful support-grip improvement.** At 192x108, B now reads as a human hand gripping a cylindrical object rather than as an open hand merely touching one. The palm and curled digits occupy the correct broad relationship around the proxy. This is the first reference-derived native-canonical candidate in this spike that clears that basic perceptual hurdle.

**Meso FAIL / incomplete.** Thumb opposition is not clearly readable in the with-vessel frame; the visible digit pads bunch toward the near contour rather than giving a clean opposing-thumb / far-side-fingers silhouette. The diagnostic report likewise shows only one non-thumb fingertip on the far side of the palm radial plane. That metric is diagnostic only, but it agrees with the visual concern. The anatomy view itself is continuous and far better than the prior cross-rig deformation failures.

Therefore B is a **seed**, not a production candidate. Do not proceed to café/bar/market product-camera integration yet.

### Micro

Not evaluated. R1 is still a Macro/Meso problem.

## What this proves

1. Checkpoint 27 was correct to change the pose source/derivation instead of crop/renderer parameters.
2. The canonical palm-normal sign is now resolved: B is visibly superior; A should not be repeated.
3. A reference-derived native-canonical authored grasp can produce a substantially more legible support grip than the CC0 wine-glass source while preserving the deformation-safe same-rig bake path.
4. The next highest-impact mismatch is no longer the whole hand being open; it is **thumb opposition / readable enclosure on candidate B**.
5. Green CI remains insufficient: B is held back because the actual thumbnail/Meso evidence has not met the locked support-hand requirement.

## Current reds

### R1 — Candidate-B thumb opposition / enclosure clarity

Freeze B palmar sign, palm placement, vessel radius, index/middle/ring/pinky authored chains and the evidence camera. Re-author only the thumb opposition/curl so the thumb is visibly on the opposing near/upper side while the curled digits remain around the other side. Do not re-open a general hand-parameter search.

### R2 — Product-camera proof

Blocked until the B-derived grasp passes R1. Then import the static/rigged staging candidate into the real café/bar/market product FOV and compare against XR baseline and locked references.

### R3 — Peel-hand flap pinch

Still behind support-hand R1/R2.

### R4+ — Micro material polish

Skin/PBR, paper fibers, glass breakup, condensation and similar fine polish remain frozen.

## Next exact action

Create one isolated v66 candidate from B only:

1. keep B palmar sign `-1`;
2. freeze the four non-thumb finger chains and vessel relationship;
3. change only the independent thumb opposition/curl choreography;
4. render the same with-vessel 192x108 and unobstructed oblique evidence;
5. accept only if thumb opposition is immediately readable without making the thumb intersect the vessel/palm;
6. if it passes, stop pose-search work and move to Godot product-camera proof; if it fails, diagnose the thumb chain specifically rather than reopening CCD/orbit/crop searches.

Production `main` remains untouched.
