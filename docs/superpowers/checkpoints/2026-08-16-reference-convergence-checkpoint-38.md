# Peel Calm reference convergence checkpoint 38

Date: 2026-08-16
Production main remains: `769d6452e75112084f537af99be90721c2629cd5`
Staging branch: `spike/contactpose-water-bottle-reference-v80`
Verified staging head before evidence/checkpoint docs: `780e9fbf2bd79453174eedd6e253136a8e281497`
ContactPose Water Bottle Reference v80: run `31920195819` — PASS
Godot Check at same exact head: run `31920195834` — PASS
ContactPose artifact: `9256129666`
Source staging integration: PR #50 merged into v80 only; **not main**.

## Acceptance references remain locked

No acceptance target changed. Final visual judgment is still against repository-locked `bar_v1` / `market_v1` for bottle support, plus `cafe_v1` for the paper-cup family. ContactPose is anatomical reference evidence only; it cannot replace the approved images.

## What this loop changed

The previous checkpoint left R1 blocked on direct visual authoring of the native MPFB GameEngine rig. Repeated code-authored pose routes had already been rejected: CCD, endpoint chasing, surface servo, shared-axis curl, per-joint angle tables, whole-hand orbit sweeps, screen-space tail authoring, blind fixed Euler artist-FK, and wine-glass source-direction transfer.

This loop changed the evidence source instead of reopening those parameter searches.

A ContactPose probe was verified on the latest checkpoint-37 lineage. It reads the public Explorer `water_bottle` 21-joint annotations and **does not use MANO code/models or ContactPose object meshes**. ContactPose documents code and non-3D-model data under MIT; MANO remains a separate license boundary and is intentionally excluded.

The probe found:

- 96 public `water_bottle` annotation files;
- 137 valid real-human 21-joint hand skeletons;
- both `use` and `handoff` grasps;
- three orthogonal palm-local skeleton sheets for the 12 strongest triage candidates.

The full durable text evidence is now in:

`docs/superpowers/evidence/2026-08-16-contactpose-water-bottle-anatomy-v80.md`

so the anatomical conclusions no longer depend solely on an expiring Actions artifact.

## Highest-value visual/anatomical finding

The top real `water_bottle` candidate (`full1_use`, hand 0) has a pronounced sequential closure grammar:

- index flex ≈ 30.6°
- middle flex ≈ 42.2°
- ring flex ≈ 49.0°
- pinky flex ≈ 60.6°
- digit depth span ≈ 1.45 palm widths
- fingertip depth span ≈ 0.65 palm widths

The real grasp sheet makes the repeated MPFB failures easier to explain: natural support is not four similar fingers curling or fanning in one screen plane. The finger chains occupy different palm-normal depths, with ulnar digits generally closing more deeply, while thumb opposition is a separate relationship.

This is not a new numeric optimizer target. The numbers diagnose the anatomy; the locked Peel Calm references remain the visual gate.

## R1 status

**R1 is not closed.**

What is closed is an evidence gap: we now have object-matched real human water-bottle grasp anatomy rather than relying on a wine-glass pose or guessed finger grammar.

The existing native-rig artist ingest gate remains valid and was deliberately not weakened. A technical PASS still cannot set a visual PASS.

## Routes that remain forbidden

Do not restart:

- CCD / endpoint target minimization;
- contact-distance servo as pose authoring;
- shared-axis or per-joint axis sweeps;
- whole-hand orbit-angle sweeps;
- fingertip tolerance relaxation;
- screen-space tail-pixel numeric authoring;
- blind fixed Euler tables;
- direct destructive BVH import into the GameEngine hero rig;
- MANO production dependency;
- treating ContactPose ranking score as acceptance.

## Next exact action

Use the real ContactPose bottle grasp as a **read-only ghost/landmark guide** in the native MPFB GameEngine authoring scene:

1. Freeze the existing continuous MPFB hand–wrist–forearm, vessel proxy, product-intent camera, wrist and current usable thumb seed.
2. Add the selected ContactPose 21-joint skeleton as non-deforming visual guide geometry/empties, aligned in palm scale and vessel-relative orientation.
3. Do not let the guide directly write production bone transforms and do not run an optimizer.
4. Pose the native GameEngine rig visually so index → middle → ring → pinky reproduce the real depth ordering and enclosure grammar while matching `bar_v1` / `market_v1` camera intent.
5. Render with-vessel 192×108 Macro and unobstructed oblique Meso evidence.
6. If Macro first reads as a natural stable bottle grasp and Meso anatomy is clean, pass the resulting same-rig `.blend` through the checkpoint-37 artist ingest gate.
7. Only then enter real Godot bar/market product-camera comparison against the current XR baseline and run independent Challenger.

If the environment still cannot directly manipulate native Blender pose bones, do **not** return to numeric pose search. Improve the visual-authoring bridge/guide instead, preserving this real-grasp evidence for the next capable posing step.

## Lower priorities remain frozen

R2 product-camera replacement proof, R3 peel-hand pinch, skin PBR, paper fibers, glass optics and condensation remain below R1 until support grasp passes Macro/Meso.
