# Peel Calm reference convergence checkpoint 08

Date: 2026-08-15
Production baseline: `main@769d6452e75112084f537af99be90721c2629cd5`
Production post-merge Godot Check: `31810098509` — PASS
Production runtime frame artifact: `9222768455`
Acceptance set: `cafe_v1`, `bar_v1`, `market_v1`

## Model-spike baseline

R1 remains continuous realistic hand/wrist/forearm anatomy. MPFB remains the accepted anatomy direction, but no MPFB pose candidate is yet approved for gameplay.

R2 remains photographic vessel-wrap and paper-flap pinch contact. It is the blocking gate before Godot integration.

## v20 — bounded thumb-chain mapping comparison

Branch/head: `spike/mpfb-hero-limb-retarget-v20@40f99dd3e016f0fdc7323e3999855832d4f2f7e5`
Godot Check: `31836805495` — PASS
MPFB preview run: `31836805485` — PASS as experiment runner
Artifact: `9232927152` (`mpfb-hero-limb-retarget-v20`)

v19 had already shown that adding XR metacarpal/base semantics reduced the Pinch gap from ~95.6 mm to ~59.3 mm. v20 froze every non-thumb mapping and tested only four explicit XR `Thumb_Distal_R` -> MPFB `thumb_02_r` / `thumb_03_r` distributions under the same camera, material, light and paper/vessel proxies.

### Pinch measurements

- `half_half` `(0.50, 0.50)`: `0.059300 m`
- `full_second_only` `(1.00, 0.00)`: `0.062352 m`
- `two_thirds_one_third` `(0.667, 0.333)`: `0.060323 m`
- `full_both` `(1.00, 1.00)`: `0.070421 m`

The original v19 half/half mapping remained numerically best. None approached the <=12 mm contact gate.

### Support measurements

All four variants retained effectively identical non-thumb support radial errors of approximately `[1.2, 27.9, 18.1, 20.7] mm`; changing distal thumb distribution did not repair the hanging/claw support silhouette.

### Real-frame verdict

- All four pinch variants visibly remain non-photographic.
- The paper proxy is not held between thumb and index.
- Extra distal rotation can make the thumb bend differently but does not establish correct opposition.
- No variant improves the Macro/Meso silhouette enough to justify gameplay integration.

Verdict: **reject the remaining thumb-weight mapping family**. Do not spend more loops distributing the same source rotation delta across `thumb_02_r` / `thumb_03_r`.

## Falsified path boundary

The following related approaches are now evidence-backed dead ends for this target:

1. direct MPFB joint-angle search / generic contact optimizer (v10-v16);
2. XR semantic local rotation-delta retarget without metacarpals (v18);
3. metacarpal-aware local rotation-delta retarget (v19) as a complete solution;
4. bounded XR-distal -> MPFB three-joint thumb redistribution (v20).

Semantic information from the XR animations remains useful, but local rotation deltas are not a sufficiently morphology-invariant representation between the two rigs.

## Next exact action

Move to a morphology-invariant semantic pose representation:

1. sample each XR authored action (`Cup`, `Pinch Up`, `Pinch Tight`) as **normalized phalanx direction vectors and fingertip/contact landmarks in the XR hand frame**;
2. keep MPFB segment lengths, mesh, wrist and forearm anatomy unchanged;
3. map those source directions into the MPFB `hand_r` frame and align each MPFB digit segment parent-to-child to the corresponding semantic direction;
4. for MPFB's extra third thumb phalanx, inherit/interpolate the source distal direction rather than splitting an angle delta;
5. report required per-joint direction change, thumb/index gap, contact midpoint and support wrap measurements;
6. reject any candidate requiring implausible joint rotations, self-intersection, or a claw silhouette even if the gap closes numerically;
7. only after fixed-camera Macro/Meso visual acceptance should the candidate be exported/imported into Godot gameplay.

This is a pose-transfer experiment, not generic IK and not an unconstrained optimizer.
