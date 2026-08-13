# Dual-Agent Protocol

Every evidence-bearing message must identify the artifact it refers to. For PR work, include the current PR number and exact head SHA. Evidence for an older head is stale immediately when the head changes.

## Message envelope

```text
TYPE: TASK | CLAIM | RED | COUNTEREXAMPLE | FIX | VERIFIED | UNVERIFIED | ACCEPTED
FROM: peel-builder | peel-challenger | owner | ci
TO: peel-builder | peel-challenger | owner | all
ARTIFACT: issue/PR/run identifier
SHA: exact commit SHA, or NONE only for a task before an artifact exists
CLAIM: one falsifiable statement
EVIDENCE: commands/runs/files/observations that support or refute the claim
NEXT_ACTION: one concrete next action
```

## Required flow

```text
TASK
  -> Builder reproduces/understands target
  -> RED when a behavior gap can be made falsifiable
  -> Builder creates/updates proposal
  -> CLAIM on exact head
  -> Challenger independently inspects exact head
       -> VERIFIED, or
       -> COUNTEREXAMPLE / NEEDS_FIX -> Builder FIX -> fresh Challenger verification
  -> deterministic Godot CI green on exact reviewed head
  -> protected merge
  -> merged-main Godot CI green
  -> ACCEPTED
```

## Builder rules

- Read `.agents/PROJECT_KNOWLEDGE.md` and current specs/tests before changing production code.
- Reproduce user-reported failures before fixing when the failure is machine-observable.
- Prefer RED -> GREEN behavior evidence.
- Keep gameplay authority deterministic; visuals/audio must not silently decide peel success.
- Do not change `.github/`, `.agents/`, repository secrets, licensing policy, or branch-protection policy through normal gameplay tasks.
- Do not merge or approve your own work.
- State experiential quality as `UNVERIFIED` unless owner playtest evidence exists.

## Challenger rules

- Fetch the actual current PR head and diff. Never review only Builder's summary.
- If requested SHA differs from current head, post `UNVERIFIED: stale head` and re-target the current artifact before verdict.
- Attempt at least one counterexample beyond existing happy-path tests.
- Check parsing/import false-green risk, missing resources, path assumptions, state-machine boundaries, reset/completion one-shot behavior, input regression, licensing/provenance for new external assets, and whether automated evidence overclaims subjective quality.
- On a reproducible defect, post exact reproduction and send repair work back to Builder.
- A green Builder test result is evidence to inspect, not a conclusion to reuse.

## Loop control

The normal handoff is linear and bounded:

`Builder -> Challenger -> Builder -> Challenger`.

Each workflow run may dispatch at most one counterpart run. Do not self-dispatch. If the same defect survives two repair attempts, create `UNVERIFIED`/`NEEDS_FIX` evidence with the narrowed root cause instead of generating an unbounded agent loop.

## Acceptance

Only merged-main verification may emit `ACCEPTED`. A PR-level Challenger verdict is `VERIFIED`, not `ACCEPTED`.
