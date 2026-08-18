---
name: peel-calm-reference-realism
description: Use when changing Peel Calm peeling feel, paper or adhesive behavior, label materials, tactile audio, product presentation, scene separation, screenshots, or acceptance evidence after feedback that the label feels like soft tape, visual direction may drift, or venues look reused.
---

# Peel Calm Reference Realism

## Authority

This skill is the current owner-level direction for the object-only Peel Calm workstream. It supersedes older presentation assumptions that rely on visible hands/arms or full-screen reference-video playback to make the scene look convincing.

**Current invariant:** real-time Godot object + label interaction remains visible and authoritative. Do not hide weak mechanics behind hands, a still frame, or video overlay.

## Mandatory recovery read

Before work, and again whenever context is long/compacted, a handoff occurs, direction feels uncertain, or a major pivot is proposed, read in this order:

1. `.agents/PROJECT_NORTH_STAR.md` — persistent whole-project memory and current owner bar;
2. `CURRENT_HANDOFF.md` in this skill directory;
3. `docs/superpowers/checkpoints/2026-08-18-paper-resistance-and-scene-separation.md`;
4. `docs/superpowers/checkpoints/2026-08-18-substrate-peel-feel-v4.md`;
5. current production code/tests, workflows, newest captures and exact `main` head.

Conversation memory is not authoritative when it conflicts with current repository evidence. If a verified owner-level direction, merged milestone, acceptance rule, or major next-work priority changes, update `.agents/PROJECT_NORTH_STAR.md` so the next agent can recover without this chat.

## Owner intent

The peel should feel **resistant, paper-like, deliberate, and satisfying**, not soft, elastic, weightless, or self-releasing. Treat the complaint “像随时会掉下来的胶带” as a blocking defect, not polish.

Do not ask the owner for normal reversible implementation choices. Search, inspect, test, generate reference/template assets when useful, implement, capture, compare, reject weak directions, and continue until the acceptance gates are met. Do not stop because an arbitrary iteration count was reached; respect repository safety/round guards, but a green test batch alone is not visual acceptance.

The owner’s completion bar is **100% precise fidelity to the approved target within the controllable real-time Godot scope**. “Looks good”, “close enough”, “CI green”, “85–90%”, or exhaustion/iteration count are not completion criteria. If some target property is inherently non-identical because the target is static/generated and runtime is real-time, state the irreducible difference explicitly and continue eliminating all controllable deltas.

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

## Image-first visual convergence

When a concrete visual solution exists, **make the intended result visible before implementing it in Godot**.

Required loop:

1. Create a practical target image/artifact first: generated reference, mockup, composite, paintover, layout board, or equivalent. It must show the intended final framing, object scale, peel state, UI placement, environment identity, light/material mood and major silhouettes.
2. Extract observable constraints from it: object bounds/position, label size, peel corner/angle, UI regions, background structure, major light direction, material cues.
3. Implement that target as real-time Godot scene/material/interaction work. Never use the target itself as a full-screen gameplay overlay.
4. Capture a directly comparable Godot runtime frame at the same state/resolution where practical.
5. Build a side-by-side/contact-sheet comparison; use quantitative image differences when useful for framing/color/alignment, but do not let a low metric hide structural or tactile defects.
6. Name the largest remaining mismatch and iterate that layer.
7. Repeat target -> Godot -> capture -> compare until the controllable output meets the owner’s 100% precision bar.

If an agent has “a good idea” but has not yet made a concrete target image or comparable visual artifact, the visual solution is not yet specified enough for high-confidence Godot convergence.

## Engineering loop

1. Re-read `.agents/PROJECT_NORTH_STAR.md` if continuity is at risk.
2. State the user-perceived defect in observable terms.
3. For visual work, create/refresh the practical target image before implementation.
4. Add a falsifiable test/acceptance check and confirm the intended RED when practical.
5. Make the smallest coherent mechanics/material/scene change.
6. Run Godot 4.7.1 import, default launch, deterministic tests, and interaction smokes.
7. Capture every affected scene at attached / representative mid-peel / 100% released.
8. Compare runtime captures against the practical target. Inspect images, not only logs.
9. Reject changes that are technically green but still look soft, fake, reused, poorly aligned, or attached at 100%.
10. Iterate on the next largest mismatch; update persistent memory when direction/progress materially changes.
11. Merge only exact-head verified work; after merge, distinguish pre-merge evidence from separately verified merged-main evidence.

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
- a visual idea was implemented without first forming a concrete target artifact;
- the newest runtime frame was not explicitly compared to that target;
- the largest controllable target/runtime delta is still visibly unresolved;
- the agent is relying on long-chat memory instead of rereading the persistent repository north star;
- screenshots were not inspected after the latest exact head.

Functional green is necessary. Convincing paper feel, scene identity, and target-to-runtime convergence are the actual product bar.