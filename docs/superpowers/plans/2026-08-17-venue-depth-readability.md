# Venue Depth Readability Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restore real venue depth cues behind the hero product while preserving the locked café/bar/market backplates and all hand/product/gameplay behavior.

**Architecture:** Keep `ReferenceBackdrop` as the atmospheric plate, but move it behind the useful `VenuePresentation` geometry and stop blanket-hiding that geometry. Lock the behavior with scene-smoke assertions before changing production code, then use exact-head runtime captures as the visual acceptance gate.

**Tech Stack:** Godot 4.7.1, GDScript, GitHub Actions `Godot Check`.

## Global Constraints

- Locked `cafe_v1`, `bar_v1`, `market_v1` remain acceptance sources of truth.
- Do not touch R1 hand pose/search while live Blender/native-rig visual authoring is unavailable.
- Macro/Meso evidence outranks Micro polish and CI-green alone.
- No hand, forearm, camera, product, label, input, reset, pause, or HUD behavior changes in this task.

---

### Task 1: RED venue-depth contract

**Files:**
- Modify: `tests/smoke_reference_scene.gd`

**Interfaces:**
- Consumes: scene nodes `ReferenceBackdrop` and `VenuePresentation`.
- Produces: a deterministic smoke contract for backdrop depth/coverage and representative visible venue props.

- [ ] **Step 1: Write the failing test** requiring `ReferenceBackdrop.position.z <= -2.45`, projected plate world width >= 8.8, and visible representative structural props for café, bar and market.
- [ ] **Step 2: Push exact RED head and run Godot Check.** Expected: scene/reference smoke fails because current backdrop is z=-1.43 and blanket masking hides venue children.
- [ ] **Step 3: Record the failing run ID and exact message before production edits.**

### Task 2: GREEN backdrop staging

**Files:**
- Modify: `scripts/presentation/reference_backdrop.gd`

**Interfaces:**
- Consumes: existing `VenuePresentation` z-layout and three locked backdrop textures.
- Produces: a background plate behind structural venue geometry with stable full-frame coverage.

- [ ] **Step 1: Move the backdrop to `Vector3(0.0, 0.72, -2.52)` and set `TARGET_WORLD_WIDTH := 9.10`.
- [ ] **Step 2: Remove `_mask_blockout_geometry()` calls and the blanket child-visibility mutation so venue geometry/lights keep their profile-owned visibility.
- [ ] **Step 3: Run exact-head Godot Check.** Expected: full deterministic suite PASS.
- [ ] **Step 4: Download exact-head nine-frame artifact and compare base + peel/inspect states against baseline `9277817340` and locked references at Macro then Meso scale.
- [ ] **Step 5: Reject or revise if venue geometry becomes more blockout-like, hero readability regresses, or any interaction-state ownership changes.

### Task 3: Challenger and checkpoint

**Files:**
- Create: `docs/superpowers/checkpoints/2026-08-17-reference-convergence-checkpoint-64.md`

**Interfaces:**
- Consumes: exact candidate SHA, CI run, runtime artifact, PR discussion.
- Produces: durable evidence and ranked remaining reds.

- [ ] **Step 1: Open a narrow PR from the unchanged exact candidate head.
- [ ] **Step 2: Run an independent Challenger on the exact PR head.
- [ ] **Step 3: Merge only if exact-head CI passes, runtime Macro improves, and Challenger has no blocker.
- [ ] **Step 4: Verify fresh merged-main CI/runtime and checkpoint the result; keep R1 hand stop condition as the next highest red unless live Blender authoring becomes available.
