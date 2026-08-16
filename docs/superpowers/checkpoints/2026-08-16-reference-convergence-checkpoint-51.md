# Peel Calm reference convergence checkpoint 51

Date: 2026-08-16
Branch: `spike/mpfb-whole-hand-enclosure-v92`
Production baseline remains: `main@769d6452e75112084f537af99be90721c2629cd5`
Visual candidate exact head: `f675ec061c76626d0d0b397d8c7e8f162c7dbbe1`
Locked acceptance references: `bar_v1`, `market_v1`

## Exact-head verification

- Godot Check run `31950414104` — **PASS** on `f675ec061c76626d0d0b397d8c7e8f162c7dbbe1`.
- Standard nine-frame artifact: `peel-calm-reference-frames`, artifact id `9264483661`.
- MPFB V92 Product Camera run `31950414099` — **PASS** on the same exact head.
- Same-camera A/B artifact: `mpfb-v92-product-camera`, artifact id `9264542824`.
- Captured product-camera states: `bar_xr`, `bar_v88` (v92 payload), `market_xr`, `market_v88` (v92 payload), `market_v88_inspect45`.

An earlier run `31950099804` failed before candidate generation because Blender `--python` did not place `tools/` on `sys.path`, so the thin v92 wrapper could not import the already-verified v88 exporter. Artifact `9264465969` contains that infrastructure failure. The only correction was explicit insertion of the script directory into `sys.path`; the v92 pose/gesture was not changed.

## v92 falsifiable hypothesis

v91 showed that whole-hand spatial orientation was a better abstraction than further grip-scalar escalation, but `+16°` wrist local-Y rotation still left an open front-side C-shape. The v88 response atlas had already established wrist local-Y translation as the direct toward/away-vessel authoring channel.

v92 therefore created exactly one higher-level gesture while freezing all previously passed contracts:

- preserve v90 semantic closure values;
- preserve `-40°` whole-limb side-on product-camera roll;
- preserve v89 crop radii: palm `0.058`, wrist/forearm `0.046`, fingers `0.018`;
- preserve physical product scale, Godot support root/yaw, camera, vessel, environment and label;
- move `wrist.R` by `+0.012 m` on the already-calibrated local-Y toward-vessel axis;
- deepen whole-hand wrist local-Y orientation from the v91 `+16°` to one fixed `+24°` gesture (one additional response-atlas-sized `8°` nudge);
- no CCD, endpoint optimizer, contact servo, automatic retarget, scale sweep or candidate grid.

Generated static staging mesh remained bounded at 1,749 vertices / 1,738 polygons.

## Visual comparison

### Macro — **FAIL / REJECT**

Compared side-by-side against v91 and the exact same XR baseline in both bar and market:

- the MPFB support hand remains a large open C-shape on the bottle's front/near side;
- four fingers still do not progressively wrap to and disappear behind the bottle's far silhouette;
- the palm/hand continues to compete with and partially cover the hero label;
- thumb-versus-opposing-fingers enclosure is still not immediately readable as a firm natural bottle grip at thumbnail scale;
- v92 is only a small positional/depth change from v91, not a material Macro convergence toward `bar_v1` / `market_v1`.

Therefore v92 does **not** advance to the unobstructed Meso anatomy gate, independent Challenger, product replacement PR, or production integration.

### Preserved passes

The failed enclosure experiment did **not** reopen these previously closed reds:

- side-on forearm approach remains stable;
- continuous wrist/palm crop remains intact; the V-notch does not return;
- physical hand/product scale contract is unchanged;
- `market_v88_inspect45` remains stable under inspection rotation;
- deterministic Godot gameplay/reset/input/reference-frame suite remains green.

## What v92 proved

1. A calibrated palm translation plus one additional whole-hand depth turn is still insufficient to create the missing enclosure.
2. The remaining Macro problem is not primarily another wrist translation/yaw magnitude problem.
3. Repeating `local-Y translation × wrist-Y angle` combinations would now be a disguised parameter sweep and should stop.
4. The next useful abstraction must change the **relative 3D palm/finger topology of the grasp**, especially progressive far-side digit depth, rather than move the current open C-shape as a rigid/near-rigid assembly.
5. Product-camera A/B remains the decisive gate: exact-head CI can be completely green while the support pose is visibly wrong.

## Do not repeat

- Do not try `+8/+12/+16 mm` wrist-local-Y translation grids.
- Do not try `20/24/28/32°` wrist-Y grids.
- Do not resume master/finger grip scalar escalation as the primary fix.
- Do not resume CCD, endpoint chasing, contact servo, raw-phalanx axis tables, whole-hand orbit sweeps, thumb-only sweeps, or arbitrary scale changes.
- Do not reopen the wrist crop unless a real runtime notch reappears.
- Do not begin skin/PBR, paper fiber, glass/liquid, condensation or other Micro polish while R1 Macro remains open.

## Remaining reds, ranked

### R1 — Natural whole-hand vessel enclosure

The continuous MPFB limb now enters from the correct side and has a stable wrist, but the support hand is still front-side/open rather than a natural firm wrap. This remains the dominant visual mismatch in both `bar_v1` and `market_v1`.

### R2 — Product-camera Meso anatomy

Blocked until R1 Macro passes. When it does, inspect web space, knuckle flow, self-intersection, digit separation and inspection rotation.

### R3 — Peel-hand pinch choreography

Still deferred behind support-hand R1.

### R4+ — Skin, paper, glass/liquid, condensation, HUD/micro polish

Still frozen behind the higher-frequency gate.

## Next exact action

Change abstraction again; do **not** create v93 as another wrist-Y/palm-translation magnitude experiment.

1. Start from the proven side-on/crop/scale/product-camera contracts.
2. Use the native GameEngine/MPFB authoring scene as a true whole-hand surface.
3. Keep palm on the bottle flank but explicitly author **relative digit depth** as part of one coordinated grasp:
   - index lightest/least deep;
   - middle deeper;
   - ring deeper again;
   - pinky wraps deepest while preserving separation;
   - distal portions must visibly pass behind/occlude at the bottle far silhouette;
   - thumb must remain readable on the opposite side with web space;
   - hero label must stay readable.
4. This must be exactly one visually reasoned candidate, not a grid.
5. Capture the same five Godot product-camera frames on the exact head.
6. If 192×108 Macro enclosure does not materially improve, reject immediately and stop code-authored transform guessing; move to a genuinely interactive/artist-authored native-rig pose source before further support-pose iteration.
7. Only if Macro passes, capture/inspect unobstructed Meso anatomy, then run an independent Challenger before any production PR.

Production `main` remains untouched and there is no product PR from v92.
