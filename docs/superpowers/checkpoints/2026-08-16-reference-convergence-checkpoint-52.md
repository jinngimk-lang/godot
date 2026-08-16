# Peel Calm reference convergence checkpoint 52

Date: 2026-08-16
Production main baseline: `769d6452e75112084f537af99be90721c2629cd5`
Latest support-hand staging checkpoint before this loop: checkpoint 51 on `spike/mpfb-whole-hand-enclosure-v92`

## Locked acceptance contract

The user-approved `cafe_v1`, `bar_v1`, and `market_v1` references remain unchanged. Runtime/staging captures are evidence only and do not redefine the target.

Macro -> Meso -> Micro ordering remains mandatory. Skin, paper-fiber, glass/liquid and condensation Micro work remains frozen while hero-hand structure/contact reds remain.

## R1 support-hand status

Checkpoint 51 already falsified further code-authored wrist translation/yaw and grip-scalar searching: v92 remained a large open near/front C-shape instead of a firm vessel enclosure.

This run restored the repository's pinned Blender 4.2.0 local-tool artifact (`9261034264`) and the editable native-rig v87 authoring scene (`9260246842`) locally. Inspecting the real seven semantic controls confirmed that continuing automated Y/Z response searching would only recreate the prohibited transform-guessing loop.

**Stop condition preserved:** do not create a v93 grid/sweep. R1 next requires a genuinely visually authored native-rig whole-hand pose, not another coded transform guess.

## New evidence-chain defect found in peel captures

`tests/capture_reference_frames.gd::_stage_peel()` requested `hand.set_pinch_amount(1.0)` but then advanced `HandVisual` with `tick(0.0)`. `HandVisual.tick()` intentionally smooths `_pinch_amount` by delta, so zero delta left the captured dynamic hand in relaxed `Pinch Up` instead of the active authored pinch.

That made the mandatory partial-peel screenshots misleading: they visually suggested the active gameplay pinch while actually staging the relaxed hand.

### Capture-only correction

Branch: `fix/reference-peel-capture-pinch-v1`
Exact head: `92281a4a834cb596cfa687dc9bd369b814b7f3eb`
Change: advance one bounded `hand.tick(0.1)` before reading/aliging the real thumb/index pinch anchor.
Live gameplay behavior: unchanged.
Godot Check: run `31954927875` — PASS.
Reference-frame artifact: `9265682730`.

Visual result: evidence is now truthful about the active `Pinch Tight` pose, but the pose still does **not** reach the locked reference-quality paper pinch. R3 remains open.

PR: #51 `fix: capture the actual active peel pinch pose`.
Independent Challenger was dispatched against exact PR head `92281a4a834cb596cfa687dc9bd369b814b7f3eb`; do not merge unless the exact-head review clears the capture-only claim.

## Pinch Flat hypothesis — falsified

Godot XR Tools' authored hand-pose family includes `Pinch Flat`, making it a reasonable falsifiable hypothesis for a thin-paper label.

### TDD RED

Branch: `fix/peel-flat-pinch-v2`
Test-only head: `d54089a32c3cd2232123db784cd37e78ffa89ab1`
Godot Check: run `31955057979` — expected FAIL at unit tests because production still reports `Pinch Tight`.

### Visual spike before production mutation

Branch: `spike/pinch-flat-visual-v1`
Exact visual head: `e5fd86745d0af8d4ac6eabdf83c633b668966539`
Godot Check: run `31955129169` — PASS.
Reference-frame artifact: `9265735969`.

The spike forces bundled `Pinch Flat` in capture staging only, refreshes the actual thumb/index anchor, then aligns that anchor to the staged flap.

**Visual verdict: REJECT.** Compared with the corrected `Pinch Tight` capture, `Pinch Flat` changes local digit posture but does not materially improve Macro/Meso readability of a human thumb/index actually pinching the lifted flap in café/bar/market frames. It must not be promoted into production `HandVisual` merely because the animation exists.

## Closed / clarified items this loop

- Closed: partial-peel reference capture was not actually advancing into the requested active pinch state.
- Clarified: correcting the staging bug does not itself close R3.
- Falsified: swapping `Pinch Tight` to bundled `Pinch Flat` is not sufficient for reference-quality label pinch.
- Preserved: no live gameplay mutation from either visual experiment.
- Preserved: no Micro polish while hero-hand Macro/Meso remains dominant.

## Remaining reds, ranked

### R1 — Support-hand whole-hand enclosure

Still requires genuine native-rig direct visual authoring. Do not resume wrist translation/yaw grids, grip-scalar escalation, CCD, endpoint/contact servo, orbit/axis sweeps, or arbitrary scale changes.

### R2 — Product-camera proof for a passing hero support hand

Only after R1 passes thumbnail Macro + unobstructed Meso should the candidate enter same-camera bar/market XR A/B and Challenger.

### R3 — Peel-hand hero pinch/contact

Current XR authored `Pinch Tight` and `Pinch Flat` both fail the reference-quality visual gate. The next valid solution is a better hero-hand pose/model path where thumb/index visibly oppose on the real flap while palm/wrist follow naturally; do not keep cycling stock animation names.

### R4+ — Micro materials

Skin PBR, paper fibers, glass/liquid, condensation and other Micro work remain deferred.

## Next exact action

1. Resolve PR #51 exact-head independent Challenger. Merge only the capture-evidence fix if the exact head is technically verified and still capture-only.
2. Do **not** promote `Pinch Flat` to production.
3. Resume R1 only when a genuine native-rig visually authored support pose source is available; otherwise use the same hero-hand asset/model work to solve R3 rather than performing another transform/animation-name sweep.
4. Any future partial-peel visual claim must use the corrected active-pose capture staging and inspect café/bar/market interaction frames, not only base frames.
