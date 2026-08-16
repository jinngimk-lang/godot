# Peel Calm reference convergence checkpoint 45

Date: 2026-08-16
Branch: `spike/mpfb-grip-web-viewport-v88`
Production main baseline: `769d6452e75112084f537af99be90721c2629cd5`
Pre-gate v88 product-camera script head: `14d269ea85867c1b739cfa1ec770719b91fdda7a`
Evidence-workflow head: `67afed70449c006081393eca8373e61ccd67c993`

## Acceptance references

Locked acceptance set remains `bar_v1` and `market_v1` for support-hand work. Runtime and staging captures remain evidence and may not replace the locked references.

## Current highest red

R1 remains the support hand at Macro/Meso scale: the product frame must read immediately as a continuous human hand/wrist/forearm stably wrapping the bottle, with readable thumb-versus-four-finger opposition and no claw/fan/fist-clump silhouette.

Micro skin/PBR, paper fiber, glass highlight breakup, liquid and condensation remain frozen until this lower-frequency hand red closes.

## What changed in v88

The v88 branch established a single deliberate semantic-control edit from the v87 native MPFB authoring scene and a staging-only GLB export path. It explicitly does not use CCD, endpoint chasing, contact optimization, automatic retargeting or parameter sweep. The candidate remains staging-only and is not a production asset.

`tests/capture_v88_product_camera.gd` was added to load the actual Peel Calm scene, preserve the product camera and scene presentation, and capture:

- `bar_xr`
- `bar_v88`
- `market_xr`
- `market_v88`
- `market_v88_inspect45`

The script swaps only the support-hand presentation while retaining the same product scene/camera so that XR versus MPFB is a meaningful A/B.

## Evidence-chain defect discovered in this loop

Exact-head Godot Check `31937799262` for `14d269ea85867c1b739cfa1ec770719b91fdda7a` passed, but its standard `peel-calm-reference-frames` artifact (`9261153247`) contains only the normal nine café/bar/market regression frames. The standard Godot workflow does **not** invoke `capture_v88_product_camera.gd` and therefore does not prove that the v88 candidate visually improves bar/market support-hand framing.

Do not use `9261153247` as v88 A/B evidence.

## Fix made

Added branch-scoped `.github/workflows/mpfb-v88-product-camera.yml` at head `67afed70449c006081393eca8373e61ccd67c993`.

The workflow performs one exact chain in the same run:

1. install pinned Blender 4.2.0 and MPFB 2.0.17 with verified archive hashes;
2. rebuild the exact v87 authoring scene;
3. export the single v88 staging candidate to `assets/models/hands/staging/support_limb_v88.glb`;
4. verify staging-only/no-sweep/no-optimizer/no-auto-retarget boundaries;
5. install pinned Godot 4.7.1;
6. import the generated GLB;
7. execute `tests/capture_v88_product_camera.gd` under Xvfb;
8. require all five XR/v88 A/B frames including `market_v88_inspect45`;
9. upload exact-head product-camera images, reports and logs.

Workflow run: `31938074660`.

At checkpoint time it is still running; no visual PASS or FAIL is recorded yet. This checkpoint must not be interpreted as candidate approval.

## v88 authoring calibration evidence

The successful semantic-control response atlas run `31937332742` produced artifact `9261132761`. It remains calibration-only (`visual_verdict = NOT_A_CANDIDATE`) and must not be ranked as a candidate set. Its purpose was to prove how the seven semantic controls affect the same native rig while restoring the seed exactly after each diagnostic response.

## Next exact action

1. Wait for product-camera run `31938074660` to complete.
2. Download its `mpfb-v88-product-camera` artifact.
3. Inspect `bar_xr` versus `bar_v88` and `market_xr` versus `market_v88` first at thumbnail/Macro scale.
4. Reject immediately if v88 does not clearly improve vessel enclosure, human silhouette and thumb/finger opposition over XR.
5. If Macro improves, inspect full-resolution/Meso anatomy plus `market_v88_inspect45` for wrist continuity, self-intersection, finger depth ordering and stability under inspection yaw.
6. Only if both Macro and Meso improve should the branch proceed to an independent Challenger and production integration proposal.
7. If v88 fails, keep the product-camera evidence workflow, record the failure, and return to the native-rig artist scene rather than starting a parameter sweep.

## Do not repeat

- Do not infer v88 visual quality from a green standard Godot Check.
- Do not use the normal nine-frame artifact as proof of the swapped MPFB candidate.
- Do not promote the response atlas frames as candidates.
- Do not restart CCD, endpoint chasing, contact servo, whole-hand orbit, raw joint-angle tables or parameter sweeps.
- Do not move to Micro material polish while R1 remains visible.
