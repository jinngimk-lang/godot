# Peel Calm reference convergence checkpoint 14

Date: 2026-08-15
Branch: `spike/mpfb-hero-limb-anatomical-grasp-v40`
Production baseline: `main@769d6452e75112084f537af99be90721c2629cd5`
Parent experimental head: `spike/mpfb-hero-limb-authored-grasp-v39@9fe5f6d663afb5f5573bfa208e09a6f67b356b02`
v39 Godot Check: run `31862329150` — PASS
v39 MPFB Authored Grasp: run `31862329230` — PASS
v39 artifact: `9241011566`

## v39 visual verdict

All six mixed-axis candidates were inspected side-by-side at the same scale. v39 is **visually rejected** for Godot product staging.

- `soft` and `medium` variants remain too open and read as a hand laid over/hovering above the vessel rather than enclosing it.
- `firm` closes more, but the four fingers still form a hanging claw silhouette instead of believable vessel-wrap opposition.
- switching the thumb between `thumb_x` and `thumb_z` does not create a readable opposing thumb across the vessel.
- the palm/root placement is better than the earliest MPFB attempts, but digit articulation is still structurally wrong at Macro/Meso scale.

This rejects the v39 abstraction: a shared Z-flexion family plus one proximal X fan is not sufficient. Endpoint/contact metrics remain diagnostic only.

## Updated falsifiable hypothesis — v40

The remaining problem is likely local joint-axis heterogeneity rather than insufficient flexion magnitude. v40 therefore removes the assumption that proximal/intermediate/distal joints of all digits share the same bending axis.

A small per-joint anatomical pose table now assigns each visible finger joint an explicit `(local axis, signed angle)` pair. Three structurally different tables are rendered:

1. `prox_x_pip_z` — proximal X preserves the readable hand volume while PIP/DIP Z supply wrap;
2. `prox_z_pip_x` — proximal Z starts the wrap while PIP X prevents the long Z-only claw arc;
3. `alternating` — X/Z/X distributes curvature across different local joint families.

Each is combined with two independent thumb tables (`thumb_xy`, `thumb_yz`) for six fixed candidates.

No CCD, no fingertip target chasing, no tolerance relaxation, and no production runtime integration are introduced.

Added:

- `tools/render_mpfb_anatomical_grasp_v40.py`
- `.github/workflows/mpfb-anatomical-grasp-v40.yml`

## Visual gate

A v40 candidate is promotable only if the fixed render shows all of:

1. immediate human vessel-wrap silhouette at thumbnail scale;
2. palm visibly enclosing the vessel rather than hovering over it;
3. thumb crossing/opposing the four fingers around the vessel;
4. natural index→pinky ordering without long parallel tines;
5. no severe self-intersection or detached-looking phalanges;
6. continuous wrist/forearm flow compatible with the approved café/bar/market reference family.

If all six fail, do not return to CCD, shared-axis profiles, or bigger flexion angles. The next step is direct artist-authored Blender posing (or a more anatomically constrained rig/pose source) followed by the same fixed-camera gate.

## Current priority

R1 remains continuous hero hand-wrist-forearm anatomy plus believable whole-hand choreography.
R2 remains real support-wrap and label-pinch contact.
Skin/PBR, paper fibers, glass micro-highlights and condensation remain deferred until Macro/Meso hand structure passes.
