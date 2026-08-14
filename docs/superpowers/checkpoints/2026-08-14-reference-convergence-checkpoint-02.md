# Reference Convergence Checkpoint 02 — Hand Contact

Date: 2026-08-14

Branch: `feat/reference-hand-contact-v2`

Base checkpoint: `4e19a2fba5db64d2698efa622e58ef570d55bc7f`

## Goal

Reduce the highest-impact hand/object mismatch without accepting a code-green visual regression. The reference frames show the support hand actually stabilizing the vessel: palm close to the side wall, fingers disappearing behind the silhouette, no obvious air gap.

## Falsified experiment: authored `Cup` pose

A first isolated experiment on `feat/reference-hand-pose-v2` changed the support authored animation from `Default pose` to the asset's `Cup` pose.

- TDD RED: `1996e236a98943e7410441abff70717e581b4f0a`
- RED run: `31788805144`
- Implementation head: `1fd83777b8d6b1b3d261efe65a88695a608b7e56`
- Exact-head Godot Check: `31788992113` — PASS
- Runtime artifact: `9214661775`

Frame comparison rejected the experiment. The `Cup` animation curled the support hand into an upward claw beside the café cup, amber bottle, and market bottle. Functional tests were green, but anatomy/contact read worse than checkpoint 01. The branch is preserved only as negative evidence and is not a merge candidate.

## Accepted experiment: move the existing support pose into contact

The visually stronger `Default pose` was retained. Instead, only non-café support staging was moved inward/deeper and rotated toward the vessel so fingers overlap the bottle silhouette during inspection.

### RED

Test head: `3d294f5e77d5c23a03795bd7367e8818aee09ce7`

Godot Check `31789218192` failed exactly at the new presentation constraint:

`FOREARM_RED: RED: glass support hand must stage close enough to overlap the vessel silhouette; x=0.774`

### Implementation

Implementation head: `840594fcd52d64ba8673492d1a6e5ed64cc77955`

Changes:

- bounded glass support target moved from approximately `x=0.71 + yaw` to `x=0.60 + yaw`;
- support depth moved closer to the bottle surface;
- support yaw increased so the palm turns toward the vessel;
- café staging remains untouched;
- no timer, penalty, score pressure, or economy change.

Verification at implementation head:

- deterministic unit tests: PASS;
- scene/reference/label/café/crumple/contents/forearm/ritual/reset/pause smokes: PASS;
- nine runtime frame capture: PASS;
- runtime artifact: `9214790703`.

## Visual comparison result

Compared with checkpoint 01 artifact `9214159817`:

- café frames are intentionally unchanged;
- amber-bar support fingertips now cross the bottle silhouette instead of hovering beside it;
- market support fingertips likewise overlap the clear bottle, giving a stronger stabilizing-contact read;
- inspection states preserve bounded support-hand follow;
- the change is materially better than the rejected stock `Cup` pose experiment.

## Remaining ranked REDs

1. **Hand asset/skin realism remains the largest gap.** Faceted topology, flat skin response, and stock finger proportions still read as prototype quality at reference scale. Any replacement asset or img-to-3D result must pass rights, topology, PBR, rig/weight, Godot import, performance, and frame gates.
2. **Forearm anatomy remains synthetic.** The generated forearms still read as smooth tapered tubes and need wrist/elbow form improvement or a higher-quality rigged arm solution.
3. **Glass optical richness is still limited.** Amber and clear bottles need stronger thickness/refraction/highlight cues without harming label readability.
4. **Surface detail is too clean.** Paper fiber, label micro-wrinkle, residue edge breakup, condensation, and glass micro-imperfections remain sparse.
5. **Peeling-hand contact still needs choreography refinement.** The pinch hand remains visibly faceted and sometimes claw-like at the lifted edge.
6. **HUD remains denser than the target references.** Reduce only after core tactile visuals are stronger.

## Resume rule

Do not reopen the rejected `Cup` pose experiment unless a new target-frame hypothesis explains why the animation would be reoriented or retargeted differently. Continue from real runtime evidence. Prefer a higher-quality hand/arm asset pipeline next; if no suitable permissive rigged asset survives evaluation, research img-to-3D/multiview generation and treat all generated meshes as staging until the repository asset gate passes.
