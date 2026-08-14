# Peel Calm V5 — Relaxation Ritual Loop Design

## Owner playtest evidence

This design is driven by the owner playtest of `main@15449efd62b94370896472cdbdb5771f83147740`.

Observed / reported evidence:
- Foley is already perceived as “还不错” (good enough to preserve and refine rather than replace wholesale).
- Hand presentation is visibly deformed / anatomically wrong in the owner screenshot. This is an acceptance failure, not a cosmetic nit.
- The current `Stamps / Score / Feels` presentation and automatic next-cup transition read too much like a technical progression system rather than a relaxing ritual.
- The owner wants the post-peel interaction extended: after removing the label, the player should be able to squeeze/crumple the cup.
- Later cups may contain ice or other contents, changing sound and deformation feedback.
- The full loop should stay comfortable, pressure-free, and replayable for a long time.

Machine tests cannot prove comfort, anatomical naturalness, ASMR quality, or relaxation. Those remain owner experiential gates.

## Unified agent prompt

> Build Peel Calm as a repeatable tactile relaxation ritual, not a score-chasing level game.
>
> The target loop is: discover the label -> peel -> final adhesive release -> brief savor/settle -> squeeze/crumple the cup -> calm reward reveal -> transition to a different tactile cup/label/content profile -> repeat.
>
> Preserve the current real Foley direction unless a specific defect is proven. Fix the visibly deformed hand presentation as a first-class acceptance failure. Do not switch between incompatible authored hand poses in a way that visibly warps anatomy; prefer a stable verified pose or controlled skeletal blending, and prove the result with real non-headless frames.
>
> Replace score pressure with soft progression. The player should never feel punished for pausing, re-grabbing, peeling slowly, or crumpling imperfectly. Every completed ritual earns progress. Smooth/continuous actions may create positive descriptive feedback or a small bonus, but never a failure state.
>
> Rewards should unlock new sensory experiences: cup silhouettes, paper/plastic stiffness, label sizes/materials, adhesive characters, lid styles, palettes, Foley sets, and later internal contents such as ice. Progression should create anticipation for the next tactile object rather than demand higher numbers.
>
> Post-peel cup deformation must become a real second tactile phase. Start with deterministic lightweight deformation, not full soft-body simulation. The cup should visibly accumulate dents/creases under repeated inward squeezes and play paper/plastic crumple Foley. The player may linger, make extra squeezes, or skip onward; there is no timer pressure.
>
> Architect cup variants as data-driven profiles. A cup profile must be able to define shell material/rigidity, dimensions, label profile, lid, crumple behavior, reward unlock, and an optional contents profile. Contents are initially `none`; future iced variants may spawn visible ice pieces and clink/rattle audio that respond to squeeze/motion without changing peel authority.
>
> Keep gameplay authority separated from presentation. The peel solver remains deterministic. A new ritual-flow state machine coordinates peel completion, crumple readiness, crumpling, reward, and next-item transition. Presentation modules render cup deformation, hands, contents, reward reveal, and ambient response.
>
> Validate with RED->GREEN tests, exact-head CI, independent agent challenge, merged-main verification, and non-headless captures for visible changes. Never claim subjective comfort/naturalness from CI.

## Product framing

Peel Calm is a “micro-tactile café ritual” rather than a level-clear game. The player should be able to repeat the loop for many minutes without urgency.

Primary emotional curve:
1. anticipation / finding the edge;
2. controlled resistance;
3. adhesive release texture;
4. final relief;
5. optional destructive satisfaction through cup crumpling;
6. soft reward / novelty reveal;
7. a fresh object with a slightly different tactile personality.

## Approaches considered

### A. Patch the existing score/session loop
Keep `SessionModel`, `ScoreModel`, the 2.15s auto-next timer, and simply add a crumple animation before reset.

Pros: smallest code change.
Cons: preserves the wrong product framing, couples future cup/contents progression to score-era assumptions, and makes the crumple phase feel bolted on.

### B. Introduce an explicit RitualFlow state machine — selected
Add a small deterministic flow model above the existing peel authority:

`PEEL -> PEEL_SETTLE -> CRUMPLE_READY -> CRUMPLING -> RITUAL_COMPLETE -> NEXT_ITEM`

The peel system remains unchanged as authority. RitualFlow owns only cross-phase sequencing and player intent after detach.

Pros: clean extension point for crumple, rewards, future ice/contents, optional lingering, and later tactile phases; testable without full scene rendering.
Cons: requires a focused refactor of current `peel_lab.gd` completion/reset timing.

### C. Full soft-body / destruction simulation
Use soft-body or high-resolution physical destruction for cups immediately.

Pros: higher theoretical physical ceiling.
Cons: expensive, unstable, harder to test, and unnecessary for the next tactile milestone.

Decision: Approach B.

## V5 ritual flow

### States

`PEEL`
- Existing peel controller/lifecycle authority.
- Player can pause, release, and re-grab with no penalty.

`PEEL_SETTLE`
- Entered exactly once when label reaches HELD/detached state.
- Short 0.35–0.65 s calm beat; no automatic next-item reset.
- Label remains visibly free/held.

`CRUMPLE_READY`
- Player-facing hint changes to a pressure-free invitation: “Squeeze the cup when you feel like it • R Next”.
- No countdown.
- Pointer fresh-press quarantine still applies when changing interaction mode.

`CRUMPLING`
- Inward horizontal pressure / repeated squeeze gestures increase deterministic crumple progress.
- Cup deformation accumulates; it never springs fully back during the ritual.
- Additional squeezes after minimum completion are allowed for tactile play.
- Player can proceed once minimum crumple completion is reached, or press R to skip/continue at any time.

`RITUAL_COMPLETE`
- Award is recorded exactly once.
- Calm reward reveal lasts as presentation, not as a forced wait; R/primary action may continue immediately.
- No “failure”, negative grade, lost streak, or countdown.

`NEXT_ITEM`
- Select the next unlocked cup profile, reset peel/crumple transient state, and quarantine held input before returning to PEEL.

### Skip policy

Crumpling is encouraged but not coercive:
- after label detach, R can advance without crumpling;
- completing the minimum crumple threshold earns the normal ritual-complete sensory reveal;
- extra crumples may produce additional sound/visual satisfaction but do not farm score indefinitely.

## Reward / progression redesign

### Remove competitive emphasis
The large public `Score` number should leave the primary HUD. Internal smoothness metrics may remain for tuning/tests, but they are not the player’s main goal.

### Soft rewards
Every completed peel ritual grants one durable `Ritual Stamp` (working internal name). Rewards unlock sensory content rather than harder difficulty.

Suggested unlock categories:
- cup shell family (kraft paper, smooth coated paper, ribbed paper, soft plastic, clear cold cup later);
- label width/height/material character;
- adhesive profile;
- lid style;
- palette / café print variation;
- crumple rigidity / crease sound;
- ambient/Foley variation;
- optional contents profile such as `ice`.

### Feedback vocabulary
Prefer descriptive positive feedback:
- “Clean release”
- “Soft fold”
- “Crisp crumple”
- “Long peel”

Avoid ranks, stars lost, combo breaks, time bonuses, and red failure messaging.

## Data-driven cup profile

Introduce a profile contract capable of carrying at least:

```text
id
name
cup_shell
cup_color
cup_dimensions
lid_profile
label_profile
peel_profile
crumple_profile
contents_profile
unlock_requirement
reward_theme
```

`contents_profile` starts as `none`. Later iced variants may use:

```text
contents_profile = {
  type: "ice",
  count,
  visibility,
  clink_set,
  movement_gain
}
```

The first V5 implementation does not need full ice physics; it must only avoid architectural dead ends that make contents impossible to add cleanly.

## Cup crumple model

Use lightweight deterministic deformation.

Model:
- cup shell represented by a small number of deformation bands / control rings;
- squeeze input creates bounded dents on left/right sectors;
- accumulated crumple scalar controls waist compression, vertical shortening, tilt/noise, and crease presentation;
- each squeeze emits a bounded crumple event for Foley/presentation;
- deformation has hard bounds so the cup never inverts/explodes numerically.

No soft-body dependency.

Input:
- fresh press is required to enter crumple ownership;
- horizontal inward drag / opposing side pressure increases squeeze amount;
- stale peel input cannot automatically inherit the crumple phase;
- pause/reset/restart preserve the existing quarantine discipline.

## Hand repair work package

Owner screenshot makes hand anatomy the highest-priority visual defect.

Current risk to challenge:
- dynamic authored hand currently switches between `Default pose` and `Pinch Tight` at a pinch threshold;
- the authored root is uniformly scaled for presentation;
- visible pose switching may expose an animation not intended for this camera/use.

Required outcome:
- no visible finger/palm collapse, inversion, extreme spread, or wrist discontinuity in idle, edge-hover, pinch, peel, held-label, or crumple-ready poses;
- prefer a stable verified authored pose for the next build unless a controlled bone blend is proven visually better;
- use real X11/OpenGL capture, not skeleton-node existence, as acceptance evidence;
- hand gameplay anchor and label pinch must remain correct after any visual fix.

This work package is intentionally separable from RitualFlow so the second agent can own/challenge it without editing the same production paths.

## Parallel-agent split

PRIMARY / Ritual package claims:
- new ritual-flow model/tests;
- new cup-crumple model/presentation/tests;
- progression/reward profile model;
- minimal `peel_lab.gd` integration needed to connect detach -> crumple -> next item;
- HUD/reward copy for the new pressure-free loop.

CHALLENGER / Hand package preferred scope:
- `scripts/hands/hand_visual.gd` and hand-specific tests/capture;
- hand/forearm presentation files only when necessary;
- independent challenge of RitualFlow exact heads after hand work is isolated.

Any overlap must be re-claimed in Issue #5 before writing.

## TDD / verification plan

Before implementation, add RED contracts for:
1. detach enters `PEEL_SETTLE/CRUMPLE_READY` instead of starting an automatic next-cup timer;
2. no timer pressure in CRUMPLE_READY;
3. crumple requires a fresh interaction owner;
4. repeated inward squeeze monotonically increases bounded crumple progress;
5. ritual reward records exactly once;
6. skip-to-next works without crumple and does not duplicate reward;
7. restart clears ritual/crumple/reward transient state;
8. cup profile selection changes actual tactile/presentation fields, not only names;
9. contents profile can be `none` now and accepts a future `ice` descriptor without touching peel authority;
10. current peel, tapered label, Foley, pointer, pause/reset and F5/default-launch gates remain green.

Visible changes require non-headless capture. Hand naturalness, crumple satisfaction, reward calmness, and long-session comfort remain owner playtest items.

## V5 first delivery scope

Implement now:
- RitualFlow state model;
- pressure-free post-peel crumple-ready phase;
- deterministic paper-cup crumple deformation + crumple event routing;
- calmer reward/HUD semantics with score de-emphasized;
- data-driven cup profile foundation with at least three visibly/tactilely distinct existing variants migrated;
- hand deformation fix through the parallel hand package;
- exact-head CI + merged-main + real render verification.

Prepare but do not fully implement yet:
- visible ice simulation;
- transparent cold-cup rendering;
- full lid removal/drinking;
- soft-body physics;
- meta shop/currency economy.

## Definition of Done for owner retest

- screenshot-level hand deformation regression is fixed or materially improved in real render evidence;
- peel completion no longer forcibly auto-resets after 2.15 s;
- player can naturally continue into a cup-crumple phase;
- cup visibly accumulates deformation and has responsive crumple Foley events;
- reward presentation is calm and non-punitive, with numeric score removed from primary emphasis;
- next item presents a genuinely different tactile/cup profile;
- all existing deterministic/scene/default-F5 gates plus new ritual/crumple gates are green on exact head and merged main;
- subjective comfort/ASMR/anatomy remains explicitly owner-verified, never claimed solely by CI.
