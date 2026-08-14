# Peel Calm V5 Ritual Core Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the current detach→2.15s auto-next score loop with a pressure-free peel→settle→cup-crumple→calm-reward→next-item ritual while preserving deterministic peel/input authority and leaving hand-anatomy repair to the parallel agent.

**Architecture:** Add a pure `RitualFlow` state model above existing peel lifecycle, a pure bounded `CupCrumpleModel`, and a presentation-only `CupCrumplePresentation`. `PeelLab` becomes the coordinator between existing `PeelController/LabelLifecycle`, new ritual state, pointer input, session progression, HUD, and presentation. Existing peel math, label geometry, tapered cup surface, pointer ownership/quarantine, Foley router, and authored-hand implementation remain separate authorities.

**Tech Stack:** Godot 4.7.1 stable, GDScript, existing `PointerAdapter`/`PointerState`, existing scene-smoke/unit runner, repository-local presentation/audio assets only.

## Global Constraints

- Godot **4.7.1 stable**; `project.godot` remains directly F5-runnable.
- No required third-party Godot plugin, Blender install, AI runtime, private secret, or external runtime asset download.
- No timer pressure, failure state, score-loss, combo-loss, or punishment for slow/re-grab play.
- Peel solver remains deterministic gameplay authority; ritual/cup deformation cannot rewrite peel progress.
- Numeric score is removed from primary HUD emphasis; soft progression unlocks sensory variants.
- Future `ice` contents are represented by profile data in this plan, but visible ice physics/rendering is not implemented in V5 Ritual Core.
- Do not modify `scripts/hands/hand_visual.gd` or hand-specific verifier/capture paths; those are reserved for the parallel hand-repair agent.
- Every new production behavior follows RED→GREEN, exact-head Godot Check, independent challenge, and merged-main verification. Visible cup/HUD changes require non-headless capture before integration.
- Comfort, anatomical naturalness, ASMR quality, and long-session relaxation remain owner experiential gates.

---

## File map

**Create**
- `scripts/ritual/ritual_flow.gd` — deterministic cross-phase state machine only.
- `scripts/cup/cup_crumple_model.gd` — deterministic bounded crumple accumulation and event values.
- `scripts/presentation/cup_crumple_presentation.gd` — presentation-only cup deformation from crumple state.
- `tests/test_ritual_flow.gd` — pure ritual-state tests.
- `tests/test_cup_crumple_model.gd` — pure crumple math tests.
- `tests/smoke_ritual_loop.gd` — real-scene detach→crumple→reward→next integration smoke.
- `tests/smoke_cup_crumple_presentation.gd` — real runtime deformation/reset/profile smoke.

**Modify**
- `scripts/session/session_model.gd` — migrate variants to carry cup/crumple/contents/reward profile fields while preserving current peel fields.
- `scripts/peel_lab.gd` — replace auto-next completion timing with RitualFlow coordination; route post-detach pointer into crumple; calm HUD/reward copy; keep peel authority unchanged.
- `scenes/peel_lab/peel_lab.tscn` — attach `CupCrumplePresentation` sibling.
- `tests/test_runner.gd` — register pure new tests.
- `.github/workflows/godot-check.yml` — add dedicated ritual/crumple smokes without removing existing gates.
- `README.md` — describe new post-peel ritual controls/reward semantics after verified integration.

---

### Task 1: Pure RitualFlow state machine

**Files:**
- Create: `scripts/ritual/ritual_flow.gd`
- Create: `tests/test_ritual_flow.gd`
- Modify: `tests/test_runner.gd`

**Interfaces:**
- Produces class `RitualFlow extends RefCounted`.
- Public phase constants/names: `PEEL`, `PEEL_SETTLE`, `CRUMPLE_READY`, `CRUMPLING`, `RITUAL_COMPLETE`.
- `reset() -> void`
- `on_label_detached() -> bool` returns true only on first accepted detach transition.
- `update(delta: float) -> void` advances only PEEL_SETTLE to CRUMPLE_READY after a fixed `settle_duration` (default `0.45` seconds); CRUMPLE_READY has no timer transition.
- `begin_crumple() -> bool`
- `mark_crumple_complete() -> bool`
- `request_next() -> bool` marks a one-shot next-item request from CRUMPLE_READY/CRUMPLING/RITUAL_COMPLETE.
- `consume_reward_event() -> bool` exact-once when ritual completion is first reached.
- `consume_next_request() -> bool` exact-once.
- `get_phase_name() -> String`

- [ ] **Step 1: Write failing unit tests**

Test exact contracts:
```gdscript
var flow := RitualFlow.new()
_assert(flow.get_phase_name() == "PEEL", "starts in PEEL")
_assert(flow.on_label_detached(), "first detach accepted")
_assert(not flow.on_label_detached(), "duplicate detach rejected")
flow.update(0.44)
_assert(flow.get_phase_name() == "PEEL_SETTLE", "settle does not finish early")
flow.update(0.02)
_assert(flow.get_phase_name() == "CRUMPLE_READY", "settle reaches ready")
for i in range(100):
    flow.update(0.1)
_assert(flow.get_phase_name() == "CRUMPLE_READY", "ready has no auto-next timer")
_assert(flow.begin_crumple(), "fresh crumple can start")
_assert(flow.mark_crumple_complete(), "first completion accepted")
_assert(flow.consume_reward_event(), "reward emitted once")
_assert(not flow.consume_reward_event(), "reward cannot duplicate")
_assert(flow.request_next(), "next request accepted")
_assert(flow.consume_next_request(), "next consumed once")
_assert(not flow.consume_next_request(), "next cannot duplicate")
flow.reset()
_assert(flow.get_phase_name() == "PEEL", "reset clears ritual state")
```

- [ ] **Step 2: Run canonical unit runner and verify RED**

Run through existing Godot Check/unit command used by `.github/workflows/godot-check.yml`.
Expected failure: missing `res://scripts/ritual/ritual_flow.gd` / RitualFlow contract, with existing unrelated tests remaining green.

- [ ] **Step 3: Implement minimal RitualFlow**

Use explicit integer phase enum; clamp non-finite/negative delta to 0; duplicate detach/completion/consume calls are idempotent. Do not import scene/input classes.

- [ ] **Step 4: Run full canonical Godot Check and verify GREEN**

Expected: import/parser, default F5 launch, all old units/smokes, plus RitualFlow units pass.

- [ ] **Step 5: Commit**

Commit message: `feat: add pressure-free ritual flow state model`.

---

### Task 2: Data-driven tactile cup profiles without score pressure

**Files:**
- Modify: `scripts/session/session_model.gd`
- Add tests to: `tests/test_session_model.gd`

**Interfaces:**
- Preserve `current_variant()`, `get_clean_peels()`, `get_unlocked_count()`, `advance_item()`, `restart_run()` so existing callers remain valid during migration.
- Add `record_ritual_complete() -> Dictionary` as the new progression authority.
- Keep `record_clean_peel(score)` temporarily as compatibility wrapper only if old tests still need it; it must delegate without requiring score for unlocks.
- Each variant dictionary must include:
```gdscript
"cup_shell": "paper",
"cup_dimensions": {"top_radius": ..., "bottom_radius": ..., "height": ...},
"crumple_profile": {"rigidity": ..., "dent_gain": ..., "max_compression": ...},
"contents_profile": {"type": "none"},
"reward_theme": "warm" # or variant-specific name
```
- Existing peel fields (`base_adhesion`, `release_increment`, `speed_gain`, `angle_gain`, `label_width`, `label_height`) remain unchanged unless a dedicated feel task later changes them.

- [ ] **Step 1: Add failing session-profile tests**

Require all three variants to expose the new fields, at least two variants to differ in crumple rigidity/max compression, all current V5 contents to be `none`, and unlock progression to depend on completed rituals rather than score magnitude.

- [ ] **Step 2: Run units and verify RED**

Expected: missing profile fields / `record_ritual_complete`.

- [ ] **Step 3: Implement profile migration**

Keep current unlock thresholds (2 and 5 completed rituals) for this slice so progression cadence changes minimally while reward framing changes.

- [ ] **Step 4: Run full suite and verify GREEN**

Existing tactile variant tests must continue proving distinct peel parameters/label sizes.

- [ ] **Step 5: Commit**

Commit message: `feat: model tactile cups as sensory ritual profiles`.

---

### Task 3: Deterministic CupCrumpleModel

**Files:**
- Create: `scripts/cup/cup_crumple_model.gd`
- Create: `tests/test_cup_crumple_model.gd`
- Modify: `tests/test_runner.gd`

**Interfaces:**
- Produces `CupCrumpleModel extends RefCounted`.
- Constructor/config dictionary accepts `rigidity`, `dent_gain`, `max_compression`.
- `reset() -> void`
- `begin_gesture(pointer_x: float, cup_center_x: float) -> void` records squeeze side (`-1` left, `+1` right), no progress yet.
- `apply_drag(relative_x: float) -> Dictionary` returns `{changed, delta, progress, event_strength}`.
  - Left-side gesture counts only positive/inward `relative_x`.
  - Right-side gesture counts only negative/inward `relative_x`.
  - Outward movement never reduces accumulated progress.
- `end_gesture() -> void`
- `get_progress() -> float` bounded `[0,1]`.
- `is_complete() -> bool` true at `progress >= 0.72`.
- `get_compression() -> float` bounded by profile `max_compression`.
- `consume_crumple_event() -> float` one-shot event strength after real inward change; stationary/outward drag emits zero.

- [ ] **Step 1: Write failing pure model tests**

Cover fresh begin requirement, left/right inward direction, no outward regression, non-finite input ignored, monotonic bounded progress, threshold completion, reset, and event exact-once consumption.

- [ ] **Step 2: Run units and verify RED**

Expected missing CupCrumpleModel only.

- [ ] **Step 3: Implement bounded deterministic model**

Use `effective = max(abs(inward_delta) - rigidity_deadzone, 0) * dent_gain`, accumulate progress, clamp 0..1. No random numbers and no physics nodes.

- [ ] **Step 4: Run full suite and verify GREEN**

- [ ] **Step 5: Commit**

Commit message: `feat: add deterministic cup crumple model`.

---

### Task 4: Presentation-only cup deformation

**Files:**
- Create: `scripts/presentation/cup_crumple_presentation.gd`
- Create: `tests/smoke_cup_crumple_presentation.gd`
- Modify: `scenes/peel_lab/peel_lab.tscn`
- Modify: `.github/workflows/godot-check.yml`

**Interfaces:**
- Scene sibling named `CupCrumplePresentation`.
- Script discovers sibling `Cup` at runtime but never owns ritual/peel state.
- `set_profile(profile: Dictionary) -> void`
- `set_crumple(progress: float, side: int, pulse: float) -> void`
- `reset_visual() -> void`
- The original Cup remains the semantic source for dimensions/material palette; presentation may replace its visible mesh with a generated deformed shell but must not change `PeelLabel` cup-surface authority.

- [ ] **Step 1: Add dedicated presentation RED smoke**

Require scene module exists; at progress 0 visual cup matches baseline dimensions within tolerance; at progress 0.6 width becomes visibly asymmetric/compressed while top/bottom radius stays positive; progress 1 remains finite and above minimum wall dimensions; reset restores baseline; switching session variant updates base dimensions/palette. Label cup-surface smoke must still pass because peel authority is unchanged.

- [ ] **Step 2: Run full CI and verify RED only at new crumple presentation gate**

- [ ] **Step 3: Implement lightweight deformed cup shell**

Generate a continuous `ArrayMesh` with 16 angular samples × 7 height rings. For each ring, apply bounded horizontal dent factor from `CupCrumpleModel` progress/side and mild vertical shortening. Rebuild only when crumple value changes meaningfully (epsilon `0.002`). Preserve material color from real Cup.

- [ ] **Step 4: Run full CI and verify GREEN**

Must include existing tapered label position/normal smoke, café presentation, forearm, session, pause/reset, and default-launch gates.

- [ ] **Step 5: Commit**

Commit message: `feat: render bounded paper cup crumple deformation`.

---

### Task 5: Integrate post-peel ritual into PeelLab and calm HUD/reward

**Files:**
- Modify: `scripts/peel_lab.gd`
- Create: `tests/smoke_ritual_loop.gd`
- Modify: `.github/workflows/godot-check.yml`

**Interfaces:**
- `PeelLab` owns one `RitualFlow` and one `CupCrumpleModel` for current item.
- Existing `LabelLifecycle` detach event calls `ritual.on_label_detached()` instead of scheduling `_reset_timer = 2.15`.
- Existing pointer is consumed once per frame. In PEEL phase it routes to existing `PeelController`; in CRUMPLE_READY/CRUMPLING it routes to crumple gesture handling.
- Transition from PEEL_SETTLE to CRUMPLE_READY calls `PointerAdapter.quarantine_current_press()` so a held peel press cannot inherit cup squeeze.
- `R` in CRUMPLE_READY/CRUMPLING/RITUAL_COMPLETE requests next immediately; ordinary R during PEEL still resets label; Shift+R restarts whole run.
- No automatic timer transitions from CRUMPLE_READY.
- HUD removes public `Score` and `Feels 3/3`; use `Rituals <n> • Tactile set <unlocked>/3` plus phase-specific invitation.
- Reward text examples: `CLEAN RELEASE`, then after crumple completion `SOFT FOLD • NEW CUP FEEL` when unlock occurs. No negative grade.

- [ ] **Step 1: Add real-scene RED ritual smoke**

Drive production helpers/state so test proves:
1. detach does not set a 2.15s next timer;
2. after >0.45s state is CRUMPLE_READY and remains there for 5 simulated seconds;
3. stale held input cannot create crumple progress before fresh release+press;
4. inward squeeze raises progress and presentation deformation;
5. reaching completion records progression/reward exactly once;
6. extra squeeze events cannot farm rituals;
7. R advances to next tactile profile;
8. Shift+R clears ritual/crumple/reward and returns to first profile.

- [ ] **Step 2: Run suite and verify RED against current auto-next implementation**

Expected failure includes old `_reset_timer=2.15` behavior and score-centric HUD.

- [ ] **Step 3: Implement integration minimally**

Refactor existing completion/reset branches rather than rewriting peel loop. Keep `ScoreModel` internal only if continuity data is still useful for descriptive feedback; do not display total score.

- [ ] **Step 4: Run full CI and verify GREEN**

All old input/quarantine/reset tests must remain green; update only expectations invalidated intentionally by no-auto-next behavior.

- [ ] **Step 5: Commit**

Commit message: `feat: connect peel completion to calm crumple ritual`.

---

### Task 6: Crumple sound event reuse and real visual audit

**Files:**
- Modify only if needed: `scripts/audio/peel_audio.gd` or a new `scripts/audio/crumple_audio.gd`
- Modify: `tests/smoke_ritual_loop.gd`
- Update: `README.md`
- Capture-only files must stay off the production PR.

**Interfaces:**
- Reuse repository-local paper flex Foley initially for crumple pulse events rather than adding an unlicensed asset.
- Crumple sound triggers only when `consume_crumple_event()` returns `>0`; stationary hold never repeats sound.
- Final peel release Foley remains unchanged.

- [ ] **Step 1: Add failing audio-event assertion**

Require no crumple audio event on stationary/outward drag; require one bounded event on real inward squeeze; repeated consume returns zero.

- [ ] **Step 2: Run and verify RED if no route exists**

- [ ] **Step 3: Implement minimal crumple Foley route**

Prefer a separate short one-shot player using existing `paper_flex.wav`, with pitch/volume derived from event strength. Do not alter the current adhesive/final-release router thresholds.

- [ ] **Step 4: Run full CI and exact-head default launch**

- [ ] **Step 5: Produce non-headless 1280×720 capture from exact production tree**

Inspect at least fresh PEEL, CRUMPLE_READY, mid-crumple, and RITUAL_COMPLETE frames. Reject candidate if deformation reads as rubber collapse, clips label/hand/café geometry grossly, or HUD becomes score-pressure heavy.

- [ ] **Step 6: Update README to actual verified controls**

Document: peel as before; after clean release, squeeze cup when desired; R skips/continues; no automatic next timer; Shift+R restarts; tactile variants unlock through completed rituals.

- [ ] **Step 7: Commit and hand exact head to CHALLENGER**

Commit message: `docs: describe V5 peel and crumple ritual`.

---

## Integration gate

Before any V5 Ritual Core PR can merge:
- exact feature head has fresh Godot Check success;
- default project launch gate passes;
- new RitualFlow + CupCrumple units pass;
- ritual + crumple presentation smokes pass;
- all existing tapered-label, café/paper-cup, forearm, pointer/session/pause/reset gates pass;
- non-headless visual frames are inspected and gross presentation regressions rejected;
- CHALLENGER independently attacks exact head, especially stale-input inheritance, duplicate reward, indefinite/automatic transitions, cup deformation bounds, and coexistence with hand-fix branch;
- immediately before merge, base/head drift is rechecked;
- merged `main` runs the complete Godot Check again.
