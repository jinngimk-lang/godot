# Peel Calm reference convergence checkpoint 67 — flexible lifted-flap integration

Date: 2026-08-17

## Recovery / source of truth

- Locked acceptance set remains `cafe_v1`, `bar_v1`, `market_v1`; runtime captures remain evidence only.
- Checkpoint 66 became the newest source-of-truth during this loop and establishes Window Café as the first completion target.
- Its priority ordering remains authoritative: R1 realistic support-hand anatomy/enclosure is the largest Macro gap; blind numeric hand-pose search remains stopped. The largest independent executable Café foreground gap is cup/lid composition, followed by other non-bone presentation causes.
- This checkpoint records one already-started, bounded Meso loop that was completed without touching the blocked hand-pose search.

## Pre-change evidence

- Product baseline at branch creation: `main@6a743b562883eedb4227da5bc1cdfb21c232a286`.
- Fresh baseline Godot Check: `32006233403` — PASS.
- Fresh baseline runtime artifact: `9280118093`, digest `sha256:9e734def1cbc64bbb41ec936d4db4d80acf7653c7bde1e0d30f72924063009ba`.
- Frames inspected: all nine; specifically `cafe_peel38`, `bar_peel48`, `market_peel45` for this red.
- Visible Meso mismatch: the free partial-peel centerline was nearly chord-flat, so the newly readable backing/contact layers still formed a rigid triangular-card silhouette rather than a flexible lifted paper/label flap.

## Falsifiable hypothesis and RED

Hypothesis: at the real 38–48% evidence range, a visibly larger but bounded free-flap bow will read as flexible paper without breaking physical peeled-length or segment-stretch constraints.

Added `tests/test_peel_flap_arc.gd`, using the same 45% peel geometry and desired grip vector as the runtime capture harness.

RED exact head: `ba21f49150930a537ef5a5a494cc1006004a6dd3`.

- Godot Check `32006485183` — expected FAIL.
- Import and configured default launch passed first.
- Exact objective failure: `FLAP_ARC_RED: lifted flap is too chord-flat for a readable flexible-paper arc; ratio=0.0951`.
- Gate requires normalized chord deviation `>= 0.12` and retains the existing segment-spacing limit `<= nominal * 1.8`.

## Minimal implementation

Exact candidate head: `1414db7ed9f88e78457fde13a25d514be1aec7ba`.

Only `scripts/peel/label_geometry.gd` changes product behavior:

- previous free-flap bow: `min(0.07, free_length * 0.08)`;
- accepted bounded bow: `min(0.09, free_length * 0.11)`.

No hand pose/search, camera, controller authority, vessel geometry, substrate/backing/residue identity, scene lighting, progression, or input behavior changed.

## Exact-head verification and visual gate

- Branch Godot Check `32006556508` — PASS; artifact `9280221062`, digest `sha256:3befc312fc700d76c767ff8143852bec48cf6074a56b2a8f3ca12079c9906389`.
- PR #103 exact-head Godot Check `32006687627` — PASS.
- Real A/B inspected against baseline artifact `9280118093`: `cafe_peel38`, `bar_peel48`, `market_peel45`, plus base/inspect/crumple states.
- Visual verdict: bounded Meso PASS. The lifted flap now has a smoother visible bow instead of a nearly straight chord wedge; the pinch remains on the rendered flap tip; the label-backing/adhesive evidence from the prior integration remains readable; no Macro regression was found.
- Do not reopen this as a curve-amplitude sweep. The accepted change is intentionally one bounded contract, not a new tuning axis.

## Independent Challenger

- Local exact-head Challenger run `32006747285` — PASS.
- Verdict on exact head `1414db7ed9f88e78457fde13a25d514be1aec7ba`:
  - `VERDICT: VERIFIED`
  - `DEFECT: NONE`
  - `EVIDENCE: NO_CONCRETE_DEFECT | ANCHOR: NO_CONCRETE_DEFECT`

## Merge and fresh integration proof

PR #103 was merged with expected-head protection.

- Merged product head: `f20b3ef3275d22b94ab32ef05811ddee7ccd442b`.
- Its parent is checkpoint-66 main `568a4dec6dc23edcd48931ff0938d107b8f35e3c`, so the Café source-of-truth checkpoint is preserved in ancestry.
- Fresh merged-main Godot Check `32007022596` — PASS across import, configured launch, deterministic tests, all smoke/reset/input-isolation gates, and nine-frame capture.
- Fresh merged-main runtime artifact: `9280380657`, digest `sha256:7a0f53129e493f1421f93492458fc5b33fa81c6e80f344beca1b2ed78e98d7e2`.
- Fresh merged `cafe_peel38` was re-inspected; the flexible arc survives integration and the lower-frequency hand/cup mismatches remain plainly visible rather than being masked by this Meso fix.

## Closed red

- Partial-peel free flap no longer reads primarily as a chord-flat rigid triangular card at the locked evidence range.

## Remaining ranked reds

1. **R1 Macro — hero support-hand anatomy / enclosure.** XR hands remain faceted and the support hand does not naturally wrap the cup/bottles. Blind numeric bone/pose search remains forbidden without live native-rig visual authoring or a structurally better hand source.
2. **Café independent Macro/Meso — cup/lid composition.** Per checkpoint 66, the hero cup is too large/cylindrical and the top silhouette lacks a clearly molded black plastic lid. This is the next executable target because it does not require forbidden bone search.
3. Peel-hand whole-hand pinch anatomy remains below reference even though capture alignment to the real flap tip is correct.
4. Micro skin/paper/glass/condensation polish remains subordinate while the lower-frequency foreground silhouette is red.

## Do not repeat

- no CCD / endpoint chasing / grip-number / wrist-orbit-yaw-translation grids for hand posing;
- no arbitrary flap curve-amplitude sweep after this accepted bounded contract;
- do not reopen backing/residue identity unless fresh evidence regresses;
- do not equate CI green with reference completion;
- do not start Micro decoration while the Café hand/cup/lid silhouette is still red.

## Next exact action

Follow checkpoint 66's Café-first source of truth on fresh `main`:

1. Compare `cafe.png` and `cafe_peel38.png` against locked `cafe_v1` at Macro scale.
2. Isolate the independent cup/lid composition gap without touching hand bones: slimmer/tapered paper-cup body, clearly molded black lid silhouette, and preserved hero framing.
3. Add a RED presentation contract for Café cup taper/proportions and lid readability before implementation.
4. Make one reversible candidate on an isolated branch, run exact-head Godot 4.7.1, inspect fresh base + peel + crumple frames, then Challenger before any merge.
