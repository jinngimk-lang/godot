# Peel Calm reference convergence checkpoint 63 — amber layer separation integrated

Date: 2026-08-17

## Stable production baseline

- Product merge: PR #96 `fix: restore amber glass layer separation`.
- Merged production code head: `fd9db75f64496a77b85bf640da545f0bcda3e070`.
- Fresh merged-main Godot Check: `31999166628` — PASS.
- Fresh merged-main runtime artifact: `9277817340` (`peel-calm-reference-frames`), digest `sha256:ae471c9ecdcbe99115ac2418242bfbfa3b9e5099c699b6220c7b5e817b75200f`.
- Locked acceptance references remain `cafe_v1`, `bar_v1`, `market_v1`; runtime/staging frames do not replace them.

## Loop completed in this checkpoint

Highest available independent Meso red while R1 remains tool-blocked: the amber bar bottle still read too much like a single opaque brown mass, with weak glass/liquid/shoulder separation.

Hypothesis: preserve the current continuous lathed bottle geometry and Fresnel shell, but reduce only amber outer-shell/liquid density and slightly lift amber inner/outer tint. This should improve optical layer separation without touching the hand, camera, label geometry, clear bottle, or gameplay.

### RED

- Isolated fresh branch from `main@e44f8754cd0ea9668e71c472bf4842aeb48a042d`: `fix/amber-glass-readability-v81-main`.
- RED commit: `a83c3a2fbcf33654b5c42e92e6977c01ca0ed0ee`.
- Added deterministic bounds requiring amber outer glass alpha `<= 0.15` and amber liquid alpha `<= 0.16`.
- Godot Check `31998491267` failed in unit tests, with import/parse and configured launch already passing.

### First implementation rejected by its own contract

- Commit `c966c51e0e3c06753910c4cc3b04425482635998` attempted an amber outer factor of `0.36`.
- Godot Check `31998593404` again failed at unit tests.
- Cause: the explicit test profile uses `glass_alpha=0.48`, so `0.48 * 0.36 = 0.1728`, still above the new `0.15` contract.
- The test was not weakened or rewritten to make the implementation green.

### GREEN

- Exact candidate: `871a99ffe4fe03b46c4aa41266328ea14f71a0bc`.
- Single bounded correction: amber outer factor `0.30`; amber inner tint modestly lifted; amber liquid alpha `0.14`. Clear-glass path unchanged.
- Push Godot Check `31998701899` — PASS across import, launch, unit, scene/reference/presentation smoke, reset/pause/input isolation, and nine-frame capture.
- Candidate artifact `9277679332`, digest `sha256:7010ef13736e221bb4202946a198d3416d222bfce045295686061c4512e9f806`.
- PR-triggered Godot Check `31998838717` — PASS on the identical exact head.

## Visual evidence inspected

Compared current-main baseline artifact `9277376835` with exact candidate `9277679332`, then re-inspected fresh merged-main artifact `9277817340`.

Frames inspected:

- `bar.png`
- `bar_inspect.png`
- `bar_peel48.png`
- café and market frames for collateral regression checks

Verdict: scoped Meso improvement accepted. The amber shell/liquid stack is modestly less dense and the shoulder/body layering is easier to read while label readability, continuous Fresnel response, composition, hands, and inspect/partial-peel state remain stable. This does **not** make the bottle photographic and does not override the larger hand mismatch.

## Independent Challenger

- Local Challenger run `31998854225` reviewed exact PR #96 head `871a99ffe4fe03b46c4aa41266328ea14f71a0bc`.
- Result: `VERDICT: VERIFIED`, `DEFECT: NONE`.
- Codex Challenger `31998852748` completed independent deterministic Godot verification but failed at the external model step; no paid action or credit purchase was attempted. This was not treated as a product defect or as VERIFIED.
- PR #96 was merged only after unchanged-head Godot PASS + runtime A/B + Local Challenger VERIFIED.

## Superseded work

Old amber PR #65 was closed without merge after #96 landed. It was based on stale pre-current presentation ancestry; its useful hypothesis was replayed and re-tested on the actual current Fresnel/lathed-bottle stack instead of merging old history.

## Multi-scale status after merge

### Macro — still RED

1. **R1 hero support-hand anatomy / vessel enclosure remains the largest mismatch.** Current XR hands are faceted/open and do not read as a natural human grip around cup/bottle.
2. The existing stop condition remains active: do not resume CCD, endpoint chasing, semantic-grip sweeps, wrist/orbit/yaw/translation grids, or other disguised numeric hand-pose search without live native-rig visual authoring or a structurally better hand asset/source.

### Meso

- Amber glass/liquid separation: improved and integrated, not photographic-complete.
- Peel-hand whole-hand pinch remains below reference quality.
- Current vessel/label/contact improvements remain accepted unless fresh evidence shows regression.

### Micro

Skin, paper fiber density, photographic glass/residue/condensation polish remain lower priority while a workable Macro/Meso red exists.

## Do not repeat

- Do not reopen or merge stale PR #65 ancestry.
- Do not sweep amber opacity factors after this bounded correction; any future glass work requires a new visible mismatch and fresh A/B evidence.
- Do not use CI green as evidence that R1 hand anatomy/enclosure is solved.
- Do not resume blind numeric hand-pose search.

## Next exact action

At the next run, first inspect the newest exact-main nine-frame artifact and capability surface. If live Blender/native-rig visual authoring is available, return immediately to R1 and author one visual support-grasp candidate using the existing stop-condition-safe workflow. If that capability is still unavailable, rank fresh interaction-step frames and select one independent, objective Macro/Meso structural defect that does not require violating the R1 stop condition. Do not begin decorative Micro polish merely because hand authoring is blocked.
