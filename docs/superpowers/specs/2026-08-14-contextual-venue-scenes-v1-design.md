# Contextual Venue Scenes V1 Design

## Goal
Make each tactile cup variant feel like it belongs to a distinct real-world place by coupling the session variant to a presentation-only venue profile. The cup remains the interaction focus, but the table, background architecture, accent lighting, and visual storytelling change with the current item.

## Product direction
The environment should answer “where would this cup naturally live?” without adding pressure or changing peel rules. The first three contexts are:

- `warm_paper` → floor-to-ceiling-window café, warm daylight, dark wood table, soft city silhouettes.
- `silky_long` → intimate evening bar, dark bar top, amber backbar, shelf/bottle silhouettes and pendant glow.
- `crisp_seal` → clean grocery/market cold-case aisle, light display counter, cool white panels, shelf/product silhouettes.

These are deliberately generic fictional venues. Do not replicate real café, alcohol, or retail brands/trade dress.

## Architecture
`SessionModel` remains the source of variant content and adds a `scene_profile` dictionary. `VenuePresentation` is a presentation-only `Node3D` that owns reusable procedural venue geometry and applies one profile at a time. `peel_lab.gd` only forwards the current variant profile during `_apply_current_variant()`.

Gameplay authority remains unchanged:

`PointerAdapter -> PeelController -> PeelModel`

Venue nodes must never decide peel progress, completion, score, crumple eligibility, pointer ownership, or session unlocks.

## Scene profile contract
Every production variant supplies:

- `scene_profile.id`: stable context id (`cafe_window`, `night_bar`, `market_coldcase`).
- `scene_profile.table_color`: table/counter albedo.
- `scene_profile.table_roughness`: presentation roughness.
- `scene_profile.ambient_color`: broad background color.
- `scene_profile.accent_color`: lights/signage/detail color.
- `scene_profile.light_energy`: bounded accent-light energy.

Unknown or missing profiles fall back to `cafe_window`.

## Venue composition
All geometry is repository-local and procedural so a fresh clone has no external scene dependency.

### Café
Large dark wall plane with three tall bright window panes, vertical mullions, low distant skyline blocks, dark walnut table, soft warm accent light.

### Bar
Deep charcoal wall, glowing amber backbar panel, two shelf rails, bottle silhouettes, three pendant shades, near-black bar counter, amber accent light.

### Market
Pale cool wall, three cold-case panels, shelf rails, product-block silhouettes, ceiling-light strips, light neutral display counter, cool accent light.

The camera/cup/hand composition stays fixed for interaction continuity; venues sit behind and below the cup and should not obscure label edges or hands.

## Testing
Add deterministic tests that:

1. every session variant contains a non-empty `scene_profile` with a unique id;
2. the expected ids are `cafe_window`, `night_bar`, `market_coldcase` in progression order;
3. `VenuePresentation` accepts each profile and exposes the active profile id;
4. exactly one venue root is visible after each switch;
5. missing/unknown ids fall back to café;
6. venue switching does not modify session progression state.

Existing Godot import, unit, scene, presentation, ritual, pause/reset and input-isolation gates must remain green.

## Non-goals for V1
Do not pretend glass/beer containers can use paper-cup crumple semantics. Material-specific post-peel rituals belong in a later cup-material expansion. This change establishes the environment/profile interface that those future variants will reuse.
