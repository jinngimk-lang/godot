# Peel Calm reference convergence checkpoint 20

Date: 2026-08-15
Production main baseline: `769d6452e75112084f537af99be90721c2629cd5`
Working branch: `spike/mpfb-hero-limb-manual-support-v51`
Verified v51 candidate head: `ada12d5e0ff8408b6dcadbab42b641318a3ab726`
Godot Check: run `31877791929` — PASS on the verified v51 candidate head
MPFB Manual Support v51: run `31877791942` — PASS on the verified v51 candidate head
Manual-support evidence artifact: `9245235989`

This checkpoint commit is documentation-only and comes after the verified candidate head. Product/staging conclusions below are based on the exact verified head and its uploaded visual artifact.

## Locked acceptance references

The acceptance set remains unchanged:

- `cafe_v1`
- `bar_v1`
- `market_v1`

Runtime screenshots, Blender staging images, and external pose thumbnails are evidence only. They do not redefine acceptance.

## R1 status

**R1 — believable continuous support hand / wrist / forearm remains OPEN.**

Do not begin Micro skin, paper-fiber, glass-highlight or condensation polish while this Macro/Meso red remains dominant.

## v50 — sacrificial MakeHuman anatomy-reference spike

Branch: `spike/mpfb-hero-limb-sacrificial-reference-v50`
Final close-up head: `7e9540fb828c1cccf85af8040161e6ebf9e64975`
MPFB Sacrificial Anatomy Reference v50: run `31877507921` — PASS
Godot Check: run `31877507936` — PASS
Close-up artifact: `9245149312`
Official Poses 01 source-pack SHA256 observed in CI:
`67b1d14923adda85f371f81e1c529fcd058f975d0bf93848838e1a3860705b7d`

### What v50 established

- The official MakeHuman Poses 01 holding-wine-glass pose can be acquired reproducibly and parsed as BVH.
- The source is used only on a throwaway/sacrificial BVH armature.
- Machine gates explicitly require:
  - `staging_only = true`
  - `production_candidate = false`
  - `automatic_retarget_allowed = false`
- No source BVH transform was written into the MPFB GameEngine hero rig.
- The first successful render was diagnostically invalid because the camera included the shoulder/upper arm and made the hand too small to judge.
- The corrected close-up isolates `lowerarm02.R`, `wrist.R`, and `finger1..5` right-side chains.
- The close-up provides a useful *anatomical visual clue*: visible digits have differentiated flexion depth and an opposing digit participates from another side instead of reading as four parallel prongs.

### What v50 did NOT establish

- It is not the Peel Calm bottle/cup support pose.
- It is not safe or necessary to retarget automatically.
- It is not a production asset.
- Its transforms are not copied to the GameEngine rig.

The useful lesson is visual/anatomical only: **progressive finger depth + independent thumb opposition should be hand-authored on the stable GameEngine rig.**

## v51 — one fixed manual corrective FK candidate

v51 deliberately contained only one candidate and no parameter sweep.

It started from the previously least-twisted v44 `distal66` staging seed, then applied one fixed corrective FK pass and saved the final 17-bone GameEngine `matrix_basis` values through the durable v49 partial-pose format.

### Technical result — PASS

The durable pose mechanism is healthy:

- pose format: `peel-calm-game-engine-partial-pose-v1`
- pose bone count: `17`
- save → clear → reload maximum matrix error: `2.384185791015625e-07`
- `automatic_retarget = false`
- `retarget_source_transforms_used = false`
- full Godot 4.7.1 suite passed on the exact candidate head.

This confirms the project can persist an artist-authored GameEngine pose once a visually correct one exists.

### Visual result — REJECT

Frames inspected from artifact `9245235989`:

- `manual_support_v51_v44_seed.png`
- `manual_support_v51_candidate.png`
- `manual_support_v51_thumbnail.png`

Macro/Meso judgment:

- v44 seed still shows index/middle/ring as long, mostly parallel prongs beside the vessel.
- v51 candidate is **worse**, not better: the middle/ring visible chains become even longer/straighter across the vessel face.
- the thumbnail does not read as a human hand wrapping the vessel.
- there is no clear near-side thumb versus far-side finger enclosure.
- progressive digit depth is not visually established.
- the candidate therefore fails the locked R1 Macro/Meso gate despite both CI workflows being green.

**Do not promote v51 to Godot product-camera staging or production.**

## Structural conclusion

The remaining failure is not pose persistence, not MPFB generation, not Godot import, and not external-reference availability.

The failed abstraction is now more specific:

> Reusing the old `_bend_toward_center` / solver-derived correction helper, even once with fixed values, still inherits the same wrong hand-shape abstraction and can lengthen/straighten the visible prong silhouette rather than authoring a believable grasp.

Therefore the next iteration must stop calling that helper for support-grasp authorship.

## Do not repeat

- CCD / endpoint chasing
- surface servo
- local-axis grids
- generic shared curl tables
- rigid whole-hand orbit search
- world-direction solver tables from v42–v48
- `_bend_toward_center` as a support-grasp authoring primitive
- external BVH destructive import/retarget into the GameEngine hero rig
- Micro material polish to hide a failed grasp
- interpreting v49/v51 technical pose persistence as visual completion

## Next exact action

Create a new isolated **true Blender manual-bone-pose spike** from this evidence.

1. Build the same stable MPFB 2.0.17 GameEngine human.
2. Use the v50 close-up only as a visual anatomy guide; do not copy BVH transforms.
3. In one fixed staging view, directly set the 17 GameEngine pose-bone `matrix_basis` values as explicit artist-authored transforms rather than invoking a target solver/helper.
4. Author the grasp in this order:
   - whole palm/wrist orientation and vessel-side placement;
   - thumb opposition on the near/upper side;
   - index proximal/intermediate/distal chain so it disappears behind the far contour;
   - middle, ring, pinky with progressively different depth and curl;
   - inspect self-intersection and wrist flow.
5. Save the result through `manual_pose_asset_v49.py`.
6. Render full + 192x108 thumbnail beside the same vertical proxy.
7. Visual gate only:
   - thumbnail must read immediately as `hand wrapping vessel`, not `fingers touching vessel`;
   - visible fingers must not be four parallel long prongs;
   - thumb must visibly oppose the finger mass;
   - at least part of the finger mass must disappear behind the vessel far contour;
   - no catastrophic self-intersection/torn-palm silhouette.
8. Only if that gate passes, export/pose the continuous limb for Godot product-camera staging against the current XR baseline.

No production PR is warranted until that product-camera proof exists.
