# Peel Calm reference convergence checkpoint 56

Date: 2026-08-17
Production main after merge: `69a31b4e894459a8af733a522263c6afeb3e2319`
Merged PR: #60 — `fix: quiet persistent reference HUD`

## Acceptance reference status

The locked café / bar / market acceptance references remain unchanged. This batch closes a Macro presentation-density mismatch while the higher-impact hero-hand R1 remains blocked by the checkpointed requirement for direct native-rig visual authoring. It does not redefine the target and does not claim hand realism is complete.

## Closed defect — persistent HUD competed with reference photography

The previous reference HUD occupied roughly 650×104 px and persisted as a four-line status/control wall. It duplicated product/title information and continuously exposed `Quality`, `residue`, and `1/2/3` shortcut text. At thumbnail/Macro scale this consumed a disproportionate part of the photographic composition even though the locked references are visually quiet.

### RED proof

- Initial HUD-density RED run: `31968110663`
- The new compact-HUD contract did not exist and failed before implementation.
- The final deterministic contract requires the normal reference HUD to stay at most two persistent lines, panel height <= 68 px, width <= 560 px, and to omit `Quality`, `residue`, and `1/2/3` while preserving essential player affordances.

### Fix

`HudChromePresentation` now compacts the authoritative gameplay HUD into a quieter two-line player-facing presentation:

- panel approximately 540×64 px;
- reduced background/shadow opacity;
- peel progress retained;
- dynamic hint shortened;
- mouse/touch peel retained;
- RMB inspect retained;
- Q/E scene navigation retained;
- Esc Pause and R Reset retained;
- persistent debug/status-wall fragments removed.

The implementation is idempotent across process frames and includes compact paused-state copy. No hand pose/model, vessel, peel physics, venue, camera, material, audio, progression, or interaction authority changed.

## Exact-head verification

### Builder GREEN

- Exact candidate head: `c4f9da27b05c8929eade0fab8d61993ed7e4cdcf`
- Exact-head Godot Check: `31968384067` — PASS
- Candidate visual artifact: `9269084618` (`peel-calm-reference-frames`)
- Nine café/bar/market base + interaction frames were captured on the exact candidate.
- Direct before/after review showed materially more venue/background photography visible without gameplay or scene-composition changes.

### Independent Challenger

Earlier local Challenger rounds were verifier-infrastructure failures or produced weakly grounded prose. Main subsequently landed a path-focused, fail-closed grounding validator and its self-test passed as run `31970269525`.

A fresh exact-head Challenger was then dispatched against the unchanged PR head:

- Round 6 exact head: `c4f9da27b05c8929eade0fab8d61993ed7e4cdcf`
- Verdict: `VERIFIED`
- The current grounded validator accepted the report on the exact candidate head.

The earlier `INFRA_FAILURE` comments are not product defects and are not reused as verification.

## Merge and fresh main verification

- PR #60 squash-merged with expected-head protection.
- New main: `69a31b4e894459a8af733a522263c6afeb3e2319`
- Fresh merged-main Godot Check: `31971048659` — PASS
- Every import/default-launch/unit/scene/smoke/reset/pause/input-isolation gate passed.
- Fresh merged-main runtime artifact: `9269793962` (`peel-calm-reference-frames`)
- Artifact digest: `sha256:5686627833b3d5e0ccb0e18d03a701f956b8110af5fd32ddcbfd301eceaed9ad`

No branch-green result is being reused as integration proof.

## Multiscale result

### Macro — improved

Persistent HUD density is materially reduced and no longer reads as a four-line debug/status wall competing with the venue photography. The compact panel preserves discoverability while returning screen area to the scene.

### Meso — unchanged by design

Hand/object contact, bottle/cup geometry, label geometry, glass/liquid readability, and interaction choreography were intentionally not changed in this batch.

### Micro — frozen

Skin, paper fibers, glass highlight breakup, liquid/condensation and other high-frequency polish remain frozen while a higher-impact hero-hand Macro/Meso mismatch remains.

## Current reds, ranked

### R1 — Hero support-hand anatomy / enclosure

Still the dominant visible mismatch. Current XR-style hand anatomy/faceting and support-grasp enclosure do not meet the locked references. The stop condition remains in force: do not resume CCD, endpoint chasing, semantic-grip number sweeps, angle/orbit/translation grids, or disguised numerical pose search.

Approved route: direct native-rig visual authoring in a live Blender viewport using `.agents/skills/blender-mcp-visual-rig-authoring/SKILL.md`, followed by 192×108 Macro, unobstructed Meso, same-rig export, Godot bar/market same-camera A/B, and Challenger. The present automation environment still lacks a live Blender/3D rig-editing connector.

### R2 — Peel-hand anatomy / pose quality

The truthful partial-peel evidence now proves the pinch is at the rendered flap, but the underlying XR hand remains prototype quality.

### R3 — Remaining objective Macro/Meso scene/product mismatches

If live native-rig authoring is unavailable, inspect the fresh exact-main frames and select only an objectively verifiable Macro/Meso defect that does not violate the R1 stop condition. Do not fall through to Micro polish merely because hand authoring is tool-blocked.

## Do not repeat

- Do not restore the persistent `Quality`, `residue`, product-title duplication, or `1/2/3` shortcut wall.
- Do not remove Pause/Reset or Q/E scene discoverability merely to make the HUD smaller.
- Do not treat old Challenger `INFRA_FAILURE` comments as product failures.
- Do not use an old branch artifact as merged-main proof.
- Do not reopen numerical support-grasp search while direct visual authoring is the declared requirement.
- Do not start Micro material polish while an objective Macro/Meso red remains available.

## Next exact action

Start from `main@69a31b4e894459a8af733a522263c6afeb3e2319` and fresh artifact `9269793962`. First check whether a live Blender/rigging connector is available. If available, resume R1 direct native-rig support-grasp authoring. If unavailable, preserve the R1 stop condition and use the fresh café/bar/market base + interaction frames to identify the next highest-impact objective Macro/Meso mismatch that can be changed and falsified without numerical hand-pose search. Keep the compact HUD contract and truthful partial-peel contact evidence intact.
