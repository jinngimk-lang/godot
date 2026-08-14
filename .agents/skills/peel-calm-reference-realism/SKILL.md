---
name: peel-calm-reference-realism
description: Use for Peel Calm visual, interaction, venue, product, hand, label, material, or tactile changes that must preserve the approved café/bar/market reference-frame feeling.
---

# Peel Calm Reference Realism

## North star

Every visible change must answer: **does the viewport feel more like a believable tactile moment with a real object in a real place?** Prefer coherent scene/product/light/material/interaction packages over isolated polish.

## Three canonical moods

- Café: takeaway paper cup, walnut table, large warm windows, café depth, soft paper residue.
- Bar: amber bottle, dark reflective counter, back-bar shelves, amber practicals, torn fibrous label.
- Market: clear citrus bottle, pale counter, cooler shelves, cool white light, crisp commercial packaging.

## Interaction invariants

- label surface is the hit target; never require the gold hotspot;
- LMB/touch owns peel, RMB owns inspection and may not steal peel input;
- bond load has damping/hysteresis; brief spikes do not instantly release;
- gentle pull preserves integrity; abuse increases residue;
- visual residue derives from deterministic model state;
- paper may crumple after peel; glass never does;
- Q/E and 1/2/3 switch showcase scenes safely.

## Visual invariants

- product is centered and readable; hands frame rather than occlude it;
- venue geometry must establish place in silhouette before decoration;
- materials must differentiate paper, plastic, glass, label, residue, wood/stone;
- use generic/non-branded props;
- HUD is concise and secondary;
- avoid high-frequency clutter, harsh camera motion, timers, punishment, or casino-style reward UI.

## Engineering loop

1. State the user-perceived defect.
2. Add/adjust a test that fails for the missing behavior.
3. Run CI and confirm the expected RED.
4. Implement the smallest coherent architecture change.
5. Run full CI, smoke, and reference-frame capture.
6. Inspect captures for composition, venue readability, material separation, hand/product coherence, and UI restraint.
7. If any criterion is weak, write the next falsifiable test/acceptance check and iterate.
8. Run an independent exact-head Challenger before merge.

## Definition of done

Functional green is necessary but insufficient. The three capture frames must each be identifiable as Café / Bar / Market without reading the HUD, the product material must match the venue/product profile, and the core peel/inspect controls must work without a hotspot.