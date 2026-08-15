# Peel Calm reference convergence checkpoint 31

Date: 2026-08-16
Production baseline: `main@769d6452e75112084f537af99be90721c2629cd5`
Staging branch: `spike/mpfb-hero-limb-thumb-abduction-v67`
Checkpoint branch head before this document: `0060f0335ce0906a0658fa2f394f8c319e5aa366`
Locked acceptance set: `art/acceptance_refs/v1` (`cafe_v1`, `bar_v1`, `market_v1`)
Open product PRs: none

## Current highest-impact red

**R1 — reference-derived support-hand silhouette, specifically an independently legible opposing thumb.**

`v65-B` remains the first MPFB staging seed whose 192x108 image reads as a hand gripping a vertical cylinder, but the thumb still does not read as a distinct opposing digit. Product-camera integration remains blocked until this Macro/Meso gate is closed.

## v68 — coherent three-bone thumb chain

Hypothesis: the earlier v66/v67 failures came from manipulating one thumb angle at a time; authoring root/proximal/distal together as a single visible chain would create the missing opposition silhouette.

- Code/head for the exact candidate: `b7b33b0819651e478f4c43e4240ee00bf6fc9fc5`
- Godot Check: run `31904461731` — PASS.
- MPFB Thumb Chain v68: run `31904461799`.
  - Blender/MPFB install: PASS.
  - render: PASS.
  - authoring-boundary checks: PASS.
  - redundant artifact upload: PASS, artifact `9251990005`.
  - workflow overall result was FAILURE only because the Git evidence-persist push raced another branch update; this is not a model/render failure.

Visual verdict: **REJECT.** The frozen v65-B four-finger grasp still reads as gripping, but the new thumb collapses into a short palm-side curled mass. The unobstructed oblique view also lacks a long, clear opposing digit.

## v69 — one longer direct-visual thumb arc

Hypothesis: the v68 abstraction was useful but its landmarks compressed thumb arc length. Keep wrist/palm/vessel/four fingers/camera/crop exactly frozen and make one structural correction: a longer visible root→proximal→distal opposition arc.

- Exact candidate head: `61971558abaa9c636da9b2aba7ad63a60ab031b6`
- Godot Check: run `31904717050` — PASS.
- MPFB Thumb Arc v69: run `31904716926` — PASS.
- Visual artifact: `9252052758`.
- Evidence persisted successfully to `docs/superpowers/evidence/mpfb-v69/`.

Visual verdict: **REJECT.** Full, oblique and 192x108 renders remain nearly the same silhouette as v68; the thumb is still not independently legible as the opposing digit.

Important diagnostic observation: v68→v69 produced large changes in thumb pose matrices, but the rendered anatomy changed only slightly. This made further blind thumb-landmark authoring unjustified until bone-to-skin deformation was measured directly.

## v70 — thumb skeleton-to-skin response diagnostic

This is diagnostic-only, not a new pose candidate.

First run `31904979527` failed because MPFB's `Hide helpers` modifier changes evaluated topology from 19,158 source vertices to 13,380, so original vertex weights could not be indexed against the evaluated mesh. That failure was a measurement-method defect, not a rig/product defect.

The diagnostic was fixed to temporarily disable non-Armature modifiers only while measuring indexed deformation; the real Armature modifier remains active and all modifier states are restored afterward.

- Fixed exact head: `a31fc96c57c21a88dddd04486c82e70948d92df3`
- Godot Check: run `31905090467` — PASS.
- Exact-head Godot runtime frame artifact: `9252120212` (`peel-calm-reference-frames`).
- MPFB Thumb Skin Diagnostic v70: run `31905090464` — PASS.
- Diagnostic evidence persisted to `docs/superpowers/evidence/mpfb-v70/thumb-skin-v70.json`.

Measured result from pristine v65-B to the exact rejected v69 thumb arc:

- source mesh: 19,158 vertices;
- thumb vertex groups with weight > 0.01:
  - `finger1-1.R`: 99 vertices;
  - `finger1-2.R`: 191 vertices;
  - `finger1-3.R`: 142 vertices;
- thumb-bone motion reaches about 26–64 mm;
- 224 vertices with combined thumb weight >= 0.5 move **47.0 mm mean**, **64.3 mm p95**, **72.8 mm max**;
- 216 vertices with thumb weight >= 0.75 move **48.2 mm mean**, **64.3 mm p95**;
- 18,878 non-thumb vertices (<0.01 thumb weight) have effectively zero median/p95 motion; mean movement is ~`8.5e-8 m`.

### v70 conclusion

**The canonical MPFB thumb bones correctly drive the visible skin.** The persistent visual failure is not missing weights, wrong bone mapping, or a non-responsive mesh. The remaining R1 cause is pose silhouette / occlusion / camera-space relationship to the vessel.

This closes the skin-weight/bone-mapping suspicion and prevents an unnecessary rig-reweighting detour.

## Do not repeat

- CCD / endpoint chasing / contact servo / fingertip-distance optimization.
- shared-axis or per-joint procedural angle sweeps.
- whole-hand orbit sweeps.
- wine-glass source pose as a production grasp.
- scalar thumb root/opposition/abduction sweeps (v66/v67).
- generic world-space thumb landmark adjustments without a camera-space silhouette target (v68/v69).
- thumb skin-weight or bone-mapping investigation unless a new import path provides contradictory evidence; v70 demonstrates the canonical mesh responds strongly and selectively.

## Remaining reds

1. **R1 — support grasp camera-space silhouette:** thumb must be a separately readable opposing digit while the four frozen v65-B fingers enclose the vessel.
2. **R2 — product-camera proof:** once R1 passes staging, test the candidate in the real café/bar/market Godot camera/FOV against current XR baseline and locked references.
3. **R3 — peel-hand pinch:** build a separate thumb/index flap-contact pose after support-hand replacement is proven.
4. **R4+ Micro remains frozen:** skin PBR, paper fibers, glass micro-highlights/condensation, etc. do not outrank R1–R3.

## Next exact action

Change abstraction again; do **not** author v71 as another 3D thumb-angle/landmark guess.

1. Freeze pristine v65-B wrist, palm, vessel, four non-thumb finger chains, camera and crop.
2. Use the locked `bar_v1` / `market_v1` support-hand reference intent to define a **camera-space thumb silhouette gate** at thumbnail scale.
3. Produce an ID/mask diagnostic that makes current thumb-influenced skin visible as a separate region against the vessel/palm and records projected thumb root/tip plus vessel contour.
4. Define the required visible opposition in screen-space terms: the thumb must produce a distinct contour/region on the near/opposing side rather than disappearing into the palm or vessel.
5. Only after that target exists, author one same-rig pose to hit the visible camera-space silhouette; no generic 3D angle sweep.
6. If the 192x108 with-vessel view and unobstructed oblique both pass, stop pose research immediately and enter Godot product-camera staging + exact-head runtime comparison + independent Challenger.

Production `main` remains untouched by all v68–v70 staging work.