# Peel Calm reference convergence checkpoint 47

Date: 2026-08-16
Branch: `spike/mpfb-grip-web-viewport-v88`
Production baseline: `main@769d6452e75112084f537af99be90721c2629cd5`
Visual candidate head: `11b15349299a3c47c2c1ddc6a5c90576dc2800e7`
Locked acceptance references: `bar_v1`, `market_v1`

## Exact-head verification

- Godot Check: run `31940986941` — PASS.
- Standard nine-frame runtime artifact: `peel-calm-reference-frames`, artifact `9262008232`.
- Dedicated same-camera MPFB product-camera A/B: run `31940986915` — PASS.
- Product-camera artifact: `mpfb-v88-product-camera`, artifact `9262056801`.
- Captured affected frames:
  - `bar_xr.png`
  - `bar_v88.png`
  - `market_xr.png`
  - `market_v88.png`
  - `market_v88_inspect45.png`

## What changed

The previous v88 product-camera candidate entered from the upper-right and read as a large hand pressing down over the bottle. The export root was already aligned to the real vessel center, so another position nudge was not justified.

A single direct-visual whole-limb artist correction was made instead:

- keep the v87 semantic grip pose unchanged;
- keep product scale unchanged;
- keep Godot root position and yaw unchanged;
- rotate the complete baked continuous hand/wrist/forearm by `-40°` in the locked authoring camera plane, around the proxy vessel center;
- no CCD, endpoint optimizer, contact servo, automatic retarget, parameter sweep, or scalar grip-angle search.

The angle came from the actual product-frame low-frequency mismatch: the forearm entered diagonally from upper-right by roughly forty degrees, while the locked reference intent requires a side support-hand approach.

## Visual verdict

### Macro — IMPROVED / approach red closed

This is the first MPFB candidate in the product-camera chain that materially improves the low-frequency approach path:

- the continuous forearm now enters from the right side rather than descending from above;
- the palm sits beside the bottle body instead of over the bottle shoulder;
- thumb and opposing fingers are readable on opposite regions of the vessel at 192×108;
- the same side relationship survives `market_v88_inspect45` rather than reverting to the old top-down composition.

Therefore the specific Macro red **“upper-right / top-down support-hand approach”** is closed for this candidate lineage.

### Meso — STILL FAIL / not production-ready

The candidate is not accepted for production yet:

1. The baked crop envelope around the wrist/palm is too tight. In both bar and market full-resolution frames a visible V-shaped missing-surface/notch appears at the wrist transition.
2. The grasp is much more readable than the previous top-down candidate, but the palm/finger enclosure is still less convincing than the locked `bar_v1` / `market_v1` intent; it must not be called reference-quality yet.
3. The forearm silhouette is continuous but still needs a cleaner anatomical crop/transition before any skin/PBR work is meaningful.

The current static staging material remains intentionally plain; skin shading is Micro and stays frozen.

## Scale finding — do not chase next

Do not react to the large-looking hand by starting an arbitrary scale sweep.

The staging harness intentionally maps the authoring proxy bottle radius (`0.038`) to the real product bottle radii (`0.342` bar and `0.330` market), producing roughly the existing 9× / 8.68× conversion. That is a physically motivated object-scale mapping, not an arbitrary enlargement. The next visible defect is the crop/enclosure geometry, not a missing scale guess.

## Local direct-visual authoring capability unlocked

This run also removed a tooling misconception from earlier checkpoints. The pinned Blender 4.2.0 artifact can be executed locally with `xvfb-run`, the real v87 `.blend` opens correctly, and we can:

1. edit the native rig / whole-limb transform;
2. render a real opaque-vessel frame;
3. inspect the rendered pixels directly;
4. make one evidence-derived correction at a time;
5. then push the candidate into the exact Godot product-camera harness.

This is not an interactive GUI viewport, but it is sufficient for direct visual artist iteration and is preferable to automated parameter sweeps.

## Closed / do-not-repeat

Do not repeat:

- top-down upper-right v88 approach;
- tiny Godot root-offset nudges as a substitute for whole-limb choreography;
- arbitrary hand-scale sweeps while the proxy/product physical ratio is already defined;
- CCD / endpoint chasing / contact servo / automatic ContactPose retarget;
- raw joint-axis or scalar grip-angle sweeps;
- Micro skin, paper, glass or condensation polish while wrist/enclosure remains Meso-failed.

## Remaining reds

### R1a — wrist/palm crop continuity

Highest immediate red. Preserve the now-improved pose/roll/scale and widen the baked anatomical crop envelope around `lowerarm02.R`, `wrist.R`, and palm just enough to eliminate the visible V-shaped missing surface. This is an export-geometry correction, not a pose change.

### R1b — final support-hand enclosure

After the crop is clean, compare the same 192×108 and full-resolution product frames again. The hand must read as firmly enclosing the bottle with natural index→pinky depth and clear thumb opposition, not merely touching the label region.

### R2 — production integration / Challenger

Only after R1a/R1b pass locked Macro/Meso evidence should the MPFB limb become a production integration candidate and receive independent Challenger review.

### R3 — peel-hand pinch

Still deferred behind support-hand R1/R2.

### Micro

Skin PBR, paper fibers, glass optical breakup, liquid and condensation remain frozen.

## Next exact action

Freeze the side-on `-40°` whole-limb roll, semantic grip deltas, physical scale mapping, root position, yaw, camera and product state. Make exactly one export-geometry correction: enlarge the retained wrist/lowerarm/palm skin envelope enough to remove the visible crop notch without restoring unrelated torso/upper-arm geometry. Re-run exact-head Godot Check and the five-frame product-camera A/B. If the notch disappears without damaging the 192×108 side-grip silhouette or `inspect45`, then judge enclosure; otherwise reject the crop correction before any further pose work.
