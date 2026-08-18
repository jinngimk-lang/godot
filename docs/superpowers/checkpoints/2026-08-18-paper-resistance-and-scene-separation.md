# Paper Resistance + Scene Separation Checkpoint

## Owner feedback that overrides previous polish assumptions

The current no-hands direction is correct, but two failures remain blocking:

1. The label reads like soft tape: too compliant, too willing to follow the cursor, and too willing to keep releasing once tension exists. It does not feel like a paper label with bending stiffness and adhesive resistance.
2. The five product selections do not read as five places because the current backdrop system reuses the same source images across multiple profiles.

Do not solve either problem by reintroducing hands or by returning to full-screen video/still playback.

## Mechanical translation

Use these implementation rules as the tactile north star:

- A stationary cursor under load must **stall** peel progress. Progress requires new outward displacement/work.
- The first few pixels build bond load and bend the paper before appreciable adhesive release.
- The release curve should feel stick-slip rather than linear time accumulation: stronger initial peak, then a steadier lower release load, with small deterministic micro-variation.
- Most visible bending belongs in a narrow band at the peel front. The free paper arm should move nearly as a stiff sheet rather than stretch vertex-by-vertex like rubber.
- The paper must have visible thickness/backing/edge response. Adhesive residue remains on the container; the paper itself does not look translucent or gelatinous.
- Mid-peel gameplay progress may be visually compressed so the label identity remains readable, but `progress == 1.0` must visually detach the **entire** label.
- Completion should transition into a short release/fall/held state where the paper is visibly off the vessel. A 100% HUD with a still-attached patch is a hard failure.

## Research grounding

Official peel-adhesion standards explicitly note that measured peel force changes with peel rate, and that backing stiffness plus adhesive rheology affect the measured response. The implementation should therefore expose distinct paper stiffness / adhesion / rate-response parameters per substrate instead of treating every label as the same elastic tape.

The model does not need laboratory units; it needs the same qualitative constraints:

`cursor displacement -> stored load -> threshold crossing -> local front release -> load relax -> next increment`

not

`cursor held far away -> progress increases every frame`.

## Five-scene separation

Each scene must have a deterministic visual signature. A signature can include source texture, crop/scale/offset, color grade, lighting, foreground surface/contact shadow, and background depth treatment.

Required directions:

1. **Coffee Shop** — warm window café, kraft cup, warm walnut/contact surface.
2. **Jar** — warm kitchen/pantry, tomato/herb cues, neutral cream/wood counter.
3. **Tin Can** — grocery pantry / canned-goods shelf, more industrial neutral light and brushed metal emphasis.
4. **Supermarket** — bright refrigerated convenience-store/cold-case, cool white light.
5. **Can** — chilled drink display / urban convenience café, cooler cyan daylight or evening display; must not be the same framing/grade as Supermarket.

The current `ReferenceBackdrop` reuse (`pantry_* -> cafe`, `market_can -> market`) is explicitly obsolete.

## Acceptance gate

A build is not acceptable until all of the following are true in an exact-head Godot run:

- holding the mouse still does not continue peeling;
- the first pull visibly loads/bends before release;
- mid-peel paper reads as a stiff sheet with a localized bending front;
- 100% progress leaves no attached printed patch;
- residue remains on the vessel after release;
- Coffee / Jar / Tin / Supermarket / Can are immediately distinguishable from a screenshot with UI labels hidden;
- no visible hands/arms;
- no full-screen gameplay video/still overlay;
- all existing pause/reset/rotation/zoom/scene-switch smokes remain green.

## Recovery instruction

If context is lost, read this file immediately after `2026-08-18-realtime-reference-rebuild-v2-design.md`. This checkpoint supersedes any earlier assumption that a soft continuously-deforming flap or reused backdrop is visually acceptable.
