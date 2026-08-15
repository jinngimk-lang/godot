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

## Historical candidate audit — source-direction v55 also REJECTED

To avoid re-opening an older branch later, the existing source-direction candidate was audited in this same loop.

- Branch: `spike/mpfb-hero-limb-source-direction-v55`
- Exact head: `f2330501c3e9b0bb3a6d58588204569977f0f68d`
- MPFB Source Direction v55: run `31880122528` — PASS
- Godot Check: run `31880122554` — PASS
- Visual artifact: `9245816588` (`mpfb-source-direction-v55`)
- Artifact digest: `sha256:938cf20c3ad1a8243e7baaf5fa72f9938862fb276cae3a8caa54962c683b0e9b`

That route deliberately avoided unsafe BVH transform copying: it reduced the CC0 holding-wine-glass source pose to phalanx direction coefficients in a source palm frame and reconstructed those directions in the target GameEngine palm frame. The safety boundary was technically sound, but the real 192×108 frame is an even clearer visual failure than artist-FK v55: the visible fingers extend horizontally across the bottle face, with essentially no vessel enclosure and no readable opposed thumb. Therefore **source phalanx-direction transfer is also closed as an R1 solution**.

Do not resurrect this branch simply because it uses a human-authored source pose; direction-only mapping loses the coupled palm, metacarpal, joint-roll and depth relationships that make the original grasp believable.

## Important falsification

Checkpoint 23 required a genuinely artist-authored durable pose rather than another procedural solver. v55 removed the solver, but the implementation still encoded the pose as guessed local XYZ Euler deltas in code. The real-frame result shows that **"fixed hand-written Euler numbers" is not equivalent to an artist-authored visual pose** when the GameEngine rig's per-bone local axes are not visually intuitive.

The source-direction audit closes the adjacent abstraction as well: **a safe human pose prior is not enough if it is reduced to independent phalanx directions**. A successful route must preserve the visual whole-hand relationship while keeping the production GameEngine rig's own rest/roll data intact.

Therefore do not create v56 as another table of guessed local XYZ values, direction-only transfer, or broad axis/angle sweep. That would recreate the same search abstraction checkpoint 23 was meant to close.

## Current MPFB safety finding

Current MPFB source code was re-checked before choosing the next route. `AnimationService.import_bvh_file_as_pose()` explicitly describes itself as destructive and copies source BVH edit-bone roll values into the destination rig before copying rotations. Its source warns that this will ruin destination bone roll values. Therefore it must **not** be applied directly to the production GameEngine hero rig. A BVH may still be loaded into a sacrificial duplicate/reference rig for visual anatomy guidance.

The verified safe persistence boundary remains the repository's same-rig v49 partial pose format (or an equivalent same-rig MPFB/Blender pose asset authored directly on the GameEngine rig) because it stores the final pose without rewriting edit-bone roll/rest structure.

## Highest-impact reds

R1 — **Visual pose authoring source:** obtain one genuinely believable support-wrap pose on the continuous MPFB hand/wrist/forearm using a pose-authoring method where the author judges the actual silhouette, not guessed local-axis numbers or direction-only transfer.

R2 — **Product-camera proof:** after R1 passes the fixed thumbnail gate, stage the candidate in the real café/bar/market camera and compare against current XR baseline and locked references.

R3 — **Peel-hand pinch:** build the same visual-first durable pose workflow for thumb/index flap pinch only after the support-hand method is proven.

R4 — **Hero fingertip/mesh finish:** investigate the block-like distal fingertip silhouettes before production promotion; do not hide them with material polish.

Micro skin/PBR, paper fibers, glass highlights, condensation and HUD polish remain downstream of R1/R2.

## Next exact action

Change the authoring interface, not another pose coefficient.

1. Keep the continuous MPFB GameEngine hero limb, v49 durable 17-bone pose format, current vessel fixture and fixed camera.
2. Author the support wrap **directly on the GameEngine rig with visual feedback** (Blender Pose Mode / a visually inspected same-rig pose asset or an equivalent direct authoring workflow). Do not destructively import a BVH into that rig.
3. A CC0 holding-object BVH may be opened only on a sacrificial reference rig beside the target to guide anatomy and silhouette.
4. Author one support wrap as a visual whole: palm close to near/side wall; thumb visibly crossing/opposing; index through pinky progressively curling in depth; distal portions disappearing behind the far contour.
5. Save only the finished visually accepted pose into the durable same-rig partial-pose format. Do not run a solver afterward.
6. Render full + 192×108 using the unchanged fixed camera.
7. Reject immediately if thumbnail still reads as touching/open hand.
8. Only after a thumbnail PASS, inspect fingertip mesh quality and then stage the exact candidate in the real Godot product camera against the XR baseline.
9. Run independent Challenger only after real product-camera evidence improves.

## Do not repeat

Do not return to endpoint/CCD/contact chasing, per-joint flex-axis derivation, whole-hand orbit sweeps, shared-axis tables, blind local XYZ tables, source-direction-only transfer, or broad coefficient sweeps. The next work must improve the **pose-authoring interface/source itself**.
