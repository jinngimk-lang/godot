# Peel Calm reference convergence checkpoint 30

Date: 2026-08-16
Production baseline: `main@769d6452e75112084f537af99be90721c2629cd5`
Acceptance set: `cafe_v1`, `bar_v1`, `market_v1` (LOCKED)
Active staging branch: `spike/mpfb-hero-limb-thumb-abduction-v67`
Authored candidate head: `dba20f10fd89a58e9efff04fa4c70823d306a781`
Evidence bot head: `9cd9add4436e844556b0ea26afdfc15ae57d4eaa`

## Exact-head verification

- Godot Check: run `31902019582` — PASS
- Godot runtime frame artifact: `peel-calm-reference-frames`, id `9251342390`
- MPFB Thumb Abduction v67: run `31902019507` — PASS
- MPFB artifact: `mpfb-thumb-abduction-v67`, id `9251366263`

## Controlled change

v67 returns to pristine v65-B rather than stacking on rejected v66. Wrist, palm, vessel, camera, crop, original thumb curl, and all four non-thumb finger chains are frozen. The only authored change is a fixed 28° thumb-root abduction about the palm normal. A +/-4° probe is used solely to choose the sign that increases thumb/index web-space; magnitude is not swept.

## Frames inspected

Persisted under `docs/superpowers/evidence/mpfb-v67/` and redundantly in artifact `9251366263`:

- `support-wrap-with-vessel.png`
- `support-wrap-thumbnail.png`
- `anatomy-oblique.png`
- `anatomy-thumbnail.png`
- `thumb-abduction-v67.json`

## Visual verdict — REJECT v67 correction, RETAIN v65-B structural seed

### Macro

**NO MEANINGFUL IMPROVEMENT.** The 192x108 silhouette still reads almost identically to v65-B/v66. The whole hand continues to read as a grip, but the thumb is not independently legible as the opposing element.

### Meso

**FAIL.** The full and unobstructed anatomy views show that abduction around the current palm-normal frame still leaves the thumb visually merged with the index-side digit mass. The change is real in pose space but not useful in the locked perceptual space.

The diagnostic thumb radial dot becomes about `-0.896`, compared with about `-0.470` in pristine v65-B and `+0.364` in v66. v66 and v67 therefore move the thumb strongly to opposite radial sides while producing almost the same inadequate visual read. This is decisive evidence that another scalar thumb-angle adjustment is not the right abstraction.

### Micro

Not evaluated.

## What this proves

1. v65-B remains the strongest whole-hand structural seed from v65-v67.
2. Both tested scalar thumb corrections are falsified:
   - more opposition/curl toward the vessel (v66);
   - more palm-plane abduction/web-space (v67).
3. Numerical thumb-axis tuning can move the skeleton substantially without improving the actual thumbnail. Stop this family now.
4. The remaining support-hand problem needs **direct visual thumb-chain authoring in the target camera/silhouette**, not another one-dimensional angle adjustment.
5. Production `main` remains clean and unchanged.

## Current reds

### R1 — Direct visual thumb-chain pose on v65-B support grip

Freeze the v65-B wrist/palm/four-finger support grip and author the three thumb bones as a coherent visible chain against a real vertical bottle/cup proxy. The thumb must read as one continuous opposing digit in the same image where the fingers enclose the vessel.

This should be authored from the rendered silhouette (or Blender pose view) and then persisted as a same-rig pose, not derived from another scalar angle sweep.

### R2 — Product-camera proof

Blocked until the support-grip thumb chain passes Macro/Meso. Then stop pose research and stage the candidate in real café/bar/market product FOV against the XR baseline.

### R3 — Peel-hand flap pinch

Still behind R1/R2.

### R4+ — Micro

Skin/PBR, paper fiber, glass highlight breakup, condensation and other Micro work remain frozen.

## Failed / do not repeat

Do not repeat:

- v64 wine-glass source pose;
- CCD or endpoint chasing;
- whole-hand orbit searches;
- crop/vertex-count tuning as pose fixes;
- v66 stronger thumb opposition/curl;
- v67 scalar thumb-root abduction;
- any additional single-axis thumb magnitude sweep.

## Next exact action

Create the next staging spike from pristine v65-B:

1. preserve the exact B wrist, palm, vessel and index/middle/ring/pinky chains;
2. use a vertical bottle-sized proxy and target-camera visual feedback;
3. pose thumb root/proximal/distal together as one coherent artist-authored chain, with no scalar sweep;
4. persist the resulting same-rig matrices/pose asset;
5. render with-vessel 192x108 plus unobstructed oblique evidence;
6. accept only if the thumb is immediately readable as the opposing digit and anatomy is continuous;
7. if accepted, move directly to Godot product-camera staging and independent Challenger rather than continuing hand-pose research.

Production `main` remains untouched.
