# Peel Calm reference convergence checkpoint 07

Date: 2026-08-15
Production baseline: `main@769d6452e75112084f537af99be90721c2629cd5`
Production post-merge Godot Check: `31810098509` — PASS
Production runtime frame artifact: `9222768455` (`peel-calm-reference-frames`)
Acceptance set: `cafe_v1`, `bar_v1`, `market_v1`

## Stable priority

R1 remains continuous realistic hand/wrist/forearm anatomy. MPFB remains materially better anatomy than the current XR hand plus generated forearm baseline.

R2 remains photographic vessel-wrap and paper-flap contact. This is still the blocker before any MPFB limb enters Godot gameplay staging.

Micro skin/nail, paper fiber, glass highlight, condensation and HUD polish remain deferred while R1/R2 are unresolved.

## v18 — semantic rest-to-pose retarget without metacarpals

Branch/head: `spike/mpfb-hero-limb-retarget-v18@454b61fb9c940138ac99d8cc7d2d2c5a3bfdab09`
Godot Check: `31835812277` — PASS
MPFB preview run: `31835812260` — PASS as an experiment runner
Artifact: `9232522156` (`mpfb-hero-limb-retarget-v18`)

Hypothesis: repository-local XR `Cup`, `Pinch Up`, and `Pinch Tight` animations can serve as semantic priors if their local Default-pose -> target-pose rotation deltas are rest-frame aligned onto MPFB GameEngine proximal/intermediate/distal digit chains.

Implementation deliberately hid the XR visible mesh and rendered only continuous MPFB anatomy. No absolute world transforms and no generic IK were used.

Measured result:

- `Pinch Up` thumb/index tip gap: approximately `0.095565 m` (~95.6 mm).
- `Pinch Tight` thumb/index tip gap: approximately `0.095565 m` (~95.6 mm).
- Support radial errors: approximately `[1.8, 27.1, 18.4, 19.8] mm`.

Real-frame verdict:

- MPFB continuous hand/wrist/forearm anatomy was preserved.
- `Cup` remained a hanging/claw-like pose rather than a photographic vessel wrap.
- The paper proxy was not between thumb and index in either pinch pose.
- Identical ~95.6 mm pinch gaps proved that proximal/intermediate/distal-only transfer was missing essential base opposition/spread semantics.

Verdict: reject v18 for gameplay integration.

## v19 — fold XR metacarpal/base deltas into MPFB proximal joints

Branch/head: `spike/mpfb-hero-limb-retarget-v19@1025f1c07ce0da22ac74b8c3725c199d7b46ca8b`
Godot Check: `31836348071` — PASS
MPFB preview run: `31836347931` — PASS as an experiment runner
Artifact: `9232701788` (`mpfb-hero-limb-retarget-v19`)

Hypothesis: the missing XR digit metacarpal/base channels contain important spread/opposition semantics. Because the extracted MPFB GameEngine rig has no one-to-one digit metacarpal deform bone, fold each XR metacarpal delta into the corresponding MPFB proximal joint before applying the XR proximal delta. For the thumb, fold `Thumb_Metacarpal_R` plus `Thumb_Proximal_R` into `thumb_01_r`; keep the v18 half/half split of XR distal delta across `thumb_02_r` and `thumb_03_r`.

The experiment proved that the omitted base channels are meaningful:

- `Thumb_Metacarpal_R` Default -> Cup delta: approximately `50.622°`.
- `Thumb_Metacarpal_R` Default -> Pinch Up delta: `30°`.
- `Thumb_Metacarpal_R` Default -> Pinch Tight delta: `30°`.
- Other digit metacarpal deltas were approximately `5°` for these actions.

Measured result:

- `Pinch Up` gap improved from ~95.6 mm to `0.059300 m` (~59.3 mm).
- `Pinch Tight` gap improved from ~95.6 mm to `0.059300 m` (~59.3 mm).
- Support radial errors: approximately `[1.2, 27.9, 18.1, 20.7] mm`.

Real-frame verdict:

- Thumb opposition visibly improved relative to v18.
- The pose is still a hanging/claw silhouette, not the approved photographic paper pinch.
- Paper proxy remains displaced from true thumb/index opposition.
- Support hand still does not read as a natural palm-driven wrap around the vessel.

Verdict: the metacarpal hypothesis is **partially confirmed**, but v19 is still rejected for gameplay integration.

## Newly narrowed problem

Do not return to generic IK, coordinate angle search, or threshold relaxation. The useful evidence now isolates the mapping ambiguity primarily to the XR thumb chain versus MPFB GameEngine thumb chain:

- XR semantic source has `Thumb_Metacarpal_R`, `Thumb_Proximal_R`, `Thumb_Distal_R`.
- MPFB target has `thumb_01_r`, `thumb_02_r`, `thumb_03_r`.
- v19 folds base + proximal into `thumb_01_r` but splits the XR distal rotation half/half over `thumb_02_r` / `thumb_03_r`.
- That split is an unverified assumption and may be under-driving distal thumb flexion/opposition.

The fact that v19 reduced the pinch gap by ~36 mm without anatomy collapse shows semantic retargeting remains more promising than the rejected optimizer family, but it is not yet visually acceptable.

## Next exact action

Create a bounded thumb-chain mapping experiment, not an optimizer:

1. preserve v19 finger/metacarpal retarget exactly;
2. render several anatomically interpretable XR-distal -> MPFB-thumb distributions under identical fixed camera/light/proxy conditions, for example:
   - half/half (v19 baseline),
   - full distal delta on `thumb_02_r` only,
   - full distal delta on both `thumb_02_r` and `thumb_03_r`,
   - two-thirds / one-third split;
3. report thumb/index gap and contact midpoint for every variant;
4. visually reject any variant that closes numerically by looping, crossing, or producing a claw silhouette;
5. if none produce a photographic pinch, stop rotational delta remapping and escalate to a pose-transfer method that matches normalized source digit segment directions / landmarks while preserving MPFB joint limits;
6. do not integrate MPFB into Godot gameplay until both a natural support wrap and paper pinch pass the fixed-camera Macro/Meso visual gate.

Production `main` remains unchanged by v18/v19; all work is isolated model-pipeline evidence.
