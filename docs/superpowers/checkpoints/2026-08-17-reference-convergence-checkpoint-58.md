# Peel Calm reference convergence checkpoint 58

Date: 2026-08-17

## Production baseline before this loop

- `main`: `e3ff0139f09e5626d6f5ae4dd9b038bb6cc6e79d`
- Fresh merged-main Godot Check before candidate: `31974825140` — PASS
- Before runtime artifact: `9270764558` (`peel-calm-reference-frames`)
- Locked acceptance set remains unchanged: `cafe_v1`, `bar_v1`, `market_v1`.

## Highest actionable red selected

R1 hero-hand anatomy/enclosure remains the largest overall mismatch, but the current automation environment still has no live native-rig Blender authoring connector. Existing stop conditions prohibit returning to CCD, endpoint chasing, grip-number sweeps, joint-axis searches, orbit/yaw/translation grids, or other numeric hand-pose search.

The newest exact-main nine-frame review exposed an independent Macro defect that could be fixed without violating that stop condition: both procedural forearms occupied a broad low-frequency band across café/bar/market and read as straight beams competing with the hero vessel/background.

Falsifiable hypothesis: **the dominant beam-like occupancy was caused mainly by the procedural forearm cross-section, so reducing only `_radius_profile()` should restore negative space without changing hand pose, grip/contact, camera, curve path, labels, materials, or gameplay.**

## TDD RED

Branch: `fix/forearm-silhouette-occupancy-v58`

RED exact head: `713fdf58115bbe6835aa674c5f4f0b68e7745c7f`

Change: tighten `tests/smoke_forearm_presentation.gd` so the maximum hero-forearm radius is `<= 0.21`.

Godot Check: `31975340104` — expected FAIL at **Forearm presentation smoke**. Import/parse, default launch, unit, scene, reference, café, crumple, and contents gates had already passed, so the RED was localized to the intended silhouette contract.

## Production change

GREEN exact head: `f57293343f4c15a4c8ebefc99f379e1ab01a93ae`

Only `_radius_profile()` changed:

- wrist radius: about `0.155 -> 0.130`
- far radius: about `0.285 -> 0.200`
- mid bulge amplitude: `0.065 -> 0.030`

Frozen by design:

- forearm curve/control/end path
- authored-hand scale
- hand/root choreography
- support and peel grip/contact
- camera/FOV
- venue materials
- label/product geometry
- gameplay/progression/input

Exact-head Godot Check `31975391867` — PASS.

Exact-head candidate artifact `9270902914`, digest `sha256:63538944f4ee0ee849602f4f5fa885b7f5333d528e272c543afb1e7c2538e594`.

## Visual verdict

Compared candidate nine frames directly against before artifact `9270764558`.

### Macro

PASS / improved for this scoped defect:

- café/bar/market foreground arms consume materially less screen area;
- hero cup/bottles and background regain negative space;
- the change is visible in base, inspect, peel, and café crumple states;
- no camera/framing or object-size substitution was used to create the improvement.

### Meso

No regression observed in the scoped states:

- hand positions and interaction contacts remain unchanged;
- inspect state remains coherent;
- partial-peel evidence remains aligned with the rendered flap;
- café crumple state remains intact.

### Remaining mismatch

This does **not** close R1. Hands remain visibly low-poly/open in support poses, and the procedural forearm still lacks real anatomical wrist/elbow form. The change only removes excess low-frequency occupancy.

## Challenger infrastructure repair

PR #68 exact product head was independently challenged.

Round 1 local analysis completed but failed closed because the normalizer copied a real code line and appended one comma to the evidence anchor. Codex Challenger separately failed because the configured API account had no remaining credits; no paid/credit action was taken and that was not treated as a product verdict.

A narrow fail-closed verifier repair was made in PR #69 and merged to main as `224ddf3411c494ced3ca6c27cd2428efce2ec42c`:

- only one trailing `, ; : .` may be removed;
- only when the repaired >=16-character anchor occurs exactly once verbatim in the exact packet;
- no internal whitespace/text fuzzy matching;
- ambiguous or missing anchors still fail;
- the verdict JSON is rewritten to the exact packet substring before the existing strict checks/reporting.

PR #69 Godot Check `31975782607` — PASS, including the repository's **Local Challenger verdict validator self-test** and all Godot/runtime capture gates.

Local Challenger round 2 then re-reviewed the unchanged PR #68 exact product head `f57293343f4c15a4c8ebefc99f379e1ab01a93ae`:

- run `31975843498` — PASS
- verdict: `VERIFIED`

## Merge and fresh integration proof

PR #68 merged with expected-head protection.

Merged production code head: `6012a290bb6f9df833a010a9cb2dacd4565e9ebc`.

Fresh merged-main Godot Check: `31976087478` — PASS, including:

- validator self-test
- Godot 4.7.1 import/parse
- configured project launch
- unit tests
- scene/reference/café/crumple/contents/forearm/ritual smoke
- repeated reset
- pause/reset input isolation
- fresh café/bar/market frame capture

Fresh merged-main runtime artifact: `9271084009`, digest `sha256:0e608fece52c7aa7ca2471f31dad4dc984e8e7d36a6590fb81b83ba52cd93df8`.

The merged-main nine frames were inspected again; the slimmer-forearm Macro improvement survives integration and interaction-state captures remain stable.

## Current reds, ranked

### R1 — Hero support-hand anatomy and enclosure

Still dominant. Current XR hands remain faceted and the support hand does not yet read like the locked bar/market reference grip. Resume direct native-rig visual authoring when a live Blender/rigging capability exists. Do not reopen numerical pose-search families already rejected.

### R2 — Forearm anatomy / hand-wrist transition

Occupancy is now better, but the procedural limb still reads generated: hard/simple bend language and weak anatomical transition remain visible. Do **not** perform another radius sweep. If R1 remains tool-blocked, the next forearm experiment must change one structural anatomy variable (for example path/transition form), preserve the new radius cap, and use the same nine-frame Macro/Meso gate.

### R3 — Peel-hand whole-hand pinch choreography

Actual rendered-flap contact evidence is now correct, but the whole hand remains prototype-like. This should use the same future direct-rig authoring route, not endpoint/angle search.

### R4 — Product/material refinement

Paper/glass/skin microdetail remains lower priority while the hero actor silhouette is still visibly wrong. Keep Micro polish frozen unless a higher-level blocker is unavailable and the chosen change is objectively independent.

## Do not repeat

- Do not restore the previous `0.155 -> 0.285` broad forearm profile.
- Do not start another forearm-radius grid/sweep from this success.
- Do not claim the slimmer procedural forearm solves human anatomy.
- Do not return to CCD, endpoint chasing, grip scalar sweeps, local-axis tables, or whole-hand transform grids for support-hand posing.
- Do not treat Codex credit exhaustion as a product failure or spend/recharge credits automatically.
- Do not weaken Challenger grounding to make a model verdict pass; the one-character resolver remains exact and fail-closed.

## Next exact action

1. Start from production code head `6012a290bb6f9df833a010a9cb2dacd4565e9ebc` plus this checkpoint document.
2. Inspect fresh artifact `9271084009` against locked `cafe_v1 / bar_v1 / market_v1` at thumbnail Macro first.
3. If live Blender/native-rig visual authoring is available, resume R1 support-hand whole-hand authoring immediately.
4. If it is still unavailable, choose the highest remaining objective Macro/Meso defect that does not require numerical hand-pose search; current candidate is forearm anatomy/path/transition, **not radius**.
5. Use one reversible variable, RED gate when objective, exact-head Godot Check, fresh affected interaction frames, independent Challenger, and fresh merged-main verification before integration.
