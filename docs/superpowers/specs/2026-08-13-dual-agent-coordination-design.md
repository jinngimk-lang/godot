# Dual-Agent Coordination Design

## Goal
Create a repository-local communication and verification protocol so two autonomous agents can work as `PRIMARY` (Owner/Builder) and `CHALLENGER` (Independent Challenger/Verifier), deliberately covering each other's blind spots instead of duplicating work.

## Chosen operating model
The project uses an asymmetric pair:

- `PRIMARY` owns the product plan, main implementation path, integration sequence, and candidate delivery SHA.
- `CHALLENGER` owns adversarial review, boundary-condition discovery, mature-solution research, falsifying tests, exact-SHA verification, and isolated corrective work.

The relationship is cooperative but not deferential. Evidence can overturn either agent's implementation choice.

## Communication architecture
The repository itself is the communication channel.

1. Root `AGENTS.md` is the durable protocol that any coding agent should read before changing the repository.
2. GitHub Issue #5, `[AGENT HUB] PRIMARY ↔ CHALLENGER coordination`, is the live message bus for claims, handoffs, RED/GREEN evidence, blockers, and releases.
3. PR comments hold change-specific evidence. The hub is for cross-PR coordination and ownership state.
4. Both agents may appear under the same GitHub account, so messages identify the agent in content (`AGENT: PRIMARY` / `AGENT: CHALLENGER`) rather than by username.

## Claim and collision avoidance
Before modifying production code, an agent posts a narrow claim with exact base SHA, branch, and files/globs claimed.

If claims overlap, the second agent does not independently rewrite the same production file. It may still:

- create a reproducer or falsifying test in a non-overlapping file;
- research an external solution and post evidence;
- request a handoff;
- verify an exact SHA without modifying it.

Claims are released explicitly when work is completed, superseded, or abandoned.

## Verification flow
The normal delivery loop is:

`PRIMARY candidate SHA -> CHALLENGER exact-SHA challenge -> PASS or falsifying RED -> fix/absorb -> exact merge-tree verification -> merge -> fresh main verification`.

A green feature-branch run is not sufficient when the base moved. When feasible, the challenger verifies the actual PR merge tree or regenerates a fresh integration branch from the latest base.

## Blind-spot allocation
The CHALLENGER preferentially investigates:

- fake-green CI and parse/import errors hidden behind exit code 0;
- boundary conditions and state transitions;
- runtime behavior not covered by pure unit tests;
- touch/device/platform behavior;
- asset source, license, provenance, and runtime dependency boundaries;
- fallback paths;
- performance or memory regressions;
- mismatch between UI/visual state and game state;
- mature open-source patterns that can replace fragile custom work.

The PRIMARY preferentially challenges the CHALLENGER on:

- scope creep and overengineering;
- unnecessary dependencies;
- tests coupled to implementation details rather than user-visible contracts;
- replacing a working implementation merely to own the code;
- changes that complicate the main product path without measurable benefit.

## Authority and conflict resolution
Evidence outranks authorship and chronology. If both agents implement the same requirement differently, compare both against the same user-visible contract and exact-SHA evidence. Preserve compatible strengths and discard the weaker solution.

Neither agent may represent same-account GitHub activity as independent human approval. Independence means independent reasoning/testing paths, not a separate account identity.

## Autonomy boundary
Normal, reversible repository work proceeds without asking the owner for routine approval. Stop only for destructive or irreversible actions, secrets/credentials, paid services, legal commitments, sensitive disclosures, or actions outside the repository that exceed standing authorization.

## Success criteria
The mechanism is successful when:

- any agent entering the repository can discover its role and the live coordination channel;
- production-file collisions are surfaced before parallel rewrites;
- every candidate integration can be challenged by a different reasoning/testing pass;
- RED/GREEN and exact-SHA evidence remain auditable after the work is done;
- one agent can catch and fix an omission without waiting for the owner to manually route work.