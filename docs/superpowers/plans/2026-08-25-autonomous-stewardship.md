# Autonomous Stewardship and Ecosystem Intelligence Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make Peel Calm self-maintaining across long contexts: persist owner intent, continuously evaluate relevant Godot/project developments, safely absorb high-value compatible ideas/assets, and keep the playable project on a verified stable engine baseline.

**Architecture:** `.agents/PROJECT_NORTH_STAR.md` remains canonical product memory, `.agents/PROJECT_KNOWLEDGE.md` remains compact operational memory, and `CURRENT_HANDOFF.md` carries current execution state. External intelligence is advisory until it passes relevance, license/provenance, dependency, architecture, and exact-runtime verification gates. Engine patch upgrades are accepted only after the full existing Godot workflow passes on the candidate version.

**Tech Stack:** Godot 4.7.x, GDScript, GitHub Actions, repository-local Markdown governance, GitHub public-repository research.

**Spec:** `.agents/PROJECT_NORTH_STAR.md`

## Global Constraints

- Object-only realtime Godot interaction remains authoritative; no visible hands/arms and no fake still/video gameplay.
- A fresh clone/ZIP must run without private runtime secrets, AI services, Blender, hidden downloads, or mandatory third-party Godot plugins.
- External code/assets require explicit license/provenance before copying; unknown-license sources may inform original implementation but are not copied.
- External additions must improve a current user-visible goal and must not add unnecessary runtime dependencies.
- Exact-head Godot verification and runtime captures remain mandatory for visible/gameplay changes.
- Conversation memory never overrides repository-owned North Star/current main evidence.

---

### Task 1: Persist autonomous stewardship rules

**Files:**
- Modify: `.agents/PROJECT_NORTH_STAR.md`
- Modify: `.agents/PROJECT_KNOWLEDGE.md`
- Modify: `.agents/skills/peel-calm-reference-realism/CURRENT_HANDOFF.md`

**Interfaces:**
- Consumes: owner authorization for normal reversible repository decisions and continuous ecosystem review.
- Produces: repository-owned recovery rules that future agents can reread after compaction or handoff.

- [ ] **Step 1: Add autonomy boundary**

Record that normal reversible product/engineering decisions are autonomous and should not trigger repeated owner questions. Preserve existing escalation boundaries for destructive/irreversible actions, secrets, paid services, legal commitments, and external publishing.

- [ ] **Step 2: Add ecosystem intelligence gate**

Record this pipeline exactly in meaning:

`discover -> relevance check -> license/provenance check -> dependency/architecture check -> isolated experiment -> exact Godot verification -> runtime visual comparison -> integrate or reject -> update memory`

- [ ] **Step 3: Add long-context recovery behavior**

Require rereading North Star + knowledge + current handoff whenever context is compacted, uncertain, or a new agent/session begins.

- [ ] **Step 4: Commit**

Commit with message `docs: codify autonomous project stewardship`.

### Task 2: Adopt the current compatible Godot maintenance release

**Files:**
- Modify: `.github/workflows/godot-check.yml`

**Interfaces:**
- Consumes: official Godot 4.7.2 stable Linux x86_64 archive and published SHA-256.
- Produces: CI verification of the existing complete Peel Calm loop on Godot 4.7.2.

- [ ] **Step 1: Update workflow download**

Replace `4.7.1-stable` with `4.7.2-stable` and use Linux x86_64 SHA-256 `cadd3204e728a35d3f13adb7fd0d7902636b79f6b95c40c265eb73b6c35329e4`.

- [ ] **Step 2: Preserve the full regression suite**

Do not remove import/parse guard, default launch, deterministic tests, complete peel/residue flow, scene smokes, input boundary smokes, or 35-frame runtime capture.

- [ ] **Step 3: Run exact-head GitHub Actions**

A green job must prove import, launch, tests, all smokes, and capture generation on 4.7.2. If it fails, diagnose before accepting the engine bump.

- [ ] **Step 4: Inspect runtime capture artifact**

Confirm the patch update did not introduce obvious GL compatibility material/transparency/layout regression.

- [ ] **Step 5: Commit**

Commit with message `ci: verify Peel Calm on Godot 4.7.2`.

### Task 3: Establish an external-source adoption ledger

**Files:**
- Create: `docs/research/ECOSYSTEM_WATCH.md`

**Interfaces:**
- Consumes: public Godot releases, relevant GitHub repositories, techniques, assets, and engine/plugin developments.
- Produces: compact evidence ledger with `candidate / value / license / dependency / decision / integration evidence` fields.

- [ ] **Step 1: Record initial scan**

Record Godot 4.7.2 stable as `ADOPT_AFTER_GREEN` and `maantho/gpu-texture-painter` as `STUDY_PATTERN_ONLY` because its MIT-licensed GPU atlas/brush approach is relevant to spatial residue clearing but a mandatory third-party plugin would violate the project's dependency boundary.

Record `alfredbaudisch/GodotRuntimeTextureSplatMapPainting` as `NO_COPY_LICENSE_UNCLEAR`; it may inform independent research but no source/assets are copied without explicit licensing.

- [ ] **Step 2: Define adoption outcomes**

Use only `INTEGRATE`, `STUDY_PATTERN_ONLY`, `WATCH`, `REJECT`, and `NO_COPY_LICENSE_UNCLEAR`.

- [ ] **Step 3: Commit**

Commit with message `docs: add ecosystem adoption ledger`.

### Task 4: Continue product work from ecosystem findings

**Files:**
- Modify/create only after a RED contract is written for the selected improvement.

**Interfaces:**
- Consumes: current highest-value product priorities and vetted external patterns.
- Produces: original repository-native implementation with no unnecessary plugin dependency.

- [ ] **Step 1: Prefer spatial residue clearing**

Use the external GPU-paint research only as an architectural reference. Prototype a Peel Calm-specific local residue mask that clears where the cursor actually rubs; keep gameplay authority deterministic and testable.

- [ ] **Step 2: Generate/record a concrete visual target before production visual changes**

Use the project's image-first convergence rule: target/mockup -> observable constraints -> Godot implementation -> runtime capture -> side-by-side comparison -> largest mismatch iteration.

- [ ] **Step 3: Preserve completion gates**

Continue must remain unavailable until the required cleaning interaction reaches completion; no stationary or outside-footprint input may create progress.

- [ ] **Step 4: Verify before integration**

Run exact-head full CI and inspect all affected runtime captures before merge.
