# Peel Calm — Tactile Upgrade V2 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Upgrade the verified V1 peel prototype so a completed label truly detaches into the right hand, the hands read as semi-realistic clean anatomy, the print stays on the deforming label, and repository-local Foley replaces the synthetic placeholder sound.

**Architecture:** Keep `PeelModel`, pointer abstraction, scoring authority and the proven controller semantics as the deterministic gameplay core. Add a small presentation lifecycle around completion, split label presentation into attached/peeling and held behavior, expose a rig-ready hand contract, and route physical peel events into sample-based Foley. Presentation never grants peel progress.

**Tech Stack:** Godot 4.7.1 stable, GDScript, built-in `ImmediateMesh`/`SubViewport`/`ViewportTexture`/`AudioStreamPlayer`, repository-local WAV assets, GitHub Actions with the official Godot 4.7.1 Linux x86_64 release.

## Global Constraints

- Canonical runnable source is `jinngimk-lang/godot`.
- Engine baseline is exactly Godot 4.7.1 stable.
- First platform remains PC mouse; touch-ready input contracts remain green.
- Selected art direction is semi-realistic, clean, calming hands; recognizable anatomy without photoreal skin pores.
- No branded Starbucks/Luckin assets or trade dress.
- No required Blender, external AI model service, login, private environment variable, or third-party Godot addon.
- External audio/model assets may be committed only with verified redistribution license metadata.
- Gameplay authority remains `PointerAdapter -> PeelController -> PeelModel`; visual/audio systems never decide whether peel progress succeeds.
- Behavioral changes follow RED -> GREEN and exact failing/passing heads are recorded.
- CI green does not prove tactile or aesthetic quality; those remain owner-playtest evidence.

---

## File Map

- `scripts/peel/label_lifecycle.gd` — pure presentation phase state (`ATTACHED`, `PEELING`, `DETACHING`, `HELD`, `RESETTING`) and one-shot detach transition.
- `tests/test_label_lifecycle.gd` — proves completion detaches once and held motion does not change solver progress.
- `scripts/peel/label_visual.gd` — upgrades V1 strip geometry to bounded-stretch peel plus cup-independent held geometry.
- `scripts/peel/label_print.gd` — builds the order label `SubViewport` and exposes its `ViewportTexture`.
- `tests/test_label_visual_v2.gd` — pure geometry/contract checks for no cup anchor after detach and bounded segment spacing.
- `scripts/hands/hand_visual.gd` — replaces the box/two-finger proxy with a five-finger articulated procedural hand behind a rig-ready interface.
- `tests/test_hand_visual.gd` — verifies five fingers, thumb/index pinch nodes, and public grip/pinch contract.
- `scripts/audio/peel_foley_router.gd` — pure event selection/rate-limit logic for idle/slow/fast/micro/final release.
- `scripts/audio/peel_audio.gd` — sample-based runtime player consuming router events.
- `assets/audio/peel/*` — verified redistributable short WAV clips.
- `assets/audio/ATTRIBUTION.md` — source/license/modification ledger.
- `tests/test_peel_foley_router.gd` — proves no active peel event while idle and final release fires once.
- `scripts/peel_lab.gd` — scene integration: lifecycle, dynamic print texture, detach/held behavior, new hand contract, sample-based Foley.
- `tests/smoke_scene.gd` — upgraded scene/resource smoke.
- `tests/test_runner.gd` — canonical suite list.
- `README.md` — updated V2 controls/status and exact local-run instructions.

---

### Task 1: RED — completion must become detached/held

**Files:**
- Create: `tests/test_label_lifecycle.gd`
- Modify: `tests/test_runner.gd`

**Interfaces:**
- Consumes: existing `PeelController.get_progress() -> float`, `PeelController.is_complete() -> bool`.
- Produces expected contract for Task 2:
  - `LabelLifecycle.new(detach_duration: float = 0.16)`
  - `reset() -> void`
  - `update(progress: float, completed_now: bool, delta: float) -> void`
  - `get_phase_name() -> String`
  - `is_detached() -> bool`
  - `consume_detach_event() -> bool`

- [ ] **Step 1: Add a failing lifecycle suite** that loads `res://scripts/peel/label_lifecycle.gd` and fails with `RED: missing label detach lifecycle contract` when absent. Once present, prove: progress 0 is `ATTACHED`; progress in `(0,1)` is `PEELING`; completion enters `DETACHING`; advancing past configured duration reaches `HELD`; `is_detached()` is true only after completion; `consume_detach_event()` returns true exactly once; later updates cannot return to a cup-anchored phase until reset.
- [ ] **Step 2: Wire the suite into `tests/test_runner.gd`.**
- [ ] **Step 3: Push RED and require Godot 4.7.1 CI to fail for the intended missing production contract, recording exact SHA/run.**

---

### Task 2: GREEN — deterministic presentation lifecycle

**Files:**
- Create: `scripts/peel/label_lifecycle.gd`
- Test: `tests/test_label_lifecycle.gd`

**Interfaces:**
- Produces exactly the Task 1 contract.
- Phase enum names are stable strings: `ATTACHED`, `PEELING`, `DETACHING`, `HELD`, `RESETTING`.

- [ ] **Step 1: Implement the minimal `RefCounted` lifecycle** with clamped finite delta, one-shot detach event, and no visual/node dependencies.
- [ ] **Step 2: Run the canonical deterministic suite in Godot 4.7.1 headless and require GREEN.**
- [ ] **Step 3: Commit the passing lifecycle separately.**

---

### Task 3: RED/GREEN — label can no longer become a rubber ribbon

**Files:**
- Create: `tests/test_label_visual_v2.gd`
- Modify: `tests/test_runner.gd`
- Modify: `scripts/peel/label_visual.gd`

**Interfaces:**
- Extend `LabelVisual` with:
  - `set_phase(phase_name: String) -> void`
  - `set_peel(progress: float, grip_local: Vector3) -> void`
  - `is_detached() -> bool`
  - `get_sample_points(progress: float, grip_local: Vector3) -> PackedVector3Array` for deterministic geometry testing.
- In `HELD`, every sample is generated in grip/hand space and none may call or depend on `CupSurface.attached_point()`.

- [ ] **Step 1: Add RED geometry tests** proving that after `set_phase("HELD")`: `is_detached()` is true, moving the grip translates the label, and the returned point set does not retain the original cup-front point. During normal peel pulls, adjacent center-sample spacing may not exceed `1.8x` the nominal segment spacing.
- [ ] **Step 2: Refactor point generation into testable sample generation while preserving V1 cylindrical attached mapping.**
- [ ] **Step 3: Add a short `DETACHING` blend that releases the cup-side anchor over 120–220 ms, then rebuilds the whole strip relative to the grip.**
- [ ] **Step 4: Run all deterministic suites and scene smoke; commit only after GREEN.**

---

### Task 4: Label print must live on the deforming label

**Files:**
- Create: `scripts/peel/label_print.gd`
- Modify: `scripts/peel/label_visual.gd`
- Modify: `scripts/peel_lab.gd`
- Create/extend test: `tests/test_label_visual_v2.gd`

**Interfaces:**
- `LabelPrint.new()` is a `SubViewport`-owning helper/node exposing:
  - `set_order(order_code: String, drink_name: String) -> void`
  - `get_texture() -> Texture2D`
- `LabelVisual.set_print_texture(texture: Texture2D) -> void` assigns `StandardMaterial3D.albedo_texture`.

- [ ] **Step 1: Add a failing contract check** that `LabelVisual` accepts a print texture and the scene no longer requires an independent world-space `Label3D` named `OrderPrint`.
- [ ] **Step 2: Build a 512x256 transparent/cream `SubViewport` with order code, drink name and simple barcode-like marks.**
- [ ] **Step 3: Feed its `ViewportTexture` to the label material so UVs carry text through peel/detach.**
- [ ] **Step 4: Delete the temporary free-standing print node from scene construction.**
- [ ] **Step 5: Run import, unit and scene smoke GREEN; commit.**

---

### Task 5: Semi-realistic procedural hand contract

**Files:**
- Create: `tests/test_hand_visual.gd`
- Modify: `tests/test_runner.gd`
- Modify: `scripts/hands/hand_visual.gd`
- Modify: `scripts/peel_lab.gd`

**Interfaces:**
- Preserve `setup(dynamic_hand: bool)` for compatibility.
- Add:
  - `set_grip_target(target: Vector3) -> void`
  - `set_pinch_amount(amount: float) -> void`
  - `snap_to(target: Vector3) -> void`
  - `tick(delta: float) -> void`
  - `get_finger_count() -> int`
- Required named child anchors: `ThumbTip`, `IndexTip`, `PinchPoint`.

- [ ] **Step 1: Add RED tests** that current hand fails because it does not expose five fingers/pinch anchors and the new public interface.
- [ ] **Step 2: Replace the box palm with rounded palm/wrist volumes and create five multi-segment fingers using capsules/spheres with correct relative lengths; thumb is opposable.**
- [ ] **Step 3: Add small nail surfaces to thumb/index and restrained skin material.**
- [ ] **Step 4: Drive thumb/index toward a controllable pinch while middle/ring/little fingers retain relaxed curl. Right hand follows `set_grip_target`; left hand stays in a cup-holding pose.**
- [ ] **Step 5: Keep gameplay dependent only on grip/pinch methods so a future GLB/Skeleton3D hand can replace this node without controller changes.**
- [ ] **Step 6: Run deterministic tests and scene smoke GREEN; commit.**

---

### Task 6: RED/GREEN — sample-based Foley event router

**Files:**
- Create: `scripts/audio/peel_foley_router.gd`
- Create: `tests/test_peel_foley_router.gd`
- Modify: `tests/test_runner.gd`

**Interfaces:**
- `PeelFoleyRouter.new()`
- `reset() -> void`
- `update(active: bool, speed: float, tension: float, released: float, detached_now: bool, delta: float) -> Array[String]`
- Stable event names: `slow`, `fast`, `paper_flex`, `micro_release`, `final_release`.

- [ ] **Step 1: Add RED tests** proving idle returns no peel loop event, low active speed selects `slow`, high active speed can select `fast`, release increments are rate-limited `micro_release`, and `final_release` can appear exactly once until reset.
- [ ] **Step 2: Implement the pure router with finite/clamped inputs and deterministic cooldowns.**
- [ ] **Step 3: Run canonical tests GREEN and commit before touching audio playback.**

---

### Task 7: Research, verify and commit redistributable Foley

**Files:**
- Create: `assets/audio/ATTRIBUTION.md`
- Create binary WAV files under `assets/audio/peel/`

**Requirements:**
- Prefer CC0/public-domain recordings from the original host/source page.
- For each committed file record: source title, source page, original author/uploader, license, downloaded date, local filename, and any trimming/normalization modification.
- Reject any file whose redistribution license cannot be independently confirmed.

- [ ] **Step 1: Research original source/license pages for paper, tape/adhesive peel and release recordings; do not rely on mirror descriptions.**
- [ ] **Step 2: Download only the minimum set needed for `slow`, `fast`, `paper_flex`, `micro_release`, `final_release`.**
- [ ] **Step 3: Normalize/trim locally only if needed; keep short PCM WAV files suitable for Godot.**
- [ ] **Step 4: Add the exact license ledger and verify Git/Godot import sees every referenced asset.**

---

### Task 8: Replace synthetic generator with sample-based Foley playback

**Files:**
- Modify: `scripts/audio/peel_audio.gd`
- Modify: `scripts/peel_lab.gd`
- Test: `tests/test_peel_foley_router.gd`

**Interfaces:**
- `PeelAudio.set_feedback(active: bool, speed: float, tension: float, released: float, detached_now: bool, delta: float) -> void`
- `PeelAudio.reset_feedback() -> void`
- Playback consumes `PeelFoleyRouter` events and repository-local WAV streams.

- [ ] **Step 1: Remove `AudioStreamGenerator` as the normal presentation path.**
- [ ] **Step 2: Create separate low-volume players for slow/fast loop texture and one-shots; vary pitch/volume slightly per one-shot to reduce repetition.**
- [ ] **Step 3: Crossfade slow/fast according to speed; drive gain gently from tension; trigger micro/final release only from router events.**
- [ ] **Step 4: Ensure idle is quiet and reset stops stale loops.**
- [ ] **Step 5: Run import, deterministic router tests and scene smoke GREEN; commit.**

---

### Task 9: Scene integration and owner-feedback regression

**Files:**
- Modify: `scripts/peel_lab.gd`
- Modify: `tests/smoke_scene.gd`
- Modify: `README.md`

**Integration flow:**
- Each frame: pointer -> controller/model -> lifecycle update -> label phase/geometry -> hand grip/pinch -> Foley events -> HUD.
- On completion: lifecycle enters `DETACHING`, final-release audio fires once, label fully enters `HELD`, score emits once, held label remains in hand during reward hold, then reset.

- [ ] **Step 1: Wire `LabelLifecycle` into the main scene and remove the old assumption that controller `COMPLETE` can still stretch from the cup.**
- [ ] **Step 2: Drive right-hand pinch amount from interaction state and ensure held label follows the pinch point after 100%.**
- [ ] **Step 3: Reduce debug marker prominence, move camera slightly closer, soften background/light balance without adding new content systems.**
- [ ] **Step 4: Strengthen scene smoke to require label lifecycle, five-finger hand nodes, label print texture and audio sample resources.**
- [ ] **Step 5: Update README with V2 behavior and keep clone/ZIP -> `project.godot` -> F5 instructions exact.**
- [ ] **Step 6: Run full Godot 4.7.1 import + all deterministic tests + scene smoke GREEN.**

---

### Task 10: Exact-head PR, review and merged-main proof

**Files:**
- No new runtime files unless review finds a defect.

- [ ] **Step 1: Inspect the complete `main...feat/tactile-upgrade-v2` diff for hard-coded local paths, missing binary resources, unlicensed assets, third-party addon/runtime dependencies, branded assets and stale `OrderPrint` world text.**
- [ ] **Step 2: Record exact V2 RED SHA/run and exact final GREEN SHA/run in the PR.**
- [ ] **Step 3: Require both push and pull-request Godot 4.7.1 CI success on the exact reviewed head.**
- [ ] **Step 4: Merge using `expected_head_sha`; abort if the head moves.**
- [ ] **Step 5: Fetch merged `main` SHA and require fresh main push CI success for checksum/install, import/parse guard, all deterministic tests and scene smoke.**
- [ ] **Step 6: Report experiential items honestly as still UNVERIFIED until the owner downloads/pulls V2 and performs the next local peel playtest.**

## Acceptance Evidence Ledger

V2 is not called complete until the PR/mainline evidence contains:

- exact RED SHA and intended failing reason for detach lifecycle;
- exact passing head SHA after all V2 changes;
- verified source/license metadata for every committed external audio file;
- push + PR CI success on the exact reviewed head;
- protected exact-head merge;
- merged `main` SHA + green post-merge Godot 4.7.1 verification;
- explicit statement that visual naturalness, Foley pleasantness and resistance feel remain experiential until local owner playtest.