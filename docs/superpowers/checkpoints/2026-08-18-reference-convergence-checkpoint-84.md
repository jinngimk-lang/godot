# Reference Convergence Checkpoint 84 — Quiet Café crumple journey UI candidate

Date: 2026-08-18

## Recovery source

This run started from:

- `main@986e9421a5010049320aa7abd875840c3492237a`
- newest checkpoint: `2026-08-18-reference-convergence-checkpoint-83.md`
- exact product/runtime evidence recovered from checkpoint 83: Godot Check `32072991514` PASS, runtime artifact `9302410623`
- no open PRs at recovery
- master prompt v3 and `.agents/skills/multiscale-reference-convergence/SKILL.md` reread before work

No installable Blender / 3D rigging / model-editing plugin was available in the current tool environment, so the R1 numeric-pose stop conditions remained active.

## Ranked reds at recovery

1. **R1 Macro — hero support-hand anatomy / true vessel enclosure.** Still dominant and still blocked from further numeric pose searching.
2. **Café crumple Macro/UI — bottom JourneyRail remains visible during the active 55% squeeze ritual.** This visibly occupies the lower negative space while both hands and the compressed cup should own the frame.
3. **R2/Meso — whole-hand peel pinch quality / full-hand flap following.**
4. **Micro — skin/paper/glass/residue/condensation detail.** Frozen.

## Scoped hypothesis

During active Café `CRUMPLING`, hiding only the bottom `JourneyRail` should improve the ritual frame without changing gameplay, hand pose, vessel, camera, peel physics, progression, or touch navigation outside the active squeeze. The rail must return in `CRUMPLE_READY`.

This deliberately does **not** hide the Continue button; the scoped target is removal of the three-scene navigation rail during the active tactile ritual.

## Isolated branch / TDD history

Product branch:

`fix/cafe-crumple-quiet-journey-v84`

RED test commit:

`262059388d30a4b296bcf456e13b07ba81e14dad`

The deterministic journey-presentation contract was extended to require:

- active `CRUMPLING` => `JourneyRail.visible == false`;
- idle `CRUMPLE_READY` => rail visible again for pointer/touch scene navigation.

The implementation commit changed only the journey presentation owner:

`e498eac9b0c05d68ff6c751d7af59f23479ff3e8`

Implementation rule:

- existing active-peel quieting remains unchanged;
- `phase == "CRUMPLING"` additionally suppresses the rail;
- `CRUMPLE_READY`, `HELD`, base navigation, inspection behavior, Continue button, product, camera, hands, label geometry and gameplay remain untouched.

## Exact-head verification

PR #143 exact head:

`e498eac9b0c05d68ff6c751d7af59f23479ff3e8`

Godot Check:

- run `32076354396` — PASS
- Godot 4.7.1 import / default launch / unit / scene / reference / café / crumple / live crumple-shell contact / contents / forearm / ritual / reset / pause/input isolation all PASS
- reference-frame capture PASS
- artifact `9303571967`
- digest `sha256:0045f5d065de116fbde894c11e7c160c659fe4970bce08772f603c1444bd30e1`

## Runtime visual verdict

Before: checkpoint-83 artifact `9302410623`.

After: candidate artifact `9303571967`.

Inspected the full nine-frame set and direct `cafe_crumple55` A/B.

Scoped result: **Macro/UI PASS**.

- before, the 588 px-wide three-scene rail occupied the lower center of `cafe_crumple55` while both hands squeezed the cup;
- after, the rail is absent during active crumple, restoring table/negative space and making the hand-and-cup ritual the dominant lower-frame read;
- the Continue button remains available at lower right;
- cup, hands, crumple deformation, camera and top-left guidance are pixel-stable apart from the intended rail removal;
- other café/bar/market base, inspect and partial-peel frames show no obvious scoped regression.

This does **not** close R1 hand anatomy/enclosure.

## Challenger gate status

The product candidate has **not been merged** because the independent Challenger gate is not closed.

Two round-1 Local Challenger reports on the unchanged exact head returned:

`VERDICT: INFRA_FAILURE`

with no accepted exact-packet verdict. Those duplicate round-1 attempts were triggered by overlapping AUTO / explicit dispatches and therefore are not product findings.

An explicit round-2 dispatch was then sent for the same exact head. At checkpoint time no grounded round-2 verdict had yet been posted.

Therefore:

- do not merge PR #143 yet;
- do not interpret Challenger infrastructure failure as a product defect;
- do not alter the already visual-PASS product candidate merely to appease an ungrounded failure.

## Closed / improved red

Evidence-backed candidate improvement, pending Challenger merge gate:

- active Café crumple no longer needs to carry persistent three-scene navigation chrome in the exact runtime capture;
- touch navigation remains available before/after the active squeeze through `CRUMPLE_READY` and other non-active states.

## Remaining reds

1. **R1 Macro — hero support-hand anatomy / true vessel enclosure.** Still the largest visible mismatch. XR hands remain open/faceted and lack realistic palm volume, progressive finger depth, web space and readable thumb opposition.
2. **R2/Meso — whole-hand peel pinch quality and full-hand following of the lifted flap.**
3. **Café crumple Meso — owner playtest/readability across other crumple strengths.** Do not start a new crumple offset or UI opacity sweep from this checkpoint.
4. **Micro — skin, paper fibre, glass/liquid, residue, condensation.** Still frozen.

## Failed / rejected / prohibited repetition

- Do not resume support-hand CCD, endpoint chasing, grip-number, wrist/orbit/yaw/translation grids, per-finger numeric grids, subdivision-density sweeps, or the rejected fixed-Cup CC0 source.
- Do not start a JourneyRail size/opacity/position sweep; this candidate changes only active-crumple ownership.
- Do not remove the Continue button as part of this scoped change without new evidence.
- Do not descend into decorative Micro polish while R1 remains dominant.
- Do not merge PR #143 without an independent grounded Challenger verdict on its unchanged exact head.

## Next exact action

1. Read PR #143 current head and Challenger comments first.
2. If a grounded exact-head `VERIFIED` result exists and the head remains `e498eac9b0c05d68ff6c751d7af59f23479ff3e8`, expected-head squash merge PR #143.
3. Immediately run fresh merged-main Godot 4.7.1 and inspect all nine runtime frames; confirm `cafe_crumple55` keeps the quiet rail state in the actual merge tree.
4. If Challenger returns a real grounded `NEEDS_FIX`, fix only the proven contradiction and rerun exact-head evidence.
5. Re-check live Blender/native-rig visual-authoring capability; if it becomes available, return immediately to R1 whole-hand support-grasp authoring. Otherwise choose the next independent objective Macro/Meso red from fresh merged-main interaction frames.
