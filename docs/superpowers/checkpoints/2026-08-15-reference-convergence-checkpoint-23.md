# Peel Calm reference convergence checkpoint 23

Date: 2026-08-15
Production main: `769d6452e75112084f537af99be90721c2629cd5`
Branch: `spike/mpfb-hero-limb-joint-plane-v54`
Exact evaluated candidate: `622857d6e91518c75e2b8a15b197fb49491f19e1`
Godot Check: run `31878904364` — PASS
MPFB Joint Plane v54: run `31878904387` — PASS
Visual artifact: `9245517275`
Artifact digest: `sha256:4079ad1057edb0bb97aa0659fac6235e7e4f3c6e10b7f0b1e707f59a0fa0f019`

## Locked target

`cafe_v1 / bar_v1 / market_v1` remain unchanged. The binding gate is still R1 support-hand Macro/Meso: at thumbnail scale the hand must immediately read as a human vessel wrap, with an opposed thumb and the four fingers progressively disappearing around/behind the far vessel contour.

## What v54 tested

v54 preserved the v53 whole-hand placement, fixed authored flex magnitudes, thumb semantic target, v49 durable-pose format, fixture and render camera. It changed only finger flexion-axis derivation: every phalanx derived its own current direction and used `phalanx_direction × palm_normal` as the geometric flexion axis, with sign selected by a small semantic probe toward the vessel-facing normal.

Machine evidence passed:

- no automatic retarget;
- no BVH/source pose transform copy;
- no endpoint target solver;
- no CCD/surface servo/distance minimization;
- no `_bend_toward_center`;
- no blind local XYZ table;
- 17 durable pose bones;
- save → clear → reload max matrix error `5.960464477539063e-08`.

The report recorded nontrivial per-joint rotations (roughly 30–50 degrees across MCP/PIP/DIP chains), so this was not a no-op pipeline run.

## Frames inspected

From artifact `9245517275`:

- `previews/anatomical_controls_v53_candidate.png` — this filename is inherited from the reused v53 renderer, but the image is the v54 pose produced by the v54 authoring step.
- `previews/anatomical_controls_v53_thumbnail.png` — 192×108 Macro gate for the same v54 pose.

## Visual verdict — REJECT

The thumbnail fails the binding Macro/Meso gate.

Observed defects:

1. The four visible fingers remain long and mostly extended along the vessel-facing plane instead of visibly wrapping around the cylinder.
2. Index/middle/ring do not progressively disappear behind the far contour; the silhouette still reads as an open hand touching a bottle.
3. Thumb opposition is not strong/readable enough to create a clear opposing-side clamp at thumbnail scale.
4. The hand therefore does not resemble the approved reference family's support-hand enclosure even though the underlying continuous MPFB hand/wrist/forearm anatomy is structurally superior to the production XR hand.

This is a visual failure despite both workflows being green. Do not promote v54 into product-camera staging or production.

## Falsification / route closed

The following increasingly semantic procedural approaches have now failed the same Macro/Meso enclosure requirement across multiple real-frame iterations:

- endpoint/CCD/contact chasing;
- shared-axis authored flexion;
- mixed-axis tables;
- world-direction/arc alignment;
- whole-hand orbit sweeps;
- shared palm semantic flex axis;
- per-joint geometric flexion plane.

Continuing to vary flex axes, tolerances, contact distances or orbit values would be another parameter-search loop around a repeatedly falsified abstraction. Stop that class of work here.

## Highest-impact red

R1 remains: **artist-quality support-hand grasp silhouette and thumb opposition on the continuous MPFB limb**.

R2 remains downstream: product-camera proof in café/bar/market after R1 passes.

R3 remains: peel-hand thumb/index pinch choreography.

Micro skin/PBR, paper fibers, glass highlights and condensation remain blocked behind R1/R2.

## Next exact action

Pivot from procedural grasp generation to a genuinely artist-authored durable FK pose using the already-verified v49 17-bone partial-pose format.

1. Keep the continuous MPFB GameEngine hand/wrist/forearm asset and current product-scale vessel fixture.
2. Use a license-safe human object-holding reference only as anatomical guidance, not as a transform source into the production rig.
3. Author one support pose deliberately as a whole silhouette: palm close to the near/side wall, thumb crossing/opposing on the near-upper side, index/middle/ring/pinky curling with visible depth ordering so distal portions disappear behind the far vessel contour.
4. Manipulate the 17 GameEngine FK bones directly and save the result as a v49 durable partial pose; do not run an optimizer after authoring it.
5. Render full + 192×108 from the same fixed camera.
6. Reject immediately unless the thumbnail first reads as a human vessel wrap without needing numeric explanation.
7. If it passes, only then make a small radius adaptation for cup vs bottle and enter Godot product-camera staging against the current XR baseline.
8. After product-camera improvement is proven on exact-head runtime frames, run the independent Challenger before any production PR/merge.

## Do not repeat

Do not create v55/v56 as another flex-axis, contact-distance, CCD, fingertip-error, orbit-angle, or broad coefficient sweep. The next candidate must change the abstraction: **manual/artist-authored FK silhouette first**.
