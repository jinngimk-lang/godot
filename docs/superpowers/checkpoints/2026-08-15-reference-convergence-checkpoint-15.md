# Peel Calm reference convergence checkpoint 15

Date: 2026-08-15
Production baseline: `main@769d6452e75112084f537af99be90721c2629cd5`
Active spike: `spike/mpfb-hero-limb-finger-helper-v42`
Exact spike head before this checkpoint: `230577e70998fa6be785d82b567737dff6e485aa`

## Acceptance rule still in force

The user-approved café / amber-bar / clear-market references remain the visual acceptance target. Macro composition and hand/vessel silhouette outrank skin, paper-fiber, glass and other micro polish. A green workflow cannot rescue a visually bad pose.

## v40 — per-joint local-axis table rejected

Branch: `spike/mpfb-hero-limb-anatomical-grasp-v40`
Head: `a4f508858d973bd1263d91f307eed022d73a4305`
MPFB workflow: `31865606745` — PASS
Artifact: `9241958903`

All six candidates still read as hovering/prong/claw poses. Explicit per-joint imported-local XYZ tables did not solve palm enclosure or thumb opposition. This triggered the planned stop condition for local-axis parameter search.

## v41 — world/palm-derived per-bone bend planes rejected

Branch: `spike/mpfb-hero-limb-artist-grasp-v41`
Head: `84132042895984866837e910fffb166d996ed71a`
MPFB Artist Grasp run: `31868070481` — PASS
Artifact: `9242632689`
Godot Check: `31868070462` — PASS

The four artist-authored degree profiles used world/palm geometry instead of imported local XYZ axes, but the rendered fingers still formed long prongs and the thumb could collapse unnaturally. This proves that direct scripted rotation of GameEngine finger bones is itself the wrong abstraction, not merely the choice of axis.

### Do not repeat

- endpoint CCD / fingertip-error chasing;
- support-axis sweeps;
- independent waypoint chains;
- shared imported-local-axis authored curls;
- mixed-axis authored curls;
- per-joint imported-local-axis tables;
- direct world-derived per-bone hinge rotations on the GameEngine rig.

## v42 — native MPFB Finger Helpers is the first structural positive

Branch: `spike/mpfb-hero-limb-finger-helper-v42`
Head: `230577e70998fa6be785d82b567737dff6e485aa`
MPFB Finger Helper run: `31868425809` — PASS
Artifact: `9242711262`
Godot Check: `31868425826` — PASS

The v42 harness deliberately moved pose authority back into MPFB's canonical Default rig. `FingerHelpers` in `POINT` mode creates five fingertip helper controls and installs MPFB's own finger-chain IK rotation limits and locks. The harness moves only those targets around an artist-defined cylindrical fixture; it does not rotate finger bones directly and does not optimize endpoint error.

Three fixed candidates were captured:

- `finger_helper_v42_open.png`
- `finger_helper_v42_natural.png`
- `finger_helper_v42_deep.png`

### Visual result

For the first time in the MPFB sequence, all three candidates visibly bend the four fingers around the vessel instead of leaving them as parallel long prongs. `natural` is currently the strongest structural seed. The palm is near the vessel and finger closure reads as a grasp at thumbnail/Macro scale.

This is **PROMISING, not production-ready**. Current visible reds:

1. The diagnostic camera still includes torso/body and is not product-reference composition.
2. The vessel axis is diagnostic rather than the final upright cup/bottle orientation.
3. Several fingertips bunch/occlude on the near silhouette and need a cleaner around-the-back ordering.
4. Thumb opposition remains less legible than the four-finger wrap.
5. The pose exists on the MPFB Default rig with helper constraints; it has not yet been baked/transferred into the production GameEngine hero-limb asset or tested in Godot product camera.
6. R2 label pinch still needs its own native-helper target layout.

## Structural conclusion

The key variable was **pose authority**, not polygon count or a better guessed bone axis. MPFB's native anatomically constrained finger helper IK is materially more promising than directly rotating the simplified GameEngine finger chains.

## Next exact action

1. Freeze v42 `natural` as the first viable support-wrap seed; do not broaden parameter search.
2. Create a product-oriented staging render with an upright vessel, clean forearm crop and reference-like oblique camera so palm enclosure / thumb opposition can be judged without torso contamination.
3. Add one native-helper label-pinch pose where thumb/index converge on a real flap point while the remaining fingers keep a relaxed anatomical silhouette.
4. If those Macro/Meso gates pass, bake the evaluated Default-rig helper result into ordinary deform-bone transforms / an animation clip and export a right hero-limb candidate.
5. Import that candidate with Godot 4.7.1 and capture the same café/bar/market product-camera states against the XR baseline.
6. Only after real Godot frames improve R1/R2 should the MPFB limb be considered for production integration. Skin PBR / paper / glass Micro work remains deferred.
