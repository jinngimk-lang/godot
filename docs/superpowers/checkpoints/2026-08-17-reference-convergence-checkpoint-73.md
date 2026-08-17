# Peel Calm reference convergence checkpoint 73

Date: 2026-08-17
Reference family: locked `art/acceptance_refs/v1` Café / Bar / Market

## Production baseline

- `main`: `90d225fcd124cbd80f2fe2d84222584ee4324a3a`
- latest product merge: PR #118, `fix: slow clean peel to a tactile cadence`
- PR #118 exact candidate: `78621616f0957c4407d474318a175a3e89705afa`
- PR #118 Local Challenger: round 1 `VERIFIED / DEFECT: NONE`
- fresh merged-main Godot Check: `32017680959` — PASS
- fresh merged-main reference-frame artifact: `9284148422`
- artifact digest: `sha256:85d8e45028e81c23024a668a621cd84170a577fb11dd87a096f5450e41a3605a`

PR #118 changes tactile peel pacing only. It does not close a reference-image Macro red.

## Current multiscale ranking

### R1 — Macro, still dominant

Hero support-hand anatomy / vessel enclosure remains the largest reference mismatch. Current production hands are visibly open and stylized compared with the locked reference: palm volume, thumb opposition, progressive finger depth and true vessel wrap remain insufficient.

The prior stop conditions remain mandatory: do not resume CCD, endpoint chasing, semantic grip sweeps, wrist/orbit/yaw/translation grids, per-finger numeric grids, or subdivision-density sweeps.

### R2 — Meso

Whole-hand peel pinch/contact still needs a more realistic hand source/pose after R1 support anatomy is structurally solved.

### Micro

Skin response, paper fiber, glass highlight breakup and condensation remain deferred while R1 is red.

## New structural model experiment — CC0 MakeHuman-derived support hand v94

Branch: `spike/cc0-makehuman-support-hand-v94`
Closed staging PR: #119

This was an allowed structural-source escalation after subdivision-only failed. It used a pinned CC0 MakeHuman-derived FPS arm source and a fixed native `Cup` pose rather than tuning the old authored XR hand.

### Pre-alignment failure

A scale-corrected candidate passed the full Godot machine gate in run `32020404963`, artifact `9285129666`, but fresh Café runtime evidence rejected it: a large bare source forearm crossed the hero composition and the fixed Cup pose wrapped empty air beside the cup. CI green was not treated as visual acceptance.

### One allowed structural frame correction

A one-off Godot diagnostic measured the real Café cup frame in `LeftHand/AuthoredHand` space in run `32020753168`. `tools/support_hand_cafe_target_v94.json` pins the measurement.

The aligned builder then made exactly one algebraic source-frame mapping and changed crop semantics from a spatial threshold to actual hand/finger skin-bone membership. No pose grid, CCD, endpoint optimization, grip sweep, wrist/orbit/yaw/translation sweep or subdivision sweep was introduced.

Build run `32021039608` passed its structural assertions. The aligned binary commit was `9b78bb14758e9d5987027b04b2d48dd48c30de29`; an evidence-only follow-up produced exact visual head `2dfd311e49b08bc95e57693604b67f1d8a73af74`.

### Exact-head machine proof

- Godot Check: `32021188945` — PASS
- exact-head reference-frame artifact: `9285407406`
- digest: `sha256:6f686a30316e077fc48c365959480da2768c13bbd2ae41fe0138d06cc4010ba8`
- inspected frames: `cafe.png`, `cafe_peel38.png`, `cafe_crumple55.png`, `bar.png`, `bar_inspect.png`, `bar_peel48.png`, `market.png`, `market_inspect.png`, `market_peel45.png`

### Visual verdict — REJECT

The algebraic alignment removes the earlier giant/off-frame placement failure, but the source still fails the mandatory Macro gate.

- Café: the hand reads as an open/claw-like shape beside the cup; palm contact, four-finger enclosure and reference-like thumb opposition are not established at thumbnail scale.
- Bar / Market: several frames expose a long forearm without a convincing enclosing support-hand silhouette at the vessel, making the two-hand composition less credible than current main.
- The improvement is therefore not a reference-convergence improvement despite the exact-head Godot PASS.

PR #119 was closed without merge. No Challenger was run because the mandatory visual gate failed first.

## Closed / do-not-repeat paths

In addition to checkpoint 72's list, now explicitly reject:

1. subdivision-density-only upgrades of the existing authored hand;
2. this CC0 FPS-arm source's fixed native Cup pose as a direct production support-hand replacement;
3. further scale / frame / wrist / orbit / yaw / translation / per-finger searches around the v94 source;
4. treating successful algebraic target alignment or CI green as evidence of anatomical enclosure.

Keep the v94 branch as provenance/build evidence only.

## Next exact action

Return to R1 only through a **structurally different** path that can change whole-hand anatomy/enclosure rather than merely re-place this rejected pose. Preferred order:

1. live native-rig visual authoring when a trusted Blender/rigging viewport capability is actually available; or
2. a different provenance-safe hand/arm source whose authored grasp already shows palm contact, progressive index→pinky depth and clear thumb opposition before Godot integration.

Any new external/generated model remains staging-only until provenance/license, topology, UV/PBR, rig/pose, polygon/material budget, Godot 4.7.1 import, performance and locked-camera screenshot gates pass.

If neither structural route is available in the runtime, choose the next independent objective Macro/Meso defect from fresh main interaction frames. Do not descend into decorative Micro polish merely because R1 is temporarily tool-blocked.
