# Peel Calm Reference-Fidelity Completion Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Finish the object-only Godot runtime so its live 1280x720 frame, paper peel response, five product scenes, and completion flow converge on the owner-approved reference images.

**Architecture:** Preserve `PointerAdapter -> PeelController -> PeelModel` as gameplay authority and keep the object-only `mouse -> projected grip -> label` presentation path. Improve the runtime through four independently testable presentation units: HUD/composition, venue/product rendering, layered paper/residue, and post-release lifecycle. Every visible change is accepted only after exact-state live captures at attached, mid-peel, and fully released states.

**Tech Stack:** Godot 4.7.1, GDScript, procedural `ArrayMesh`/`PrimitiveMesh`, `StandardMaterial3D`, Godot spatial shaders, deterministic scene smoke tests, runtime PNG capture.

**Spec:** `docs/superpowers/specs/2026-08-18-realtime-reference-rebuild-v2-design.md` plus `.agents/PROJECT_NORTH_STAR.md`

## Global Constraints

- Gameplay contains no visible hand or arm models and no full-screen still/video overlay.
- The five scene order remains Coffee Shop, Jar, Tin Can, Supermarket, Can.
- Controls remain LMB peel, RMB rotate, Wheel zoom, R reset, 1-5 scene select, Esc pause.
- Static pointer hold never advances peel; new outward pointer work remains required.
- Substrate feel ordering remains Jar > Tin / Coffee > Yuzu > Can unless fresh runtime evidence proves a change is necessary.
- Real-time product, label, residue, lighting, foreground surface, cursor, and interaction remain authoritative.
- Target resolution is the configured 1280x720 viewport; HUD must scale without covering the label contact zone.
- No external runtime download, private service, third-party Godot plugin, trademarked café identity, or hidden local dependency.
- Visual acceptance requires direct target/runtime comparison at Macro, Meso, then Micro scale; passing tests alone is insufficient.

---

### Task 1: Establish the exact live-frame baseline and measurable target

**Files:**
- Inspect: `tests/capture_reference_frames.gd`
- Create: `docs/superpowers/checkpoints/2026-08-20-reference-fidelity-baseline.md`
- Output: `artifacts/reference_frames/*.png`

**Interfaces:**
- Consumes: `PeelLab.debug_select_variant(index: int)` and the existing attached/mid/done capture staging.
- Produces: no runtime API; this task records the unmodified production baseline.

- [ ] **Step 1: Verify project and capture preconditions**

```gdscript
assert(ProjectSettings.get_setting("display/window/size/viewport_width") == 1280)
assert(ProjectSettings.get_setting("display/window/size/viewport_height") == 720)
assert(CASES.size() == 5)
```

- [ ] **Step 2: Run the focused capture script without changing production code**

Run: `Godot_v4.7.1-stable_win64.exe --path . --rendering-method gl_compatibility --script res://tests/capture_reference_frames.gd`

Expected: the existing script captures five attached, five mid-peel, and five fully released frames with no runtime error.

- [ ] **Step 3: Capture and inspect all 15 baseline frames**

Run the capture script again. Record for each product: hero-object bounding box, label bounding box, cursor-to-edge distance, dominant light direction, HUD bounds, and the largest Macro/Meso/Micro mismatch against the approved images.

- [ ] **Step 4: Save the baseline checkpoint**

The checkpoint must name the exact Git head, commands run, all 15 inspected files, ranked visible defects, and the single first implementation target. Do not claim visual completion.

---

### Task 2: Match the owner-approved HUD composition and visual hierarchy

**Files:**
- Modify: `scripts/presentation/hud_chrome_presentation.gd`
- Modify: `scripts/presentation/guided_journey_presentation.gd`
- Modify: `tests/test_hud_chrome_presentation.gd`
- Modify: `tests/test_guided_journey_presentation.gd`

**Interfaces:**
- Consumes: scene name, controller progress, pause state, and `scene_requested(index: int)`.
- Produces: named controls `ProgressPanel`, `ControlsPanel`, `HowToPanel`, `JourneyRail`, `Scene0` through `Scene4`.

- [ ] **Step 1: Write RED layout assertions for the 1280x720 reference frame**

```gdscript
_assert_rect(progress_panel, Rect2(52, 36, 262, 96))
_assert_rect(controls_panel, Rect2(52, 205, 170, 318))
_assert_rect(how_to_panel, Rect2(970, 44, 278, 524))
assert(rail.position.y >= 650.0)
assert(rail.size.x >= 1120.0)
assert(progress_panel.mouse_filter == Control.MOUSE_FILTER_IGNORE)
```

Use proportional tolerances of 6 px so the test catches macro drift without overfitting font rasterization.

- [ ] **Step 2: Run the two focused suites and verify RED**

Run: `Godot_v4.7.1-stable_win64.exe --headless --path . --script res://tests/test_runner.gd`

Expected: HUD layout contracts fail while unrelated mechanics remain green.

- [ ] **Step 3: Rebuild the chrome as compact translucent groups**

Use one font hierarchy, warm-gold accent `Color(1.0, 0.66, 0.08)`, 9-12 px radii, 1 px low-alpha borders, and dark translucent backgrounds. Add small keycap/mouse-glyph controls without adding texture dependencies. Keep the center interval from x=260 to x=950 clear for direct peeling.

- [ ] **Step 4: Make the tutorial a four-row panel**

Each row contains a gold numbered circle, bold title, and compact two-line instruction. The panel must never intercept mouse input and must remain visually subordinate to the hero object.

- [ ] **Step 5: Make the bottom rail match the five equal reference tabs**

Keep all tabs visible during peel and inspection. The active tab uses the gold border/fill; inactive tabs retain readable white text and low-contrast borders.

- [ ] **Step 6: Run tests and capture Coffee attached/mid frames**

Accept only if the hero object remains unobstructed and the HUD reads like one coherent 16:9 interface rather than three debug panels.

---

### Task 3: Strengthen five-scene identity at Macro scale

**Files:**
- Modify: `scripts/presentation/reference_backdrop.gd`
- Modify: `scripts/presentation/reference_lighting.gd`
- Modify: `scripts/presentation/reference_composition.gd`
- Modify: `scripts/presentation/table_surface_presentation.gd`
- Modify: `scripts/presentation/venue_presentation.gd`
- Modify: `tests/test_venue_presentation.gd`
- Modify: `tests/test_table_surface_material.gd`

**Interfaces:**
- Consumes: current variant `venue`, `container_profile`, and `camera_profile` dictionaries.
- Produces: five visibly distinct instantiated venue/background/foreground/light combinations; no test-only runtime getter.

- [ ] **Step 1: Add RED assertions that every venue has a unique identity tuple**

```gdscript
for profile in session.get_variants():
	venue.apply_profile(profile)
	var backdrop := venue.get_node("Backdrop") as MeshInstance3D
	var table := venue.get_node("TableSurface") as MeshInstance3D
	assert(backdrop.visible and table.visible)
	assert(backdrop.material_override != null)
	assert(table.material_override != null)
```

Pair this real-node test with the five-column HUD-hidden thumbnail review; do not introduce an exact-string identity tuple merely for testing.

- [ ] **Step 2: Run venue and table tests to verify RED**

Expected: any repeated backdrop/foreground/light tuple is reported.

- [ ] **Step 3: Author five deterministic environment treatments**

Coffee uses warm café bokeh and amber wood; Jar uses kitchen/pantry forms and a stone/wood prep surface; Tin uses cooler grocery shelving and brushed counter; Supermarket uses bright refrigerated commercial depth; Can uses a darker beverage-counter/display treatment. Background plates may be reused only with enough crop, foreground geometry, practical lights, and palette separation that HUD-hidden thumbnails identify the venue.

- [ ] **Step 4: Calibrate hero composition per product**

Constrain hero height to 56-68% of viewport, center x to 48-52%, contact point to the lower third, and label edge to the clear center interaction corridor. Store per-product camera/FOV in the existing profile dictionaries.

- [ ] **Step 5: Run tests and build a five-column HUD-hidden contact sheet**

Downsample to approximately 96 px per frame. Reject if any two locations read as the same room with a swapped object.

---

### Task 4: Upgrade all hero products from primitives to believable objects

**Files:**
- Modify: `scripts/presentation/product_presentation.gd`
- Modify: `scripts/presentation/hero_product_detail_presentation.gd`
- Modify: `scripts/presentation/cafe_lid_molded_presentation.gd`
- Modify: `tests/test_product_presentation.gd`
- Modify: `tests/test_hero_product_detail_presentation.gd`
- Modify: `tests/test_cafe_hero_product.gd`

**Interfaces:**
- Consumes: five `container_profile` dictionaries.
- Produces: stable semantic product nodes with real meshes, distinct silhouette parts, and distinct visible material layers.

- [ ] **Step 1: Add RED semantic and geometry assertions**

```gdscript
var body := product.get_node(expected_body_name) as MeshInstance3D
assert(body.mesh != null)
assert(body.get_aabb().size.y > body.get_aabb().size.x)
assert(product.get_child_count() >= expected_minimum_visible_parts)
assert(body.material_override != null)
```

Coffee must declare body/seam/base/lip/lid grooves; Jar glass/sauce/lid/base thickness; Tin body/top/bottom rolled rims/seam; Bottle glass/liquid/neck/mouth/cap; Can body/shoulder/top/bottom rims/tab.

- [ ] **Step 2: Run product suites and verify RED only on missing realism contracts**

- [ ] **Step 3: Improve silhouette before shader polish**

Use lathed profiles or layered rings to reproduce tapered cup walls, glass shoulder/neck transitions, tin rim overhangs, and soda-can shoulder/base transitions. Keep geometry deterministic and built only on scene change.

- [ ] **Step 4: Add material separation and contact grounding**

Paper uses high roughness with subtle warm variation; glass uses wall/highlight separation and an inner liquid volume; metal uses controlled metallic response with reflection breakup; every product gets a soft contact shadow aligned to the foreground surface.

- [ ] **Step 5: Capture all five attached frames and reject lower-frequency regressions**

Only proceed to label Micro detail after the vessel silhouette, scale, and product family are immediately readable.

---

### Task 5: Make the label read as layered, tearing paper with separate adhesive

**Files:**
- Modify: `scripts/presentation/corner_peel_presentation.gd`
- Modify: `scripts/presentation/residue_visual.gd`
- Modify: `scripts/peel/label_print.gd`
- Modify: `art/shaders/peeled_paper.gdshader`
- Modify: `tests/test_paper_surface_shader.gd`
- Modify: `tests/test_label_backing_material.gd`
- Modify: `tests/test_residue_visual.gd`
- Modify: `tests/test_peel_flap_arc.gd`

**Interfaces:**
- Consumes: peel progress, effective grip, integrity, residue amount, and per-substrate `peel_feel`.
- Produces: distinct printed face, opaque backing, edge/thickness, narrow bend band, torn edge, and vessel-bound residue.

- [ ] **Step 1: Add RED paper-layer and edge assertions**

```gdscript
assert(corner.get_layer_names() == ["PrintFace", "PaperBacking", "PaperEdge"])
assert(corner.get_bend_band_ratio() <= 0.19)
assert(residue.get_parent_space_contract() == "vessel_local")
assert(residue.has_adhesive_trace())
```

- [ ] **Step 2: Run paper/residue suites and verify RED**

- [ ] **Step 3: Generate a deterministic irregular tear boundary**

Perturb only the released boundary with seeded low-frequency notches plus smaller fiber-scale offsets. Preserve a continuous main sheet; never turn the whole label into fuzzy noise.

- [ ] **Step 4: Separate the material layers in shading and geometry**

The print face remains matte and readable, backing stays opaque and slightly darker, edge thickness follows the substrate profile, and fibers affect roughness/normal more than silhouette. Glue/residue stays on the vessel after release and does not inherit paper transforms.

- [ ] **Step 5: Preserve resistance truth while improving visible load**

Before breakaway, show bounded corner lift and narrow-band curvature from stored load. Stationary holds still stall; no time-based peel progress is introduced.

- [ ] **Step 6: Capture all five mid-peel and released frames**

Inspect for paper stiffness, print continuity, irregular released edge, backing visibility, residue separation, and complete visual detachment.

---

### Task 6: Author a calm post-release label lifecycle

**Files:**
- Modify: `scripts/peel/label_lifecycle.gd`
- Create: `scripts/presentation/released_label_settle_presentation.gd`
- Modify: `scripts/peel_lab.gd`
- Modify: `scripts/presentation/guided_journey_presentation.gd`
- Modify: `tests/test_label_lifecycle.gd`
- Modify: `tests/test_post_peel_progression.gd`
- Create: `tests/test_released_label_settle_presentation.gd`

**Interfaces:**
- Consumes: lifecycle transition to fully released, product kind, label world transform, and reset/scene-switch boundaries.
- Produces: `FULLY_RELEASED -> SETTLING -> RESOLVED -> NEXT_READY` and `ReleasedLabelSettlePresentation.begin(kind: String, transform: Transform3D)`.

- [ ] **Step 1: Write RED lifecycle tests**

```gdscript
lifecycle.complete_detach()
assert(lifecycle.get_phase_name() == "FULLY_RELEASED")
lifecycle.advance(0.8)
assert(lifecycle.get_phase_name() == "RESOLVED")
assert(lifecycle.is_next_ready())
```

Also assert reset and scene switch cancel settlement and remove old paper exactly once.

- [ ] **Step 2: Run lifecycle tests and verify RED**

- [ ] **Step 3: Implement a deterministic 0.8 second settle**

Hold the released label for 0.18 seconds, then move/rotate it along a short eased path to a product-specific unobtrusive discard/collection location. After settlement, hide or archive the world sheet so it cannot cover the hero object. Do not add scoring pressure, timers, or failure states.

- [ ] **Step 4: Expose calm completion feedback and an obvious next action**

Update the bottom rail/status copy to show completion and keep number-key/rail navigation available. `R` still resets the current object; scene selection starts cleanly with quarantined input.

- [ ] **Step 5: Run lifecycle, progression, pause, reset, and input-isolation tests**

- [ ] **Step 6: Capture release at hold, settle, and resolved states**

Reject any result where the label remains floating indefinitely or disappears instantly before success is readable.

---

### Task 7: Close the full interaction flow and scene-boundary regressions

**Files:**
- Modify: `scripts/peel_lab.gd`
- Modify: `scripts/presentation/guided_journey_presentation.gd`
- Modify: `tests/test_input_reference_contract.gd`
- Modify: `tests/smoke_reset_input_isolation.gd`
- Modify: `tests/smoke_pause_input_isolation.gd`
- Modify: `tests/smoke_reset_loop.gd`
- Create: `tests/smoke_object_only_complete_flow.gd`

**Interfaces:**
- Consumes: direct mouse ownership, peel lifecycle, inspection controller, scene selection, pause/reset boundaries.
- Produces: one uninterrupted discover -> load -> peel -> inspect -> release -> settle -> next-ready flow.

- [ ] **Step 1: Write the complete-flow smoke test**

Stage fresh hover/contact, verify initial load without progress, provide outward work, inspect with RMB, complete release, wait for resolution, change scene, and assert the new scene begins neutral with progress zero and no stale held input.

- [ ] **Step 2: Run the smoke and verify any real boundary RED**

- [ ] **Step 3: Fix only the observed ownership or transition defect**

Keep `PointerAdapter` as the source owner and preserve fresh-press re-arm after pause/reset/scene switch. Do not add parallel input state in presentation scripts.

- [ ] **Step 4: Run all deterministic and smoke gates**

Run import/parser, default launch, unit suites, scene/reference/label/pause/reset smokes, and the new complete-flow smoke.

---

### Task 8: Final exact-head visual convergence and delivery evidence

**Files:**
- Modify: only presentation files implicated by the newest comparison.
- Create: `docs/superpowers/checkpoints/2026-08-20-reference-fidelity-final.md`
- Output: `artifacts/reference_frames/*.png`

**Interfaces:**
- Consumes: the approved reference images and exact-head runtime captures.
- Produces: a final evidence matrix with attached/mid/released frames for all five scenes plus lifecycle settlement frames.

- [ ] **Step 1: Run the complete exact-head verification gate**

Import/parser guard, configured default launch, deterministic tests, all smoke scripts, and 1280x720 capture must pass with no `SCRIPT ERROR` or missing resource.

- [ ] **Step 2: Compare at Macro scale**

Downsample target and runtime. Verify hero occupancy, center, value blocks, venue identity, HUD bounds, and silhouette before considering detail.

- [ ] **Step 3: Compare at Meso scale**

Verify vessel proportions, label contact/curl, cursor-edge alignment, residue placement, foreground grounding, light direction, and state continuity.

- [ ] **Step 4: Compare at Micro scale**

Verify paper fibers/edge, backing thickness, glue breakup, glass/metal/paper response, condensation, lid/rim details, and readable print.

- [ ] **Step 5: Iterate the largest controllable mismatch**

Change only the responsible presentation layer, rerun its tests, recapture the affected states, and repeat Macro -> Meso -> Micro. Never accept a prettier Micro result that regresses Macro or Meso.

- [ ] **Step 6: Write the final checkpoint**

Record exact head, engine version, commands, all inspected frames, before/after findings, remaining irreducible real-time-vs-static differences, and any owner-only feel judgments still unverified.
