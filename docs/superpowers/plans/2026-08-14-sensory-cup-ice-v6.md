# Sensory Cup + Contained Ice V6 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make unlocked cups visibly distinct in silhouette and add one bounded, deterministic ice-content sensory layer without introducing free rigid-body chaos or touching peel/label authority.

**Architecture:** Keep `SessionModel` as the sensory-profile source of truth. Reuse existing `cup_dimensions` to make the live `CylinderMesh` silhouette visibly different, and add a separate `CupContentsPresentation` node that consumes `contents_profile` plus the live cup dimensions. Ice cubes are presentation-only `MeshInstance3D` children with deterministic local offsets and small bounded motion driven by crumple progress/pulse; they never become physics bodies and never affect peel, cup surface, label lifecycle, score, or ritual state.

**Tech Stack:** Godot 4.7.1, GDScript, existing `SessionModel`, `PeelLab`, `CupCrumplePresentation`, headless Godot CI/smoke tests.

## Global Constraints

- Preserve the owner-approved pressure-free loop: no timers, fail states, grind pressure, or new parallel economy.
- Preserve current Foley; do not replace the existing peel/crumple sound stack wholesale.
- Keep `LabelLifecycle` and peel/cup-surface math authoritative; contents are presentation-only.
- Do not use `RigidBody3D`, `SoftBody3D`, or general physics for ice in this phase.
- Ice must be finite, resettable, deterministic, and contained inside the configured cup dimensions.
- Only later/unlocked profile(s) may expose ice; fresh first profile must remain visually quiet.
- Any visible presentation change needs a machine smoke gate and remains subject to owner playtest for aesthetics/comfort.

---

### Task 1: Sensory profile contract for real cup silhouettes and ice

**Files:**
- Modify: `scripts/session/session_model.gd`
- Modify: `tests/test_session_model.gd`

**Interfaces:**
- Produces: `current_variant()["cup_dimensions"]` with three materially distinct silhouettes.
- Produces: `current_variant()["contents_profile"]`, where the late unlocked profile uses `{ "type": "ice", "count": int, "cube_size": float, "motion_gain": float }`.

- [ ] **Step 1: Write the failing profile test**

Require all three variants to have different `(top_radius, bottom_radius, height)` signatures and require only the final unlock profile to have `contents_profile.type == "ice"` with bounded count `2..5`, cube size `0.07..0.16`, and motion gain `0.0..1.0`.

- [ ] **Step 2: Run the unit suite and prove RED**

Run the canonical Godot unit runner. Expected: failure because all current `contents_profile.type` values are `none` and cup silhouettes are only subtly different.

- [ ] **Step 3: Implement minimal profile values**

Keep first cup as the current baseline. Make second cup slightly taller/narrower and final cup shorter/wider enough to be visibly distinct at the fixed camera. Set final profile to a small ice payload (3 cubes) only.

- [ ] **Step 4: Run unit suite and prove GREEN**

Expected: all deterministic tests pass.

- [ ] **Step 5: Commit**

Commit message: `feat: define distinct sensory cup and ice profiles`.

---

### Task 2: Deterministic contained ice presentation

**Files:**
- Create: `scripts/presentation/cup_contents_presentation.gd`
- Create: `tests/smoke_cup_contents_presentation.gd`
- Modify: `.github/workflows/godot-check.yml`

**Interfaces:**
- `set_profile(profile: Dictionary) -> void`
- `set_crumple(progress: float, side: int, pulse: float) -> void`
- `reset_visual() -> void`
- `get_content_count() -> int`
- Presentation node name: `CupContentsPresentation`
- Ice child container name: `IceContents`

- [ ] **Step 1: Write failing smoke**

Instantiate production scene and require: baseline/warm profile exposes zero content meshes; an ice profile creates exactly configured cube count; every cube remains within the cup inner radius and vertical bounds; repeated `set_crumple()` calls stay finite and bounded; `reset_visual()` restores deterministic base transforms; no `RigidBody3D`/`SoftBody3D` descendants exist.

- [ ] **Step 2: Add smoke to CI and prove RED**

Expected: dedicated `Cup contents presentation smoke` fails because the node/script does not yet exist.

- [ ] **Step 3: Implement minimal presentation**

Create cubes as rounded-looking `BoxMesh` `MeshInstance3D` nodes under `IceContents`. Compute deterministic base positions from the cube index using fixed angles/radii; clamp each base position to an inner radius derived from `cup_dimensions`. Drive only small local translation/rotation from crumple progress, side, and pulse. No random calls and no physics nodes.

- [ ] **Step 4: Run CI and prove GREEN**

Expected: import, units, existing scene/presentation smokes, and new contents smoke pass.

- [ ] **Step 5: Commit**

Commit message: `feat: add bounded contained ice presentation`.

---

### Task 3: Wire contents into the real ritual lifecycle

**Files:**
- Modify: `scripts/peel_lab.gd`
- Modify: `tests/smoke_reset_loop.gd`
- Modify: `tests/smoke_scene.gd`

**Interfaces:**
- `PeelLab` owns `_contents_presentation: CupContentsPresentation`.
- `_apply_current_variant()` forwards the full variant to `set_profile()`.
- `_process_crumple_pointer()` forwards crumple progress/side/pulse after cup deformation.
- `_reset_session()` calls `reset_visual()`.

- [ ] **Step 1: Write failing integration assertions**

Require the production scene to contain `CupContentsPresentation`; first variant has zero ice; after five ritual completions and advancing to the final tactile set, content count is exactly the configured ice count; next/reset/restart does not duplicate cubes; ice remains presentation-only and label/cup-surface smokes still pass.

- [ ] **Step 2: Run canonical suite and prove RED**

Expected: integration tests fail on missing production node/wiring.

- [ ] **Step 3: Implement minimal wiring**

Create/find `CupContentsPresentation` in world setup, set its profile whenever the variant changes, forward crumple pulse/progress, and reset it with the existing ritual reset path. Keep all gameplay state unchanged.

- [ ] **Step 4: Run canonical suite and prove GREEN**

Expected: all existing gates plus contents integration pass.

- [ ] **Step 5: Commit**

Commit message: `feat: connect ice contents to tactile cup progression`.

---

### Task 4: Final regression and visual handoff gate

**Files:**
- Modify only if a verifier exposes a defect; no production changes by default.

**Interfaces:**
- Exact branch head must pass the repository's canonical `Godot Check` workflow.
- Visual claims remain limited to gross-regression evidence until owner playtest.

- [ ] **Step 1: Run exact-head canonical CI**

Verify default launch, unit tests, scene smoke, tapered label/cup-surface smoke, cafe/cup-crumple/contents/forearm smokes, repeated session, pause isolation, and reset/restart isolation.

- [ ] **Step 2: Independently challenge containment and progression**

Counterexamples: maximum crumple pulse, both squeeze sides, repeated reset, restart run, final-profile loop back to baseline, and profile values at min/max bounds.

- [ ] **Step 3: Prepare PR only if exact-head evidence is green**

PR must state that ice is deterministic presentation-only and that pleasantness/rattle preference remain owner-experiential rather than machine-proven.
