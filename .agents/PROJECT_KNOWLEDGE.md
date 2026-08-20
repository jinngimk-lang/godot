# Peel Calm Shared Project Knowledge

This is compact operational memory for local and cloud agents. Current `main`, exact workflow evidence, `.agents/PROJECT_NORTH_STAR.md`, and the current handoff override conversation summaries and historical branches.

## Product thesis

Peel Calm is a relaxing realtime tactile/ASMR game about catching the edge of a paper label, loading and releasing its adhesive, watching the complete sheet curl away, then rubbing the glue and torn fibers off the vessel with the mouse.

It is object-first and object-only. The hero container, paper, adhesive, residue, lighting, and cursor must remain realtime Godot authority.

## Platform and entrypoint

- Godot 4.7.1 stable, GDScript.
- PC mouse first; pointer abstraction remains touch-ready.
- Configured main scene: `res://scenes/peel_lab/peel_lab.tscn`.
- A fresh clone/ZIP must import and run without Blender, external downloads, private runtime secrets, third-party Godot plugins, or AI services.

Pointer state exposed to gameplay:

```text
pressed: bool
position: Vector2
relative: Vector2
velocity: Vector2
released_this_frame: bool
```

## Current interaction authority

Peel authority:

`PointerAdapter -> PeelController -> PeelModel`

Visible paper consumes that state through `CornerPeelPresentation`. Presentation does not decide whether peel progress succeeds.

Residue-cleaning authority:

`PointerAdapter -> ResidueScrubModel -> ResidueVisual`

Cleaning only advances from pressed pointer travel inside the projected former-label footprint. Motion is capped per frame; back-and-forth reversal receives tactile weight. Hover, stationary hold, and outside motion do not clean.

Lifecycle:

`ATTACHED -> PEELING -> DETACHING -> HELD -> SETTLING -> RESOLVED -> RUB_RESIDUE -> CLEAN -> NEXT_READY`

`LabelLifecycle` owns the paper detach/settle phases. `ResidueScrubModel` owns the cleaning pass after `RESOLVED`. Continue and the exact-once session result are gated until cleaning completes.

## Input and boundary invariants

- One physical source owns a gesture: `NONE / MOUSE / TOUCH`.
- Ownership begins only from a fresh press; motion, stale release, secondary touch, or emulated duplicate events cannot silently inherit it.
- Touch and real mouse cannot steal/release one another mid-gesture.
- Pause, reset, detach, cleanup completion, and scene transition quarantine a held input.
- After a boundary, release is consumed and a later fresh press re-arms gameplay.
- RMB rotation and LMB peel/rub responsibilities must not leak into one another.

Preserve adversarial tests whenever changing input.

## Paper and adhesive invariants

Required causal peel path:

`new outward work -> stored bond load -> breakaway -> local release -> relaxation -> next increment`

- Stationary tension never creates progress.
- Initial breakaway is stronger than steady peel.
- Sideways/inward movement grants no free release.
- Released paper remains mostly stiff and bounded, not cloth/rubber/slime.
- Visible print remains on one continuous paper face and stays readable at representative mid-peel.
- Most bending remains localized near the peel front.
- Front, fibrous backing, thickness, adhesive boundary, and residue remain distinct material layers.
- 100% means the whole printed sheet is detached and later clears the hero.
- Residue stays on the vessel until the dedicated rub pass removes it.

Current resistance/stiffness ordering is approximately:

`Jar > Tin / Coffee > Yuzu > Soda Can`

Do not flatten all variants to one generic feel profile.

## Object-only presentation invariants

- No visible human hand or arm model.
- Use the repository-local small hand-shaped cursor for peel and rub feedback.
- No full-screen still image or video playback as fake gameplay.
- Background plates may support the scene but cannot replace the realtime hero.
- Centered hero product dominates the composition.
- Left HUD: scene/progress and compact controls.
- Right HUD: four-step tutorial ending in `RUB RESIDUE`.
- Bottom HUD: persistent five-scene rail.

Historical authored-hand, forearm, support-hand, crumple, and hand-pose documents/tests are not current product authority.

## Five product/scene bundles

- Coffee Shop: paper cup, molded lid, thermal label, warm café.
- Jar: glass food jar, sauce volume, rustic paper, pantry/kitchen.
- Tin Can: manufactured metal can, grocery wrap, merchandising/pantry.
- Supermarket: clear citrus bottle, coated paper, refrigerated retail.
- Can: aluminum beverage can, thin wrap, convenience/drink display.

They must remain distinguishable without reading the HUD. Differences come from silhouette, materials, environment, foreground/contact surface, light direction/temperature, and peel/substrate behavior.

## Audio model

Current event vocabulary includes slow/fast adhesive, paper flex, micro release, and final release. Audio reacts to real interaction state; idle/stationary holds do not sustain or retrigger peel events.

Next audio extension should be restrained residue-rub friction and tack release driven by real scrub travel/reversals. Keep all runtime audio repository-local with provenance.

## Verification contract

Meaningful work requires:

- official Godot 4.7.1 fresh import/parser guard;
- configured default-main-scene launch;
- deterministic unit/input/material/lifecycle tests;
- complete real-scene grab → peel → settle → rub → clean → next flow;
- pause/reset/scene-boundary isolation;
- all five product/environment smokes;
- non-headless captures at attached, peel, release, settle, dirty residue, partial scrub, and clean states;
- explicit image comparison for visible work;
- exact-head verification before integration and fresh verification on merged `main`.

CI cannot prove resistance pleasantness, scrub satisfaction, Foley balance, or owner taste. Keep those marked experiential until owner local playtest.

## Multi-agent coordination

Issue #5 remains the canonical cross-agent coordination hub. Before meaningful work, inspect current `main`, open PRs/branches, Issue #5 path claims, the current handoff, and relevant exact workflow results.

Avoid production-path collisions. Declare branch/base/files/evidence clearly. Old green evidence becomes stale when the candidate head or base changes.

## Next priorities

1. Owner feel tuning for peel and scrub.
2. Spatial/local residue removal plus restrained crumbs/adhesive rolls.
3. Rub Foley tied to motion/reversal.
4. Product, paper, contact-shadow, reflection, and environment realism.
5. Release-edge irregularity without print distortion or stretch.
6. Settings, accessibility, touch validation, and performance after PC feel stabilizes.
