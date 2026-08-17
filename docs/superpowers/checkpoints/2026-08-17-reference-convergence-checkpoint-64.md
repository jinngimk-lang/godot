# Peel Calm reference convergence checkpoint 64 — guided three-scene journey integrated

Date: 2026-08-17

## Stable production baseline

- Predecessor product flow merge: PR #98 `fix: make post-peel progression explicit and continuous`.
- PR #98 merged main head: `d037a3867cf18ebe598194baf70a528ab4f7abb3`.
- Fresh PR #98 merged-main Godot Check: `32001409817` — PASS.
- Fresh PR #98 merged-main runtime artifact: `9278523184` (`peel-calm-reference-frames`), digest `sha256:416080bd51df614cfb2f08dd9f62244cec50516b5bfbc68f4462baf4bef083bf`.
- Guided-journey product merge: PR #99 `feat: guide the café bar market journey`.
- Merged production code head: `3097fbd2251f3b08fd4e216397c648df66bc6d43`.
- Fresh merged-main Godot Check: `32002794280` — PASS.
- Fresh merged-main runtime artifact: `9278984219` (`peel-calm-reference-frames`), digest `sha256:663d7983a25a73affece401f0b1e7a710453dd4c819f7563e610cfe228bb9e85`.
- Locked acceptance references remain `cafe_v1`, `bar_v1`, `market_v1`; runtime captures remain evidence and do not replace the approved references.

## Loop completed in this checkpoint

After PR #98 made post-peel progression explicit, the remaining journey-level UX mismatch was that the three-scene product still exposed expert keyboard shortcuts without a persistent visual model of where the player was in Café → Bar → Market or how manual scene switching related to the main flow.

Hypothesis: add a presentation-only guided journey observer that exposes current scene/action plus pointer/touch scene navigation while preserving the existing `PeelLab` authority. Replace the large post-peel reward wall with the same journey/status system and align the existing Continue action with that rail. This should make progression legible without changing peel physics, hand pose, camera, labels, materials, or scene ownership.

## Candidate / TDD evidence

- PR #99 exact head: `e15f8ca94add8f59c65152fb9b614bb6d010d929`.
- RED exact head `1df809b...`: Godot Check `32001365347` failed at unit tests because the guided journey contract did not exist.
- Intermediate failures were treated as evidence rather than waived:
  - `32001555462`: test fixture parse issue; production import/launch already green; only the fixture typing was corrected.
  - `32001647556`: reached Reference scene smoke; the old smoke incorrectly required persistent `Q/E Scene` copy. It was upgraded to click Bar → Market → Café rail buttons and verify scene/product/reset ownership.
  - The first machine-green visual was rejected because the legacy Reward copy overlapped the new rail; the duplicate legacy chrome was removed before the final candidate.
- Candidate Godot Check `32002163309` — PASS across import, launch, unit, pointer-navigation reference smoke, presentation/reset/pause/input smokes, and nine-frame capture.
- PR-triggered exact-head Godot Check `32002282132` — PASS.
- PR-triggered runtime artifact: `9278810054`, digest `sha256:3b79fefc3cace8b7c4d5875cc8746b44e448a608a1b04c46798f7d464c377181`.

## Visual evidence inspected

Compared fresh pre-merge main artifact `9278523184` against PR #99 exact-head artifact `9278810054`, then re-inspected fresh merged-main artifact `9278984219`.

Frames inspected:

- `cafe.png`
- `cafe_peel38.png`
- `cafe_crumple55.png`
- `bar.png`
- `bar_inspect.png`
- `bar_peel48.png`
- `market.png`
- `market_inspect.png`
- `market_peel45.png`

Verdict: scoped journey/presentation improvement accepted.

- Base frames now expose a compact three-scene rail with the current scene visibly selected.
- The top guide exposes current scene and current action without requiring expert shortcut knowledge.
- In `cafe_crumple55`, the old large centered `CLEAN RELEASE / next scene unlocked / optional squeeze` reward block is replaced by the same journey/status language, with the existing Continue button aligned beside the scene rail.
- The rail does not change hero-object placement, camera, hand choreography, peel state, inspect state, or crumple state.
- The fresh merged-main frames preserve the exact candidate presentation and do not show an integration-only regression.

This is a UX/presentation convergence improvement, not a claim that hero visual quality is complete.

## Independent Challenger

- Local Challenger reviewed exact PR #99 head `e15f8ca94add8f59c65152fb9b614bb6d010d929`.
- Result: `VERDICT: VERIFIED`, `DEFECT: NONE`, `MIN_TEST: NONE`.
- PR #99 was merged only after unchanged-head Godot PASS + real runtime A/B + Local Challenger VERIFIED.
- Merge used expected-head protection.

## Multi-scale status after merge

### Macro — still RED

1. **R1 hero support-hand anatomy / vessel enclosure remains the largest reference mismatch.** Current XR hands are still faceted/open and do not read as a natural human grip around the cup/bottles.
2. The stop condition remains active: do not resume CCD, endpoint chasing, semantic-grip sweeps, wrist/orbit/yaw/translation grids, or other disguised numeric hand-pose search without live native-rig visual authoring or a structurally better hand asset/source.

### Meso

- Three-scene journey/progression legibility: improved and integrated.
- Post-peel Continue is explicit and continuous after PR #98.
- Peel-hand whole-hand pinch remains below reference quality.
- Existing vessel/label/contact/ice/glass improvements remain accepted unless fresh runtime evidence shows regression.

### Micro

Skin, paper-fiber density, photographic glass/residue/condensation polish remain lower priority while Macro/Meso reds remain.

## Do not repeat

- Do not reintroduce persistent `Q/E` or `1/2/3` shortcut copy as the primary scene-navigation model; the shortcuts may remain functional but the journey rail owns visible scene navigation.
- Do not reintroduce a duplicate large Reward wall over the journey/status UI.
- Do not use CI green or cleaner navigation as evidence that R1 hand anatomy/enclosure is solved.
- Do not resume blind numeric hand-pose search.

## Next exact action

At the next run, first inspect the newest exact-main nine-frame artifact and current capability surface. If live Blender/native-rig visual authoring is available, return immediately to R1 and author exactly one direct-visual support-grasp candidate using the existing stop-condition-safe workflow. If that capability is still unavailable, rank fresh interaction-step frames and choose one independent, objective Macro/Meso structural defect that does not require violating the R1 stop condition. Do not begin decorative Micro polish merely because hand authoring is blocked.
