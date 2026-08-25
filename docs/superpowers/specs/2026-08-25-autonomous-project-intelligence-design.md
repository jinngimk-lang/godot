# Peel Calm Autonomous Stewardship + Project Intelligence Design

Date: 2026-08-25
Status: owner-authorized design

## Goal

Keep Peel Calm continuously improving without requiring routine owner decisions. The repository, not chat history, is the durable source of product direction. New public technical information and relevant GitHub work should be evaluated continuously and adopted only when it produces a measurable product or maintenance benefit.

## Decision authority

The PRIMARY agent owns normal, reversible product and engineering decisions inside this repository. It should not stop for routine preference or implementation questions when evidence can resolve them. Destructive/irreversible actions, secrets or credentials, paid services, legal commitments, sensitive disclosures, or actions outside the repository remain outside this standing authorization.

## Durable memory

`.agents/PROJECT_NORTH_STAR.md` is the product outline and strategic authority. `.agents/PROJECT_KNOWLEDGE.md` is compact operational memory. `.agents/EXTERNAL_INTELLIGENCE.md` is the living external-watch ledger. A meaningful direction, architecture, acceptance, engine/toolchain, or priority change must update the appropriate durable files in the same workstream.

## Intelligence loop

1. Inspect current `main`, Issue #5 claims, open PRs/branches, current handoff, CI and newest runtime captures.
2. Scan trusted external sources, ordered roughly as: official Godot releases/docs/issues/proposals and official demos; maintained upstream GitHub projects; mature community references; lower-confidence discussion only as leads.
3. Triage each candidate for direct relevance, freshness, maintenance state, license/provenance, engine/rendering compatibility, dependency cost, security/privacy impact, and whether the result can be falsified by a test or runtime capture.
4. Prefer adopting a principle, test, parameter, or small isolated implementation over adding a dependency. Do not vendor code/assets merely because they are related.
5. For a worthwhile candidate, post a narrow Issue #5 claim, use an isolated branch, establish RED/acceptance evidence when practical, implement the smallest coherent change, and run canonical verification.
6. For visible work, inspect non-headless captures. Functional green never overrides a visibly worse frame.
7. Merge only exact-head verified work. Reverify merged `main` separately before calling the integration complete.
8. Record the source, decision, integration state and evidence in `.agents/EXTERNAL_INTELLIGENCE.md`; update North Star/Knowledge when the result changes durable direction.

## Adoption gates

External material may enter production only when all applicable gates pass:

- **Relevance:** it solves a current product, correctness, feel, rendering, accessibility or maintenance problem.
- **Provenance/license:** origin and license are understood before copying source/assets. When license clarity is absent, use the idea as research only.
- **Compatibility:** it fits the current stable Godot line and the project's renderer/input architecture.
- **Fresh-clone invariant:** no new runtime internet requirement, private secret, AI dependency, Blender requirement, or mandatory third-party Godot plugin is introduced without a separately justified architecture decision.
- **Evidence:** deterministic tests/smokes and, for visual changes, real runtime captures demonstrate improvement.
- **Reversibility:** adoption remains easy to revert until exact-head and merged-main verification are complete.

## Engine policy

Stay on the latest verified **stable patch** of the currently adopted Godot minor line when the patch is compatible and useful. Evaluate patch releases promptly, especially input, rendering, platform, crash and performance fixes. Preview/dev releases are research-only until an explicit migration workstream proves the benefit and compatibility.

The first execution of this policy is the 4.7.1 -> 4.7.2 patch evaluation. Godot 4.7.2 is an official maintenance release and includes a high-polling-rate mouse performance fix that is directly relevant to Peel Calm's high-frequency drag interaction.

## External-source policy

The project may learn from or selectively integrate relevant public GitHub projects, but wholesale dependency growth is not a goal. Official Godot demo code/materials are preferred reference sources. When copying a file is genuinely better than reimplementing a small principle, preserve the source repository, exact commit/tag, original file path and license/provenance note in the intelligence ledger and any required attribution file.

## Continuous operation

The monitoring loop is not a release-only task. It should run on a recurring basis and also before major product/rendering/input changes. A scan with no material finding should make no repository churn. A material finding should result in either (a) a recorded research/watch decision, or (b) a claimed, testable integration workstream.
