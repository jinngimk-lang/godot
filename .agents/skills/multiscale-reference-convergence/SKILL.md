---
name: multiscale-reference-convergence
description: Use when a Peel Calm visual, rendering, modeling, hand-pose, material, lighting, UI, camera, or interaction-state change is judged against the locked approved reference images.
---

# Multiscale Reference Convergence Skill

Use this skill whenever a visual, rendering, modeling, hand-pose, material, lighting, UI, camera, or interaction-state change is judged against approved reference images.

## Principle

Do not optimize the full-resolution image all at once. Treat reference matching as a coarse-to-fine image-pyramid problem so low-frequency mistakes are removed before high-frequency polish.

The hierarchy is:

1. **Macro / low-frequency** — composition, silhouette, camera/FOV, object occupancy, hand-to-object scale, dominant value blocks, background depth, scene identity.
2. **Meso / structural** — hand pose/contact, vessel proportions, label placement and lifted arc, material separation, glass/liquid readability, lighting direction, support-hand choreography, interaction-state continuity.
3. **Micro / high-frequency** — skin response, paper fibers, label torn edge, residue breakup, micro-roughness, condensation, glass highlight breakup, lid grooves, small reflections.

If a lower level fails, do not spend the iteration budget on a higher level.

## Mandatory loop

1. Read the newest Git checkpoint and exact branch head.
2. Recover the approved reference family and the latest real Godot runtime captures.
3. Build a conceptual image pyramid by inspecting the same pair at strongly reduced, medium, and native resolution.
4. Write the largest mismatch at each scale.
5. Rank by perceptual impact and choose the highest-impact red item.
6. Make one reversible implementation change plus an objective regression gate where possible.
7. Run exact-head Godot Check.
8. Capture affected runtime states from the exact candidate.
9. Compare Macro, Meso, then Micro again.
10. Reject code-green work if the runtime frame regressed.
11. Run an independent Challenger on the exact head.
12. Checkpoint the evidence before merge/context transition.

## Image-pyramid review

### Macro

Review a strongly downsampled frame first. A useful target is about 48–96 pixels wide or a similarly small thumbnail. Judge:

- hero-object screen occupancy and center;
- hand/palm size relative to cup or bottle;
- silhouette and negative space;
- camera/FOV and perspective;
- forearm entry direction;
- dominant light/dark blocks;
- background depth and venue identity.

If the reference reads as a hand wrapping a bottle at thumbnail size while the game reads as a pointing/open hand, hand choreography is a Macro failure regardless of material quality.

### Meso

Then judge:

- thumb/finger opposition;
- real contact versus hovering;
- wrist transition;
- vessel shoulder/neck/lip or cup taper;
- label curvature/thickness/lift arc;
- residue placement;
- glass/liquid/ice separation;
- main highlight/shadow placement;
- continuity across partial-peel, inspection and crumple steps.

### Micro

Only after the first two levels pass, inspect:

- skin roughness/specular and normal detail;
- nail response;
- paper fibers and torn edges;
- adhesive breakup;
- condensation;
- glass highlight structure;
- lid molding/grooves;
- micro-roughness and subtle shadows.

## Metrics

Metrics are diagnostics, not acceptance by themselves. Prefer perceptual/structural measures over raw pixel equality. Useful evidence includes:

- multi-scale SSIM-style structural comparison;
- LPIPS-style perceptual feature comparison when available;
- silhouette/edge overlap;
- landmark ratios such as vessel height / viewport height and palm span / vessel width;
- contact-point distances;
- temporal/state continuity.

Never let a favorable scalar metric override a visible reference mismatch.

## Interaction-state matrix

For a tactile change, inspect the affected interaction states, not just idle. Depending on the work, include:

- untouched/base;
- hover/contact;
- first lift;
- partial peel;
- stressed pull/residue;
- near/final release;
- inspection yaw;
- crumple stages for paper cup;
- reset/next item/scene switch.

The exact interaction-step frame is part of the product contract.

## Model escalation

If the same Macro/Meso model red survives two evidence-backed iterations, stop polishing around the model and enter a model-pipeline spike.

Candidate assets/generated models remain staging inputs until they pass:

- provenance and rights;
- topology/retopology;
- bounded polygon/material budget;
- PBR provenance;
- scale/origin;
- useful rig/pose path when deforming;
- Godot 4.7.1 import;
- performance;
- direct target-camera screenshot comparison.

Do not infer production safety from an open-source code repository; model weights/assets may have separate terms.

## Checkpoint contract

Every stable or context-boundary checkpoint must contain:

- exact branch/head;
- main/base head;
- CI run ID;
- screenshot artifact ID;
- reference family/version;
- frames inspected;
- Macro/Meso/Micro before/after findings;
- failed experiments that must not be repeated;
- remaining reds ranked;
- next exact action.

## Anti-drift

- Approved references are locked targets, not mood boards.
- Runtime captures are evidence, never replacement references.
- A new generated image may be a derived step/explanatory reference, but may not silently redefine acceptance.
- Do not polish Micro while Macro/Meso is visibly wrong.
- Do not add speculative features while hero-frame mismatch remains obvious.
- Do not claim success from CI alone.
- Do not continue a model-search path after its configured stop condition has been reached.
