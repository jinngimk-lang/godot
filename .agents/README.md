# Peel Calm Dual-Agent Runtime

This directory defines the repository-owned collaboration contract for two independent AI coding agents.

## Identities

- `peel-builder`: implementation, reproduction, repair, tests, draft PR proposals.
- `peel-challenger`: independent challenge, counterexamples, exact-head verification, repair requests.

The two roles must run in separate GitHub Actions agentic-workflow runs. A single chat session switching roles does not count as dual-agent verification.

## Shared project context

Before acting, both agents must read:

1. `.agents/PROJECT_KNOWLEDGE.md`
2. `.agents/protocol.md`
3. the latest relevant files under `docs/superpowers/specs/`
4. the latest relevant files under `docs/superpowers/plans/`
5. `README.md`
6. current tests and `.github/workflows/godot-check.yml`

Repository history and exact GitHub artifacts are evidence. Summaries are not substitutes for inspecting the actual current head.

## Acceptance gate

A gameplay change is not `ACCEPTED` until all of these are true:

1. Builder has produced a falsifiable claim and exact proposed PR head.
2. Challenger has independently inspected that same exact head and has no unresolved `FAIL` or `NEEDS_FIX` finding.
3. Godot 4.7.1 deterministic CI is green on the exact PR head.
4. Merge is protected against head drift.
5. Merged `main` runs Godot 4.7.1 CI successfully again.
6. Subjective visual/audio/tactile claims remain `UNVERIFIED` until owner playtest evidence exists.

## Runtime status

The collaboration protocol is backend-independent. GitHub Agentic Workflows + Codex is the initial runtime. If the AI engine is unavailable, ordinary development and deterministic CI continue; the agent outage must never prevent the game from opening locally.

## Activation

Codex-backed runs require repository Actions secret `OPENAI_API_KEY` (or `CODEX_API_KEY`). Configure it only in GitHub repository Settings → Secrets and variables → Actions. Never commit the value or paste it into issues, PRs, logs, prompts, or chat.
