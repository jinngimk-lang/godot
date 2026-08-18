# Peel Calm Dual-Agent Runtime

This directory defines the repository-owned collaboration contract for two genuinely independent AI coding-agent runs.

## Identities

- `peel-builder`: implementation, reproduction, repair, deterministic tests, one evolving Builder PR.
- `peel-challenger`: independent challenge, counterexamples, exact-head Godot verification, repair/continuation handoff, and final merge decision.

The two roles run as separate GitHub Actions jobs in separate workflow runs using OpenAI's official `openai/codex-action`. A single chat session switching roles does not count as dual-agent verification.

## Runtime files

- `.github/workflows/agent-builder.yml` — workspace-write Builder Codex plus deterministic commit/PR/dispatch wrapper.
- `.github/workflows/agent-challenger.yml` — read-only Challenger Codex plus independent Godot verification, handoff and protected integration wrapper.
- `.github/workflows/godot-check.yml` — ordinary project verification and explicit merged-main verification target.

The Codex Action dependency is pinned to the immutable commit behind v1.11: `52fe01ec70a42f454c9d2ebd47598f9fd6893d56`.

## Shared project context

Before acting, both agents must read:

1. `.agents/PROJECT_NORTH_STAR.md` — persistent whole-project memory; reread after long-context compaction/handoff or before a major pivot.
2. `.agents/PROJECT_KNOWLEDGE.md`
3. `.agents/protocol.md`
4. `.agents/CONTACTS.md`
5. `.agents/skills/peel-calm-reference-realism/SKILL.md` for visual/tactile Peel Calm work
6. the canonical `[AGENT-TASK]` Issue and its comments
7. the latest relevant handoff/checkpoints/specs/plans under `.agents/skills/` and `docs/superpowers/`
8. `README.md`
9. current production files, tests and Godot verification workflow

Repository history and exact GitHub artifacts are evidence. Summaries and conversation memory are not substitutes for inspecting the current head.

If owner-level direction, major architecture, acceptance criteria, merged milestone, or highest-priority next work changes, update `.agents/PROJECT_NORTH_STAR.md` so a later agent can recover without relying on a long chat transcript.

## Communication

Builder and Challenger communicate through the canonical task Issue, the single `[builder]` PR for that task, exact commit SHAs, and explicit `workflow_dispatch` handoffs. GitHub documents `workflow_dispatch` as an exception that creates a new workflow run even when the dispatch is made with the repository `GITHUB_TOKEN`, so each handoff is a distinct runner/execution context.

Each run may dispatch the counterpart once. The task carries a numeric round value and stops automatically after round 20 rather than allowing an accidental unbounded API loop. Reaching that guard is `UNVERIFIED`, never acceptance.

## Acceptance gate

A complete-version task is not `ACCEPTED` until all of these are true:

1. Builder produced an exact proposed PR head and falsifiable claim.
2. Challenger independently checked that exact head and ran Godot 4.7.1 import/parser guard/unit/scene-smoke verification itself.
3. Challenger has no unresolved `NEEDS_FIX` or machine-observable `UNVERIFIED` item.
4. Challenger says the canonical task's full machine-verifiable complete-playable scope is satisfied; a single green batch is not enough.
5. Merge is performed with the reviewed expected head SHA and refuses head drift.
6. Challenger explicitly dispatches `Godot Check` against merged `main` and observes success.
7. Only then is the task closed with `ACCEPTED`.
8. Subjective peel feel, Foley pleasantness, visual naturalness and overall tactile satisfaction remain experiential `UNVERIFIED` until the owner downloads the result and playtests it locally.

For visual work, a concrete target image/mockup must precede Godot implementation when a visual solution is known, and the newest runtime capture must be compared against that target. Functional green alone is not visual acceptance.

## Security boundary

Codex receives only `OPENAI_API_KEY` through OpenAI's action/proxy and never receives the GitHub write token as a prompt value. Builder Codex has workspace-write filesystem permission but network access is sandboxed; deterministic steps outside Codex own git push, PR/comment and counterpart dispatch operations. Challenger Codex is read-only. Both workflows reject or avoid agent-authored changes to `.github/` and `.agents/` during normal gameplay work.

## Activation

Actual Codex runs require repository Actions secret `OPENAI_API_KEY`. Configure it only in GitHub repository **Settings → Secrets and variables → Actions**. Never commit the value or paste it into issues, PRs, logs, prompts, or chat.

The secret may incur OpenAI API usage and GitHub Actions usage when the agent loop runs. The repository therefore uses event/dispatch operation rather than polling and enforces the bounded round guard above.

## Failure mode

If the AI key is absent, API access fails, or either agent workflow is unavailable, ordinary Godot development and `Godot Check` remain usable. Agent infrastructure must never be required to open or play the game.
