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
8. Capture the full reference-frame matrix, including interaction states, not just base scenes.
9. Compare again at all three scales.
10. Repeat until lower-scale reds are closed; only then move to fine detail.
11. Before long-context/tool transitions, save a checkpoint containing head SHA, CI run/artifact IDs, fixed reds, remaining reds, and next action.

## Comparison guidance

Raw pixel equality is not the acceptance criterion because small camera/lighting shifts can increase pixel error while improving perceptual likeness. Prefer structural/perceptual concepts:

- Multi-scale SSIM for structure across viewing scales.
- LPIPS-style learned feature similarity for perceptual likeness.
- Silhouette/edge overlap for vessel and hand geometry.
- Explicit landmark ratios for camera and composition: vessel height/viewport height, hand span/vessel width, label center/hero-object center, support-contact location.

Metrics support the visual review; they do not replace it.

## Model escalation rule

If the same macro/meso geometry red survives two evidence-backed iterations, stop polishing around the bad model and enter a model-pipeline spike.

Candidate staging tools to evaluate:

- **TRELLIS / TRELLIS.2** — image-conditioned 3D generation; official Microsoft repository, MIT-licensed project/model according to its repository. Use only after confirming the exact dependency/model-card licenses in the chosen version.
- **InstantMesh** — efficient single-image sparse-view reconstruction; official TencentARC repository, Apache-2.0 code. Confirm checkpoint/model licenses separately before production use.
- **TripoSR** — single-image reconstruction; MIT-licensed repository. Confirm model-weight and dependency licenses before production use.

Do not make Hunyuan3D a default production dependency: its published license contains territory/distribution restrictions. It can be studied as research, but production adoption requires a separate rights review.

External/generated 3D is staging input, never automatic production output. Require:

- source/provenance record;
- commercially compatible rights;
- clean silhouette and useful topology;
- retopology/decimation target;
- UVs and PBR materials;
- rig/weights or a documented pose path for hands;
- bounded polygon/material counts;
- Godot 4.7.1 import;
- frame-time check;
- direct runtime-frame comparison against the references.

## Hand-specific acceptance

Hands are tactile hero assets. A candidate hand is not accepted merely because it has more polygons.

At macro scale: palm/forearm size, crop, and cup/bottle relationship must match the reference.

At meso scale: support fingers must wrap the vessel; thumb and fingers should visibly oppose each other around the surface; peel thumb/index must meet the actual flap; wrist transition must read as anatomy or believable clothing rather than a tube.

At micro scale: normals, skin roughness/specular response, nails, creases, and shading must not expose faceting at the target camera distance.

## Research anchors

- Wang, Simoncelli, Bovik, “Multi-scale Structural Similarity for Image Quality Assessment” (2003): https://ece.uwaterloo.ca/~z70wang/publications/msssim.html
- Zhang et al., “The Unreasonable Effectiveness of Deep Features as a Perceptual Metric” (LPIPS, 2018): https://arxiv.org/abs/1801.03924
- Microsoft TRELLIS: https://github.com/microsoft/TRELLIS
- Microsoft TRELLIS.2: https://github.com/microsoft/TRELLIS.2
- TencentARC InstantMesh: https://github.com/TencentARC/InstantMesh
- TripoSR: https://github.com/VAST-AI-Research/TripoSR
