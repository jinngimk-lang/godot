# Peel Calm reference convergence checkpoint 42

Date: 2026-08-16
Branch: `spike/mpfb-grip-helper-contactpose-v86`
Production baseline: `main@769d6452e75112084f537af99be90721c2629cd5`
Previous staging checkpoint head: `caa7aae6948e61602bd942ae2b79696833bbe84a` (checkpoint 41)
Exact v86 candidate head: `167f09d582adeb540d6d0f1657484ab485c17d4b`
Godot Check: run `31929554432` — PASS
Godot runtime artifact: `9258876986` (`peel-calm-reference-frames`)
MPFB Grip Helper ContactPose v86: run `31929554568` — PASS
MPFB visual artifact: `9258931294` (`mpfb-grip-helper-contactpose-v86`)
Open product PRs at the start of this loop: none

## Locked acceptance references

Final support-hand acceptance remains:

- `bar_v1`
- `market_v1`

The ContactPose `water_bottle / full6_use / hand1` skeleton remains anatomy guidance only. It is not an acceptance replacement and is not retargeted onto production/staging bones.

## Hypothesis tested

Checkpoint 41 left a true visual-authoring requirement: use the native MPFB Default-rig semantic controls instead of raw finger-bone tables or solver search.

v86 tested one deliberately bounded hypothesis without a sweep:

> Can the real-human non-thumb closure ordering persisted from ContactPose be translated once into MPFB's semantic `master grip + per-finger grip` controls, while freezing wrist, vessel, camera, and all forbidden solver paths, and produce a natural bottle-support silhouette?

The single candidate used:

- `right_master_grip = 48 deg`
- thumb semantic offset `+18 deg`
- index semantic offset `-17.4 deg`
- middle semantic offset `-5.8 deg`
- ring semantic offset `+1.0 deg`
- pinky semantic offset `+12.6 deg`

The intended non-thumb effective ordering was approximately the persisted ContactPose closure sequence:

- index `30.6 deg`
- middle `42.2 deg`
- ring `49.0 deg`
- pinky `60.6 deg`

This was one candidate only. There was no candidate grid, no value sweep, and no second numeric correction.

## Technical boundary result — PASS

The exact v86 head passed both verification chains.

The v86 report confirms:

- `candidate_count == 1`
- `production_candidate == false`
- `automatic_retarget_used == false`
- `guide_used_for_bone_retarget == false`
- `parameter_sweep_used == false`
- `endpoint_optimizer_used == false`
- `contact_servo_used == false`
- `wrist_changed == false`
- wrist matrix delta `0.0`
- locked vessel unchanged
- locked camera unchanged
- locked references remain `bar_v1 / market_v1`

The same exact head also passed the full Godot 4.7.1 import/launch/unit/smoke/reset/pause/input/reference-capture pipeline.

## Real-frame visual verdict — REJECT

Technical green does not promote this candidate.

### Macro / 192x108 — FAIL

`v86-support-thumbnail.png` does **not** read immediately as a stable human bottle grip.

Visible defects:

- most of the four-finger mass disappears behind the opaque vessel;
- only disconnected distal fragments remain visible on the opposite side;
- the large right-side digit/hand mass and the small left fragments do not form a coherent thumb-versus-fingers opposition silhouette;
- at thumbnail scale the result reads as isolated hand pieces around a cylinder rather than one continuous hand wrapping it;
- therefore it is materially below the `bar_v1` / `market_v1` support-hand intent.

### Meso / unobstructed anatomy — FAIL

`v86-support-anatomy.png` shows that the failure is not merely opaque-vessel occlusion:

- the four non-thumb chains curl downward into a hanging cluster rather than forming separated arcs around a cylindrical volume;
- the digit chains do not preserve the real-human index-light / middle-ring-pinky progressive enclosure grammar in a visually natural way;
- knuckle flow is still too claw-like/downward;
- thumb opposition is not integrated into a believable whole-hand grasp.

### Guide overlay

`v86-guide-overlay.png` remains useful only as diagnostic evidence. The cyan ContactPose ghost and the authored MPFB hand still disagree at the whole-hand silhouette/depth level. The ghost must not be used as final Macro acceptance.

## Evidence hashes from downloaded artifact

These hashes identify the exact reviewed bytes from artifact `9258931294`:

- `v86-support-thumbnail.png` — SHA-256 `e5583d6fb7c1090dadeac62f367e042fd9a3f5a49b92ab401ad2af31f351ea27`
- `v86-support-with-vessel.png` — SHA-256 `77e11fb936062f9bbeea3d4ff96d1902dba1050e6679f35828168968e334e697`
- `v86-support-anatomy.png` — SHA-256 `0542f6f62a0253e94e1f817f58585c0adf6c0f2242ade3214190846848320f49`
- `v86-guide-overlay.png` — SHA-256 `9b86c4ea297789a0cdcd4d4045c3028759154304598d7df061dbfa18db35a6bc`
- `v86-guide-thumbnail.png` — SHA-256 `af7bb920f9692f84bd9ed590871d51dc71365d62460653fba98b44d2b44b7182`
- `build.json` — SHA-256 `85c015ff7b17c8a926cda793e47227d1223d668d336e948db837c94d04035b18`

## New falsified assumption

Do **not** treat ContactPose anatomical closure angles as though they linearly equal `MPFB master grip + per-finger helper offset` in visual/anatomical effect.

The helper controls remain valuable as a higher-level authoring interface, but their numeric rotations are not a direct anatomical closure coordinate system. Matching the human angle numbers produced a visually over-curled/downward and heavily occluded hand instead of the target grasp.

This closes the tempting next path of sweeping semantic helper values until the numbers look closer.

## Updated do-not-repeat list

In addition to checkpoint 41:

- do not sweep `right_master_grip` / `right_finger*_grip` values to numerically fit ContactPose closure angles;
- do not claim `master + offset` degrees are equivalent to human MCP/PIP/DIP or screen-space enclosure angles;
- do not rescue v86 by moving the locked vessel/camera to make disconnected fingers look coherent;
- do not promote the guide/wire view instead of the opaque-vessel Macro view;
- do not start Micro skin/paper/glass work while the whole-hand support silhouette still fails.

## Current reds

### R1 — Whole-hand support grasp remains the dominant blocker

Need one visually authored native-rig pose in which:

- palm clearly sits beside the vessel;
- thumb visibly opposes the four fingers;
- index closes lightly;
- middle/ring/pinky progressively wrap toward/behind the far contour;
- the hand reads as a single continuous grasp at 192x108;
- unobstructed anatomy keeps web space, natural knuckle flow, separated arcs, and no obvious self-intersection.

### R2 — Godot product-camera proof

Still blocked behind R1. Only after R1 passes should the MPFB limb be compared with the current XR baseline in real bar/market product FOV and interaction states.

### R3 — Peel-hand pinch

Still blocked behind proving the support-hand pipeline.

### Micro

Skin PBR, paper fibers, glass optical polish, liquid, condensation, and other Micro work remain frozen.

## Next exact action

Return to the v85/v86 editable native-rig `.blend` as an **artist scene**, not as a numeric target solver.

Use the ContactPose ghost/wire view only to see depth and human finger ordering. Make exactly one direct whole-hand visual correction that coordinates wrist/palm placement with the semantic grip controls, then render the unchanged opaque vessel at 192x108 and the unobstructed anatomy view.

If that single visual candidate fails, reject it and improve the visual-authoring capability; do not convert the seven controls into another parameter sweep.

No product PR or production merge is allowed until the Macro and Meso gates pass.
