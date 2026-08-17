# Reference Convergence Checkpoint 76 — full bottle reference framing

Date: 2026-08-17

## Resume source

- Product `main` after PR #126: `9c3abdcf609e38ac8c439ec65cb7fcfaa6d24960`.
- Fresh merged-main Godot Check: run `32034880885` — PASS.
- Fresh merged-main nine-frame artifact: `9290277838`, digest `sha256:a5b77d7c261e4640552fe7d29329fdaae3e63d8b8d92ad21850cc2155347a378`.
- Previous checkpoint: checkpoint 75 on `main@692eb234d71d9148142ddc39c3fefcc905b3ee95`, runtime artifact `9289507971`.
- Locked user-approved café / bar / market references remain the acceptance source of truth. Runtime frames are comparison evidence, never replacement references.
- Live/native-rig Blender or 3D rigging connector was re-checked in this run and remains unavailable. R1 numeric hand-pose search stop conditions therefore remain active.

## Closed scoped Macro red — tall bottle framing was over-cropped

Fresh checkpoint-75 `bar` / `market` frames used the same 39° close-up lens as the shorter café cup. The tall amber/clear product meshes reached or crossed the top edge and visually occupied most of the 720p frame, conflicting with `ReferenceComposition`'s own close-up contract that the hero vessel should occupy roughly one-half to two-thirds of frame height while preserving venue context.

The café cup was already fully framed and should not move.

### Falsifiable hypothesis

Keep the approved café close-up at 39°, but use one bounded 48° lens for amber/clear bottle presentation. This should restore the complete bottle mouth/top and contextual breathing room without changing vessel geometry, scale, table grounding, hand pose, label contact, peel physics, materials, progression, timers, punishment, or economy.

## RED

Isolated branch: `fix/bottle-reference-framing-v76`.

- RED head: `68a0cf3844a60f910f1173a22f9b983e819cf86b`.
- Godot Check `32033987131` — expected FAILURE at deterministic Unit tests after static guard, validator self-test, Godot install, import/parse and default launch passed.
- New contract required live café framing to remain 39° and bottle framing to stay within 47–50°.

## Evidence-ownership correction before merge

The first GREEN encoded `camera_fov` in each session profile while the actual runtime camera was owned by `ReferenceComposition`. That duplicated source of truth and could later reproduce checkpoint 75's failure mode where a test goes green without binding the visible product owner.

Before PR integration, the unused session values were removed and `tests/test_reference_profiles.gd` was changed to interrogate the live `ReferenceComposition.target_fov_for_kind()` contract directly.

Final PR exact head: `b9c2146e4d6b977505a46621f7988aff2ce42bfc`.

## GREEN / exact-head product evidence

- Equivalent visual head Godot Check `32034183100` — PASS; artifact `9290022914`.
- Final PR exact-head Godot Check `32034520563` — PASS.
- Final PR exact-head artifact `9290149852`, digest `sha256:ad7cd24e4c6f1d06329eecc238eb02a881c69f17625d483b7a41d9357205c167`.
- Local Independent Challenger `32034611582` — PASS / `VERDICT: VERIFIED`, `DEFECT: NONE` on exact head `b9c2146e...`.
- PR #126 merged with expected-head protection as `9c3abdcf609e38ac8c439ec65cb7fcfaa6d24960`.
- Fresh merged-main Godot Check `32034880885` — PASS.
- Fresh merged-main artifact `9290277838`.

The Codex-hosted Challenger run failed independently of product acceptance; Local Challenger supplied the required exact-head independent gate and completed successfully. No paid credits or account changes were attempted.

## Frames inspected / visual verdict

Baseline artifact `9289507971`, final PR artifact `9290149852`, and merged-main artifact `9290277838` were compared across all nine interaction states:

- `bar.png`
- `bar_inspect.png`
- `bar_peel48.png`
- `market.png`
- `market_inspect.png`
- `market_peel45.png`
- `cafe.png`
- `cafe_peel38.png`
- `cafe_crumple55.png`

Scoped visual verdict: **PASS / improved**.

- Bar and Market now retain the complete bottle mouth/top inside frame with visible breathing room instead of forcing the neck into the top edge.
- More venue context is visible, making both bottles read as slender products rather than oversized vertical blocks.
- Inspect states remain stable.
- Partial-peel states retain readable flap/hand interaction rather than becoming too distant.
- Café remains effectively unchanged because the paper cup continues to use 39°.
- The change does not close R1. The XR-style support hand remains low-poly/open and still lacks the natural vessel enclosure required by the locked references.

## Failed / rejected hypothesis this run

The partial-peel flaps initially looked broad and rigid enough to suggest missing curvature. Repository evidence disproved that as the next useful hypothesis: `LabelGeometry.peeling_points()` already authors a bowed centerline, `LabelVisual` already applies up to 150° free-paper roll, and `test_peel_flap_arc.gd` already requires a meaningful centerline arc. Do not begin another flap-arc/roll parameter sweep without new evidence that the existing mechanism itself is failing.

## Remaining ranked reds

1. **R1 Macro — hero support-hand anatomy / vessel enclosure.** Still the dominant reference mismatch: insufficient palm volume, thumb opposition, progressive finger depth and real cup/bottle wrap.
2. **R2 Meso — whole-hand peel pinch / anatomy.** The captured contact state is truthful, but the hand silhouette/choreography remains far below reference quality.
3. Other independent Macro/Meso structural gaps may be taken only if objectively visible and falsifiable while genuine live/native-rig R1 authoring is unavailable.
4. Micro skin / paper fiber / glass / residue / condensation polish remains deferred while R1/R2 dominate.

## Stop / anti-drift rules still active

Do not resume:

- CCD or endpoint chasing;
- semantic grip scalar sweeps;
- wrist/orbit/yaw/translation grids;
- per-finger numeric pose grids;
- subdivision-density sweeps on the existing authored/XR hand;
- scale/frame/wrist/orbit/yaw/translation/per-finger search around the rejected CC0 MakeHuman fixed `Cup` pose;
- crumple gain sweeps after the rejected `1.85 -> 2.20` experiment;
- café lid size/detail sweeps without new reference evidence;
- bottle FOV grids around the now-verified 48° solution without a new visual regression;
- peel flap arc/roll sweeps merely because the flap looks broad in one frame;
- visual tests bound only to hidden or otherwise non-rendered owners.

CI green remains technical evidence, not a claim of reference completion.

## Next exact action

Start from `main@9c3abdcf609e38ac8c439ec65cb7fcfaa6d24960` and artifact `9290277838`. Re-check live/native-rig visual-authoring capability first. If it becomes available, return immediately to R1 and require exactly one reference-derived whole-hand support candidate to pass Macro enclosure and unobstructed Meso anatomy before production integration. If it remains unavailable, inspect the fresh merged nine interaction frames and select the next independent, objective Macro/Meso structural red. Do not sweep bottle FOV and do not substitute decorative Micro polish for the blocked hand problem.
