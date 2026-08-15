# Peel Calm reference convergence checkpoint 21

Date: 2026-08-15
Production main baseline: `769d6452e75112084f537af99be90721c2629cd5`
Working branch: `spike/mpfb-hero-limb-direct-fk-v52`
Prior checkpoint baseline: `spike/mpfb-hero-limb-manual-support-v51@6472728706b7b609c95537650e61fff88ded3551`

## Locked acceptance references

Unchanged:

- `cafe_v1`
- `bar_v1`
- `market_v1`

Runtime captures and Blender staging renders remain evidence only and cannot redefine acceptance.

## R1 status

**R1 — believable continuous support hand / wrist / forearm remains OPEN.**

Macro/Meso hand choreography still blocks Micro skin, paper-fiber, glass-highlight and condensation work.

## v52 — explicit per-bone FK, no support solver

Branch candidate head: `2b6f34e53d0bb29b5042274fb48330c1bd0b45d2`
Godot Check: run `31878291474` — PASS
MPFB Direct FK v52: run `31878291463` — PASS
Artifact: `9245354385`

v52 was deliberately a single fixed candidate, not a parameter sweep. It introduced:

- `tools/author_mpfb_direct_fk_v52.py`
- `.github/workflows/mpfb-direct-fk-v52.yml`

The 17 durable GameEngine hero-limb bones are assigned an explicit fixed local-FK delta table. Machine gates require:

- `automatic_retarget = false`
- `retarget_source_transforms_used = false`
- `target_solver_used = false`
- `bend_toward_center_used = false`
- `pose_bone_count = 17`
- `explicit_fk_bone_count = 17`
- pose save → clear → reload matrix error `<= 1e-6`

This closes the implementation-risk question raised by checkpoint 20: the project can author and persist a support-hand candidate without CCD, endpoint chasing, surface servo, `_bend_toward_center`, world-direction closure, or destructive BVH retargeting.

### First v52 render — diagnostically INVALID

The first full/thumbnail render placed the proxy vessel far away from the posed palm. The hand and vessel occupied separate sides of the frame, so the result could not answer the grasp question. This was a staging-fixture failure, not a valid visual rejection of the FK pose.

No hand matrix was changed in response.

## v52b — same hand matrices, corrected palm-adjacent fixture

Corrected exact head: `fd95ce8da68aa82ef7a853afd7b32fb77293cb07`
Godot Check: run `31878475702` — PASS
MPFB Direct FK v52b: run `31878475774` — PASS
Corrected evidence artifact: `9245400079`
Artifact digest: `sha256:64ae25469779340335138c21fb7bf581c9913c2c7318624f323dfc6c49e23143`

v52b changes only staging geometry. `tools/author_mpfb_direct_fk_v52b.py` replaces proxy placement with a vertical vessel fixture derived from the already-posed palm. It does not mutate a hand bone or alter the v52 FK table.

Frames inspected:

- `direct_fk_v52_candidate.png`
- `direct_fk_v52_thumbnail.png`

### Visual result — REJECT

The corrected fixture makes the Macro/Meso failure unambiguous:

- the vessel is now adjacent to the hand, so the grasp can be judged;
- the visible finger mass still reads as several long, mostly parallel digits hanging beside the vessel rather than wrapping it;
- the thumb does not form a clear opposing mass on the near/upper side;
- the visible fingers do not disappear behind the vessel far contour in a way that reads as enclosure;
- the thumbnail reads as `hand beside/touching vessel`, not `hand wrapping vessel`;
- therefore the candidate does not pass the locked R1 gate even though both exact-head workflows are green.

**Do not promote v52/v52b to Godot product-camera staging or production.**

## Structural conclusion

Checkpoint 20 correctly rejected solver-derived support authorship. v52 proves that merely replacing the solver with a blind per-joint Euler-delta table is still insufficient when the authoring process does not have an anatomically reliable control representation.

The problem is now narrower:

> Pose persistence works, continuous MPFB anatomy works, Godot verification works, and solver-free FK assignment works. The missing layer is a reliable anatomical authoring/control space that allows an artist-authored palm + thumb + finger enclosure to be expressed without guessing opaque GameEngine local Euler axes.

Current MPFB source/docs provide pose-orientation utilities and a pose format for static bone rotations, but external MakeHuman BVH poses have a known bone-roll mismatch with MPFB rigs. Therefore the v50 BVH remains a visual anatomy guide only; do not copy its rotations into the hero GameEngine rig.

## Do not repeat

In addition to checkpoint 20:

- do not run another blind 17-bone local-Euler angle table expecting a natural grasp;
- do not treat proxy-placement fixes as pose improvement;
- do not promote a pose because the durable matrix contract is green;
- do not use external BVH rotations directly on the GameEngine rig;
- do not return to CCD / endpoint / surface-servo / `_bend_toward_center` / world-direction solver families;
- do not start Micro material polish while the support silhouette still fails at 192x108.

## Next exact action

Create an isolated **anatomical-control authoring spike** rather than another grasp-angle sweep.

1. Keep the stable MPFB 2.0.17 GameEngine human and the durable v49 partial-pose asset format.
2. Build a diagnostic authoring representation for the 17 hero-limb bones that exposes each joint in anatomical terms (flexion/extension, abduction/adduction, thumb opposition) instead of raw unexplained XYZ Euler deltas.
3. Derive that representation from the GameEngine rig's own rest/pose orientation and MPFB orientation metadata; do not import BVH bone rolls.
4. Use the v50 holding-object close-up only to visually author one fixed target: palm beside vessel, thumb opposed, index/middle/ring/pinky progressively wrapping behind the far contour.
5. Persist the resulting GameEngine `matrix_basis` through v49 and render full + 192x108 thumbnail against the corrected palm-adjacent vessel fixture.
6. Visual gate remains authoritative: immediate human vessel-wrap silhouette, clear thumb opposition, differentiated digit depth, far-contour disappearance, no long parallel prongs, no catastrophic self-intersection.
7. Only after this passes should the continuous limb be exported for real café/bar/market product-camera staging against the XR baseline.

No production PR is warranted yet.
