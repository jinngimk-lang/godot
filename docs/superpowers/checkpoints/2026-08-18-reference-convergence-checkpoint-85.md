# Reference Convergence Checkpoint 85 — One persistent top-left HUD; forearm terminus hypothesis falsified

Date: 2026-08-18

## Recovery source

This run started from:

- `main@c69e84256c3fd66724e41cd975cb29f9e7d7ebaa`
- newest checkpoint: `docs/superpowers/checkpoints/2026-08-18-reference-convergence-checkpoint-84.md`
- checkpoint-84 exact runtime artifact `9303571967`
- no open product PRs at recovery
- master prompt v3 and `.agents/skills/multiscale-reference-convergence/SKILL.md` reread before work
- locked acceptance manifest reread; runtime/staging screenshots remain evidence only and cannot replace `cafe_v1`, `bar_v1`, or `market_v1`

No installable Blender / native-rig / 3D model-editing plugin was available in this run. The R1 numeric-pose stop conditions therefore remained active.

## Ranked reds at recovery

1. **R1 Macro — hero support-hand anatomy / true vessel enclosure.** Still dominant and still not eligible for another CCD/grip/wrist/orbit/yaw/translation/per-finger numeric search.
2. **Macro/UI — two persistent stacked top-left panels duplicate venue/action information.** `ReferenceHudPanel` already showed venue/progress/hint/inputs while `JourneyGuide` immediately below repeated scene identity and peel/post-action text.
3. **R2/Meso — whole-hand peel pinch / full-hand following of the lifted flap.**
4. **Bare-arm anatomy — current forearms still read tube-like in Bar/Market, but the causal mechanism needed objective testing before geometry edits.**
5. **Micro — skin/paper/glass/residue/condensation detail.** Frozen.

## Failed experiment first: bare-forearm terminal-cap hypothesis

Visual observation from the checkpoint-84 Bar/Market frames: the left bare forearm enters from the image edge with a pointed/tapered read that can resemble an amputated tube.

Scoped hypothesis tested on isolated branch:

`fix/forearm-offscreen-termination-v85`

No production geometry was changed. Three increasingly direct screen-space contracts were added sequentially against the unchanged forearm mesh:

1. **Far cap center must be outside the viewport.**
   - test head `c9a9d83a2863edd827260a0f1c9a27c112ae51da`
   - Godot Check `32080770443` — PASS
2. **Whole terminal ring must be outside the viewport.**
   - test head `6ca2064bb5df62cbe44b2eb21b0ed0af3e456b12`
   - Godot Check `32080884557` — PASS
3. **Terminal ring must be at least one of its own projected diameters beyond the viewport.** This rejects a frame cut through the last taper section even when the cap itself is technically offscreen.
   - test head `7acafd75bc4afc830cfec77af9fcfc4dc5ffc01e`
   - Godot Check `32081020936` — PASS

Result: **hypothesis falsified**. The current forearm terminus is already well beyond the frame. Extending the far endpoint would therefore be an unsupported geometry tweak and a disguised parameter search, not an evidence-backed fix.

Draft PR #145 was closed unmerged. It contains tests only; production `main` was never modified by this experiment.

### Do not repeat

- Do not extend the current bare-forearm terminus to fix the visible tube/wedge read.
- Do not re-test cap-center or terminal-ring offscreen clearance unless camera/forearm geometry is materially replaced later.
- Preserve the broader visual observation that the bare arm still looks generated/tube-like, but attribute it to anatomy/silhouette/cross-section/whole-limb design rather than terminal-cap clearance unless new evidence proves otherwise.

## Product hypothesis: remove duplicated persistent top-left journey chrome

The checkpoint-84 runtime used two stacked persistent top-left panels:

- `ReferenceHudPanel` at the top, already carrying venue, peel progress/hint and input affordances;
- `JourneyGuide` immediately below, repeating scene identity and peel/post-action text.

The bottom `JourneyRail` already provides explicit three-scene pointer/touch identity and navigation before engagement, and Continue remains a dedicated post-detach control.

Falsifiable hypothesis:

> Keep `GuidedJourneyPresentation` as the journey state/navigation owner, keep its internal action text, bottom rail and Continue behavior, but remove only the second persistent top-left `JourneyGuide` visual panel. The nine reference frames should gain top-left negative space without losing scene navigation or interaction discoverability.

Isolated product branch:

`fix/deduplicate-top-left-journey-v85`

## RED

RED exact head:

`b6afa3d52dc07b9ed626897d3c2378db4fcc3a76`

Godot Check:

- run `32081344797`
- expected result: FAIL at deterministic Unit gate
- actual result: FAIL at deterministic Unit gate because the old implementation still rendered a separate persistent `JourneyGuide`
- import, launch and verifier self-test preceding the Unit gate remained healthy

The new contract preserved all journey semantics while requiring:

- `JourneyRail` remains present with all Café / Bar / Market scene buttons;
- internal `get_action_text()` and scene index semantics remain correct;
- active peel / inspection / crumple rail suppression remains correct;
- post-detach and idle navigation restore remains correct;
- legacy Reward stays hidden;
- Continue stays beside the rail;
- **no separate persistent top-left `JourneyGuide` node is rendered.**

## GREEN exact candidate

Exact product head:

`6990ed8103273d24039213492cb014f5f78f026c`

Implementation scope:

- removed only the persistent top-left `JourneyGuide` panel plus its `SceneStatus` and `Action` labels;
- kept journey state, `_action_text`, scene index, pointer/touch `JourneyRail`, scene buttons, rail quieting rules, Continue positioning and legacy Reward suppression;
- did not modify camera, vessel, hand pose, label geometry, peel physics, inspection authority, crumple, progression or Micro materials.

Exact-head Godot verification:

- Godot Check `32081406889` — PASS
- Godot 4.7.1 import / configured launch / unit / scene / reference / café / crumple / live crumpled-shell contact / contents / forearm / ritual / repeated reset / pause and reset input isolation all PASS
- nine-frame capture PASS
- artifact `9305232699`
- digest `sha256:a0c53c615e902c573ff4a71fe3e1033f9f007ca9458738809ceee29ee68c62af`

## Runtime visual comparison

Baseline:

- checkpoint-84 artifact `9303571967`

Candidate:

- exact-head artifact `9305232699`

Inspected all nine Café / Bar / Market interaction frames plus direct baseline/candidate comparisons.

Scoped visual result: **Macro/UI PASS**.

- Café / Bar / Market base frames now have one compact persistent top-left information panel instead of two stacked panels.
- The removed panel duplicated scene/action information already inferable from the compact HUD plus bottom scene rail.
- Active peel frames retain the prior quiet lower-frame behavior; removing the second top-left panel restores additional acceptance-photography negative space rather than moving chrome elsewhere.
- Inspection and Café crumple frames remain quiet at the bottom per checkpoints 82/84.
- `cafe_crumple55` still exposes `Continue to Bar` after detach while the duplicate top-left journey panel is absent.
- Hero vessel, camera, support/peel hands, flap, crumple deformation and backgrounds are visually unchanged apart from the intended UI removal.

This scoped PASS does **not** close R1 hand anatomy/enclosure or R2 peel-hand quality.

## Independent Challenger

The first manual dispatch comment used a non-numeric `TASK_ID` and was rejected by the repository's dispatch contract before product review. It is invocation noise, not a product finding.

A corrected single explicit dispatch used:

- `TASK_ID: 1468501`
- PR #146
- exact head `6990ed8103273d24039213492cb014f5f78f026c`
- round 1

Local Challenger result on the unchanged exact head:

- `VERDICT: VERIFIED`
- `DEFECT: NONE`
- `MIN_TEST: NONE`
- `EVIDENCE: NO_CONCRETE_DEFECT | ANCHOR: NO_CONCRETE_DEFECT`
- PR bot report comment `5321580573`

No product change occurred between visual PASS and VERIFIED.

## Merge

PR #146 was marked ready only after the exact-head Godot + visual gates and independent Challenger had passed, then squash-merged with expected-head protection.

Merged product commit:

`985efb1763fe94349e290d9401030421819995ff`

The merge contains only:

- `scripts/presentation/guided_journey_presentation.gd`
- `tests/test_guided_journey_presentation.gd`

## Closed reds

Closed in checkpoint 85:

- persistent top-left scene/action duplication between `ReferenceHudPanel` and `JourneyGuide`;
- top-left UI now uses one persistent compact hierarchy while journey navigation remains available through the bottom rail before engagement and Continue after detach.

Falsified, not closed by product code:

- bare-forearm visual truncation is **not** caused by the far terminal cap/ring being too near the viewport.

## Remaining reds

1. **R1 Macro — hero support-hand anatomy / true vessel enclosure.** Still the largest visible mismatch. Current XR hands remain faceted/open and lack realistic palm volume, progressive index→pinky depth, web space and readable thumb opposition.
2. **R2/Meso — whole-hand peel pinch / full-hand following of lifted flap.** Current peel hand still reads more like a stylized claw/pinch than the locked photographic target.
3. **Bare-arm anatomy / silhouette — generated tube-like limb read.** Terminal clearance has been disproven as the cause; only a structurally different anatomy/silhouette hypothesis is eligible next.
4. **Micro — skin, paper fibre, glass/liquid, residue, condensation.** Frozen while lower-frequency reds dominate.

## Prohibited repetition

- Do not resume support-hand CCD, endpoint chasing, master/finger grip-number sweeps, wrist/orbit/yaw/translation grids, per-finger numeric grids, subdivision-density sweeps, or the rejected fixed-Cup CC0 arm source.
- Do not extend the current forearm terminus or sweep its endpoint based on the visible edge wedge; three exact screen-space contracts disproved that mechanism.
- Do not add a second top-left journey panel back by moving/re-sizing/re-opacity-sweeping it. Journey semantics remain in state + rail + Continue; persistent chrome is intentionally deduplicated.
- Do not start a JourneyRail size/opacity/position sweep from this checkpoint.
- Do not descend into decorative Micro polish while R1/R2 remain dominant.

## Next exact action

On recovery:

1. read this checkpoint, master prompt v3 and multiscale skill;
2. read newest `main`, open PRs/branches, exact-head CI and newest nine-frame artifact;
3. check again for a real live Blender/native-rig visual-authoring capability;
4. if available, immediately return to R1 whole-hand visual authoring against locked references;
5. if still unavailable, inspect the fresh interaction frames and choose one independent, falsifiable Macro/Meso structural red that does not reopen prohibited hand/forearm parameter searches;
6. preserve the lesson from PR #145: a visually plausible causal story must RED against the actual camera/render geometry before production code is changed.

Completion remains blocked by the locked-reference hand/anatomy gates and later owner aesthetic/playtest gates. CI green alone is not visual completion.
