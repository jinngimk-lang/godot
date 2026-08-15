# Peel Calm reference convergence checkpoint 34

Date: 2026-08-16
Production baseline: `main@769d6452e75112084f537af99be90721c2629cd5`
Staging branch: `spike/mpfb-hero-limb-artist-scene-v77`
Authoring-scene exact code head: `3ebf90dffa29d8dc039957163d99ee94227706b8`
Evidence-persist head: `9d3da724af13cf86cbbf51de0b60129a35b4dcbc`
Godot Check: run `31913070898` — PASS on exact code head
MPFB Artist Authoring Scene v77: run `31913070919` — PASS on exact code head
Authoring-scene artifact: `9254222066`
Locked acceptance references: `bar_v1`, `market_v1`

## Why this checkpoint exists

Checkpoint 33 rejected v76 and activated the escalation rule: stop scripting further fan/curl/solver searches and move to direct artist posing on the native GameEngine rig.

v77 does **not** claim R1 is visually solved. It closes the infrastructure gap required to perform the next abstraction safely and reproducibly.

## What v77 provides

A deterministic Blender/MPFB 2.0.17 authoring scene can now be regenerated from repository code:

`tools/build_mpfb_artist_authoring_scene_v77.py`

The scene reconstructs the verified staging baseline and saves:

- continuous native MPFB hand/wrist/forearm on the same GameEngine rig;
- pristine v65-B whole-hand placement;
- exact v74 visible opposing-thumb seed;
- locked vessel proxy and fixed diagnostic camera;
- wrist + three thumb bones explicitly marked as frozen;
- only the twelve index/middle/ring/pinky pose bones selected for direct editing;
- embedded `PEEL_CALM_V77_AUTHORING_GUIDE` Text datablock with locked-reference intent, forbidden solver paths, Macro/Meso gates and save rules;
- Outliner marker pointing to the guide;
- durable same-rig seed pose JSON;
- baseline with-vessel thumbnail/full frame and unobstructed anatomy frame;
- editable `.blend` in the workflow artifact.

The saved `.blend` in artifact `9254222066` is approximately 7 MB and is reproducible from source rather than being the only copy of project state.

## Verification

### Exact-head Godot

`31913070898` — PASS on `3ebf90d...`.

No production gameplay path was changed by v77.

### MPFB authoring scene

`31913070919` — PASS.

The workflow verifies:

- staging-only / not a production candidate;
- native GameEngine rig;
- no pose authored automatically in v77;
- no sweep, CCD, endpoint optimizer, contact servo or root-orbit motion;
- exactly 12 non-thumb edit bones;
- wrist + all three v74 thumb bones frozen;
- digits 2-5 were not changed while reconstructing v74 (`matrix max delta = 0.0`);
- frozen seed remains unchanged through `.blend` save (`matrix max delta = 0.0`);
- distal v74 thumb remains independently visible at approximately `12.053 px` outside the vessel projection at 192×108;
- the `.blend` is created and non-trivial;
- a second headless Blender invocation reopens the saved file and verifies the embedded reference/authoring contract.

### Infrastructure false start

The first v77 workflow run `31912922167` successfully built the scene but failed its structural gate because the report accidentally reused the pre-v74 thumb metric (`0 px`) rather than measuring the post-v74 pose.

This was a reporting/gate bug only. The scene itself was generated. The fix on `3ebf90d...` measures the thumb after v74 reconstruction without changing the scene or finger pose and passes both technical paths.

Do not treat the first run as a pose failure.

## Visual status

**R1 remains OPEN.**

The v77 images are intentionally the v74 authoring seed, not a new candidate. They inherit the already-known four-finger fist/clump failure and exist only as the before-state for direct authoring.

No product-camera staging, PR or merge is permitted from this seed.

## Reference-data audit

`art/acceptance_refs/v1/MANIFEST.md` remains locked.

- `bar_v1`: support hand firmly grips the bottle.
- `market_v1`: realistic large support hand steadies the bottle.

`reference_features.json` contains compressed multi-scale RGB/drift features, not explicit hand anatomical landmarks. It is useful for drift detection but cannot replace direct pose comparison to the locked images.

The original `bar_reference.png` and `market_reference.png` are still present in the project File Library and match the manifest's logical targets. They must remain acceptance references, never replaced by the v77 worksheet.

## Do not repeat

All checkpoint-33 prohibitions remain active. In particular:

- do not convert v77 into a parameter sweep;
- do not reintroduce CCD, endpoint chasing, contact servo or whole-hand orbit search;
- do not add another scripted scalar fan/curl solver because the authoring scene is now available;
- do not promote the v77 seed screenshots as reference targets;
- do not start Micro skin/PBR/paper/glass work while the support-grasp silhouette still fails.

## Next exact action

Use the v77 authoring scene as the new base and create **one direct artist-authored same-rig support pose**:

1. Keep wrist, palm/whole-hand placement, vessel, camera and v74 thumb frozen.
2. Edit the twelve selected non-thumb pose bones as one visual shape rather than solving targets.
3. Make index the lightest closure; middle, ring and pinky progressively wrap behind the vessel far contour.
4. Preserve distinct web spaces and knuckle flow; eliminate the forward spear, palm-under clump and blocky/kinked distal silhouettes.
5. Save the accepted pose using the durable same-rig partial-pose format.
6. Render with-vessel 192×108 + full frame and unobstructed oblique anatomy.
7. Reject unless thumbnail first-glance reads as a relaxed but firm human bottle-support grip **and** Meso anatomy is continuous/non-self-intersecting.
8. Only after that visual gate, stage it in actual Godot bar/market product cameras beside the current XR baseline and run an independent Challenger.

If a runtime cannot directly manipulate Blender Pose Mode, it may regenerate the v77 `.blend` and preserve the handoff, but must not substitute another automated parameter search for artist posing.

## Current red ranking

1. **R1 — direct reference-derived artist-authored support grasp** using the v77 native-rig authoring scene.
2. **R2 — Godot bar/market product-camera proof** against current XR baseline after R1 passes.
3. **R3 — peel-hand flap pinch choreography** on the continuous-limb pipeline.
4. Skin/forearm PBR and anatomical surface refinement.
5. Glass/liquid/ice optical cues.
6. Paper fibers, residue, lid/product microdetail.
7. HUD quietness/final presentation polish.

Production `main` remains untouched; no product PR is open from v76/v77 staging work.
