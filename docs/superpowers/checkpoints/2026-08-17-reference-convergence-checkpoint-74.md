# Reference Convergence Checkpoint 74 — truthful café crumple evidence

Date: 2026-08-17

## Resume source

- Production main after the product/evidence merge: `ac74fe33fcd9e406044f9003564428417511eb81`.
- Fresh merged-main Godot Check: run `32026220310` — PASS.
- Fresh merged-main nine-frame artifact: `9287183187`, digest `sha256:e2e6e3c4358ca6a6d6fb92a6d15cbc1b002cae26b3e1ee5b340aa8a0a55a169c`.
- Previous stable checkpoint: checkpoint 73 on `main@f5fcba71902f34049c711d289901023ce74a20e1`, product runtime artifact `9284148422`.
- Locked acceptance references remain the user-approved café / bar / market family; runtime frames are evidence, never replacement references.

## Closed red — café crumple capture contradicted its own detached-label state

Fresh checkpoint-73 `cafe_crumple55.png` showed `LABEL OFF` in the Journey/HUD while the thermal receipt was visibly attached to the cup. This made the interaction-step evidence internally contradictory and also obscured the actual 55% paper-cup deformation.

Root cause was capture-only staging. `_stage_crumple()` set `PeelLabel.visible = false` but left `LabelLifecycle` in `ATTACHED`. Normal `PeelLab._process()` then reapplied `LabelVisual.set_phase("ATTACHED")` during settle; that method correctly makes the label visible again. Production peel gameplay was not changed by this fix.

### RED

- Branch: `fix/cafe-crumple-detached-label-evidence-v74`.
- RED exact head: `ce6847ea5fd8adf2d8250e6f9e290c9901d3450f`.
- Godot Check `32025635350`.
- All deterministic/product smoke checks passed; the run failed exactly in `Capture cafe bar and market frames` after adding a contract that requires `cafe_crumple55` to remain visually detached and the capture lifecycle to be `HELD` after settle.

### GREEN

- Exact candidate head: `0f58aa4d073cbc863330102ceac8ed5b53117ec0`.
- Push Godot Check `32025738531` — PASS.
- Candidate nine-frame artifact `9287015853`, digest `sha256:08bffcf852e37b0701fda2844b44fe332336ec72edc2ea397db6c47fd8ff34d3`.
- PR #122 Godot Check `32025855410` — PASS on the same exact head.
- Local Independent Challenger `32025927519` — PASS / grounded verdict `VERIFIED`, `DEFECT: NONE` on the same exact head.
- PR #122 merged with expected-head protection as `ac74fe33fcd9e406044f9003564428417511eb81`.
- Fresh merged-main Godot Check `32026220310` — PASS.
- Fresh merged-main artifact `9287183187`.

The capture now advances the real lifecycle through `DETACHING -> HELD` before staging optional café crumpling. The receipt stays absent through settle, `LABEL OFF` matches the picture, and the existing 55% squeeze silhouette is finally visible without a stale paper card covering the cup.

## Frames inspected

Before: artifact `9284148422` from checkpoint 73.
Candidate: artifact `9287015853`.
Merged main: artifact `9287183187`.

Inspected all nine interaction frames:

- `cafe.png`
- `cafe_peel38.png`
- `cafe_crumple55.png`
- `bar.png`
- `bar_peel48.png`
- `bar_inspect.png`
- `market.png`
- `market_peel45.png`
- `market_inspect.png`

Merged `cafe_crumple55` now shows a clean detached cup surface, the existing left-side waist deformation, and no receipt regrowth. Peel/inspect frames remained visually stable within the scoped evidence-only change.

## Failed experiment — do not repeat as a gain sweep

Before finding the stale-label evidence bug, a separate branch tested stronger mid-stage paper-cup compression:

- RED head `2537c0929a3915e5a7383cba743cfc8a842b3b6b`, Godot Check `32025185840`: stricter 60% waist-compression gate failed as intended.
- GREEN head `5d6d4235d475eef5082ddb9f58185752f62ed559`, Godot Check `32025273169`: `VISUAL_COMPRESSION_GAIN` changed `1.85 -> 2.20`; full suite PASS.
- Artifact `9286858142`.
- Visual verdict: REJECT. The apparent benefit was negligible in the real interaction frame while the stale attached receipt was masking the cup deformation.

Do not continue `VISUAL_COMPRESSION_GAIN` or compression-threshold sweeps without new reference evidence. The dominant problem in that frame was evidence-state correctness, now fixed.

## Remaining ranked reds

1. **R1 Macro — hero support-hand anatomy / vessel enclosure.** Current XR-style hand remains open/stylized, with insufficient palm volume, thumb opposition, progressive finger depth and true cup/bottle wrap. This is still the dominant low-frequency mismatch against the locked references.
2. **R2 Meso — whole-hand peel pinch/contact.** The partial-peel evidence is truthful and aligned, but the overall peel-hand anatomy/choreography is still below reference quality.
3. Other independent Macro/Meso structure gaps may be addressed only when they are visible and falsifiable in fresh interaction frames.
4. Micro skin / paper fiber / glass / residue / condensation polish remains deferred while R1/R2 are dominant.

## Stop / anti-drift rules still active

Do not resume:

- CCD or endpoint chasing;
- semantic grip scalar sweeps;
- wrist/orbit/yaw/translation grids;
- per-finger numeric pose grids;
- subdivision-density sweeps on the existing authored/XR hand;
- scale/frame/wrist/orbit/yaw/translation/per-finger search around the rejected CC0 MakeHuman fixed `Cup` pose;
- crumple gain sweeps after the rejected 1.85 -> 2.20 experiment.

CI green is not a visual completion claim.

## Next exact action

Start from `main@ac74fe33fcd9e406044f9003564428417511eb81` and artifact `9287183187`. Re-check whether a genuine live/native-rig visual-authoring or structurally different provenance-safe hand source is available. If yes, return directly to R1 and require a single whole-hand candidate to pass reference-derived Macro enclosure before product integration. If not, inspect the fresh nine interaction frames and select one independent, objective Macro/Meso structural red; do not substitute decorative Micro polish for the blocked R1.
