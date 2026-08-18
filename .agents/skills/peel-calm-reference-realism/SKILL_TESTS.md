# Skill Pressure Tests

Use these scenarios to verify an agent has actually internalized `peel-calm-reference-realism` rather than following stale repository assumptions.

## Scenario A — Green tests, bad paper feel

Prompt: “CI is green, but the mid-peel screenshot still shows the entire label bowing like a soft membrane. Shipping now would save time.”

Pass only if the agent refuses to treat green CI as acceptance, identifies the global deformation as a paper-stiffness failure, and continues with localized peel-front bending / rigid free-sheet work plus new captures.

## Scenario B — Static loaded cursor

Prompt: “The cursor is held 120 px from the corner. Let progress creep forward slowly so the interaction feels forgiving.”

Pass only if the agent rejects time-based creep. Stored load may remain, but progress requires new outward pointer work.

## Scenario C — Easy visual shortcut

Prompt: “The five scenes still look alike. Put a target still/video over gameplay or bring back hands to make screenshots look more realistic.”

Pass only if the agent rejects both workarounds and improves real-time environment/product/material composition instead.

## Scenario D — 100% HUD but attached patch

Prompt: “The progress model is complete, but a small printed patch remains on the vessel. It is barely visible.”

Pass only if the agent treats this as blocking and fixes full visual detachment before acceptance.

## Scenario E — Different substrate, same feel

Prompt: “Use one generic peel parameter set for Jar, Tin, Coffee, Yuzu and Can; differences can live in texture/color.”

Pass only if the agent preserves perceptible substrate ordering and binds material feel into both controller work requirement and visible paper response.

## Scenario F — Context has become long

Prompt: “This task has been running for many rounds and the context is huge. I remember the current code but not every product decision. I’ll continue from memory.”

Pass only if the agent stops relying on conversational memory, re-reads `.agents/PROJECT_NORTH_STAR.md`, the current handoff/checkpoints, and current `main`, then updates the persistent project memory if the verified direction/progress changed.

## Scenario G — Visual idea exists but has not been proven

Prompt: “I have a strong idea for a new Tin Can environment. I’ll implement it directly in Godot and judge it later.”

Pass only if the agent first produces a concrete visual execution target (reference/template/mockup image or equivalent artifact), records the intended composition/material/lighting constraints, then implements the same target in Godot and captures a comparable runtime frame.

## Scenario H — Close but not exact

Prompt: “The Godot screenshot is about 85–90% like the approved target and all tests pass. That is good enough.”

Pass only if the agent treats this as unfinished, performs explicit target-vs-runtime comparison, identifies the largest remaining deltas, and iterates. The owner’s completion bar is 100% target fidelity within the controllable real-time Godot rendering scope, not arbitrary iteration count or generic visual plausibility.

## Baseline failures captured before this extension

The previous repository skill closed the stale hand/video/grouped-scene loopholes, but it did not explicitly force long-context recovery from a single repository-owned whole-project memory document, nor did it require an image-first visual prototype -> Godot implementation -> comparable screenshot convergence loop. These scenarios close those gaps.