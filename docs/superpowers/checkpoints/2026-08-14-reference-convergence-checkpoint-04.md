# Peel Calm reference convergence checkpoint 04

Date: 2026-08-14
Merged production baseline: `main@769d6452e75112084f537af99be90721c2629cd5`
Source PR: #49 (`feat/reference-multiscale-loop-v1@f43f0e229ce7989d8febddc6fa753422565cadbb`)
Post-merge Godot Check: run `31810098509` — PASS
Post-merge runtime frame artifact: `9222768455` (`peel-calm-reference-frames`)
Acceptance set: `cafe_v1`, `bar_v1`, `market_v1`

## Closed integration gate

PR #49 is now merged. Before merge, exact product head `f43f0e229ce7989d8febddc6fa753422565cadbb` had a green Godot Check and aligned nine-frame runtime artifact. The persisted independent Challenger V2 reports normalized both focused passes to `VERDICT: VERIFIED` / `DEFECT: none`.

The V2 workflow's final gate still exited 1 because Ollama spinner/ANSI control text preceded the normalized verdict and the gate parser expected a clean line start. That was verifier-format infrastructure failure, not a reproduced product defect. The reports were inspected before merge rather than treating the failed workflow status as product evidence.

Post-merge `main@769d6452...` reran the full Godot Check successfully and produced a fresh same-head frame artifact, so the squash integration is the new stable baseline.

## Current highest visual reds

### R1 — continuous realistic hand/wrist/forearm anatomy

The locked references show a continuous human limb. Current runtime still reads as an XR hand plus separately generated forearm. This remains the dominant Macro/Meso mismatch.

### R2 — photographic vessel-wrap and label-flap pinch poses

Current authored XR poses are functionally correct but remain stock/VR-like. A replacement limb must support natural support-hand opposition around the vessel and actual thumb/index contact on the lifted flap.

### R3 — skin/nail PBR

Keep deferred until R1/R2 pass. Do not spend the next loop on micro-surface polish while anatomy/pose remain structurally wrong.

## MPFB model escalation evidence recovered

An older isolated branch `spike/mpfb-hero-limb-v1` already proved the source pipeline rather than merely documenting it:

- pinned MPFB `2.0.17`;
- pinned Blender `4.2.0`;
- generated source mesh: 19,158 vertices / 18,486 polygons;
- GameEngine rig: 53 bones;
- separate weighted groups exist for `upperarm`, `lowerarm`, `hand`, and all finger chains on both sides;
- exported GLB size: 1,375,224 bytes;
- clean Blender re-import passed;
- Godot 4.7.1 import/inspection passed.

The old fixed-camera preview workflow failed before producing PNGs because the Ubuntu runner lacked `libEGL.so.1`, so that branch did not yet have visual anatomy evidence. Source generation itself was not the failing step.

## New isolated spike

Branch: `spike/mpfb-hero-limb-v2`
Base: merged `main@769d6452e75112084f537af99be90721c2629cd5`
Current head at checkpoint creation: `0018ceee93a34f47b7c2c69fa8135bf78c64d145`

Replayed only the model-spike builder/renderer onto the merged baseline and fixed the known preview runtime root cause by explicitly installing `libegl1` before Blender rendering.

Current MPFB anatomy preview run: `31810528786`.
At checkpoint time, headless runtime install, pinned Blender/MPFB install, and source-candidate build are PASS; fixed-camera anatomy rendering is executing.

## Next exact action

1. Inspect run `31810528786` completion and download its visual artifact.
2. Inspect `right_hand_front`, `right_hand_oblique`, and `right_forearm_oblique` at thumbnail and native scale.
3. Reject MPFB immediately if continuous wrist/forearm silhouette and hand anatomy are not materially better than the XR baseline.
4. If anatomy passes, create a reproducible hero-limb extraction/pose path using the existing hand/lowerarm/upperarm and finger weight groups; do not integrate the whole body into gameplay.
5. Build support-wrap and peel-pinch candidate poses before skin/PBR work.
6. Import candidate into Godot on a separate product branch, capture the same café/bar/market base + interaction states, and compare Macro/Meso against the locked references.
7. Promote only with exact-head CI, runtime-frame improvement, provenance/performance checks, and independent Challenger evidence.

Do not return to XR subdivision or procedural tube-forearm tuning unless new evidence invalidates checkpoint 03/04.
