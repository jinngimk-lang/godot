# Reference convergence checkpoint 69 — Window Café sleeve fabric integrated

Date: 2026-08-17

## Recovery source

- Production integration head: `19af81147ad715001318f25f91d8105a9396042a`
- Parent checkpoint main: `5ac09fa1d43774499cd5fb483338ec405ef12a8a`
- Integrated PR: #107 `feat: make Window Café sleeve read as cloth`
- Acceptance order remains `cafe_v1` first, with `bar_v1` and `market_v1` preserved as regression scenes.

## Red and failed experiment

Checkpoint 68 identified the Window Café sleeve/forearm as an independently executable Macro/Meso red: the bridge still read as a thick smooth tube even though hero-hand pose search is stopped until true visual rig authoring is available.

Objective RED head `ac72115df19ca0c3a83d425f6d62e948805f1687`, Godot Check `32008703974`, failed the intended sleeve contract: explicit non-circular cloth cross-section, cloth material, and stable UVs.

The first green implementation at `dedebbc5192673fe20ef0b3ba6fdfbf06367f91a` was visually rejected despite technical success. Artifact `9280988501` showed high-frequency albedo weave as fingerprint/woodgrain moiré and the sleeve remained too thick. Do not repeat that tactic.

## Accepted clean candidate

Only the true sleeve increment was replayed onto fresh `main@5ac09fa1d43774499cd5fb483338ec405ef12a8a`.

Exact candidate: `1e498029f4ccf8aa018e14ceb5837e061d604d37`

Changed paths:

- `scripts/presentation/forearm_presentation.gd`
- `tests/test_cafe_sleeve_fabric.gd`
- `tests/test_runner.gd`

The accepted implementation preserves hand bones, pinch targets, cubic forearm path, wrist overlap, cup, label, camera and gameplay. It narrows the Café radius profile from `0.130 -> 0.200` to `0.112 -> 0.168`, adds a flattened/folded deterministic cross-section, stable generated UVs, and keeps weave almost entirely as subtle roughness variation rather than visible high-frequency color.

## Verification evidence

Clean branch Godot Check `32009912780` — PASS.

- exact head `1e498029f4ccf8aa018e14ceb5837e061d604d37`
- artifact `9281379446`
- digest `sha256:0bf22a9e39b0f30cf39dce87020cd15c52388e92e023dc7294a404aea8cc3772`

PR-triggered Godot Check `32010025528` — PASS on the same head, including import, configured launch, deterministic tests, smoke/reset/input gates and nine-frame capture.

Independent Local Challenger `32010116460` — PASS on the same head with `VERDICT: VERIFIED` and `DEFECT: NONE`.

PR #107 was squash-merged with expected-head protection.

Merged product commit: `19af81147ad715001318f25f91d8105a9396042a`

Fresh merged-main Godot Check `32010548685` — PASS.

- merged-main artifact `9281604354`
- digest `sha256:2cfe08de669589beb50d5ab0a9faa1bb6e881537ae2ee976596dd870cbb82dd1`

## Visual frames inspected

The clean candidate and fresh merged-main evidence were checked at interaction scale, including `cafe.png` and `cafe_peel38.png`.

Scoped visual result: the sleeve is narrower and flatter, occupies less low-frequency screen area, and the rejected weave moiré is absent. Cup/hand/contact composition and partial-peel state remain stable. This closes the sleeve-specific red only.

## Remaining reds

1. **R1 — hero support-hand anatomy and vessel enclosure.** Current XR hands remain faceted/open and are still the largest Macro gap versus the approved reference.
2. Whole-hand peel/pinch anatomy remains below reference quality.
3. Café receipt/label face still needs acceptance-level pale receipt readability; coordinate with active label work instead of duplicating it.
4. Skin, cloth, paper and glass Micro detail remains subordinate to unresolved Macro/Meso structure.

## Do not repeat

Keep the existing hand-pose stop condition: no CCD, endpoint chasing, semantic grip sweeps, wrist/orbit/yaw/translation grids, or disguised pose-parameter searches without live visual native-rig authoring or a better validated hand source.

Do not sweep the accepted sleeve radius or weave frequency merely because it is easy to tune. Re-open it only for a concrete new reference mismatch.

## Next exact action

1. Recover from latest `main`, this checkpoint, active PRs/branches, exact-head CI and the newest nine-frame artifact.
2. Audit the active Café receipt-label work against this new sleeve main and real interaction frames. If it is stale, replay only the narrow label increment; if visually weak, reject it even if CI is green.
3. If live native-rig visual authoring becomes available, return immediately to R1 support-hand anatomy/enclosure. Otherwise keep the numeric-search stop condition and select the next independent Macro/Meso red.
4. Keep Micro polish frozen wherever a lower-frequency red still dominates.
