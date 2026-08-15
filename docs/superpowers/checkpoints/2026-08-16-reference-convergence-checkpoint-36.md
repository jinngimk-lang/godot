# Peel Calm reference convergence checkpoint 36

Date: 2026-08-16
Branch: `spike/mpfb-hero-limb-artist-direct-v78`
Production main baseline: `769d6452e75112084f537af99be90721c2629cd5`
Corrected artist code/pose head: `3beca92bf98b2dc79bd6011ae83a84485637d2f3`
Evidence-persisted branch head before this checkpoint: `38c3969b50af4825d38f1b6729b33b8dae48426b`
Godot Check: run `31915509260` — PASS
MPFB Artist Direct corrected run: `31915509197` — PASS
Visual artifact: `9254833555`
Locked acceptance references: `bar_v1`, `market_v1`

## Why this checkpoint matters

Checkpoint 35 rejected the first v78 screen-space artist gesture because it over-curled the four fingers into a claw. It explicitly allowed one evidence-derived correction and required the scripted/numeric authoring route to stop if that correction still failed to create a natural bottle support grip.

That correction has now been executed and visually inspected. The stop condition is met.

## What the corrected artist gesture changed

The v78 authoring bridge itself was left unchanged. No solver, search, score, contact objective or angle sweep was added.

Only the single committed artist handle set was redrawn from the first render evidence:

- proximal→intermediate→distal trajectories were made monotonic/smooth instead of reversing direction;
- camera-depth curl was reduced substantially;
- index remained the least closed;
- middle/ring/pinky were progressively directed farther toward the vessel side;
- wrist and the verified v74 thumb remained frozen.

## Exact verification

Godot Check run `31915509260` passed every configured gate on exact head `3beca92bf98b2dc79bd6011ae83a84485637d2f3`, including import/parse, default launch, unit tests, all presentation/ritual/reset/input smoke tests, reference-frame capture and artifact upload.

MPFB Artist Direct run `31915509197` also passed. Artifact `9254833555` contains:

- `support-wrap-v78-with-vessel.png`
- `support-wrap-v78-thumbnail.png`
- `support-wrap-v78-anatomy-oblique.png`
- `support-wrap-v78-anatomy-thumbnail.png`
- `support-wrap-v78-canonical-pose.json`
- `peel-calm-support-grasp-v78.blend`
- reports/logs and the reproducible v77 seed scene.

The direct-authoring bridge again preserved the frozen wrist/thumb exactly.

## Visual verdict — REJECT, but structurally informative

### Meso improvement

The corrected unobstructed anatomy render is a clear improvement over the first v78 gesture:

- the severe downward claw hooks are gone;
- proximal/PIP/DIP chains are substantially smoother;
- large kink/reversal artifacts are reduced;
- the hand reads more like one continuous MPFB limb than the earlier scripted claw candidates.

This proves the screen-space diagnostic was useful for identifying the zig-zag defect.

### Macro failure

The locked reference requirement is still not met. In the 192x108 vessel thumbnail the four non-thumb fingers now lie as a flattened, nearly parallel stack along the bottle rather than visibly enclosing its volume. The pose reads as **hand resting/sliding over a bottle**, not **human hand firmly gripping the bottle**.

The unobstructed anatomy render confirms why:

- insufficient three-dimensional separation between the four digit chains;
- inadequate far-side enclosure;
- web spaces collapse into a layered sheet;
- the frozen thumb is readable, but the four-finger mass does not form a convincing opposing cylindrical grasp.

Therefore the corrected candidate must **not** enter Godot product-camera staging or production.

## Closed route

The scripted fixed-camera artist-handle bridge has served its diagnostic purpose and is now closed as a pose-generation route. Continuing to change `tail_px` or `away_from_camera` values would be a disguised parameter search and would violate checkpoints 34–35.

Do not create v79/v80 as another numeric handle revision.

## Durable interactive handoff

Artifact `9254833555` contains `frames/peel-calm-support-grasp-v78.blend`, a native GameEngine-rig Blender scene at the corrected pose. The reproducible v77 builder and v78 apply script remain in Git, so artifact expiry does not lose the state.

The next pose change must be made **visually on the native rig as a whole shape**:

- keep `wrist.R` and `finger1-1/2/3.R` frozen initially;
- pose `finger2..finger5` directly in Blender Pose Mode;
- work from the locked bar/market support-grip intent, not from endpoint/contact metrics;
- index should close lightly around the near/far contour;
- middle and ring provide the strongest cylindrical enclosure;
- pinky closes deepest but remains separated;
- preserve visible knuckle flow and web spaces;
- ensure fingers disappear around the far bottle contour rather than stacking on its front face.

Any accepted interactive pose must be exported using the existing same-rig matrix-basis pose persistence path, then re-rendered at 192x108 and unobstructed anatomy before Godot integration.

## Capability note

The current automation runtime has no interactive Blender viewport/plugin available. Plugin discovery for Blender/3D rigging returned no installable connector. That is a tooling limitation, not permission or product ambiguity. Do not compensate by silently returning to automated angle/endpoint search.

## Current ranked reds

### R1 — Native-rig artist-authored four-finger enclosure

Highest priority and still open. Needs true visual posing, not another numerical search family.

### R2 — Godot bar/market product-camera proof against XR baseline

Blocked until R1 passes Macro/Meso staging.

### R3 — Peel-hand flap pinch

Blocked behind support-hand replacement proof.

### R4 — Micro polish

Skin/PBR, paper fibers, glass micro-highlights and condensation remain intentionally frozen.

## Do not repeat

All previously closed routes remain closed, plus:

- further `tail_px` screen-handle revisions;
- further `away_from_camera` depth tuning;
- calling a fixed numeric handle table "artist posing" after this point.

## Next exact action

Acquire/use a genuinely visual native-rig pose-editing path (interactive Blender viewport, equivalent direct-manipulation environment, or a new reference-derived anatomical pose source that is not a parameter optimizer). Start from the durable v78 `.blend`/same-rig pose, visually reshape the four-finger enclosure, and return to the exact 192x108 + unobstructed anatomy gate. Until that capability is available, preserve production `main` unchanged and do not spend cycles on Micro polish or reopen closed numeric grasp searches.
