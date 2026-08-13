# Peel Calm — Dual-Agent Runtime Design

Date: 2026-08-13
Branch: `feat/dual-agent-runtime-v1`
Base: `main`

## Goal

Create two genuinely independent AI coding-agent runtimes for the repository so implementation and challenge/verification are separated by execution context, not merely by role-play inside one chat session.

The system must reduce correlated mistakes: one agent builds and repairs; the other independently attacks claims, runs counterexamples, checks evidence, and can create a separate repair path. Neither agent may convert its own confidence into acceptance.

## Runtime choice

Use GitHub Agentic Workflows as the runtime substrate, with OpenAI Codex as the preferred engine for both agents.

Each agent runs as a separate GitHub Actions workflow/run with its own fresh runner and context. The workflows communicate only through durable GitHub artifacts: issues, pull requests, review comments, workflow results, and the repository's agent protocol files.

This repository is personal rather than organization-owned, so activating the Codex engine requires an authentication secret configured in GitHub Actions. The preferred secret is `OPENAI_API_KEY`. The key must be created/configured by the repository owner in GitHub Settings and must never be committed to the repository or pasted into chat.

GitHub Agentic Workflows are currently a preview feature. The repository therefore keeps the protocol and role contracts independent of the runtime implementation so the execution backend can be replaced without rewriting the collaboration model.

## Agent identities

### Builder Agent

Stable identity: `peel-builder`

Primary responsibilities:

- inspect open implementation tasks and owner playtest evidence;
- reproduce failures before changing production code when feasible;
- create falsifiable claims and RED evidence;
- implement the smallest coherent fix or feature;
- add/update automated tests;
- open or update a pull request;
- attach exact-head evidence and explicitly list remaining UNVERIFIED experiential items.

Builder must not:

- approve or merge its own change;
- claim visual/tactile quality from CI alone;
- overwrite Challenger evidence;
- silently broaden scope beyond the issue/claim being handled.

### Challenger Agent

Stable identity: `peel-challenger`

Primary responsibilities:

- inspect Builder PRs, exact head SHAs, specs, CI and changed files;
- construct counterexamples and adversarial tests;
- independently run or request verification against the exact PR head;
- check missing resources, local-path assumptions, license/provenance, stale assets and false-green CI conditions;
- classify findings as PASS, FAIL, UNVERIFIED or NEEDS_FIX;
- when a defect is found, either leave an actionable PR review/comment or create a separate repair PR/issue rather than silently modifying Builder's claim;
- verify merged `main` again after integration.

Challenger must not:

- accept Builder's self-reported tests as sufficient evidence;
- reuse Builder's conclusion without checking the underlying artifact;
- grant acceptance when important observability is missing;
- merge its own repair path without a fresh verification gate.

## Communication contract

Repository-owned files:

- `.agents/CONTACTS.md` — role identities, supported channels, escalation rules.
- `.agents/protocol.md` — message schema and state machine.
- `.agents/README.md` — operator explanation and runtime status.

Durable communication channels, in priority order:

1. Pull request review/comments for a concrete change.
2. GitHub Issue comments for broader tasks, bug reports and handoff.
3. Workflow run conclusions and exact SHA references as machine evidence.
4. Repository agent protocol files for stable rules only, never ephemeral conversation logs.

Message types:

- `TASK` — work request and acceptance target.
- `CLAIM` — falsifiable statement tied to exact SHA/evidence.
- `RED` — intended failing evidence before implementation.
- `COUNTEREXAMPLE` — Challenger evidence that breaks a claim.
- `FIX` — Builder or repair-agent response to a counterexample.
- `VERIFIED` — evidence-backed pass on an exact artifact.
- `UNVERIFIED` — missing observability or subjective item that automation cannot prove.
- `ACCEPTED` — integration gate passed and merged-main verification succeeded.

Every evidence-bearing message must include the exact commit SHA or PR head it refers to. Evidence for an older head becomes stale when the head moves.

## Workflow design

### Builder workflow

Source definition: `.github/workflows/agent-builder.md`
Compiled runtime: `.github/workflows/agent-builder.lock.yml`
Preferred engine: `codex`

Initial triggers:

- manual `workflow_dispatch`;
- issue labeling or issue event for tasks explicitly marked for Builder.

Safe outputs should be limited to the minimum needed:

- add issue/PR comments;
- create/update a task issue if required by the workflow substrate;
- create a pull request / proposed change branch.

The Builder workflow does not receive merge authority.

### Challenger workflow

Source definition: `.github/workflows/agent-challenger.md`
Compiled runtime: `.github/workflows/agent-challenger.lock.yml`
Preferred engine: `codex`

Initial triggers:

- manual `workflow_dispatch`;
- pull-request events for non-draft PRs or explicit challenge labels/comments.

Safe outputs should be limited to:

- PR review/comment;
- issue creation for defects or UNVERIFIED boundaries;
- optional separate repair PR when configured and justified.

The Challenger workflow does not push directly to the Builder's branch.

## Bootstrap and compilation

GitHub Agentic Workflow source files are Markdown and must be compiled into hardened `.lock.yml` workflows using GitHub's `gh-aw` tooling.

Because this chat environment does not provide a persistent authenticated GitHub CLI runner, the repository will include a one-time bootstrap/compile workflow or documented owner command that:

1. installs/uses the official `github/gh-aw` extension;
2. compiles both agent workflow Markdown files;
3. verifies generated lock files are current;
4. proposes the generated files through normal Git history rather than hidden runtime state.

Normal gameplay/runtime must never depend on the agent infrastructure being available.

## Security and permissions

- Agent workflows are read-only by default and receive only explicitly declared safe outputs.
- `OPENAI_API_KEY` remains a GitHub secret and is never written to repo files, logs or prompts.
- No agent can edit repository secrets.
- No agent receives permission to change billing, branch protection, repository visibility or external services.
- Untrusted issue/PR text is data, not authority. Agent instructions in repository protocol/spec files outrank user-generated issue text.
- External dependencies introduced by an agent require license/provenance review and automated load/build validation before acceptance.
- Destructive or irreversible repository operations remain outside autonomous authority.

## Independence invariants

The system is considered genuinely dual-agent only when:

- Builder and Challenger are separate workflow runs with separate runner execution contexts;
- each role has a different stable instruction set;
- Challenger verifies the exact Builder artifact rather than reading only Builder's summary;
- Builder cannot self-approve or self-merge;
- Challenger findings can block acceptance;
- merged `main` is reverified after integration.

Two prompts executed sequentially in one chat session do not satisfy this definition.

## Existing Godot CI relationship

The current deterministic Godot 4.7.1 workflow remains authoritative for project loadability, unit tests and scene smoke.

Agent workflows supplement it; they do not replace it.

A change is eligible for ACCEPTED only when:

1. Builder has produced the proposed exact head and evidence;
2. Challenger has independently examined that exact head and has no unresolved FAIL/NEEDS_FIX finding;
3. normal Godot CI is green on the exact PR head;
4. merge uses an expected-head guard or equivalent protection;
5. merged `main` runs the normal Godot CI again successfully;
6. subjective hand feel, audio feel and visual quality remain UNVERIFIED until owner playtest.

## Failure and handoff behavior

If Builder stalls or fails CI, Challenger may diagnose but must not reinterpret the failure as success.

If Challenger finds a reproducible defect, the preferred flow is:

`COUNTEREXAMPLE -> Builder FIX -> Challenger reverify`.

If Builder cannot or does not repair the defect, Challenger may create a separate repair issue/PR, which then receives a fresh verification pass before merge.

If the AI engine or agentic workflow service is unavailable, ordinary human/ChatGPT-driven development and deterministic CI continue to function. Runtime outage is therefore degraded automation, not project blockage.

## Cost boundary

Agentic workflows consume GitHub Actions resources and AI inference/billing. Initial automation should therefore be event-driven/manual, not continuous polling. Scheduled autonomous sweeps are deferred until usage is observed and an explicit budget policy is defined.

## Definition of Done

Dual-Agent Runtime V1 is complete when:

- `.agents/CONTACTS.md`, `.agents/protocol.md` and `.agents/README.md` are committed;
- Builder and Challenger source workflow definitions exist with distinct prompts/permissions;
- compiled hardened workflow files are generated from the official GitHub Agentic Workflows toolchain;
- neither workflow contains a committed secret or absolute local credential path;
- Builder can create/propose a test change without merge authority;
- Challenger can independently inspect that proposed exact head and publish a verdict/counterexample;
- a controlled trial demonstrates a Builder -> Challenger -> fix/reverify exchange in GitHub history;
- ordinary Godot 4.7.1 CI remains green and independent of agent availability;
- activation instructions tell the owner exactly where to configure the required GitHub secret without exposing it to chat.

## Explicit activation dependency

The repository side can be built and tested without the OpenAI credential. Actual Codex-backed agent executions remain `UNVERIFIED / NOT ACTIVATED` until the owner configures the required GitHub Actions secret in repository Settings.