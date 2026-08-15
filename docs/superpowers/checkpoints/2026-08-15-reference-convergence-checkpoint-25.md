# Peel Calm reference convergence checkpoint 25

Date: 2026-08-15
Production main baseline: `769d6452e75112084f537af99be90721c2629cd5`
Candidate branch: `spike/mpfb-hero-limb-manual-fk-v57`
Exact candidate head used for CI + visual artifacts: `90373e241a5395f76dc68f29328e3526ba5a0aec`

## Exact-head verification

- Godot Check: run `31883312589` — **PASS** on exact candidate head.
- Godot runtime capture artifact: `peel-calm-reference-frames`, artifact id `9246583297`.
- MPFB Manual FK v57: run `31883312686` — **PASS** on exact candidate head.
- Manual-FK visual artifact: `mpfb-manual-fk-v57`, artifact id `9246629417`.
- The MPFB workflow built the pinned GameEngine human, wrote one explicit 17-bone target-rig FK pose, persisted/reloaded it with the v49 pose format, rendered every authoring stage, and passed the non-retarget/non-solver contract.

The documentation commit containing this checkpoint is not the visual candidate. All evidence above belongs to candidate `90373e241a5395f76dc68f29328e3526ba5a0aec`.

## v57 hypothesis

After v54-v56 showed that geometry fitting, source-derived directions, and parameterized grasp construction can remain numerically plausible while visually wrong, v57 tested a stricter idea:

> A single explicit artist-authored FK table written directly onto the target MPFB GameEngine rig, with no XR/BVH/source transform, source direction, endpoint target, CCD, surface servo, contact optimizer, or angle sweep, can create a readable support grasp.

The candidate was intentionally staging-only and could not be promoted from technical success alone.

## Durable technical result

The infrastructure part succeeded and remains useful:

- one target-rig pose can be authored directly without source retarget contamination;
- exactly 17 right hero-limb bones are persisted;
- save -> clear -> reload remains bounded by the existing `<=1e-6` matrix gate;
- the workflow renders meaningful construction stages plus a 192x108 thumbnail;
- this makes it possible to identify the first authoring stage where the silhouette becomes wrong instead of judging only a final pose.

Do not discard this infrastructure.

## Visual review — REJECT

The candidate does **not** pass the locked Macro/Meso support-wrap gate.

### Macro

`manual_fk_v57_final_thumbnail.png` does not read as a hand wrapping a vessel. At thumbnail scale the vessel occupies the left side while the palm/finger group remains largely beside it on the right. There is no immediate enclosure silhouette and no clear thumb-vs-fingers opposition across the vessel.

### Stage-localized diagnosis

1. `manual_fk_v57_01_palm.png` — **first failure already present**.
   - Before any authored thumb/finger closure, the whole-hand/palm relationship to the upright vessel is wrong.
   - The hand reads as hanging beside the cylinder rather than approaching/straddling its near contour.
   - Therefore later digit values cannot rescue the grasp without first correcting whole-hand composition.

2. `manual_fk_v57_02_thumb.png` — no valid opposition.
   - Thumb folds locally but does not create a strong opposite-side clamp across the vessel.
   - The distal thumb shape reads pinched/twisted rather than naturally opposed.

3. `manual_fk_v57_03_index.png` — local curl worsens an already incorrect frame.
   - Index does not disappear naturally around the far vessel contour.
   - The result starts to read as isolated bent phalanges rather than a finger wrapping a surface.

4. `manual_fk_v57_04_middle_ring.png` — strong visual regression.
   - Long near-parallel finger chains extend across the lower frame.
   - Several joints form unnatural angular/kinked shapes.
   - This is not reference-style enclosure.

5. `manual_fk_v57_05_pinky.png` / `final` — no recovery.
   - Pinky does not resolve the silhouette.
   - Final remains a claw/side-touch pose instead of a human vessel wrap.

## Falsified conclusion

The v57 explicit 17-bone table is **visually rejected** even though both workflows are green.

More importantly, the staged evidence falsifies the idea that the next useful move is to keep editing all finger angles at once. The first failing abstraction is now earlier:

> **whole-hand palm/root placement and orientation relative to the vessel must pass before digit closure is authored.**

## Do not repeat

Do not return to:

- CCD / endpoint chasing;
- fingertip distance optimization;
- surface servo/contact optimizer;
- shared local-axis angle tables;
- geometric/reference-derived target directions as the primary grasp author;
- whole-hand orbit angle sweeps;
- copying XR/BVH/source transforms or source bone roll into the target rig;
- broad 17-joint FK edits while the palm stage itself still fails;
- using green CI or pose round-trip correctness to promote a visually failed grasp.

## Remaining reds

### R1 — Whole-hand support composition

Before any finger closure, establish a reference-readable target-rig frame:

- palm sits at the vessel near/side contour, not beside it with a visible gap;
- wrist/forearm flow enters the frame naturally;
- palm normal faces into/around the vessel rather than parallel to the image plane;
- the four finger roots are positioned so their future chains can travel behind the far contour;
- thumb root is left on the opposing near/upper side with room for opposition.

This is now the highest-impact red.

### R2 — Artist-authored local digit closure

Only after R1 passes, author thumb opposition first, then index, then middle/ring, then pinky. Freeze the last visually good stage after each addition. A later finger group must not destroy an earlier passing silhouette.

### R3 — Godot product-camera proof

Only after the staging thumbnail reads as a human wrap may the MPFB limb enter a Godot comparison scene against current XR hands under the locked cafe/bar/market product FOV and lighting.

### R4 — Peel-hand pinch

Remain deferred until support-hand Macro/Meso is credible.

### R5 — Micro realism

Skin PBR, paper fibers, glass optics, condensation, micro-roughness, and similar detail remain deferred while R1/R2 are open.

## Next exact action

Create a **palm-only v58** from this checkpoint:

1. keep the v49 durable target-rig pose infrastructure and pinned MPFB/Blender pipeline;
2. do not author thumb/index/middle/ring/pinky yet;
3. manually place/orient only `lowerarm_r` + `hand_r` and the staging vessel until the fixed-camera full image and 192x108 thumbnail show a plausible pre-grasp composition;
4. require the palm near-side contour and MCP/finger-root arc to overlap/straddle the vessel in a way that leaves a believable far-side path for at least index/middle/ring;
5. only after that single frame passes should a subsequent iteration add thumb opposition as a separate visual gate.

No production PR is warranted from v57. Keep `main` clean.
