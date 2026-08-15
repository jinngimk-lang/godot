# Peel Calm reference convergence checkpoint 22

Date: 2026-08-15
Production main: `769d6452e75112084f537af99be90721c2629cd5`
Branch: `spike/mpfb-hero-limb-anatomical-controls-v53`
Exact candidate: `1f53e5613abe8ddf47f99229bad1ec9829fa3d25`
MPFB Anatomical Controls v53: run `31878738300` — PASS
Visual artifact: `9245472184`
Artifact digest: `sha256:9d0fd20297c43262d8ef9cc5a3792b9b3926f58da85ea21d40381099ff39c97f`

## Locked target

`cafe_v1 / bar_v1 / market_v1` remain unchanged. R1 support-hand Macro/Meso remains binding.

## What v53 tested

v53 was the first solver-free support candidate to replace raw local Euler-axis guessing with a semantic palm frame derived from the GameEngine rig itself.

Machine evidence passed:

- no automatic retarget;
- no source BVH transforms;
- no target solver;
- no `_bend_toward_center`;
- no blind local-Euler table;
- 17 durable pose bones;
- save → clear → reload max matrix error `1.7881393432617188e-07`.

The semantic control used `index MCP -> pinky MCP` palm span as one shared flexion axis. Fixed authored MCP/PIP/DIP flex magnitudes were applied around actual joint heads; thumb opposition was expressed in palm semantic axes.

## Visual verdict — REJECT

Frames inspected:

- `anatomical_controls_v53_candidate.png`
- `anatomical_controls_v53_thumbnail.png`

The corrected vessel fixture and whole-hand placement are readable, but the four visible fingers remain long and mostly straight. They fan/rotate in the hand plane rather than flexing at MCP/PIP/DIP into a wrap. The candidate therefore still reads as an open hand touching a vessel, not a human hand enclosing it.

This is a useful local falsification: the shared palm-span vector is not the GameEngine finger-flexion axis. The failure no longer requires another broad pose search.

## Next exact action

Keep the v53 whole-hand placement, fixed authored flex magnitudes, thumb semantic target, v49 durable-pose format, fixture and rendering camera unchanged. Replace only the finger flexion-axis definition.

For each phalanx at the instant it is authored:

1. derive the current phalanx direction from its own pose-bone head/tail;
2. use the already-resolved palm/vessel-facing normal as the desired closing-plane direction;
3. define that joint's geometric flexion axis as `phalanx_direction × palm_normal` (with degeneracy fallback only);
4. choose the sign once so a small probe rotation moves that phalanx toward the palm/vessel-facing normal;
5. apply the same fixed index/middle/ring/pinky MCP/PIP/DIP flex magnitudes used by v53;
6. retain the independent semantic thumb opposition/curl;
7. render full + 192×108 and reject unless fingers visibly articulate and progressively disappear behind the far vessel contour.

This remains an anatomical-control authoring test, not endpoint IK: no target points, CCD, surface servo, distance minimization, BVH rotation copy or parameter sweep is allowed.

Do not move to product-camera staging or Micro polish until this Macro/Meso gate passes.
