# Peel Calm reference convergence checkpoint 27

Date: 2026-08-16
Production main: `769d6452e75112084f537af99be90721c2629cd5`
Diagnostic branch: `spike/mpfb-source-anatomy-v62`
Diagnostic exact head: `588702f9ed6a1cc6745e21bb6ae1d32bb0f793d3`
Godot Check: run `31895955311` — PASS
MPFB Source Anatomy v62: run `31895955335` — PASS
Source anatomy artifact: `9249814243` (`mpfb-source-anatomy-v62`)
Parent visual-rejection checkpoint: checkpoint 26 (`v61`)

## Locked acceptance references

The locked `cafe_v1`, `bar_v1`, and `market_v1` targets remain unchanged. Their original PNGs remain in the persisted project library and their hashes remain defined by `art/acceptance_refs/v1/MANIFEST.md`. No staging image in this loop replaces them.

## Why v62 existed

v61 proved that a safe, non-destructive source-direction retarget could execute correctly, but its 192×108 silhouette still failed the vessel-wrap gate. Before transferring richer source pose information, checkpoint 26 required one falsifiable diagnosis:

> Does the selected CC0 `holding-wine-glass` source pose itself contain the progressive finger curl and thumb opposition required by the Peel Calm support-hand reference?

v62 rendered only the sacrificial source right distal forearm/wrist/finger skeleton as a canonical close-up. No MPFB GameEngine target rig was loaded or modified and no automatic retarget was permitted.

## Technical result — PASS

- Official MakeHuman Community Poses 01 pack acquired and provenance checked as CC0.
- Source hand renderer selected the expected right forearm/wrist/thumb/finger bones.
- Source anatomy workflow produced both full and thumbnail evidence.
- Full Godot 4.7.1 suite remained green on the exact diagnostic head.

## Macro/Meso visual result — SOURCE REJECTED

The real `source-hand-thumbnail.png` and `source-hand-full.png` were inspected directly.

The `holding-wine-glass` source pose is **not a suitable bottle/cup-wrap anatomical template** for Peel Calm:

1. The wrist/hand chain is strongly bent relative to the distal forearm instead of flowing naturally into a side-on vessel grip.
2. The four fingers do not form a clean progressive cylindrical enclosure.
3. The visible thumb/finger relationship reads more like holding a small stem/glass feature or small object than wrapping the body of a slender bottle/cup.
4. Several finger chains overlap/cross in the canonical close-up rather than producing a clean reference silhouette.
5. At thumbnail scale the hand does not present the unmistakable opposed-thumb + far-contour finger wrap required by `bar_v1` / `market_v1`.

Therefore the selected source pose itself fails the required anatomy gate. A richer retarget of this same source would only transfer the wrong grasp more faithfully.

## Source-pack inventory conclusion

The inspected Poses 01 CC0 pack contains only one explicitly object-holding pose by filename: `mindfront_sitting_in_armchair_holding_wine_glass`. The remaining entries are sitting, lotus, floor, swing, and other non-object-holding poses. There is no second obvious bottle/cup wrap candidate in this pack worth another source-retarget iteration.

## Closed route

Stop the `holding-wine-glass -> target GameEngine support grip` retarget family here.

Do NOT create a v63 that merely transfers:

- richer parent-relative swing from this same source;
- source joint bend planes from this same source;
- more source twist;
- source roll;
- direct source matrices/quaternions;
- a stronger scalar blend toward this source.

The source target is wrong, so greater retarget fidelity is not progress.

## Remaining reds

### R1 — Reference-derived human vessel wrap

Still the highest red. The next support-hand pose source must be derived from the actual locked Peel Calm reference intent (or from a demonstrably closer permissive anatomical source), not from the rejected wine-glass pose.

Required thumbnail read:

- palm on the near/side vessel surface;
- index→pinky progressively travel toward/behind the far contour;
- fingers remain anatomically separated without long parallel forks or hooks;
- thumb visibly opposes the finger side;
- wrist/forearm flow into frame naturally.

### R2 — Godot product-camera proof

Still blocked by R1.

### R3 — Peel-hand flap pinch

Still blocked behind the support-hand silhouette gate.

### Micro

Skin PBR, paper fibers, glass highlights, liquid, condensation, and other Micro polish remain frozen.

## Next exact action

Pivot away from unrelated object-holding BVH sources and make the acceptance reference itself the pose source.

Preferred next spike:

1. Recover/verify the locked `bar_v1` and/or `market_v1` PNG bytes using the hashes in `art/acceptance_refs/v1/MANIFEST.md`.
2. Derive a support-hand landmark / silhouette constraint set directly from that accepted image: palm orientation, wrist flow, thumb side, visible finger ordering, far-contour disappearance, and vessel-relative contact bands.
3. Use those **reference-derived constraints** to visually author the target MPFB GameEngine rig, preserving the v49 17-bone durable pose format.
4. Render full + 192×108 after every meaningful authored change; do not optimize fingertip distance or return to blind Euler/axis sweeps.
5. Only a thumbnail-passing pose may enter Godot café/bar/market product-camera staging against the current XR baseline.

If automated landmark extraction is evaluated, it must remain diagnostic: the human/reference silhouette gate is authoritative and any model/tool license must be verified before production dependency.

No production PR or merge is warranted yet.