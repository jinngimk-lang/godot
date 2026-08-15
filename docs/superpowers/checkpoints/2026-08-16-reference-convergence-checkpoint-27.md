# Peel Calm reference convergence checkpoint 27

Date: 2026-08-16
Production baseline: `main@769d6452e75112084f537af99be90721c2629cd5`
Acceptance set: `cafe_v1`, `bar_v1`, `market_v1` (LOCKED; see `art/acceptance_refs/v1/MANIFEST.md`)
Active staging branch: `spike/mpfb-hero-limb-baked-evidence-v64c`
Authored candidate head: `d6efafae7b4adcac3ec9cf2ad2ad8f540c03949b`

## Exact-head verification

### v64b gate repair

- Authored head: `6e11fbb2ca217313fe15127db2d8aacc8c50bf8f`
- Godot Check: run `31898485794` — PASS
- MPFB Baked Source v64b: run `31898485775` — PASS
- Artifact: `mpfb-baked-source-v64b`, id `9250466324`
- Evidence bot commit: `79a8f825249ea9e6ad677322e4099adfa39a3e8f`

The previous v64b run failed only because it used a hard-coded `baked_vertices >= 2200` proxy while the adaptive crop produced 1,747 vertices. That proxy did not prove anatomical completeness. It has been replaced with an anatomical coverage gate rather than simply weakened:

- `baked_vertices = 1747`
- `palm_vertex_coverage = 1300`
- minimum per-segment surface coverage = `55` vertices
- required segments: `lowerarm02.R`, `wrist.R`, and all 15 `finger{1..5}-{1..3}.R` segments
- every required segment must retain >= 12 nearby surface vertices
- total retained vertices still have a coarse >= 1400 sparsity guard

This closes the CI/evidence-extraction defect without allowing a missing finger or palm to pass merely because unrelated body vertices remain.

### v64c multiview evidence

- Authored head: `d6efafae7b4adcac3ec9cf2ad2ad8f540c03949b`
- Godot Check: run `31898820923` — PASS
- MPFB Baked Evidence v64c: run `31898820951` — PASS
- Artifact: `mpfb-baked-evidence-v64c`, id `9250561259`
- v64c changes **no pose, crop, source, vessel transform, rig, deformation or production gameplay**. It only renders the same baked v64b mesh from deterministic unobstructed anatomy views in addition to the original with-vessel view.

## Frames inspected

Persisted / artifact evidence:

- `support-wrap-with-vessel.png`
- `support-wrap-with-vessel-thumbnail.png`
- `anatomy-front.png`
- `anatomy-oblique.png`
- `anatomy-thumbnail.png`

## Visual verdict — REJECT v64/v64b source pose for support-wrap production staging

The v64b product-like view was initially inconclusive because the proxy vessel occluded almost the entire hand, leaving only several fingertip/palm blobs visible. v64c removed that ambiguity.

### Macro

**FAIL.** The unobstructed 192x108 anatomy thumbnail reads as an open/partly curled hand, not a firm human hand wrapping a cup or bottle. The acceptance references require a substantial palm and a clear opposing-thumb / enclosing-fingers silhouette.

### Meso

**FAIL.** The front view can look superficially curled because of foreshortening, but the oblique view exposes the actual structure: the digits remain mostly extended rather than enclosing a bottle-sized volume, and thumb opposition is not strong enough. The with-vessel view therefore shows isolated visible pads rather than a readable grip.

The extracted forearm boundary is also staging-cut geometry rather than a production-ready anatomical transition; this is acceptable for diagnosis but another reason not to promote the static crop.

### Micro

Not evaluated. Macro/Meso failed, so skin/PBR/fibers/glass polish remains frozen.

## What this proves

1. The earlier v64b failure was **not** evidence that 1,747 vertices were insufficient; the repaired anatomical coverage gate proves the relevant limb regions survived the crop.
2. The source-native same-rig bake avoids the cross-rig deformation artifacts that plagued earlier transfer experiments.
3. However, `mindfront_sitting_in_armchair_holding_wine_glass` is not a suitable bottle/cup support-wrap pose for the locked Peel Calm references. The source itself is the current mismatch.
4. Do not spend another loop changing crop radii, vertex-count thresholds, camera occlusion, or vessel darkness for this source pose.
5. Do not send v64/v64b/v64c to Godot product-camera staging and do not open a production PR from it.

## Current reds

### R1 — Reference-derived whole-hand support grasp

Need a pose whose thumbnail immediately reads as a human hand enclosing the vessel: palm beside/behind the container, fingers genuinely curling around the far contour, and thumb clearly opposing them. The current CC0 wine-glass source pose does not satisfy this.

### R2 — Product-camera proof

Blocked until R1 passes in staging. Only then compare the candidate against current XR baseline in café/bar/market product FOV and interaction states.

### R3 — Peel-hand flap pinch

Still blocked behind support-hand R1/R2.

### R4+ — Micro material polish

Skin, paper fibers, glass breakup, condensation and similar high-frequency polish remain frozen.

## Research note

The official MakeHuman Community asset packs remain rights-safe staging sources: the published asset-pack index identifies Poses 01/02 as CC0 pose packs. Poses 01 contains the holding-wine-glass pose used here; Poses 02 is sports-focused and does not provide an obvious bottle/cup power-grasp replacement. Do not assume another bundled MakeHuman pose will solve R1 without inspecting its actual hand silhouette.

## Next exact action

Change the **pose source / pose derivation**, not the crop or renderer.

Preferred next spike:

1. Keep the same native MPFB canonical body/rig path that proved deformation-safe.
2. Derive a support-hand pose directly from the locked `bar_v1` / `market_v1` visual relationship rather than from the wine-glass BVH.
3. Use a real bottle-sized proxy while authoring the pose.
4. Produce at least: with-vessel thumbnail, unobstructed anatomy front, anatomy oblique.
5. Gate first on Macro enclosure + thumb opposition, then on Meso finger continuity/self-intersection.
6. Only if those pass, bake/export staging GLB and proceed to Godot product-camera comparison.
7. No CCD/endpoint tolerance/orbit/crop parameter sweep resurrection; those families have already been falsified in prior checkpoints.

Production `main` remains untouched by this staging work.
