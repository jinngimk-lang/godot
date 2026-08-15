# Peel Calm reference convergence checkpoint 26

Date: 2026-08-16
Production baseline: `main@769d6452e75112084f537af99be90721c2629cd5`
Active staging branch: `spike/mpfb-hero-limb-rest-delta-v62`
Open production PRs: none

## Recovered baseline

Checkpoint 25 closed the remaining uncertainty around the v55/v60 artist-FK family: corrected camera focus preserves the intended durable 17-bone pose, but the pose still fails visually. Do not reinterpret those failures as camera-reset artifacts.

## v61 — source-frame swing/twist representation

Branch: `spike/mpfb-hero-limb-swing-twist-v61`
Exact authored/workflow head: `18627ccf4da5440658bc924dc013dee94fc45f7e`
Persisted evidence bot head: `980b083aa7d7bd03049efb8f15ed6c58d1a69bcd`
Godot Check: run `31896835806` — PASS
MPFB Swing Twist v61: run `31896835869` — PASS
Artifact: `9250052193` (`mpfb-swing-twist-v61`)

### Hypothesis

Source-direction-only transfer discarded a roll/bend-plane degree of freedom. v61 therefore transferred source posed phalanx direction as SWING and reconstructed a bounded TWIST from the source bend plane while keeping the GameEngine target rest/edit structure untouched.

### Technical result

PASS:

- official MakeHuman Community Poses 01 holding-object source inspected as CC0 staging reference;
- continuous MPFB GameEngine target built successfully;
- source edit-bone roll was not copied;
- source pose matrices were not copied;
- no target solver or contact servo was used;
- target rest/edit structure remained unchanged;
- 17-bone durable pose save/reload passed;
- same authored head passed the full Godot 4.7.1 suite.

### Visual result — REJECT

The real 192×108 render is substantially worse than the desired support-wrap silhouette:

- two major fingers become abnormally long, nearly horizontal parallel bars;
- another chain hangs downward;
- the hand does not read as enclosing the vessel;
- thumb opposition is not a readable counter-grip.

The report also shows multiple reconstructed twist values saturating the ±48° bound. The bend-plane reconstruction is therefore not a stable representation for this source/target pair.

**Do not tune the v61 twist bound or create a twist-angle sweep.** The representation is rejected.

## v62 — source-rest to target-rest local rotation-delta transfer

Branch: `spike/mpfb-hero-limb-rest-delta-v62`
Exact authored/workflow head: `ca4f698a4711ef0b71d941658c895c326225f69d`
Persisted evidence bot head before this checkpoint: `5cb7becc2346cc3f96515837d1649d2842063439`
Godot Check: run `31897066024` — PASS
MPFB Rest Delta v62: run `31897066065` — PASS
Artifact: `9250108449` (`mpfb-rest-delta-v62`)

### Hypothesis

Instead of reconstructing roll from geometric bend planes, read the sacrificial CC0 BVH's complete first-frame local pose rotation delta and conjugate that delta through source-rest -> target-rest local orientation alignment. Keep lowerarm/hand whole-placement fixed; clear only the 15 digit bones before applying the mapped deltas. Never copy source edit-bone roll or source matrices.

### Technical result

PASS:

- source declared CC0 and remained sacrificial/staging-only;
- source edit-bone roll not copied;
- source pose matrix not copied verbatim;
- target rest/edit structure error remained zero;
- no CCD, endpoint target, contact servo, direction solver, swing/twist reconstruction or search sweep;
- durable v49 pose contains the expected 17 target bones and reloads within the existing matrix gate;
- full Godot 4.7.1 suite passed on the exact authored head.

### Visual result — PROMISING REPRESENTATION, REJECTED CANDIDATE

This is the first candidate in the recent sequence with a clear Macro improvement:

- at 192×108 the palm is visibly beside the vessel;
- the four digits move toward/around the vessel contour rather than remaining long parallel bars;
- the silhouette begins to read as a support wrap rather than a pointing/open hand.

However the full/Meso render is not production-credible:

- several joints and fingertips collapse into blocky/folded shapes;
- visible finger chains self-intersect and overlap unnaturally;
- skin deformation around the phalanges reads as broken rather than smoothly flexed;
- thumb opposition is still not a clean reference-like counter-grip.

Therefore v62 does **not** enter Godot product-camera staging yet. Preserve the representation because it improved Macro, but reject the current pose as a production candidate.

## What the new evidence changes

R1 is no longer simply “find any representation that curls the fingers.” v62 shows that complete local pose-delta transfer carries useful grasp structure, while target/source local frame mismatch still corrupts Meso anatomy.

The highest-value next step is to preserve v62's full source rotation information but change how source and target local coordinate frames are related.

## Do not repeat

In addition to checkpoint 25's list, do not return to:

- v61 per-joint bend-plane twist reconstruction;
- tuning the v61 ±48° twist cap;
- a grid/sweep over swing/twist weights;
- treating v62's Macro improvement as sufficient for Godot gameplay integration;
- reducing the problem to contact distance or fingertip radial error.

## Current reds

### R1 — Meso-safe anatomical frame transfer for the continuous support hand

Highest priority. Preserve v62's promising whole-hand enclosure, but remove broken joint silhouettes/self-intersection.

### R2 — product-camera proof

Still blocked. Enter actual café/bar/market Godot cameras only after staging thumbnail **and** full Meso anatomy pass.

### R3 — peel-hand pinch

Still blocked behind support hand.

### R4+ — Micro detail

Skin PBR, paper fiber, glass, residue and condensation remain frozen.

## Next exact action

Create one new isolated representation experiment, not a parameter sweep:

1. Keep v62's source CC0 holding-object pose, target GameEngine rig, whole-hand placement, vessel fixture, camera, durable v49 pose format and visual gates unchanged.
2. Replace edit-roll-derived local-frame conjugation with a **coherent anatomical frame per digit**. Build each digit's semantic rest frame from:
   - the phalanx rest direction;
   - a stable palm/digit-plane normal shared coherently across the chain;
   - the resulting orthogonal binormal.
3. Express the source local pose delta in that semantic frame and re-express it in the corresponding target semantic frame. Do not infer a separate noisy plane per joint.
4. Preserve source angle/magnitude; do not start a damping/curl grid.
5. Assert target rest/edit matrices remain unchanged and durable reload remains exact.
6. Render full + 192×108 and visually compare directly against v62.

Promotion criterion:

- retain v62's thumbnail enclosure improvement;
- remove blocky/broken phalanx silhouettes and major self-intersection;
- show a readable opposing thumb;
- only then proceed to Godot product-camera comparison and independent Challenger.
