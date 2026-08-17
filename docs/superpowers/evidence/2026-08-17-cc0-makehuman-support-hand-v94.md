# CC0 MakeHuman support-hand v94 — structural candidate gate

Date: 2026-08-17
Base product main: `90d225fcd124cbd80f2fe2d84222584ee4324a3a`
Initial candidate binary commit: `5d586b52cfe94df04cc8e15df21a860f9717a997`
Reference-envelope rescale commit: `8f12fe57c835e03f85a0177a75722e03b95f5355`
Measured-frame aligned candidate: `9b78bb14758e9d5987027b04b2d48dd48c30de29`
Role-semantic scaling fix: `a27b5a012ef8c026db176cb3625e9a4d6bb409e5`
Authoring branch: `spike/cc0-makehuman-support-hand-v94`

## Why this spike exists

The locked Café reference still has one dominant Macro mismatch: the support hand should visibly wrap the paper cup with palm volume, four-finger enclosure, and thumb opposition. The existing Godot-XR-derived support hand remained open / side-contacting. Checkpoint 72 rejected a rig-preserving subdivision of that old hand because it improved smoothing only and did not improve the support-grasp anatomy.

This v94 spike changes the *source structure* rather than tuning the old pose. It uses a rights-safe CC0 MakeHuman-derived FPS arm rig whose native Blender controls were independently inspected and whose fixed native frame 20 produced a semantic cup-proxy preview with palm contact, finger enclosure, and thumb opposition.

## Non-negotiable stop condition

This spike does not authorize CCD, endpoint chasing, wrist/orbit/yaw/translation sweeps, per-finger numeric grids, or other disguised pose search. One fixed source-rig Cup pose is tested in the current runtime. A single evidence-driven structural frame correction is permitted when a runtime capture proves the source frame is not mapped to the existing cup frame; a grid is not.

## Build / failure / correction receipts

### Structural source build

The first successful source-normalization build produced a left-only GLB with:

- selected substantial source component: 2,049 vertices / 2,038 polygons;
- 1,621 vertices / 1,609 polygons after the original spatial arm-side crop;
- 50-bone armature;
- semantic actions `Default pose`, `Pinch Up`, `Cup`, `Pinch Tight`;
- 20 real fingertip polygons on `HandNail`.

The first Godot candidate passed import, default launch, and deterministic unit tests, including the authored-hand asset contract, but failed `Scene smoke`: runtime support-hand mesh extent was `1.719`, above the existing `<=1.40` hero-hand presentation envelope. The tests were not changed.

### One scale-only correction

The source scale was corrected once from measured mesh envelope data, without changing pose/position/rotation/finger values. That rebuilt GLB passed the complete Godot 4.7.1 machine gate and produced nine fresh runtime frames in run `32020404963`, artifact `9285129666`.

The visual gate **rejected** that machine-green candidate. Fresh `cafe.png` showed two Macro failures:

1. a large bare source forearm crossed the hero composition despite the intended wrist crop;
2. the fixed frame-20 hand curled around empty air on the cup's right side instead of enclosing the cup.

Machine green was therefore not treated as visual acceptance.

### Structural root cause 1 — crop semantics

The spatial `z` crop was removed. The aligned builder deletes vertices only when they have no non-trivial skin membership in the real left hand/palm/thumb/index/middle/ring/pinky deform groups. Build run `32021039608` reports 1,657 vertices retained by actual hand/finger skin bones, 392 vertices removed as forearm-only, and 1,632 final polygons. The second visual capture confirmed that the bare source forearm was removed.

### Structural root cause 2 — semantic Cup frame mismatch

A one-off Godot diagnostic measured the actual Café cup target directly in `LeftHand/AuthoredHand` local space at run `32020753168`, pinned in `tools/support_hand_cafe_target_v94.json`. The fixed native frame-20 Cup pose was then mapped to that measured frame by one orthonormal rigid transform, with no search loop.

Aligned build run `32021039608` / artifact `9285359168` proved the algebraic mapping with center error `6.13e-08`, radial dot `1.00000009`, and axis dot `1.00000008`. The bot committed that binary as `9b78bb14758e9d5987027b04b2d48dd48c30de29`.

Exact-head Godot Check `32021188945` was FULL PASS, artifact `9285407406`, but the visual gate again rejected the candidate: the support hand was now cleanly cropped yet still hovered to the cup's left rather than enclosing it.

### Structural root cause 3 — support role was incorrectly using peel-hand pinch preservation

The second runtime failure exposed a production semantic bug outside the asset. `ForearmPresentation._apply()` scaled both RightHand and LeftHand through `_scale_hand_preserve_pinch()`. That helper preserves the thumb/index pinch world anchor by translating the entire `HandVisual` root after changing `AuthoredHand` scale to `4.15`.

That behavior is appropriate for the dynamic right peel hand, but it is wrong for the left support hand: the left root is already staged around the vessel, and translating it to preserve a pinch anchor invalidates any authored Cup frame.

A deterministic TDD contract was added in `tests/test_support_hand_scale_semantics.gd`. Exact RED Godot Check `32021429493` passed import/default launch and failed Unit only with:

`SUPPORT_SCALE_RED: support-hand authored scaling needs a root-preserving path distinct from peel-hand pinch preservation`

The production fix was applied by exact text patch workflow `32021617985` and committed as `a27b5a012ef8c026db176cb3625e9a4d6bb409e5`:

- RightHand still uses `_scale_hand_preserve_pinch()`;
- LeftHand now uses `_scale_support_hand_keep_root()`;
- the new support helper scales only `LeftHand/AuthoredHand` to the same `4.15`, and never translates the staged `LeftHand` root.

This evidence commit exists to trigger the full Godot GREEN check on that role-semantic fix. If green, the Café target frame must be re-measured under corrected semantics before rebuilding the same fixed native frame-20 Cup pose. The old target measurement must not be reused after removing the root translation.

## Machine gate

The exact candidate head must pass the existing Godot 4.7.1 contract without weakening it: import/parse, default launch, deterministic tests, authored-hand asset contract, reference/café/forearm/reset/input smokes, and fresh nine-frame capture.

## Visual gate — locked Café reference

Accept structurally only if the left palm contacts the cup, fingers wrap the vessel silhouette, thumb opposition is legible, hand scale is human, bare source forearm is absent, and wrist/sleeve continuity is not a new dominant Macro defect. Machine green alone is insufficient.

Reject if the hand is mirrored/inverted/off-scale, still wraps empty air, exposes a dominant bare forearm, only improves mesh quality without enclosure, or requires weakening machine gates.

## What a structural pass would mean

A structural pass would not complete Stage 1. It would only prove a better support-hand source. Remaining high-value work includes material/skin realism, semantic wrist-to-sleeve integration if needed, and the peel-hand pinch/contact lane. Final completion still requires locked-reference convergence and owner playtest.
