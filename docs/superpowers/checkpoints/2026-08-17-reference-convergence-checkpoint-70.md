# Reference convergence checkpoint 70 — restrained Café wrist cuff integrated

Date: 2026-08-17

## Recovery contract

Inherit checkpoints 66–69 and the owner long-horizon directive unchanged: no artificial iteration ceiling; recover from latest main/checkpoint/PR+CI/latest screenshots; locked references outrank historical implementation; machine-green does not equal visual-green; do not repeat falsified experiments; final subjective aesthetics remain an owner playtest gate.

Phase 1 remains locked `cafe_v1`. This checkpoint closes only a small sleeve/wrist sub-red and does **not** declare Window Café complete.

## Fresh main

- current product main after this integration: `9a2a64e076f6d480ba8ad93ac99573cfc842a931`;
- fresh merged-main Godot Check: `32011219104` — PASS through import, configured launch, all deterministic/smoke/reset/input gates, nine-frame capture and artifact upload;
- checkpoint 69 remains the accepted core sleeve integration source (`#107`, merged `19af81147ad715001318f25f91d8105a9396042a`).

## Why a second sleeve PR existed

A parallel agent merged #107 while the wrist-cuff experiment was still in flight. The original #108 branch therefore became duplicate/stale. It was not merged as-is.

The branch was clean-rebased directly onto `main@19af81147ad715001318f25f91d8105a9396042a` and narrowed to the true remaining **two-file cuff delta only**:

- `scripts/presentation/forearm_presentation.gd`
- `tests/test_cafe_sleeve_fabric.gd`

Latest-main runner already contained the sleeve suite and was left untouched.

## Cuff RED / rejected candidates

Valid cuff RED:

- head `e740513faf001787861ae4b61d987775034d89d0`;
- Godot Check `32009470075`;
- import/default launch passed;
- intended unit failure only: no semantic short ribbed wrist cuff to break the smooth hose transition.

First cuff GREEN:

- head `29a324ff15f60ee4ee46fff0282fcca5fc888440`;
- Godot Check `32009638471` — PASS;
- artifact `9281277932`;
- **visually rejected**: cuff appeared as a hard black wrist brace/armor because it was too dark, too wide and too long.

Do not repeat this high-contrast oversized cuff direction.

Softened candidate before final clean replay:

- head `199a19a328e453a8285c9b2bed4980f61c98a1e4`;
- Godot Check `32010064647` — PASS;
- artifact `9281432627`, digest `sha256:2922c934b03aa0652c4e2ddf53dbbddd2464e2667f81941303cc678d1266441d`;
- real `cafe.png` showed the cuff reduced to a restrained near-sleeve-color wrist transition; no moiré and no hard-brace read.

## Final exact-head integration

PR #108 was clean-rebased after #107 and retitled `feat: add a restrained Window Café wrist cuff`.

Exact head: `de5e7056760cfa08066be1a0779c7830cd591016`.

Fresh exact-head Godot Check:

- run `32010683312` — PASS;
- artifact `9281649889`, digest `sha256:1f558e00054ccc789a9f10088083ebfdd0cdf4de5707f6ab9a26a355f0d137f7`;
- exact-head `cafe.png` was visually re-inspected and matched the accepted softened-cuff direction.

Independent Local Challenger round 2:

- run `32010829497` — PASS through exact-head validation, packet build, schema-constrained review, grounding, PR report and `Enforce verdict`;
- therefore exact head was grounded `VERIFIED`.

Merged with expected-head protection:

- merged product commit `9a2a64e076f6d480ba8ad93ac99573cfc842a931`.

## Remaining Phase-1 reds

1. **R1 hero support-hand anatomy / cup enclosure remains the dominant Macro red.** Existing no-blind-numeric-pose-search stop condition remains active until live visual native-rig authoring or a structurally better validated hand source exists.
2. Café receipt/label face is still visually too dark/brown and its old shape/readability differs strongly from the pale receipt-like `cafe_v1` target.
3. Hand/skin material remains faceted/game-like.
4. Normal-play UI remains heavier than the locked reference.
5. Final owner playtest gate remains open.

## Active coordinated next work

Do **not** start a duplicate label branch. Active PR #106 already exists: `feat: converge Window Café receipt label`, head `2eacca5cdc518bfaa1692cf7b2f3f15bb72b2043`.

It currently proposes a near-square Café receipt layout and print hierarchy, but it was based on older main after #105 and must be audited/replayed onto current main before any merge.

Objective visual diagnosis from current runtime vs locked `cafe_v1`:

- current runtime attached label mid-face luminance is approximately 41% of nearby cup-body luminance;
- locked `cafe_v1` label is approximately 82% of nearby cup-body luminance;
- therefore “label too dark/brown” is a measurable mismatch, not only subjective feedback.

Read-only root-cause audit so far:

- `LabelVisual` front material is physically lit `StandardMaterial3D`, with a nominal pale albedo and the SubViewport print texture;
- geometry normals are outward/frustum-correct;
- Godot 4.7 officially supports `emission_texture` and `emission_energy_multiplier` on BaseMaterial3D/StandardMaterial3D, providing a bounded future option to add paper bounce while preserving dark print if #106 layout alone does not fix the measured darkness.

Do not apply that emission idea before reviewing #106’s fresh replay frames; it is a hypothesis, not an accepted fix.

## Next exact action

1. Recover latest `main@9a2a64e...`, checkpoint 70, active PR #106 status/CI, and newest fresh-main screenshot artifact.
2. Inspect #106 changed files and existing artifacts; decide which narrow receipt-label deltas are still valid after #105/#107/#108.
3. Clean-replay only the non-overlapping label increment onto latest main; preserve all newer runner suites and presentation work.
4. Run fresh exact-head Godot Check and visually compare `cafe.png` + partial peel against locked `cafe_v1`.
5. If shape improves but label remains much too dark, add a new objective RED for receipt-face readability before changing material/lighting. Do not tune brightness blindly.
6. Require exact-head Local Challenger and expected-head merge protection; then fresh-main CI and the next checkpoint before changing red category.
