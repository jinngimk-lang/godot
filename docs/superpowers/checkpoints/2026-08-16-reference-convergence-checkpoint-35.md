# Peel Calm reference convergence checkpoint 35

Date: 2026-08-16
Branch: `spike/mpfb-hero-limb-artist-direct-v78`
Production main baseline: `769d6452e75112084f537af99be90721c2629cd5`
Candidate code head: `4ad0af7762c203439b53bd5599ad351943412898`
Evidence-persisted branch head before this checkpoint: `7a261b8ccbe6de11e3cae1deeeb1599fcbcaacd3`
Godot Check: run `31915233033` — PASS on candidate code head
MPFB Artist Direct v78: run `31915233055` — PASS
MPFB visual artifact: `9254765371`
Locked references: `bar_v1`, `market_v1`

## What changed

Checkpoint 34 required the next attempt to stop scripted angle-table/sweep work and pose the native GameEngine rig as one visible shape. This loop therefore added a reproducible direct-artist authoring bridge rather than another contact/IK solver:

- `tools/diagnose_mpfb_artist_scene_v78.py` measures the twelve editable non-thumb bones in the fixed 192x108 authoring camera without changing pose.
- `.github/workflows/mpfb-artist-direct-v78.yml` rebuilds the v77 `.blend`, persists the diagnostic, and can realize exactly one committed artist gesture.
- `art/mpfb/support-wrap-v78-artist-pose.json` contains one manually chosen screen-space whole-finger gesture, not a parameter grid.
- `tools/apply_mpfb_artist_pose_v78.py` rotates the twelve existing pose bones once toward those committed artist handles, parent-first, with no search/scoring/optimization loop. Wrist and the v74 thumb are frozen and verified unchanged.

The diagnostic made the v77 silhouette failure concrete. At 192x108 the seed finger chains reverse direction after each proximal segment: proximal travels generally right/down, while PIP/DIP turn back right/up. That zig-zag is the visible fist/claw grammar.

## Exact technical evidence

Godot remained completely green on the candidate exact head. The MPFB workflow also completed all steps, including real Blender 4.2.0 + MPFB 2.0.17 reconstruction, pose application, four renders, same-rig pose persistence, and artifact upload.

Frozen wrist/thumb matrix max absolute delta after the one-shot artist gesture: `0.0`.

Observed post-pose screen chains (head -> tail, 192x108, rounded):

- index: `(115,56)->(143,62)`, `(143,62)->(129,74)`, `(129,74)->(125,87)`
- middle: `(89,64)->(124,72)`, `(124,72)->(107,83)`, `(107,83)->(124,90)`
- ring: `(70,68)->(100,73)`, `(100,73)->(90,84)`, `(90,84)->(85,94)`
- pinky: `(55,68)->(77,71)`, `(77,71)->(78,79)`, `(78,79)->(66,83)`

These coordinates prove the script is realizing the committed gesture and not silently leaving the v77 pose unchanged.

## Visual verdict — REJECT

Technical green does **not** satisfy the visual gate.

### Macro

`support-wrap-v78-thumbnail.png` still does not read as the relaxed firm support grip in the locked bar/market references. The pose becomes a compact claw underneath the palm. Several digits collapse into one lower silhouette rather than progressively wrapping around the far side of the vessel.

### Meso

`support-wrap-v78-anatomy-oblique.png` makes the defect unambiguous:

- middle/ring/pinky bend too sharply downward and interpenetrate visually;
- the digit chains form hook-like kinks rather than smooth knuckle-to-tip arcs;
- finger separation/web spaces are poor;
- the v74 thumb remains readable, but the four-finger side does not oppose it as a natural cylindrical grip.

The direct-artist bridge itself is useful and verified, but this first artist gesture is **not** a production pose and must not enter Godot product-camera staging.

## What this falsifies

A screen-space artist-handle representation is technically capable of driving the native rig while preserving frozen bones, but the first handle set over-curled the fingers. This is not evidence to return to CCD, endpoint chasing, contact servo, local-axis tables, whole-hand orbit search, or parameter sweeps. Those remain closed routes.

## Remaining reds

### R1 — Whole four-finger support-grip silhouette

Still the dominant mismatch. The next direct artist edit must keep each digit chain as one smooth arc, preserve separation, and avoid the PIP/DIP reversal/clump seen in v78.

### R2 — Godot product-camera proof

Blocked until R1 passes 192x108 + unobstructed anatomy staging.

### R3 — Peel-hand label pinch

Blocked behind support-grip R1/R2.

### R4 — Micro polish

Skin/PBR, paper fibers, glass micro-highlights and condensation remain intentionally frozen.

## Do not repeat

- CCD / endpoint optimization / contact servo
- scalar tolerance/angle sweeps
- generic local-axis tables
- whole-hand orbit-angle search
- v76-style scripted fan/curl correction
- the exact v78 first handle set, which visibly over-curled/clumped the fingers

## Next exact action

Perform **one evidence-derived artist correction**, not a sweep: retain the verified direct-authoring bridge and frozen v74 wrist/thumb, but redraw the four screen-space finger arcs from the v78 rendered result so that proximal→intermediate→distal motion remains smooth and separated. Reduce excessive camera-depth curl. Render the same 192x108 vessel view and unobstructed anatomy view. If this corrected direct artist gesture still cannot produce a natural support grip, stop numeric authoring entirely and preserve the v77/v78 `.blend` as the explicit interactive Blender handoff instead of opening another scripted search family.
