# Peel Calm reference convergence checkpoint 59

Date: 2026-08-17

## Baseline recovered

- Main before this loop: `7078f48fd699dce00c7bfc9ec2ec559f34a15cf4`
- Fresh main Godot Check before the change: `31976236360` — PASS
- Baseline runtime artifact: `9271123406` (`peel-calm-reference-frames`)
- Locked acceptance family remains `cafe_v1 / bar_v1 / market_v1`; runtime captures remain evidence, never replacement references.

## Highest actionable red selected

R1 remains hero support-hand anatomy/enclosure, but the established stop condition still forbids more CCD, endpoint chasing, grip-number sweeps, local-axis searches, orbit/yaw/translation grids or other numerical hand-pose search until live/native-rig visual authoring is available.

The next independent Macro/Meso defect visible in all nine fresh main frames was the procedural forearm path: checkpoint 58 had successfully reduced radius/occupancy, but the centerline still read like a nearly straight beam with little wrist-to-forearm-to-exit tangent change.

Falsifiable hypothesis: keep radius, hand pose, camera, materials and gameplay frozen; increasing only the path curvature should reduce the beam-like low-frequency silhouette without regressing peel/inspect/crumple states.

## RED

Branch: `fix/forearm-path-curvature-v59`

RED head: `ca10b7fc64014a636f9c48cafab174fcf7d8b140`

Added a deterministic path-shape contract to `tests/smoke_forearm_presentation.gd`:

- forearm presentation must expose `_path_tangent_deflection_degrees()`;
- both left/right mirrored paths must produce at least `24°` start-to-end tangent deflection;
- all existing radius (`<= 0.21`), reach, material, hidden legacy sleeve/cuff and single-owner choreography gates remain unchanged.

Godot Check `31976849245` failed exactly at **Forearm presentation smoke** after import/parse, configured launch, unit tests, scene/reference/café/crumple/contents checks passed. This is the intended RED.

The old quadratic path measured about `12.27°` of tangent deflection.

## GREEN implementation

Candidate head: `afe175336b89b8345b2c15dd790796ed380a4d4c`

Changed only `scripts/presentation/forearm_presentation.gd` path geometry:

- replaced the single-control quadratic centerline with a two-control cubic Bézier;
- preserved the same general exit reach;
- introduced a short wrist/drop phase and a broader forearm/exit phase;
- new deterministic tangent deflection is about `39.09°`;
- checkpoint-58 radius profile is frozen exactly at `0.130 -> 0.200` with the same `0.030` mid bulge;
- authored-hand scale, support/peel root ownership, camera/FOV, labels, materials and gameplay remain unchanged.

Exact candidate Godot Check `31976890001` — PASS through Godot 4.7.1 import/launch, unit/smoke/reset/input isolation and fresh nine-frame capture.

Candidate artifact: `9271295312`
Digest: `sha256:1802c391342e8eaa1bfcbb602c94a848ef8ea491a19e578c043538229d847924`

## Real-frame comparison

Compared all nine candidate captures against baseline artifact `9271123406` at Macro first, then Meso.

Observed improvement:

- café base/partial/crumple: both arms now have a visible wrist drop and broader exit arc instead of reading as near-straight bars;
- bar base/partial/inspect: the same curved centerline survives venue material switching and inspection;
- market base/partial/inspect: centerline curvature remains visible while checkpoint-58 narrow occupancy is retained;
- no visible peel, inspect or café-crumple regression was found;
- no new hook, vessel intersection or runaway geometry appeared in the inspected frames.

This is a scoped R2 path improvement, **not** anatomical completion. The XR hands remain the dominant reference mismatch.

## Independent challenge

PR: #71 `fix: curve procedural forearm path`
PR exact head stayed `afe175336b89b8345b2c15dd790796ed380a4d4c`.

PR-triggered Godot Check `31976956554` — PASS.

Local independent Challenger round 1: run `31976980681` — PASS / `VERDICT: VERIFIED` on the exact candidate head.

Codex Challenger run `31976979649`:

- exact-head checkout and independent deterministic Godot verification succeeded;
- the Codex model step failed only because the configured OpenAI API account reported no credits remaining;
- no purchase/recharge was performed and this infrastructure failure was not counted as a product defect or as verification.

## Merge and fresh main proof

PR #71 was squash-merged with expected-head protection.

Merged production head: `a36687e52e1e0984cb82e4d3a2decc4d2acd73fd`

Fresh merged-main Godot Check: `31977239699` — PASS.

Fresh merged-main runtime artifact: `9271383599`
Digest: `sha256:454e8a4008684e9768879d4b26ad686c4cc35013b60ae64ea32c45e020043e01`

The merged-main nine frames were inspected again. The curved forearm benefit survives integration, while peel/inspect/crumple states remain coherent.

## Closed / improved reds

- **R2a — excessive forearm occupancy:** remains closed from checkpoint 58.
- **R2b — near-linear beam-like forearm centerline:** materially improved/closed as an independent procedural-path defect.

These do not mean the generated forearm is anatomically final.

## Remaining reds, ranked

### R1 — Hero support-hand anatomy / vessel enclosure

Still the largest visible mismatch. Current XR hands are faceted/open and do not reproduce the locked reference’s natural vessel wrap. Do not resume numerical pose search. Resume only when a true native-rig/live visual authoring path is available, or when a new evidence-backed asset route changes the capability boundary.

### R2 — Hand/wrist/forearm anatomical continuity

The procedural forearm is now slimmer and less beam-like, but it remains a generated bridge rather than a true continuous human limb. Do not start another radius or centerline parameter sweep; future progress should come from integrated limb assets/native-rig authoring.

### R3 — Peel-hand whole-hand pinch choreography

Capture truth is fixed and the hand reaches the real flap endpoint, but the entire hand pose still does not match the reference-quality pinch anatomy.

### R4 — Product/material Micro detail

Skin PBR, paper fibers, torn-edge microdetail, glass/liquid optics and condensation remain frozen while the higher-impact hand anatomy red persists.

## Do not repeat

- no forearm radius sweep;
- no cubic control-point grid/search after this accepted path correction;
- no CCD / endpoint chasing / contact servo for hero hand authoring;
- no master/finger grip-number sweeps;
- no hand orbit/yaw/translation grids;
- no Micro material polishing while R1 remains obvious.

## Next exact action

Start from fresh `main@a36687e52e1e0984cb82e4d3a2decc4d2acd73fd` and its artifact `9271383599`.

Re-rank the nine frames. If live Blender/native GameEngine rig authoring is still unavailable, choose the next **independent, objective Macro/Meso defect** that does not violate the R1 stop condition. Prefer a user-visible structural mismatch with a deterministic contract over another cosmetic or Micro pass. If live rig authoring becomes available, R1 immediately regains execution priority.
