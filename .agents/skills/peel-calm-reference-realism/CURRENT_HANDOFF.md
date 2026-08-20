# Current Handoff — 2026-08-20 Reference Fidelity + Residue Rub

## Start here

Repository: `jinngimk-lang/godot`

Start from current `main`. Do not revive old hand/forearm/crumple branches or treat their screenshots/tests as current product authority.

Read in this order:

1. `.agents/PROJECT_NORTH_STAR.md`
2. this handoff
3. `docs/superpowers/checkpoints/2026-08-20-reference-fidelity-final.md`
4. `docs/superpowers/plans/2026-08-20-reference-fidelity-completion.md`
5. current production code, tests, `Godot Check`, and newest capture artifact

## Owner direction now locked

- Object-only interaction. No visible hand or arm model.
- The small hand-shaped mouse cursor directly grabs paper and later rubs residue.
- No full-screen still/video layer may replace realtime Godot gameplay.
- Target composition remains the supplied Coffee Shop mockup: large centered product, warm defocused environment, left controls/progress, four-step right tutorial, persistent five-scene rail.
- Paper must feel resistant and fibrous, not like loose tape or elastic film.
- The loop does not end at detach. Paper release must settle clear, expose residue, require a fresh LMB rubbing pass, and unlock Continue only after cleaning.

## Current production baseline

### Five realtime scene bundles

- Coffee Shop — kraft paper cup, molded black lid, thermal order label, warm café window.
- Jar — glass/sauce/meniscus/lid details, rustic paper, warm pantry/kitchen.
- Tin Can — metal body/chimes/top details, grocery wrap, cooler merchandising scene.
- Supermarket — clear bottle/liquid/punt/cap, coated paper, refrigerated retail scene.
- Can — aluminum shoulder/top/opening details, thin wrap, beverage/convenience scene.

### Paper and peel

- `CornerPeelPresentation` is final visible label authority; the old simulation ribbon remains hidden.
- The printed face is one continuous 56×40 segmented mesh with bounded cell stretch.
- Gameplay progress is visually compressed at early/mid stages so the 38% reference state keeps most print readable and lifts only the upper-right region.
- Printed face, fibrous backing, paper thickness, adhesive release surface, and vessel residue are separate material semantics.
- 100% produces a stiff arc-length-preserving curl, then lifecycle hold/settle and removal from the hero.

### Post-peel residue rubbing

- `ResidueScrubModel` accepts only pressed movement inside the projected former-label region.
- Hover, stationary hold, and movement outside the region produce no cleaning.
- Short back-and-forth reversals receive extra tactile weight; a one-frame fling is capped.
- `ResidueVisual.set_cleanup_progress()` fades adhesive and paper-fiber layers to zero.
- The software hand cursor animates and displays `RUB ↔` during the cleaning stage.
- The upper-left HUD switches to `Residue Clean N%`.
- Continue and the exact-once completion record remain gated until residue reaches 100% clean.
- Input is quarantined at detach and cleanup completion, requiring a fresh press across boundaries.

## Latest evidence

Local Godot: `4.7.1.stable.official.a13da4feb`.

The integration candidate passed:

- deterministic object-only test runner;
- complete real pointer flow: grab → load → peel → settle → rub → clean → next scene;
- configured default project launch;
- five-scene reference, product-surface, café presentation, reset-loop, pause-isolation, and reset-isolation smokes;
- `git diff --check`;
- 35 runtime captures: attached / peel / release hold / settling / dirty residue / partial scrub / clean for every scene.

Exact detailed checkpoint:
`docs/superpowers/checkpoints/2026-08-20-reference-fidelity-final.md`

After this branch lands, use the merged `main` workflow result as the only merged-main CI claim. Local/pre-merge evidence must not be upgraded into a remote post-merge claim.

## Highest-value next work

1. **Owner feel pass** — tune breakaway peak, travel per release, substrate contrast, scrub duration, cursor oscillation, and Foley levels from local playtest feedback.
2. **Spatial cleaning** — replace uniform whole-footprint fading with a local coverage/mask model so the exact rubbed area clears first. Add restrained adhesive rolls/paper crumbs without turning the effect into dirt or foam.
3. **Cleaning Foley** — add low, dry friction and intermittent tack-release events driven by real scrub motion/reversals; stationary holds must stay silent.
4. **Realtime realism** — continue improving hero silhouettes, glass/metal edge response, paper microstructure, contact shadows, reflections, and environment/live-surface integration.
5. **Release edge polish** — increase irregular tear silhouette and substrate differentiation while preserving print readability and bounded paper stretch.
6. **Settings/touch/performance** — only after PC mouse feel is stable; preserve the same fresh-press and boundary quarantine invariants.

## Do not regress

- No rendered hands/arms.
- No fake still/video gameplay.
- No full-height ribbon peel or stretched printed text.
- No time-based progress from a stationary pointer.
- No immediate Continue at paper detach; residue cleaning is now part of the core completion loop.
- No timer pressure, failure grind, or large meta/economy system before tactile quality is owner-approved.
- Do not claim subjective feel solved from CI alone.
