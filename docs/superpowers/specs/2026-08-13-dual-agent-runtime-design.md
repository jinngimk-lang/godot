# Peel Calm — Dual-Agent Runtime Design

Date: 2026-08-13
Branch: `feat/dual-agent-runtime-v1`
Base: `main`

## Goal

Create two genuinely independent AI coding-agent executions inside the repository so implementation and challenge/verification are separated by fresh GitHub Actions runners and separate Codex invocations, not by role-play inside one chat session.

The system must then use the repository's accumulated game knowledge to advance Peel Calm toward one coherent complete-playable handoff before asking the owner to perform the next local screenshot/feel test.

## Runtime decision and implementation amendment

The initial design evaluated GitHub Agentic Workflows (`gh-aw`) as the runtime. A strict `gh-aw v0.83.4` compile proved the Builder and Challenger definitions valid, but the generated lock workflows are each over 100 KB and GitHub's default Actions installation token correctly refuses to push workflow-file updates without additional workflow-write authority.

Rather than widen credentials solely to materialize compiler output, the implementation uses OpenAI's official `openai/codex-action` directly from two ordinary GitHub Actions workflows. This preserves the important properties—independent runners, sandboxed Codex calls, auditable Actions history, separate prompts, exact-head evidence—while removing a generated-workflow bootstrap and an unnecessary workflow-write credential.

Pinned Codex Action: v1.11 commit `52fe01ec70a42f454c9d2ebd47598f9fd6893d56`.

The collaboration protocol remains backend-independent so the runtime can be replaced later without rewriting task/evidence semantics.

## Agent identities

### peel-builder

Builder owns implementation and repair batches. It:

- reads `.agents/PROJECT_KNOWLEDGE.md`, protocol, task Issue, specs/plans, code and tests;
- finds or creates the single `[builder]` PR for the canonical task;
- works on that actual PR branch when continuing a task;
- uses Codex with workspace-write filesystem permission and no direct GitHub-write authority inside the model;
- prefers RED -> GREEN evidence and runs Godot while working;
- is followed by deterministic wrapper verification using Godot 4.7.1 import/parser guard/unit/smoke;
- only after deterministic success may wrapper steps commit/push/comment/dispatch Challenger;
- never approves or merges its own work;
- never converts subjective visual/audio/tactile confidence into VERIFIED evidence.

Builder may not modify `.github/`, `.agents/`, secrets, billing, branch protection or repository policy during normal gameplay tasks.

### peel-challenger

Challenger independently attacks the exact Builder artifact. It:

- runs in a separate workflow/run and fresh runner;
- checks that the requested SHA is still the current PR head;
- independently downloads the pinned Godot 4.7.1 binary and runs import/parser guard/unit/smoke on that exact head;
- invokes Codex with read-only filesystem permission;
- inspects actual PR diff, task/specs/tests and verification logs rather than Builder's summary;
- must construct at least one concrete counterexample/boundary scenario beyond happy-path tests;
- classifies the exact head as VERIFIED, NEEDS_FIX or UNVERIFIED;
- dispatches Builder for repair when a defect is found;
- if a batch is sound but the canonical complete-version machine scope is still incomplete, dispatches Builder to continue the highest-priority remaining item;
- acts as merge decider only when the independent exact-head checks are green and the complete machine-verifiable task scope is satisfied.

Challenger never treats its own later repair as pre-verified; any new head receives another fresh Challenger run.

## Durable communication

Repository-owned rules:

- `.agents/PROJECT_KNOWLEDGE.md` — compact shared product/technical/owner-feedback memory.
- `.agents/CONTACTS.md` — stable identities and escalation boundaries.
- `.agents/protocol.md` — message envelope, stale-evidence rules and lifecycle.
- `.agents/README.md` — runtime/operator guide.
- `.agents/state.json` — non-secret install/activation status.

Ephemeral communication lives in GitHub Issue/PR comments and Actions runs, not append-only chat logs in source control.

Message types remain:

`TASK / CLAIM / RED / COUNTEREXAMPLE / FIX / VERIFIED / UNVERIFIED / ACCEPTED`.

Every evidence-bearing message must name its exact SHA. Evidence is stale as soon as the artifact head moves.

## Handoff topology

The normal loop is:

`owner master TASK -> Builder -> Challenger -> Builder -> Challenger -> ...`

Builder and Challenger call one another through explicit `workflow_dispatch`. Each dispatch creates a separate Actions run. A numeric round is passed through the chain and a hard guard stops after round 20 instead of allowing an accidental unbounded API loop.

Within one task there is normally one evolving Builder PR. This gives both agents a shared, auditable candidate instead of producing a pile of competing PRs.

## Complete-version behavior

The master task is larger than a single bug fix. A Challenger `VERIFIED` verdict on one batch is not completion by itself.

After each sound batch, Challenger must compare the current repository against the canonical complete-playable acceptance scope and either:

- dispatch Builder for the next highest-priority incomplete machine-verifiable item; or
- set `complete_machine_scope=true` only when the repository is ready for owner experiential playtest apart from properties automation cannot prove.

The shared project knowledge defines the product thesis, V1/V2 regression history, tactile priorities, asset boundaries, cup/label variation axes, scoring philosophy, direct-run contract and automation limitations.

The expected complete-playable handoff is a polished coherent sensory loop, not a commercial live-service content universe. Large shop/economy, ads/IAP, multiplayer, cloud save and mobile release are not prerequisites unless a later canonical task explicitly adds them.

## Final integration

When Challenger independently returns VERIFIED with `complete_machine_scope=true`, `continue_build=false`, and deterministic checks green:

1. wrapper re-checks current PR head equals the reviewed SHA;
2. merge uses GitHub's merge API with that expected SHA;
3. `Godot Check` is explicitly dispatched against merged `main`;
4. Challenger waits for that exact merge SHA's workflow-dispatch run;
5. only a successful merged-main verification permits `ACCEPTED` and closes the master task.

If post-merge verification fails, the failure is not reinterpreted as success; a repair task must be sent back through the Builder/Challenger loop.

## Godot verification relationship

The ordinary `.github/workflows/godot-check.yml` remains project authority for engine loadability and deterministic test/smoke behavior. It supports push, pull_request and explicit workflow_dispatch.

Because Builder-created PR pushes may not behave like human pushes for normal event cascades, Challenger does not depend on an incidental pull_request CI event. It runs the same Godot 4.7.1 import/parser/unit/smoke checks itself on the exact Builder SHA, then explicitly dispatches ordinary Godot Check after final merge.

## Security boundary

- Required AI credential: repository Actions secret `OPENAI_API_KEY`.
- Secret value never appears in tracked files, Issue/PR text or prompts.
- OpenAI's Codex Action receives the API key through its Responses proxy path.
- Builder Codex uses `:workspace`; Challenger Codex uses `:read-only`; both use the action's `drop-sudo` safety strategy.
- Codex is not given the repository GitHub write token as prompt data.
- Deterministic workflow steps—not natural-language model output—perform git push, PR comments, counterpart dispatch and final merge.
- Only task Issues opened by repository owner `jinngimk-lang` with `[AGENT-TASK]` title automatically start Builder.
- Bot-triggered counterpart dispatches are allowed because they originate inside repository workflows; arbitrary public users do not get an API-spend trigger.
- External runtime assets introduced by game work still require license/provenance and load validation.
- Destructive repository actions, secrets changes, billing changes and legal/brand commitments remain outside agent authority.

## Cost boundary

Codex calls may consume OpenAI API usage and GitHub Actions resources. The loop is event/dispatch-driven, not polling, and is hard-bounded at round 20. Reaching the bound produces UNVERIFIED rather than silently increasing spend.

## Independence invariants

The system counts as genuinely dual-agent only when:

- Builder and Challenger have distinct workflow run IDs and runners;
- their Codex calls use distinct prompts and permissions;
- Challenger checks the actual current Builder head and independently runs deterministic verification;
- Builder cannot self-merge;
- Challenger findings can block integration and return work to Builder;
- every changed head invalidates prior Challenger evidence;
- merged main is separately verified after integration.

Two prompts executed sequentially inside this chat do not satisfy these invariants.

## Experiential boundary

Even after ACCEPTED, automation still cannot prove:

- peel resistance feels pleasant;
- hand placement reads naturally on the owner's display;
- Foley is relaxing at the owner's volume/headphones;
- final detachment is emotionally satisfying;
- overall polish matches the owner's taste.

Those are intentionally deferred to the owner's next local playtest/screenshots after the substantial complete-playable build is delivered.

## Definition of Done — Dual-Agent Runtime V1

Runtime installation is complete when:

- `.agents/` identity/protocol/shared-knowledge files exist;
- `agent-builder.yml` and `agent-challenger.yml` are committed with distinct Codex permissions/prompts;
- OpenAI Codex Action is immutable-SHA pinned;
- standard Godot Check statically guards required runtime files and secret material;
- no API key is committed;
- a real owner task starts Builder, Builder creates/updates a proposal, and a separate Challenger run publishes an exact-head verdict;
- a defect or continuation can be handed back and re-reviewed on a new head;
- Godot runtime remains independent of the agent system.

## Activation dependency

Repository-side installation can be validated without the API credential. Actual independent Codex calls remain `NOT ACTIVATED` until the owner configures `OPENAI_API_KEY` under GitHub repository Settings → Secrets and variables → Actions. The value must never be sent through chat.
