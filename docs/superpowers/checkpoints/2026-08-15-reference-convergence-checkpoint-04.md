# Peel Calm reference convergence checkpoint 04

Date: 2026-08-15
Production baseline: `main@769d6452e75112084f537af99be90721c2629cd5`
Active spike: `spike/mpfb-hero-limb-surface-servo-v26`
Checkpoint branch head before this document: `28c744efb07e86a971e059b1ab51d35667cca8e6`
Acceptance set: `cafe_v1`, `bar_v1`, `market_v1`

## Highest-impact red remains R1/R2

The dominant reference mismatch is still the hero human limb and its tactile poses:

1. one continuous realistic hand/wrist/forearm surface;
2. photographic vessel-wrap support pose;
3. thumb/index contact on the actual lifted paper flap.

Do not move to skin PBR, paper fibers, glass micro-highlights, or other Micro polish until this Macro/Meso gate improves.

## MPFB progression since checkpoint 03

The MPFB 2.0.17 / Blender 4.2 GameEngine-rig route is technically reproducible and has produced a continuous right hero limb. The current work is no longer blocked by model generation or extraction; it is now a contact/pose validation problem.

### v24 — strict bone-tail contact gate

Branch/head: `spike/mpfb-hero-limb-contact-ik-v24@5ec464a616ef9a75bd26b166e5ab9ea047a53e38`
MPFB run: `31845484930` — expected FAIL at strict pinch gate
Evidence artifact: `9235785747` (`mpfb-hero-limb-contact-ik-v24`)
Godot Check on the same branch head: `31845484922` — PASS

Measured pinch after bounded CCD:

- index distal-bone endpoint to flap center: ~6.3 mm;
- thumb distal-bone endpoint to flap center: ~9.6 mm;
- distal-bone endpoint gap: ~15.5 mm;
- v24 <=12 mm mutual-gap gate correctly rejected the candidate.

More importantly, direct inspection of `contact_v23_pinch_ik.png` falsified the metric itself: the visible skinned fingertip surfaces remained noticeably detached from the flap despite small bone-endpoint errors.

**Conclusion:** MPFB distal bone tails are not sufficient visual contact proxies. Do not loosen the v24 threshold and do not promote a pose using bone-tail distance alone.

### v25 — one-shot bone-to-visible-surface offset compensation

Branch/head: `spike/mpfb-hero-limb-surface-contact-v25@9436c83b7cabb609611aabfae2b5eed76a65c2b6`
MPFB run: `31846407383` — expected FAIL at visible-surface gate
Evidence artifact: `9236094855` (`mpfb-hero-limb-surface-contact-v25`)

v25 evaluates the deformed mesh vertices influenced by `index_03_r` and `thumb_03_r`, converts the current bone-tail→surface offset into a corrected CCD target, and then validates the rendered surface rather than the skeleton endpoint.

Measured final visible-surface result:

- index flap-face error: ~9.5 mm;
- thumb flap-face error: ~30.9 mm;
- index distance to flap center: ~10.7 mm;
- thumb distance to flap center: ~32.1 mm;
- visible surface gap: ~36.7 mm;
- joint extra-rotation budget remained capped at 24 degrees.

Rendered `surface_v25_pinch.png` agrees with the metrics: one fingertip approaches the paper while the other remains visibly separated.

**Conclusion:** a once-sampled surface offset is not invariant while the phalanges rotate. This is a useful negative result, not a reason to weaken the visual gate.

## Current falsifiable experiment — v26 direct surface servo

Branch checkpoint head before this document: `28c744efb07e86a971e059b1ab51d35667cca8e6`.

New script: `tools/render_mpfb_surface_servo_v26.py`.

Hypothesis: if each bounded CCD joint update recomputes the actual evaluated skinned fingertip surface and rotates that visible surface point toward a fixed flap-face target, contact should converge better than v25's stale offset compensation without changing MPFB morphology or increasing the 24-degree per-joint budget.

The support-wrap path remains the unchanged v23 control. Pinch gates remain strict:

- visible face error <=6 mm per digit;
- visible distance to flap center <=9 mm per digit;
- visible fingertip gap <=10 mm;
- max extra rotation <=24 degrees per joint.

Exact-head workflows started for `28c744ef...`:

- MPFB Surface Servo v26: run `31846706995` — in progress at checkpoint time;
- Godot Check: run `31846706989` — in progress at checkpoint time.

Do not infer success from the workflow starting. Download the artifact and visually inspect the pinch frame before promoting anything.

## Ranked next actions

1. Resolve exact v26 CI result and download its artifact.
2. Read `surface-servo-v26.log` and inspect `surface_v26_pinch.png` at Macro/Meso scale.
3. If v26 closes visible contact without anatomical collapse, proceed to a target/base/candidate hero-limb pose comparison and only then prepare a Godot integration spike.
4. If v26 still misses, do not loosen gates. Determine whether the limitation is target orientation, thumb chain range, or the fixed 24-degree budget from the actual visible frame/log. Make one falsifiable change.
5. Keep all MPFB work isolated from production until real Godot café/bar/market interaction frames improve on the locked references.

## Do not repeat

- Do not return to simple XR-hand subdivision; it improved Micro only.
- Do not graft a procedural tube forearm onto the XR hand; it regressed Macro anatomy/composition.
- Do not use distal-bone endpoint distance as proof of visible fingertip contact.
- Do not accept green Godot CI as proof that the hero pose is visually acceptable.
