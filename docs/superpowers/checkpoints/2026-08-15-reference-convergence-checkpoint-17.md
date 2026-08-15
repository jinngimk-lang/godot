# Peel Calm reference convergence checkpoint 17

Date: 2026-08-15
Production baseline: `main@769d6452e75112084f537af99be90721c2629cd5`
Experiment branch: `spike/mpfb-hero-limb-authored-support-v47`
Exact authored-pose code head with full Godot verification: `f718b1538653d24060e7a416618bcf95c09613d5`
Evidence persistence head: `a2678e9c4c635ca54e87052e32dc60753e979217`
Godot Check: run `31874719813` — PASS
Godot runtime frames artifact: `9244420423` (`peel-calm-reference-frames`)
MPFB authored-support run: `31874879226` — PASS on the same v47 pose implementation plus reconstructable-evidence tooling
Earlier equivalent visual artifact: `9244403022` (`mpfb-authored-support-v47`)
Locked references remain: `cafe_v1`, `bar_v1`, `market_v1`

## Hypothesis tested

Checkpoint 16 closed further rigid-orbit and IK/endpoint parameter searches. v47 tested one deliberately authored whole-hand grasp instead:

- preserve the proven continuous MPFB hand/wrist/forearm and v35 whole-hand placement;
- give every index/middle/ring/pinky phalanx an explicit world-frame direction intended to travel from the near palm surface around the vessel far contour;
- author the thumb independently toward a near/upper opposition region;
- use no optimizer, endpoint tolerance, CCD, surface servo, or parameter sweep;
- render both full resolution and a true 192×108 thumbnail so Macro silhouette is a first-class gate.

The falsifiable claim was: if a coherent whole-hand direction table is sufficient, the thumbnail should immediately read as a human vessel wrap rather than parallel prongs.

## Technical result

The pipeline itself is healthy.

- Continuous MPFB right hero limb built and extracted successfully.
- The authored pose rendered successfully in pinned Blender 4.2.0 + MPFB 2.0.17.
- Exact-head Godot 4.7.1 import/parse/default launch/unit/smoke/reset/pause checks passed.
- Nine café/bar/market runtime frames were captured successfully.
- Visual evidence is now persisted in Git instead of existing only as a transient Actions artifact.

Diagnostic values from the authored pose were:

- whole-hand rotation: `64.476°`
- root shift: `0.020901 m`
- palm clearance: `0.014 m`
- palm normal alignment: `0.9999`
- minimum fingertip spacing: `0.028475 m` (`ring`, `pinky`)
- thumb near-dot: `0.6872`
- finger near-dots: `[0.0649, -0.1042, -0.0453, 0.5320]`

These values are diagnostic only and did not determine acceptance.

## Mandatory visual review

Evidence reviewed:

- `docs/superpowers/evidence/mpfb-v47/authored-support-thumbnail.png`
- `docs/superpowers/evidence/mpfb-v47/authored-support-full.png`

### Macro — REJECT

The 192×108 thumbnail does **not** read as a support hand enclosing a bottle. It reads as a palm at frame left with several long, almost parallel fingers projecting horizontally into the bottle silhouette. The far-side enclosure that is obvious in the approved reference family is absent.

The hand therefore still fails the most important low-frequency question: “is the vessel visibly held?”

### Meso — REJECT

The full frame explains the Macro failure:

- index, middle and ring remain substantially extended rather than curling around the cylinder;
- their intermediate/distal chains do not disappear behind the far vessel contour;
- pinky has more curl, but it becomes an isolated hooked digit rather than part of a coherent progressive grasp;
- thumb sits below/inside the palm region and does not form a clear near/upper opposition against the four fingers;
- large gaps between the main fingers preserve the VR-controller / open-hand reading;
- the hand-vessel relationship remains approach/contact rather than enclosure.

This is a visual failure despite green CI and plausible diagnostic metrics.

### Micro — intentionally not evaluated

Skin, paper, glass and lighting micro-polish remain deferred because the grasp fails Macro/Meso.

## Conclusion

**v47 is visually rejected and must not enter Godot product-camera staging or production.**

The experiment provides useful evidence: merely replacing an optimizer with authored world-space segment directions is still too abstract. A believable grasp requires the pose to be authored as a composition in the actual reference view, with proximal, intermediate and distal joints deliberately arranged so the visible finger chains bend behind the vessel silhouette and thumb opposition is obvious.

## Closed / do-not-repeat paths

Continue to avoid:

- CCD / fingertip endpoint chasing;
- surface servo / tolerance relaxation;
- broad local-axis grids;
- generic stronger-curl sweeps;
- rigid whole-hand orbit sweeps;
- another large coefficient parameter grid around v47;
- Micro material polish used to camouflage the grasp.

## Current reds

### R1 — Artist-authored support enclosure

Still open. The next pose must be judged directly in the reference-facing camera. Required thumbnail properties:

1. palm readable on the near/lateral vessel surface;
2. index→pinky form a progressive curl rather than parallel prongs;
3. intermediate/distal portions visibly pass behind the far vessel contour;
4. thumb remains visibly opposed on the near/upper side;
5. natural wrist/forearm flow toward the crop;
6. no obvious self-intersection or isolated hooked pinky.

### R2 — Product-camera proof

Blocked until R1 passes staging Macro/Meso.

### R3 — Peel-hand / flap pinch

Separate hero-pose problem after support grasp passes.

### R4 — Micro realism

Skin PBR, paper fiber, glass optics, condensation and residue microdetail remain deferred.

## Next exact action

Create a single v48 reference-view authored grasp, **not a search grid**. Use the v47 render itself as negative evidence: bend the index/middle/ring chains substantially earlier, make each digit cross the visible vessel edge at a different height, keep distal segments behind the cylinder, and move thumb opposition to a clearly visible near/upper contact. Render one fixed candidate + true thumbnail. If the thumbnail still reads as prongs/contact instead of enclosure, stop procedural direction-table authoring and move to a manually keyed Blender pose / external anatomical grasp-pose source before any product integration.
