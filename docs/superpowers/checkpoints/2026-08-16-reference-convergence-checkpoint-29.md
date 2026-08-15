# Peel Calm reference convergence checkpoint 29

Date: 2026-08-16
Production baseline: `main@769d6452e75112084f537af99be90721c2629cd5`
Acceptance set: `cafe_v1`, `bar_v1`, `market_v1` (LOCKED)
Active staging branch: `spike/mpfb-hero-limb-thumb-opposition-v66`
Authored candidate head: `3dc8c553c046b4480327a40c20374db4e3b197af`
Evidence bot head: `9e06a3ed11fc4e32e418831320bbc6feb1bf7823`

## Exact-head verification

- Godot Check: run `31901750238` — PASS
- Godot runtime frame artifact: `peel-calm-reference-frames`, id `9251273848`
- MPFB Thumb Opposition v66: run `31901750239` — PASS
- MPFB artifact: `mpfb-thumb-opposition-v66`, id `9251305060`

## Controlled change

v66 freezes the v65-B palm sign, wrist/palm placement, vessel relationship, camera, crop and all four non-thumb finger chains. It changes only the thumb chain by adding 24° root opposition plus 10°/6° proximal/distal curl. No CCD, endpoint optimizer, orbit search, contact-tolerance search or parameter sweep is used.

## Frames inspected

Persisted under `docs/superpowers/evidence/mpfb-v66/` and redundantly in artifact `9251305060`:

- `support-wrap-with-vessel.png`
- `support-wrap-thumbnail.png`
- `anatomy-oblique.png`
- `anatomy-thumbnail.png`
- `thumb-opposition-v66.json`

## Visual verdict — REJECT v66 thumb correction, KEEP v65-B as structural seed

### Macro

**NO MEANINGFUL IMPROVEMENT.** The 192x108 image remains almost perceptually identical to v65-B: the whole hand still reads as a grip, but the thumb is not separately readable as the opposing element.

### Meso

**FAIL.** The full and unobstructed oblique images show the thumb still visually bunched close to the index-side digit mass. Increasing opposition/curl toward the vessel did not create the web-space separation seen in the locked bar/market references.

The diagnostic thumb radial dot moved from about `-0.47` in v65-B to `+0.36` in v66. This proves the extra rotation materially moved the thumb across the palm radial plane, yet the visual evidence did not improve. Therefore the remaining defect is not simply insufficient curl/opposition magnitude.

### Micro

Not evaluated.

## What this proves

1. v65-B remains the best structural seed from the current native-canonical path.
2. More thumb curl toward the vessel is the wrong next abstraction.
3. The next thumb problem is **abduction / web-space separation**: the thumb must visibly separate from the index chain while staying on the opposing near/upper vessel side.
4. Do not increase the same opposition/curl angles again and do not reopen general finger/palm/camera searches.

## Current reds

### R1 — Thumb web-space / abduction on frozen v65-B grasp

Freeze v65-B exactly and change only thumb-root abduction within the palm plane. The acceptance signal is visual: thumb becomes independently readable at thumbnail scale without opening the four-finger support grip or causing intersection.

### R2 — Product-camera proof

Still blocked until R1 passes. Then stop pose-search work and stage against real café/bar/market FOV.

### R3 — Peel-hand flap pinch

Still behind support-hand R1/R2.

### R4+ — Micro

Still frozen.

## Next exact action

Create one v67 candidate from pristine v65-B (not from v66):

1. retain the original v65-B thumb curl/opposition;
2. apply one fixed thumb-root abduction about the palm normal;
3. choose only the abduction sign needed to increase thumb/index web-space; do not sweep magnitude;
4. keep wrist, palm, vessel, four-finger chains, crop and camera unchanged;
5. rerender the same thumbnail and oblique evidence;
6. if thumb becomes clearly opposing and anatomy remains clean, proceed to product-camera proof; otherwise stop numerical thumb tuning and move to direct visual pose authoring of the thumb chain.

Production `main` remains untouched.
