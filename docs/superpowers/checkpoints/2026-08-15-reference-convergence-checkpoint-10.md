# Peel Calm reference convergence checkpoint 10

Date: 2026-08-15
Production baseline: `main@769d6452e75112084f537af99be90721c2629cd5`
Production post-merge Godot Check: `31810098509` — PASS
Production runtime frame artifact: `9222768455`
Acceptance set: `cafe_v1`, `bar_v1`, `market_v1`

## Highest-impact reds

R1 remains continuous realistic hand/wrist/forearm anatomy in the real product camera.

R2 remains photographic support-wrap and paper-flap pinch choreography. This checkpoint strengthens the evidence that fingertip/contact numbers cannot substitute for whole-hand Macro/Meso silhouette and palm/root choreography.

Micro skin, paper, glass and condensation polish remains blocked behind R1/R2.

## Recovered v31 gate

Previous checkpoint 09 proved that the continuous MPFB limb can survive the rigged GLB -> Godot 4.7.1 staging pipeline. That was a technical pipeline result, not visual acceptance.

Persisted evidence inspected this loop:

- `docs/superpowers/evidence/mpfb-v31/support-wrap.png`
- `docs/superpowers/evidence/mpfb-v31/label-pinch.png`

### Visual verdict: v31 REJECTED at Macro/Meso

**Support wrap:** numeric contact passes, but the fixed-camera pose visibly reads as a hanging claw. Index/middle/ring/pinky descend along the vessel rather than wrapping naturally around it, and thumb opposition does not create a convincing human grasp.

**Label pinch:** thumb/index can reach the flap numerically, but the palm/root remains visually disconnected above the paper. The image reads as two fingertips reaching down from a hanging hand rather than a whole hand tracking and pinching a lifted paper edge.

These are explicitly listed rejection conditions in checkpoint 09, so v31 must not proceed to a Godot product staging scene.

## v32 falsification — transverse support-vessel axis

Branch: `spike/mpfb-hero-limb-support-axis-v32`
Exact experiment head: `07e841b2a55e92a92ed9265c30fc67fe81536f93`

Hypothesis: v31's hanging-claw support silhouette might primarily be caused by the v22/v23 fixture defining the support vessel axis from `lowerarm -> palm`, which can reward fingertip motion along the incoming forearm. A more anatomically transverse vessel axis derived across the neutral MCP/knuckle row might force a believable circumference wrap.

One structural variable changed:

- support axis now derives from neutral `index_01_r -> pinky_01_r`;
- support center/radius remain unchanged;
- XR `Cup` seed remains unchanged;
- CCD iterations, step cap, 24-degree cumulative extra-joint budget and contact tolerances remain unchanged;
- v30 surface-servo precision remains unchanged;
- pinch fixture is unchanged;
- morphology/scale are unchanged.

New files:

- `tools/render_mpfb_support_axis_v32.py`
- `.github/workflows/mpfb-support-axis-v32.yml`

### Exact-head evidence

Godot Check `31854084623` on `07e841b2a55e92a92ed9265c30fc67fe81536f93` — PASS.

MPFB Support Axis v32 run `31854084614` on the same head — PASS.

Artifact: `9238501440` (`mpfb-support-axis-v32`), digest `sha256:74f472910cb7f4e9cb5d900dd4d6346ad5950aa7abbda26fb73705e1be6425d4`.

Recorded v32 support values:

- transverse axis ~= `(-0.384541, 0.825279, -0.413574)`;
- target errors ~= `[13.08, 15.21, 16.25, 8.16] mm`;
- radial errors ~= `[17.93, 14.45, 21.00, 16.87] mm`;
- palm clearance ~= `41.27 mm`;
- extra joint budget reaches the unchanged `24.0 deg` cap.

Pinch remained the v29/v30 control and still records good numeric contact: face errors approximately `0.65 / 1.20 mm`, visible gap approximately `5.41 mm`, root shift approximately `14.91 mm`.

### Visual verdict: v32 REJECTED

The support image is visibly worse than v31. The proxy cylinder crosses the hand transversely, the fingers still hang rather than form a natural grasp, and self-intersection/structural discontinuity becomes more obvious. The experiment therefore falsifies the hypothesis that changing the support-axis definition alone can solve R2.

This is another deliberate example where green CI plus acceptable contact numbers do **not** imply visual acceptance.

## Updated structural diagnosis

Do not continue with arbitrary v33/v34 axis or fingertip-target tuning.

The support problem is now better described as a **whole-hand root/palm placement problem followed by local finger closure**, not a fingertip-target problem:

1. The palm/root must first be rigidly staged beside the actual upright cup/bottle at a photographic approach angle and believable clearance.
2. The vessel axis should come from product geometry / product-equivalent staging, not be inferred from forearm or knuckle vectors solely to make an IK fixture convenient.
3. Thumb opposition must be a first-class target, not an incidental result of four-finger CCD.
4. Only after palm/root + thumb are credible should index/middle/ring/pinky close locally around the near/far vessel surface.
5. The support solver should preserve finger ordering and test self-intersection / silhouette, not only endpoint distance.

The pinch diagnosis is analogous: keep the successful bounded whole-limb tracking idea, but validate palm/root approach and hand plane around the lifted flap before accepting fingertip contact.

## Failed experiments / do not repeat

- v31 fixed-target support CCD: numeric pass, visible hanging claw.
- v31/v29 pinch: numeric pass, palm/root visually disconnected from flap.
- v32 transverse knuckle-derived vessel axis: numeric pass, visual regression and stronger structural intersection.
- Do not spend another loop changing only support-axis vectors, tolerance numbers, or adding more distal-finger rotation.

## Next exact action

1. Build a **whole-hand support staging fixture** against a fixed upright product-equivalent cup/bottle proxy.
2. Before finger CCD, rigidly align MPFB palm/root to a reference-derived grasp plane: palm beside vessel, wrist/forearm flowing toward the frame edge, thumb on the opposing side.
3. Add explicit Macro/Meso gates for palm-to-vessel clearance, thumb opposition, finger ordering and obvious self-intersection in addition to endpoint distance.
4. Render the same fixed camera before and after local finger closure.
5. Reject the candidate unless the thumbnail silhouette reads as a human hand wrapping a vessel.
6. Only after support passes, perform the analogous whole-hand approach-plane correction for label pinch.
7. Only after both isolated poses visually pass should a Godot staging scene be created.

No PR or merge into `main` is justified by v31/v32.
