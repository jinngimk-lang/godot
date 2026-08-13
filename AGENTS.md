# Peel Calm Agent Entry Point

This repository is operated by two cooperating autonomous agents with asymmetric roles.

## Identify yourself first

Before changing repository files, declare one of these roles in the live coordination hub:

- `AGENT: PRIMARY` — Owner/Builder. Owns product direction, main implementation path, integration sequencing, and candidate delivery SHAs.
- `AGENT: CHALLENGER` — Challenger/Verifier. Owns adversarial review, blind-spot discovery, mature-solution research, falsifying tests, exact-SHA verification, and isolated corrective work.

Do not infer agent identity from the GitHub account name. Both agents may act through the same repository identity.

## Live coordination channel

Use GitHub Issue #5, **`[AGENT HUB] PRIMARY ↔ CHALLENGER coordination`**, as the cross-PR message bus.

Before modifying production code, post a narrow claim containing:

```text
AGENT: PRIMARY | CHALLENGER
ROLE: OWNER/BUILDER | CHALLENGER/VERIFIER
TASK: short task name
BASE_SHA: exact commit or N/A
BRANCH: branch name or N/A
FILES_CLAIMED: paths/globs or NONE
STATUS: CLAIM | UPDATE | HANDOFF | RED | GREEN | BLOCKED | RELEASED
EVIDENCE: exact test/run/PR/commit references or UNVERIFIED
BLOCKER: NONE or concrete blocker
NEXT_ACTION: one concrete next action
```

If another agent already claims an overlapping production file, do not silently rewrite it in parallel. Prefer a non-overlapping reproducer/test/research path or request a handoff in Issue #5.

## Durable protocol

The PRIMARY is building the fuller dual-agent runtime and repository protocol on `feat/dual-agent-runtime-v1`. Once `.agents/README.md`, `.agents/CONTACTS.md`, and `.agents/protocol.md` exist, treat them as the detailed contract and this file as the stable entry point.

## Verification invariant

Normal integration flow:

`PRIMARY candidate SHA -> CHALLENGER exact-SHA challenge -> PASS or falsifying RED -> fix/absorb -> exact merge-tree verification -> merge -> fresh main verification`.

A green feature branch is not sufficient evidence if the base moved. Evidence is stale when the referenced head SHA changes.

## Mutual blind-spot coverage

The CHALLENGER should preferentially inspect boundary cases, fake-green CI, runtime smoke gaps, device/touch behavior, asset provenance and licenses, performance/fallback behavior, and mismatches between visual state and game state.

The PRIMARY should preferentially challenge scope creep, overengineering, unnecessary dependencies, implementation-detail tests, and replacement of working code without measurable product benefit.

Evidence outranks authorship. When two implementations overlap, preserve the stronger compatible parts instead of merging code merely because it was written first.

## Autonomy boundary

Proceed autonomously with normal reversible repository work. Stop for destructive or irreversible actions, secrets or credentials, paid services, legal commitments, sensitive disclosures, or actions outside the repository that exceed standing authorization.
