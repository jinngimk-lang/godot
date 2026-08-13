# Peel Calm — Tactile Upgrade V2 Design

Date: 2026-08-13
Branch: `feat/tactile-upgrade-v2`
Base: `main@b5f32cf722284458104c2688fa95fec9c4177231`

## Goal

Turn the proven V1 interaction into a materially more believable peel experience without replacing the deterministic peel model that already passed RED/GREEN and mainline verification.

The V2 target is: the player sees a semi-realistic clean hand pinch the actual peel edge, feels visible resistance while the label remains partly adhered, then sees the final adhesive bond release and the entire label become a detached object held by the right hand. Audio changes from synthetic placeholder noise to repository-local real Foley layers.

## Owner Playtest Evidence

The first local playtest produced three concrete failures:

1. At `Peel 100% / COMPLETE`, the label still visually stretches from the cup to the hand instead of becoming fully detached.
2. The hands read as abstract blocks rather than believable hands.
3. The procedural audio reads as synthetic/abstract rather than satisfying adhesive/paper Foley.

Screenshots additionally show the printed order text visually separating from the deformed label, so text must become part of the label surface rather than a free-standing world-space `Label3D`.

These are V2 acceptance failures, not optional polish.

## Approach Decision

Three approaches were considered:

- Patch V1 presentation only: fastest, but preserves the same structural limits.
- Rebuild presentation around the proven peel model: selected. Keep deterministic peel/scoring/input contracts; replace completion lifecycle, label rendering, hand presentation, and audio presentation.
- Adopt a full external rig/IK/Blender stack immediately: higher visual ceiling, but adds dependency and iteration cost before the tactile loop is proven.

V2 uses the second approach. External GLB hand assets remain a replaceable presentation layer, not a required runtime dependency.

## 1. Label Lifecycle

### Runtime phases

`ATTACHED -> PEELING -> DETACHING -> HELD -> RESETTING`

- `ATTACHED`: progress 0; all label samples conform to the cup surface.
- `PEELING`: progress in `(0, 1)`; the unpeeled region stays constrained to the cup, the peeled region forms a short paper arc to the pinch point.
- `DETACHING`: one-shot transition when solver completion fires. Cup anchoring is removed over a short 120–220 ms release impulse; the label must never remain connected to the cup after this phase.
- `HELD`: the complete label is a free object whose transform is driven by the pinch grip, with mild bend/sag/inertia. No vertex or endpoint references the cup surface.
- `RESETTING`: reward hold, then a new label/cup session.

### Completion invariant

Once `completed_now == true` has fired:

- the label visual must expose `is_detached() == true` after the detaching transition;
- no geometry point may be generated from `CupSurface.point_on_cylinder()`;
- the cup-side anchor is released exactly once;
- completion score is emitted exactly once;
- mouse movement after completion moves the held label with the hand instead of stretching the label back to the cup.

A deterministic test will explicitly prove this lifecycle.

## 2. Label Geometry and Print

### Geometry

Retain lightweight segmented geometry rather than full cloth simulation.

During `PEELING`, the attached section follows cylindrical mapping and the free section uses a constrained paper arc. Maximum apparent stretch is bounded so a normal label cannot become a long rubber ribbon. V2 will prefer preserving approximate segment spacing over connecting arbitrary world-space endpoints.

During `HELD`, rebuild/transform the whole strip in hand-local space. A small procedural curl and damped secondary motion are allowed, but the strip has no cup anchor.

### Printed label surface

Remove the independent world-space order `Label3D`.

Create a small `SubViewport` containing the order number, drink name, simple barcode-like marks, and subtle thermal-print styling. Use its `ViewportTexture` as the `StandardMaterial3D.albedo_texture` for the deforming label mesh. This keeps text and graphics on the label while it bends and detaches.

The texture system is deliberately data-driven so later cups can change order text without changing mesh code.

## 3. Semi-Realistic Clean Hand Direction

Selected art direction: semi-realistic, clean, calming; recognizable anatomy without photoreal skin pores.

### V2 hand contract

Replace the current palm-box/two-finger proxy with an articulated hand representation:

- wrist/palm volume with rounded silhouette;
- five fingers with correct relative lengths;
- opposable thumb;
- visible thumb/index pinch around the label edge;
- relaxed middle/ring/little finger curl;
- simple nail surfaces on visible fingertips;
- soft skin material and restrained roughness;
- left hand uses a stable cup-holding pose;
- right hand exposes `set_grip_target()` and `set_pinch_amount()` so gameplay code does not depend on the specific hand asset.

### Implementation boundary

V2 may start with repository-local procedural articulated geometry if that is the fastest deterministic route, but the interface must be rig-ready. A later `.glb` hand with `Skeleton3D`/IK can replace the visual without changing peel/controller code.

Do not add a mandatory third-party IK addon. Godot 4.7 native skeleton modifier/IK capabilities are the preferred future path; external IK projects are research references only.

## 4. Foley Audio System

Delete the synthetic sine/noise generator as the primary presentation path.

### Layers

Repository-local short audio samples will be grouped into:

- `adhesive_slow`: close, sticky low-speed peel texture;
- `adhesive_fast`: brighter/faster peel texture;
- `paper_flex`: quiet paper bend/crinkle layer;
- `micro_release`: short adhesive ticks for incremental releases;
- `final_release`: distinct final separation pop/peel;
- optional `hand_contact`: fingertip/paper touch.

Use short WAV assets for tactile one-shots/loops and vary playback slightly to reduce repetition. Source only assets with a license we can redistribute in the repository; prefer CC0 and record source/license metadata in `assets/audio/ATTRIBUTION.md` even when attribution is not legally required.

The first research pool includes CC0 paper/tape recordings from OpenGameArt/Freesound; only files whose source and license are independently confirmed may be committed.

### Parameter mapping

- pull velocity controls slow/fast blend;
- tension controls gain and brightness/intensity;
- actual solver `released` amount triggers micro-release accents;
- final detach triggers the final release once;
- no peel loop while the player is not actively peeling.

## 5. Camera, Cup and Readability

Keep the single close-up tabletop composition, but improve presentation only where it supports the tactile action:

- slightly closer camera framing;
- softer key/fill balance and less harsh black background contrast;
- cleaner generic café cup material;
- label print must remain readable before peeling;
- gold debug marker becomes subtler and can later be replaced by edge highlight/tutorial affordance;
- debug state text remains available in development builds but should not dominate the final composition.

No new progression/shop/cup collection work in this V2 slice.

## 6. Data Flow

`PointerAdapter -> PeelController -> PeelModel`

`PeelController` emits phase/progress/release/completion data.

Presentation consumers:

- `LabelVisualV2` consumes progress, grip transform, phase;
- `HandVisualV2` consumes grip target + pinch amount;
- `PeelFoley` consumes speed, tension, released amount, phase transitions;
- HUD/reward consumes progress/state/completion.

Gameplay authority stays in the deterministic model/controller; visual/audio systems never decide whether peel progress succeeds.

## 7. Testing and Evidence

### RED tests to add before implementation

1. completion transitions from peeling to detached/held state exactly once;
2. held-label geometry has no cup-surface anchor after detachment;
3. held label follows grip movement without changing solver progress;
4. label segment length/stretch stays within a bounded tolerance during normal pulls;
5. label texture provider exists and free-standing print node is no longer required;
6. audio event router emits final release exactly once and does not emit active peel while idle;
7. existing touch/mouse/solver/scoring tests remain green.

### Scene smoke

Headless scene smoke must instantiate the upgraded label, hand and audio nodes without missing resources.

### Mainline proof

As in V1: exact RED SHA, exact GREEN/reviewed SHA, PR CI, protected exact-head merge, then merged `main` Godot 4.7.1 import/unit/smoke verification.

### Explicit UNVERIFIED items

CI cannot prove:

- the new hand looks natural enough;
- the pinch pose is visually convincing on the owner's display;
- the Foley is relaxing rather than annoying;
- resistance feels pleasant;
- the final detach visual reads as satisfying.

Those remain local owner playtest evidence for V3 tuning.

## 8. Dependency and Licensing Rules

- Canonical project still opens directly from `project.godot` in Godot 4.7.1.
- No Blender, external AI model service, login, private environment variable, or addon is required to run the project.
- `.glb` remains the preferred future authored-model exchange format.
- Any committed external audio/model asset must include source URL, license, and modification notes.
- Real Starbucks/Luckin branding or trade dress remains out of scope; the presentation stays generic café-style.

## Definition of Done

V2 is ready to merge only when:

- the owner-reported 100%-but-still-attached failure has an automated regression test and visually correct implementation;
- final detach leaves the label entirely in the right hand;
- the right hand has a recognizable semi-realistic five-finger pinch pose and the left hand reads as holding the cup;
- label print deforms/moves with the label rather than remaining on the cup;
- real licensed Foley replaces synthetic placeholder audio as the normal path;
- fresh Godot 4.7.1 CI import, all deterministic tests, and scene smoke pass on exact PR head;
- merged `main` passes the same verification again;
- experiential quality is reported honestly as UNVERIFIED until the next local playtest.