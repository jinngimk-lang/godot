# Reference Convergence Checkpoint 75 — visible café lid molding

Date: 2026-08-17

## Resume source

- Production main after the product merge: `ecc5f7b01452b4406d13854f722c95e18400502b`.
- Fresh merged-main Godot Check: run `32032441331` — PASS.
- Fresh merged-main nine-frame artifact: `9289408872`, digest `sha256:12e2b38bc93b22288c8b14a21dc12991b58a830e76cfb9ae7a7459a087f8ee5c`.
- Previous checkpoint: checkpoint 74 on `main@0fa0b8d9bb12b368491a9d17b5e17377f11e66eb`, runtime artifact `9287263447`.
- Locked user-approved café / bar / market acceptance references remain source of truth; runtime screenshots are evidence, not replacement targets.
- Live/native-rig Blender or 3D rigging connector was re-checked and remains unavailable in the current execution environment, so the R1 numeric-search stop condition remained active.

## Closed scoped red — café lid lacked visible molded drinking detail

The fresh café interaction frames still showed the black takeaway lid primarily as broad stacked circular layers. The locked café reference explicitly calls for black lid detail. Because R1 support-hand anatomy remains blocked from further numeric pose search without genuine visual rig authoring, this run selected the lid as an independent, objective Meso structure gap rather than starting Micro polish.

### Failed experiment — hidden legacy owner can make CI green without changing product pixels

An initial branch `fix/cafe-lid-molded-sip-detail-v75` placed a sip tab and vent under `CafePresentation`.

- RED exact head: `385cb919ba399aa0fa7fda2d060b7d62be599082`.
- Godot Check `32031018689` failed specifically in Café presentation smoke because the nodes were absent; earlier import/unit/reference/label checks passed.
- Hidden-geometry GREEN head: `42f4ac89e26167a404df4863461e1cf3f21124fb`.
- Godot Check `32031232559` — PASS.
- Artifact `9288968022`.
- Visual verdict: REJECT. Real café frames showed effectively no lid-region pixel improvement.

Root cause: `PeelLab._disable_legacy_cafe_stage()` intentionally hides the complete `CafePresentation` tree. Therefore a structural test under that hidden owner could pass while the runtime product stayed unchanged.

Do not repeat this route. Any future visual acceptance contract must target the live presentation owner visible in captured gameplay frames.

## RED on the live product owner

A clean branch `fix/cafe-lid-product-molding-v75` was created from `main@0fa0b8d9bb12b368491a9d17b5e17377f11e66eb`.

- RED exact head: `f54c28bfa57bf5f896b032bab6d2039f56e826b5`.
- Godot Check `32031509138` — expected FAILURE exactly at Café presentation smoke.
- The new contract requires a visible `ProductPresentation/CafeLidMoldedDetail` on the live paper-cup product, including a bounded `LidSipTab` and quiet `LidVentDimple`.
- The test explicitly refuses hidden `CafePresentation` geometry as product evidence.

## GREEN / exact-head visual evidence

Implementation adds `CafeLidMoldedPresentation`, a presentation-only helper that anchors the detail to the live `ProductPresentation/CupLidTopBead`.

- Detail exists only while the active product kind is `paper_cup`; amber/clear bottle variants do not inherit it.
- Sip/vent cues are positioned from the actual live top bead instead of hard-coding against the hidden legacy stage.
- No hand pose, camera, receipt, peel physics, vessel dimensions, progression, timers, economy, or Micro material system changed.

Exact candidate head: `408d8195390141179d59fc1c084a73121f8e6cb1`.

- Push Godot Check `32031604059` — PASS.
- Candidate artifact `9289103165`, digest `sha256:f5cc2f6b13b18ef204c8d1162cd2847a3945efa83f9ac5d567de0087b0ed3079`.
- PR #124 Godot Check `32031779871` — PASS on the unchanged exact head.
- Local Independent Challenger `32031995140` — PASS / grounded `VERIFIED`, `DEFECT: NONE` on the same exact head.
- PR #124 merged with expected-head protection as `ecc5f7b01452b4406d13854f722c95e18400502b`.
- Fresh merged-main Godot Check `32032441331` — PASS.
- Fresh merged-main artifact `9289408872`.

## Frames inspected

Candidate artifact `9289103165` and merged-main artifact `9289408872` were inspected across interaction states, especially:

- `cafe.png`
- `cafe_peel38.png`
- `cafe_crumple55.png`

The small molded sip feature is now visibly present on the actual black lid in base, partial-peel and crumple frames. The receipt, cup silhouette, truthful detached crumple state, hands and interaction framing remain stable within this scoped change. The result is intentionally subtle; it closes only the missing lid-structure cue and is not a claim of reference-quality café completion.

## Remaining ranked reds

1. **R1 Macro — hero support-hand anatomy / vessel enclosure.** The current XR-style support hand remains the dominant low-frequency mismatch: insufficient palm volume, thumb opposition, progressive finger depth and true cup/bottle wrap.
2. **R2 Meso — whole-hand peel pinch/contact.** Contact evidence is truthful, but overall peel-hand anatomy/choreography remains below the reference.
3. Other independent Macro/Meso structure gaps may be addressed only when objectively visible and falsifiable in fresh interaction frames while R1 visual authoring capability is unavailable.
4. Micro skin / paper fiber / glass / residue / condensation polish remains deferred while R1/R2 dominate.

## Stop / anti-drift rules still active

Do not resume:

- CCD or endpoint chasing;
- semantic grip scalar sweeps;
- wrist/orbit/yaw/translation grids;
- per-finger numeric pose grids;
- subdivision-density sweeps on the existing authored/XR hand;
- scale/frame/wrist/orbit/yaw/translation/per-finger search around the rejected CC0 MakeHuman fixed `Cup` pose;
- crumple gain sweeps after the rejected `1.85 -> 2.20` experiment;
- lid-size/detail parameter sweeps without new reference evidence;
- visual work placed only under hidden `CafePresentation` and then treated as runtime proof.

CI green is not a visual completion claim.

## Next exact action

Start from `main@ecc5f7b01452b4406d13854f722c95e18400502b` and artifact `9289408872`. Re-check live/native-rig visual-authoring capability first. If it becomes available, return immediately to R1 and require one reference-derived whole-hand support candidate to pass Macro enclosure before production integration. If it remains unavailable, inspect the fresh nine interaction frames and select one independent, objective Macro/Meso structural red. Do not perform another café lid parameter sweep and do not substitute decorative Micro polish for the blocked hand problem.