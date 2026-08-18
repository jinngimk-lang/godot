# Realtime Reference Rebuild v2 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the current full-screen Café reference playback and flat foreground rendering with one coherent, fully interactive real-time 3D peel experience across Café, Amber Bar, and Market Yuzu.

**Architecture:** Keep the existing gameplay model, label geometry, authored XR hand skeletons, and session variants as authority. Remove the full-screen reference playback from the runtime, then upgrade the existing presentation layers: physically shaded authored hands, shorter cinematic forearms, scene-specific product/label profiles, photographic backdrops plus matched lights, and a single unified HUD/input contract. Runtime screenshots from exact-head GitHub Actions are the final visual gate.

**Tech Stack:** Godot 4.7.1, GDScript, Godot StandardMaterial3D/ShaderMaterial, existing XR hand GLBs, GitHub Actions headless capture.

**Spec:** `docs/superpowers/specs/2026-08-18-realtime-reference-rebuild-v2-design.md`

## Global Constraints

- No full-screen target still/video playback during gameplay.
- No per-frame image decoding or full-screen texture swapping.
- LMB = grab/peel, RMB drag = rotate, R = inspect/return, T = reset, 1/2/3 = scene select, Esc = pause.
- Authored XR hand topology/skeleton remains the hand authority.
- Exact-head runtime screenshots are required; green tests alone are not acceptance.

---

### Task 1: Remove the reference playback from runtime

**Files:**
- Modify: `scenes/peel_lab/peel_lab.tscn`
- Modify: `tests/test_runner.gd`
- Delete: `scripts/presentation/reference_peel_playback.gd`
- Delete: `tests/test_reference_peel_playback.gd`

**Interfaces:**
- Consumes: existing scene `PeelLab` and `ReferenceBackdrop`.
- Produces: a scene with no `ReferencePeelPlayback` node and no full-screen reference texture path.

- [ ] **Step 1: Write the failing runtime-authority test**

Create `tests/test_realtime_render_authority.gd` with a test that loads `res://scenes/peel_lab/peel_lab.tscn`, instantiates it, and fails when `ReferencePeelPlayback` exists or when any child is a `CanvasLayer` named `ReferencePeelPlayback`.

```gdscript
extends RefCounted

func run() -> Array[String]:
    var failures: Array[String] = []
    var scene := load("res://scenes/peel_lab/peel_lab.tscn") as PackedScene
    if scene == null:
        return ["RED: peel_lab scene failed to load"]
    var root := scene.instantiate()
    if root.get_node_or_null("ReferencePeelPlayback") != null:
        failures.append("RED: full-screen reference playback is still present")
    root.free()
    return failures
```

- [ ] **Step 2: Wire the new test into `tests/test_runner.gd` and run CI**

Expected before implementation: FAIL because the node is still in the scene.

- [ ] **Step 3: Remove the runtime playback node/script and obsolete playback test/resources from the scene path**

The scene must continue to contain `ReferenceBackdrop`.

- [ ] **Step 4: Re-run deterministic tests**

Expected: new authority test PASS and no scene parse errors.

- [ ] **Step 5: Commit**

Commit message: `refactor: remove reference playback from runtime`

---

### Task 2: Restore physically shaded authored hands

**Files:**
- Modify: `scripts/presentation/cinematic_hand_presentation.gd`
- Modify: `scripts/hands/hand_visual.gd`
- Modify: `tests/test_cinematic_hand_presentation.gd`
- Modify: `tests/test_authored_hand_asset.gd`

**Interfaces:**
- Consumes: `HandVisual`, `AuthoredHand`, imported hand mesh surfaces, `Cup`/`Pinch Up`/`Pinch Tight` animations.
- Produces: `CinematicHandPresentation.get_visible_authored_hand_mesh_count()`, `get_polished_authored_mesh_count()`, and a bounded cinematic forearm span.

- [ ] **Step 1: Extend tests to reject unshaded hand material**

Load the presentation script source and require the skin shader to use normal spatial shading rather than `render_mode unshaded`. Add a runtime assertion that the polished authored mesh surfaces use either the skin or nail material and remain visible.

- [ ] **Step 2: Run deterministic tests**

Expected: FAIL because `SKIN_SHADER` and `NAIL_SHADER` currently declare `unshaded`.

- [ ] **Step 3: Replace the flat shaders with physically lit skin/nail shaders**

Use this contract:

```gdscript
const SKIN_SHADER := """shader_type spatial;
render_mode cull_back;
uniform vec4 skin_color : source_color = vec4(0.67,0.43,0.31,1.0);
uniform float roughness = 0.58;
uniform float specular = 0.34;
void fragment() {
    float pore = (fract(sin(dot(UV*vec2(611.0,487.0),vec2(12.9898,78.233)))*43758.5453)-0.5)*0.018;
    ALBEDO = clamp(skin_color.rgb + vec3(pore), vec3(0.0), vec3(1.0));
    ROUGHNESS = roughness;
    SPECULAR = specular;
}
"""
```

Use a slightly lighter, smoother nail shader without `unshaded`.

- [ ] **Step 4: Shorten and reshape the cinematic forearms**

Change the curve so each forearm exits its nearest lower corner instead of crossing most of the viewport. Preserve wrist alignment and use cloth material with roughness around `0.82–0.92`. The test must keep `get_cinematic_forearm_span()` below the current long-tube baseline.

- [ ] **Step 5: Reduce authored hand scale if runtime screenshots show oversized palms**

Keep one constant in `HandVisual` (`AUTHORED_PRESENTATION_SCALE`) and assert both hands use it. Tune only after exact-head runtime evidence.

- [ ] **Step 6: Re-run tests and capture**

Expected: deterministic hand tests PASS, no primitive shell visible, authored hand mesh visible and lit.

- [ ] **Step 7: Commit**

Commit message: `feat: restore realtime pbr hands`

---

### Task 3: Retune the three real-time product and label profiles

**Files:**
- Modify: `scripts/session/session_model.gd`
- Modify: `scripts/presentation/product_presentation.gd`
- Modify: `scripts/peel/label_print.gd`
- Modify: `tests/test_product_presentation.gd`
- Modify: `tests/test_reference_profiles.gd`
- Modify: `tests/test_label_print_contract.gd`

**Interfaces:**
- Consumes: `SessionModel.current_variant()` dictionaries.
- Produces: per-scene `container_profile`, label dimensions, print copy and materials used by the existing label/product presenters.

- [ ] **Step 1: Add failing profile assertions**

Require:

```gdscript
# Café: prominent portrait-ish receipt patch
assert(cafe.label_width >= 0.72)
assert(cafe.label_height >= 0.56)
# Bar: target uses a large damaged vertical paper label
assert(bar.label_width >= 0.74)
assert(bar.label_height >= 0.62)
# Market: target uses a broad white/green label
assert(market.label_width >= 0.84)
assert(market.label_height >= 0.58)
```

Also assert amber and clear bottle kinds remain distinct.

- [ ] **Step 2: Run tests**

Expected: FAIL for the current Bar/Market label heights.

- [ ] **Step 3: Retune session profiles**

Recommended starting values:

```gdscript
# Café
"label_width": 0.76, "label_height": 0.60, "label_y": 0.16
# Bar
"label_width": 0.80, "label_height": 0.66, "label_y": -0.02
# Market
"label_width": 0.92, "label_height": 0.62, "label_y": -0.04
```

Keep Bar fibrous and Market coated/clean.

- [ ] **Step 4: Upgrade bottle material response**

Keep dense lathe geometry but reduce the flat tinted-alpha look. Use a shaded glass outer shell, visible fresnel shell, inner shell and liquid. Keep transparent surfaces from casting opaque shadows. Add amber highlight warmth and market glass neutral/cool highlights.

- [ ] **Step 5: Retune print copy**

Café must read `COCOA CLOUD`; Bar must visibly read `MOUNTAIN RIDGE` / `PALE ALE`; Market must visibly read `YUZU` / `SPARKLING`. Keep barcode/detail copy subordinate.

- [ ] **Step 6: Run profile/product/label tests**

Expected: PASS.

- [ ] **Step 7: Commit**

Commit message: `feat: retune realtime products and labels`

---

### Task 4: Make the input contract match the supplied interaction design

**Files:**
- Modify: `scripts/input/pointer_adapter.gd`
- Modify: `scripts/inspection/inspection_controller.gd`
- Modify: `scripts/peel_lab.gd`
- Modify: `project.godot`
- Modify: `tests/test_pointer_adapter.gd`
- Modify: `tests/test_inspection_controller.gd`
- Modify: `tests/smoke_pause_input_isolation.gd`
- Modify: `tests/smoke_reset_input_isolation.gd`

**Interfaces:**
- Produces controls: LMB peel; RMB drag product rotate; R inspect toggle; T reset; 1/2/3 select scene; Esc pause.

- [ ] **Step 1: Add failing input mapping tests**

Tests must require reset to use `T` and inspection toggle to use `R` while keeping RMB as pointer/rotation input.

- [ ] **Step 2: Run tests**

Expected: FAIL because current UI/runtime still describe `R Reset` and RMB inspect.

- [ ] **Step 3: Introduce explicit action names in `project.godot`**

Use actions `inspect_toggle`, `reset_item`, `scene_1`, `scene_2`, `scene_3`, and preserve existing pause semantics.

- [ ] **Step 4: Update `PeelLab` event routing**

RMB drag changes inspection yaw continuously; `R` toggles an inspect presentation state/return; `T` calls reset. Scene number keys call `_select_showcase(index)`.

- [ ] **Step 5: Verify paused/reset transients remain isolated**

Run pause/reset smokes and ensure no peel progress changes from stale pointer input.

- [ ] **Step 6: Commit**

Commit message: `feat: align controls with peel calm reference`

---

### Task 5: Replace the debug HUD with the unified Peel Calm HUD

**Files:**
- Modify: `scripts/presentation/hud_chrome_presentation.gd`
- Modify: `scripts/presentation/guided_journey_presentation.gd`
- Modify: `tests/test_hud_chrome_presentation.gd`
- Modify: `tests/test_guided_journey_presentation.gd`

**Interfaces:**
- Consumes: current variant name, peel progress, residue, integrity, active scene index.
- Produces named HUD nodes `ObjectivePanel`, `ProgressPanel`, `ControlsPanel`, `HowToPanel`, `JourneyRail`.

- [ ] **Step 1: Add failing HUD structure tests**

Require the five named nodes above and require visible copy for `GRAB EDGE`, `PEEL GENTLY`, `INSPECT`, and `CLEAN PEEL`.

- [ ] **Step 2: Run tests**

Expected: FAIL because the current HUD only creates a small top-left strip and a bottom three-button rail.

- [ ] **Step 3: Build reusable glass-panel helpers**

Add helper methods that create translucent dark `Panel`/`Label` combinations with readable scaling at 1280x720 and 1920x1080.

- [ ] **Step 4: Build the reference hierarchy**

- upper-left product/progress;
- left objective card;
- top-right concise controls;
- right how-to-play steps;
- bottom scene rail.

Keep the center contact zone free of UI.

- [ ] **Step 5: Update all control copy**

Use the new LMB/RMB/R/T/1/2/3/Esc mapping only.

- [ ] **Step 6: Run HUD tests and scene smoke**

Expected: PASS and no duplicate legacy chrome.

- [ ] **Step 7: Commit**

Commit message: `feat: unify peel calm hud`

---

### Task 6: Recompose hands, products, lights, and backdrops per scene

**Files:**
- Modify: `scripts/presentation/reference_composition.gd`
- Modify: `scripts/presentation/reference_lighting.gd`
- Modify: `scripts/presentation/hand_choreography_presentation.gd`
- Modify: `scripts/presentation/reference_backdrop.gd`
- Modify: `tests/smoke_reference_scene.gd`
- Modify: `tests/smoke_forearm_presentation.gd`

**Interfaces:**
- Consumes: product kind + venue id.
- Produces: stable scene-specific camera FOV, hand resting positions, and lighting.

- [ ] **Step 1: Extend smoke contracts**

Require no visible blockout venue geometry, no black viewport wedges, two authored hands in the player view, and scene-specific FOVs.

- [ ] **Step 2: Tune camera framing**

Start with Café `38–40°`, Amber `41–44°`, Market `42–45°`; bottles should no longer look tiny in a 48° view.

- [ ] **Step 3: Tune support-hand choreography**

Support hand should contact the cup/bottle body/shoulder. Peel hand starts near the label edge. Both hands should remain on opposite sides of the product until peel movement crosses the center.

- [ ] **Step 4: Tune light rigs**

Café warm neutral skin key, Bar warm amber key/rim, Market soft cool fill plus neutral skin key. Keep skin from becoming orange/red under Bar lighting.

- [ ] **Step 5: Run smokes and capture**

Expected: no black wedges, products occupy roughly half the frame height, hands visibly contact the product/label.

- [ ] **Step 6: Commit**

Commit message: `feat: recompose realtime reference scenes`

---

### Task 7: Expand exact-head capture to all three mid-peel states

**Files:**
- Modify: `tests/capture_reference_frames.gd`
- Modify: `.github/workflows/godot-check.yml` only if artifact coverage needs additional filenames.

**Interfaces:**
- Produces exact-head PNG evidence: `cafe.png`, `cafe_peel38.png`, `bar.png`, `bar_peel48.png`, `market.png`, `market_peel45.png`.

- [ ] **Step 1: Add a capture assertion that `ReferencePeelPlayback` is absent**

Fail the capture run if the scene contains the obsolete playback node.

- [ ] **Step 2: Preserve staged real-time hand/flap alignment**

Continue using `HandVisual.get_pinch_world_position()` and compare it to the rendered flap tip with the existing sub-millimeter tolerance.

- [ ] **Step 3: Capture all base and mid-peel states**

No reference overlay is allowed to hide the 3D result.

- [ ] **Step 4: Run GitHub Actions and download the exact-head artifact**

Expected: workflow PASS and six required evidence frames present.

- [ ] **Step 5: Commit**

Commit message: `test: expand realtime visual evidence`

---

### Task 8: Visual convergence loop and final merge gate

**Files:**
- Modify only the presentation/profile files implicated by exact-head evidence.
- Add checkpoint: `docs/superpowers/checkpoints/2026-08-18-realtime-reference-rebuild-v2.md`

**Interfaces:**
- Consumes: exact-head runtime PNGs and the six owner-supplied target images.
- Produces: mergeable PR only after runtime + visual acceptance.

- [ ] **Step 1: Compare each runtime image against its supplied target concept**

Score the high-value differences in this order: hand anatomy/scale, hand-label contact, product silhouette/material, label scale/curl, forearm exit, scene lighting, HUD hierarchy.

- [ ] **Step 2: Pick the single largest verified gap**

Change only the files responsible for that gap.

- [ ] **Step 3: Re-run exact-head CI and inspect new screenshots**

Reject regressions even if tests remain green.

- [ ] **Step 4: Repeat while a clear high-value visual gap remains**

Do not stop due to an arbitrary iteration count.

- [ ] **Step 5: Record final evidence in the checkpoint**

Include commit SHA, successful workflow run, artifact id, and remaining known limitations if any.

- [ ] **Step 6: Open/complete PR and merge only after the exact-head evidence gate passes**

Commit message for final evidence: `docs: record realtime rebuild acceptance`
