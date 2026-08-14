---
name: peel-calm-reference-realism
description: Use for Peel Calm visual, interaction, venue, product, hand, label, material, or tactile changes that must preserve the approved café/bar/market reference-frame feeling.
---

# Peel Calm Reference Realism

## North star

Every visible change must answer: **does the viewport feel more like a believable tactile moment with a real object in a real place?** Prefer coherent scene/product/light/material/interaction packages over isolated polish.

The approved reference feeling is the product standard, not inspiration to drift from. Rendering, modeling, hand posing, materials, camera framing, interaction staging, and UI must converge toward concrete visual evidence.

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

## Mandatory visual-convergence ladder

For every rendering, modeling, animation, hand-pose, material, lighting, interaction-staging, UI, or scene-composition problem, do not jump straight from prose to code.

1. **Target frame** — establish or generate a concrete image that shows the intended final feeling. It may be an approved user reference, an intentionally generated concept frame, or a previous runtime frame that already meets the bar.
2. **Step frames** — if the feature changes over time, establish concrete images for the important interaction states. Typical peel work uses at least: untouched, grip/edge-lift, mid-peel, rough/partial tear, detached-with-residue, inspect rotation, and post-peel finish.
3. **Implementation** — model and code toward those frames. Do not let convenient primitive geometry redefine the target.
4. **Exact-head runtime capture** — capture the real Godot viewport from the candidate SHA for every canonical venue and every changed interaction state.
5. **Side-by-side audit** — compare target vs runtime for composition, product proportions, silhouette, camera distance/FOV, hand anatomy, contact points, label location, peel shape, residue shape, material separation, roughness/specular response, lighting direction, shadow softness, background depth, color temperature, HUD hierarchy, and motion continuity.
6. **Mismatch ledger** — write objective mismatches as concrete defects (for example: `bar bottle shoulder 18% too wide`, `right thumb misses label by ~25 px`, `market background contrast competes with bottle`, `residue edge too uniform`). Do not write vague notes such as `make prettier`.
7. **Iterate** — fix the highest-impact mismatch, capture again, and repeat until remaining differences are either intentional product decisions or owner-only subjective comfort gates.

A green test suite without runtime frame evidence is not enough for visual work. A beautiful static frame that breaks input, reset, accessibility, or deterministic state is also not enough.

## Engineering loop

1. State the user-perceived defect.
2. Establish target/step frame evidence when the defect is visible or interaction-shaped.
3. Add or adjust a test that fails for the missing deterministic behavior when applicable.
4. Run CI and confirm the expected RED.
5. Implement the smallest coherent architecture change.
6. Run full CI, smoke, and reference-frame capture.
7. Inspect captures against the visual-convergence ladder and update the mismatch ledger.
8. If any load-bearing criterion is weak, iterate instead of declaring polish complete.
9. Run an independent exact-head Challenger before merge; the Challenger must inspect both code evidence and captured frames for visual tasks.

## Definition of done

Functional green is necessary but insufficient. The three canonical capture frames must each be identifiable as Café / Bar / Market without reading the HUD, the product material must match the venue/product profile, the core peel/inspect controls must work without a hotspot, and changed visual states must have target-vs-runtime comparison evidence with no unresolved load-bearing mismatch.
