# Reference Convergence Checkpoint 83 — Café crumple hands grounded on rendered shell

Date: 2026-08-18

## Recovery source

This run started from:

- `main@d0ef0a75ded5be196f346ca78337016f981b6d7f`
- newest checkpoint: `2026-08-18-reference-convergence-checkpoint-82.md`
- exact-main visual/runtime state from checkpoint 82: Godot Check `32067879079` PASS, runtime artifact `9300605391`
- open PR #140: Café crumple rendered-shell hand contact candidate

The master prompt v3 and `.agents/skills/multiscale-reference-convergence/SKILL.md` were reread before continuation.

## Ranked reds at recovery

1. **R1 Macro — hero support-hand anatomy / true vessel enclosure.** Still dominant. Existing stop conditions remain active: no CCD, endpoint chasing, grip-number, wrist/orbit/yaw/translation grids, per-finger numeric grids, subdivision-density sweeps, or rejected fixed-Cup source reuse without genuinely different visual-authoring capability.
2. **Café crumple Meso — visible hand-to-rendered-shell contact.** Checkpoint 81 left a small visible air gap; this was the highest-value independent objective red that could be advanced without violating R1 stop conditions.
3. **R2/Meso — whole-hand peel pinch quality / full-hand flap following.**
4. **Micro — skin/paper/glass/residue/condensation detail.** Frozen while lower-frequency reds remain.

## Product candidate recovered

PR #140: `fix: ground café crumple hands on rendered shell`

Exact product head remained unchanged through review:

`1089dd0622d2cf90e499f3a1ef74db6ec6616282`

The credible live-scene RED measured the visible HandVisual pinch anchors against the actual 55% `CrumpledCup` ArrayMesh:

- support gap: **78.6 mm**
- released peel-hand gap: **295.1 mm**
- hard visible-contact contract: **<=45 mm**

The earlier off-tree / `_init()` fixture attempts were rejected because Godot global transforms were not trustworthy before the scene entered the live SceneTree.

## Product implementation

The final candidate keeps the existing semantic crumple choreography and adds one geometry-derived residual translation from each real HandVisual pinch anchor to the nearest vertex of the currently rendered `CrumpledCup` shell.

It also:

- gives active Café crumple sole presentation ownership of the released peel-hand root so idle peel-rest staging cannot pull it away again;
- allows explicit squeeze intent to enter optional `CRUMPLING` during the calm `PEEL_SETTLE` beat, while the no-input 0.45 s calm beat remains unchanged;
- does **not** add CCD, endpoint optimization, contact servo search, offset grids, grip sweeps, or pose-angle search.

Exact-head product verification:

- Godot Check `32072991514` — PASS
- runtime artifact `9302410623`
- artifact digest `sha256:53eaee7cb7a23b71c220df35a13581f2e6627c963477f2f22f4128c765aa7458`

## Runtime visual verdict

The exact candidate nine-frame set was inspected before merge.

- `cafe_crumple55`: both hands visibly participate against the compressed cup instead of hovering off the paper shell; the released peel hand no longer reads as a bystander.
- other café/bar/market base, inspect, and partial-peel states showed no obvious scoped regression.
- this is a **scoped Meso PASS only**. It does not close R1 hand anatomy/enclosure and does not make the XR hands reference-quality.

## Challenger infrastructure failure and repair

PR #140 Local Challenger rounds 1 and 2 both returned `INFRA_FAILURE` before a grounded schema verdict. The failures occurred before parser/validator evidence was available.

Root cause: because PR #140 changes `hand_choreography`, `tools/build_local_challenger_packet.sh` routed it into the broader hand-contract bundle and appended several whole hand/capture files without byte bounds. That bypassed the existing generic-batch 42 KB protection and could fail before Ollama review began.

Verifier-only PR #141 fixed this without product changes:

- byte-bounds broader hand context under an explicit hand-contract budget;
- preserves bounded exact diffs for every changed file;
- adds a synthetic hand-route self-test reproducing the old `hand_choreography` packet-expansion failure;
- exact verifier head `6c240a7337a83bc32258f08fa9a92971753b392d` passed Godot Check `32073860138`;
- Local Challenger round 1 on the verifier head returned `VERIFIED / DEFECT: NONE`.

PR #141 was expected-head squash merged as:

`4bc30105d25744f32db35b53cb8491fa55b76be4`

## Independent Challenger on unchanged product head

After the verifier repair reached `main`, PR #140 was challenged again without changing its product head.

Round 3 exact head:

`1089dd0622d2cf90e499f3a1ef74db6ec6616282`

Grounded result:

- `VERDICT: VERIFIED`
- `DEFECT: NONE`
- `MIN_TEST: NONE`

This closed the final merge gate for the scoped Café crumple contact change.

## Merge

PR #140 was squash merged with expected-head protection.

Merged product commit:

`a8c4564aa128e1b44618aa96e5452a855e08947d`

The only intervening `main` change between the candidate base and merge was the verifier-only packet-bounding repair; no visual/runtime product files overlapped.

## Closed red

Closed in this checkpoint:

- Café 55% crumple no longer leaves both visible pinch anchors floating materially away from the rendered paper shell;
- released peel-hand rest choreography no longer fights active crumple ownership;
- explicit user squeeze intent during the calm settle is not blocked by a timer lockout;
- Local Challenger hand-route packets are now byte-bounded instead of failing before independent review.

## Remaining reds

1. **R1 Macro — hero support-hand anatomy / true vessel enclosure.** XR hands remain low-poly/open and lack reference-quality palm volume, progressive finger depth, web space, and readable thumb opposition.
2. **R2/Meso — whole-hand peel pinch quality and full-hand following of the lifted flap.**
3. **Café crumple Meso — final subjective contact/readability at other crumple strengths.** The 55% shell-contact contract is closed; do not start another root-offset sweep.
4. **Micro — skin, paper fibre, glass/liquid, residue, condensation.** Still frozen.

## Failed / rejected / prohibited repetition

- Do not use off-tree global-transform fixtures as product evidence for hand/shell contact.
- Do not resume crumple root-offset sweeps from the old `0.150` value; shell contact is now geometry-derived.
- Do not resume banned support-hand numeric pose searches: CCD, endpoint, grip-number, wrist/orbit/yaw/translation grids, per-finger grids, subdivision-density sweeps, or the rejected fixed-Cup CC0 source.
- Do not treat this Meso crumple improvement as R1 completion.
- Do not descend into decorative Micro polish while R1 remains dominant.

## Next exact action

1. Re-check for trustworthy live Blender/native-rig visual-authoring capability. If available, return immediately to R1 whole-hand support-grasp authoring against locked references.
2. If unavailable, inspect the newest exact-main interaction-step runtime frames and choose the next independent, objective Macro/Meso structural red.
3. Preserve base / partial-peel / inspect / crumple evidence; do not judge only idle frames.
4. Write the next Git checkpoint before any context boundary or after the next stable merge.
