# Peel Calm reference convergence checkpoint 62

Date: 2026-08-17
Main at checkpoint start: `6e8985f91ca37104febcab5bd429a8aaab91ec24`
Locked references: `cafe_v1 / bar_v1 / market_v1`

## Closed since checkpoint 61

- Market shoulder pseudo-cap root cause was fixed and merged in PR #79: deterministic ice is bounded to the clear-bottle body instead of staging in the shoulder/neck.
- Post-merge product baseline passed full Godot 4.7.1 verification and real-frame capture.
- Local Challenger packet overflow/SIGPIPE infrastructure was fixed in PR #80.
- Several follow-up verifier repairs removed an unstable second model-normalization pass, added deterministic report parsing, tolerated harmless Markdown formatting, and exposed parser/grounding failures without weakening exact-packet grounding.

## In-flight product PR #81 — readable market ice

Branch: `fix/market-ice-readability-v63`
Exact product head: `a1111173d1c8b46c4663f07aad77da5dd44ca995`

### TDD
- RED: `638a528cc7952b87b05eab202654f5c40a9c393d`, Godot Check `31985803654`.
- Failures were exact: opaque alpha=1, roughness=.28, saturated blue, vertical span=.006<.058, nearest pair=.111<.119.
- GREEN candidate Godot Check: `31985930395`.
- Exact runtime artifact: `9273768856`.
- PR exact-head Godot Check: `31986022300` PASS.

### Visual result
- Three market ice chunks are individually readable instead of merging into a cyan slab.
- Chunks are staggered in X/Y/Z and remain below `max_center_y=0.34` during motion.
- Glass ice is now translucent, wet, and near-neutral; paper-cup ice path is unchanged.
- Market shoulder stays clear in base/inspect/peel captures.

### Only blocker
Independent local Challenger infrastructure has repeatedly failed to emit/parse a stable protocol; no product defect has been proven. Do **not** merge PR #81 until an exact-head independent `VERDICT: VERIFIED` is obtained.

## In-flight product PR #86 — continuous glass edge response

Branch: `fix/glass-edge-fresnel-v68`
Exact head: `b18abcb0af6ce8bd321f5e27829789dcad62a928`

- RED: `f222da13ace0a09b1ad94bbd71814cec07bebdba`, Godot Check `31987682474`.
- First implementation correctly failed Godot 4.7.1 shader parsing because `CLEARCOAT_GLOSS` is obsolete.
- Fixed to `CLEARCOAT_ROUGHNESS`.
- Exact-head Godot Check `31987841941` PASS.
- Runtime artifact `9274315005` A/B-reviewed against main baseline artifact `9274372809`.
- `BottleEdgeFresnel` uses the same continuous lathed bottle mesh and `1 - dot(NORMAL, VIEW)` grazing response; no rectangular fake highlight guides.
- Visual result is safe/modest: no halo, no label washout, no detached outline. Clear market glass still needs stronger photographic separation later.
- PR #86 is open and must also receive independent exact-head verification before merge.

## Current independent-review infrastructure experiment

Branch: `fix/challenger-qwen7b-structured-v70`
Current head at checkpoint write: `7b149c41b8304d7e3ffb391242d3ecf97b048247`

Reason: Qwen 2.5 Coder 3B repeatedly consumed output on free-form analysis and sometimes emitted zero final protocol fields. Stop patching 3B formatting heuristically.

New approach under test:
- Qwen 2.5 Coder 7B;
- temperature 0;
- bounded `num_predict`;
- one exact-packet review call;
- output restricted to five labelled fields;
- deterministic parser + existing fail-closed evidence-anchor validator;
- no second model normalization call.

A real-model GitHub Actions smoke workflow (`Local Challenger Model Smoke`) is currently testing whether 7B reliably emits the required five-field protocol before this verifier change is eligible for merge.

## Ranked visual reds

### R1 — Hero support-hand anatomy / enclosure
Still the largest perceptual mismatch across references.

**Stop condition remains active:** do not restart blind numeric CCD/orbit/yaw/translation searches. Resume only with a true live/native-rig authoring workflow or structurally better hero-hand mesh/rig pipeline.

### R2 — Peel-hand whole-hand pinch choreography
Finger endpoints can approach the flap, but the whole-hand silhouette/contact does not yet match the photographic reference through the complete peel arc. Same hand-pipeline stop condition applies.

### R3 — Market ice readability
Implementation is complete in PR #81 and visually approved for this red; waiting independent verification/merge.

### R4 — Glass/liquid photographic cues
PR #86 is a safe first structural improvement using continuous Fresnel edge response. Bright-market glass still disappears too much against the cold-case backdrop and amber glass remains somewhat uniform.

### R5 — Label paper/torn-edge fidelity
Partial-peel frames still read as a smooth rectangular card. Current `LabelVisual` uses a 28-segment rectangular strip with fixed top/bottom extents and no deterministic deckle/torn-edge geometry. Next product loop after R3/R4 should attack deterministic paper-edge irregularity/thickness tied to peel quality, without random nondeterminism.

### R6 — final UI/commercial polish
After hero assets/materials reach reference quality.

## Do not repeat

- Do not infer screen-space ownership from semantic names; real-frame A/B already disproved the bottle-mouth hypothesis once.
- Do not accept CI green without runtime-frame comparison.
- Do not resume blind hand-pose parameter sweeps while the checkpoint 60/61/62 stop condition is active.
- Do not continue adding parsers around a 3B model that repeatedly fails the output contract; validate the 7B structural reviewer change instead.

## Resume protocol

1. Read this checkpoint + master prompt + multiscale skill.
2. Check `Local Challenger Model Smoke` for `fix/challenger-qwen7b-structured-v70` exact head.
3. If the real 7B protocol smoke passes, run full project CI, open/merge the verifier PR, then redispatch Challenger to **unchanged exact heads** PR #81 and PR #86.
4. Merge PR #81 only after exact-head VERIFIED; rerun main Godot/capture.
5. Merge PR #86 only after exact-head VERIFIED; rerun main Godot/capture.
6. Then begin R5 deterministic paper/torn-label edge TDD unless a new higher-impact non-hand red appears in post-merge frames.
