# Peel Calm reference convergence checkpoint 57

Date: 2026-08-17

## Production baseline

- Main before this loop: `0980cf729f9f6e6b73fd3c98ee683d2de65f33f0` (checkpoint-only head; runtime behavior from `69a31b4e894459a8af733a522263c6afeb3e2319`).
- Fresh pre-loop merged-main Godot Check: `31971048659` — PASS.
- Fresh pre-loop runtime artifact: `9269793962` (`peel-calm-reference-frames`).
- Main after verifier-grounding infrastructure fix: `6e5cb105ab7746be70bfb87effb069aedfea24e6`.
- Merged-main verifier Godot Check: `31974711841` — PASS.

## Highest visual red and stop condition

R1 remains hero support-hand anatomy / vessel enclosure. Existing stop condition remains in force: do not resume CCD, endpoint chasing, semantic-grip sweeps, angle/orbit/translation grids, or disguised numerical pose search. A trustworthy live native-rig visual-authoring capability is still required before continuing that hand-pose route.

Because that route is tool-blocked, this loop selected the highest-impact objective Meso defect visible in the fresh exact-main frames that does not violate the R1 stop condition.

## Amber glass Meso candidate

Fresh `bar`, `bar_inspect`, and `bar_peel48` frames showed the amber bottle shoulder/neck/body collapsing into the dark bar background and reading too much like an opaque brown mass rather than layered amber glass.

Falsifiable hypothesis: the amber-only layered glass/liquid transmission is too heavy. Reduce only amber outer/liquid opacity and modestly lift amber tint; keep clear glass, hands, camera, lighting, label geometry, scene composition, and interaction unchanged.

### TDD

- Branch: `fix/amber-glass-readability-v57`
- RED head: `8bc018520e39efe7db0b28036a18c9de846f3115`
- RED Godot Check: `31973907211` — failed exactly on new amber outer/liquid transmission contracts.
- Candidate GREEN head: `b17eb2dbc4c48e7b174e4688e88524ff92122263`
- Push Godot Check: `31973956435` — PASS.
- PR Godot Check: `31973958109` — PASS.
- Exact-head runtime artifact: `9270542264`, digest `sha256:3a723ee2c56081e90eb8fb4a5c95f5b36ef60031bc78ecefe5ebba932ed52fb6`.
- Product PR: #65 `fix: improve amber glass readability` — still open; do not merge without grounded independent review.

### Exact change

- Amber outer glass only: lighter amber tint and lower effective alpha.
- Amber liquid only: alpha reduced to `0.14` with a slightly lighter warm color.
- Clear-bottle branch unchanged.
- Existing prohibition on fake rectangular `BottleHighlight` strips unchanged.

### Real-frame verdict

A/B against artifact `9269793962` shows a modest but consistent Meso gain in amber neck/shoulder/body separation while preserving the rest of the scene. This does not close photographic-glass realism and does not displace R1 as the dominant red.

Approximate sampled luminance deltas in the bar frame were positive in the intended bottle regions: neck about `+0.016`, shoulder `+0.010`, lower body `+0.006`.

## Challenger infrastructure defect discovered

PR #65 exposed a verifier-grounding bug rather than a grounded product defect.

- Codex Challenger deterministic exact-head checks completed, but the model step failed because the connected OpenAI API account had no credits. No payment or credential action was performed.
- Local Challenger round 1 and round 2 both returned `NEEDS_FIX`, but each used only `test_product_presentation.gd` as its evidence anchor while asserting that the test did not check structure/materials. The exact test does check continuous `ArrayMesh` structure, layered outer/inner/liquid nodes, absence of stacked shoulder/fake highlight nodes, and amber material alpha thresholds. The reviews were therefore false positives.

Root cause: `tools/validate_local_challenger_verdict.sh` allowed a path/basename that happened to occur in the packet to qualify as a NEEDS_FIX evidence anchor.

## Verifier-grounding fix

- Branch: `fix/local-challenger-anchor-content-v57`
- RED self-test head: `bed7ae867a001f19627930f5b0975bf73256658f`
- RED Godot Check: `31974625081` — failed exactly at `Local Challenger verdict validator self-test`, proving the old validator accepted a path-only anchor.
- GREEN head: `920206eb2e46b052a62cdbb204f73deb405fc550`
- `Local Challenger Packet Self-Test` `31974642819` — PASS.
- Godot Check `31974642837` — PASS including the new grounding self-test and full Godot 4.7.1 suite.
- PR #66 merged with expected-head protection.
- New main: `6e5cb105ab7746be70bfb87effb069aedfea24e6`.
- Fresh merged-main Godot Check `31974711841` — PASS.

New rule: a NEEDS_FIX anchor that is only a `.gd/.yml/.yaml/.sh` path is metadata, not defect evidence. Grounded NEEDS_FIX must quote contiguous code/test content from the exact packet.

## Review gate currently in flight

PR #65 candidate head has not changed: `b17eb2dbc4c48e7b174e4688e88524ff92122263`.

A fresh Local Challenger round 3 has been dispatched after the validator fix landed on main. Its workflow uses the verifier implementation from current `origin/main`, so this is the first meaningful rerun against the repaired grounding gate.

Do not merge PR #65 until this rerun yields a grounded VERIFIED verdict, or a genuinely grounded NEEDS_FIX finding is fixed and all exact-head frame/CI gates are repeated.

## Remaining reds

1. **R1 — hero support-hand anatomy/enclosure**: still the largest reference mismatch and blocked on trustworthy live visual rig authoring; do not return to numerical pose search.
2. **R2 — amber glass photographic optical depth**: v57 improves shoulder/neck readability but remains only a Meso step; further work must remain subordinate to R1 and must use real frames, not fake highlight geometry.
3. **R3 — peel-hand anatomical quality / whole-hand pinch choreography**: actual flap contact evidence is now honest, but hero hand mesh/pose remains prototype quality.
4. Product surface Micro detail (skin, paper fibers, glass micro-highlights, condensation) remains frozen while higher-frequency blockers remain.

## Next exact action

1. Read the fresh Local Challenger round 3 result for PR #65 at exact head `b17eb2dbc4c48e7b174e4688e88524ff92122263`.
2. If grounded VERIFIED, confirm PR head/main have not drifted, merge with expected-head protection, then run a fresh merged-main Godot Check and inspect the new nine-frame artifact before calling the amber Meso step landed.
3. If grounded NEEDS_FIX, add the minimum falsifying test, fix the valid defect, rerun exact-head Godot + frames + Challenger.
4. If verifier infrastructure fails again, do not merge the product candidate; fix/record the verifier failure without creating visual churn.
5. Continue to honor the R1 numerical-pose stop condition and keep Micro polish frozen.
