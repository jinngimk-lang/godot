# Peel Calm reference convergence checkpoint 24

Date: 2026-08-15
Production main: `769d6452e75112084f537af99be90721c2629cd5`
Branch: `spike/mpfb-hero-limb-artist-fk-v55`
Exact evaluated candidate: `cd1caa476c2dc191165e790aad424fd7be35e01f`
Godot Check: run `31884834130` — PASS
MPFB Artist FK v55: run `31884834148` — PASS
Visual artifact: `9246993570` (`mpfb-artist-fk-v55`)
Artifact digest: `sha256:39d91783fa93397557845f0cd5177f33edff35e88686691ab3a59a99309fa8f9`

## Locked target

`cafe_v1 / bar_v1 / market_v1` remain unchanged. R1 still binds promotion: at 192×108 the support hand must immediately read as a believable human hand wrapping the vessel, with the thumb visibly opposing the four fingers and the distal finger chains disappearing progressively around/behind the far vessel contour.

## What v55 tested

v55 was the first candidate after checkpoint 23 to remove every automatic contact/axis solver and apply one fixed 17-bone GameEngine pose as explicit local FK deltas. It used one deliberately authored closure rhythm — lighter index, progressively deeper middle/ring/pinky, independent thumb opposition — and then persisted the result with the already verified v49 durable partial-pose format.

Machine evidence passed:

- exact-head Godot 4.7.1 verification passed;
- MPFB build/author/save/reload/render workflow passed;
- no automatic retarget;
- no source BVH transforms copied;
- no target point, CCD, surface servo, distance minimizer, coefficient sweep or optimizer;
- 17 durable pose bones;
- save → clear → reload max matrix error `1.7881393432617188e-07`.

The fixed authoring values were nontrivial, including PIP/DIP rotations up to roughly 54° and an independently authored thumb chain. This was not a no-op.

## Frames inspected

Downloaded exact artifact `9246993570` and inspected:

- `previews/anatomical_controls_v53_candidate.png` — inherited renderer filename, but contains the v55 artist-FK pose;
- `previews/anatomical_controls_v53_thumbnail.png` — 192×108 Macro gate for the same v55 pose.

## Visual verdict — REJECT

Both technical workflows are green, but the visual candidate fails R1.

Observed defects:

1. At thumbnail scale the hand still reads as an open palm touching the vessel, not a vessel wrap.
2. Index/middle/ring remain long and strongly visible instead of curling behind the far cylinder contour; pinky closes more but does not create an enclosure rhythm.
3. Thumb opposition is not visually readable enough to form a near-side / far-side clamp.
4. Palm-to-vessel placement is close enough to expose the core pose failure rather than hide it: the remaining mismatch is primarily digit-chain choreography, not camera distance.
5. Several distal silhouettes terminate with conspicuously flat/block-like ends in the diagnostic render, which is unacceptable for a hero-hand close-up and must be checked as part of the eventual production asset pass.

Do not promote v55 into Godot product-camera staging or production.

## Important falsification

Checkpoint 23 required a genuinely artist-authored durable pose rather than another procedural solver. v55 removed the solver, but the implementation still encoded the pose as guessed local XYZ Euler deltas in code. The real-frame result shows that **"fixed hand-written Euler numbers" is not equivalent to an artist-authored visual pose** when the GameEngine rig's per-bone local axes are not visually intuitive.

Therefore do not create v56 as another table of guessed local XYZ values or a broad axis/angle sweep. That would recreate the same search abstraction checkpoint 23 was meant to close.

## Highest-impact reds

R1 — **Visual pose authoring source:** obtain one genuinely believable support-wrap pose on the continuous MPFB hand/wrist/forearm using a pose-authoring method where the artist/author judges the actual silhouette, not guessed local-axis numbers.

R2 — **Product-camera proof:** after R1 passes the fixed thumbnail gate, stage the candidate in the real café/bar/market camera and compare against current XR baseline and locked references.

R3 — **Peel-hand pinch:** build the same visual-first durable pose workflow for thumb/index flap pinch only after the support-hand method is proven.

R4 — **Hero fingertip/mesh finish:** investigate the block-like distal fingertip silhouettes before production promotion; do not hide them with material polish.

Micro skin/PBR, paper fibers, glass highlights, condensation and HUD polish remain downstream of R1/R2.

## Next exact action

Change the authoring interface, not another pose coefficient.

1. Keep the continuous MPFB GameEngine hero limb, v49 durable 17-bone pose format, current vessel fixture and fixed camera.
2. Use a visual pose-authoring source/workflow that exposes the actual hand silhouette while posing (for example Blender Pose Mode / a deterministic pose asset authored from a visually inspected stance, or an equivalently direct authoring source). A CC0 holding-object pose may remain anatomical guidance, but source transforms must not silently overwrite GameEngine rig roll/rest data.
3. Author one support wrap as a visual whole: palm close to near/side wall; thumb visibly crossing/opposing; index through pinky progressively curling in depth; distal portions disappearing behind the far contour.
4. Save only the finished visually accepted pose into the durable partial-pose format. Do not run a solver afterward.
5. Render full + 192×108 using the unchanged fixed camera.
6. Reject immediately if thumbnail still reads as touching/open hand.
7. Only after a thumbnail PASS, inspect fingertip mesh quality and then stage the exact candidate in the real Godot product camera against the XR baseline.
8. Run independent Challenger only after real product-camera evidence improves.

## Do not repeat

Do not return to endpoint/CCD/contact chasing, per-joint flex-axis derivation, whole-hand orbit sweeps, shared-axis tables, blind local XYZ tables, or broad coefficient sweeps. The next work must improve the **pose-authoring interface/source itself**.
