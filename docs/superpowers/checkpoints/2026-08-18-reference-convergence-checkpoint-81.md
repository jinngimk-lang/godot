# Reference Convergence Checkpoint 81 — Café two-hand crumple staging

Date: 2026-08-18

## Recovery source

This checkpoint supersedes chat-only continuation claims. At the start of this run the repository source of truth was:

- `main@1f4d5ea4cfdd87d63f30824f6d9319c6ee30e3c2`
- newest checkpoint: `2026-08-18-reference-convergence-checkpoint-80.md`
- exact-main Godot Check `32047525652` — PASS
- exact-main runtime artifact `9293426215`
- no open PRs

The master prompt v3 and `.agents/skills/multiscale-reference-convergence/SKILL.md` were reread before work started.

## Highest visible red and scope chosen

R1 remains the dominant Macro red: the hero XR support hand still lacks reference-quality palm volume, progressive finger depth, thumb opposition, and true vessel enclosure. Existing stop conditions remain active: do not resume CCD, endpoint chasing, grip-number, wrist/orbit/yaw/translation, per-finger numeric grids, subdivision-density sweeps, or the rejected fixed-Cup CC0 source without genuinely different visual-authoring capability.

Because live native-rig/Blender visual authoring is still unavailable in the current environment, this run selected an independent Café interaction-state Meso red from `cafe_crumple55`: after the receipt is detached and the paper cup visibly deforms, only the support hand participated in the crumple staging while the released peel hand remained visually detached from the ritual.

## Falsifiable hypothesis

If the released peel hand is owned by `CrumpleHandStaging` during Café crumple, then both presentation roots should move inward/down as crumple progress rises and reset exactly afterward, without modifying hand rig/pose, camera, peel physics, or general hand choreography.

## RED

Branch: `fix/cafe-crumple-two-hand-staging-v81`

RED exact head:

`5b3302485e61b945dcbea25827143bb6b0738dcd`

A new deterministic `tests/test_crumple_hand_staging.gd` contract required the released `RightHand` to move inward during 60% crumple and both hand roots to restore exactly on reset. `tests/test_runner.gd` was updated to execute it.

Godot Check `32060752895` failed at the new Unit contract with:

`RED: released peel hand must also move inward during cafe crumple`

Import/default launch and earlier deterministic gates passed before that failure, so this was a clean scoped RED rather than a parser/infrastructure failure.

## First GREEN and visual rejection of under-correction

First implementation head:

`3042d26f04d547c9026a864c7efa4b358a9305c9`

Godot Check `32060981519` — PASS.

Runtime artifact:

`9298134465`

This implementation bound `RightHand` into `CrumpleHandStaging` and moved both hand presentation roots inward/down with the same 0.085 maximum inward offset. Real `cafe_crumple55` inspection showed that the released peel hand moved materially toward the cup, but a clear air gap remained. Therefore code-green was not accepted as the final visual result.

## Evidence-driven correction

Only one visual variable was changed after the first runtime A/B:

- support-hand maximum inward travel stayed `0.085`
- released peel-hand maximum inward travel became `0.150`
- down travel stayed `0.018`
- no rig/pose edit, CCD, endpoint optimizer, contact servo, grip sweep, orbit/yaw/translation grid, camera change, peel-physics change, or gameplay-authority change was introduced

Final candidate exact head:

`db6f058a667b5994b97cb91d0e387f44b6e97aea`

Push Godot Check `32061211873` — PASS.

Candidate runtime artifact:

`9298210145`

PR #136 exact-head Godot Check `32061363204` — PASS.

The runtime A/B showed the released peel hand moving from clearly detached staging to immediately beside the cup wall while support-hand staging and the crumpled paper silhouette remained stable. The state now reads as a two-hand crumple ritual rather than one hand plus a floating post-peel hand.

Important visual boundary: the released peel hand still retains a small visible air gap in the merged `cafe_crumple55`; this checkpoint does **not** claim physically exact surface contact, and it does not close hand anatomy/pose R1.

## Independent Challenger

Local Independent Challenger run `32061542897` reviewed the unchanged exact product head `db6f058a667b5994b97cb91d0e387f44b6e97aea` and completed all exact-head, packet, schema, grounding, comment, and enforcement steps successfully.

Grounded verdict on PR #136:

- `VERDICT: VERIFIED`
- `DEFECT: NONE`
- `MIN_TEST: NONE`

## Merge and fresh-main proof

PR #136 was squash-merged with expected-head protection.

Merged product commit:

`336844a252b58b556d926f73fd9e5fbaa66a9324`

Fresh merged-main Godot Check:

`32061763948` — PASS

Fresh merged-main runtime artifact:

`9298397108`

Digest:

`sha256:d40f5925b490f1354c3422a9638e6787768759e1110b6b27da8c321c58058470`

The merged `cafe_crumple55` was re-inspected. Both hands remain visibly engaged in the crumple composition after integration; the support hand/cup deformation did not regress. The small released-hand air gap remains a lower-level visible imperfection and must not be silently relabeled as exact contact.

## Closed red

Closed in this checkpoint:

- Café post-peel crumple no longer leaves the released peel hand completely outside the ritual; both hand presentation roots now respond to crumple progress and reset deterministically.

Not closed:

- R1 hero support-hand anatomy / true vessel enclosure
- true physically convincing crumple-hand surface contact
- whole-hand peel pinch quality
- photographic skin/paper/glass/residue/condensation detail

## Failed / rejected experiments

- Symmetric 0.085 inward travel for both hands: technically GREEN but visually under-corrected; preserved as evidence and not treated as completion.
- Do not start an inward-offset sweep from 0.150. Further Café crumple contact work must use rendered-geometry or direct visual-authoring evidence, not a grid of root translations.

## Next exact action

1. On every recovery, first re-check for live native-rig/Blender visual-authoring capability. If it becomes available, return immediately to R1 whole-hand support-grasp authoring against the locked references.
2. If that capability is still unavailable, inspect fresh merged-main interaction frames from artifact `9298397108` and select the next independent, objective Macro/Meso structural red.
3. Do **not** tune Café crumple root offsets again merely to close the remaining few pixels of air gap. If that gap becomes the highest available red, derive contact from the actual rendered crumpled shell / visible pinch anchor or use direct visual authoring, with a new falsifiable contract.
4. Keep Micro polish frozen while R1 remains dominant.
