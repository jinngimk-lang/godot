# Reference Convergence Checkpoint 87 — idle peel edge contact

Date: 2026-08-18

## Recovery source

This run recovered from:

- `main@e338f07ea6095eaa5c85831e7da91d796d165fb1`
- newest checkpoint: `docs/superpowers/checkpoints/2026-08-18-reference-convergence-checkpoint-86.md`
- checkpoint-86 runtime artifact `9305625772`
- master prompt v3 and `.agents/skills/multiscale-reference-convergence/SKILL.md` reread before work
- open PR audit found PR #151 `fix: ground idle peel hand on real label edge`

A fresh capability check still found no live Blender/native-rig visual-authoring integration. Existing R1 numeric-pose stop conditions therefore remain active.

## Ranked reds at recovery

1. **R1 Macro — hero support-hand anatomy / true vessel enclosure.** Still the largest visible mismatch and still prohibited from another CCD/grip/wrist/orbit/yaw/translation/per-finger numeric search.
2. **R2/Meso — whole-hand peel pinch / full-hand following of lifted flap.**
3. **Idle interaction-state Meso — untouched Café/Bar/Market frames showed the peel hand already making a pinch gesture while floating away from the actual attached paper edge.**
4. **Bare-arm anatomy / silhouette — generated limb remains tube-like; prior terminal-cap and subdivision routes are already disproven.**
5. **Micro — skin, paper fibre, glass/liquid, residue, condensation.** Frozen while lower-frequency reds dominate.

## Scoped hypothesis

Preserve the authored peel-hand pinch pose, venue rotation, gameplay target authority, camera, vessel and label geometry. Replace only the untouched idle root position with a translation derived from the live visible pinch anchor to `LabelVisual.get_front_position(0.0)`.

Falsifiable expectation: Café/Bar/Market base frames should read as fingertip-at-paper-edge rather than an OK-sign pinching air, while partial-peel and Café crumple remain unchanged.

Branch / PR:

- `fix/idle-peel-edge-contact-v88`
- PR #151

## RED

RED exact head:

`66b2040a08ae4683690c4fe77db24e737ba2be62`

Godot Check:

- run `32085551316`
- expected result: FAIL
- actual result: FAIL at Forearm/hand choreography smoke after earlier deterministic/reference/café/crumple/contents gates passed
- measured failure: `idle peel pinch ... gap 0.624 > 0.100`

The test settles `HandChoreographyPresentation` and measures the visible `RightHand.get_pinch_world_position()` against the live attached label front edge.

## GREEN exact candidate

Exact product head:

`6d686461c0c7f82aae1dc20498d5167c561a914d`

Implementation boundary:

- binds the live `PeelLabel` into `HandChoreographyPresentation`;
- for untouched `IDLE/EDGE_HOVER/RELEASED` with progress `<= 0.001`, computes root translation from the current visible pinch anchor to the actual attached label edge;
- keeps the authored pinch pose and venue rotation;
- progress after first lift still yields to gameplay hand target;
- Café crumple still yields to `CrumpleHandStaging`;
- no support-hand, camera, vessel, label geometry, peel-physics, timer, punishment or economy changes.

Godot Check:

- run `32085621455` — PASS
- artifact `9306603457`
- digest `sha256:089940fe8c89e8c8ae51e3e56ae7829227e93895b01ceac6ba820ada57b05973`

## Runtime visual comparison

Baseline:

- checkpoint-86 artifact `9305625772`

Candidate:

- exact-head artifact `9306603457`

Inspected all nine real Godot frames, with focused attention to Café/Bar/Market base plus partial-peel and Café crumple states.

Scoped result: **idle-contact Meso PASS**.

- Café/Bar/Market base frames now place the visible thumb/index pinch at the real attached paper edge rather than leaving the hand pinching open air.
- Partial-peel frames remain under gameplay target ownership and do not regress.
- Café crumple staging remains stable.
- R1 support-hand anatomy/enclosure is visibly still poor and is not closed by this change.

## Independent Challenger

PR #151 exact head remained unchanged at `6d686461c0c7f82aae1dc20498d5167c561a914d`.

Round 1 returned verifier `INFRA_FAILURE` with no grounded product defect.

Round 2 returned:

- `VERDICT: VERIFIED`
- `DEFECT: NONE`
- `MIN_TEST: NONE`
- `EVIDENCE: NO_CONCRETE_DEFECT | ANCHOR: NO_CONCRETE_DEFECT`
- bot report comment `5322087172`

No product change occurred between visual PASS and VERIFIED.

## Merge

PR #151 was squash-merged with expected-head protection only after exact-head Godot, runtime visual and independent Challenger gates passed.

Merged product commit:

`2db2eaa0bcd9ee7a44e8dc8450d1e6e195369372`

The product merge contains only:

- `scripts/presentation/hand_choreography_presentation.gd`
- `tests/test_forearm_presentation_smoke.gd`

## Fresh integrated-product proof

Checkpoint PR #152 was branched directly from merged product commit `2db2eaa0bcd9ee7a44e8dc8450d1e6e195369372`; its first documentation head `bdb306a415dd95d6f576c1f40be62e28410999fb` therefore exercised the real merged product tree plus this checkpoint file.

Godot Check:

- run `32086713581` — PASS
- Godot 4.7.1 import / launch / unit / scene / reference / label-surface / café / crumple / live crumpled-shell contact / contents / forearm / ritual / repeated reset / pause and reset isolation all PASS
- nine-frame capture PASS
- artifact `9306956726`
- digest `sha256:197ea8fad8db4a6eadca04f287d83c2914574d0b56ea34c455bbaea855e349be`

This is fresh integration verification after product merge, not reuse of the feature-branch GREEN.

## Closed reds

Closed in checkpoint 87:

- untouched/base interaction frames no longer show the peel hand visibly pinching far away from the real attached paper edge.

## Remaining reds

1. **R1 Macro — hero support-hand anatomy / true vessel enclosure.** Current XR hands remain faceted/open and lack realistic palm volume, progressive index→pinky depth, web space and readable thumb opposition.
2. **R2/Meso — whole-hand peel pinch / full-hand following of lifted flap.** Edge contact is now grounded at idle, but the entire hand still does not visually follow the lifted flap with reference-quality anatomy.
3. **Bare-arm anatomy / silhouette — current generated limb still reads tube-like.**
4. **Micro — skin, paper fibre, glass/liquid, residue, condensation.** Frozen.

## Prohibited repetition

- Do not resume support-hand CCD, endpoint chasing, master/finger grip-number sweeps, wrist/orbit/yaw/translation grids, per-finger numeric grids, subdivision-density sweeps, or rejected fixed-Cup CC0 arm sources.
- Do not turn this idle-edge fix into a root-offset or edge-position sweep; it is closed unless new runtime evidence identifies a specific regression.
- Do not use idle edge contact as evidence that R2 whole-hand pinch is solved.
- Do not descend into decorative Micro polish while R1/R2 remain dominant.

## Next exact action

On recovery:

1. read this checkpoint, master prompt v3 and multiscale skill;
2. inspect newest main/open PRs/branches, exact-head CI and newest nine-frame artifact;
3. check again for live Blender/native-rig visual-authoring capability;
4. if available, immediately return to R1 whole-hand support-grasp authoring against locked references;
5. otherwise select one independent falsifiable Macro/Meso structural red from the freshest interaction frames without reopening prohibited hand/forearm parameter searches;
6. preserve exact-head runtime comparison and Challenger gates before any next product merge.

Completion remains blocked by the locked-reference hand/anatomy gates and later owner aesthetic/playtest gates. CI green alone is not visual completion.
