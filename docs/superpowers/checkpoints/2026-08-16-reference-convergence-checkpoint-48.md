# Peel Calm reference convergence checkpoint 48

Date: 2026-08-16
Branch: `spike/mpfb-grip-web-crop-v89`
Visual candidate exact head: `a07a8ee823fe7d60fdbc0ece38a81cd8ef51a3af`
Production baseline remains: `main@769d6452e75112084f537af99be90721c2629cd5`
Locked acceptance references: `bar_v1`, `market_v1`

## Exact-head verification

- Godot Check `31942159153` — PASS on `a07a8ee823fe7d60fdbc0ece38a81cd8ef51a3af`.
- MPFB V88 Product Camera `31942159148` — PASS on the same exact head.
- Product-camera artifact: `9262367501` (`mpfb-v88-product-camera`).
- Five product frames inspected: `bar_xr`, `bar_v88`, `market_xr`, `market_v88`, `market_v88_inspect45`.

An earlier first v89 workflow attempt `31942070055` failed only because the copied workflow invocation passed the wrong v87 builder argument contract; this was CI infrastructure, not a model result. The workflow was restored to the proven v88 invocation before the exact-head evidence above.

## Single change under test

Checkpoint 47 identified R1a as an export/crop defect: the baked MPFB hand–wrist–forearm showed a large V-shaped missing-surface notch at the wrist transition in the real Godot bar/market camera.

This iteration freezes:

- the successful side-on whole-limb artist roll at `-40°`;
- semantic grip deltas;
- product scale mapping;
- Godot root placement and yaw;
- product camera and scene state;
- finger crop radius (`0.018`).

Only the continuous wrist/palm skin-retention envelope changed:

- palm radius: `0.050 -> 0.058`;
- `lowerarm02.R / wrist.R` segment radius: `0.038 -> 0.046`.

The exporter now writes those values into `crop_envelope` in the staging report and the product-camera workflow asserts them before capture.

## Visual comparison

### R1a — wrist/forearm crop continuity: CLOSED for this candidate

Direct old-v88 versus v89 product-camera comparison shows the former large V-shaped cutout at the right wrist transition is gone in both bar and market. The new limb reads as a continuous hand → wrist → forearm surface through the product-camera crop. `market_v88_inspect45` also preserves the continuity rather than reopening the notch during inspection.

The crop correction is geometrically small rather than a hidden scale/pose rewrite: the baked mesh changed from 1,739 to 1,749 vertices and from 1,716 to 1,738 polygons while the pose/roll/scale/root/camera contract remained frozen.

### R1b — natural vessel enclosure: still FAIL / highest red

The widened crop exposes the remaining real problem more cleanly. The MPFB support limb now enters from the correct side and has a continuous wrist, but the fingers/palm still do not convincingly enclose the bottle at the locked-reference level. In the bar and market frames the hand reads as a large open C-shape hovering/pressing around the label region rather than a firm natural support grip. Thumb opposition is more legible than the old XR baseline, but the finger chains do not disappear around the bottle far side strongly enough.

Do not mark R1 complete and do not promote this staging asset to production.

## Multiscale verdict

- Macro approach direction: PASS relative to the previous upper-right/top-down red; preserve the `-40°` whole-limb choreography.
- Macro wrist continuity/crop: PASS; preserve the widened envelope unless later anatomy evidence disproves it.
- Macro/Meso vessel enclosure: FAIL; this is now the dominant support-hand red.
- Meso inspection continuity: no new crop regression at `inspect45`.
- Micro skin/material polish: still frozen.

## Do not do next

- Do not shrink the hand via arbitrary scale sweep; current scale derives from authoring proxy bottle radius to real product radius mapping.
- Do not reopen wrist crop tuning unless a new product-camera defect appears.
- Do not return to CCD, endpoint chasing, contact servo, joint-axis tables, whole-hand orbit search, scalar thumb sweeps, or screen-space finger parameter sweeps.
- Do not spend the next iteration on skin PBR, paper fibers, glass highlights, liquid or condensation.

## Remaining reds

### R1 — support-hand enclosure / grasp grammar

Keep the now-correct side-on approach and continuous wrist. The next change must target the actual whole-hand vessel enclosure: palm should sit against the bottle side, opposing fingers should visibly wrap toward/disappear behind the far silhouette, and thumb should oppose them without covering the hero label area.

### R2 — product-camera production integration

Only after R1 passes Macro/Meso in both bar and market should the MPFB support limb become a production integration candidate, followed by exact-head full Godot verification and independent Challenger.

### R3 — peel-hand label pinch

Still deferred until support-hand R1/R2 are stable.

## Next exact action

Start from this v89 evidence state but freeze crop envelope, `-40°` approach, physical scale mapping, root/yaw and camera. Make exactly one reference-derived whole-hand enclosure correction using the existing native-rig semantic authoring controls. The target is not a smaller hand or a prettier material: at 192×108 the support hand must immediately read as firmly wrapping the bottle, with fingers and thumb on opposing sides and without obscuring the label.

Then rerun the same exact-head five-frame Godot product-camera A/B. Reject the correction if side-on approach, wrist continuity, or `inspect45` stability regress. If enclosure materially improves, proceed to an independent Challenger before any production merge.
