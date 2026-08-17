# Peel Calm Reference Convergence — Checkpoint 77

Date: 2026-08-17

## Recovery source

Start the next run from repository evidence, not chat memory:

1. read this checkpoint;
2. read `docs/superpowers/prompts/2026-08-14-autonomous-reference-convergence-master-prompt-v3.md`;
3. read `.agents/skills/multiscale-reference-convergence/SKILL.md`;
4. inspect latest `main`, open PRs/branches, exact-head CI, and newest screenshot artifact;
5. re-check whether live Blender/native-rig visual authoring capability has become available before touching R1.

## Mainline state entering this loop

- Starting `main`: `ba76a084dbb1f17c2b5af75ec5a4d61883c56cdf` (`docs: checkpoint full bottle reference framing`).
- Starting fresh nine-frame artifact: `9290390548` from Godot Check `32035175394`.
- Locked reference family remains Café / Bar / Market; runtime frames remain evidence, not acceptance-target replacements.
- Highest visual red remained **R1 Macro: hero support-hand anatomy / vessel enclosure**. Current XR hand still lacks natural palm volume, thumb opposition, progressive finger depth and convincing wrap around the cup/bottle.
- Live Blender/native-rig/3D posing connector was re-checked this run and remained unavailable.
- Existing stop conditions remain active: do not resume CCD/endpoint chasing, semantic-grip scalar sweeps, wrist/orbit/yaw/translation grids, per-finger numeric pose grids, subdivision-density sweeps, rejected fixed-Cup model searches, or other disguised numeric hand-pose searches.

## Why this run did not fake R1 progress

Because the required direct visual native-rig authoring capability is still unavailable, this run did **not** substitute another numerical hand-pose search. Instead it closed a separate comfort-first product gap that already had owner evidence and a falsifiable deterministic contract: persistent adhesive loops were too foregrounded and read like background music instead of subtle peel texture.

This does not change the Macro/Meso visual priority ordering; it improves shippable interaction comfort while R1 remains tool-blocked.

## Superseded stale candidate

Old PR #102 (`fix: quiet continuous peel friction under tactile releases`) still expressed the desired product behavior but was stale/unmergeable against current `main`:

- old head: `571341738072622b55914b6f3de38e695e1362d9`;
- old base: `694af542407ea648f11501540a79fdf11f15a2cf`;
- current mergeability at recovery: false.

Its product intent was replayed cleanly on latest main instead of merging old ancestry. After the replay was merged, PR #102 was closed as superseded.

## RED — deterministic continuous-loop mix contract

Isolated branch: `fix/quieter-adhesive-foley-v77-mainline` from `main@ba76a084...`.

RED exact head:

`23dfbc8914635856f2634a3e3018c2a4b5960310`

Added `tests/test_peel_audio_mix.gd` and wired it into `tests/test_runner.gd`. Contract:

- inactive peel continuous loops must be exactly `(-80, -80) dB`;
- slow-peel worst-tension slow layer must stay `<= -22 dB` and remain quietly audible;
- fast-peel worst-tension fast layer must stay `<= -21 dB` and remain quietly audible;
- opposite-speed layer must remain at least 6 dB below the active layer at the endpoints;
- mid-speed crossfade must keep both continuous layers `<= -25 dB`;
- tactile event routes `paper_flex`, `micro_release`, `final_release` must remain present.

RED PR Godot Check:

- run `32036370298`;
- import/parse and configured default launch passed;
- failure occurred exactly at **Unit tests**, because production `PeelAudio` did not yet expose `get_continuous_mix_targets()`;
- later scene/capture stages were correctly skipped.

This is the intended falsification evidence, not an infrastructure failure.

## GREEN — bounded adhesive bed

GREEN exact candidate head:

`e7a66b3b5a578044a9c337a7790ae28804b95a40`

Production change is intentionally narrow:

- add pure `get_continuous_mix_targets(active, speed, tension)`;
- inactive returns `Vector2(-80.0, -80.0)`;
- normalize speed over 0–9 and cap tension lift to only +2 dB;
- slow target: `lerp(-24 + tension_lift, -39, speed_mix)`;
- fast target: `lerp(-39, -23 + tension_lift, speed_mix)`;
- `set_feedback()` consumes this helper;
- all tactile one-shot routing and hierarchy remain unchanged.

No hand, camera, product, label/residue, progression, peel physics, timers, punishment, economy or visual presentation behavior changed.

Exact-head Godot Check:

- run `32036423917` — **PASS**;
- Godot 4.7.1 import/parse — PASS;
- configured default launch — PASS;
- deterministic unit suite including new audio mix contract — PASS;
- all scene/reference/presentation/smoke/reset/input gates — PASS;
- nine-frame capture — PASS;
- artifact `9290851717`;
- digest `sha256:2f01d2e810fc872905f9cad37adb63054c4e0fe262de394d7b4a3f8ee8846e5c`.

Because this is audio-only, screenshot changes were not an acceptance target. Comparing the nine candidate frames with starting-main artifact `9290390548`, per-frame mean absolute RGB difference remained below 0.71/255; no visual-improvement claim is derived from this change.

## Independent Challenger

PR #128 exact head remained:

`e7a66b3b5a578044a9c337a7790ae28804b95a40`

Local Independent Challenger:

- run `32036638857` — **PASS**;
- exact PR head validation — PASS;
- exact-head review packet — PASS;
- schema-constrained independent review — PASS;
- deterministic parse and exact-packet grounding — PASS;
- report comment — PASS;
- `Enforce verdict` — PASS.

The workflow's enforce step succeeds only when `/tmp/review-report.txt` contains the exact line `VERDICT: VERIFIED`, so this run constitutes a grounded **VERIFIED** gate for the unchanged candidate.

The hosted Challenger was not required as merge authority; Local Challenger is the repository's available independent gate. No paid action, credential change or account intervention was performed.

## Merge and fresh-main proof

PR #128 was squash-merged with expected-head protection only after the unchanged exact candidate passed Godot + Challenger.

Merged product commit:

`5b8d29b4506c0fc1dff86907acb7ec57ec49a258`

Fresh merged-main Godot Check:

- run `32036985262` — **PASS**;
- import/launch/unit/all smoke and reset/input gates — PASS;
- fresh nine-frame capture — PASS;
- artifact `9291014859`;
- digest `sha256:fa23f0deaeb1cd4f61cb73f97ff19326d23035fd988cad7a81ece05af57fab78`.

Thus the integration proof does not reuse branch-green evidence.

## What this closes

Closed product/comfort red:

- continuous adhesive loops no longer rise into foreground-like levels under high tension;
- tactile one-shots remain the intended foreground interaction cues;
- inactive loops still fully quiet;
- old stale PR #102 no longer competes for ownership.

## What remains red

1. **R1 Macro — hero support-hand anatomy / vessel enclosure.** Still the largest reference mismatch and not improved by this audio change.
2. **R2 Meso — whole-hand peel pinch.** The hand must follow and visibly pinch the lifted paper as a whole, not merely satisfy point contact.
3. Other Macro/Meso scene/object/material issues may be selected only when independently visible and falsifiable if live native-rig capability remains unavailable.
4. Micro skin/paper/glass/residue/condensation polish remains lower priority while a dominant lower-frequency red exists.

## Owner playtest gate

The dB envelope is objectively bounded and verified, but final subjective audio taste cannot be proven by headless CI. Owner playtest should confirm that the continuous adhesive bed now feels like subtle friction rather than BGM, while paper-flex/micro-release/final-release cues remain satisfying and non-fatiguing.

Do not call audio 'perfect' before that playtest.

## Failed / forbidden repeats

Carry forward checkpoint 76's complete stop list. Add:

- do not re-open stale PR #102 or merge its old ancestry;
- do not perform a broad continuous-audio volume sweep without new owner/playtest evidence; the current bounded envelope is now the deterministic baseline;
- do not treat visual frame noise from an audio-only branch as visual convergence.

## Next exact action

At next recovery:

1. read latest main + checkpoint + master prompt + multiscale skill;
2. inspect latest nine interaction frames;
3. re-check availability of a live Blender/native-rig visual authoring connector;
4. if available, return immediately to R1 and perform exactly one direct visual whole-hand support-grasp authoring loop against locked Café/Bar/Market references;
5. if still unavailable, preserve the R1 stop condition and select one new, independent, objective Macro/Meso red from the fresh merged-main frames; do not descend to decorative Micro polish merely because R1 is tool-blocked.
