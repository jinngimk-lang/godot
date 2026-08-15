# Peel Calm reference convergence checkpoint 24

Date: 2026-08-15
Production main: `769d6452e75112084f537af99be90721c2629cd5`
Branch: `spike/mpfb-hero-limb-reference-bend-v56`
Exact visual candidate: `d3d5fc7f337a914de87aa79761ce761d073a9c5b`
Godot Check: run `31881929105` — PASS
MPFB Reference Bend v56: run `31881929003` — PASS
Visual artifact: `9246271422`
Artifact digest: `sha256:7d10d4ab45649dae1517ec0c5cbcb8c051cee2d574befa52beca44b200ee3a22`

## Locked target

`cafe_v1 / bar_v1 / market_v1` remain the acceptance family. The support hand must read as a natural human hand wrapping the cup/bottle at thumbnail and product-camera scale before any skin/PBR/paper/glass Micro work can outrank it.

## v56 technical result

PASS. The exact candidate was verified by both the full Godot 4.7.1 suite and the dedicated MPFB workflow. The workflow also verified:

- official MakeHuman Poses 01 holding-wine-glass source remains CC0 staging reference;
- no source matrix, bone roll, translation, scale or absolute segment direction was copied;
- only bounded proximal pitch and adjacent-phalanx relative bend magnitudes were transferred;
- target pose remained a 17-bone GameEngine partial pose;
- save → clear → reload stayed within the existing `<= 1e-6` matrix gate;
- both full and 192×108 evidence frames were produced.

## v56 visual verdict — REJECT

Inspected:

- `reference_bend_v56_candidate.png`;
- `reference_bend_v56_thumbnail.png`.

At full resolution the palm and vessel are spatially associated, but the hand still does not form a convincing support grasp. Index, middle and ring remain long, nearly straight projections toward/along the near side of the bottle rather than progressively curling around its far contour. Pinky is more bent but reads as an isolated hooked digit rather than part of an ordered grip. Thumb opposition is not legible as the opposing side of a clamp.

The 192×108 frame is decisive: it reads as several fingers touching/reaching toward the vessel, not a human hand enclosing it. The silhouette therefore fails the binding Macro/Meso gate despite green technical metrics.

## Closed hypothesis family

v54–v56 now provide enough evidence to stop reference-derived parametric support-grasp authoring for this rig.

Rejected families include:

- CCD / endpoint chasing / surface servo;
- broad local-axis/angle sweeps;
- whole-hand orbit search;
- shared semantic flexion axis;
- per-phalanx geometric hinge-axis derivation;
- absolute source segment-direction transfer;
- bounded source relative-bend transfer;
- direct source BVH matrix/roll/translation/scale transfer.

Do not create v57 as another retargeting or geometric solver variant.

## New route — true manual FK pose asset

The next support-hand candidate must be authored as an explicit target-rig pose, judged visually while it is authored, rather than computed from endpoint/reference geometry.

Rules:

1. Keep the continuous MPFB GameEngine hand–wrist–forearm mesh and the proven 17-bone durable partial-pose format from v49.
2. Use `cafe_v1 / bar_v1 / market_v1` plus the CC0 holding-object image/pose only as side-by-side anatomy references.
3. Do not feed source transforms or derived target directions into the target rig.
4. Author the target GameEngine FK values explicitly, digit by digit and joint by joint, with visual renders between meaningful edits.
5. Work from whole-hand composition inward:
   - palm orientation/clearance;
   - thumb base/opposition;
   - index proximal enclosure;
   - middle/ring enclosure;
   - pinky only after the major silhouette works.
6. Freeze a joint once it improves the reference silhouette; avoid reopening broad parameter searches.
7. Persist every accepted manual pose as a named 17-bone pose asset with provenance `artist-authored-target-rig`.
8. No production integration until a 192×108 render immediately reads as a human vessel wrap.

## Manual-pose visual gates

Macro:

- palm overlaps/frames the near side of the vessel in a reference-like way;
- at least two non-thumb fingers visibly disappear around the far contour;
- hand/vessel proportion resembles the locked references;
- wrist/forearm flow is plausible at product framing.

Meso:

- thumb is clearly on the opposing side from the finger group;
- index/middle/ring show non-parallel progressive curl;
- no detached-looking phalanges, self-intersection or solver kinks;
- contact reads as support/grip, not reach/touch.

## Integration status

No production PR was opened. Current `main` remains clean at `769d6452e75112084f537af99be90721c2629cd5`; the current known merged-main nine-frame runtime artifact remains `9222768455`. No open PRs were present when this checkpoint was written.

## Next exact action

Create an isolated manual-FK authoring branch/tool that loads the GameEngine human and the v49 durable target-rig pose format, renders the locked product-side support composition, and applies only explicit hand-authored target-rig joint edits. Produce one named support-wrap manual pose, full render, and 192×108 thumbnail. If and only if it passes Macro/Meso, export it to a Godot staging asset and compare it under the real café/bar/market camera against the current XR baseline.
