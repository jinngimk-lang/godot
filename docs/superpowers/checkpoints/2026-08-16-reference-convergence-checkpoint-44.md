# Peel Calm reference convergence checkpoint 44

Date: 2026-08-16
Branch: `spike/mpfb-grip-helper-authoring-panel-v87b`
Production main baseline: `769d6452e75112084f537af99be90721c2629cd5`
Verified infrastructure candidate head: `cf4af70f8bc7abac8539d9a61274ed7bae464e26`
Godot Check: run `31934297121` — PASS
Godot reference-frame artifact: `9260193468`
MPFB Grip Helper Authoring Panel v87: run `31934297186` — PASS
Editable authoring-panel artifact: `9260246842`
Locked acceptance references: `bar_v1`, `market_v1`

## Why this loop existed

Checkpoint 43 had already reduced the remaining support-grasp task to a true direct-visual artist operation:

1. put the palm beside the bottle rather than over its near face;
2. correct index depth most strongly while keeping it the lightest closure;
3. progressively deepen middle/ring enclosure;
4. disturb pinky minimally;
5. finish with readable whole-thumb opposition;
6. hide all guides before acceptance;
7. accept only if the opaque 192x108 Macro immediately reads as a natural stable human bottle grip and unobstructed Meso anatomy stays continuous.

The automated runtime still has no interactive Blender viewport / rigging connector. Reintroducing numeric pose tables, CCD, endpoint targets, ContactPose retargeting, or parameter sweeps would violate the already-proven stop condition. This loop therefore addressed the remaining *authoring friction* without creating another pose candidate.

## What v87 changed

Starting from the verified v86 ghost/wire/discrepancy authoring scene, v87 adds persistent direct-artist controls while deliberately leaving the pose unchanged:

- creates dedicated bone collection `PEEL_CALM_DIRECT_ARTIST_CONTROLS_V87`;
- assigns persistent visible custom control shapes to exactly seven approved semantic controls:
  - `wrist.R`;
  - `right_master_grip`;
  - `right_finger1_grip` through `right_finger5_grip`;
- embeds per-control edit-order hints matching the checkpoint-43 visual brief;
- embeds `PEEL_CALM_V87_DIRECT_ARTIST_BRIEF` inside the `.blend`;
- keeps ContactPose ghost, wire vessel and v86 discrepancy arrows as guidance only;
- keeps the locked opaque vessel and locked camera untouched;
- keeps scene verdict `PENDING_DIRECT_ARTIST_EDIT` and `production_candidate=false`.

No gameplay code or production hand asset changed.

## Exact-head verification

### Godot

Run `31934297121` passed on `cf4af70f8bc7abac8539d9a61274ed7bae464e26`:

- static guard;
- Godot 4.7.1 install/import/parse;
- configured project launch;
- unit tests;
- scene/reference-scene smoke;
- label/cafe/crumple/contents/forearm/ritual smoke;
- repeated-session reset;
- pause/reset input isolation;
- nine café/bar/market runtime captures.

Artifact `9260193468` was manually inspected in this loop. The current production-style bar/market frames still show the same dominant R1: XR-like open/faceted hands and forearm transitions do not read as a natural vessel wrap. Therefore the panel work does not close R1.

### MPFB / Blender boundary gate

Run `31934297186` passed on the same exact head.

The workflow builds the v87 scene and then starts a second Blender process that reopens the saved `.blend`. The reopened-file gate verifies:

- exactly seven semantic controls exist;
- every approved control still has a persistent custom shape;
- the dedicated control collection exists;
- the embedded artist brief exists;
- `visual_verdict == PENDING_DIRECT_ARTIST_EDIT`;
- `production_candidate == false`;
- no optimizer, automatic retarget, or parameter sweep is enabled;
- vessel and camera remain locked;
- semantic-control matrix delta from v86 is `<= 1e-9`;
- vessel matrix delta from v86 is `<= 1e-9`;
- camera matrix delta from v86 is `<= 1e-9`.

Artifact `9260246842` contains the editable `.blend`, inherited Macro/Meso evidence, reports, and logs.

## Visual verdict

**Infrastructure PASS; pose still FAIL / pending direct artist edit.**

This checkpoint must not be interpreted as a new support-grasp visual candidate. v87 intentionally preserves the v86 seed pose. The newest Godot bar/market screenshots still fail the locked reference intent at Macro/Meso scale because the support hand is not a convincing human enclosure of the bottle.

## Closed risk

A future direct Blender artist no longer needs to rediscover opaque MPFB finger bones or manipulate 12 raw phalanx controls. The authoring scene now exposes only the already-approved semantic surface and carries the exact edit order and acceptance gates inside the file. The CI boundary proves these aids do not mutate the staged pose or locked reference context.

## Remaining reds

### R1 — true direct-visual whole-hand support grasp

Still the highest red. Required operation is a single native-rig artist pose using the seven semantic controls, not a generated value sweep.

Required edit sequence:

1. `wrist.R`: palm beside vessel;
2. index: strongest coherent move toward far-side/depth arc, lightest closure;
3. middle then ring: progressively deeper enclosure with visible separation;
4. pinky: minimal disturbance unless continuity demands it;
5. thumb: final whole-chain opposition against the four-finger group.

Acceptance:

- hide ghost / wire / discrepancy arrows;
- opaque 192x108 immediately reads as stable natural human bottle grip;
- palm sits beside vessel;
- thumb clearly opposes four-finger group;
- index is lightest closure and middle/ring/pinky progressively enclose;
- unobstructed anatomy retains web space, separated digit arcs, natural knuckle flow and no obvious self-intersection.

### R2 — Godot product-camera proof

Blocked by R1. Once R1 passes staging, render the candidate in actual bar and market product cameras against the current XR baseline and locked references.

### R3 — peel-hand label pinch

Blocked behind support-grasp replacement proof.

### R4+ — Micro fidelity

Skin/PBR, paper fibers, glass/liquid/condensation, residue detail and other Micro polish remain frozen while R1 is dominant.

## Do not repeat

Do not convert the next direct-artist operation into:

- CCD / endpoint chasing;
- contact-distance or surface servo;
- raw MCP/PIP/DIP Euler tables;
- semantic grip-value sweeps;
- whole-hand orbit search;
- automatic ContactPose retarget;
- source-direction copying;
- per-digit scalar angle scans;
- another headless approximation presented as interactive artist posing.

## Next exact action

Open artifact `9260246842` / `peel-calm-grip-helper-authoring-panel-v87.blend` in a real interactive Blender viewport (or a future verified rigging connector). Perform exactly one direct visual whole-hand edit using the seven semantic controls and the embedded ghost/wire/arrows only as guidance. Save the same-rig `.blend`, run it through the existing non-mutating ingest/evidence gate, hide all guides, and judge opaque Macro first. If Macro and unobstructed Meso both pass, immediately stop support-pose research and move to Godot bar/market product-camera A/B plus independent Challenger. If it fails, reject that single pose and preserve the failure evidence; do not turn it into a parameter sweep.
