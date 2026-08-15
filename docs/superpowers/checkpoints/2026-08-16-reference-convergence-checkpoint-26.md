# Peel Calm reference convergence checkpoint 26

Date: 2026-08-16
Production main: `769d6452e75112084f537af99be90721c2629cd5`
Staging branch: `spike/mpfb-hero-limb-samefamily-retarget-v61`
Visual candidate exact head: `b5b6e95191eb5aae1ebd78527effcd478cdc45c5`
Godot Check: run `31895631021` — PASS on the exact candidate head
MPFB Same-Family Swing Retarget v61: run `31895630927` — PASS
Visual/pose artifact: `9249744992` (`mpfb-samefamily-retarget-v61`)

## Acceptance reference status

The locked `cafe_v1`, `bar_v1`, and `market_v1` reference families remain unchanged. Runtime or staging captures remain evidence only and must not replace the acceptance set.

## Why v61 existed

Checkpoint 25 rejected the corrected-focus Artist-FK candidate and prohibited another raw Euler / shared-axis / CCD / endpoint / contact-distance / orbit / tolerance search. v61 changed the representation instead of tuning those parameters:

- import the official MakeHuman Community Poses 01 `holding-wine-glass` BVH only on a sacrificial source rig;
- derive each source phalanx direction relative to the source palm frame;
- map that direction into the target MPFB GameEngine palm frame;
- rotate target phalanges with swing-only pose rotations;
- never copy source edit-bone roll, source twist, source pose matrices, or target rest/edit bones;
- save only the resulting target-rig pose through the existing 17-bone v49 durable `matrix_basis` format.

## Evidence-chain correction during this loop

The first v61 artifact (`run 31895456144`, artifact `9249679937`) contained no valid render. Its `retarget.log` showed that the source semantic mapping incorrectly assumed lowercase right-side suffixes (`wrist.r`, `finger*.r`). The official MakeHuman Poses 01 BVH actually uses uppercase `.R` names. That initial workflow result is INVALID visual evidence and must never be cited as a v61 pose result.

The mapping was corrected without changing the retarget strategy. The rerun at exact head `b5b6e951...` generated the real v61 evidence and passed both the non-destructive retarget contract and the full Godot suite.

## Technical result — PASS

The real v61 report records:

- source license: CC0;
- source edit-bone roll copied: false;
- source pose matrices copied: false;
- source twist copied: false;
- target edit/rest modified: false;
- target solver used: false;
- camera focus preserves pose: true;
- durable target pose bones: 17;
- mapped digit bones: 15;
- max save/clear/reload matrix error: `2.980232238769531e-07`.

This closes the engineering question of whether a safe direction-only same-family retarget can execute and survive durable-pose persistence.

## Macro/Meso visual result — REJECT

The persisted `samefamily_swing_v61_thumbnail.png` and full candidate were inspected directly.

At 192×108 the pose does **not** read as a natural vessel wrap:

1. Index, middle, and ring remain long, near-horizontal fingers laid across the near bottle face instead of progressively wrapping behind the far contour.
2. Pinky is the opposite failure: it curls into a conspicuous hook/kink beneath the other fingers.
3. Thumb opposition is not readable as a clean opposing clamp against the four-finger side.
4. The palm is adjacent to the vessel, but the hand silhouette reads as `touching / spanning across the bottle`, not `enclosing the bottle`.
5. The full frame confirms that the failure is structural, not a thumbnail aliasing issue.

Therefore v61 is technically valid but visually rejected. It must NOT enter Godot product-camera staging or production.

## What v61 proved

A source pose's per-segment direction alone is not a rich enough anatomical representation for the target GameEngine hand. It loses the coordinated joint-chain / bend-plane / enclosure relationship needed for the reference silhouette. Good provenance and a mathematically clean retarget contract cannot override a failed Macro/Meso image gate.

## Do not repeat

Do not respond to this rejection with:

- another v61 swing-strength scalar;
- a source/target palm-frame yaw sweep;
- endpoint/contact-distance tuning;
- CCD;
- shared local-axis tables;
- whole-hand orbit scans;
- more distal curl on the existing result;
- lowering the visual gate.

Those are either already disproved families or would turn this structurally new experiment back into parameter search.

## Remaining reds

### R1 — Support-hand vessel enclosure

Still the highest product red. A valid candidate must read at thumbnail scale as a human hand enclosing the vessel: palm near/side contact, index→pinky progressively passing toward or behind the far contour, and an unmistakable opposing thumb.

### R2 — Product-camera proof

Blocked on R1. No hero-hand replacement enters café/bar/market product cameras until the staging silhouette passes first.

### R3 — Peel-hand flap pinch

Blocked behind support-hand R1. Must eventually show whole-hand approach plus real thumb/index flap contact, not only endpoint coincidence.

### Micro work

Skin PBR, paper fibers, glass highlight breakup, condensation, and other Micro polish remain intentionally frozen.

## Next exact action

Before designing a richer retarget, render the **CC0 source holding-wine-glass hand itself** in a canonical hand-only close-up using the existing sacrificial v50 anatomy renderer. This answers a falsifiable question that v61 cannot answer:

> Does the selected source pose itself contain the progressive finger curl and thumb opposition required by the Peel Calm vessel-wrap reference?

- If the source close-up itself fails that silhouette test, stop using this source pose and select a more suitable anatomical reference or directly visually author the target GameEngine rig.
- If the source close-up passes, the lost information is in the retarget representation; the next experiment may transfer richer parent-relative swing/bend-plane relationships while still stripping source roll/twist and preserving target rest bones.

No production PR is warranted before that diagnosis and a new thumbnail-passing candidate.