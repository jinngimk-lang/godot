# Peel Calm reference convergence checkpoint 68 — Café hero product closed, sleeve red active

Date: 2026-08-17

## Recovery contract

Inherit checkpoints 66–67 and the owner's long-horizon operating directive unchanged: no artificial iteration ceiling, recover from repository evidence, write checkpoints at complex boundaries, trust locked reference images over historical implementation, require real capture comparison in addition to machine-green tests, keep subjective final aesthetics behind the owner playtest gate, and continue while a clear high-value red remains.

Phase 1 remains `cafe_v1`; this checkpoint does **not** declare the Window Café complete.

## Fresh main baseline

- latest main: `8eccf7b9d5a6d69429056b19d1cf3b42964bb609`;
- merged PR #105: `feat: converge Window Café hero cup and molded lid`;
- fresh merged-main Godot Check: `32008945533` — PASS;
- locked Source of Truth remains `/Peel Calm/Acceptance References/v1/cafe_reference.png`.

## Closed red: Café hero cup / molded lid

Valid RED:

- test-only Godot Check `32007078093`;
- import and configured default launch passed;
- failure was confined to the new Café hero-product contract: prototype cup proportions/color/roughness, missing molded-lid layers, flat paper body material, overly slick lid.

Accepted production direction:

- Café cup profile tightened to top radius `0.49`, bottom radius `0.415`, height `1.40`;
- warm off-white paper stock with high roughness;
- bounded procedural paper-fiber material;
- semantic molded black-lid layers `CupLidCrown`, `CupLidSnapRing`, `CupLidTopBead`;
- real peel interaction remained live.

Important root cause discovered during visual review:

- an initial machine-green candidate still rendered the cup orange;
- `VenuePresentation.apply_profile()` rewrote Café lights after child initialization;
- `ReferenceLighting` previously cached the venue id and therefore failed to reclaim final presentation ownership;
- `ReferenceLighting` now reasserts the three-light profile as final presentation authority, giving the hero cup neutral window-side light while retaining the warm café background/table context.

Do not repeat the rejected tactic of merely nudging Café light colors while leaving this ownership race in place.

Final exact-head evidence before squash merge:

- head `17c75e1db00d2327e8fc1f2a8788349ac4cd04c4`;
- Godot Check `32008198771` — PASS through import, default launch, deterministic suites, all smoke tests, and nine-frame capture;
- artifact `9280784058`, digest `sha256:83433a00267bad40c43eec52c9e643900f0b7f72c64fd3499e8e13c77fe61c42`;
- `cafe.png` and `cafe_peel38.png` were visually compared against `cafe_v1`; hero cup/lid was a materially safer direction while the hand/sleeve red remained obvious;
- independent Local Challenger round 2 run `32008391586` completed success through exact-head validation, schema review, grounding, and `Enforce verdict`, therefore the reviewed exact head was grounded `VERIFIED`.

Parallel-merge audit:

- a flexible-flap integration introduced `tests/test_peel_flap_arc.gd` while #105 was in flight;
- before Challenger/merge, #105's runner was audited and updated to preserve that suite;
- do not merge a green stacked branch without repeating this latest-main runner audit.

## Still open in Phase 1

Largest visual red remains hand anatomy / enclosure:

- support hand still does not naturally wrap the cup like `cafe_v1`;
- hands still read substantially more faceted/game-like than the locked reference.

The existing stop condition remains active: do not resume blind numeric skeleton/CCD/endpoint/orbit/per-digit pose search without live visual native-rig authoring or a structurally better hand source.

Independent executable reds remain available without violating that stop condition:

1. programmatic Café sleeve/forearm still reads too tubular;
2. hand/skin material and lighting remain too game-like;
3. Café label face is still darker/browner than the pale receipt-like reference;
4. normal-play UI remains more prominent than the reference.

## Active red: Café sleeve / forearm fabric

Branch: `feat/cafe-sleeve-fabric-v88`.

Valid RED:

- head `ac72115df19ca0c3a83d425f6d62e948805f1687`;
- Godot Check `32008703974`;
- import/default launch passed;
- intended unit failures only: missing explicit non-circular cloth cross-section, Café sleeve still flat/non-procedural material, and generated forearm mesh had no stable UVs.

First GREEN candidate:

- head `dedebbc5192673fe20ef0b3ba6fdfbf06367f91a`;
- Godot Check `32008810794` — full PASS;
- artifact `9280988501`, digest `sha256:fbac5bb834354120a1da3c710e7dc1859179bc544c3dff75c03761554a0e4ac5`;
- **visually rejected** despite full green CI: high-frequency albedo weave produced obvious fingerprint/woodgrain moiré and the sleeve remained too thick.

Do not repeat high-frequency visible albedo weave at the 720p acceptance scale.

Current candidate:

- head `f94345c715df4a865cfaf1387e85fad36a2fd291`;
- Godot Check `32009051831` — PASS;
- candidate keeps hand bones/path/topology unchanged, moves weave mostly into subtle roughness response, reduces albedo modulation, and slims the forearm bridge (`0.112 -> 0.168` radius profile with a flattened/folded cloth cross-section).

## Next exact action

1. Download and visually inspect the latest `f94345c...` capture, especially `cafe.png` and `cafe_peel38.png`, against locked `cafe_v1`.
2. If visually safer, clean-rebase v88 onto latest main because the branch still contains pre-squash #105 history; preserve only the true sleeve increment (`forearm_presentation.gd`, `test_cafe_sleeve_fabric.gd`, latest-main `test_runner.gd` + sleeve suite).
3. Run fresh clean-head Godot Check and inspect its artifact again.
4. Open a focused PR, run exact-head Local Challenger, merge unchanged verified head, then verify fresh main.
5. Write the next checkpoint before switching to the next red category.
6. If the second sleeve candidate is visually unsafe, remain on this red and correct geometry/screen occupancy rather than reopening high-frequency cloth texture experiments.
