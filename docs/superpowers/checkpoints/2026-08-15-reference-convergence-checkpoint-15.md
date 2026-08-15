# Peel Calm reference convergence checkpoint 15

Date: 2026-08-15
Production baseline: `main@769d6452e75112084f537af99be90721c2629cd5`
Working branch: `spike/mpfb-hero-limb-pinky-distal-v44`
Verified visual-candidate head before this checkpoint: `bd453a8ef930b6a51f51304a2cb9654a48f9a7c9`
Godot Check: run `31869751111` — PASS
Godot runtime frame artifact: `peel-calm-reference-frames`, artifact id `9243086059`
MPFB Pinky Distal v44: run `31869751138` — PASS
MPFB visual artifact: `mpfb-pinky-distal-v44`, artifact id `9243120536`

## Locked acceptance references

The acceptance set remains unchanged and must not drift:

- `cafe_v1` — Window café / paper cup peel
- `bar_v1` — Warm dark bar / amber bottle peel
- `market_v1` — Convenience cooler / clear citrus bottle peel

The canonical hashes and intent remain in `art/acceptance_refs/v1/MANIFEST.md`. Runtime captures and MPFB staging renders are evidence only and must never replace the locked references.

## Why this checkpoint exists

The hand-model spike crossed a useful structural boundary in v42-v44. Earlier local-axis, endpoint, CCD and angle-table experiments could make numerical contact while producing claws, twisted phalanges or ribbon-like ring/pinky chains. The new world-space segment-direction abstraction materially improved the support-hand silhouette, and v43-v44 localized and reduced the remaining pinky deformation. The experiment is still not ready for production because the whole hand does not yet read as a firm reference-quality vessel wrap.

## v41 — artist hinge angles rejected

Branch: `spike/mpfb-hero-limb-artist-grasp-v41`
Head: `84132042895984866837e910fffb166d996ed71a`
MPFB run: `31868070481` — PASS
Artifact: `9242632689`
Godot Check: `31868070462` — PASS

Visual result:

- index/middle remained too straight;
- ring/pinky produced severe chain/twist deformation;
- thumb opposition remained weak;
- green CI did not make the candidate acceptable.

This closed the path of continuing to tune imported-bone hinge-angle tables.

## v42 — first useful world-space segment-direction grasp

Branch: `spike/mpfb-hero-limb-world-arc-v42`
Head: `63c49c2de6fce488380015edb9dea81265330a41`
MPFB World Arc run: `31869274557` — PASS
Artifact: `9242990710`
Godot Check: `31869274504` — PASS

Hypothesis:

Instead of rotating each imported MPFB pose bone around an assumed local bend axis, align the current world-space phalanx segment to an explicit desired world-space tangent around a cylindrical vessel. This removes imported local X/Y/Z roll conventions from the meaning of the authored pose.

Visual result:

- **first meaningful structural gain in this spike**;
- index/middle/ring changed from broad twisted strips into much cleaner cylindrical human finger volumes;
- global hand/wrist continuity from the MPFB limb remained intact;
- remaining dominant deformation became concentrated in the pinky;
- thumb and overall enclosure still did not pass Macro/Meso reference quality.

Important conclusion: shortest-arc world segment alignment is a materially better abstraction than shared local-axis angle tables for this rig.

## v43 — pinky-local radial frame partially succeeds

Branch: `spike/mpfb-hero-limb-pinky-basis-v43`
Head: `ab76fa288c8ed68bb9b55ee0ac6e446642b41eb7`
MPFB Pinky Basis run: `31869529206` — PASS
Artifact: `9243060405`
Godot Check: `31869529164` — PASS

Hypothesis:

The pinky starts from a different radial location around the vessel than the index-derived/global palm frame. Give only the pinky an MCP-derived radial/tangent basis while freezing index/middle/ring/thumb to the useful v42 soft/opposed pose.

Visual result:

- the catastrophic folded pinky block reduced;
- the pinky chain became more anatomically continuous;
- changing pinky axial drop from `-0.08` through `-0.12` made little useful visual difference;
- the distal phalanx still kinked sharply.

Important conclusion: the pinky needed a digit-local radial frame, but axial-drop tuning was not the remaining solution.

## v44 — terminal pinky closure isolated

Verified visual-candidate head: `bd453a8ef930b6a51f51304a2cb9654a48f9a7c9`
MPFB run `31869751138` — PASS
Artifact `9243120536`
Godot Check `31869751111` — PASS
Runtime frames artifact `9243086059`

The v43 local pinky frame and axial drop `-0.08` were frozen. Only the terminal pinky wrap angle changed:

- `distal58`
- `distal66`
- `distal74`
- `distal82`

Visual result:

- the ugly terminal pinky kink is substantially reduced across the set;
- `distal66` is the current best staging compromise: cleaner anatomical continuity than v43 without the increasingly tight curl of 74/82;
- the improvement is local and real, but the whole support-hand silhouette still does **not** immediately read as a firm reference-quality vessel wrap;
- index/middle/ring remain too extended in the diagnostic view;
- thumb opposition is still not strong enough to establish a convincing grip around the vessel.

### Closed sub-red

**Catastrophic pinky-chain twisting is no longer the dominant support-hand failure.** Freeze the v44 `distal66` morphology unless product-camera evidence proves it wrong.

## Current reds, ranked

### R1 — Whole-hand vessel enclosure / thumb opposition

The MPFB limb is continuous and individual finger deformation is materially healthier, but the support pose still reads too open. The next question is not another distal-finger angle search. The palm/root approach and thumb-versus-finger opposition must match the actual approved reference-camera geometry.

### R2 — Product-camera proof

The current Blender diagnostic cylinder/camera is useful for anatomy debugging but is not the final product framing. Before promoting the MPFB candidate, it must be judged using the real café/bar/market composition or a derived staging camera that reproduces the locked reference hand/object relation. A pose that only looks plausible from the diagnostic side view does not pass.

### R3 — Peel-hand / label-pinch choreography

This v42-v44 loop addressed support-hand grasp only. The peel hand still needs a separate whole-hand approach + thumb/index flap-pinch solution. Do not infer success from the support-hand work.

### R4 — Skin/PBR, paper, glass and other Micro polish

Still intentionally deferred. Do not spend the next iteration on skin pores, paper fibers, condensation or glass highlight breakup while R1/R2 remain visible.

## Reference-derived next action

Before another broad pose algorithm experiment, re-ground the support hand in the locked reference intent:

1. Keep v44 `distal66` as the pinky seed; freeze the cleaned index/middle/ring world-space segment method.
2. Derive the next support-hand test from the actual reference relationship rather than an arbitrary stronger curl:
   - palm on the near/lateral side of the vessel;
   - visible fingers should wrap toward/behind the far contour instead of pointing across the image plane;
   - thumb must occupy the opposing side/upper contact zone so the silhouette reads as a grip at thumbnail scale;
   - wrist/forearm approach must enter naturally from the frame edge.
3. Prefer one or two reference-camera/root/thumb hypotheses over another large angle grid.
4. Render at strongly downsampled Macro scale first. Reject any candidate that still reads as an open/claw hand before product integration.
5. If a reference-derived support candidate passes Macro/Meso, export/freeze it and place it in a Godot staging scene using the actual product FOV and vessel geometry, side-by-side with the current XR baseline.
6. Only after that product-camera gate should production hand replacement begin.

## Do not repeat

- endpoint-distance optimization as the primary pose objective;
- CCD / surface-servo loops that produce numerically good but claw-like hands;
- shared local-axis flexion tables;
- broad X/Y/Z axis searches;
- broad pinky axial-drop sweeps;
- stronger generic curl merely because contact metrics improve;
- material/lighting polish intended to hide an open or anatomically wrong grasp.

## Continuity rule

The next session must begin from this checkpoint, verify current main and exact candidate CI/artifacts, and continue the highest-impact Macro/Meso hand red. No product merge is authorized from v44 alone; the candidate has not yet passed reference-camera support-wrap or independent visual Challenger gates.
