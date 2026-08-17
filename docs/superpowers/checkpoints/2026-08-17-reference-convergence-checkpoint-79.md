# Reference Convergence Checkpoint 79 — Market green-cap identity

Date: 2026-08-17

## Recovery source

Start every continuation from repository evidence, not chat memory:

1. Read this checkpoint, `docs/superpowers/prompts/2026-08-14-autonomous-reference-convergence-master-prompt-v3.md`, and `.agents/skills/multiscale-reference-convergence/SKILL.md`.
2. Read latest `main`, open PRs/branches, exact-head CI, and newest reference-frame artifact.
3. Treat `art/acceptance_refs/v1/` as source of truth. Runtime/staging frames are evidence, never replacement acceptance targets.
4. Continue coarse-to-fine. R1 hero support-hand anatomy / vessel enclosure is still the dominant Macro red. Do not resume previously rejected numeric hand-pose searches.

## Start-of-run evidence

- Starting main/checkpoint head: `d1d3d0010901b995cf7e2bab04ec897162828d5e`.
- Exact-main Godot Check: `32040592867` — PASS.
- Exact-main nine-frame artifact: `9291878582`.
- No open PRs at run start.
- Live Blender/native-rig authoring capability remained unavailable: plugin discovery returned no installable Blender / 3D-rigging tool, so the established R1 numerical-pose STOP condition remained binding.

## Ranked visual state

### R1 — still dominant / OPEN

Hero support-hand anatomy and vessel enclosure remain the largest low-frequency mismatch across Café / Bar / Market. Current authored/XR hands still lack reference-quality palm volume, progressive finger depth, convincing thumb opposition, and true vessel enclosure.

Do **not** restart CCD, endpoint chasing, master/finger grip sweeps, wrist/orbit/yaw/translation grids, per-finger angle grids, subdivision-density sweeps, or the rejected fixed-Cup CC0 arm route merely because live visual rig authoring is unavailable.

### Independent Meso red selected this run — Market cap identity

The locked `market_v1` acceptance target explicitly requires a clear bottle **with green cap**. In exact-main `9291878582`, Market base / inspect / partial-peel all showed a near-transparent gray/white glass mouth with no green cap. This weakened product/scene identity independently of the blocked R1 hand problem.

Hypothesis: adding one bounded opaque green screw-cap silhouette to the clear-bottle presentation only would materially improve Market reference identity without changing hand, camera, bottle body/glass, label, ice, gameplay, Café, or Bar.

## RED

Isolated branch: `fix/market-green-cap-v79`

RED exact commit:

`8e5eae72896fcebbf879a2c41cd8f6d2454af7b0`

The deterministic product-presentation contract was extended to require:

- `MarketGreenCap` on `clear_bottle`;
- cylindrical cap silhouette;
- bounded opaque `StandardMaterial3D` whose green channel dominates red/blue enough to survive thumbnail viewing;
- no `MarketGreenCap` inheritance on the amber Bar bottle.

RED Godot Check:

`32043078000` — expected FAILURE.

The run reached Unit tests after successful import/default launch and failed exactly on:

`RED: market clear bottle must carry the reference-defining green cap`

This falsified the old implementation without broadening scope.

## GREEN candidate

PR: #132 — `fix: restore market green cap identity`

Exact candidate head:

`ece45684998f7c2dc3aa273e1ead8ff1364faea3`

Implementation scope:

- add `MarketGreenCap` only for the clear-bottle branch in `ProductPresentation`;
- use one modest cylindrical capped silhouette over the existing authored glass mouth;
- deep leaf-green opaque material, moderate roughness, no metallic response;
- preserve existing hollow `BottleMouthRim`, glass body, Fresnel, ice/liquid, camera, hands, label, gameplay, and all Café/Bar presentation.

No cap-size/color sweep was started. One reference-derived candidate was evaluated.

Exact-head Godot Check:

`32043199571` — PASS.

Exact-head nine-frame artifact:

`9292329900`

Digest:

`sha256:31955c94f1602146df910b7a9707a8c2df64662bceea610b312e7f9aff895303`

## Runtime visual verdict

Compared exact-main `9291878582` against exact-candidate `9292329900` across:

- `market.png`
- `market_inspect.png`
- `market_peel45.png`

Result: **scoped Meso PASS**.

The bottle top now reads immediately as the locked-reference green cap in all three interaction states. The cap gives Market a stronger product/venue identity while preserving bottle framing, glass-body silhouette, label, ice, hands, and interaction staging. Café and Bar did not acquire the Market cap.

This does **not** close R1 and is not a claim of final photographic material quality.

## Independent Challenger

Auto dispatch was issued only after exact-head Godot PASS and runtime visual PASS.

Local Independent Challenger:

`32043325407` — PASS on the unchanged exact candidate head.

Grounded report:

- `VERDICT: VERIFIED`
- `DEFECT: NONE`
- `MIN_TEST: NONE`
- `EVIDENCE: NO_CONCRETE_DEFECT`

The hosted/Codex Challenger run `32043324305` failed independently; no paid/credential action was taken and its infrastructure failure was not treated as a product defect or as verification. The grounded local Challenger supplied the independent release gate for this scoped change.

## Merge and fresh-main proof

PR #132 was squash-merged with expected-head protection against:

`ece45684998f7c2dc3aa273e1ead8ff1364faea3`

Merged product commit:

`da41a7ce0ddaf649994befc2e5b94338d5bf9193`

Fresh merged-main Godot Check:

`32043570517` — PASS.

Fresh merged-main nine-frame artifact:

`9292396375`

Digest:

`sha256:8a121c3e2a3c08dcab4f402f06d113f23cd02b0460eb68291ffcbb1c207fc999`

Merged-main `market.png` was re-inspected: the green cap remains visible after integration. Branch-green evidence was not reused as merge proof.

## Closed reds this run

- Market clear bottle missing its reference-defining green cap — CLOSED for the scoped Meso identity gate.

## Remaining reds

1. **R1 Macro:** hero support-hand anatomy / true vessel enclosure — still dominant and OPEN.
2. Whole-hand peel pinch / hand anatomy still remain below reference quality where visible.
3. Product/material/detail work remains subordinate to unresolved Macro/Meso hand structure; do not use Micro polish to hide it.

## Do not repeat

In addition to all prior checkpoint stop lists:

- do not start a green-cap radius/height/color sweep after this scoped identity gate has passed;
- do not replace the deliberate Market cap with the previously rejected generic solid `BottleLip` / fake glass-mouth disk;
- do not use this Meso win as justification to claim Market or the product is reference-complete.

## Next exact action

On the next run:

1. Read latest main and this checkpoint; re-check for newly available live native-rig/Blender visual-authoring capability.
2. Inspect the newest exact-main nine interaction frames, starting from merged product evidence `9292396375` unless a newer verified artifact exists.
3. If true native-rig visual authoring is available, return immediately to R1 whole-hand support-grasp anatomy/enclosure.
4. If it is still unavailable, preserve the R1 numeric-search STOP condition and select exactly one independent, objective Macro/Meso mismatch from fresh runtime evidence; write a falsifiable RED before implementation.
5. Continue to withhold decorative Micro polish while a lower-frequency red dominates.
