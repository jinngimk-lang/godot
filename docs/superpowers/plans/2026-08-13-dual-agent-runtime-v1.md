# Dual-Agent Runtime V1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Run two genuinely independent repository agents—`peel-builder` and `peel-challenger`—that discover each other, communicate through durable GitHub artifacts, cross-test exact heads, and hand work back and forth until a change is accepted.

**Architecture:** Keep deterministic Godot CI authoritative. Add repository-owned agent identity/protocol files plus two GitHub Agentic Workflow Markdown sources compiled by the official `github/gh-aw` toolchain. Builder proposes code through safe-output PR creation; Challenger independently inspects exact PR heads, publishes counterexamples/verdicts, and may dispatch Builder again for repair. Agent outages never block gameplay or ordinary CI.

**Tech Stack:** GitHub Actions, GitHub Agentic Workflows (`github/gh-aw` current stable release at compile time), OpenAI Codex engine, GitHub Issues/PRs, Godot 4.7.1 deterministic CI.

## Global Constraints

- Canonical repository: `jinngimk-lang/godot`.
- Runtime engine: Godot 4.7.1 stable.
- Agent engine: `codex` with repository secret `OPENAI_API_KEY`; secret must never be committed or printed.
- Builder and Challenger must execute in distinct GitHub Actions workflow runs and distinct fresh contexts.
- Builder cannot self-approve or self-merge.
- Challenger must verify exact artifacts, not Builder summaries.
- Existing Godot CI remains independent and authoritative for import/unit/smoke checks.
- No continuous polling in V1; use manual/event/dispatch triggers to control cost.
- Agent infrastructure must not be required to run the game locally.
- GitHub Agentic Workflows is a preview dependency; role/protocol contracts remain backend-independent.

---

### Task 1: Repository-owned identities and mailbox protocol

**Files:**
- Create: `.agents/README.md`
- Create: `.agents/CONTACTS.md`
- Create: `.agents/protocol.md`
- Create: `.agents/state.json`

**Interfaces:**
- Produces stable identities `peel-builder` and `peel-challenger`.
- Produces message envelope fields: `type`, `from`, `to`, `artifact`, `sha`, `claim`, `evidence`, `next_action`.
- Produces state values: `BOOTSTRAPPING`, `READY`, `WORKING`, `CHALLENGED`, `NEEDS_FIX`, `VERIFIED`, `ACCEPTED`, `BLOCKED_SECRET`.

- [ ] **Step 1:** Write protocol files defining PR comments as the concrete-change mailbox and Issues as task/handoff mailbox.
- [ ] **Step 2:** Define stale-evidence rule: any evidence whose SHA is not the current artifact head is invalid.
- [ ] **Step 3:** Define Builder→Challenger and Challenger→Builder handoff templates with exact SHA requirements.
- [ ] **Step 4:** Commit and inspect for secret values, absolute paths, TODO/TBD placeholders.

### Task 2: Builder agentic workflow source

**Files:**
- Create: `.github/workflows/agent-builder.md`

**Interfaces:**
- Trigger: `workflow_dispatch` with `task`, `issue_number`, and optional `challenger_feedback` inputs.
- Engine: `codex`.
- Reads: repository, issues, PRs, Actions status.
- Safe outputs: draft PR creation, issue/PR comments, and dispatch of `agent-challenger`.
- Must never expose merge safe-output.

- [ ] **Step 1:** Define least-privilege frontmatter with read permissions and bounded safe outputs.
- [ ] **Step 2:** Prompt Builder to reproduce failures, add tests, run Godot checks when practical, and state UNVERIFIED experiential claims.
- [ ] **Step 3:** Require Builder output to include exact produced head SHA and dispatch Challenger after a proposal exists.
- [ ] **Step 4:** Ensure protected `.github/` and `.agents/` files are not normal Builder mutation targets.

### Task 3: Challenger agentic workflow source

**Files:**
- Create: `.github/workflows/agent-challenger.md`

**Interfaces:**
- Trigger: `workflow_dispatch` with `pr_number`, `builder_claim`, and `expected_head_sha`.
- Engine: `codex`.
- Reads: repository, PR diff/head, Actions status, specs/tests/asset provenance.
- Safe outputs: PR review/comment, issue comment/create, and dispatch of `agent-builder` for repair.
- No merge safe-output.

- [ ] **Step 1:** Define separate instructions that forbid accepting Builder self-reports.
- [ ] **Step 2:** Require Challenger to fetch/check current PR head and mark stale requests rather than reviewing the wrong SHA.
- [ ] **Step 3:** Require adversarial checks for parse/load false-green, missing tests/resources, path assumptions, asset licenses, state-machine edge cases and regressions.
- [ ] **Step 4:** On FAIL/NEEDS_FIX, dispatch Builder with the counterexample; on VERIFIED, publish exact-head verdict and stop.

### Task 4: Compile and validate hardened lock workflows

**Files:**
- Create: `.github/workflows/agent-bootstrap.yml`
- Generated: `.github/workflows/agent-builder.lock.yml`
- Generated: `.github/workflows/agent-challenger.lock.yml`

**Interfaces:**
- Bootstrap installs current official `github/gh-aw`, runs `gh aw compile`, and verifies source/lock consistency.
- Bootstrap never receives `OPENAI_API_KEY`.

- [ ] **Step 1:** Add a manual bootstrap workflow with `contents: read` that compiles both Markdown sources and uploads generated lock files as an artifact.
- [ ] **Step 2:** Run bootstrap in GitHub Actions and require compile success.
- [ ] **Step 3:** Materialize exact generated `.lock.yml` content into the branch and rerun ordinary CI/compile validation.
- [ ] **Step 4:** Record gh-aw version used and compiler success in PR evidence, not in a self-referential head marker file.

### Task 5: Secret/activation boundary

**Files:**
- Modify: `.agents/README.md`

**Interfaces:**
- Required secret: `OPENAI_API_KEY` in GitHub repository Actions secrets.
- Optional future CI trigger token: `GH_AW_CI_TRIGGER_TOKEN`; not required for V1 because Builder explicitly dispatches Challenger and deterministic CI can be checked independently.

- [ ] **Step 1:** Document exact GitHub UI location for the owner to add `OPENAI_API_KEY` without ever revealing the value to agents/chat.
- [ ] **Step 2:** Ensure workflows fail closed with a clear activation error when the secret is absent.
- [ ] **Step 3:** Confirm no secret values or secret-derived output appear in tracked files.

### Task 6: Controlled two-agent discovery trial

**Files:**
- No production-code change required; use a dedicated GitHub Issue and draft PR created by the agents.

**Interfaces:**
- Builder message: `CLAIM` on an exact PR head.
- Challenger response: `VERIFIED`, `COUNTEREXAMPLE`, `NEEDS_FIX`, or `UNVERIFIED` on that exact head.

- [ ] **Step 1:** Create a task Issue instructing Builder to make a tiny test-only/documentation-safe project improvement with an intentionally reviewable acceptance target.
- [ ] **Step 2:** Dispatch Builder and verify a distinct workflow run exists.
- [ ] **Step 3:** Verify Builder creates a proposal and dispatches Challenger.
- [ ] **Step 4:** Verify Challenger runs separately, identifies Builder by protocol/PR metadata, and posts an exact-head verdict.
- [ ] **Step 5:** If Challenger finds a defect, require Builder repair and a fresh Challenger run on the new head.
- [ ] **Step 6:** Do not call the runtime READY until GitHub history shows both independent runs and the handoff loop.

### Task 7: Project-wide acceptance gate and long-running handoff

**Files:**
- Modify: `.agents/README.md`
- Modify: project workflow documentation only if the trial exposes a concrete gap.

**Interfaces:**
- `ACCEPTED` requires: Builder artifact + Challenger exact-head VERIFIED + Godot CI green + protected merge + merged-main Godot CI green.

- [ ] **Step 1:** Integrate the dual-agent gate into normal project operating instructions.
- [ ] **Step 2:** Keep subjective hand feel/audio/visual quality explicitly UNVERIFIED until owner playtest evidence arrives.
- [ ] **Step 3:** Use new owner feedback as TASK/COUNTEREXAMPLE input for the next Builder run, followed by Challenger re-verification.
- [ ] **Step 4:** Preserve fallback: if either AI workflow is unavailable, deterministic CI and normal repository development continue.

### Task 8: PR exact-head and merged-main verification

**Files:**
- No new runtime files unless review finds a defect.

- [ ] **Step 1:** Open a PR from `feat/dual-agent-runtime-v1` to `main`.
- [ ] **Step 2:** Require ordinary Godot 4.7.1 CI success on exact PR head.
- [ ] **Step 3:** Inspect full diff for secret exposure, write/merge over-permission, unpinned/unsafe bootstrap behavior, and accidental runtime dependency on agent files.
- [ ] **Step 4:** Merge only with expected-head protection.
- [ ] **Step 5:** Require merged `main` Godot CI success.
- [ ] **Step 6:** Report runtime as `READY` only if the controlled two-agent trial has also completed; otherwise report `INSTALLED / BLOCKED_SECRET` with the exact missing activation dependency.
