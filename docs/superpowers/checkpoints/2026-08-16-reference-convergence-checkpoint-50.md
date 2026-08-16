# Peel Calm reference convergence checkpoint 50

Date: 2026-08-16
Production baseline: `main@769d6452e75112084f537af99be90721c2629cd5`
Staging branch: `spike/mpfb-whole-hand-spatial-v91`
Exact visual head: `79c4f194f9dfed85b6d96fd6f7185799b3dded80`

## Locked acceptance references

- `bar_v1`
- `market_v1`
- Manifest: `art/acceptance_refs/v1/MANIFEST.md`

Runtime/staging captures remain evidence only. They do not replace the acceptance targets.

## Why v91 exists

Checkpoint 49 rejected v90 even though its exact-head CI was green. Increasing semantic grip values changed local finger flexion but left the support hand reading as a large open C-shape across the bottle/label rather than a firm human vessel grip.

The next falsifiable hypothesis was deliberately an abstraction change rather than another grip-magnitude sweep:

> preserve the proven `-40°` side-on whole-limb choreography, v89 continuous wrist crop, physical product scale/root/camera, and the exact v90 semantic closure, then make one native-rig whole-hand spatial rotation so palm and fingers change depth together. If the product-camera silhouette becomes materially more enclosing without regressing the side-on approach, wrist continuity, label readability, or `inspect45`, whole-hand spatial orientation is a useful control level. If the hand remains an open C-shape, reject the candidate and do not turn the experiment into a yaw sweep.

## Single v91 production-staging change

`tools/export_mpfb_support_candidate_v88.py` now preserves the exact v90 semantic values:

- `wrist.R rx +10°`
- master grip `+18°`
- thumb `+4°`
- index `-8°`
- middle `+4°`
- ring `+10°`
- pinky `+16°`

and adds exactly one native-rig whole-hand spatial edit:

- `wrist.R local Y +16°`

The following remain frozen:

- whole-limb product-camera roll `-40°`
- palm crop radius `0.058`
- wrist/forearm crop radius `0.046`
- finger crop radius `0.018`
- product scale
- Godot support root/yaw contract
- product camera
- vessel geometry / label / environment

No CCD, endpoint optimizer, contact servo, automatic retarget, parameter sweep, or arbitrary scale change was used.

## Exact-head verification

### Godot 4.7.1 full check

- Run: `31947443445`
- Head: `79c4f194f9dfed85b6d96fd6f7185799b3dded80`
- Result: **PASS**
- Standard nine-frame artifact: `peel-calm-reference-frames`
- Artifact id: `9263694601`

This verifies exact-head import/launch, deterministic unit/smoke/reset/input contracts, and the normal café/bar/market capture matrix.

### Same-camera MPFB product A/B

- Run: `31947446545`
- Head: `79c4f194f9dfed85b6d96fd6f7185799b3dded80`
- Result: **PASS**
- Artifact: `mpfb-v88-product-camera`
- Artifact id: `9263760132`

The exact-head A/B contains:

- `bar_xr`
- `bar_v88` (v91 candidate payload)
- `market_xr`
- `market_v88` (v91 candidate payload)
- `market_v88_inspect45`

## Runtime frames inspected

I directly compared v90 and v91 product-camera frames for:

- bar support hand
- market support hand
- market support hand at `inspect45`

and checked the new v91 candidate against the same locked acceptance intent used by v89/v90.

## Visual verdict — **REJECT for production**

### Macro

v91 changes the support hand more coherently in depth than simply increasing grip. The palm/finger assembly becomes slightly more side-oriented and less uniformly flat across the bottle front.

However the primary R1 Macro requirement still fails:

- the hand still reads as an **open C-shape** around the bottle rather than a firm natural support grip;
- the four fingers do not convincingly progress around and disappear behind the bottle's far silhouette;
- thumb versus opposing-finger separation remains too weak to make stable opposition immediately readable at thumbnail scale;
- the hand continues to compete with the hero label more than the locked references do.

Therefore CI green does **not** promote v91 to a product candidate.

### Meso

Preserved passes:

- the proven side-on forearm approach remains intact;
- the v89 wrist/palm crop fix remains intact — no V-notch regression;
- physical vessel-relative scale remains unchanged;
- `market_v88_inspect45` keeps the hand/wrist relationship stable enough to show no new rotation/crop failure.

Positive but insufficient learning:

- rotating the whole native-rig palm/finger assembly in depth is a more useful structural control than continuing semantic grip escalation;
- `+16°` alone is still insufficient to create the reference-style enclosure.

## Closed / preserved reds

- **R1a side-on limb approach:** remains closed.
- **R1a wrist crop discontinuity:** remains closed.
- **Physical scale mapping:** preserved; no arbitrary scale sweep.
- **Inspection stability:** no new `inspect45` regression.

## Remaining reds, ranked

### R1 — whole-hand support enclosure

The palm must sit on the bottle flank rather than across the hero label, while index is the lightest closure and middle/ring/pinky progressively occupy deeper far-side layers. Thumb must remain visibly opposing on the other side.

### R2 — Godot product-camera final support-hand validation

Only after R1 passes Macro and unobstructed Meso should the MPFB support hand replace the XR baseline for integration testing.

### R3 — peel-hand pinch / flap contact

Still blocked behind the support-hand hero-asset gate.

### Micro — skin, paper, glass, liquid, condensation

Still frozen.

## What v91 proved

1. The v90 failure is not solved by still more scalar grip.
2. Whole-hand spatial orientation is the correct *level of abstraction* to investigate, because it changes palm/finger depth together.
3. A single wrist spatial rotation is **not** enough by itself; the remaining problem is the combined palm placement + orientation + progressive finger depth relationship.
4. Product-camera proof remains mandatory; Blender or report metrics alone are insufficient.

## Do not repeat

- Do not turn `WHOLE_HAND_SPATIAL_YAW_DEG` into a blind `8/12/16/20/24°` sweep.
- Do not increase semantic master/finger grip again as the primary fix.
- Do not restart CCD, endpoint chasing, contact servo, raw phalanx axis tables, whole-hand orbit sweeps, thumb-only sweeps, or arbitrary scale sweeps.
- Do not reopen crop envelopes unless the wrist notch actually returns.
- Do not begin skin/PBR, paper, glass, liquid, or condensation polish while R1 remains obvious at thumbnail scale.

## Next exact action

Create exactly **one** reference-derived whole-hand product-camera authoring candidate at the next structural level:

1. Freeze v91/v89 proven side-on limb approach, wrist crop, physical scale, product root/yaw, camera, vessel, environment, and label.
2. Use the native-rig artist scene / semantic controls as a whole-hand authoring surface rather than a scalar search.
3. Treat palm placement and orientation as one gesture: put the palm on the bottle flank and away from the label center/front.
4. Preserve the useful depth-control lesson from v91, but author the four fingers as a coordinated depth stack: index lightest, middle/ring/pinky progressively farther around the cylinder so some distal silhouette is occluded by the far side.
5. Keep thumb clearly readable on the opposing side and retain web space.
6. Produce one candidate only; no parameter grid.
7. Run full exact-head Godot 4.7.1 validation and the exact same five-frame bar/market A/B.
8. Reject immediately if thumbnail enclosure does not materially improve, or if side-on approach, wrist continuity, label readability, physical scale, or `inspect45` regress.
9. Only if Macro passes, add/inspect an unobstructed Meso anatomy view before Challenger or production integration.

`main` remains untouched. No product PR should be opened from v91.