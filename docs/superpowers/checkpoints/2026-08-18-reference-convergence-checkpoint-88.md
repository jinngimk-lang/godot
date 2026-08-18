# Reference Convergence Checkpoint 88 — flap-derived peel-hand yaw rejected

Date: 2026-08-18

## Recovery source

This run recovered from:

- `main@c8ae3c438258f45e27af8aa8efe8819245bd35bf`
- newest checkpoint: `docs/superpowers/checkpoints/2026-08-18-reference-convergence-checkpoint-87.md`
- checkpoint-87 integrated runtime artifact `9306956726`
- `docs/superpowers/prompts/2026-08-14-autonomous-reference-convergence-master-prompt-v3.md`
- `.agents/skills/multiscale-reference-convergence/SKILL.md`

Open-PR audit was empty at recovery. A fresh capability review still found no live Blender/native-rig visual-authoring integration in the available tool surface, so all established support-hand numeric-pose stop conditions remained active.

## Ranked reds at recovery

1. **R1 Macro — hero support-hand anatomy / true vessel enclosure.** Still the largest visual mismatch and still blocked from another CCD/grip/wrist/orbit/yaw/translation/per-finger numeric search.
2. **R2 Meso — whole-hand peel pinch / full-hand following of the lifted flap.** Checkpoint 87 grounded the idle pinch anchor on the real attached edge, but the active peel hand still visually reads as the same rigid faceted pinch/claw while the flap changes direction.
3. **Bare-arm anatomy / silhouette — generated limb remains tube-like.** Existing radius/path/cap/subdivision routes are already evidence-closed.
4. **Micro — skin, paper fibre, glass/liquid, residue, condensation.** Frozen while lower-frequency reds remain dominant.

## Scoped hypothesis

Keep gameplay as the sole owner of active peel-hand position and keep the authored pinch pose, vessel, camera, label geometry and peel physics unchanged. During active peel only, derive the right-hand root yaw from the **actual visible label centerline** returned by `LabelVisual.get_sample_points()`.

Falsifiable expectation: at Café 38%, Bar 48% and Market 45% peel, the whole hand should visibly turn with the lifted flap rather than reading as the same idle-oriented pinch shape.

No angle grid, yaw-factor sweep, CCD, endpoint optimizer or grip-number search was allowed.

Branch / PR:

- `fix/peel-hand-flap-frame-v89`
- draft PR #154

## RED

RED commit:

`cee8433d64381c4138dc31b50eb8fce780263e25`

The deterministic forearm/hand smoke gained a new contract:

- active peel choreography must expose a geometry-derived `_peel_follow_yaw_delta(progress, grip_local)`;
- a 45% lifted-paper sample must produce at least 8° of whole-hand yaw response.

The base implementation at checkpoint 87 had no such method and never changed active peel root rotation, so the new contract is a structural RED against the recovered source. A separate RED-only Actions run was not captured before the implementation commit; the RED commit is retained in Git to preserve the falsifiable sequence.

## Candidate implementation

Exact candidate head:

`23d504b4456dfdc0813a827f39198b8fc3746ef9`

Implementation boundary:

- active peel **position remains gameplay-owned** via the existing effective-grip path in `PeelLab` / `HandVisual`;
- `HandChoreographyPresentation` owns only active root orientation;
- yaw is computed from the signed XZ angle between the true free-tip label centerline tangent and the substrate tangent at the current attachment boundary;
- idle edge grounding from checkpoint 87 is unchanged;
- Café crumple still yields full peel-hand root ownership to `CrumpleHandStaging`;
- support hand, vessel, camera, label mesh/physics, timer, punishment and economy are unchanged;
- no tunable yaw factor or candidate sweep was added.

## Exact-head technical verification

Godot Check:

- run `32088646648`
- exact head `23d504b4456dfdc0813a827f39198b8fc3746ef9`
- result: **PASS**
- Godot 4.7.1 import/parse, default launch, unit, scene/reference/label/café/crumple/live-shell/contents/forearm/ritual/reset/pause/input isolation all PASS
- new flap-follow orientation contract passed in Forearm presentation smoke
- nine-frame capture PASS
- artifact `9307570605`
- digest `sha256:e208e4d6d840d58f870262cf43f04b280ea6323fe3f37dcb9b8b43988667898d`

## Runtime visual comparison

Baseline:

- checkpoint-87 artifact `9306956726`

Candidate:

- exact-head artifact `9307570605`

Inspected all nine real Godot frames, with focused full-resolution and thumbnail A/B on:

- `cafe_peel38.png`
- `bar_peel48.png`
- `market_peel45.png`

Scoped visual result: **REJECT / no material R2 gain**.

The geometry-derived yaw moves real pixels, but the perceptual result is negligible:

- Café partial peel: pixels with >5 RGB max-channel delta ≈ **0.12%**;
- Bar partial peel: ≈ **0.19%**;
- Market partial peel: ≈ **0.19%**.

At thumbnail and native resolution the peel hand still reads as essentially the same faceted pinch/claw silhouette. The whole-hand relationship to the lifted flap does not become materially more natural or reference-like. Base idle grounding and Café crumple remain stable, so this is not a regression-driven rejection; it is a **code-green / visual-no-gain** rejection.

Per the master prompt and multiscale skill, a technically green candidate that does not visibly improve the targeted Macro/Meso mismatch does not proceed to Challenger or production.

## PR disposition

PR #154 was explicitly reviewed as visual REJECT and then closed without merge.

- PR state: closed
- merged: false
- rejected exact head: `23d504b4456dfdc0813a827f39198b8fc3746ef9`
- no Challenger was run because the mandatory visual gate failed first.

Production `main` remains unchanged at `c8ae3c438258f45e27af8aa8efe8819245bd35bf` apart from this subsequent checkpoint documentation branch.

## Closed knowledge / failed experiment

This run closes the following hypothesis:

- **Deriving only whole-hand yaw from the real flap centerline is not enough to make the active peel hand visibly follow the paper at reference quality.**

Do not repeat this as:

- a yaw-factor multiplier sweep;
- 8/12/16/24° angle variants;
- a different tangent sample offset grid;
- another root-yaw-only rule;
- a claim that a larger numerical orientation response will necessarily improve the visible hand/flap relationship.

The evidence indicates that R2, like R1, is dominated by whole-hand anatomy/pose readability rather than a missing single root-yaw scalar.

## Remaining reds

1. **R1 Macro — hero support-hand anatomy / true vessel enclosure.** Current authored hands remain faceted/open and lack realistic palm volume, progressive index→pinky depth, web space and readable thumb opposition.
2. **R2 Meso/Macro — whole-hand peel pinch / lifted-flap following.** Idle contact is grounded, and root-yaw-only follow is now disproven; the visible whole-hand pose/anatomy must change structurally.
3. **Bare-arm anatomy / silhouette.** Current generated limb remains tube-like, with prior radius/path/cap/subdivision parameter routes closed.
4. **Micro — skin, paper fibre, glass/liquid, residue, condensation.** Frozen.

## Prohibited repetition

Carry forward all checkpoint-87 prohibitions:

- no support-hand CCD, endpoint chasing, master/finger grip-number sweeps, wrist/orbit/yaw/translation grids, per-finger numeric grids, subdivision-density sweeps or rejected fixed-Cup CC0 arm source;
- do not turn idle edge grounding into a root-offset/edge-position sweep;
- do not descend into decorative Micro polish while R1/R2 dominate.

New prohibition from checkpoint 88:

- **no peel-hand root-yaw / yaw-factor / tangent-offset sweep.** Root orientation alone produced technical movement without meaningful visual convergence.

## Next exact action

On recovery:

1. reread this checkpoint, master prompt v3 and multiscale skill;
2. inspect newest `main`, open branches/PRs, exact-head CI and newest runtime artifact;
3. check again for live Blender/native-rig visual-authoring capability;
4. if available, return immediately to structural whole-hand authoring, prioritizing R1 support grasp first and R2 lifted-flap pinch second;
5. if unavailable, do **not** reopen hand pose scalar searches. Select one independent, objective Macro/Meso structural red from the freshest interaction frames whose fix does not depend on pretending a bad hand mesh/pose can be solved by another transform coefficient;
6. retain exact-head Godot, runtime A/B, Challenger and fresh-integration gates before any future product merge.

Completion remains blocked by the locked-reference hand/anatomy gates and later owner aesthetic/playtest gates. CI green alone is not visual completion.
