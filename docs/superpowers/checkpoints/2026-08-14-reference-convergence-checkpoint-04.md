# Peel Calm reference convergence checkpoint 04

Date: 2026-08-14
Merged production baseline: `main@769d6452e75112084f537af99be90721c2629cd5`
Source PR: #49 (`feat/reference-multiscale-loop-v1@f43f0e229ce7989d8febddc6fa753422565cadbb`)
Post-merge Godot Check: run `31810098509` — PASS
Post-merge runtime frame artifact: `9222768455` (`peel-calm-reference-frames`)
Acceptance set: `cafe_v1`, `bar_v1`, `market_v1`

## Closed integration gate

PR #49 is merged. Before merge, exact product head `f43f0e229ce7989d8febddc6fa753422565cadbb` had a green Godot Check and aligned nine-frame runtime artifact. The persisted independent Challenger V2 reports normalized both focused passes to `VERDICT: VERIFIED` / `DEFECT: none`.

The V2 workflow's final gate exited 1 because Ollama spinner/ANSI control text preceded the normalized verdict and the gate parser expected a clean line start. That was verifier-format infrastructure failure, not a reproduced product defect. The reports were inspected before merge rather than treating the failed workflow status as product evidence.

Post-merge `main@769d6452...` reran the full Godot Check successfully and produced a fresh same-head frame artifact, so the squash integration is the new stable baseline.

## Current highest visual reds

### R1 — continuous realistic hand/wrist/forearm anatomy

The locked references show a continuous human limb. Current runtime still reads as an XR hand plus separately generated forearm. This remains the dominant Macro/Meso mismatch.

### R2 — photographic vessel-wrap and label-flap pinch poses

Current authored XR poses are functionally correct but remain stock/VR-like. A replacement limb must support natural support-hand opposition around the vessel and actual thumb/index contact on the lifted flap.

### R3 — skin/nail PBR

Keep deferred until R1/R2 pass. Do not spend the next loop on micro-surface polish while anatomy/pose remain structurally wrong.

## MPFB model escalation evidence

An older isolated branch `spike/mpfb-hero-limb-v1` had already proved the source pipeline:

- pinned MPFB `2.0.17`;
- pinned Blender `4.2.0`;
- generated source mesh: 19,158 vertices / 18,486 polygons;
- GameEngine rig: 53 bones;
- separate weighted groups exist for `upperarm`, `lowerarm`, `hand`, and every finger chain on both sides;
- exported GLB size: 1,375,224 bytes;
- clean Blender re-import passed;
- Godot 4.7.1 import/inspection passed.

Its visual preview failed only because the Ubuntu runner lacked `libEGL.so.1`; source generation itself was not the failing step.

## MPFB v2 anatomy gate — PASS TO NEXT SPIKE STAGE

Branch: `spike/mpfb-hero-limb-v2`
Base: merged `main@769d6452e75112084f537af99be90721c2629cd5`
Visual candidate head: `0018ceee93a34f47b7c2c69fa8135bf78c64d145`
MPFB anatomy preview run: `31810528786` — PASS
Visual artifact: `9222989264` (`mpfb-hero-limb-preview-v2`)

The v2 spike replayed only the model builder/preview tooling onto merged main and fixed the known headless-render root cause by installing `libegl1`. The full preview job then passed: runtime install, pinned Blender/MPFB install, candidate build, all three fixed-camera renders, and artifact upload.

Inspected frames:

- `right_hand_front.png`;
- `right_hand_oblique.png`;
- `right_forearm_oblique.png`.

### Macro/Meso verdict

**PROMISING — continue, but do not promote to gameplay yet.**

Positive evidence:

- hand, wrist, and forearm are one continuous human surface rather than separate XR hand + generated tube;
- wrist transition is structurally coherent;
- finger volumes and palm silhouette are materially less faceted/prototype-like than the current XR runtime hand;
- the GameEngine skeleton/weights give a credible path to authored vessel-wrap and pinch poses.

Remaining problems visible in the neutral preview:

- pose is still default/open and does not yet prove vessel wrap or label pinch;
- oblique preview includes torso geometry, so gameplay integration must extract/retain only the useful limb region or keep hidden body geometry out of view;
- simple diagnostic skin material is over-bright and intentionally not a production PBR judgment;
- the forearm still needs gameplay-camera pose/framing comparison before it can close R1.

This is enough improvement to justify the next structural stage. It is not evidence that R1/R2 are closed.

## Next exact action

1. Build a reproducible left/right hero-limb extraction path using the existing `upperarm`, `lowerarm`, `hand`, and finger weight groups; do not ship the whole body mesh.
2. Preserve enough upper-arm geometry beyond the gameplay crop so no open seam enters frame.
3. Build two deterministic pose previews before production integration:
   - support-hand vessel wrap with thumb/fingers visibly opposing around a cylinder matching bottle/cup scale;
   - peel-hand label pinch with thumb/index meeting a small flap proxy.
4. Render those pose previews at fixed cameras and reject if the silhouette is still stock/open/claw-like.
5. Only after the pose gate passes, import extracted limbs into Godot on a separate product branch and map them into `HandChoreographyPresentation` / café ownership without reintroducing multiple transform writers.
6. Capture café/bar/market base + affected interaction states on exact head and compare Macro/Meso against locked references.
7. Keep skin/PBR, paper fibers, and glass micro-detail deferred until the limb candidate visibly improves real gameplay frames.
8. Require provenance, polygon/material budget, Godot import/performance, exact-head CI, fresh runtime frames, and independent Challenger before production promotion.

Do not return to XR subdivision or procedural tube-forearm tuning unless new evidence invalidates checkpoint 03/04.
