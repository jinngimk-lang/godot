# Peel Calm Object-Only North Star

## Purpose

This file is the durable product-direction source of truth for the current rebuild. If implementation context is lost, re-read this file before changing presentation, interaction, scene composition, or scope.

The owner-approved visual direction is the latest no-hands gameplay mockup: a photoreal hero container centered in a real-feeling environment, a partially lifted label, a small hand-shaped mouse cursor at the peel edge, dark translucent UI chrome at left/right/bottom, and no visible character hands or arms.

## Non-negotiable direction

- **No visible hand or arm models in gameplay.** Delete the previous hand rendering/choreography/polishing stack from the runtime and remove its obsolete tests/assets once no references remain.
- **No video/still playback used as gameplay presentation.** Reference imagery is acceptance evidence only.
- **The mouse is the interaction authority.** Pointer screen position projects directly to the real 3D label grip point. There is no hidden hand proxy between mouse and label.
- **Use a small white outlined hand-shaped cursor** when interacting, matching the owner-supplied cursor reference.
- **Everything visible in the center is real-time Godot content:** product geometry, label geometry, residue, lighting, table/contact surface, and backdrop.
- **The latest object-only mockup is the visual north star.** A change is not done because tests pass; it is done when exact-head Godot screenshots converge on that reference.

## Core interaction

### Primary controls

- LMB: grab / peel the visible label
- RMB + drag: rotate the hero object
- Mouse wheel: zoom the camera in/out within a bounded range
- R: reset current object
- 1 / 2 / 3 / 4 / 5: select scene directly
- Esc: pause / resume

### Peel data flow

The intended runtime path is:

`mouse -> screen-to-world projection -> LabelVisual effective grip -> peel simulation -> label deformation/residue/audio`

Do **not** reintroduce:

`mouse -> hand model -> pinch anchor -> label`

When LMB is held, the visible flap follows the direct pointer-derived grip continuously. On release, the current peel state remains and can be re-grabbed.

## Scene set

The bottom rail exposes five deterministic scenes. These are the current product set and order.

### 1. Coffee Shop — paper cup

- Warm cinematic coffee-shop backdrop with shallow depth of field.
- Beige/tan paper takeaway cup centered as the hero object.
- Black molded plastic lid with stepped rings.
- Rectangular order sticker/receipt; hero copy reads **Cocoa Cloud** with secondary drink/order details.
- Paper tears/fibers and adhesive residue are visible during a partial peel.
- Warm polished wood table and grounded contact shadow.

### 2. Jar — tomato basil sauce jar

- Pantry/kitchen feeling; warm-neutral presentation.
- Clear cylindrical glass jar with metal lid and red tomato sauce interior.
- Rustic paper label with **Tomato Basil** / **Sauce** identity.
- Fibrous paper peel and glue residue on glass.

### 3. Tin Can — grocery can

- Pantry/grocery counter presentation.
- Silver tin can with top/bottom rolled rims.
- Printed paper wrap label, e.g. **Golden Peaches**.
- Peeling exposes bare brushed metal and patchy glue residue.

### 4. Supermarket — Yuzu glass bottle

- Bright convenience-store/cold-case backdrop.
- Clear glass bottle with pale yellow liquid and cool highlights.
- White/green **YUZU SPARKLING** citrus label.
- Cleaner coated-paper peel with translucent adhesive residue rather than heavy fibers.

### 5. Can — chilled soda can

- Modern convenience/café cold-display environment.
- Aluminum soda can with condensation and readable metallic rims.
- Bright lemon/citrus printed wrap label, e.g. **Lemon Sparkling Soda**.
- Thin wrap peels away to reveal bare aluminum with subtle adhesive.

## Product rendering architecture

`ProductPresentation` is the deterministic real-time hero-object generator. It supports these semantic kinds:

- `paper_cup`
- `sauce_jar`
- `tin_can`
- `clear_bottle`
- `soda_can`

Each kind must expose one stable semantic root/detail node for tests and presentation tuning. Geometry is built once per variant switch, not every frame.

### Material priorities

1. silhouette and real-world proportions,
2. product-specific surface response,
3. readable label contact,
4. grounded contact shadow,
5. small secondary details.

Avoid expensive effects that do not materially improve the reference match.

## Cursor

Add a repository-owned cursor asset under `assets/ui/` and install it at runtime with Godot's custom cursor API. The hotspot should sit near the index-finger tip so the label visibly follows the cursor contact point. The cursor remains lightweight and independent of scene content.

## Camera and composition

- Hero object occupies roughly 55–70% of viewport height in the owner-approved reference style.
- Camera remains centered on the object; no human limbs enter the frame.
- Mouse wheel zoom adjusts FOV or camera distance only within a narrow reference-safe range.
- Backdrop must cover the entire viewport with overscan and no black wedges.
- Table/contact plane must visually integrate with the backdrop rather than read as a separate low-poly stage.

## HUD north star

The HUD follows the owner-approved object-only mockup.

### Upper-left

- `SCENE: <NAME>`
- `Peel Progress NN%`
- horizontal progress bar with warm gold fill

### Left control stack

- LMB Peel
- RMB Rotate
- Wheel Zoom
- R Reset
- 1 2 3 4 5 Change Scene
- Esc Pause / Menu

### Right tutorial panel

Title: `HOW TO PLAY`

1. `GRAB EDGE` — move to/click the label edge
2. `PEEL GENTLY` — click and drag slowly
3. `INSPECT` — rotate and zoom to inspect residue
4. `CLEAN PEEL` — remove the label with minimal residue

The center peel contact zone must stay unobstructed.

### Bottom rail

Five persistent buttons:

1. COFFEE SHOP
2. JAR
3. TIN CAN
4. SUPERMARKET
5. CAN

The active scene uses a warm gold border/fill accent. The rail remains visible during an active peel, matching the reference.

## Cleanup contract

The following previous directions are obsolete and must not be reintroduced:

- visible `HandVisual` runtime hands,
- cinematic hand/forearm overlays,
- hand choreography,
- hand surface smoothing,
- crumple hand staging,
- reference peel playback,
- tests that require visible hands or hand-label pinch alignment.

Once runtime references are removed, delete obsolete scripts/tests/assets rather than leaving dead code.

## Testing contract

Deterministic tests must prove:

- scene contains no visible hand presentation nodes;
- `PeelLab` reports `visible_hands = false` and `pointer_grip = mouse_direct`;
- control contract includes Wheel zoom and scene keys `1/2/3/4/5`;
- five variants exist in the required order and kinds;
- all five product kinds build their semantic real-time geometry;
- HUD contains progress, controls, tutorial, and five-button scene rail;
- reference playback is absent;
- pause/reset input isolation remains intact;
- peel progress/residue still run through the existing real simulation.

## Runtime evidence gate

GitHub Actions is the execution environment when the local container cannot run the repository directly. Exact-head CI must:

1. install Godot 4.7.1;
2. import/parse and launch the configured project;
3. run deterministic and smoke tests;
4. capture each of the five scenes at 0% peel;
5. capture representative mid-peel frames for visual comparison;
6. upload the screenshot artifact.

### Visual RED conditions

Do not merge while any of these are visible:

- human hand/arm geometry,
- frozen/reference-video presentation,
- low-poly blockout objects that dominate the frame,
- product too small or off-center,
- label flap disconnected from cursor contact,
- scene rail missing during active peel,
- unreadable HUD hierarchy,
- materials that read as flat plastic instead of paper/glass/metal,
- backgrounds/lighting that make the five scenes feel like different prototypes.

## Completion rule

The rebuild is complete only when the game is genuinely playable in Godot and the exact-head runtime screenshots visually match the approved object-only reference direction closely enough that remaining differences are minor polish, not architecture, interaction, composition, or material failures.
