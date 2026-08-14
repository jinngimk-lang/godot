# Peel Calm reference convergence checkpoint 05

Date: 2026-08-15
Production baseline: `main@769d6452e75112084f537af99be90721c2629cd5`
Production post-merge Godot Check: `31810098509` — PASS
Production runtime frame artifact: `9222768455` (`peel-calm-reference-frames`)
Acceptance set: `cafe_v1`, `bar_v1`, `market_v1`

## Repository hygiene

Obsolete open PRs #46 and #48 were explicitly marked superseded and closed. Both predate the clean multiscale integration that landed via PR #49 and must not be considered active merge candidates in future recovery passes.

## Stable visual diagnosis

R1/R2 remain the dominant gates. The current production nine-frame runtime matrix still shows an XR-style hand plus synthetic forearm, stock/claw-like support and peel choreography, and a visible anatomy discontinuity. Skin/PBR, paper fibers, glass micro-highlights, and other Micro work remain deferred.

## MPFB pose v9 — contact gap remains

Branch: `spike/mpfb-hero-limb-pose-v9`
Exact head: `998f389dd40731502d5e287c1f287f231192879a`
Godot Check: `31825791347` — PASS
MPFB preview: `31825791294` — PASS
Visual artifact: `9228870438`

v9 improved the continuous human limb and produced a recognisable support-wrap silhouette, but its peel pose solved only thumb rotations against a mostly fixed index pose. Best thumb/index tip gap remained roughly 21 mm. The unused fingers also retained a hanging/claw character.

Verdict: useful anatomy pipeline, pinch not accepted.

## MPFB pose v10 — metric success, visual reject

Branch: `spike/mpfb-hero-limb-pose-v10`
Exact head: `f910345aba09e602e215d4e1872a2c1e4f141e19`
Godot Check: `31826548071` — PASS
MPFB preview: `31826548087` — PASS
Visual artifact: `9229156439`

Hypothesis: solve index flexion and thumb opposition together instead of fixing the index.

Measured best result:

- thumb/index gap: `0.004035 m` (~4.0 mm);
- contact-anchor error: `0.075238 m` (~75 mm).

The numerical contact target passed, but the real previews were an obvious visual failure: index/thumb and the unused digits looped into extreme, self-evidently non-human arcs. The solver had learned to close the metric by moving the entire contact event far away and accumulating excessive joint flexion.

Verdict: **REJECT**. A distance-only pinch metric is insufficient.

## MPFB pose v11 — anatomy constraint exposes solver limitation

Branch: `spike/mpfb-hero-limb-pose-v11`
Exact head: `d22e58d503068e5a5ebb0992d8dd6c2b6d4ae595`
Godot Check: `31827121576` — PASS
MPFB preview: `31827121573` — expected gate FAIL
Visual artifact: `9229359174`

v11 constrained cumulative finger flexion, reduced the unused-finger curl, raised the contact-anchor penalty, and added an explicit CI gate requiring both <=10 mm fingertip gap and <=25 mm anchor error.

Measured best result:

- thumb/index gap: `0.068763 m` (~68.8 mm);
- contact-anchor error: `0.015138 m` (~15.1 mm).

This is a productive RED result. The preview is much more anatomically plausible than v10 and stays near the intended flap region, but the tips cannot meet under the bounded coordinate-descent pose model. The workflow correctly fails the contact gate while still uploading visual evidence.

## Falsified approach

Do not continue widening the per-joint coordinate-descent bounds. v10 proves that this can manufacture a small numerical gap through gross contortion; v11 proves that sensible bounds then cannot reach the required contact. More angle-search iterations are unlikely to address the structural control problem.

## Current ranked reds

### R1 — continuous realistic hand/wrist/forearm anatomy

MPFB remains promising and materially better than the XR hand + generated tube baseline, but it is still staging only.

### R2 — photographic vessel-wrap / label-flap contact

This is the immediate blocker. Support wrap is directionally useful; peel pinch still lacks a physically credible control method.

### R3 — gameplay-camera integration

Do not integrate the MPFB limb into Godot until the pose gate demonstrates a believable support wrap and pinch at fixed preview cameras.

### R4 — skin/nail PBR and other Micro detail

Remain deferred.

## Next exact action

Replace raw per-joint angle coordinate descent for the peel pose with a constraint/IK-based pose spike:

1. create two explicit flap contact targets separated by paper-scale thickness;
2. solve the index distal chain and thumb distal chain toward opposing targets using Blender armature constraints/IK or an equivalent target-driven rig method;
3. keep hand/wrist orientation and unused fingers under anatomical priors;
4. add hard gates for fingertip gap, contact midpoint error, and obvious target-region drift;
5. render the same fixed neutral/support/pinch cameras and visually reject self-intersection, inverted joints, loops, or claw silhouettes even when metrics pass;
6. only if the target-driven pose is visually credible should the extracted MPFB limbs proceed to Godot gameplay integration and café/bar/market runtime capture.

Do not spend the next iteration on Micro materials or return to XR subdivision/procedural tube forearms.
