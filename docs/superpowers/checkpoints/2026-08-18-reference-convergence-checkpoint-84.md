# Reference Convergence Checkpoint 84 — Quiet Café crumple journey UI

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
2. **Café crumple Macro/UI — bottom JourneyRail remains visible during the active 55% squeeze ritual.** This visibly occupied lower negative space while both hands and the compressed cup should own the frame.
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

The implementation exact head was:

`e498eac9b0c05d68ff6c751d7af59f23479ff3e8`

Implementation rule:

- existing active-peel quieting remains unchanged;
- `phase == "CRUMPLING"` additionally suppresses the rail;
- `CRUMPLE_READY`, `HELD`, base navigation, inspection behavior, Continue button, product, camera, hands, label geometry and gameplay remain untouched.

## Exact-head verification

PR #143 exact product head:

`e498eac9b0c05d68ff6c751d7af59f23479ff3e8`

Godot Check:

- run `32076354396` — PASS
- Godot 4.7.1 import / default launch / unit / scene / reference / café / crumple / live crumple-shell contact / contents / forearm / ritual / reset / pause/input isolation all PASS
- reference-frame capture PASS
- artifact `9303571967`
- digest `sha256:0045f5d065de116fbde894c11e7c160c659fe4970bce08772f603c1444bd30e1`

## Runtime visual verdict

Before: checkpoint-83 artifact `9302410623`.

After: exact candidate artifact `9303571967`.

Inspected the full nine-frame set and direct `cafe_crumple55` A/B.

Scoped result: **Macro/UI PASS**.

- before, the ~588 px-wide three-scene rail occupied the lower center of `cafe_crumple55` while both hands squeezed the cup;
- after, the rail is absent during active crumple, restoring table/negative space and making the hand-and-cup ritual the dominant lower-frame read;
- the Continue button remains available at lower right;
- cup, hands, crumple deformation, camera and top-left guidance remain stable apart from the intended rail removal;
- other café/bar/market base, inspect and partial-peel frames show no obvious scoped regression.

This does **not** close R1 hand anatomy/enclosure.

## Independent Challenger

The first two round-1 Local Challenger comments returned `INFRA_FAILURE` with no accepted exact-packet verdict. They were duplicate dispatches from overlapping AUTO / explicit round-1 commands and were treated as verifier/invocation noise, not product findings.

A clean explicit round-2 run then reviewed the unchanged exact product head:

`e498eac9b0c05d68ff6c751d7af59f23479ff3e8`

Grounded result:

- `VERDICT: VERIFIED`
- `DEFECT: NONE`
- `MIN_TEST: NONE`
- `EVIDENCE: NO_CONCRETE_DEFECT`

No product changes were made between the visual PASS and this VERIFIED result.

## Merge

PR #143 was merged with expected-head protection and squash semantics only after the exact head remained unchanged and the round-2 Challenger returned VERIFIED.

Merged product commit:

`75f10b39df9d0d78cd93b590dbb63642212db231`

## Closed red

Closed in this checkpoint:

- active Café crumple no longer carries the persistent three-scene JourneyRail in the exact runtime ritual frame;
- touch navigation still returns in `CRUMPLE_READY` and other non-active states;
- active peel and inspection quiet-UI behavior remain intact.

## Remaining reds

1. **R1 Macro — hero support-hand anatomy / true vessel enclosure.** Still the largest visible mismatch. XR hands remain open/faceted and lack realistic palm volume, progressive finger depth, web space and readable thumb opposition.
2. **R2/Meso — whole-hand peel pinch quality and full-hand following of the lifted flap.**
3. **Café crumple Meso — owner playtest/readability across other crumple strengths.** Do not start a new crumple offset or UI opacity sweep from this checkpoint.
4. **Micro — skin, paper fibre, glass/liquid, residue, condensation.** Still frozen.

## Failed / rejected / prohibited repetition

- Do not resume support-hand CCD, endpoint chasing, grip-number, wrist/orbit/yaw/translation grids, per-finger numeric grids, subdivision-density sweeps, or the rejected fixed-Cup CC0 source.
- Do not start a JourneyRail size/opacity/position sweep; this change is only active-crumple ownership.
- Do not remove the Continue button as part of this scoped change without new evidence.
- Do not descend into decorative Micro polish while R1 remains dominant.
- Do not interpret the duplicate round-1 Challenger `INFRA_FAILURE` reports as product defects; round 2 on the unchanged exact head is the accepted grounded result.

## Next exact action

1. Start from `main` and confirm the merged product commit / newest checkpoint head.
2. Inspect the freshest merged-main nine-frame artifact, especially `cafe_crumple55`, to confirm the rail remains absent in the true integration tree.
3. Re-check live Blender/native-rig visual-authoring capability. If available, return immediately to R1 whole-hand support-grasp authoring against the locked references.
4. If unavailable, choose the next independent objective Macro/Meso red from the freshest interaction-step frames; preserve base / partial-peel / inspect / crumple evidence.
5. Keep Micro polish frozen while R1 remains dominant.
