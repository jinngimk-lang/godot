# Peel Calm reference convergence checkpoint 24

Date: 2026-08-15
Production main: `769d6452e75112084f537af99be90721c2629cd5`
Evidence branch: `spike/mpfb-hero-limb-evidence-v60`
Branch head when checkpoint was written: `d5033954a136fabbf12f9901b74ca601a146c58e`
Godot Check: run `31890242097` — PASS on `d5033954a136fabbf12f9901b74ca601a146c58e`
MPFB Evidence v60: run `31890242127` — IN PROGRESS when this checkpoint was written
Prior corrected-focus candidate: `spike/mpfb-hero-limb-artist-fk-v59@e004e2e9335ef2ea9dcb2579eb4e0963aa95dbb0`
Prior Godot Check: run `31888689445` — PASS
Prior MPFB Artist FK v59: run `31888689475` — PASS
Prior visual artifact: `9247975079`, digest `sha256:f939018b7c119868ddda98685d1ab0c08130a63d2bba408bbb6b1cdd77bb97b7`

## Locked target

`cafe_v1 / bar_v1 / market_v1` remain the acceptance reference family. R1 remains support-hand Macro/Meso enclosure: at thumbnail scale the support hand must immediately read as a human vessel wrap with an opposed thumb and progressively occluded fingers around the far contour. Micro skin/PBR, paper fibers, glass highlight breakup and condensation remain blocked behind R1/R2.

## Critical verification correction discovered after checkpoint 23

The v58 regression investigation found that earlier artist-pose previews could be invalidated after durable pose restore. `v49.load_pose(...)` correctly restored the 17 GameEngine pose matrices, but the preview/focus path could subsequently invoke legacy `v22._neutral_targets(arm)`. That helper clears MPFB pose bones. The result is a dangerous false visual verdict: the durable pose can be technically valid while the rendered evidence silently shows a neutralized hand.

`tools/test_mpfb_artist_pose_survives_focus_v58.py` now guards this exact failure by rejecting any `_neutral_targets(arm)` call after the durable load marker.

This means any previous visual rejection that depended on the affected post-reload focus path is not sufficient evidence by itself. The original artist-FK candidate must be judged again only from a corrected-focus render.

## v59 corrected-focus evidence

v59 reran the original fixed artist-FK authoring path with the focus-reset regression enabled. Its exact-head Godot Check and MPFB workflow both passed, and its report contract requires:

- staging-only candidate;
- not a production candidate;
- `camera_focus_preserves_pose == true`;
- 17 durable pose bones;
- save/load max matrix error <= `1e-6`.

The v59 images existed only inside an expiring GitHub Actions artifact. In the current connector/runtime that binary artifact was not reliably inspectable as a durable image source, so the visual verdict was intentionally left open rather than guessed.

## v60 evidence-persistence change

v60 changes the evidence boundary, not the production game and not the artist pose itself.

A branch-only workflow now:

1. enforces the pose-focus regression before rendering;
2. uses pinned Blender 4.2.0 and MPFB 2.0.17 with existing SHA-256 checks;
3. rebuilds the same GameEngine source human;
4. rerenders the same original v55 artist-FK candidate through the corrected focus path;
5. copies full-resolution and 192x108 thumbnail PNGs, report JSON, and thumbnail RGBHEX into `docs/superpowers/evidence/mpfb-v60/`;
6. commits that evidence back to the isolated v60 branch;
7. ignores bot-only evidence paths on subsequent pushes to avoid a workflow loop.

The purpose is to make the Macro/Meso visual evidence recoverable and directly inspectable in future loops instead of relying on a short-lived Actions artifact.

## Current verdict

Technical gate on the v60 branch: PASS so far (`Godot Check 31890242097`).

Visual gate: **PENDING** until the corrected-focus full + thumbnail evidence is committed and inspected. Do not infer PASS or REJECT from v55/v56 historical screenshots that may have been neutralized by the focus bug.

No production PR is open and production `main` remains unchanged.

## Highest-impact red

R1: determine whether the corrected-focus original artist-FK candidate actually produces a readable human vessel-wrap silhouette. This is now a verification/evidence problem before it is another pose-authoring problem.

R2: if R1 passes, prove the candidate in the real Godot café/bar/market product cameras against the current XR baseline.

R3: peel-hand thumb/index flap-pinching choreography.

## Next exact action

1. Resolve MPFB Evidence v60 run `31890242127`.
2. Confirm the branch moves to the bot evidence commit.
3. Inspect `docs/superpowers/evidence/mpfb-v60/support-wrap-thumbnail.png` first for Macro silhouette.
4. Inspect `support-wrap-full.png` for Meso thumb opposition, finger depth ordering, self-intersection and wrist/forearm flow.
5. REJECT immediately if it still reads as an open hand touching a vessel, parallel finger rays, claw, or absent thumb opposition.
6. If it passes Macro/Meso, stop staging-pose search and build a Godot product-camera comparison against the current XR hand; do not do Micro polish first.
7. If it fails, use the corrected image itself to drive genuinely visual Blender pose authoring. Do not return to CCD, endpoint chasing, shared-axis/per-joint procedural solvers, contact tolerance sweeps, or whole-hand orbit sweeps.
8. Run an independent Challenger only after a product-camera candidate demonstrates visible improvement.

## Do not repeat

- Do not treat green CI as visual acceptance.
- Do not use historical v55/v56 screenshots affected by the focus-reset ambiguity as final evidence.
- Do not create another procedural grasp-parameter sweep.
- Do not merge this evidence workflow or MPFB staging code into production merely because the evidence pipeline works.
- Do not start skin/material Micro work until the support-hand Macro/Meso gate is closed.
