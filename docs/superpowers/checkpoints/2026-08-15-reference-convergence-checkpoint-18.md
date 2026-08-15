# Peel Calm reference convergence checkpoint 18

Date: 2026-08-15
Production baseline: `main@769d6452e75112084f537af99be90721c2629cd5`
Experiment branch: `spike/mpfb-hero-limb-reference-view-v48`
Exact candidate head: `374931469da844d9f67c1466946513c92a2d4f24`
Godot Check: run `31875068363` — PASS
Godot runtime frames artifact: `9244509294` (`peel-calm-reference-frames`)
MPFB Reference View v48: run `31875068402` — PASS
MPFB visual artifact: `9244530494` (`mpfb-reference-view-v48`)
Locked references remain: `cafe_v1`, `bar_v1`, `market_v1`

## Hypothesis tested

Checkpoint 17 rejected v47 because index/middle/ring remained long, nearly parallel prongs. v48 made one final direction-table experiment rather than a grid:

- preserve the same continuous MPFB right hand/wrist/forearm;
- preserve the same whole-hand placement and fixed diagnostic camera;
- turn proximal/intermediate finger segments around the vessel substantially earlier;
- stagger index→pinky axial crossing heights;
- send distal segments toward the far side of the vessel;
- elevate the thumb toward a clearly visible near/upper opposition region;
- use no CCD, endpoint optimizer, surface servo, tolerance relaxation or parameter sweep.

The falsifiable claim was: if the remaining problem was only “too-late finger turning,” this one stronger early-enclosure pose would make the 192×108 thumbnail read as a held vessel.

## Technical result

The technical pipeline remains healthy.

- Pinned Blender 4.2.0 + MPFB 2.0.17 built and extracted the continuous right hero limb.
- v48 rendered both full-resolution and true-thumbnail evidence.
- MPFB workflow `31875068402` completed successfully.
- Exact-head Godot 4.7.1 workflow `31875068363` completed successfully and produced the normal nine café/bar/market runtime frames.

Diagnostic values:

- whole-hand rotation: `64.476°`
- root shift: `0.020901 m`
- palm clearance: `0.014 m`
- palm normal alignment: `0.9999`
- minimum fingertip spacing: `0.025765 m` (`ring`, `pinky`)
- thumb near-dot: `0.794`
- finger near-dots: `[-0.1574, -0.5009, -0.4030, 0.9979]`
- segment rotation degrees:
  - index: `[28.28, 29.68, 29.82]`
  - middle: `[29.64, 25.20, 33.37]`
  - ring: `[40.05, 27.08, 35.30]`
  - pinky: `[57.26, 25.97, 39.37]`
  - thumb: `[123.21, 69.43, 34.73]`

Again, these numbers are diagnostics only; the visual gate decides acceptance.

## Mandatory visual review

Actual artifact `9244530494` was downloaded and the generated PNGs were inspected directly.

### Macro — REJECT

`reference_view_v48_thumbnail.png` still reads immediately as an open/pronged hand approaching the vertical vessel rather than a hand enclosing it.

The dominant thumbnail silhouette is:

- three long, nearly horizontal index/middle/ring bars crossing in front of the bottle;
- a shorter bent pinky below;
- no obvious thumb-vs-finger opposition silhouette;
- no strong visual evidence that the major fingers continue around and disappear behind the far vessel contour.

The required low-frequency statement “this hand is holding the bottle” still fails.

### Meso — REJECT

`reference_view_v48_full.png` confirms the structural failure:

- index/middle/ring remain visually almost straight despite substantially larger early segment rotations;
- the cylinder is visually behind the finger bars rather than enclosed by them;
- proximal palm/finger geometry shows increasingly unnatural deformation near the hand base;
- pinky bends more but still behaves as an isolated lower hook;
- thumb opposition is not readable as a natural clamp against the four fingers;
- the grasp remains an approach/contact pose instead of a vessel-wrap pose.

This is not a “needs slightly stronger coefficients” result. The visible response of the rig to direct per-segment world direction constraints is itself the wrong abstraction for final hero-hand authoring.

### Micro — intentionally not evaluated

Skin PBR, nails, paper fiber, glass optics, condensation, residue microdetail and final lighting remain deferred.

## Conclusion

**v48 is visually rejected and must not enter product-camera staging or production.**

This also triggers the explicit stop condition from checkpoint 17:

> Stop procedural direction-table authoring after another thumbnail failure.

The direction-table family is now closed. Do not create v49 by tuning these coefficients, increasing joint rotations, or adding another small parameter grid.

## Research-backed next route

Fresh primary/official MPFB documentation confirms a more appropriate authoring path exists:

- MPFB has a dedicated MakePose workflow for saving deliberately posed FK/partial poses as reusable JSON assets.
- Saved poses can be full or partial and are reloadable for the same rig type.
- MakeHuman Community publishes CC0 pose asset packs; `Poses 01` includes a `mindfront_sitting_in_armchair_holding_wine_glass` pose, which is a potentially useful anatomical *reference/source* for an object-holding hand but is not automatically assumed to match our GameEngine rig or bottle grasp.
- The MakeHuman `Hands 01` target pack is CC0 and contains hand-shape corrections (finger correction, thenar/hypothenar, knuckles) that may later improve anatomy, but it is Micro/Meso shape support and must not precede a correct grasp silhouette.

Any external pose is staging input only. Rig compatibility, provenance/license, transform quality, and direct reference-camera screenshot comparison remain mandatory.

## Closed / do-not-repeat paths

Do not return to:

- CCD / endpoint chasing;
- surface servo;
- local-axis grids;
- generic curl sweeps;
- per-joint axis tables;
- rigid whole-hand orbit sweeps;
- direct world-space direction-table authoring (v42–v48 family) as the final pose method;
- Micro material polish as camouflage.

## Current reds

### R1 — manually authored anatomical support grasp

Still open. Next candidate must come from a genuinely keyed pose rather than a procedural segment-direction formula.

Required thumbnail properties remain:

1. palm on the near/lateral vessel surface;
2. index→pinky progressive curl;
3. intermediate/distal chains visibly pass behind the far contour;
4. thumb clearly opposed on near/upper side;
5. natural wrist/forearm flow;
6. no base-hand tearing, prong silhouette or isolated hooked digit.

### R2 — product-camera proof

Blocked until R1 passes staging Macro/Meso.

### R3 — peel-hand / flap pinch

Separate manually-authored hero pose after support grasp succeeds.

### R4 — Micro realism

Still intentionally deferred.

## Next exact action

Build a v49 **manual-pose ingestion/authoring spike**, not another grasp solver:

1. use the stable MPFB GameEngine-rig human before hero-limb extraction;
2. establish a reusable partial hand/wrist pose asset path (MPFB MakePose-compatible JSON or directly keyed Blender FK pose saved as a repository staging asset);
3. first evaluate a permissively licensed object-holding pose source only as anatomical reference/seed, with explicit provenance;
4. manually/keyframe-correct the right hand so the fixed reference camera shows true vessel enclosure;
5. save the resulting pose asset so later cup/bottle radius adaptations start from a visual human pose rather than solver output;
6. render one full frame + true thumbnail and apply the same Macro/Meso gate;
7. only after a pass, export the posed continuous limb and enter Godot product-camera staging.
