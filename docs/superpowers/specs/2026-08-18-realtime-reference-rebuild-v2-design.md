# Realtime Reference Rebuild v2

## Goal

Rebuild Peel Calm so the supplied reference images are a visual target, not a rendered overlay. The shipped game must remain fully interactive in Godot while all three scenes read as one coherent photoreal first-person peeling experience.

## Non-goals

- Do not play or swap full-screen reference stills/video frames during gameplay.
- Do not replace gameplay authority with canned animation.
- Do not add unrelated progression systems.
- Do not build low-poly procedural room geometry that competes with the photographic venue plates.

## Reference-derived acceptance target

### Café

- Warm window café plate, shallow depth of field, wood table.
- Large paper takeaway cup centered slightly right of frame center.
- Black molded lid with visible stepped rim.
- Two human hands: support hand holds cup; peel hand pinches a lifted paper corner.
- Paper label is physically attached to the cup and visibly curls as it peels.
- Forearms exit naturally toward the lower corners and do not form long tubes across the viewport.

### Amber bar

- Warm dark bar background with bottle bokeh.
- Brown/amber glass bottle, glossy highlights and visible thickness/fresnel.
- Large vertical fibrous paper label rather than a small horizontal strip.
- Support hand grips the bottle shoulder/body; peel hand pulls a damaged fibrous flap.
- Torn backing/residue must be visible when the player pulls too fast.

### Market yuzu

- Bright convenience-store/cold-case plate.
- Clear glass bottle with pale yuzu liquid, condensation and green/metal cap treatment.
- Large white/green label on the bottle body.
- Clean coated peel should expose translucent adhesive residue without the heavy fibrous backing used by the bar variant.
- Hands and lighting must use the same visual language as Café/Bar.

## Runtime architecture

### 1. Real-time render authority

`ReferencePeelPlayback` is removed from the scene and no reference motion image is rendered over gameplay. Reference images remain external acceptance evidence only.

The render stack becomes:

1. photographic venue backdrop (`ReferenceBackdrop`),
2. real 3D table/contact plane,
3. real-time product geometry,
4. real-time label geometry + residue,
5. authored XR hand skeleton/mesh,
6. PBR hand/sleeve presentation,
7. HUD.

### 2. Hands

The repository hand GLBs remain the source of topology, skeleton and authored `Cup`, `Pinch Up`, and `Pinch Tight` poses.

The presentation layer must:

- keep the continuous authored hand mesh visible;
- use shaded PBR skin instead of an unshaded color shader;
- preserve imported smooth geometry and skinning;
- use a short tapered forearm/sleeve that exits the lower corners;
- use believable warm skin roughness/specular and a separate nail material;
- never reveal the procedural fallback unless the authored asset fails to load.

Hand pose and label grip remain coupled through `HandVisual.get_pinch_world_position()`.

### 3. Product rendering

`ProductPresentation` remains procedural but is upgraded as a deterministic real-time model generator.

Paper cup:
- correct taper and height;
- molded multi-ring black lid;
- fibrous paper shader;
- grounded contact shadow.

Amber bottle:
- denser smooth lathe silhouette;
- physically lit amber glass shell + subtle inner shell + amber liquid;
- neck/lip geometry and highlights;
- large paper-label fit.

Market bottle:
- clear glass shell + pale liquid;
- cap and mouth details;
- condensation;
- large coated label fit.

### 4. Label interaction

The label mesh remains the authoritative object. LMB press on the visible label/edge arms a peel, then drag controls the real 3D flap. The flap is regenerated continuously from progress and the current hand pinch target.

Requirements:

- no discrete reference-frame stepping;
- no visual teleport at the start of a peel;
- hand pinch and rendered flap tip remain within a small deterministic tolerance;
- release allows re-grab;
- Café uses mostly clean paper separation;
- Bar can leave fibrous backing;
- Market leaves cleaner coated adhesive residue.

### 5. Camera and composition

- Product should occupy the central 45–60% of frame height depending on scene.
- Café uses a tighter FOV than bottles.
- Support hand stays on the opposite side of the peel hand and both remain in front of the product.
- Forearms leave the frame diagonally instead of running laterally through the scene.
- Reference backdrop covers the viewport with small overscan and no black wedges.

### 6. Unified HUD / controls

The HUD follows the supplied Peel Calm concept rather than the current tiny debug strip.

Persistent controls:

- LMB: grab / peel
- RMB + drag: rotate product
- R: inspect / return
- T: reset current item
- 1 / 2 / 3: Café / Bar / Market
- Esc: pause / resume

HUD hierarchy:

- upper-left: product name + peel progress + quality summary;
- left objective panel: remove label, minimize residue, preserve intactness;
- upper/right helper: concise control legend;
- right how-to-play panel: Grab Edge, Peel Gently, Inspect, Clean Peel;
- bottom scene rail: three consistent scene choices with active state.

The panels must use translucent dark glass styling and stay readable without covering the hand-label contact area.

## Input changes

RMB rotation becomes the default inspect/rotation gesture during play. Keyboard `R` toggles inspection presentation and `T` resets. Existing code paths are adapted so pointer state remains isolated while paused and resetting.

## Performance requirements

- No per-frame image decoding.
- No full-screen reference texture swaps.
- No creation/freeing of hand/product meshes every frame.
- Rebuild label geometry only when progress/grip changes.
- Static materials and product geometry are reused within a scene run.

## Tests

Deterministic tests must cover:

- reference playback no longer exists in the default scene;
- authored hand assets remain active and shaded;
- no visible primitive/procedural shell when authored assets load;
- forearm presentation span stays within cinematic bounds;
- product profiles match paper/amber/clear kinds;
- label dimensions differ appropriately per variant;
- input contract maps LMB/RMB/R/T/1/2/3/Esc correctly;
- hand pinch target remains aligned to label flap tip;
- scene reset and pause isolation continue to pass.

## Runtime evidence gate

The GitHub Actions Godot job must:

1. import and launch the configured project;
2. run deterministic/unit/smoke tests;
3. capture Café, Bar and Market at 0% peel;
4. capture each scene at a representative mid-peel state with the hand positioned on the flap;
5. upload exact-head screenshots.

A change is not accepted from green tests alone. Exact-head screenshots must be inspected for:

- no reference overlay/video look;
- believable hands and short forearms;
- correct product silhouette/material;
- label scale and peel direction matching the target concept;
- no black background wedges or low-poly room geometry;
- consistent UI hierarchy across all scenes.
