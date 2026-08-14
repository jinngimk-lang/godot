# Peel Calm reference convergence checkpoint 02

Date: 2026-08-14
Branch: `feat/reference-multiscale-loop-v1`
Exact verified head before checkpoint: `dc8be19d43df60486a8c5eaf8d3da7406393da10`
Godot Check: run `31789831870` — PASS
Capture artifact: `peel-calm-reference-frames`, artifact id `9214994480`

## Process improvements persisted

- Added `.agents/skills/multiscale-reference-convergence/SKILL.md`.
- Added long-horizon Master Prompt under `docs/superpowers/prompts/`.
- Added execution addendum covering reference versioning, generate/annotate-before-coding, capability acquisition, quantitative diff artifacts, two-strike model escalation, and anti-self-deception completion checks.
- Autonomous recurring loop prompt was updated to use coarse-to-fine Macro/Meso/Micro reference convergence and Git checkpoint recovery.

## Visual loop result

### Macro

Improved:

- untouched peel hand is staged farther from the label instead of permanently pinching empty air over the hero object;
- bar and market support hands are staged closer to their bottle and turn with the inspection yaw;
- café crumple support-hand ownership remains isolated, preventing reset drift;
- Q/E and 1/2/3 controller replacement no longer leaves the choreography layer reading stale controller state.

Still acceptable but not final:

- overall hero-object framing is close enough that the hand asset is now the highest-salience mismatch.

### Meso

Improved:

- glass-scene support hand is closer to an actual vessel wrap;
- peel hand no longer competes with the label in the untouched base frame;
- presentation responsibilities are more explicit: café crumple owns café support-root staging; glass hand choreography owns glass support-root staging.

Remaining red:

- finger silhouette and pose quality still read as XR/VR stock hands;
- right-hand `Pinch Up` silhouette remains claw-like;
- support `Cup` pose adds flexion but is not anatomically photographic enough at the current close camera;
- hand/wrist/forearm transition still reads as assembled presentation pieces rather than a continuous hero limb.

### Micro

Remaining red:

- obvious faceting / low-frequency polygon planes in fingers and palm;
- flat skin shading and simplified nail response;
- skin lacks the subtle normal/roughness breakup visible in the target reference family.

## Regression discovered and fixed

Initial choreography implementation caused `smoke_ritual_loop.gd` to fail:

`RITUAL_RED: next item must restore exact support-hand staging baseline`

Root cause:

- the new generic support-hand layer and existing `CrumpleHandStaging` both wrote the café support-hand root;
- the crumple layer stored one baseline while the choreography layer interpolated to another.

Fix:

- café support-root staging remains exclusively owned by `CrumpleHandStaging`;
- `HandChoreographyPresentation` only stages support roots in non-crumpling glass venues;
- the peel-hand untouched composition still applies in all venues.

A second lifecycle defect was caught proactively:

- PeelLab recreates `PeelController` on variant selection;
- choreography now refreshes its controller reference every frame so scene switching cannot use stale input state.

## Model escalation decision

The same hero-hand quality red has survived multiple evidence-backed iterations (scale, forearm replacement, pose selection, support-follow, and composition staging). Per the two-strike escalation rule, stop trying to solve this with more lighting/position tweaks.

### Candidate pipeline research

1. **MakeHuman**
   - official MakeHuman documentation says exported models are CC0 and may be used commercially;
   - bundled MakeHuman assets repository is CC0;
   - promising as a legally clean higher-resolution human/hand/forearm source with rigged anatomy;
   - requires a practical export/crop/retarget path before adoption.

2. **TRELLIS / TRELLIS.2**
   - useful image-conditioned 3D research/staging option;
   - current official repositories advertise MIT licensing, but exact model/dependency terms must be rechecked at time of use;
   - generated hands would still require retopology, rigging/weight transfer, PBR, and pose validation, so this is not automatically superior to a human base-mesh pipeline.

3. **InstantMesh**
   - useful single-image reconstruction research/staging option;
   - official project is Apache-2.0 code, with model/checkpoint terms requiring separate verification;
   - static reconstructed hands are not sufficient unless a robust rig/retopology path is also solved.

## Next exact action

Open a dedicated high-fidelity hand/forearm model spike from this verified head.

Priority order:

1. assess whether a MakeHuman-derived CC0 hand/forearm with game rig can be produced reproducibly;
2. if available environment cannot run that pipeline directly, add a reversible CI/staging workflow or import a provenance-clean prebuilt candidate;
3. compare candidate vs current authored XR hands using identical café/bar/market base + peel frames;
4. reject candidate if it does not materially improve silhouette/anatomy at thumbnail and medium scale;
5. only after geometry/pose wins, tune PBR skin/nail detail.

Do not merge a new hand asset without provenance, import, performance, exact-head CI, and real-frame evidence.
