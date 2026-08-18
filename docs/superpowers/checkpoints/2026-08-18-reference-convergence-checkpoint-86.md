# Reference Convergence Checkpoint 86 — Market citrus print identity

Date: 2026-08-18

## Recovery source

This run recovered from:

- `main@16ecec2f3b858a352ed2cb183c046b0cbcb0c5d3`
- newest checkpoint: `docs/superpowers/checkpoints/2026-08-18-reference-convergence-checkpoint-85.md`
- checkpoint-85 runtime artifact `9305232699`
- master prompt v3 and `.agents/skills/multiscale-reference-convergence/SKILL.md` reread before work
- open PR audit found draft PR #148 `fix: strengthen market citrus label identity`

A fresh plugin-capability search again found no installable Blender/native-rig/3D model-editing integration. Existing R1 numeric-pose stop conditions therefore remained active.

## Ranked reds at recovery

1. **R1 Macro — hero support-hand anatomy / true vessel enclosure.** Still the largest visible mismatch and still prohibited from another CCD/grip/wrist/orbit/yaw/translation/per-finger numeric search.
2. **Market Meso identity — locked reference carries Japanese citrus identity plus a fruit/citrus motif; runtime label still read as English `YUZU` plus a generic yellow dot.**
3. **R2/Meso — whole-hand peel pinch / full-hand following of lifted flap.**
4. **Bare-arm anatomy / silhouette — generated tube-like read; checkpoint 85 already falsified terminal-cap clearance as the cause.**
5. **Micro — skin/paper/glass/residue/condensation.** Frozen.

## Scoped hypothesis

Keep label geometry, color family, glass, camera, hands and gameplay unchanged. Strengthen only the Market print content with:

- a visible Japanese `柚子` cue;
- one simple radial citrus-slice motif replacing the generic dot.

Falsifiable expectation: Market base/inspect/partial-peel frames should gain product identity at Meso scale without changing the other scene families or lower-frequency composition.

Branch / PR:

- `fix/market-label-identity-v86`
- PR #148

## RED

Initial RED exact head:

`85b5588d2c2beb487b49aa71fe0da9df7a3886cd`

Godot Check:

- run `32082301170`
- expected result: FAIL
- actual result: FAIL at deterministic Unit gate because current Market print still lacked `柚子` and still used the generic `●` accent

The test directly instantiates `LabelPrint`, applies the YUZU theme, and inspects `PrintRoot/Note` and `PrintRoot/Accent`.

## First implementation attempt — infrastructure/test fixture failure

Implementation head:

`7481c897812094b38895822a1c48dedcc5f6ab20`

The product implementation changed only:

- `CITRUS • 330 ml` → `柚子 • CITRUS • 330 ml`
- `●` → `✹`

Godot Check `32082595327` failed before product assertions were evaluated because Godot 4.7.1 could not infer the type of `print_view := print_script.new()` in the new test fixture.

This was a test parse failure, not a product visual failure. The fixture was corrected to explicit `SubViewport` typing; the Market implementation was unchanged.

## GREEN exact candidate

Exact product head:

`9bb8e8ea8d7ce01cacd974870966be760b3fafcd`

Godot Check:

- run `32082689319` — PASS
- Godot 4.7.1 import / default launch / unit / scene / reference / label-surface / café / crumple / live crumpled-shell contact / contents / forearm / ritual / repeated reset / pause and reset input isolation all PASS
- nine-frame capture PASS
- artifact `9305625772`
- digest `sha256:4fc124ad5d02d7ae3ff0ca47de9370af1e625f2b338702409884fef36e3faec1`

## Runtime visual comparison

Baseline:

- checkpoint-85 artifact `9305232699`

Candidate:

- exact-head artifact `9305625772`

Inspected all nine frames, with focused native-resolution crops of:

- `market.png`
- `market_inspect.png`
- `market_peel45.png`

Scoped result: **Meso identity PASS**.

- `柚子` is rendered next to the existing citrus/volume line and remains visible on the curved label in the base frame.
- The old generic yellow dot is replaced by a small radial `✹` mark that reads closer to a citrus cross-section at product distance.
- The green cap, clear glass, ice, label geometry, hands, camera, inspection and partial-peel silhouettes remain otherwise unchanged.
- Café and Bar presentation are unaffected by the Market-only theme path.

This does **not** close R1 hero-hand anatomy/enclosure and does not authorize Micro polish.

## Independent Challenger

PR #148 exact head remained unchanged at `9bb8e8ea8d7ce01cacd974870966be760b3fafcd`.

Local Challenger dispatch:

- task `1488601`
- round 1

Grounded result:

- `VERDICT: VERIFIED`
- `DEFECT: NONE`
- `MIN_TEST: NONE`
- `EVIDENCE: NO_CONCRETE_DEFECT | ANCHOR: NO_CONCRETE_DEFECT`
- bot report comment `5321708527`

No product change occurred between visual PASS and VERIFIED.

## Merge

PR #148 was marked ready only after exact-head Godot, runtime visual and independent Challenger gates passed, then squash-merged with expected-head protection.

Merged product commit:

`2384bd281512617a07e6361d0ffe882f7e5648bb`

The product merge contains only:

- `scripts/peel/label_print.gd`
- `tests/test_label_print_contract.gd`

## Closed reds

Closed in checkpoint 86:

- Market printed label now carries the locked-reference Japanese yuzu identity cue;
- Market printed label no longer uses a generic circular accent as its only citrus motif.

## Remaining reds

1. **R1 Macro — hero support-hand anatomy / true vessel enclosure.** Current XR hands remain faceted/open and lack realistic palm volume, progressive index→pinky depth, web space and readable thumb opposition.
2. **R2/Meso — whole-hand peel pinch / full-hand following of lifted flap.**
3. **Bare-arm anatomy / silhouette — current generated limb still reads tube-like; terminal-cap clearance is already disproven as the cause.**
4. **Micro — skin, paper fibre, glass/liquid, residue, condensation.** Frozen while lower-frequency reds dominate.

## Prohibited repetition

- Do not resume support-hand CCD, endpoint chasing, master/finger grip-number sweeps, wrist/orbit/yaw/translation grids, per-finger numeric grids, subdivision-density sweeps, or the rejected fixed-Cup CC0 arm source.
- Do not extend/sweep the current forearm terminus; checkpoint 85 disproved that mechanism.
- Do not start a Market label font-size/color/motif-position sweep from this change. The scoped identity cue is closed unless new reference evidence shows a specific mismatch.
- Do not descend into decorative Micro polish while R1/R2 remain dominant.

## Next exact action

On recovery:

1. read this checkpoint, master prompt v3 and multiscale skill;
2. inspect newest main, open PRs/branches, exact-head CI and newest nine-frame artifact;
3. check again for live Blender/native-rig visual-authoring capability;
4. if available, immediately return to R1 whole-hand support-grasp authoring against locked references;
5. if unavailable, inspect the freshest interaction frames and select one independent falsifiable Macro/Meso structural red that does not reopen prohibited hand/forearm parameter searches;
6. preserve exact-head runtime comparison and Challenger gates before any next product merge.

Completion remains blocked by the locked-reference hand/anatomy gates and later owner aesthetic/playtest gates. CI green alone is not visual completion.
