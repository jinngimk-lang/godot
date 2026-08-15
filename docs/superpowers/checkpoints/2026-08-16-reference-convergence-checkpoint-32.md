# Peel Calm reference convergence checkpoint 32

Date: 2026-08-16
Production baseline: `main@769d6452e75112084f537af99be90721c2629cd5`
Staging branch: `spike/mpfb-hero-limb-finger-silhouette-v75`
Exact staging code/workflow head: `406b21bfbb145866d0b66ec152141b2ecbcec6a3`
Evidence-persist branch head before this checkpoint: `c166ddcd1ac304c26c15a58a54a4fc4b42d18284`
Locked acceptance set: `art/acceptance_refs/v1` (`bar_v1`, `market_v1` for this support-grasp loop; `cafe_v1` remains locked but is not the bottle-grasp target)
Open product PRs: none

## Current highest-impact red

**R1 — whole support-hand vessel enclosure / progressive non-thumb digit ordering.**

The v74 camera-space thumb change successfully made the distal thumb visibly emerge past the vessel contour, but direct visual review still reads the hand as a fist-like near-side mass plus an extended thumb, not the natural bottle-support wrap required by `bar_v1` / `market_v1`.

The v75 diagnostic changes the diagnosis: the remaining Macro/Meso problem is not one hidden thumb segment or one hidden finger. The four non-thumb chains themselves do not form a coherent ordered enclosure around the vessel.

## v74 — thumb screen-space legibility improved, whole grasp still rejected

- Persisted evidence branch: `spike/mpfb-thumb-distal-screen-v74@34d73054f7cbd861c8f66495f43d136da1eed80b`.
- Exact candidate code head: `582508d4b6193ab9d4e541909537da6e43f159d9`.
- Godot Check: run `31909177685` — PASS.
- MPFB Thumb Distal Screen v74: run `31909177727` — PASS.
- Artifact: `9253207839`.
- Candidate distal thumb skin extends about `12.05 px` beyond the vessel projected contour at 192×108, versus `0 px` at the pristine v65-B baseline.
- Thumb root/thenar remained frozen within the structural gate; only `finger1-2.R` and `finger1-3.R` were authored.

### v74 visual verdict

**REJECT as a support-hand pose.** The thumb is now independently visible, but the whole hand reads as a clenched/fist-like mass with a side-extended thumb. This is not the reference intent of a relaxed but firm human bottle wrap.

This means thumb visibility is necessary but not sufficient. Do not continue distal-thumb angle/landmark tuning in isolation.

## v75 — four-finger ID / camera-space enclosure diagnostic

Purpose: freeze the exact v74 thumb and the v65-B index/middle/ring/pinky pose, then expose the four non-thumb chains as independent colored skin regions before any further authoring.

- Exact code/workflow head: `406b21bfbb145866d0b66ec152141b2ecbcec6a3`.
- Godot Check: run `31909550064` — PASS.
- MPFB Finger Silhouette v75: run `31909550051` — PASS.
- Artifact: `9253309974`.
- Evidence persisted by bot commit `c166ddcd1ac304c26c15a58a54a4fc4b42d18284` under `docs/superpowers/evidence/mpfb-v75/`.
- v75 authored **no** new pose parameters: no CCD, endpoint optimizer, contact servo, parameter sweep, root/camera/vessel motion, or digit 2–5 change.

### v75 projected high-weight digit metrics at 192×108

Projected vessel x-band: approximately `[76.56, 146.96] px`, diameter `70.40 px`.

- **Index**: bbox x `[109.38, 151.38]`, `96.49%` of high-weight vertices remain inside the vessel x-band, only `4.42 px` reaches right of the vessel.
- **Middle**: bbox x `[85.22, 122.30]`, `100%` inside the vessel x-band.
- **Ring**: bbox x `[64.40, 97.90]`, `86.77%` inside, with `12.16 px` left of the vessel.
- **Pinky**: bbox x `[49.63, 100.20]`, only `42.72%` inside, extending `26.93 px` left of the vessel.
- v74 thumb distal reproduction remains about `12.05 px` outside the vessel contour.

### v75 visual verdict

The diagnostic views make the structural problem explicit:

- index remains a forward/right protrusion beneath the thumb;
- middle curls into the near-side mass rather than reading as a clean far-side wrap;
- ring/pinky collapse unevenly left/down instead of forming a natural progressive set of fingertips around the vessel;
- the four digits do not create the reference-like hierarchy of index lighter, middle/ring/pinky progressively closing around the far side;
- thumbnail silhouette still reads as a compact fist-like clump on the vessel rather than an anatomically relaxed support grip.

Therefore **R1 is now redefined from “visible opposing thumb” to “whole non-thumb enclosure + progressive digit ordering while retaining the now-visible opposing thumb.”**

## What this closes

- Do not re-open MPFB thumb skin-weight / bone-mapping investigation; v70 already proved selective deformation.
- Do not continue thumb-only screen-space authoring after v74; the next dominant defect is the non-thumb enclosure.
- Do not treat fingertip/contact or simple inside/outside-vessel metrics as a visual pass. v75 is diagnostic evidence, not a production gate.

## Do not repeat

- CCD / endpoint chasing / contact servo / fingertip-distance minimization.
- shared-axis/per-joint scalar angle sweeps.
- whole-hand orbit sweeps.
- wine-glass source pose as production support grip.
- isolated scalar thumb sweeps or generic thumb 3D landmark guessing.
- another thumb-only v75/v76 adjustment while the four-finger enclosure remains fist-like.
- Micro skin/PBR/paper/glass polish before support-grasp Macro/Meso is accepted.

## Remaining reds

1. **R1 — reference-derived whole support grasp:** preserve v74's separately readable thumb, but re-author index/middle/ring/pinky together as a coherent progressive wrap around the real bottle proxy. The result must read as a human support grip at thumbnail scale, not a fist/claw.
2. **R2 — product-camera proof:** once R1 passes fixed staging thumbnail + unobstructed anatomy, integrate only as staging in the real Godot café/bar/market camera/FOV and compare against the current XR baseline and locked references.
3. **R3 — peel-hand pinch:** build a separate thumb/index flap-contact pose only after support-hand replacement is proven.
4. **R4+ Micro frozen:** skin PBR, paper fibers, glass micro-highlights, condensation and other fine detail remain lower priority.

## Next exact action

Change abstraction again; do not run a new broad angle sweep.

1. Freeze the v74 thumb, wrist/forearm, vessel, camera, crop and overall palm placement.
2. Use `bar_v1` / `market_v1` reference intent plus v75 digit-ID evidence to define one **reference-derived screen-space finger ordering** for index→middle→ring→pinky.
3. Author one same-rig four-finger pose in which the index remains the least closed and the middle/ring/pinky progressively wrap toward/behind the vessel's far contour; avoid all-finger equal curl.
4. Persist the 17-bone same-rig pose and render: with-vessel 192×108, full with-vessel, unobstructed oblique and unobstructed thumbnail.
5. Macro gate: at 192×108 the hand must read immediately as a natural bottle-support wrap with thumb and fingers on opposing sides, not a fist, claw, or flat fan.
6. Meso gate: unobstructed view must preserve continuous wrist/palm anatomy, distinct finger ordering, no major self-intersection or kink, and credible thumb web space.
7. If that single authored candidate fails, do not resume parameter search; move to direct interactive/artist posing on the native GameEngine rig using the same screen-space target.
8. If it passes, stop pose research immediately and enter Godot product-camera staging + exact-head runtime comparison + independent Challenger.

Production `main` remains untouched by v74/v75 staging work.