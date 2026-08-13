# Peel Calm Shared Project Knowledge

This file is a compact operational memory for both repository agents. It does not replace specs, plans, tests, Git history, or owner playtest evidence; agents must inspect those sources when a detail matters.

## Product thesis

Peel Calm is a relaxing tactile/ASMR game about peeling printed café-style production/order labels from drink cups. The core fantasy is not speed or difficulty: it is the physical satisfaction of catching an edge, feeling adhesive resistance, hearing paper/tape Foley, releasing the last bond, and holding a cleanly removed label.

The product frame is closer to a `Coffee Ritual ASMR / Micro-Tactile Relaxation` experience than a generic sticker minigame.

## Owner intent

- Build the canonical complete project in GitHub first.
- The owner downloads/clones it and imports `project.godot` into local Godot without hand assembly or hidden dependencies.
- Test repeatedly and prefer evidence over confidence.
- Normal reversible implementation decisions are autonomous; do not repeatedly ask the owner.
- The owner supplies local screenshots/feel feedback after a substantial playable delivery.
- When model assets become important, keep them repository-local, auditable, and preview/reviewable.

## Platform and engine

- Godot 4.7.1.
- GDScript.
- PC mouse first, touch-ready architecture for later mobile adaptation.
- Runtime must not require Blender, an AI model service, private environment variables, external downloads, or third-party Godot plugins.

Pointer contract remains device-neutral:

```text
pressed: bool
position: Vector2
relative: Vector2
velocity: Vector2
released_this_frame: bool
```

## Interaction philosophy

Priority order:

1. adhesive resistance/release feel;
2. believable responsive audio;
3. readable hand/label contact;
4. cup/label material quality;
5. completion/reward satisfaction;
6. content breadth;
7. meta systems.

Do not add timers as a core pressure mechanic. Progression should unlock more satisfying things to peel, not merely harder things.

## Proven core architecture

Gameplay authority:

`PointerAdapter -> PeelController -> PeelModel`

Presentation consumes gameplay state but does not decide whether peel progress succeeds.

Label lifecycle introduced after owner V1 feedback:

`ATTACHED -> PEELING -> DETACHING -> HELD`

Completion invariant: after final detach, held-label geometry has no cup anchor.

## Owner V1 feedback that must never regress

V1 failed because:

- `100% / COMPLETE` visually remained connected to the cup as a stretched ribbon;
- hands looked like abstract block/capsule proxies;
- synthetic oscillator/noise audio sounded abstract;
- order text visually separated from the deforming label.

V2 addressed these with:

- explicit detach lifecycle;
- bounded peel geometry plus cup-independent held geometry;
- dynamic print rendered into the label material;
- repository-local rigged hand GLBs with `Cup` and `Pinch Tight` authored poses, plus procedural fallback;
- repository-local CC0-derived paper/tape Foley and provenance ledgers.

Agents must add regression tests when touching these areas.

## Sensory model

Desired peel rhythm:

`pull -> resistance -> local adhesive release -> small relaxation -> repeat -> final separation`

Key variables include base adhesion, release hysteresis, speed response, peel-angle response, micro-variation, damping, and release increment.

Mouse/pointer drives a desired hand/grip target, not raw label translation. The visible right hand follows with damped lag. Unpeeled label follows the cup surface; detached material bends/curls. Avoid a full cloth dependency unless evidence proves the lightweight solver cannot reach the target feel.

## Audio model

Audio is a second physics engine. It should react to actual interaction state rather than play generic ambience only.

Current event vocabulary:

- slow adhesive;
- fast adhesive;
- paper flex/crinkle;
- micro release;
- final release.

Use sample variation conservatively to avoid repetition. Do not reintroduce synthetic placeholder noise as the normal presentation path.

## Visual direction

Selected direction: semi-realistic, clean, calming hands. Recognizable anatomy, readable thumb/index pinch, relaxed other fingers, restrained material detail; not hyper-photoreal skin pores.

Cup/scene direction: calm close-up tabletop, generic fictional café presentation. Do not replicate Starbucks, Luckin, or other real brand marks/trade dress.

## Content/progression direction for the complete playable version

The first proven object is a hot paper cup with a thermal-style rectangular label. A fuller game may add, in controlled increments:

Cup axes:
- paper hot cup;
- transparent iced/plastic cup;
- glass/frosted glass;
- metal/travel cup;
- different curvature/material response.

Label axes:
- small order label;
- wide/tall label;
- wrap-like label;
- transparent film;
- larger production/logistics-style label;
- different adhesion/material response.

Reward/progression should emphasize satisfaction: unlock prettier/different cups and larger/more interesting labels. Avoid building a large economy/shop before the repeated peel loop is strong.

## Scoring

A clean full detach awards score. Time is not the primary multiplier. Continuity/no re-grab may reward a clean one-pull peel, but the experience should remain relaxing.

Potential quality dimensions:
- full completion;
- continuity / one pull;
- later: residue/damage/perfect peel if implemented without making the game frustrating.

## Model asset boundary

Preferred runtime model format: `.glb` (glTF 2.0 binary). Optional source assets may live outside runtime-facing directories. External/generated assets require source/license/provenance and must not become hidden runtime dependencies.

Existing hand models are repository-local, rigged, CC0-derived assets with attribution under `assets/models/hands/`.

## Verification contract

Automatable acceptance should include:

- Godot 4.7.1 headless import;
- parse/load guard rather than trusting process exit code alone;
- deterministic unit tests for peel math/state/input/scoring/lifecycle;
- scene smoke for main scene and critical runtime resources;
- exact-head PR verification;
- stale-evidence invalidation when head moves;
- protected merge;
- post-merge `main` verification.

Automation cannot prove:

- whether resistance feels pleasant;
- whether a hand pose looks natural on the owner's display;
- whether Foley is relaxing at the owner's volume/headphones;
- whether the overall interaction is satisfying.

Those remain `UNVERIFIED` until owner local playtest evidence exists.

## Definition of a meaningful complete-version handoff

Do not hand the project back merely because one technical change is green. Before calling a substantial version ready for owner playtest, Builder and Challenger should jointly verify that the repository contains a coherent playable loop with:

- direct clone/ZIP -> import `project.godot` -> F5 startup;
- clear onboarding/interaction affordance;
- reliable edge catch and progressive peel;
- true final detachment into the right hand;
- believable hand presentation;
- responsive repository-local Foley;
- readable label print/material;
- completion reward and reset/next-item loop;
- at least a small amount of replayable variation/progression only where it improves the sensory loop;
- deterministic tests and scene smoke;
- no missing assets or hidden local setup;
- explicit record of remaining experiential uncertainties for the owner's next screenshot/playtest round.
