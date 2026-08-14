# Peel Calm reference convergence checkpoint 09

Date: 2026-08-15
Production baseline: `main@769d6452e75112084f537af99be90721c2629cd5`
Production post-merge Godot Check: `31810098509` — PASS
Production runtime frame artifact: `9222768455`
Acceptance set: `cafe_v1`, `bar_v1`, `market_v1`

## Highest-impact reds

R1 remains continuous realistic hand/wrist/forearm anatomy in the real product camera.

R2 remains photographic support-wrap and paper-flap pinch choreography. Contact metrics are necessary but not sufficient; fixed-camera and Godot-runtime Macro/Meso evidence remain the visual gate.

Micro skin, paper, glass and condensation polish remains intentionally blocked behind R1/R2.

## Recovered model-spike state

The previous checkpoint 08 rejected v10-v20 direct joint-angle/rotation-delta/thumb-weight redistribution families as morphology-dependent dead ends. The later v29/v30 line moved to visible-surface contact plus gameplay-realistic bounded hand-root tracking.

`spike/mpfb-hero-limb-precision-v30@ebf3ad4d28e07f5ba2d11401dbd19acbccee6323`:

- MPFB precision run `31847786391` — PASS.
- Godot Check `31847786517` — PASS.
- Artifact `9236541363`.
- v30 changes only direct surface-servo early stop from 4.0 mm to 1.5 mm; it does not relax the <=10 mm visible pinch-gap gate, 24 degree extra joint budget, morphology, root-shift limit, seed pose or paper-face targets.
- v29 recorded a ~14.9 mm hand-root shift and near-pass contact; v30 closes the remaining precision miss under the existing gates.

Verdict: do not spend another loop on arbitrary v31/v32 numeric IK tuning before proving the pose can survive the production asset pipeline.

## v31 — rigged staging GLB + Godot 4.7.1 import gate

Branch: `spike/mpfb-hero-limb-godot-import-v31`
Implementation head used by the completed gate: `dcd19379894dd64c49af1f1da3de83b5ca7bca11`

New staging components:

- `tools/export_mpfb_pose_candidates_v31.py`
  - reuses the v30 precision configuration;
  - exports one-frame rigged `SupportWrapV31` and `LabelPinchV31` actions;
  - exports armature plus driven MPFB mesh as GLB;
  - does not replace production hand assets.
- `tests/inspect_mpfb_staging_candidate.gd`
  - requires Godot import as `PackedScene`;
  - requires `Skeleton3D`, a nontrivial bone count, named pose animation, renderable mesh and a bounded staging vertex count.
- `.github/workflows/mpfb-hero-limb-preview.yml`
  - re-proves v30 in Blender;
  - exports both GLBs;
  - installs pinned Godot 4.7.1;
  - performs real headless import and staging inspection.

### Exact-head evidence

Godot Check `31850748987` on `dcd19379894dd64c49af1f1da3de83b5ca7bca11` — PASS.

MPFB Hero Limb Godot Import v31 run `31850748984` on the same head — PASS all steps:

1. pinned Blender 4.2.0 + MPFB 2.0.17;
2. build/extract continuous MPFB right hero limb;
3. re-prove v30 precision pose gate;
4. export rigged support and pinch GLBs;
5. install pinned Godot 4.7.1;
6. Godot import and instantiate/inspect both candidates;
7. upload evidence.

Artifact: `9237484960` (`mpfb-hero-limb-godot-import-v31`), digest `sha256:07f5106a639f0af4c091fb638c24e932a290e13a19c3f72d1a8bc08516825eb1`.

### Exported asset contract

Both candidates preserve:

- one continuous MPFB hero-limb mesh;
- 53-bone GameEngine armature;
- 3,184 mesh vertices;
- one named baked pose action;
- approximately 1.53 MB GLB size.

Support contact errors recorded at export are approximately `[24.68, 7.89, 5.46, 13.88] mm`, all inside the unchanged 30 mm staging support-contact gate.

This closes a real pipeline risk: the successful pose is no longer only a Blender experiment. It can be exported as a rigged GLB and consumed by Godot 4.7.1 without replacing production assets.

## Evidence persistence

A follow-up workflow head `48571979c25a9797782ac4196bee18f0fa22fc1a` added branch-persisted visual/import evidence. Run `31850997816` re-ran the same build/export/Godot-import path and successfully reached the evidence-persist step. The workflow committed selected fixed-camera images and the pose contract back to this branch as bot commit `b2f957d3ab895f2d71084893b30324500cce188c`.

Persisted evidence directory:

`docs/superpowers/evidence/mpfb-v31/`

Known files include:

- `support-wrap.png`
- `label-pinch.png`
- `pose-candidates-v31.json`

The images are evidence only; they do not redefine `cafe_v1`, `bar_v1` or `market_v1`.

## What is NOT yet accepted

Do not promote the MPFB limb into production gameplay yet.

The remaining visual gate is not another contact-number improvement. It is whether the support and pinch silhouettes read naturally at Macro/Meso scale in a product-equivalent camera and, next, in a real Godot staging scene beside the actual cup/bottle/label geometry.

Specifically reject the candidate if any of these are visible even when numeric contact passes:

- claw/hanging support fingers;
- implausible thumb opposition;
- wrist/forearm crop that does not resemble the reference;
- self-intersection;
- pinch fingers technically touching while the hand root/palm reads disconnected from the flap;
- hand/vessel scale inconsistent with the locked reference family.

## Next exact action

1. Inspect `support-wrap.png` and `label-pinch.png` at thumbnail/Macro and Meso scale; record the largest visible red for each.
2. If either isolated pose visibly fails, make one structural pose change only; do not polish materials.
3. If both are visually credible, create a **Godot staging scene**, not production integration, that instantiates the exported MPFB candidate beside the project cup/bottle and label-flap proxies under product-equivalent camera/FOV and lighting.
4. Capture Godot staging frames for support wrap and label pinch.
5. Compare those frames to the locked acceptance intent and current XR-hand baseline at Macro then Meso scale.
6. Only if the Godot staging frames visibly improve R1/R2, prepare a production integration branch with the normal exact-head screenshot matrix and independent Challenger.

No PR/merge into `main` is justified by this checkpoint alone.
