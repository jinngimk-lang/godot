# High-fidelity hand spike — subdivision candidate result

Date: 2026-08-14
Branch: `spike/high-fidelity-hand-v1`
Candidate workflow head: `6c1516518526638fc7ebc5d427189e37b7ef288c`
Workflow: `High Fidelity Hand Spike` run `31790770701` — PASS
Artifact: `high-fidelity-hand-candidate`, id `9215414320`
Acceptance set: `cafe_v1`, `bar_v1`, `market_v1`

## What was tested

A reversible Blender pipeline imported the existing repository-local CC0 Godot XR Tools hand GLBs, applied one Catmull-Clark subdivision level before the armature modifier, set smooth polygons, preserved the 26-bone armature and authored animation library, and exported new GLBs. The candidate GLBs replaced the production paths only inside the CI checkout.

### Geometry report

Both hands:

- source render vertices: `3,794`
- candidate render vertices: `20,662`
- source polygons: `6,540`
- candidate polygons: `19,620`
- armature: `26` bones preserved
- animation/action report: `70` imported action/NLA names retained, including `Cup`, `Grip`, `Hold`, `Pinch Tight`, `Pinch Up`, and related actions
- candidate GLB size: about `1.94 MB` per hand vs about `0.88 MB` source

## Technical verdict

**PASS as an experiment.**

The candidate:

- built deterministically in CI;
- imported in Godot 4.7.1;
- preserved the authored-hand contract;
- passed deterministic unit tests;
- passed scene, forearm, ritual, and repeated-reset smokes;
- produced the full nine-frame reference capture matrix.

## Visual verdict

**REJECT for production.**

Direct `target vs baseline vs subdivision-candidate` comparison shows:

### Macro

No meaningful improvement. The same hand-to-vessel scale, claw-like silhouette, detached support grip, and long straight procedural forearm remain.

### Meso

Only minor surface smoothing. Finger curl, thumb opposition, palm orientation, wrist transition, and forearm anatomy remain materially unlike all three acceptance references.

### Micro

Faceting is reduced, but that improvement is too small to justify the ~5.4× render-vertex increase and >2× GLB size while Macro/Meso remain wrong.

## Decision

Do **not** promote the subdivided GLBs to production.

The next model candidate must be structurally different and cover the entire visible tactile limb, not just add polygons to the existing hand. The target is a continuous hand/palm/wrist/forearm silhouette with a usable rig/pose path.

Preferred next approaches:

1. reproducible MakeHuman/MPFB rigged human/arm pipeline using Blender >=4.2;
2. a repository-derived integrated hand+forearm mesh that extends the existing CC0 rig without a visible procedural tube;
3. image/multiview reconstruction only if it can also pass topology, rigging, license, and performance gates.

Keep the existing subdivision builder as evidence/research tooling; it is not a production dependency.
