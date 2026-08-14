# Peel Calm reference convergence checkpoint 06

Date: 2026-08-15
Production baseline: `main@769d6452e75112084f537af99be90721c2629cd5`
Production post-merge Godot Check: `31810098509` — PASS
Production runtime frame artifact: `9222768455` (`peel-calm-reference-frames`)
Acceptance set: `cafe_v1`, `bar_v1`, `market_v1`

## Current spike

Branch: `spike/mpfb-hero-limb-pose-v16`
Exact head before this checkpoint: `f9cc8e8a7366ee2c1b9921bf34571b696109af94`
Exact-head Godot Check: `31834815408` — PASS
MPFB v16 preview run: `31834815664` — expected visual/contact gate FAIL
MPFB v16 artifact: `9232146769`

Production `main` was not modified by the rejected pose experiments.

## Stable priority

R1 remains continuous realistic hand/wrist/forearm anatomy. MPFB is still the best anatomy candidate and is materially better than the XR hand + generated forearm baseline.

R2 remains photographic vessel-wrap and paper-flap contact. This is the immediate blocker before any Godot gameplay integration of MPFB limbs.

Micro skin, nail, paper-fiber, glass-highlight, condensation and HUD polish remain deferred while R1/R2 are unresolved.

## v13 — distal IK preserves base anatomy but stalls

Branch/head: `spike/mpfb-hero-limb-pose-v13@55e9f2331b5af52cb7bbc499deccbc4dab8ba2e3`
Preview run: `31828240015`
Artifact: `9229783056`

The restrained proximal thumb/index prior plus two-bone distal IK avoided some of v12's oversized C-thumb behavior, but the best distal bone-tail gap was `0.016406 m` (~16.4 mm), above the 12 mm gate. Real previews also retained obvious lateral/distal bending. Support-wrap coverage stayed around one third of the desired vessel contact.

Verdict: reject as production pose control.

## v14 — tighter generic IK constraints make contact worse

Branch/head: `spike/mpfb-hero-limb-pose-v14@7e00e6f1713a84255a281438b15e666f50138805`
Preview run: `31833741383`
Artifact: `9231777765`

Hypothesis: restore small proximal participation while bounding all IK joints to narrow anatomical envelopes and disabling stretch.

Measured best pinch gap: approximately `0.023445 m` (~23.4 mm), worse than v13's 16.4 mm. Support-wrap metrics were essentially unchanged.

Verdict: hypothesis falsified. Do not loosen the gate or keep tightening generic IK limits.

## v15 — empirical GameEngine hand-axis diagnostic

Branch/head: `spike/mpfb-hero-limb-pose-v15@acbd834b393b3328ce94d8dc0d8eebae0d99691d`
Diagnostic run: `31834616847` — PASS
Artifact: `9232015303`
Baseline restrained-prior distal bone-tail gap: `0.043160 m`.

The diagnostic perturbed thumb/index GameEngine bones by +/-10 degrees around each local axis and measured actual world-space fingertip motion. It proved a major earlier assumption wrong: index flexion that closes the pinch is not primarily the positive local-Z direction used by the old helper.

Strongest single-axis gap closers from the diagnostic:

- `thumb_02_r`, local Z `-10°`: gap delta `-0.0058196 m`;
- `thumb_01_r`, local Y `+10°`: `-0.0055230 m`;
- `thumb_01_r`, local Z `-10°`: `-0.0052102 m`;
- `thumb_01_r`, local X `+10°`: `-0.0047733 m`;
- `thumb_02_r`, local X `+10°`: `-0.0046869 m`;
- `thumb_03_r`, local Z `-10°`: `-0.0036048 m`;
- `index_01_r`, local X `-10°`: `-0.0035429 m`;
- `index_02_r`, local X `-10°`: `-0.0021169 m`.

This explains why v13/v14 could numerically approach contact while producing sideways/claw-like visible digit arcs: the assumed control axes/signs were not grounded in the imported GameEngine rig.

## v16 — measured-axis explicit pose still visually fails

Branch/head: `spike/mpfb-hero-limb-pose-v16@f9cc8e8a7366ee2c1b9921bf34571b696109af94`
Godot Check: `31834815408` — PASS
Preview run: `31834815664` — expected gate FAIL
Artifact: `9232146769`

v16 removed generic IK and searched only the v15 empirically useful axis/sign combinations within bounded ranges. This was a deliberately different control family, not a threshold relaxation.

Measured result:

- baseline gap: `0.043160 m`;
- best measured-axis candidate gap: about `0.022188 m` (~22.2 mm);
- contact-midpoint / anchor error: about `0.014817 m` (~14.8 mm).

The candidate reduced the baseline gap substantially and kept the contact region near the intended location, but it still failed the <=12 mm gate. More importantly, the real preview remained an obvious hanging/claw silhouette rather than the reference's photographic thumb-index paper pinch. Therefore the candidate is visually rejected even though the rig-axis diagnosis itself was useful.

## Newly falsified approach family

Do not continue iterating generic IK limits or direct bounded angle/axis coordinate search on MPFB solely to manufacture fingertip proximity. We now have multiple independent failures:

- v10: tiny numeric gap through gross contortion;
- v11: anatomy bounds prevent closure;
- v12: target-driven full-chain IK closes more but creates an oversized C-thumb;
- v13: restrained distal IK stalls at ~16.4 mm and bends laterally;
- v14: tighter anatomical IK worsens to ~23.4 mm;
- v16: empirically correct axes still produce ~22.2 mm and a claw-like silhouette.

The problem is now a pose-prior / retargeting problem, not an optimizer-iteration problem.

## Next exact action

Use the repository-local authored XR hand animations as semantic pose priors instead of solving a pose from scratch:

1. inspect `assets/models/hands/hand_left.glb` / `hand_right.glb` skeletons and the existing `Cup`, `Pinch Up`, and `Pinch Tight` animations;
2. derive a semantic bone map from XR thumb/index/middle/ring/little chains to the MPFB GameEngine hand bones;
3. retarget local rest-to-pose rotation deltas, not absolute world transforms, onto the continuous MPFB hand/wrist/forearm candidate;
4. preserve MPFB palm/wrist orientation and anatomy while importing only useful digit pose deltas;
5. render the same fixed cameras for support-wrap and paper-flap pinch;
6. keep hard contact-region, no-self-intersection and visual silhouette gates; do not accept a pose merely because a numeric gap is small;
7. only after retargeted MPFB support/pinch poses are visually credible should the limb enter Godot gameplay staging and the café/bar/market runtime frame matrix.

The XR assets are already repository-local and provenance-tracked, so this route reuses pose semantics without promoting their low-fidelity visible mesh.
