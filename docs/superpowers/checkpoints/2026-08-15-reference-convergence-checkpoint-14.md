# Peel Calm reference convergence checkpoint 14

Date: 2026-08-15
Production baseline: `main@769d6452e75112084f537af99be90721c2629cd5`
Active experiment: `spike/mpfb-hero-limb-anatomical-table-v40`
Exact experiment head before this checkpoint: `9a7c7227f78c1842983790bdee2ea5a665ec02f5`

## Acceptance target

The locked user-approved cafe / bar / market reference families remain authoritative. R1 is still a continuous realistic hand-wrist-forearm hero asset; R2 is photographic vessel-wrap / label-pinch choreography. Macro and Meso visual evidence outrank endpoint/contact metrics and green CI.

## v39 evidence and verdict

Branch: `spike/mpfb-hero-limb-authored-grasp-v39`
Exact head: `9fe5f6d663afb5f5573bfa208e09a6f67b356b02`
Godot Check: run `31862329231` — PASS
MPFB Authored Grasp v39: run `31862329230` — PASS
Artifact: `mpfb-authored-grasp-v39`, id `9241011566`

Six fixed-camera candidates were visually inspected. Bounded local-Z flexion plus proximal X fan reduced the catastrophic self-intersections seen in v38, but all candidates still read as four long, nearly parallel hanging digits. The palm did not convincingly envelope the vessel and thumb opposition remained weak.

**Verdict: visual FAIL. Do not advance v39 to product-camera staging.**

## v40 hypothesis

v38 suggested local X+ preserved readable human hand volume while local Z+ was the only tested direction that visibly curled toward the vessel. v40 therefore tested a per-joint-family authored table:

- proximal joints: local X+;
- intermediate/distal joints: bounded local Z+;
- thumb opposition: independent X or Z variants;
- no CCD;
- no endpoint chasing;
- no relaxed target tolerance.

Three finger balance tables (`balanced`, `proximal`, `wrap`) x two thumb variants produced six candidates.

## v40 exact-head evidence

Exact head: `9a7c7227f78c1842983790bdee2ea5a665ec02f5`
Godot Check: run `31864698925` — PASS
MPFB Anatomical Grasp v40: run `31864698924` — PASS
Artifact: `mpfb-anatomical-grasp-v40`, id `9241700301`

The pipeline successfully:

1. installed pinned Blender 4.2.0 and MPFB 2.0.17;
2. rebuilt the continuous MPFB human source;
3. extracted the continuous right hero limb;
4. rendered all six fixed-camera per-joint candidates;
5. uploaded the evidence artifact.

## v40 visual verdict

All six candidates were inspected at Macro/Meso scale.

Positive evidence:

- v40 produces more explicit finger bending than v39;
- continuous hand-wrist-forearm anatomy remains intact;
- catastrophic whole-hand mesh failure is reduced relative to earlier procedural/axis experiments.

Blocking visual defects:

- four fingers remain visibly too long and nearly parallel;
- fingers hook across the *front* of the vessel rather than wrapping around its circumference/back side;
- palm volume remains detached from the vessel instead of enveloping it;
- thumb does not form credible opposition against the index/middle side;
- the silhouette still reads as an algorithmic claw before it reads as a human vessel grip.

**Verdict: visual FAIL despite exact-head green CI. Do not advance v40 to Godot product-camera staging or production.**

## Falsified / do-not-repeat routes

Do not spend another loop on minor variants of these approaches unless new evidence changes the model:

- subdividing the old XR hand;
- procedural tube forearms;
- stock XR `Cup` pose;
- fingertip endpoint CCD / target chasing;
- changing the support vessel axis while keeping endpoint IK;
- uniform-axis authored flexion;
- bounded-Z flexion with only a proximal-X fan;
- one fixed bend-axis policy for an entire joint family;
- loosening endpoint/contact thresholds to make a visual failure numerically pass.

## Structural conclusion

The remaining problem is not a scalar bend amount. A photographic wrap requires each digit to occupy a different azimuth around the vessel and each joint to contribute a different anatomical function. Palm/root placement, MCP flexion/abduction, PIP/DIP closure, and thumb opposition must be authored as a coherent whole-hand pose.

The next abstraction is therefore **artist-authored whole-hand pose**, not another IK tolerance or global axis search.

## Next exact action — v41

Create an isolated `spike/mpfb-hero-limb-artist-authored-v41` branch and build an authored vessel-wrap staging pose with these constraints:

1. Keep the proven continuous MPFB limb and v35 whole-hand root/palm placement.
2. Give index/middle/ring/pinky independent circumferential/azimuth intent around a realistic vertical vessel.
3. Separate MCP flexion and finger fan/abduction from PIP/DIP closure rather than assigning one axis rule to every joint family.
4. Author thumb opposition independently toward the index/middle side.
5. Prefer a small number of explicit, readable candidates over broad parameter sweeps.
6. Judge thumbnail silhouette and Meso contact first: palm approach, finger ordering, wrap-around depth, thumb opposition, wrist/forearm flow, self-intersection.
7. Do not run product-camera integration unless one candidate clearly reads as a human vessel wrap.
8. Do not polish skin/PBR/paper/glass while R1/R2 remain dominant.

If programmatic bone-local rotation remains ambiguous, first produce a bone/rest-axis diagnostic and then encode an explicit per-bone artist-authored rotation table from that evidence. Do not return to CCD.