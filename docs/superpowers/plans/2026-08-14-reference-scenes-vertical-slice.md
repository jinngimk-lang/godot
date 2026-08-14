# Reference Scenes Vertical Slice — Delivery Plan

## Goal

Move Peel Calm from the brown-room prototype to the approved three-mood vertical slice: Café paper cup, Bar amber bottle, Market clear citrus bottle. The delivery must change both visible presentation and the interaction substrate.

## Task order

1. **Lock contracts in tests**
   - reference product/venue matrix;
   - label-wide grab region;
   - damped bond load + integrity/residue;
   - RMB inspection controller;
   - venue/product/residue presentation semantics.
   - Confirm CI RED for missing production contracts.

2. **Deterministic tactile core**
   - port/adapt damped `PeelModel`;
   - expose quality fields through `PeelController`;
   - add `set_grab_region(Rect2)` and direct press-anywhere lift;
   - preserve completion monotonicity and old reset/input invariants.

3. **Reference profile model**
   - three `SessionModel` variants with `scene_profile`, `container_profile`, `post_peel_action`;
   - add direct showcase `select_variant` while leaving earned progression counters intact.

4. **Inspection and transform correctness**
   - add `InspectionController`;
   - route RMB independently of `PointerAdapter`;
   - rotate base body/lid/label/product/residue coherently;
   - convert all label local/world coordinates explicitly.

5. **Presentation replacement**
   - replace scene-bound `CafePresentation` in the main scene with `VenuePresentation`;
   - procedural café/bar/market landmarks and distinct lighting/table materials;
   - add `ProductPresentation` for paper/amber/clear silhouettes;
   - add `ResidueVisual` driven only by model quality output.

6. **HUD + navigation**
   - minimal top-left identity/progress/quality;
   - concise controls line;
   - Q/E + 1/2/3 navigation with safe reset/quarantine;
   - glass products remain inspectable after detach; paper retains optional crumple.

7. **Regression and visual verification**
   - full existing Godot Check;
   - new integrated smoke for all three scenes and navigation;
   - optionally add Xvfb capture artifacts for all three 1280×720 frames if runner support proves reliable;
   - inspect screenshots, then tune camera/light/material density if venue identity or foreground readability is weak.

8. **Independent challenge**
   - repair/install local Challenger workflow if default-branch dispatcher references a missing workflow;
   - open exact-head PR;
   - dispatch paid + local Challenger; paid credit failure is infrastructure evidence, not a VERIFIED verdict;
   - require at least the local independent model or equivalent independent reviewer to produce a structured verdict;
   - reproduce any concrete defect with a failing test before fixing.

## Acceptance criteria

- Any visible label location can start a peel.
- Brief force spikes do not instantly release; sustained gentle pull does.
- Rough pull increases residue and lowers integrity.
- RMB rotates product without taking over LMB/touch.
- Café/Bar/Market are visually identifiable without HUD text.
- Paper/amber/clear product silhouettes and materials are visibly different.
- Q/E and 1/2/3 switch scenes deterministically.
- Existing pause/reset/ritual/session protections remain green.
- No real brands or external runtime dependencies.
- Full CI green at exact PR head plus independent challenge evidence.