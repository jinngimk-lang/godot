# Peel Calm reference convergence checkpoint 33

Date: 2026-08-16
Production baseline: `main@769d6452e75112084f537af99be90721c2629cd5`
Staging branch: `spike/mpfb-hero-limb-finger-wrap-v76`
Visual-candidate exact head: `dc3bbf7bb613c91c0ab064b57d974cc08da0834e`
Evidence-persist head: `e7012922bcbb157a73b7ce69a4d1b2c2cc3c9558`
Godot Check: run `31912578754` — PASS on candidate exact head
MPFB Finger Wrap v76: run `31912578824` — PASS on candidate exact head
MPFB visual artifact: `9254101473`
Locked acceptance references: `bar_v1`, `market_v1`

## Highest-impact red

**R1 — the support hand still does not read as a natural human vessel wrap at Macro/Meso scale.**

The distal thumb from v74 remains independently visible, but index/middle/ring/pinky still form a compact fist/claw-like near-side clump rather than a progressive relaxed wrap around the bottle. Micro skin/material work remains frozen.

## What v76 tested

Checkpoint 32 required exactly one non-thumb candidate before abandoning code-authored angle guessing. v76 followed that rule:

- started from pristine v65-B and reconstructed the exact v74 distal-thumb screen-space authoring;
- froze wrist and all three thumb bones;
- kept vessel, camera, crop and whole-hand placement unchanged;
- made one deterministic four-finger correction only;
- reduced the inherited v65 MCP fan and added progressively deeper closure from index to pinky;
- did **not** use a parameter sweep, CCD, endpoint optimizer, contact servo, root/orbit motion or Micro/material changes;
- persisted the same-rig canonical pose plus vessel and unobstructed evidence frames.

## Infrastructure false start — not a visual verdict

The first MPFB run `31912478343` failed before pose rendering because `_reconstruct_v74()` incorrectly passed `arm.parent` to the v73 static-mesh diagnostic. The MPFB armature has no parent, so this produced `AttributeError: 'NoneType' object has no attribute 'modifiers'`.

This was fixed without changing any v76 pose parameter by passing the actual MPFB basemesh. The corrected candidate is exact head `dc3bbf7...`. The failed-run artifact `9254058991` is logs only and must not be treated as visual evidence.

## Exact-head technical result

The corrected exact candidate passed both independent technical paths:

- Godot Check `31912578754` — PASS;
- MPFB Finger Wrap v76 `31912578824` — PASS;
- structural gate confirmed frozen wrist/thumb matrices (`max_abs_delta = 0.0`) and retained visible v74 distal thumb (`12.053 px` outside the vessel projection at 192×108).

Technical green does **not** override the visual gate.

## Real-frame visual verdict — REJECT

Evidence persisted under `docs/superpowers/evidence/mpfb-v76/`:

- `support-wrap-thumbnail.png`
- `support-wrap-with-vessel.png`
- `support-wrap-anatomy-thumbnail.png`
- `support-wrap-anatomy-oblique.png`
- `finger-wrap-v76.json`
- `support-wrap-v76-canonical-pose.json`

### Macro

**FAIL.** At 192×108 the hand still reads as a tight fist/claw mass adjacent to the bottle, not as the relaxed but firm support grip seen in `bar_v1` / `market_v1`. The thumb is visible, but thumb visibility alone does not create a readable opposing grasp.

### Meso

**FAIL.** In the unobstructed oblique frame:

- index still protrudes as a long forward digit;
- middle/ring/pinky are crowded beneath/against the palm instead of forming a clean progressive hierarchy;
- several distal silhouettes look blocky or sharply kinked;
- the four non-thumb digits do not form a believable far-side vessel enclosure.

### Quantitative diagnostic

The screen-space metrics corroborate that the single correction did not create the required ordering:

| digit | before | after | interpretation |
|---|---|---|---|
| index | right outside `4.420 px`, inside fraction `0.9649` | right outside `4.468 px`, inside `0.9585` | essentially unchanged / slightly worse |
| middle | all inside vessel X projection | all inside | no meaningful enclosure change |
| ring | left outside `12.159 px`, inside `0.8677` | left outside `11.813 px`, inside `0.8742` | only marginal movement |
| pinky | left outside `26.930 px`, inside `0.4272` | left outside `28.030 px`, inside `0.4239` | worsened |

These are diagnostics only; the visual failure is decisive.

## Closed hypothesis

**Rejected:** “The remaining support-grip problem can be solved by one more scripted fan/curl correction on the v65/v74 pose.”

The v76 one-shot candidate failed both Macro and Meso, so checkpoint 32's escalation rule is now active.

## Do not repeat

Do **not** start v77 as another angle/fan/curl sweep or another scripted finger solver. Existing rejected families now include:

- CCD / endpoint chasing / contact servo;
- shared/local-axis parameter searches;
- whole-hand orbit search;
- wine-glass/source-direction pose transfer;
- isolated thumb scalar sweeps;
- screen-space thumb-only authoring beyond the already retained v74 seed;
- scripted scalar MCP-fan + per-joint curl correction such as v76;
- Micro skin/PBR/paper/glass polish while R1 remains obvious.

## Reference-set audit

`art/acceptance_refs/v1/MANIFEST.md` remains LOCKED. It still requires:

- `bar_v1`: support hand firmly grips the bottle;
- `market_v1`: realistic large support hand steadies the bottle.

`reference_features.json` currently contains compressed multi-scale image features useful as drift detectors, but no explicit anatomical hand landmarks. It cannot substitute for direct reference-space hand posing.

The original `bar_reference.png` and `market_reference.png` remain available in the project File Library with the hashes recorded in the manifest; staging/runtime images must not replace them.

## Next exact action

Change abstraction rather than searching more numbers:

1. Freeze the verified v74 thumb, vessel proxy, camera, wrist/forearm and continuous MPFB/GameEngine hero limb.
2. Build a **native GameEngine-rig artist-authoring scene/worksheet** with the non-thumb chains exposed for direct pose editing and with the locked reference intent documented alongside the scene.
3. Author the four non-thumb chains as a whole silhouette, not through target-point or angle search: index least closed, middle/ring/pinky progressively wrap behind the vessel far contour, with clean finger separation and continuous knuckle flow.
4. Save the successful result through the existing durable same-rig partial-pose format rather than copying BVH bone roll/rest transforms.
5. Render the exact fixed vessel thumbnail plus unobstructed oblique anatomy view.
6. Only if Macro enclosure and Meso anatomy pass, enter real Godot café/bar/market product-camera staging against the current XR baseline and run Challenger.

If the current execution environment cannot directly manipulate Blender pose controls interactively, spend the next reversible step on making that authoring scene reproducible and evidence-safe; do not fall back to automated angle sweeps simply because they are easier to script.

## Current red ranking

1. **R1 — reference-derived artist-authored support grasp** on the continuous MPFB hand/wrist/forearm.
2. **R2 — Godot product-camera proof** against current XR baseline after R1 passes staging.
3. **R3 — peel-hand label-pinch choreography** using the same continuous-limb pipeline.
4. Forearm/hand skin PBR and anatomy refinement.
5. Glass optical cues and liquid/ice readability.
6. Paper fibers, residue breakup, lid/product microdetail.
7. HUD quietness and final presentation polish.

Production `main` remains untouched by the v76 staging experiment. No production PR should be opened from this rejected candidate.
