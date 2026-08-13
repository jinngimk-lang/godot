# Dual-Agent Runtime Direct Codex Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: use `superpowers:executing-plans` for bootstrap; after activation, the two repository agents execute ordinary game tasks through the repository protocol.

**Goal:** Install two separate OpenAI Codex GitHub Actions workflows that repeatedly build and independently challenge one evolving game PR until complete-machine acceptance, then merge and reverify main.

**Architecture:** `agent-builder.yml` runs workspace-write Codex on the actual Builder branch and deterministic Godot verification before any push. It explicitly dispatches `agent-challenger.yml`, whose separate read-only Codex run independently checks the exact head plus Godot verification; Challenger either dispatches Builder with a counterexample/continuation or performs expected-head merge and explicitly dispatches merged-main `Godot Check`.

**Tech Stack:** Godot 4.7.1, GitHub Actions, `openai/codex-action` pinned to v1.11 commit `52fe01ec70a42f454c9d2ebd47598f9fd6893d56`, GitHub CLI, repository Actions secret `OPENAI_API_KEY`.

## Global Constraints

- Builder and Challenger must be separate Actions workflow runs and separate Codex calls.
- Builder cannot merge itself.
- Challenger must inspect actual exact head and run its own deterministic Godot verification.
- Each new head invalidates prior Challenger evidence.
- Normal gameplay tasks cannot modify `.github/`, `.agents/`, secrets, billing or repository policy.
- Agent handoff is event/dispatch based and bounded at round 20.
- Runtime game startup never depends on AI infrastructure.
- Subjective tactile/visual/audio quality stays UNVERIFIED until owner local playtest.

---

### Task 1: Repository protocol and shared product memory

**Files:** `.agents/README.md`, `.agents/CONTACTS.md`, `.agents/protocol.md`, `.agents/PROJECT_KNOWLEDGE.md`, `.agents/state.json`.

- [x] Define stable Builder/Challenger identities.
- [x] Define TASK/CLAIM/RED/COUNTEREXAMPLE/FIX/VERIFIED/UNVERIFIED/ACCEPTED messages with exact SHA.
- [x] Preserve product thesis, V1/V2 owner failures, tactile priorities, content boundaries and verification rules in shared knowledge.

### Task 2: Builder runtime

**File:** `.github/workflows/agent-builder.yml`.

- [x] Owner `[AGENT-TASK]` Issue or explicit dispatch starts Builder.
- [x] Resolve one existing Builder PR or create one task branch.
- [x] Install pinned Godot before Codex sandboxing.
- [x] Run Codex with `:workspace`, `drop-sudo`, no GitHub write token in prompt.
- [x] Reject protected infrastructure edits.
- [x] Run Godot import/parser guard/unit/smoke before push.
- [x] Commit/push only after deterministic success, publish exact-head CLAIM, dispatch Challenger once.

### Task 3: Challenger runtime

**File:** `.github/workflows/agent-challenger.yml`.

- [x] Accept exact task/PR/head dispatch only.
- [x] Reject stale-head verification.
- [x] Independently run Godot 4.7.1 verification.
- [x] Run Codex with `:read-only`, `drop-sudo`, strict JSON verdict schema.
- [x] Require at least one adversarial counterexample/boundary analysis.
- [x] Dispatch Builder for repair or next incomplete complete-version batch.
- [x] Merge only VERIFIED + complete machine scope + exact unchanged head.
- [x] Explicitly dispatch merged-main Godot Check, wait for success, then ACCEPTED/close task.

### Task 4: Standard verification integration

**File:** `.github/workflows/godot-check.yml`.

- [x] Add `workflow_dispatch` for explicit post-merge verification.
- [x] Add static guard for both agent workflows, shared knowledge and immutable Codex Action pin.
- [x] Add heuristic secret-material scan.
- [x] Preserve existing Godot 4.7.1 checksum/import/parser/unit/smoke behavior.

### Task 5: Infrastructure PR gate

- [ ] Require fresh Godot Check success on exact infrastructure PR head.
- [ ] Review full diff for secret values, excessive model permissions, untrusted automatic triggers and uncontrolled dispatch recursion.
- [ ] Merge with expected head protection.
- [ ] Require fresh merged-main Godot Check success.

### Task 6: Real activation and mutual discovery trial

- [ ] Configure `OPENAI_API_KEY` only as GitHub Actions secret; never expose value in chat or repository.
- [ ] Create canonical owner Issue titled `[AGENT-TASK] Complete playable Peel Calm before owner handoff` with machine and experiential acceptance boundaries.
- [ ] Observe a real Builder run ID and resulting `[builder]` PR.
- [ ] Observe Builder's workflow_dispatch creating a separate Challenger run ID.
- [ ] Require Challenger exact-head comment and either repair/continuation dispatch or final verdict.
- [ ] Do not claim the two agents are operating until both distinct Codex runs exist in GitHub history.

### Task 7: Complete-playable autonomous loop

- [ ] Builder and Challenger iterate the same PR across the canonical complete-game acceptance scope.
- [ ] Preserve owner V1/V2 regression fixes on every batch.
- [ ] Prefer tactile quality/onboarding/presentation/replayable sensory variation over large meta-system breadth.
- [ ] Challenger only ends the loop when all machine-verifiable complete scope is satisfied and remaining uncertainty is experiential.
- [ ] Final expected-head merge + explicit merged-main Godot Check must succeed.
- [ ] Owner receives the resulting main build for local Godot playtest/screenshots; subjective feedback starts the next evidence loop.

## Runtime-switch evidence

The earlier `gh-aw` prototype remains useful evidence: the separate Builder/Challenger source definitions passed strict compiler validation, but an attempt to have the default GitHub Actions installation token commit generated workflow files was correctly rejected because workflow-file modification requires additional authority. The direct Codex Action design deliberately removes that unnecessary credential expansion instead of bypassing the guard.
