# Peel Calm reference convergence checkpoint 52

Date: 2026-08-16
Branch: `spike/mpfb-relative-digit-depth-v93`
Production baseline remains: `main@769d6452e75112084f537af99be90721c2629cd5`
Final v93 evidence head: `794361b1e679c9ed0eb7070153c1c3fb0e17ed4b`
Locked acceptance references: `bar_v1`, `market_v1`

## Exact-head verification

- Godot Check run `31956129174` — **PASS** on `794361b1e679c9ed0eb7070153c1c3fb0e17ed4b`.
- MPFB V93 Product Camera run `31956129156` — **FAIL before GLB/product-frame capture** at the structural relative-depth gate on the same exact head.
- Failure artifact: `mpfb-v93-product-camera`, artifact id `9266051926`.
- Earlier v93 structural run `31953625379` also failed before product-frame capture; artifact id `9265388480`.

The product-camera failure is not a Godot gameplay failure and not a visual-frame verdict: the candidate never reached GLB validation or the five-frame A/B capture.

## v93 hypothesis

Checkpoint 51 allowed exactly one final code-authored structural candidate before transform guessing had to stop. v93 preserved the verified v92 hand, side-on `-40°` limb approach, v89 continuous wrist crop, physical product scale, product camera and internal PIP/DIP closure. It changed only the four non-thumb proximal digit roots to create progressive far-side depth:

- index: 4°;
- middle: 8°;
- ring: 13°;
- pinky: 18°.

No CCD, endpoint target, contact servo, automatic retarget, scale sweep, candidate grid or iterative optimizer was used.

## First structural failure

The first exact full-chain attempt produced distal far-depth deltas:

- index: `+0.000461000949 m`;
- middle: `+0.000022292137 m`;
- ring: `-0.001236010343 m`;
- pinky: `-0.000961334634 m`.

The MPFB helper/constraint chain therefore did not preserve a common local rotation convention across digits. The candidate was correctly rejected before image capture.

## One permitted calibration correction

To distinguish a simple rig-sign convention issue from a deeper abstraction failure, the only follow-up change froze sign choices from that exact full-chain response while preserving all magnitudes:

- index `+4°`;
- middle `-8°`;
- ring `-13°`;
- pinky `-18°`.

This was a single sign calibration, not a magnitude search or parameter sweep. Godot remained completely green on the calibrated exact head.

## Calibrated result — structural **REJECT**

The calibrated run produced the **same final distal response** as the first attempt:

- index: `+0.000461000949 m`;
- middle: `+0.000022292137 m`;
- ring: `-0.001236010343 m`;
- pinky: `-0.000961334634 m`.

The candidate again failed the required positive/progressive far-depth gate before GLB/product-frame capture.

This proves the remaining behavior is not a simple per-digit sign convention that can be repaired by another code-authored angle/sign tweak. The Default-rig helper/constraint stack is overriding or remapping these proximal matrix edits in a way that makes further sign/angle guessing a disguised search.

## Stop condition reached

Checkpoint 51 explicitly required that if the single relative-depth candidate failed to materially establish the intended enclosure, code-authored transform guessing must stop. That condition is now reached even before the visual gate.

Do **not** create v94/v95 variants that:

- change the 4/8/13/18° magnitudes;
- try additional per-digit sign combinations;
- probe helper/local axes and then optimize them;
- resume CCD, endpoint chasing, contact servo or raw phalanx tables;
- sweep wrist/palm translation, wrist-Y, orbit, grip scalars or scale;
- treat structural metrics as a substitute for the locked 192×108 Macro reference gate.

## What remains valid

- `main` remains unmodified by MPFB staging work.
- The continuous MPFB hand–wrist–forearm asset path remains technically valid.
- The `-40°` side-on whole-limb choreography remains the best verified approach direction.
- The v89 crop envelope remains the verified fix for the wrist V-notch.
- Physical hand/product scale mapping remains unchanged.
- The v87/v85/v86 authoring scenes remain useful infrastructure for a human/interactive pose author.
- ContactPose water-bottle anatomy remains a read-only guide, not a runtime dependency or automatic retarget source.

## Parallel evidence-truthfulness work

PR #51 (`fix/reference-peel-capture-pinch-v1`) is an evidence-only capture correction. Current head `980345c46c2968265e4eb248067c1dce7721c545` has a green Godot Check (`31955572236`) and changes only `tests/capture_reference_frames.gd`. It remains open because the connected GitHub identity cannot independently approve its own PR; do not call self-review an independent Challenger.

## Remaining reds, ranked

### R1 — Genuine artist-authored whole-hand vessel enclosure

The dominant blocker is now authoring capability, not another scalar or axis. A trustworthy next pose must be produced directly on the native GameEngine/MPFB rig with visual control of palm placement, four-digit depth ordering and thumb opposition.

### R2 — Product-camera Meso anatomy

Blocked until an artist-authored pose passes the 192×108 Macro enclosure gate. Then inspect web space, knuckle flow, self-intersection, digit separation and `inspect45` rotation.

### R3 — Peel-hand pinch choreography

Still deferred behind support-hand R1. PR #51 only fixes capture truthfulness; it does not close this visual red.

### R4+ — Skin/PBR, paper fibers, glass/liquid, condensation, HUD/micro polish

Remain frozen while R1 Macro is unresolved.

## Capability check

A fresh plugin search for Blender / 3D rigging / animation / modeling / posing returned no installable connector in the current environment. Therefore do not pretend headless numerical scripts are equivalent to interactive artist posing.

## Next exact action

1. Recover the verified native authoring scene and semantic controls (`wrist.R`, master grip, five finger grips), ContactPose ghost/wire guides and fixed product proxy/camera.
2. Produce a **genuinely visual/artist-authored** same-rig whole-hand support pose, not another generated parameter candidate.
3. Preserve the verified side-on limb, wrist crop and physical scale unless the visual author explicitly needs a coherent whole-hand correction.
4. Hide all guides and judge the unchanged opaque 192×108 product-view Macro first:
   - palm on bottle flank;
   - index lightest;
   - middle/ring/pinky progressively deeper;
   - distal digits visibly pass behind the far bottle silhouette;
   - thumb remains readable on the opposite side with web space;
   - hero label remains readable.
5. Only if Macro passes, inspect unobstructed Meso anatomy and then capture the same five Godot bar/market product-camera frames against XR baseline.
6. Run an independent Challenger before any production replacement PR.
7. Until such an artist-authored pose source exists, do not spend autonomous loops on more code-authored pose transforms; work only on reversible capability/evidence infrastructure that directly enables that visual edit.

Production `main` remains untouched; no MPFB support-hand candidate is ready for production integration.
