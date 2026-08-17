# Reference Convergence Checkpoint 72 — deliberate edge lift + subdivision rejection

Date: 2026-08-17

## Recovery source

Start every continuation by reading this checkpoint, `docs/superpowers/prompts/2026-08-14-autonomous-reference-convergence-master-prompt-v3.md`, and `.agents/skills/multiscale-reference-convergence/SKILL.md`, then inspect current `main`, open PRs/branches, exact-head CI, and the newest runtime-frame artifact before changing code.

## Current production baseline

- Production main after PR #114: `15fe5c04cacc903e7d17b4249f345514581f499d`.
- Fresh merged-main Godot Check: `32016493705` — PASS on Godot 4.7.1 across import/parse, default launch, unit, scene/reference/presentation/reset/input isolation, and nine-frame capture.
- Fresh merged-main runtime artifact: `9283711503` (`peel-calm-reference-frames`), digest `sha256:e43e2aada3157c215d619f4781f30756cdf5b31e911a569bf7c99ceff7b56e8f`.
- Locked reference family remains `cafe_v1 / bar_v1 / market_v1`.

## Closed this loop — deliberate first edge lift

PR #114 fixed an owner-visible interaction problem: a fresh label previously accepted a press almost anywhere on its projected surface and armed peeling after only a tiny twitch.

The final exact candidate `d160618495ee8d3cfe61928620714501378c0eab`:
- restricts the first fresh-label grab to the projected peel edge;
- requires at least 10 px lift plus at least 0.08 s tactile dwell before arming PINCHED/PEELING;
- keeps re-grab forgiving once peel progress already exists;
- updates Café/Bar/Market guidance from `peel anywhere` to `grab edge • lift`;
- does not change hand pose, camera, adhesion/release-rate tuning, or material presentation.

TDD lineage:
- RED `3eba8ea9d881ead4e52ac2092227c9fff71a272c`, Godot Check `32015379058` — deterministic unit failure proved fresh-center press and 6 px motion were too permissive.
- GREEN behavior `d5278bdc2e49fc4f9a579aa9ffaa7d9c07965cf3`, Godot Check `32015461690` — PASS.
- Guidance RED `83dfbb7432b2e40d41bfda7363954570d7ab3d17`, Godot Check `32015583245` — failed only because Café still taught obsolete copy.
- Exact candidate Godot Check `32015703943` — PASS; runtime artifact `9283421773`.
- PR-triggered exact-head Godot Check `32015921558` — PASS.
- Local Challenger round 1 returned `VERIFIED / DEFECT: NONE` for the unchanged exact head.
- PR #114 was expected-head squash merged as `15fe5c04cacc903e7d17b4249f345514581f499d`.
- Fresh merged-main Godot Check `32016493705` — PASS; artifact `9283711503`.

## Model-pipeline negative result — authored hand subdivision v91

A concurrent R1 spike promoted repository-local, provenance-safe subdivided authored hand GLBs into branch `spike/hero-hand-subdiv-v91`. The bounded question was whether substantially increasing mesh density could reduce the current hero-hand faceting without changing pose or interaction.

Provenance/gate evidence recorded on draft PR #115:
- source artifact `9281903731` (`authored-hand-subdiv-candidates`), built from the repository-local CC0-derived hand assets;
- source mesh approximately `3752v / 6460f` per side -> subdivided candidate approximately `20420v / 19380f`;
- 26 skin groups, 26-bone armature, authored `Cup`, `Pinch Tight`, and `Pinch Up` actions preserved;
- no CCD, endpoint chasing, wrist/orbit/yaw/translation grid, camera, vessel, label, gameplay, or forearm-path change.

Exact runtime staging head `54f2f1c4b9d67d1f4fd8ed2185fbd11ef375429c` completed Godot Check run `32016324234` successfully and produced artifact `9283647764`.

Visual comparison against the current café/bar/market base + partial-peel frames: **REJECT**.

The subdivision does not materially improve the dominant Macro/Meso R1 mismatch. Support hands remain open/non-enclosing, thumb/finger opposition remains weak, and the overall silhouette is essentially unchanged. The extra tessellation mainly changes high-frequency surface appearance; in several views it reads more mottled/creased rather than more anatomical. This is therefore code-green but visually insufficient. Draft PR #115 was closed without merge.

### Non-repeat rule

Do **not** start another subdivision-density sweep on the same current authored hand mesh. Mesh density alone has now been falsified as the next R1 lever. The next hand-model iteration must be structurally different: live native-rig whole-hand visual authoring, a better provenance-safe hand source, or another model-pipeline change that can alter anatomy/enclosure rather than only tessellation.

## Coordination cleanup

Old PR #106 was closed as superseded. Its Café receipt-shape work is already represented by the later merged PR #111 and PR #112 path captured in checkpoint 71; keeping the divergent duplicate open created unnecessary visual-ownership and ancestry ambiguity.

PR #102 remains open and independently VERIFIED for its bounded continuous peel-audio mix change; it is not part of this visual loop and was not merged or modified here.

## Current multi-scale verdict

### Macro — RED

R1 hero support-hand anatomy / vessel enclosure remains the dominant project mismatch. The current hands are still visibly open and do not reproduce the approved references' palm volume, thumb opposition, natural finger depth ordering, or genuine wrap around cup/bottle.

Existing numeric-search stop conditions remain active: no CCD, endpoint chasing, master/finger-grip sweeps, wrist/orbit/yaw/translation grids, or disguised pose parameter search.

### Meso

First peel entry is now more deliberate and the guidance teaches the correct edge-lift affordance. Receipt shape/readability improvements from checkpoint 71 remain integrated. Interaction-step capture remains mandatory; base frames alone are insufficient.

### Micro — frozen

Do not divert into skin pores, paper fibers, condensation, glass micro-highlights, residue breakup, or other high-frequency polish while hero-hand Macro remains the dominant mismatch.

## Failed / non-repeat experiments this loop

- Do not infer hand progress from triangle count or CI import success; subdivision v91 passed technical gates but failed the actual runtime silhouette/enclosure gate.
- Do not continue subdivision density sweeps on the same mesh.
- Do not reopen the superseded Café receipt PR #106.
- Do not weaken the new deliberate first-edge-lift contract just to make automation easier; re-grab remains forgiving after progress, while fresh-label entry is intentionally deliberate.

## Next exact action

1. Recover from current `main`, this checkpoint, active PRs/branches, exact-head CI, and newest runtime frames.
2. Re-rank the newest nine interaction frames against the locked references at thumbnail/Macro scale.
3. If live Blender/native GameEngine rig authoring is available, return immediately to R1 with one direct whole-hand visual pose; preserve all numeric-search stop conditions.
4. Otherwise, only pursue a structurally different provenance-safe hand-model pipeline candidate that can change anatomy/enclosure, or choose the next independent objective Macro/Meso defect visible in current frames.
5. For any product merge candidate require exact-head Godot 4.7.1, real affected interaction frames, visual A/B, independent grounded Challenger, expected-head merge, and fresh merged-main Godot + screenshots.
