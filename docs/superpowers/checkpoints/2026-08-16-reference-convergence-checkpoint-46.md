# Peel Calm reference convergence checkpoint 46

Date: 2026-08-16
Branch: `spike/mpfb-grip-web-viewport-v88`
Production baseline: `main@769d6452e75112084f537af99be90721c2629cd5`
Candidate/evidence head: `24129dad1009cf7231dc7d615d173875604421eb`
Locked acceptance references: `bar_v1`, `market_v1`

## Exact-head verification

- Godot Check: run `31939840167` — PASS.
- Standard runtime reference-frame artifact: `peel-calm-reference-frames`, artifact `9261713311`.
- Dedicated MPFB v88 product-camera A/B: run `31939840186` — PASS.
- Dedicated product-camera artifact: `mpfb-v88-product-camera`, artifact `9261769574`.
- Captured same-camera frames:
  - `bar_xr.png`
  - `bar_v88.png`
  - `market_xr.png`
  - `market_v88.png`
  - `market_v88_inspect45.png`

The product-camera workflow now initializes the checked-out Godot project before generating Blender staging evidence, then loads the newly generated v88 GLB at runtime with `GLTFDocument.append_from_file()` / `generate_scene()`. This avoids both previous evidence-chain failures: ResourceLoader had no import remap for a job-generated GLB, while a later full-project `--import` tried to import unrelated staging `.blend` files and required a Blender Editor Setting. The final path produced all five required frames.

## Visual verdict: v88 REJECT

Technical PASS does not promote this candidate.

### Macro

`bar_v88` and `market_v88` are worse than the XR baseline in the most important low-frequency support-hand structure:

- the MPFB limb enters from the upper-right and dominates too much of the frame;
- the palm/wrist placement is on the wrong approach path relative to the locked bottle references;
- the fingers descend from above the bottle/label instead of disappearing progressively around the bottle's far-side silhouette;
- thumb-versus-four-finger opposition is not immediately readable as a stable vessel wrap;
- the pose reads more like a large hand placed over the bottle top than a support hand enclosing the bottle body.

The MPFB mesh is visibly smoother and more continuous than the XR hand, but the lower-frequency composition and grasp grammar are wrong, so that topology improvement cannot justify promotion.

### Meso

`market_v88_inspect45` does not rescue the candidate. The same top-down hand relationship persists under a common inspection state rather than becoming a stable side wrap. Therefore the candidate does not pass the interaction-state structure gate either.

## What was learned

1. The MPFB export/runtime-Godot pipeline is no longer the blocker. A generated staging GLB can be loaded and captured in the real Peel Calm product camera without committing the asset to production.
2. The candidate-scale conversion works well enough to make a decisive product-camera comparison; the remaining failure is visual choreography, not missing evidence.
3. Continuous anatomy alone is insufficient. Whole-hand root/palm placement and grasp direction outrank mesh smoothness.
4. A product-camera gate was necessary: the staging authoring view did not reveal how severely the upper-right approach would damage real composition.

## Closed / do-not-repeat

Do not repeat:

- treating standard nine-frame Godot artifact as proof for an uninvoked v88 staging candidate;
- `ResourceLoader.load()` on a GLB generated after the project scan without an import remap;
- running a full project `--import` after staging `.blend` evidence has been generated under `res://`;
- promoting v88 because its mesh is smoother than XR;
- tuning skin/PBR, paper fibers, glass highlights, liquid or condensation while R1 remains Macro-failed.

## Remaining reds

### R1 — reference-derived support-hand whole-hand choreography

Highest priority remains a continuous human hand/wrist/forearm that, in the actual bar/market product camera:

- approaches the bottle from the reference-compatible side rather than from above;
- places the palm beside the bottle body;
- sends index through pinky progressively around the far-side silhouette;
- leaves a clearly readable opposing thumb on the near/opposite side;
- remains anatomically continuous and stable under inspection yaw.

### R2 — product-camera integration proof

Only after a new R1 pose passes a locked 192x108 Macro staging gate should it use the now-working v88 runtime GLTF/product-camera A/B harness.

### R3 — peel-hand pinch

Still deferred behind support-hand R1/R2.

### Micro

Skin PBR, paper fibers, glass optical breakup, liquid and condensation remain frozen.

## Next exact action

Do **not** make another scalar grip/angle sweep from v88.

Use the v87/v86 authoring infrastructure and ContactPose ghost as visual guidance to create one structurally different whole-hand candidate whose **root/palm approach is side-on in the locked product-camera language** before finger refinement. The first test is not fingertip distance: render a low-resolution opaque-vessel staging frame and require the support hand to read immediately as a side vessel wrap with clear thumb opposition. If that passes, feed the candidate into the now-proven `MPFB V88 Product Camera` runtime harness and compare bar/market against XR on the same camera, then inspect the yaw state. If it fails Macro, reject before Meso/Micro or Challenger.
