# Peel Calm reference convergence checkpoint 41

Date: 2026-08-16
Branch: `spike/mpfb-grip-helper-ghost-v85`
Production baseline: `main@769d6452e75112084f537af99be90721c2629cd5`
Exact verified staging head before checkpoint: `1ddb3b76f1c6dd38fb256f1a0c0a4e32b2f711d5`

## Exact-head verification

- Godot Check run `31927288198` — **PASS**
  - headless import/parse
  - configured project launch
  - deterministic unit tests
  - scene/reference/cafe/crumple/contents/forearm/ritual smoke
  - repeated reset
  - pause/reset input isolation
  - nine cafe/bar/market runtime captures
- Godot runtime artifact `peel-calm-reference-frames` id `9258221155`
- MPFB Grip Helper Ghost v85 run `31927288202` — **PASS**
- Editable authoring/evidence artifact `mpfb-grip-helper-ghost-v85` id `9258246596`

## Locked acceptance references

The final support-hand acceptance targets remain `bar_v1` and `market_v1`. ContactPose is an anatomical guide only. Runtime captures, staging images, and the cyan ghost must never replace the locked acceptance set.

## What v85 changes

v84 already reduced native MPFB Default-rig authoring to seven semantic controls:

- `wrist.R`
- `right_master_grip`
- `right_finger1_grip` ... `right_finger5_grip`

v85 adds the selected real-human ContactPose `water_bottle / full6_use / hand1` 21-joint annotation as **read-only cyan ghost geometry** inside the same authoring scene.

Critical boundaries verified on exact head:

- no automatic ContactPose retarget;
- no CCD;
- no endpoint/contact optimizer;
- no raw-phalanx angle table;
- no parameter sweep;
- ghost construction changes the seven v84 authoring-control matrices by `0.0` within the `1e-9` gate;
- original vessel geometry and fixed camera remain locked;
- scene verdict remains `PENDING_DIRECT_ARTIST_EDIT`;
- `production_candidate == false`.

## Evidence correction inside this loop

The first v85 evidence pass technically passed, but visual inspection found its opaque-vessel ghost view was not useful enough: the locked opaque bottle hid most of the far-side real-human skeleton, and at 192x108 only fragments remained visible.

This was an **evidence-presentation defect**, not a reason to alter the hand pose, vessel geometry, camera, or acceptance target.

The corrected exact head therefore adds a separate non-selectable `AUTHORING_WireVesselGuide_V85` duplicate used only for authoring diagnostics. The original `LOCKED_VesselProxy` remains unchanged and is still used for final opaque Macro evidence.

The artifact now contains:

- `v85-ghost-with-vessel.png` — unchanged opaque acceptance-context view;
- `v85-ghost-thumbnail.png` — unchanged 192x108 opaque Macro view;
- `v85-ghost-wire-vessel.png` — authoring-only vessel-outline view;
- `v85-ghost-wire-thumbnail.png` — authoring-only 192x108 depth guide;
- `v85-ghost-anatomy.png` — unobstructed Meso anatomy;
- `peel-calm-grip-helper-ghost-v85.blend` — editable semantic-control authoring scene.

## Visual verdict

### v85 infrastructure — KEEP

The wire-vessel diagnostic successfully exposes the real-human guide's depth ordering without changing the actual locked vessel or camera. It is materially more useful than the first opaque-only overlay for direct visual posing.

### v84/v85 seed pose — still REJECT as product candidate

The current MPFB seed is still not a natural reference-quality vessel wrap.

At Macro/Meso scale:

- the current non-thumb fingers still read primarily as a near-side downward/open arrangement;
- the ContactPose ghost visibly occupies distinct depth layers and demonstrates a different index -> middle -> ring -> pinky enclosure grammar;
- the current seed does not yet reproduce a clean opposing thumb + far-side four-finger silhouette;
- therefore technical PASS must not promote the seed into Godot product-camera staging.

The ghost exists to make this mismatch easier to author against; it is not an automatic solution.

## Closed engineering risk

A future direct artist no longer has to choose between:

1. opaque vessel context that hides the far-side anatomy, and
2. anatomy-only context that loses the cylinder relationship.

v85 provides both unchanged opaque acceptance context and an authoring-only wire vessel context while preserving the seven semantic controls and immutable pose boundary.

## Remaining reds

### R1 — Direct whole-hand support grasp

Use the v85 `.blend` to visually author **exactly one** native-rig support grasp through the seven semantic controls while looking at the real-human ghost and locked vessel/camera.

Pass conditions:

- 192x108 opaque-vessel view immediately reads as a stable human bottle grip;
- palm sits beside the vessel rather than merely touching it;
- thumb visibly opposes the four fingers;
- index closes more lightly;
- middle/ring/pinky progressively travel around the far contour/depth;
- unobstructed anatomy retains web space, natural knuckle flow, separated digit arcs, and no obvious self-intersection.

If it fails, reject the single candidate. Do not turn the semantic controls into a value sweep.

### R2 — Godot product-camera proof

Only after R1 passes, import the continuous limb into a Godot staging scene and compare exact same-camera bar/market frames against the current XR baseline and locked references.

### R3 — Peel-hand pinch

After the support-hand pipeline is proven, author thumb/index flap pinch with the same visual-first process.

### R4+ — Micro fidelity

Skin PBR, paper fiber, glass/liquid, condensation and other Micro work remain frozen while R1 is visibly dominant.

## Do not repeat

- CCD / endpoint chasing / contact servo;
- raw 12-phalanx local-axis tables;
- whole-hand orbit sweeps;
- exact ContactPose retarget;
- ContactPose source-direction copying;
- v83-style semantic-control value sweep;
- changing locked vessel geometry or camera to make a weak pose look acceptable;
- using the wire-vessel diagnostic as the final Macro acceptance image;
- treating green CI as visual acceptance.

## Next exact action

Start from `peel-calm-grip-helper-ghost-v85.blend`. In a true visual authoring environment, make exactly one direct whole-hand pose using `wrist.R`, `right_master_grip`, and the five per-digit grip controls while using the cyan ContactPose ghost / wire-vessel view only as anatomical guidance. Render the unchanged opaque-vessel 192x108 Macro frame and unobstructed Meso anatomy frame. If both pass, stop support-pose research immediately and move to Godot bar/market product-camera comparison + independent Challenger.
