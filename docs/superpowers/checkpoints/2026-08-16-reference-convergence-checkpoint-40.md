# Peel Calm reference convergence checkpoint 40

Date: 2026-08-16
Production main baseline: `769d6452e75112084f537af99be90721c2629cd5`
Previous staging checkpoint: `spike/contactpose-guided-artist-v82@0ffbc2e95741801a2e06db7afb9ca16032dfc81c`
Current staging branch: `spike/mpfb-grip-helper-authoring-v84`
Current exact head before this checkpoint: `f9df022ee8e9cbaecc7b19f3954110f50715a597`

## Locked acceptance targets

The acceptance set remains unchanged: `bar_v1` and `market_v1` for the glass-bottle support-hand problem. Runtime screenshots and staging renders remain evidence only and cannot replace the approved target set.

## Why this loop changed abstraction

Checkpoint 39 rejected v82 because a ContactPose-informed screen-space handle table still produced a near-side claw/clump. The four non-thumb fingers did not read as a natural far-side vessel enclosure, and unobstructed anatomy showed distal bunching and overlap. More raw-bone angle tables, endpoint chasing, CCD, contact servo, whole-hand orbit sweeps and exact ContactPose retargeting remain forbidden.

This loop found an official MPFB capability that better matches the actual authoring problem: the Default-rig Finger Helper supports `GRIP_AND_MASTER`, with a master grip control plus one semantic grip control per digit. The helper distributes semantic grip rotation through the actual finger chains. This is a different control abstraction from directly posing 12 phalanx bones.

## v83 — single semantic Grip Helper candidate

Branch: `spike/mpfb-default-grip-helper-v83`
Exact evidence head: `7dfc184d4cfc1829849c62978f921437825d3903`
Godot Check: run `31924679583` — PASS
Godot runtime artifact: `peel-calm-reference-frames`, artifact `9257460471`
MPFB Default Grip Helper: run `31924679572` — PASS
MPFB visual artifact: `mpfb-default-grip-helper-v83`, artifact `9257490621`

The candidate count was exactly one. No parameter sweep was used. The frozen semantic controls were:

- `right_master_grip = 34°`
- `right_finger1_grip = 10°`
- `right_finger2_grip = -12°`
- `right_finger3_grip = 2°`
- `right_finger4_grip = 10°`
- `right_finger5_grip = 18°`

Explicitly absent: CCD, endpoint optimizer, contact servo, ContactPose retarget, direct phalanx pose table, production GameEngine-rig mutation.

### Visual verdict

**REJECT for product staging, KEEP the semantic helper abstraction.**

The initial front-with-vessel evidence was too occluded to judge fairly, so v83b added only a second evidence camera. Pose, rig, vessel transform, crop, materials and grip values were frozen. The corrected vessel-oblique 192×108 frame still failed Macro: the cylinder dominates the frame and only isolated finger/thumb fragments appear; the image does not immediately read as a stable human hand wrapping a bottle. The with-vessel oblique frame likewise lacks a clear thumb-versus-four-finger opposing silhouette.

The unobstructed oblique anatomy is nevertheless materially better than v82 in one respect: the semantic helper produces smoother, more coherent curved digit chains rather than the previous tight distal claw/clump. This is enough evidence to preserve the helper as an authoring control layer, but not enough to accept the v83 seed as a pose.

A separate Meso defect is visible in the staging crop: the wrist/palm crop creates polygon-like gaps. This is an evidence/static-crop defect, not proof that the semantic finger-control abstraction is wrong. Do not tune grip values to hide it.

## v84 — editable native semantic-grip authoring scene

Branch: `spike/mpfb-grip-helper-authoring-v84`
Exact verified head: `f9df022ee8e9cbaecc7b19f3954110f50715a597`
Godot Check: run `31924881416` — PASS
Godot runtime artifact: `peel-calm-reference-frames`, artifact `9257520812`
MPFB Grip Helper Authoring: run `31924881428` — PASS
Editable authoring artifact: `mpfb-grip-helper-authoring-v84`, artifact `9257521841`

The workflow creates and then reopens an editable Blender `.blend` containing:

- native MPFB Default rig;
- official `GRIP_AND_MASTER` finger helper;
- `wrist.R` for whole-hand placement/orientation;
- `right_master_grip` plus `right_finger1_grip` through `right_finger5_grip` as the only semantic finger controls intended for direct editing;
- locked vessel proxy;
- locked fixed camera;
- embedded `bar_v1,market_v1` acceptance contract;
- embedded Macro/Meso gate text;
- embedded forbidden-method list;
- `PENDING_DIRECT_ARTIST_EDIT` visual verdict;
- `production_candidate = false`.

The second Blender invocation reopened the saved `.blend` and verified that all seven editable controls, the locked camera/vessel, reference contract and non-production visual verdict survived serialization. Candidate count remains one and parameter sweep remains false.

### What v84 closes

The environment no longer needs to expose 12 raw phalanx local axes for direct visual posing. A future direct visual edit can work through one whole-hand/wrist control plus six semantic MPFB grip controls and then pass the existing evidence/ingest gates. This is a substantial reduction in authoring complexity and a better match for the reference-derived grasp grammar.

v84 does **not** close R1 because no new directly visually edited pose has yet passed Macro/Meso.

## External capability research

MHR-Hand was examined as a possible browser-based interactive hand poser. Its repository exposes an interactive viewer, but the derivative repository did not present a clear root license grant during this review even though its upstream Meta MHR project is Apache-2.0. Do not introduce MHR-Hand code/checkpoints/assets into the production or preferred staging path until the derivative asset/code licensing boundary is explicit.

## Current ranked reds

### R1 — Direct whole-hand support grasp

Use the v84 editable native rig scene. Visually author the hand as one object rather than optimizing endpoints. Macro target: at 192×108 the bottle plus hand must immediately read as a natural stable human grip, with palm beside the vessel, four fingers disappearing progressively around the far contour and thumb visibly opposing them.

### R2 — Godot product-camera proof

After one v84-derived pose passes Macro and unobstructed Meso, bake/export it through the verified staging boundary and compare bar/market product-camera frames against current XR baseline and locked references.

### R3 — Peel-hand pinch

Only after the support-hand replacement path is proven, author thumb/index flap contact with the same reference-first discipline.

### R4+ — Micro polish

Skin PBR, paper fibers, glass highlights, liquid/ice, condensation and other Micro work remain frozen while R1 is dominant.

## Do not repeat

- v82 screen-space handle or JSON angle-table search;
- raw 12-phalanx direct angle authoring as the primary control layer;
- CCD / endpoint chasing / contact servo;
- whole-hand orbit sweeps;
- exact ContactPose retarget;
- source-direction copying;
- v83 semantic-control value sweep;
- changing the locked vessel/camera merely to make a bad pose look acceptable;
- treating technical PASS as visual PASS.

## Next exact action

1. Start from the verified v84 `.blend` artifact or reproducible v84 builder.
2. Directly edit `wrist.R`, `right_master_grip` and the five per-digit semantic grip controls while viewing the locked bottle and fixed camera.
3. Produce exactly one visually authored candidate, not a sweep.
4. Render with-vessel 192×108 Macro plus unobstructed oblique Meso.
5. Reject unless the thumbnail immediately reads as a natural human vessel wrap with an opposing thumb and the oblique anatomy has coherent web space, knuckle flow and separated progressive digit arcs.
6. If it passes, stop support-pose search and move immediately to Godot bar/market product-camera comparison against current XR baseline; then run an independent Challenger before any production merge.
