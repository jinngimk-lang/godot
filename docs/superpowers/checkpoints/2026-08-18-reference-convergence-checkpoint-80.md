# Reference Convergence Checkpoint 80 — Active-Peel Journey Rail

Date: 2026-08-18

## Restore source

- Previous checkpoint: `docs/superpowers/checkpoints/2026-08-17-reference-convergence-checkpoint-79.md`.
- Run-start `main`: `23570e6b2ec8e0dc2b4a339c5db843584b64c66a`.
- Run-start exact-main Godot Check: `32043745506` — PASS.
- Run-start nine-frame artifact: `9292426742`.
- Master prompt v3 and `.agents/skills/multiscale-reference-convergence/SKILL.md` were re-read before changing code.
- No open PR existed at restore time.
- Plugin/capability search again found no usable live Blender/native-rig/3D posing connector. Therefore the standing R1 numeric-pose STOP remains binding.

## Priority / mismatch ranking

1. **R1 remains dominant Macro red:** hero support-hand anatomy / real vessel enclosure. Current XR hand still lacks convincing palm volume, progressive finger depth, thumb opposition, and a natural wrap around the cup/bottle.
2. While R1 is tool-blocked, the next independent objective Macro issue in the interaction-step evidence was persistent bottom-center journey navigation chrome during active peel. The locked acceptance family calls for quiet top-left interaction UI; the `JourneyRail` occupied a 588×50 strip across the lower frame exactly during the reference-critical peel moment.
3. Micro material polish remains frozen behind unresolved lower-frequency reds.

## Falsifiable hypothesis

During an attached, already-started peel, hiding only the bottom `JourneyRail` should restore lower-frame negative space and make Café / Bar / Market interaction frames closer to the locked references, while keeping the quiet top-left scene/action guide, all gameplay, and pointer/touch scene navigation available before engagement and immediately after detach.

Scope exclusions: no camera, vessel, hand, peel physics, label geometry, progression, scene-selection authority, timer, punishment, economy, or material changes.

## RED

Branch: `fix/quiet-journey-rail-during-peel-v80`

RED exact head:

`1831ae392dc8dc85ca560167764dcacd52f05f88`

The deterministic journey presentation test was extended to require:

- `JourneyRail.visible == false` during an attached peel with progress > 0;
- rail restored after detach / post-interaction;
- rail still available before peeling starts;
- existing scene button and pointer-navigation contracts remain intact.

Godot Check `32046362873` failed at the Unit gate after import/default launch succeeded, proving the old implementation violated the active-peel visibility contract.

## GREEN implementation

Exact candidate head:

`683c4fbb3c682d68749d711c9dbdecdbfffea7aa`

Changed only:

- `scripts/presentation/guided_journey_presentation.gd`
- `tests/test_guided_journey_presentation.gd`

Implementation keeps a persistent `_rail` reference and a `_rail_visible` state. The rail is hidden only when `peel_progress > 0.001` and the interaction has not reached a detach/post-interaction phase. It remains visible at idle and returns immediately for `DETACHING`, `HELD`, `PEEL_SETTLE`, `CRUMPLE_READY`, `CRUMPLING`, or `RITUAL_COMPLETE` states.

No navigation action, scene-selection authority, or input path was removed.

## Exact-head verification

Candidate push Godot Check:

- Run `32046542062` — PASS.
- Exact head `683c4fbb3c682d68749d711c9dbdecdbfffea7aa`.
- Runtime artifact `9293093922`.
- Artifact digest `sha256:215df1f654452ec07f1ad80a60d9dd4b4a07179a35e1077da386a807a5344b18`.

PR #134 exact-head Godot Check:

- Run `32046631617` — PASS.
- Same exact head; no candidate drift.

## Real runtime visual comparison

Compared exact-main artifact `9292426742` against exact-candidate artifact `9293093922` in:

- `cafe_peel38.png`
- `bar_peel48.png`
- `market_peel45.png`

Observed result:

- the persistent 588×50 bottom JourneyRail is absent in all three active-peel frames;
- lower counter/table/background negative space is restored, most visibly in Market;
- hero vessel, both hands, lifted flap, camera, background composition, and quiet top-left interaction guide remain stable;
- deterministic tests retain rail availability before engagement and after detach.

Scoped Macro UI-clutter verdict: **PASS**.

This does **not** close R1 support-hand anatomy/enclosure or make the product reference-complete.

## Independent Challenger

PR #134 Challenger dispatch initially hit transient GitHub GraphQL HTTP 503 errors before reviewer execution. These were infrastructure failures, not product findings. The unchanged exact-head dispatch was retried.

Successful Local Independent Challenger:

- Run `32046900601` — PASS.
- Exact PR head validation, exact packet creation, schema review, deterministic grounding, comment, and verdict enforcement all passed.
- Grounded verdict: `VERIFIED` / `DEFECT: NONE`.
- The model emitted irrelevant extra `MIN_TEST/EVIDENCE` text while the exact grounding anchor was `NO_CONCRETE_DEFECT`; enforcement still passed, and the supposed test text contradicted no actual Godot result because both exact-head Godot runs were green.

Hosted Challenger also ran independently but is not required as a substitute for the grounded local gate when external model infrastructure is unavailable/failing.

## Merge and fresh-main proof

PR #134 was squash-merged with expected-head protection at unchanged head `683c4fbb3c682d68749d711c9dbdecdbfffea7aa`.

Product merge commit:

`0cabb0bfe8459923867998526a9a6a6681d1dc5e`

Fresh merged-main Godot Check:

- Run `32047222290` — PASS.
- Import/parse, default launch, unit, all presentation/smoke/reset/input gates, real frame capture, and upload all passed.
- New merged-main runtime artifact: `9293330002`.
- Digest: `sha256:c64adc5d2c4e02b4a9bf97def0edec150dd378e036d23c91fab67e79e2e48fe8`.

Merged `cafe_peel38`, `bar_peel48`, and `market_peel45` were re-inspected: the bottom rail remains absent during active peel and no integration regression was observed.

## Closed red

- Persistent bottom-center JourneyRail competing with active-peel reference framing: **closed**.

## Reds still open

- **R1 / dominant Macro:** hero support-hand anatomy and vessel enclosure.
- Whole-hand support gesture still reads open / synthetic rather than a natural stabilizing wrap.
- Peel-hand anatomy/whole-hand pinch remains below reference quality after the support-hand blocker.
- Higher-frequency skin, paper, glass, residue, and condensation detail remain deferred until lower-frequency structure allows them to matter.

## Do not repeat

Continue all prior R1 prohibitions:

- no CCD / endpoint chasing;
- no grip-number, per-finger angle, wrist/orbit/yaw/translation grids;
- no subdivision-density sweep on the current authored hand;
- no reuse of the rejected fixed-Cup CC0 FPS-arm source;
- no transform numeric search disguised as artist posing.

Newly closed scope:

- do **not** start a JourneyRail size/opacity/position sweep. Its active-peel ownership issue is closed; keep it available before engagement and after detach unless new acceptance evidence proves otherwise.

## Next exact action

At the next restore:

1. Read latest `main`, this checkpoint, active branches/PRs, exact-head CI, and newest screenshot artifact.
2. Check first for a genuine live Blender/native-rig visual-authoring capability. If available, immediately return to R1 whole-hand support pose and use real viewport evidence rather than numeric search.
3. If that capability is still absent, re-rank the fresh merged interaction frames and choose the next independent, objective Macro/Meso structural red. Do not descend into decorative Micro polish.
