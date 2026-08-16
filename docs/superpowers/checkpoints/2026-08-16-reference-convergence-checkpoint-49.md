# Peel Calm reference convergence checkpoint 49

Date: 2026-08-16
Branch: `spike/mpfb-grip-enclosure-v90`
Production baseline: `main@769d6452e75112084f537af99be90721c2629cd5`
Visual candidate exact head: `56a351db0e42cb8e350599790c7896de248da94e`
Locked references: `bar_v1`, `market_v1`

## Exact-head verification

- Godot Check run `31944480700` — PASS on exact candidate head.
- Godot reference-frame artifact `9262907926` — nine standard café/bar/market runtime frames.
- MPFB V88 Product Camera run `31944480702` — PASS on exact candidate head.
- Product-camera A/B artifact `9262963094`.
- Product-camera frames inspected: `bar_xr`, `bar_v88`, `market_xr`, `market_v88`, `market_v88_inspect45`.
- No production PR was opened and `main` was not modified.

## Hypothesis tested

Checkpoint 48 left R1b as the highest red: v89 had a correct side-on approach and continuous wrist but still read as a large open C-shape rather than a firm human vessel wrap.

v90 tested exactly one reference-derived semantic enclosure correction while freezing the parts already proven in v89:

- whole-limb camera-plane roll: `-40°` — unchanged;
- palm crop radius: `0.058` — unchanged;
- wrist/lowerarm crop radius: `0.046` — unchanged;
- finger crop radius: `0.018` — unchanged;
- physical product scale/root/yaw/camera — unchanged;
- no CCD, endpoint optimizer, contact servo, automatic retarget or parameter sweep.

The single semantic control edit was:

```text
wrist.R             +10°  (unchanged)
master grip          +18°
thumb grip            +4°
index grip            -8°
middle grip           +4°
ring grip             +10°
pinky grip            +16°
```

The intent was moderate common closure with index lightest and middle/ring/pinky progressively deeper, following the qualitative ordering seen in the real water-bottle anatomy reference.

## Visual verdict

**REJECT as a support-grasp production candidate.**

### What improved

- Relative to v89, the visible finger chain bends downward more clearly around the label region.
- The previously accepted `-40°` side-on whole-limb approach remains intact.
- The v89 wrist/palm crop fix remains intact; the V-shaped wrist hole does not return.
- `market_v88_inspect45` preserves the same stable hand/wrist relationship instead of breaking during inspect rotation.
- The candidate remains substantially more anatomically continuous than the current XR support-hand baseline.

### Why Macro still fails

At 192×108 / thumbnail reading, the MPFB support hand still reads as an **open C-shape hovering/laying across the bottle front**, not as a human hand firmly enclosing the vessel.

- The palm still occupies the front/label region instead of reading as a side contact surface.
- Increasing semantic closure curls the visible digits but does not make the four-finger chain convincingly pass around and disappear behind the vessel's far silhouette.
- Thumb-versus-four-finger opposition is more legible than XR but still does not create the locked-reference grip grammar.
- The hero label remains too competed with by the open hand silhouette.

### Meso conclusion

The semantic grip scalar controls are now demonstrated to affect local flexion without solving the remaining 3D palm/finger **depth relationship** required for reference-grade enclosure. More `master/fingerX` magnitude is therefore not an evidence-backed next step; it is likely to convert the open C-shape into a fist/claw or increase label occlusion.

## Closed / preserved reds

- R1a side-on approach direction: **PASS, preserve**.
- R1a wrist/forearm crop continuity: **PASS, preserve**.
- Real product scale mapping: **preserve; do not start arbitrary hand-scale sweep**.
- Inspect-state continuity for the staging hand: **preserved in v90**.

## Current reds, ranked

### R1 — Reference-grade whole-hand vessel enclosure

Need a palm that visually sits on the vessel side, four fingers that progressively travel to/fall behind the far silhouette, and a thumb that opposes them without covering the hero label. This is a spatial/whole-hand authoring problem, not another scalar grip-strength problem.

### R2 — Product-camera integration / replacement decision

Only after R1 passes Macro+Meso should the MPFB hand be considered for production support-hand replacement and Challenger review.

### R3 — Peel-hand pinch choreography

Still deferred until support-hand anatomy is stable.

### R4 — Micro realism

Skin PBR, paper fibers, glass/liquid/condensation and other high-frequency polish remain frozen while R1 is red.

## Do not repeat

- Do not create v91 by increasing/decreasing master grip or individual finger-grip numbers as a sweep.
- Do not reopen CCD, endpoint chasing, contact servo, direct phalanx-axis tables, orbit-angle search, thumb-only scalar sweeps or arbitrary hand scale.
- Do not reopen crop tuning unless a new candidate actually reintroduces a crop defect.
- Do not spend a loop on skin/material Micro polish while the support grasp still fails at thumbnail scale.

## Next exact action

Change abstraction rather than magnitude.

Build/use a **direct whole-hand native-rig authoring pass with product-camera spatial feedback**. Preserve the proven `-40°` side-on limb direction, crop envelope, physical scale and camera, but allow the actual palm/wrist relationship plus semantic finger controls to be visually authored together as one pose so that:

1. palm reads beside/against the bottle rather than across its front;
2. index remains the lightest closure;
3. middle/ring/pinky progressively wrap into far-side depth and disappear behind the bottle silhouette;
4. thumb forms a clear opposing contour;
5. hero label remains readable;
6. unobstructed anatomy has continuous web/knuckle flow and no self-intersection.

Generate exactly one visually authored candidate, then rerun the same five Godot product-camera frames. If Macro enclosure is not materially better, reject it without proceeding to Micro polish or production PR.
