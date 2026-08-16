# Peel Calm reference convergence checkpoint 55

Date: 2026-08-17
Production main after merge: `87770c984ae5e30757063f49ad23db9380d931ee`
Merged PR: #58 — `fix: align reference peel hand with rendered flap`

## Acceptance reference status

The locked café / bar / market acceptance references remain unchanged. This batch changes capture truthfulness only; it does not redefine the target and does not claim support-hand realism is complete.

## Closed defect — partial-peel hand captured at unreachable raw grip

The reference capture helper intentionally requested a large peel pull but moved the peel hand to that raw request. `LabelGeometry` independently clamped the rendered paper endpoint to the physically reachable free-paper chord. Normal gameplay already resolves the target first through `LabelVisual.get_effective_grip()`.

The result was fake visual evidence: the authored `Pinch Tight` hand could be internally aligned to its requested target while visibly pinching empty air because the rendered flap ended elsewhere.

### RED proof

- Branch candidate: `99778a24d99f95ede4c893ee15aead3c305cbeaa`
- Godot Check: `31964944196`
- All earlier import/default-launch/unit/smoke/reset/input gates passed.
- Capture failed with a measured café hand-to-rendered-flap mismatch of **0.730674 m**.

### Fix

`tests/capture_reference_frames.gd` now keeps the same exaggerated desired pull for a readable partial-peel state, resolves it using `label.get_effective_grip(progress, desired_grip_local)` exactly like gameplay, independently asks the label for the rendered peel points from the same request, asserts the effective hand target matches `flap_points[0]` within `0.0005 m`, and only then places the `Pinch Tight` hand at that truthful endpoint.

No production gameplay code, pose asset, model, camera, scene selection, progress value, residue state, or capture-owner freeze/resume logic was changed.

## Exact-head verification

### Builder GREEN

- Exact head: `ea5ce39b8d3db3f92e3b690702c2fc1f0710a470`
- Push Godot Check: `31965037945` — PASS
- Artifact: `9268253411` (`peel-calm-reference-frames`)
- PR Godot Check: `31965140235` — PASS

Visual A/B inspection of café/bar/market partial-peel frames showed the peel hand moving from clearly detached empty-air pinch locations onto the actual lifted paper endpoint. Café/bar/market base frames, café crumple, and bar/market inspect states remained visually stable.

### Independent Challenger

- Local exact-head Challenger: `31965185319` — PASS / `VERDICT: VERIFIED`
- Challenged exact head: `ea5ce39b8d3db3f92e3b690702c2fc1f0710a470`
- OpenAI Codex Challenger: `31965183686` — infrastructure failure only. Deterministic verification passed, but model inference stopped because the configured API account had no credits remaining. No paid action was taken and this was not treated as a product defect or verification result.

## Merge and fresh main verification

- PR #58 squash-merged with expected-head protection.
- New main: `87770c984ae5e30757063f49ad23db9380d931ee`
- Fresh merged-main Godot Check: `31965366847` — PASS
- Fresh merged-main runtime artifact: `9268338772` (`peel-calm-reference-frames`)

The merge therefore has both exact-candidate verification and fresh merged-main verification; no branch-green result is being reused as integration proof.

## Current reds, ranked

### R1 — Hero support-hand realism remains the dominant visual blocker

Current XR-style hand anatomy / faceting and support-grasp enclosure still do not meet the locked references. Previous checkpoints established a stop condition against returning to CCD, endpoint chasing, grip-number sweeps, angle grids, whole-hand orbit grids, or other disguised numerical pose search.

The approved next route remains direct native-rig visual authoring in a live Blender viewport using `.agents/skills/blender-mcp-visual-rig-authoring/SKILL.md`, followed by 192×108 Macro, unobstructed Meso, same-rig export, Godot bar/market same-camera A/B, and Challenger. The current automation environment still lacks a live Blender / 3D rig-editing connector, so do not violate the stop condition to manufacture another numeric candidate.

### R2 — Peel-hand anatomy / pose quality

The capture now truthfully proves where the pinch occurs, but the underlying XR hand is still prototype-quality. Do not confuse the closed capture-contact defect with a solved hero-hand asset.

### R3 — Glass / paper / surface Micro realism

Remain frozen while a higher-frequency hand/anatomy red dominates, per the multiscale prompt.

## Do not repeat

- Do not stage the capture hand at an unclamped desired grip while rendering paper from a clamped grip.
- Do not accept internal hand-target alignment as proof that the fingers touch rendered geometry.
- Do not treat Codex Challenger credit exhaustion as a product failure or spend money to bypass it.
- Do not reopen numerical support-grasp search while direct visual authoring is the declared requirement.

## Next exact action

At the next run, first inspect whether a live Blender/rigging connector is actually available. If yes, resume R1 through the checkpoint-54 visual-rig-authoring skill and make exactly one direct visual support-grasp candidate. If not, preserve the R1 stop condition and select the next highest-impact objectively verifiable Macro/Meso defect that can be improved without pretending a numerical pose search is artist authoring. Continue using the now-truthful partial-peel capture frames as evidence.
