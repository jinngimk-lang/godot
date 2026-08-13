# Godot Game Base + Model Asset Pipeline Design

Date: 2026-08-13
Status: Design approved in principle; implementation gated on spec review
Target engine: Godot 4.7.1 stable
Primary language: GDScript
Repository: `jinngimk-lang/godot`

## 1. Objective

Build a reusable, lightweight Godot project base that can be cloned or downloaded and opened directly in Godot 4.7.1. The base must remove repeated setup work without locking future games into a specific genre or a large third-party framework.

The same repository will also define a reproducible 3D asset pipeline so future game models can be generated, previewed, reviewed, and then imported into Godot with minimal manual conversion work.

The base is not a finished game. It is the product shell and asset infrastructure from which different games can be built quickly.

## 2. Design Principles

1. **Godot-native first.** Prefer built-in Godot concepts, scenes, resources, autoloads, ConfigFile, ResourceSaver, and import tools before adding plugins.
2. **Small reusable core.** Keep the base understandable without reading a framework manual.
3. **Genre-neutral shell.** Menu, pause, settings, save/session, scene routing, input, audio, and CI must not assume shooter/platformer/RPG gameplay.
4. **Scenes own local behavior.** Avoid global nodes reaching deep into scene trees. Reusable scenes expose small signals/methods.
5. **Evidence before dependency.** Third-party plugins and AI/model backends are optional until a bounded experiment proves they improve the baseline.
6. **Runtime assets are portable.** Prefer `.glb` as the committed runtime 3D interchange artifact.
7. **Source and generated assets are distinct.** Blender source, procedural recipes, generated GLB, preview renders, and metadata have separate locations.
8. **Model generation is reviewable.** A generated model is not accepted merely because generation succeeded; it must have a preview and asset metadata.
9. **No hidden authority.** Tools that can execute arbitrary host code are never enabled by default in the project pipeline.
10. **No copied template identity.** External repositories are research references. We adopt patterns, not project identity or unnecessary dependencies.

## 3. Research Inputs and What We Keep

### Godot official demo projects

Keep:
- Godot-native scene organization patterns.
- Small isolated examples rather than one giant framework.
- Version-matched engine behavior.

Do not copy:
- Demo-specific gameplay or assets that do not serve the base.

### Maaack/Godot-Game-Template

Keep as design inspiration:
- Main menu / pause / options separation.
- Scene loading as infrastructure rather than gameplay logic.
- Settings persistence.
- Reusable menu flow.

Do not adopt as a hard dependency in v1.

### crystal-bit/godot-game-template

Keep as design inspiration:
- Lightweight project boilerplate.
- Lowercase/snake_case filesystem discipline.
- Scene management abstraction.
- ConfigFile-backed settings.
- Debug/release separation.
- Automated export/check workflows.

Do not import its addons wholesale in v1.

### Blender / Godot glTF workflow

Keep:
- `.glb` as the normal runtime model artifact.
- `.blend` as an optional authoring source, not a required runtime dependency.
- PBR-friendly material conventions.
- Import automation where deterministic.

### AI-assisted 3D projects

- **TripoSR:** MIT-licensed image-to-3D project; candidate for a future optional experiment, not a base dependency.
- **BlenderMCP:** useful reference for AI-assisted Blender control, but disabled as a default integration because arbitrary Python execution and host-level access create a materially larger trust boundary. Its telemetry/data terms also require explicit review before any use.
- **Hunyuan3D:** not a default candidate because its community license has territory and distribution constraints that are inappropriate for a neutral base.

## 4. Proposed Repository Structure

```text
/
├── project.godot
├── README.md
├── LICENSE
├── .gitignore
├── .gitattributes
├── .editorconfig
│
├── autoload/
│   ├── app_state.gd
│   ├── scene_router.gd
│   ├── settings_store.gd
│   └── save_store.gd
│
├── scenes/
│   ├── app/
│   │   └── app.tscn
│   ├── gameplay/
│   │   └── playground_3d.tscn
│   └── ui/
│       ├── main_menu/
│       ├── pause_menu/
│       ├── settings_menu/
│       └── hud/
│
├── components/
│   ├── audio/
│   ├── interaction/
│   └── debug/
│
├── resources/
│   ├── themes/
│   ├── audio/
│   └── data/
│
├── assets/
│   ├── textures/
│   ├── audio/
│   └── models/
│       ├── authored/
│       └── generated/
│
├── asset_source/
│   └── models/
│       ├── blender/
│       └── briefs/
│
├── tools/
│   ├── modeling/
│   │   ├── recipes/
│   │   ├── render_preview.py
│   │   ├── validate_asset.py
│   │   └── README.md
│   └── ci/
│
├── tests/
│   ├── smoke/
│   └── fixtures/
│
├── docs/
│   ├── architecture/
│   ├── assets/
│   └── superpowers/specs/
│
└── .github/
    └── workflows/
        └── godot-check.yml
```

Empty directories will only be created when they have a real file to contain; no placeholder-directory noise is required.

## 5. Runtime Application Shell

### 5.1 App scene

`scenes/app/app.tscn` is the project main scene. It owns only top-level presentation surfaces and starts in the main menu.

It does not contain game-specific systems.

### 5.2 SceneRouter

Responsibilities:
- Change between high-level scenes.
- Optionally pass a small dictionary of transition parameters.
- Prevent duplicate transition requests.
- Expose transition state for UI.

Non-responsibilities:
- Gameplay state.
- Saving game-specific entities.
- Deciding level progression.

V1 should use the smallest implementation that supports menu → gameplay → menu and restart.

### 5.3 AppState

Contains ephemeral cross-scene session state only, for example:
- current run identifier;
- selected profile slot later;
- developer flags in debug builds.

Persistent settings belong in `SettingsStore`; persistent game progress belongs in `SaveStore`.

### 5.4 SettingsStore

Use Godot `ConfigFile` for user settings.

V1 settings:
- master volume;
- music volume;
- SFX volume;
- fullscreen/windowed;
- VSync;
- input sensitivity placeholder where applicable.

Requirements:
- defaults work with no config file;
- corrupted/unknown values fall back safely;
- writing settings is explicit;
- release does not depend on editor state.

### 5.5 SaveStore

V1 provides a stable interface, not a full game save schema.

Responsibilities:
- versioned save envelope;
- one test save slot;
- atomic-ish temp-write/replace pattern where practical;
- graceful handling of missing or invalid save data.

Gameplay-specific save payloads are added only when the selected game requires them.

### 5.6 Menu flow

Required runnable flow:

```text
Boot
→ Main Menu
→ Start
→ 3D Playground
→ Esc / Pause
→ Resume | Restart | Main Menu
```

The playground proves the shell works but remains deliberately minimal.

## 6. Input and Device Strategy

V1 supports keyboard/mouse and conventional gamepad navigation for shell actions.

Canonical actions:
- `ui_accept`, `ui_cancel` where Godot already defines them;
- `game_pause`;
- a minimal movement quartet for the playground;
- optional look actions only if needed by the first gameplay prototype.

Do not create dozens of speculative actions before a game design exists.

## 7. Audio Strategy

Define buses:

```text
Master
├── Music
└── SFX
```

Settings control bus volume. The base should include no copyrighted third-party music or sound assets.

## 8. 3D Asset Contract

### 8.1 Runtime format

Default committed runtime model: `.glb` (glTF 2.0 binary).

Reasons:
- recommended and well-supported by Godot;
- supports hierarchy, materials, skeletons, animation, and PBR workflows better than OBJ;
- compact single-file delivery for normal assets;
- independent of the model generation backend.

### 8.2 Asset package

Each generated asset lives in:

```text
assets/models/generated/<asset_id>/
├── model.glb
├── preview.png
└── asset.json
```

`asset.json` records at minimum:

```json
{
  "asset_id": "example_crate_01",
  "generator": "procedural_blender",
  "generator_version": "1",
  "brief": "asset_source/models/briefs/example_crate_01.json",
  "scale_meters": true,
  "status": "candidate"
}
```

Additional fields may later include triangle count, material count, texture set, rig information, and accepted commit SHA.

### 8.3 Source files

- Editable `.blend` sources go under `asset_source/models/blender/` when preserving the source is useful.
- Generation requests/briefs are small JSON files under `asset_source/models/briefs/`.
- Runtime code never loads from `asset_source/`.

### 8.4 Modeling quality baseline

For ordinary real-time assets:
- scale expressed in meters;
- sensible origin/pivot placement;
- applied transforms before final export when appropriate;
- consistent outward normals;
- PBR-compatible materials;
- avoid accidental backface rendering unless intentional;
- no hidden cameras/lights in runtime GLB unless the asset requires them;
- geometry complexity appropriate to gameplay distance;
- collision generated separately unless the model has a justified authored collision mesh.

Character-specific rig/animation rules will be specified when a character pipeline is selected.

## 9. Model Generation Pipeline

### 9.1 Default backend: deterministic Blender Python

The first supported model-generation route is a bounded Blender Python recipe.

Flow:

```text
asset brief
→ Blender Python recipe
→ source scene (optional)
→ normalized geometry/materials
→ GLB export
→ preview render
→ validation
→ candidate asset package
→ human review
→ accepted asset
```

This route is preferred for:
- low-poly props;
- modular environment pieces;
- blockout buildings;
- simple weapons/tools;
- pickups;
- rocks, crates, barriers, platforms;
- procedural variants.

Benefits:
- reproducible;
- editable;
- no hosted model API required;
- easier to validate than opaque generation.

### 9.2 Optional image-to-3D adapter

A future adapter may accept a concept image and produce a candidate mesh through a project such as TripoSR or another backend.

It remains experimental until it passes:
- license review;
- hardware/runtime feasibility;
- output topology and texture quality checks;
- repeatable conversion to the same asset contract;
- measurable time saving over the Blender baseline.

The game project must not know which generator created a GLB.

### 9.3 BlenderMCP position

BlenderMCP is a research reference, not a default dependency.

If later tested, requirements are:
- telemetry disabled;
- disposable/bounded environment preferred;
- no secrets available to Blender;
- generated Python reviewed/logged;
- no direct promotion of output to accepted game assets;
- normal preview/validation gate still required.

### 9.4 Preview standard

Every model candidate should receive a consistent preview image before acceptance.

Default preview:
- PNG;
- 512×512 or larger;
- neutral background;
- three-quarter camera angle;
- neutral key/fill lighting;
- model fully visible;
- no post-processing that hides geometry defects.

For characters or important hero props, additional front/side/back previews can be generated.

This preview is what can be shown to the owner for visual confirmation before the asset is treated as final.

## 10. CI / Verification

V1 CI goal is correctness of the base, not automated game quality scoring.

Required checks:
1. Repository contains a valid `project.godot`.
2. Godot 4.7.1 can import/open the project headlessly.
3. GDScript parsing succeeds.
4. Main scene is loadable.
5. A smoke script can exercise the expected main-scene path without parse/load errors.
6. Generated model metadata validator rejects missing `model.glb`, `preview.png`, or malformed `asset.json` once model assets exist.

Export jobs for Windows/Linux/Web are a later bounded addition after the base imports and runs reliably.

## 11. Error Handling

- Missing settings file → defaults, no crash.
- Invalid settings field → ignore field and use default.
- Missing save → clean new-save state.
- Invalid save → surface a recoverable error and preserve bad file where practical.
- Scene transition to invalid path → log failure and keep current stable scene.
- Missing generated model metadata → asset validation fails; runtime shell is not blocked if the model is unused.
- Model generator unavailable → mark generation route unavailable; do not change the game runtime contract.

## 12. Testing Strategy

Behavioral changes follow RED → GREEN where practical.

Initial tests cover:
- settings default/load/save behavior;
- invalid settings fallback;
- save envelope version parsing;
- invalid save handling;
- scene router invalid-path behavior;
- main scene smoke load;
- model asset manifest validation.

A test framework plugin is not required in v1. If native/headless test scripts become cumbersome, GUT or another framework may be evaluated as a bounded dependency later.

## 13. Explicit Non-Goals for V1

Do not implement yet:
- a final game genre;
- inventory/RPG systems;
- combat framework;
- ECS framework;
- multiplayer;
- Steam integration;
- dialogue framework;
- procedural world generation;
- character creator;
- mandatory AI model service;
- mandatory BlenderMCP;
- heavy third-party Godot framework;
- automated acceptance of generated visual assets.

## 14. First Implementation Acceptance Criteria

The base implementation is accepted only when all are true:

1. Fresh clone opens in Godot 4.7.1 without missing project dependencies.
2. Running the project shows a main menu.
3. Start enters the 3D playground.
4. Pause/resume/restart/main-menu flow works.
5. Audio/window settings persist across runs.
6. SaveStore can write/read a versioned smoke payload.
7. Invalid config/save data does not crash the shell.
8. CI verifies parse/import/main-scene smoke behavior.
9. Modeling directories and manifest validator exist without requiring Blender to run the game.
10. A tiny procedural model experiment can be added later without changing the runtime asset contract.
11. README explains local import/run steps in under a few minutes.
12. No third-party plugin is required for the first successful run.

## 15. Implementation Sequence After Spec Approval

1. Create implementation plan with exact files and RED/GREEN checks.
2. Establish repository hygiene and `project.godot`.
3. Build minimal app/menu/playground flow.
4. Add settings and audio buses.
5. Add SaveStore envelope.
6. Add pause/restart/main-menu behavior.
7. Add headless smoke validation and CI.
8. Add model asset contract + manifest validator.
9. Add one bounded procedural-model recipe only as a pipeline proof, not as game art direction.
10. Independently review exact head, fix findings, then merge/verify main.

## 16. Decision Summary

**Decision: BUILD the lightweight Godot-native base.**

**Decision: BUILD the model asset contract and deterministic procedural Blender route as an optional tool layer.**

**Decision: WATCH/EXPERIMENT with image-to-3D backends later.**

**Decision: DO NOT integrate BlenderMCP into the trusted default pipeline at this stage.**

This design intentionally optimizes for fast future game development while preserving the ability to change genre, art direction, modeling backend, and export targets without rebuilding the foundation.
