# Peel Calm reference convergence checkpoint 25

Date: 2026-08-16
Branch: `spike/mpfb-hero-limb-evidence-v60`
Production baseline: `main@769d6452e75112084f537af99be90721c2629cd5`
Open production PRs: none

## Exact evidence chain

- v60 evidence workflow original run `31890242127`: FAILED in the combined build/rerender step, but redundant artifact `9248366037` preserved the render and logs.
- Root cause was infrastructure-only: `.github/workflows/mpfb-evidence-v60.yml` invoked `tools/export_render_rgbhex.py` with system `python` even though the script imports Blender `bpy`, and it omitted the required width/height arguments.
- Minimal infrastructure fix commit: `bb00c0b20f298798e759b734ff0a29cb0c34db44`.
- Exact-head Godot Check for that fix: run `31894516708` — PASS.
- Corrected v60 evidence workflow: run `31894516737` — PASS.
- Corrected redundant artifact: `9249444818`.
- Workflow persisted the corrected-focus evidence back to Git in bot commit `2cbe2281d84a6db345ed3ceccc07c03b95531ad3`.
- Persisted evidence paths:
  - `docs/superpowers/evidence/mpfb-v60/support-wrap-full.png`
  - `docs/superpowers/evidence/mpfb-v60/support-wrap-thumbnail.png`
  - `docs/superpowers/evidence/mpfb-v60/support-wrap-report.json`
  - `docs/superpowers/evidence/mpfb-v60/support-wrap-thumbnail.rgbhex`

## Visual verdict — corrected-focus artist FK is REJECTED

The v58/v59 pose-focus regression fix proved that the current camera-focus path preserves the loaded 17-bone pose. Therefore the corrected v60 render is valid evidence rather than a neutral-pose false negative.

The full render and 192×108 thumbnail both fail the Macro/Meso support-hand gate:

- several finger chains exhibit severe kinked / wrong-axis deformation;
- multiple phalanges read as broken or folded rather than smoothly flexed;
- the fingers do not progressively disappear behind the far vessel contour;
- thumb opposition is not a clean, readable counter-grip;
- at thumbnail scale the silhouette does not immediately read as a natural human vessel wrap.

The persisted report confirms this was the intended fixed 17-bone candidate and not an optimizer side effect:

- `camera_focus_preserves_pose: true`;
- `pose_bone_count: 17`;
- `max_reload_matrix_error: 1.7881393432617188e-07`;
- `automatic_retarget: false`;
- `target_solver_used: false`;
- `production_candidate: false`.

## Closed uncertainty

Historical concern that artist-FK failures may have been caused only by camera focus resetting the pose is now closed. Corrected-focus evidence still fails visually.

The v55-style fixed local Euler pose must not be promoted to Godot gameplay or used as a production candidate.

## Do not repeat

Do not return to:

- CCD / endpoint chasing;
- contact-distance servo;
- shared or per-joint axis sweeps;
- whole-hand orbit-angle sweeps;
- blind local-Euler tables;
- merely increasing curl values;
- source-direction-only transfer;
- direct destructive BVH import into the production GameEngine rig;
- judging a pose by numerical contact error without thumbnail/full-frame evidence.

## Current reds

### R1 — natural support-hand pose on the continuous MPFB limb

Highest priority. The continuous hand-wrist-forearm asset pipeline is technically viable, but the current authored pose is not anatomically credible.

### R2 — product-camera proof

Blocked on R1. Once a support pose passes the fixed staging thumbnail, compare it against the current XR baseline in actual café/bar/market Godot cameras.

### R3 — peel-hand pinch

Blocked behind support-hand anatomy so the project does not split effort across two unsolved hero poses.

### R4+ — skin / paper / glass microdetail

Still frozen while R1/R2 remain Macro/Meso reds.

## Next exact action

Change the abstraction rather than tune another Euler table.

Build a same-rig visual pose-authoring path where the GameEngine hero rig is posed from a reliable anatomical pose representation and assessed directly in the fixed staging camera. The next candidate must preserve the target rig's edit-bone roll/rest structure and the v49 durable 17-bone partial-pose format. Prefer a non-destructive visual/retarget approach that operates on target-rig pose transforms with explicit swing/twist or an artist-authored Blender pose asset; do not copy source BVH edit-bone roll into the production rig.

Acceptance remains visual first:

1. 192×108 thumbnail immediately reads as a human vessel wrap.
2. Palm sits beside/partly around the vessel instead of merely touching it.
3. Index→pinky chains curve naturally and progressively disappear behind the far contour.
4. Thumb visibly opposes the fingers from the other side.
5. No obvious finger-chain kinks, self-intersection, or broken-joint silhouettes.
6. Only after this passes, enter Godot product-camera staging and independent Challenger.
