# Reference Convergence Checkpoint 82 — Quiet JourneyRail during inspection

Date: 2026-08-18

## Recovery source

At the start of this run the repository source of truth was:

- `main@0b966dd7af272c08968bbaa3a2e2caf55c45e27c`
- newest checkpoint: `2026-08-18-reference-convergence-checkpoint-81.md`
- exact-main Godot Check `32062106569` — PASS
- exact-main runtime artifact `9298516937`
- no open PRs

The master prompt v3 and `.agents/skills/multiscale-reference-convergence/SKILL.md` were reread before implementation.

## Highest visible red and scope chosen

R1 remains the dominant Macro red: the current XR support hand still lacks reference-quality palm volume, progressive finger depth, thumb opposition, and true vessel enclosure. Existing stop conditions remain active: do not resume CCD, endpoint chasing, grip-number, wrist/orbit/yaw/translation, per-finger numeric grids, subdivision-density sweeps, or the rejected fixed-Cup CC0 source without genuinely different visual-authoring capability.

Live native-rig/Blender visual authoring is still unavailable in this environment, so this run selected an independent interaction-frame Macro/UI red: fresh `bar_inspect` and `market_inspect` still showed the approximately `588×50` bottom JourneyRail during RMB inspection, consuming lower-frame negative space while the product should own the frame.

## Falsifiable hypothesis

If Journey presentation derives rail visibility from the existing inspection state, the rail must hide during inspection, return afterward when peel has not begun, remain available before engagement for pointer/touch navigation, and preserve the existing active-peel hide behavior. Fixed reference-frame inspection evidence must exercise the same contract without taking gameplay authority.

## RED

Branch: `fix/inspection-journey-rail-v82`

RED exact head: `fdf05843c63d226c2f77264d7daf93aebf9640bc`

`tests/test_guided_journey_presentation.gd` was extended to require `set_inspection_active()` and assert hide/restore behavior.

Godot Check `32066969849` failed cleanly at Unit tests after import and configured default launch passed.

## First implementation and evidence-path correction

First implementation head `73906c39f2d0bd029247e12016dd21d2617cfe93`; Godot Check `32067146313` — PASS.

It added `_inspection_active`, exposed `set_inspection_active(active)`, read the existing `InspectionController.is_active()` state from the parent lab, and rendered the rail only when normal journey visibility and non-inspection conditions were both true.

Code inspection then found that `tests/capture_reference_frames.gd` freezes guide processing during fixed inspect capture and directly applies product yaw. A live-only `_inspection.is_active()` hook could therefore pass the deterministic contract while leaving the inspection screenshot unchanged. This was treated as an evidence-path gap, not permission to modify gameplay or fake screenshots.

## Final GREEN candidate

Final exact candidate: `92965ee762ce723cc6020218af24f3cfb81d7548`

`GuidedJourneyPresentation.set_state()` additionally recognizes non-zero visible Cup yaw as fixed-capture inspection evidence while the guide process is frozen. Runtime `_pull_runtime_state()` still overwrites inspection state from the real `InspectionController`, so gameplay authority is unchanged.

No camera, product, hand, label, peel physics, input semantics, timer, punishment, or economy changed.

- Push Godot Check `32067280786` — PASS
- candidate runtime artifact `9300388027`
- candidate artifact digest `sha256:159d89f7cac281f1908a89cf2c1b7a6dbf89d8608ce6bd18da114fadba68f590`
- PR #138 exact-head Godot Check `32067431454` — PASS

## Runtime visual verdict

Exact candidate frames were inspected directly:

- `bar_inspect.png`: bottom JourneyRail gone; amber bottle and lower-frame negative space no longer compete with persistent navigation chrome.
- `market_inspect.png`: bottom JourneyRail gone; inspection state owns the lower frame.
- `market.png`: JourneyRail remains visible before engagement, preserving pointer/touch navigation.
- active-peel states remain rail-free under the existing checkpoint-80 contract.

No meaningful regression was observed in vessel framing, hand staging, label state, camera/background, or interaction silhouettes. This closes only the scoped UI ownership red; R1 is not closed.

## Independent Challenger

Local Independent Challenger run `32067496624` reviewed unchanged exact head `92965ee762ce723cc6020218af24f3cfb81d7548`. Exact-head validation, packet construction, schema review, deterministic grounding, PR comment, and enforcement all passed.

Grounded verdict:

- `VERDICT: VERIFIED`
- `DEFECT: NONE`
- `MIN_TEST: NONE`

## Merge and fresh-main proof

PR #138 was squash-merged with expected-head protection.

Merged product commit: `35fda46a1d5ba921804074845db1394b77c10a7c`

Fresh merged-main proof:

- Godot Check `32067879079` — PASS
- runtime artifact `9300605391`
- digest `sha256:0bdcbd0807f332db8fa19e2ab7634a02bffd9af7883e5660dd79278d3e3dd85c`

Fresh merged `bar_inspect.png` and `market_inspect.png` were re-inspected: the bottom rail remains absent. Fresh merged `market.png` still shows the rail before engagement. The scoped visual gain survives the actual merge tree.

## Closed red

Closed here:

- bottom JourneyRail no longer occupies active RMB/fixed-reference inspection frames;
- rail returns after inspection when peel has not begun;
- pre-engagement pointer/touch navigation remains available;
- existing active-peel rail hiding remains intact.

## Remaining reds

1. **R1 Macro — hero support-hand anatomy / true vessel enclosure.** XR hands remain low-poly/open and lack natural palm volume, progressive finger depth, web space, and readable thumb opposition.
2. **Café crumple Meso — exact visible hand-to-crumpled-shell contact.** Checkpoint 81 intentionally leaves a small visible air gap; do not resume root-offset sweeps.
3. **R2/Meso — whole-hand peel pinch quality and full-hand following of the lifted flap.**
4. **Micro — skin, paper fibre, glass/liquid, residue and condensation detail.** Frozen while lower-frequency reds dominate.

## Failed / rejected / prohibited repetition

- A live-only inspection-state hook was insufficient for fixed screenshot evidence because capture freezes guide processing and stages inspect through visible product yaw; the final implementation aligns evidence with the real contract without changing gameplay authority.
- Do not start a JourneyRail size/opacity/position sweep; this ownership problem is closed.
- Do not resume banned numeric hand-pose searches: CCD, endpoint chasing, grip-number, wrist/orbit/yaw/translation grids, per-finger grids, subdivision-density sweeps, or the rejected fixed-Cup CC0 source.
- Do not convert this UI win into Micro polish while R1 remains dominant.

## Next exact action

1. Re-check for trustworthy live Blender/native-rig visual-authoring capability. If available, return immediately to R1 whole-hand support-grasp authoring against the locked references.
2. If unavailable, inspect fresh merged-main interaction frames from artifact `9300605391` and select the next independent, objective Macro/Meso structural red.
3. Keep interaction-step frames in the evidence set; do not judge only base scenes.
4. Preserve numerical-pose and Micro-polish stop conditions until a lower-frequency gate actually closes.
