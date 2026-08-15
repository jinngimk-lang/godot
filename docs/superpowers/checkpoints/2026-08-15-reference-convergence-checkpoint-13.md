# Peel Calm reference convergence checkpoint 13

Date: 2026-08-15
Branch: `spike/mpfb-hero-limb-authored-grasp-v39`
Production baseline: `main@769d6452e75112084f537af99be90721c2629cd5`
Parent experimental head: `spike/mpfb-hero-limb-authored-grasp-v38@5576347b36da27de01a0f0be0d962ea83d07f5d7`
v38 Godot Check: run `31859943833` — PASS
v38 MPFB Authored Grasp: run `31859943771` — PASS
v38 artifact: `9240322721`

## v38 visual verdict

All six fixed-axis authored candidates were inspected as real rendered evidence. v38 is **visually rejected** for product staging.

- `axisX+` preserved the most anatomically readable hand volume, but the four fingers stayed largely extended across the vessel and did not form a convincing wrap.
- `axisZ+` provided the clearest visible curl direction, but over-curled the hand into long parallel claw/tine shapes and did not produce credible thumb opposition.
- `axisX-`, both Y candidates, and `axisZ-` produced severe deformation/self-intersection or visibly non-human digit layouts.

This is useful negative evidence: the MPFB GameEngine rig cannot be driven by one identical local axis/sign for every finger joint. Numeric contact metrics remain non-authoritative.

## Updated falsifiable hypothesis — v39

Hypothesis: the useful information in v38 can be combined without returning to endpoint optimization:

1. use the **Z+ direction only as bounded visible finger flexion**, at substantially lower magnitudes than the rejected v38 profile;
2. apply only a small **X-axis proximal digit spread** to preserve index→pinky ordering and reduce parallel-tine collapse;
3. treat thumb opposition as an **independent axis choice** rather than forcing it to mirror the four fingers;
4. keep the already improved v35 whole-hand root/palm placement unchanged.

v39 deliberately has no CCD, no fingertip target chasing, and no relaxed endpoint tolerance.

## v39 candidate family

Six candidates are generated as:

- closure strength: `soft`, `medium`, `firm`;
- thumb opposition: bounded `thumb_x` or `thumb_z`.

Four-finger flexion is bounded below the v38 34–62° over-curl range. Progressive closure is retained from index to pinky. Only the proximal joint receives a small X-axis fan offset.

Added:

- `tools/render_mpfb_authored_grasp_v39.py`
- `.github/workflows/mpfb-authored-grasp-v39.yml`

## Visual gate

A v39 candidate is promotable only if the rendered frame shows all of:

1. immediate human vessel-wrap silhouette at thumbnail scale;
2. palm enclosing the vessel rather than hovering beside it;
3. visible thumb opposition;
4. progressive index→pinky ordering;
5. no severe self-intersection, detached-looking phalanges, or long parallel claw silhouette;
6. continuous wrist/forearm flow compatible with the approved reference family.

If all six fail, do not return to CCD or tolerance tuning. Use the v39 evidence to identify per-joint/per-digit local bend axes and move to a small anatomical pose table (or direct artist-authored Blender pose) before any Godot product integration.

## Current priority

R1 remains continuous hero hand-wrist-forearm anatomy and believable whole-hand choreography.
R2 remains real support-wrap and label-pinch contact.
Micro skin/PBR, paper fibers, glass micro-highlights and condensation remain deferred until Macro/Meso hand structure passes.
