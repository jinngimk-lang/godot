# Peel Calm Shared Project Knowledge

This file is compact operational memory for both repository agents. It does not replace specs, plans, tests, Git history, the canonical cross-PR coordination Hub in Issue #5, phase-specific task/evidence ledgers such as the complete-playable record in Issue #7, PR evidence, or owner playtest evidence. Discover the active task/PR from Hub #5 and current repository state rather than assuming a historical task issue is still current. Inspect the relevant sources whenever a detail matters, and treat stale exact-head evidence as invalid after a head/base changes.

## Product thesis

Peel Calm is a relaxing tactile/ASMR game about peeling printed café-style production/order labels from drink cups. The core fantasy is not speed or difficulty: it is the physical satisfaction of catching an edge, feeling adhesive resistance, hearing paper/tape Foley, releasing the last bond, and holding a cleanly removed label.

The product frame is closer to a `Coffee Ritual ASMR / Micro-Tactile Relaxation` experience than a generic sticker minigame.

## Owner intent

- Build the canonical complete project in GitHub first.
- The owner downloads/clones it and imports `project.godot` into local Godot without hand assembly or hidden dependencies.
- Test repeatedly and prefer evidence over confidence.
- Normal reversible implementation decisions are autonomous; do not repeatedly ask the owner.
- The owner supplies local screenshots/feel feedback after a substantial playable delivery.
- When model or audio assets become important, keep them repository-local, auditable, and preview/reviewable.
- Continue improving after a green vertical slice; do not freeze useful work merely because one machine-complete checkpoint was reached.

## Platform and engine

- Godot 4.7.1.
- GDScript.
- PC mouse first, touch-ready architecture for later mobile adaptation.
- Runtime must not require Blender, an AI model service, private environment variables, external downloads, or third-party Godot plugins.
- `project.godot` must remain directly runnable through its configured `run/main_scene`; tests that manually load a scene are not by themselves proof of the clone/import/F5 path.

Pointer data exposed to gameplay remains device-neutral:

```text
pressed: bool
position: Vector2
relative: Vector2
velocity: Vector2
released_this_frame: bool
```

## Proven pointer and boundary invariants

These are regression contracts, not suggestions:

- One physical pointer source owns a gesture at a time: `NONE / MOUSE / TOUCH`.
- Ownership can begin only from a genuinely fresh press. Mouse motion, touch drag, stale release, or a still-held secondary finger must never silently inherit ownership.
- While a touch owns gameplay, secondary touch indices cannot move or release the owner.
- Godot touch-emulated mouse events must not duplicate or steal direct-touch gameplay input.
- On hybrid devices, real mouse and real touch cannot steal/release one another mid-gesture.
- Pause suspends gameplay input while physical held state is still tracked.
- Resume after pause remains neutral if the pointer is still held; release is consumed, then a later fresh press re-arms gameplay.
- Label reset, run restart, next-item reset, and automatic next-item transitions quarantine any pre-boundary held press in the same way.

When changing input, add or preserve adversarial tests for secondary fingers, emulated mouse, hybrid real mouse/touch, lingering secondary drag, pause, reset, restart, and fresh-press re-arm.

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

Presentation consumes gameplay state but does not decide whether peel progress succeeds. Scene-level café, hand/forearm, print, and material presentation modules must not become gameplay authority.

Label lifecycle:

`ATTACHED -> PEELING -> DETACHING -> HELD`

Completion invariant: after final detach, held-label geometry has no cup anchor. A fully held label must remain bounded and translate with the grip rather than rubber-banding back to the cup.

## Proven cup / label geometry invariants

- The production cup is a tapered `CylinderMesh`/frustum, so the still-attached label must follow the actual runtime cup surface rather than a guessed fixed cylinder radius.
- Attached top and bottom strip vertices use the cup radius at their own y coordinate plus the declared surface offset.
- Standalone callers/tests without a runtime cup retain a cylindrical fallback contract.
- The free/bent portion remains peel-curve geometry; do not snap it back to the cup just because the attached portion is frustum-aware.
- `DETACHING -> HELD` must converge to cup-independent geometry.
- Surface lighting direction should follow the actual attached surface as well as vertex position; when touching normals, preserve free/bent/held curve-normal behavior.
- All production tactile variants use different label sizes; geometry changes must be checked across variant progression rather than only the initial label.

## Owner V1 feedback that must never regress

V1 failed because:

- `100% / COMPLETE` visually remained connected to the cup as a stretched ribbon;
- hands looked like abstract block/capsule proxies;
- synthetic oscillator/noise audio sounded abstract;
- order text visually separated from the deforming label.

Later iterations addressed these with:

- explicit detach lifecycle;
- bounded peel geometry plus cup-independent held geometry;
- dynamic print rendered into the deforming label material;
- repository-local rigged hand GLBs with authored poses, real renderable meshes/materials, plus procedural fallback;
- repository-local CC0-derived paper/tape Foley and provenance ledgers;
- tapered-cup-aware attached label geometry;
- calm café presentation and stronger authored-hand/forearm presentation checks.

Agents must add regression tests when touching these areas.

## Hand and presentation invariants

- `authored=true` is not sufficient evidence: authored hand assets must contain real renderable mesh vertices/material surfaces, not only Skeleton3D/AnimationPlayer data.
- Keep repository-local provenance/license evidence for external/generated assets.
- The right hand's pinch anchor must remain aligned with the actual fresh/active grip target; the left hand must remain readable as cup support.
- Procedural hands remain a fallback path and should not be accidentally broken by authored-only assumptions.
- Wrist/forearm presentation should be presentation-only. It may follow a HandVisual transform, but it must not alter peel state or grip authority.
- Visible-presentation changes require a real non-headless frame/capture when practical; headless node existence alone cannot prove that meshes actually render or compose well.
- Machine evidence may prove presence, geometry, clearance, material assignment, bounds, and anchor relationships; it does not prove anatomy, beauty, or owner taste.

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

Idle must not sustain peel loops. High tension by itself must not turn paper flex into a metronome: paper-flex events require real pointer motion or incremental label release, remain cooldown-limited, and must not be backfilled merely because a cooldown expired while stationary. Final release is an exact-once-per-cycle event and reset re-arms it. Use sample variation conservatively to avoid repetition. Do not reintroduce synthetic placeholder noise as the normal presentation path.

Runtime Foley must remain repository-local. Asset source/license/provenance and transformation notes belong with the assets; do not introduce untracked external runtime downloads.

## Visual direction

Selected direction: semi-realistic, clean, calming hands. Recognizable anatomy, readable thumb/index pinch, relaxed other fingers, restrained material detail; not hyper-photoreal skin pores.

Cup/scene direction: calm close-up tabletop, generic fictional café presentation. Do not replicate Starbucks, Luckin, or other real brand marks/trade dress.

Keep cup + printed label as the visual focal subject. Presentation additions should not obscure the peel edge, label print, or interaction hand.

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

Current progression deliberately exercises multiple tactile profiles with real parameter and label-size differences. When changing the repeated-session loop, verify unlock/advance/restart behavior rather than testing only the first item.

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

- official Godot 4.7.1 headless import;
- parse/load guard rather than trusting process exit code alone;
- deterministic unit tests for peel math/state/input/scoring/lifecycle;
- unit logs must fail on unexpected Godot `ERROR:` / script errors even if the process exit code is zero;
- scene smoke for the configured main scene and critical runtime resources;
- focused real-scene smokes for any falsifiable integration claim;
- exact-head PR verification;
- stale-evidence invalidation when PR head or base moves;
- independent Builder/Challenger attack before integration when another agent is available;
- mergeability/base-drift check immediately before integration;
- fresh post-merge `main` verification.

Do **not** describe a merge as protected unless branch protection is actually configured and observed. Query repository settings before making that claim; evidence discipline, exact-head checks, independent review, and post-merge verification remain required regardless of protection state.

For visible presentation changes, use a non-headless capture where practical. Capture-only branches/workflows must not silently become production dependencies.

Automation cannot prove:

- whether resistance feels pleasant;
- whether a hand pose looks natural on the owner's display;
- whether Foley is relaxing at the owner's volume/headphones;
- whether the overall interaction is satisfying.

Those remain `UNVERIFIED` until owner local playtest evidence exists.

## Multi-agent coordination protocol

Issue #5 is the canonical cross-PR coordination Hub. Use it for role declaration, narrow file/path claims, ownership collisions, handoffs, blockers, releases, and cross-task state. PR comments carry change-local evidence and review conclusions. Issue #7 is the complete-playable Peel Calm phase/task evidence ledger; it is useful historical evidence for that phase, but it is not a permanent current-task entrypoint. Discover the active task issue/PR from Hub #5 and current repository state instead of assuming #7 remains current.

- Before starting a meaningful line, inspect current `main`, open PRs, active branches, recent Issue #5 ownership/handoff state, the relevant PR discussion, and the currently active task issue/PR discovered from that state. Consult Issue #7 when complete-playable phase history is relevant rather than treating it as permanently active.
- Every cross-PR coordination comment should declare `AGENT`, `ROLE`, `TASK`, `BASE_SHA`, `BRANCH`, `FILES_CLAIMED`, `STATUS`, `EVIDENCE`, `BLOCKER`, and `NEXT_ACTION` as required by Hub #5.
- State path claims/collision boundaries before production writes when two agents are active; do not edit another agent's claimed production paths unless explicitly taking over after a handoff/blocker.
- Prefer isolated, narrowly scoped branches/PRs so repairs can be challenged, replayed, merged, or discarded independently.
- A Challenger must try to falsify the exact candidate rather than merely repeat the author's tests.
- Valid independent REDs are accepted into the contract; do not defend an implementation simply because its previous CI was green.
- When `main` advances, replay/rebase a candidate onto the new base and rerun combined gates before integration. Old-base green evidence is not merge-candidate evidence.
- Keep verifier-only tests/capture tooling separate from production unless the test proves a durable regression contract worth keeping.
- After integration, release path claims so the other agent can continue.
- If automated remote agents are blocked by service/API credits, continue repository work through the available human-mediated PRIMARY/CHALLENGER loop; do not repeatedly burn failing automation runs.

## Definition of a meaningful complete-version handoff

Do not hand the project back merely because one technical change is green. Before calling a substantial version ready for owner playtest, Builder and Challenger should jointly verify that the repository contains a coherent playable loop with:

- direct clone/ZIP -> import `project.godot` -> F5/default-main-scene startup;
- clear onboarding/interaction affordance;
- reliable edge catch and progressive peel;
- true final detachment into the right hand;
- believable hand presentation;
- responsive repository-local Foley;
- readable label print/material;
- completion reward and reset/next-item loop;
- at least a small amount of replayable variation/progression only where it improves the sensory loop;
- deterministic tests and real-scene smoke;
- no missing assets or hidden local setup;
- explicit record of remaining experiential uncertainties for the owner's next screenshot/playtest round.

A machine-complete label is never evidence that the experiential gate is complete. Keep improving machine-verifiable defects and presentation regressions while clearly separating them from owner-only feel/taste judgments.
