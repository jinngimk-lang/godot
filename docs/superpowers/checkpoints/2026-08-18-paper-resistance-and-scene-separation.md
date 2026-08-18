# Paper Resistance + Scene Separation Checkpoint

## Owner feedback that overrides previous polish assumptions

The current no-hands direction is correct, but two failures remain blocking:

1. The label reads like soft tape: too compliant, too willing to follow the cursor, and too willing to keep releasing once tension exists. It does not feel like a paper label with bending stiffness and adhesive resistance.
2. The five product selections do not read as five places because the previous backdrop system reused the same source images across multiple profiles.

Do not solve either problem by reintroducing hands or by returning to full-screen video/still playback.

## Mechanical translation

Use these implementation rules as the tactile north star:

- A stationary cursor under load must **stall** peel progress. Progress requires new outward displacement/work.
- The first few pixels build bond load and bend the paper before appreciable adhesive release.
- The release curve should feel stick-slip rather than linear time accumulation: stronger initial peak, then a steadier lower release load, with small deterministic micro-variation.
- Most visible bending belongs in a narrow band at the peel front. The free paper arm should move nearly as a stiff sheet rather than stretch vertex-by-vertex like rubber.
- The paper must have visible thickness/backing/edge response. Adhesive residue remains on the container; the paper itself does not look translucent or gelatinous.
- Mid-peel gameplay progress may be visually compressed so the label identity remains readable, but `progress == 1.0` must visually detach the **entire** label.
- Completion transitions into a released/held sheet where the paper is visibly off the vessel. A 100% HUD with a still-attached patch is a hard failure.

## Research grounding

Official peel-adhesion standards explicitly note that measured peel force changes with peel rate, and that backing stiffness plus adhesive rheology affect the measured response. The implementation therefore models different responsibilities explicitly rather than treating the label as elastic tape.

The qualitative runtime path is:

`cursor displacement -> stored load -> threshold crossing -> local front release -> load relax -> next increment`

not

`cursor held far away -> progress increases every frame`.

## Implemented v3 mechanics

- `PeelModel.step()` now accepts a bounded release-motion gate. Bond load can remain stored while the cursor is stationary, but adhesive release and damage only advance with new release motion.
- `PeelController` projects pointer-relative motion onto the active pull direction. Sideways/inward or zero movement does not advance the peel front.
- The release curve has a higher initial peak plus deterministic micro-resistance so the first breakaway feels stronger than the running peel.
- `CornerPeelPresentation` maps mid-progress conservatively for readable labels, then ramps the final section to **100% visual detachment**.
- The bend zone is limited to a narrow 14% front band. Beyond it, detached vertices converge rapidly to a tangent sheet instead of stretching continuously.
- Released paper now has a separate opaque matte fibrous backing surface with visible thickness. The printed front is no longer rendered as a two-sided transparent/tape-like sheet.
- CI captures three states for each object: attached, representative mid-peel, and 100% released.

## Five-scene separation

Each scene has a deterministic visual signature using source plate, crop/scale/offset, color grade, lighting, foreground surface/contact shadow, and depth treatment.

Current directions:

1. **Coffee Shop** — warm window café, kraft cup, warm walnut/contact surface.
2. **Jar** — warm bar/pantry crop with orange kitchen-like light, glass/sauce hero.
3. **Tin Can** — grocery/cold-case plate with warmer neutral grade, industrial metal emphasis.
4. **Supermarket** — bright refrigerated convenience-store/cold-case, cool white light.
5. **Can** — tighter beverage-bar crop with cooler cyan rim/fill, distinct from Supermarket.

The old grouped mapping (`pantry_*` sharing one look and `market_*` sharing one look) is not acceptable even if source photography is reused. Final rendered signatures must remain visibly distinct.

## Verification history

- RED run `32114604504`: proved the original soft-tape behavior advanced by ~0.35 progress while the cursor was held still; it also lacked completion/stiffness/scene-signature helpers.
- GREEN run `32115039675` at `9647d45...`: import, default launch, deterministic tests, all interaction smokes, and five scene-pair captures passed after displacement-gated release + stiff-sheet mapping.
- GREEN run `32115311358` at `bbd8334...`: upgraded capture gate passed with 15 images (attached / mid / 100% released for all five scenes), proving no attached printed patch remains at 100%.
- GREEN run `32115618336` at `a16ded2...`: same full suite passed after stronger five-scene backdrop/lighting separation.
- RED run `32115812769`: intentionally added the paper-backing material contract and failed only because the explicit backing had not yet been implemented. The next exact-head run must prove this new material gate green.

## Acceptance gate

A build is not acceptable until all of the following are true in an exact-head Godot run:

- holding the mouse still does not continue peeling;
- the first pull visibly loads/bends before release;
- mid-peel paper reads as a stiff sheet with a localized bending front;
- the released sheet has a matte opaque paper backing rather than two-sided print/tape;
- 100% progress leaves no attached printed patch;
- residue remains on the vessel after release;
- Coffee / Jar / Tin / Supermarket / Can are immediately distinguishable from a screenshot with UI labels hidden;
- no visible hands/arms;
- no full-screen gameplay video/still overlay;
- all existing pause/reset/rotation/zoom/scene-switch smokes remain green.

## Recovery instruction

If context is lost, read this file immediately after `2026-08-18-realtime-reference-rebuild-v2-design.md`. This checkpoint supersedes any earlier assumption that a soft continuously-deforming flap, two-sided printed sheet, or reused grouped backdrop is visually acceptable.
