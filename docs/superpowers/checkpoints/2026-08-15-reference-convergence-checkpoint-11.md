# Peel Calm reference convergence checkpoint 11

Date: 2026-08-15
Branch: `spike/mpfb-hero-limb-joint-arc-v37`
Production baseline: `main@769d6452e75112084f537af99be90721c2629cd5`
Exact experimental head before this checkpoint: `95d814608b3f7d2600f32aed910f1b85c9dc2e9a`
Exact-head Godot Check: run `31859059590` — PASS
MPFB Joint Arc v37: run `31859059624` — objective/workflow FAIL after rendering
Visual artifact: `mpfb-joint-arc-v37`, artifact id `9240006413`

## Acceptance context

The approved café/bar/market references remain the visual source of truth. Hand work is still blocked at Macro/Meso, so skin pores, paper fibers, glass micro-highlights and other Micro polish remain deliberately deferred.

Current dominant requirement: a continuous human hand-wrist-forearm whose support pose reads immediately as a natural vessel wrap, and whose peel pose reads as a whole hand approaching and pinching the actual lifted flap.

## v36 conclusion carried forward

v36 proximal-first CCD was visually rejected. Changing CCD ordering did not solve the long parallel-tine silhouette. Endpoint-driven optimization remained the wrong abstraction.

## v37 falsifiable hypothesis

Hypothesis: after the improved v35 whole-hand root/palm orientation, explicitly steering the tails of proximal/intermediate/distal phalanges through progressive cylindrical arc waypoints would establish believable finger curvature before a weak fingertip refinement.

The experiment deliberately preserved the existing 24-degree per-bone budget and used only a small endpoint refinement after the structural arc pass.

## Exact results

Godot project verification for exact head `95d8146...` passed, so this is not an import/parser/product-code failure.

The MPFB staging run rendered both sign candidates but rejected both objective screens. Most participating finger joints saturated near the 24-degree local budget.

Approximate final fingertip target errors:

- positive: thumb 78.6 mm, index 164.4 mm, middle 123.8 mm, ring 129.2 mm, pinky 121.3 mm;
- negative: thumb 81.6 mm, index 163.1 mm, middle 120.0 mm, ring 125.9 mm, pinky 114.7 mm.

The error increase is useful negative evidence: forcing each phalanx toward independent cylinder waypoints consumes the anatomical budget without producing a coherent grasp.

## Runtime/visual evidence inspected

Inspected:

- `joint_arc_v37_positive_closed.png`
- `joint_arc_v37_negative_closed.png`

### Positive candidate — REJECT

Macro/Meso reading is still a claw rather than a support grip. The fingers bend at isolated joints and touch the near wall, but the palm does not visually enclose the vessel and the digits do not form a coherent grasp family. The silhouette reads as hooked fingers placed against a cylinder.

### Negative candidate — REJECT

The vessel/hand relationship is worse: thumb/palm mass dominates the near side while the remaining fingers disappear behind the vessel. The resulting silhouette does not resemble the approved reference's visible support-wrap anatomy.

## What v37 proves

1. Better whole-hand placement remains necessary but is not sufficient.
2. Endpoint-only CCD is rejected.
3. Proximal-first CCD is rejected.
4. Independent per-joint cylinder-arc waypoint steering is also rejected.
5. Low endpoint error is not a reliable realism metric; conversely, forcing local curvature can destroy endpoint/contact quality without yielding believable anatomy.
6. The next abstraction should be an authored grasp pose whose silhouette and anatomy are accepted first, followed only by bounded vessel adaptation.

## Do not repeat

Do not spend additional loops on:

- support-axis sign/axis randomization;
- CCD order permutations;
- simply increasing per-joint budgets;
- endpoint tolerance tuning;
- per-phalanx waypoint IK as the primary grasp generator;
- material/lighting polish on this rejected pose.

## Next exact action — authored grasp v38

Build a staging-only authored cylindrical support pose from the continuous MPFB limb:

1. start from the accepted v35 whole-hand root/palm frame;
2. establish a deterministic artist-authored finger curl/opposition pose rather than solving endpoints;
3. judge silhouette, palm clearance, thumb opposition, visible finger ordering and self-intersection before any contact metric;
4. render fixed positive/negative or one clearly superior camera-side candidate against the same cylinder;
5. only if Macro/Meso visually reads as a human wrap, add very small bounded adaptation for cup vs bottle radius;
6. do not integrate into production until a Godot product-camera staging frame beats the XR baseline/reference gap.

R1 remains hero hand-wrist-forearm anatomy/choreography. R2 remains real support-wrap / label-pinch contact. No production merge is justified by v37.
