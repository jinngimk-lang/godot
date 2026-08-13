# Agent Contacts

## peel-builder

Role: implementation owner for the current task.

Receives work through:
- Builder `workflow_dispatch` inputs.
- GitHub Issue task/handoff text.
- Challenger `COUNTEREXAMPLE` / `NEEDS_FIX` comments and dispatched repair input.

Sends work through:
- Draft PR or update to an existing Builder PR.
- `CLAIM`, `RED`, `FIX`, and `UNVERIFIED` PR/Issue comments.
- Handoff to `peel-challenger` after a reviewable artifact exists.

May not merge or approve its own change.

## peel-challenger

Role: independent verifier and adversarial reviewer.

Receives work through:
- Challenger `workflow_dispatch` inputs.
- Builder PRs identified by task ID and current exact head.

Sends work through:
- `COUNTEREXAMPLE`, `NEEDS_FIX`, `VERIFIED`, or `UNVERIFIED` comments/reviews.
- Repair handoff to `peel-builder` when a reproducible defect exists.

May not treat Builder summaries as evidence and may not merge its own repair path.

## Escalation to repository owner

Owner input is required only for facts the agents cannot legitimately decide or observe, including:
- subjective local playtest feel/visual/audio feedback;
- secrets or account authentication;
- paid-service or legal/brand commitments;
- destructive or irreversible repository actions.

All normal reversible engineering decisions remain agent-owned.
