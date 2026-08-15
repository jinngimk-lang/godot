# Peel Calm reference convergence checkpoint 16

Date: 2026-08-15
Production baseline: `main@769d6452e75112084f537af99be90721c2629cd5`
Working branch: `spike/mpfb-hero-limb-reference-bracket-v46`
Exact visual-candidate head: `134d03fa11fbf1f122985264fbcb9f82dbd3cecd`
Godot Check: run `31872612309` — PASS
MPFB Reference Bracket v46: run `31872612348` — PASS
MPFB visual artifact: `mpfb-reference-bracket-v46`, artifact id `9243871418`

## Locked acceptance references

The acceptance set remains unchanged:

- `cafe_v1`
- `bar_v1`
- `market_v1`

Runtime and MPFB staging images remain evidence only and do not replace the locked references.

## Why this checkpoint exists

Checkpoint 15 froze the useful v44 world-space digit morphology and identified whole-hand vessel enclosure / thumb opposition as the dominant Macro/Meso red. This loop tested whether a small rigid orbit of that already-improved hand around the vessel could close the remaining silhouette gap without reopening finger morphology.

The result is negative and useful: rigid orbit alone cannot turn the current v44 morphology into a reference-quality support grasp. This closes another tempting parameter-tuning path before product integration.

## v45 — reference-derived orbit endpoints

Branch: `spike/mpfb-hero-limb-reference-wrap-v45`
Exact head: `8231a96ab700a4e1e7b93d6555d60ab6de214200`
Godot Check: run `31872434978` — PASS
MPFB Reference Wrap v45: run `31872434989` — PASS
Artifact: `9243825536`

Frozen morphology:

- v42 soft index/middle/ring world-space segment directions;
- v44 pinky local basis with distal `66°`;
- no CCD / endpoint solving;
- stronger explicit thumb opposition arc `(30°, 70°, 108°)` with axial component `0.11`.

Only whole-hand rigid orbit changed:

- `orbit_plus22`
- `orbit_minus22`

Visual result:

- `+22°` remained visibly too open; the fingers still projected across the image plane rather than enclosing the cylinder;
- `-22°` over-rotated the hand behind the vessel; palm/fingers became largely occluded and did not read as a useful support grip;
- numeric vessel-relative diagnostics stayed nearly unchanged under the rigid orbit, confirming that those metrics cannot choose a perceptually correct support pose.

Conclusion: the useful solution, if it were a pure orbit, would need to lie between these failure endpoints.

## v46 — narrow orbit bracket rejected

Exact head: `134d03fa11fbf1f122985264fbcb9f82dbd3cecd`
Godot Check: `31872612309` — PASS
MPFB Reference Bracket v46: `31872612348` — PASS
Artifact: `9243871418`

Everything from v45 was frozen except the whole-hand orbit. Two intermediate negative values were rendered:

- `orbit_minus08`
- `orbit_minus14`

### Visual result

Both candidates fail the Macro/Meso support-wrap gate.

`-8°`:

- palm remains visible, but the index/middle/ring still project toward the camera/image plane rather than visibly disappearing around the far contour;
- thumb opposition is not strong/readable enough at thumbnail scale;
- the silhouette reads as an open hand beside a cylinder, not a hand supporting it.

`-14°`:

- increases vessel occlusion but does not create a convincing enclosure;
- finger tips remain visually truncated/open rather than forming an understandable wrap on the far side;
- palm/thumb relation still does not form the reference-like opposing clamp.

### Closed hypothesis

**Rigid whole-hand orbit is not the missing structural degree of freedom.**

The two v45 endpoints plus the two v46 intermediate samples bracket the useful range well enough to reject more orbit-angle tuning. Do not create v47 as another orbit sweep.

## Current reds, ranked

### R1 — Artist-authored whole-hand support choreography

The continuous MPFB limb and world-space digit morphology are technically usable, but the support grasp still lacks a coherent palm/thumb/finger arrangement. The next solution must author the hand as a single grasp shape rather than deriving a grasp from a fixed digit pose plus a rigid orbit.

The target is the reference silhouette:

- palm on the near/lateral vessel surface;
- index/middle/ring/pinky visibly curl behind the far contour with progressive ordering;
- thumb visibly opposes them on the near/upper side;
- wrist continues naturally to the frame edge;
- no claw, parallel-prong or hidden-palm silhouette.

### R2 — Product-camera proof

Still blocked by R1. Do not integrate the MPFB support hand into gameplay until a fixed-camera staging render passes the support-wrap Macro/Meso gate.

### R3 — Peel-hand / flap pinch

Still separate and unresolved. Do not infer peel-hand quality from support-hand experiments.

### R4 — Micro polish

Skin/PBR, paper fibers, glass highlight breakup and condensation remain intentionally deferred.

## Next exact action

Stop parameter-search approaches for the support hand and build one deliberately artist-authored support pose in Blender/MPFB space.

1. Keep the continuous MPFB hand/wrist/forearm asset and v44 `distal66` only as anatomical reference, not as a pose constraint.
2. Author palm orientation, thumb opposition and four finger chains together from the locked support-hand silhouette, preferably with direct joint transforms/pose-key data rather than another optimizer.
3. Render the authored pose from a camera matching the bar/market product-side relationship and also at thumbnail scale.
4. Reject immediately if thumb/finger opposition or far-contour enclosure is not legible.
5. Only after a single authored pose passes Macro/Meso should it be exported and staged in Godot against the current XR baseline.
6. Then run an independent visual Challenger before any production replacement.

## Do not repeat

- CCD / endpoint targets / surface servo;
- local-axis angle grids;
- broad per-joint axis searches;
- generic stronger curl;
- pinky axial/distal sweeps (v44 distal66 is already adequate as an anatomical reference);
- rigid whole-hand orbit sweeps around the vessel;
- Micro material/lighting work intended to make an open hand look acceptable.

## Continuity rule

The next session must begin from this checkpoint and continue R1 with an artist-authored whole-hand support pose. No PR or production merge is authorized from v45/v46; both are visual staging experiments and failed the reference support-wrap gate despite green CI.
