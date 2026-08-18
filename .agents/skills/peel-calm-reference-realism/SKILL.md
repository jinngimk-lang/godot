---
name: peel-calm-reference-realism
description: Use when changing Peel Calm peeling feel, paper or adhesive behavior, label materials, tactile audio, product presentation, scene separation, screenshots, or acceptance evidence after feedback that the label feels like soft tape or the venues look reused.
---

# Peel Calm Reference Realism

## Authority

This skill is the current owner-level direction for the object-only Peel Calm workstream. It supersedes older presentation assumptions that rely on visible hands/arms or full-screen reference-video playback to make the scene look convincing.

**Current invariant:** real-time Godot object + label interaction remains visible and authoritative. Do not hide weak mechanics behind hands, a still frame, or video overlay.

Before work, read:
- `CURRENT_HANDOFF.md` in this skill directory;
- `docs/superpowers/checkpoints/2026-08-18-paper-resistance-and-scene-separation.md`;
- `docs/superpowers/checkpoints/2026-08-18-substrate-peel-feel-v4.md`;
- current production code/tests and exact `main` head.

## Owner intent

The peel should feel **resistant, paper-like, deliberate, and satisfying**, not soft, elastic, weightless, or self-releasing. Treat the complaint “像随时会掉下来的胶带” as a blocking defect, not polish.

Do not ask the owner for normal reversible implementation choices. Search, inspect, test, generate reference/template assets when useful, implement, capture, compare, reject weak directions, and continue until the acceptance gates are met. Do not stop because an arbitrary iteration count was reached; respect repository safety/round guards, but a green test batch alone is not visual acceptance.

## Mechanical truth

The runtime path is:

`new outward pointer work -> stored bond load -> breakaway threshold -> local peel-front release -> load relax -> next increment`

Never regress to `cursor held away -> progress increases every frame`.

Required behavior:
- stationary pointer under load stalls progress;
- first movement visibly loads/bends paper before meaningful release;
- initial breakaway is stronger than running peel;
- release has restrained deterministic stick-slip variation;
- sideways/inward motion does not grant free peel progress;
- most bending is confined to a narrow peel-front band;
- the released arm behaves mainly as a stiff sheet, not a rubber membrane;
- `progress == 1.0` means the whole printed label is off the vessel.

## Paper material truth

A paper label needs three readable layers:
1. printed fibrous front;
2. opaque matte backing with visible thickness/edge;
3. adhesive/residue response on the vessel.

Preserve micro-fiber roughness/normal response. Avoid translucent, glossy, gelatinous, or two-sided-print tape appearance.

Substrate ordering must remain perceptibly different unless new evidence justifies changing it:

`rustic jar paper > tin / coffee > coated Yuzu > thin soda wrap`

for pointer work / stiffness, with thin soda wrap the most compliant.

## Tactile audio

Audio supports mechanical state; it does not fake progress.
- `EDGE_LIFT` / `PINCHED`: quiet paper/adhesive loading is audible before release;
- active peel: continuous adhesive texture remains background-level;
- `paper_flex`, `micro_release`, and `final_release` remain foreground tactile events;
- inactive/released states do not hiss continuously.

## Five-scene rule

Coffee Shop, Jar, Tin Can, Supermarket, and Can must read as **five different places/products from screenshots with HUD hidden**. Changing only the hero mesh, label text, or tint is failure.

Use scene-specific composition, source plate or geometry, crop, depth, contact surface, lighting direction/color temperature, practicals, reflections, and product material response. Reusing a source image is acceptable only if the final scenes are immediately distinguishable; unique environment assets are preferred when reuse still reads as the same room.

## Engineering loop

1. State the user-perceived defect in observable terms.
2. Add a falsifiable test/acceptance check and confirm the intended RED when practical.
3. Make the smallest coherent mechanics/material/scene change.
4. Run Godot 4.7.1 import, default launch, deterministic tests, and interaction smokes.
5. Capture every scene at attached / representative mid-peel / 100% released.
6. Inspect the images, not only logs. Reject changes that are technically green but still look soft, fake, reused, or attached at 100%.
7. Iterate on the next highest-impact defect.
8. Merge only exact-head verified work; after merge, distinguish pre-merge evidence from separately verified merged-main evidence.

## Acceptance gate

Do not call this direction finished while any of these fail:
- static hold still creeps forward;
- peel has no visible/audible loading phase;
- free label stretches like tape instead of moving as paper;
- paper lacks front/back/thickness/fiber separation;
- 100% leaves a printed patch attached;
- residue/paper separation is visually ambiguous;
- any two of the five venues look like the same place with a swapped prop;
- hands/arms or full-screen playback are used as a workaround;
- screenshots were not inspected after the latest exact head.

Functional green is necessary. Convincing paper feel and scene identity are the actual product bar.