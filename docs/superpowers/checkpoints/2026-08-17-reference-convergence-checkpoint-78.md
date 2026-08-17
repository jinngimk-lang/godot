# Reference convergence checkpoint 78 — bottle backdrop coverage

Date: 2026-08-17

## Recovery source

- Product base entering this loop: `main@e6474ee45aed4e02b65e551528cfb63b0f4df435`.
- Starting fresh Godot Check: `32037162350` — PASS.
- Starting nine-frame artifact: `9291065208` (`peel-calm-reference-frames`).
- Product merge from this loop: PR #130, squash commit `04ce281bd5137cb6163c30a473d33ee7b6a446d9`.
- Fresh merged-main Godot Check: `32040394144` — PASS.
- Fresh merged-main nine-frame artifact: `9291843141`, digest `sha256:eedc7dac03a789600a4e5d6375c8f70a311a32a15777f2647583e2a5965675f2`.

## Files / contracts read before work

- newest checkpoint before this loop: checkpoint 77;
- `docs/superpowers/prompts/2026-08-14-autonomous-reference-convergence-master-prompt-v3.md`;
- `.agents/skills/multiscale-reference-convergence/SKILL.md`;
- current `main`, open PR state, current Godot CI, latest runtime artifact;
- `scripts/presentation/reference_backdrop.gd` and `scripts/presentation/reference_composition.gd`.

## Ranked mismatch selected

R1 hero support-hand anatomy / vessel enclosure remains the dominant project-wide Macro red, but the current runtime still has no live Blender/native-rig visual-authoring connector and all prior numeric hand-pose search families remain stopped.

The highest-value independent Macro defect visible in the fresh nine-frame artifact was therefore selected instead: after bottle framing widened to 48 degrees, Bar and Market exposed obvious world-clear black wedges at the image margins. Café, which remains at the tighter 39-degree FOV, did not show the same failure.

This defect was lower-frequency and higher-impact than remaining material micro-polish because it broke the venue image plate itself in every bottle interaction state.

## Falsifiable hypothesis

`ReferenceBackdrop.TARGET_WORLD_WIDTH = 7.45` was still sized for the older/tighter reference framing. With the live camera at `(0.0, 0.80, 3.55)`, focus `(0.0, 0.15, 0.0)`, backdrop plane `z = -1.43`, 16:9 aspect, and bottle FOV 48 degrees, geometric viewport coverage requires about `8.014` world units, or `8.335` with 4% overscan.

If this is the cause, increasing only the backdrop world width to a bounded `8.40` should remove the black wedges while leaving camera/FOV, bottle, hands, label, interaction and gameplay unchanged.

## RED

Isolated branch: `fix/bottle-backdrop-coverage-v78`.

RED exact head: `37235f1baeb2e2c8926d66c9baf291f4cf120237`.

A deterministic contract was added to the existing venue-presentation test. It derives the required world width from the live camera/backdrop geometry and asserts that the reference plate covers the 48-degree bottle camera with 4% overscan.

Godot Check `32039839813` failed exactly at the new contract:

`bottle reference backdrop must cover 48-degree camera with overscan (7.450 < 8.335)`

Import, parse and configured launch passed before the expected unit failure.

## GREEN implementation

Exact candidate head: `20ecdd2f1aeb79af9f5e51341ee8520282061968`.

Only `ReferenceBackdrop.TARGET_WORLD_WIDTH` changed from `7.45` to `8.40`, plus the deterministic coverage contract. No camera/FOV, hero object, hand, label, table, material, input, progression or gameplay authority changed.

Exact-head push Godot Check `32039925344` — PASS.

Candidate runtime artifact: `9291753191`, digest `sha256:926dd729925296affb79413d21729ef65a8954bca48e10367ef6928757b22352`.

PR-triggered exact-head Godot Check `32040027131` — PASS on the same candidate SHA.

## Real runtime visual comparison

Frames inspected against starting artifact `9291065208`:

- `bar.png`
- `bar_inspect.png`
- `bar_peel48.png`
- `market.png`
- `market_inspect.png`
- `market_peel45.png`
- `cafe.png`

Visual verdict: PASS for the scoped Macro defect.

- The large exposed black wedge at the left side of Bar is removed in base, inspect and partial-peel states.
- The exposed black side region in Market is removed in base, inspect and partial-peel states.
- Bottle framing, labels, hand choreography and interaction state silhouettes remain stable.
- Café remains visually stable under its tighter 39-degree framing.
- The fix does not close R1 and does not make the project reference-complete.

## Independent Challenger

PR #130 exact head remained `20ecdd2f1aeb79af9f5e51341ee8520282061968`.

The first owner comment dispatch reached the Codex workflow but GitHub returned a transient HTTP 503 when dispatching the local Challenger. No product code was changed in response to that infrastructure failure.

Round 2 successfully dispatched the local exact-head Challenger:

- run `32040152192` — PASS;
- exact-head validation — PASS;
- exact review packet construction — PASS;
- schema-constrained independent review — PASS;
- deterministic parser / grounding — PASS;
- final enforced verdict: `VERIFIED`, `DEFECT: NONE`.

## Merge and fresh-main proof

PR #130 was merged only after exact-head CI, real-frame visual improvement and the grounded independent Challenger all passed.

Expected-head protected squash merge produced product commit:

`04ce281bd5137cb6163c30a473d33ee7b6a446d9`

Fresh merged-main Godot Check `32040394144` — PASS.

Fresh merged-main artifact: `9291843141`.

This fresh-main proof replaces branch-green as the integration authority.

## Closed red

Closed: Bar / Market 48-degree reference framing no longer exposes world-clear black side wedges because the dedicated image plate now covers the widest live camera with explicit overscan.

## Remaining reds

1. **R1 Macro — hero support-hand anatomy / vessel enclosure.** Current XR hand remains low-poly/open, lacks realistic palm volume, progressive index→pinky depth and clear thumb opposition, and still does not read like the locked references' firm support grip.
2. **R2 Meso — whole-hand peel pinch anatomy/contact.** Existing capture/contact correctness is substantially better than earlier states, but the hand anatomy itself remains prototype-like.
3. Remaining vessel/paper/light detail is subordinate; do not descend into decorative Micro polish while the above lower-frequency reds dominate.

## Failed / forbidden repeats

Continue to avoid:

- CCD / endpoint chasing / contact-servo hand posing;
- semantic grip-number sweeps;
- wrist/orbit/yaw/translation grids;
- per-finger numeric angle grids;
- authored-hand subdivision-density sweeps;
- the rejected fixed-Cup CC0 FPS-arm source plus alignment searches;
- forearm radius/control-point/overlap sweeps already closed in earlier checkpoints;
- backdrop-width sweep beyond the now contract-derived coverage value unless a future camera/aspect contract objectively changes.

## Next exact action

At the next recovery:

1. read latest `main`, this checkpoint, active PRs/branches, exact-head CI and newest merged-main screenshot artifact;
2. check first for a genuinely available live Blender/native-rig visual-authoring capability; if present, immediately return to R1 whole-hand direct visual authoring;
3. if still unavailable, inspect the fresh `9291843141` interaction-step frames and choose exactly one independent, objective Macro/Meso defect that does not violate the hand-pose stop condition;
4. write RED where objective, isolate the change, run exact-head Godot 4.7.1, inspect real runtime frames, independently challenge, merge only on technical + visual improvement, then write the next checkpoint.

Do not claim release/reference completion from this scoped fix.
