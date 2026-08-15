# Peel Calm reference convergence checkpoint 23

Date: 2026-08-15
Production main: `769d6452e75112084f537af99be90721c2629cd5`
Previous branch: `spike/mpfb-hero-limb-joint-plane-v54`
Previous exact candidate: `622857d6e91518c75e2b8a15b197fb49491f19e1`
MPFB Joint Plane v54: run `31878904387` — PASS
Godot Check v54: run `31878904364` — PASS
v54 visual artifact: `9245517275`

Reference-direction branch: `spike/mpfb-hero-limb-reference-direction-v55`
Reference-direction exact candidate: `76fca6bfe95a3b3c5692fc66b7147c191dd01f16`
MPFB Reference Direction v55: run `31881539197` — PASS
Godot Check v55: run `31881539152` — PASS
v55 visual artifact: `9246166520`
v55 artifact digest: `sha256:2bf4b107256b6060e11150d746333df92820cf11b02d1463e3d989730f94d26b`

Current branch: `spike/mpfb-hero-limb-reference-bend-v56`
Current hypothesis head after workflow creation: `19f669387f5b425488a04c7ce3a88ceec41c6263`

## Locked target

`cafe_v1 / bar_v1 / market_v1` remain unchanged. R1 support-hand Macro/Meso is still binding. No Micro polish is allowed while the support-hand silhouette reads as open/claw-like or structurally broken.

## v54 visual verdict — REJECT

Inspected:

- `anatomical_controls_v53_candidate.png` from the v54 artifact;
- corresponding 192×108 thumbnail.

The vessel fixture and whole-hand placement remain readable, but the four fingers still read as long, mostly straight projections. Per-phalanx `direction × palm_normal` axes did not produce a convincing enclosing grasp. This closes the v54 hypothesis: the missing authoring layer is not solved by another geometric hinge-axis definition.

## v55 visual verdict — REJECT

Inspected:

- `reference_direction_v55_candidate.png`;
- `reference_direction_v55_thumbnail.png`.

v55 deliberately avoided BVH matrix/roll/translation copying and transferred only normalized source segment directions from the official CC0 MakeHuman Poses 01 holding-wine-glass reference into the GameEngine palm frame. The technical contract passed and the durable 17-bone pose reload remained stable.

The visual result is nevertheless unacceptable. Several finger chains show severe twisting/self-intersection and detached-looking phalanx blocks; the full frame is anatomically broken and the thumbnail does not read as a coherent human vessel wrap. The v55 report shows why the transfer was too aggressive: individual target segment rotations reached roughly 74° for middle/ring fingers and more than 107° at the thumb base.

Therefore absolute reference segment-direction transfer is rejected even when it is license-safe and transform-safe.

## Do not repeat

Do not return to:

- CCD / endpoint chasing / surface servo;
- broad local-axis tables or angle sweeps;
- whole-hand orbit search;
- shared flexion axes;
- per-phalanx geometric hinge-axis search;
- absolute source segment-direction transfer;
- direct source BVH matrices, bone roll, translation or scale.

## v56 falsifiable hypothesis

A useful part of the CC0 holding-object pose may be its **relative anatomical bend structure**, not its absolute segment directions.

v56 changes only this abstraction:

1. import the official CC0 holding-wine-glass BVH into a sacrificial source armature;
2. extract a bounded proximal pitch plus the two adjacent-phalanx bend angles for each non-thumb digit;
3. keep the proven GameEngine whole-hand placement and target palm frame;
4. rebuild target finger directions recursively in the target palm closing plane;
5. preserve bounded v53 semantic thumb opposition rather than copying the source thumb direction;
6. copy no source matrix, bone roll, translation, scale or absolute segment direction;
7. persist the resulting 17-bone target pose through the v49 durable-pose format;
8. render one full frame plus one 192×108 frame — no candidate sweep.

## Acceptance gate

v56 is accepted for the next stage only if the 192×108 frame immediately reads as a coherent human vessel wrap:

- palm is visibly associated with the vessel rather than merely beside it;
- index→pinky form an ordered enclosing silhouette;
- phalanges remain connected-looking without catastrophic twists/self-intersection;
- fingers progressively turn around / disappear behind the far vessel contour;
- thumb visibly opposes the finger group;
- wrist/forearm flow remains compatible with the locked reference composition.

Technical success cannot promote a visually failed candidate.

## Next exact action

Wait for exact-head v56 Godot Check and `MPFB Reference Bend v56` workflow. Download the v56 artifact, inspect both full and 192×108 frames, and either:

- **PASS Macro/Meso:** freeze the pose and move to a Godot product-camera staging scene against the current XR baseline; or
- **REJECT:** stop reference-derived parametric authoring and move to a true artist-authored/manual Blender pose asset, using the CC0 source only as a side-by-side anatomy reference rather than as transform input.
