# Current Handoff — 2026-08-25 Autonomous Stewardship + Reference Fidelity

## Start here

Repository: `jinngimk-lang/godot`

Start from current `main`. Do not revive old hand/forearm/crumple branches or treat their screenshots/tests as current product authority.

Read in this order:

1. `.agents/PROJECT_NORTH_STAR.md`
2. `.agents/PROJECT_KNOWLEDGE.md`
3. this handoff
4. `docs/research/ECOSYSTEM_WATCH.md`
5. `docs/superpowers/checkpoints/2026-08-20-reference-fidelity-final.md`
6. current production code, tests, `Godot Check`, and newest capture artifact

## Owner direction now locked

- Object-only interaction. No visible hand or arm model.
- The small hand-shaped mouse cursor directly grabs paper and later rubs residue.
- No full-screen still/video layer may replace realtime Godot gameplay.
- Target composition remains the supplied Coffee Shop mockup: large centered product, warm defocused environment, left controls/progress, four-step right tutorial, persistent five-scene rail.
- Paper must feel resistant and fibrous, not like loose tape or elastic film.
- The loop does not end at detach. Paper release must settle clear, expose residue, require a fresh LMB rubbing pass, and unlock Continue only after cleaning.
- Normal reversible project/engineering decisions are autonomous. Do not repeatedly ask the owner to choose implementation details when repository evidence can decide them.
- The agent must maintain the North Star/knowledge/handoff so long context or agent replacement cannot erase project direction.
- Relevant GitHub projects, Godot releases, techniques, and project-adjacent developments should be continuously evaluated. External files/code/assets enter production only after relevance, explicit license/provenance, dependency fit, isolated testing, and exact runtime verification.
- Unknown-license external code/assets are never copied. Prefer repository-native implementations over mandatory plugins when practical.

## Current production baseline

### Five realtime scene bundles

- Coffee Shop — kraft paper cup, molded black lid, thermal order label, warm café window.
- Jar — glass/sauce/meniscus/lid details, rustic paper, warm pantry/kitchen.
- Tin Can — metal body/chimes/top details, grocery wrap, cooler merchandising scene.
- Supermarket — clear bottle/liquid/punt/cap, coated paper, refrigerated retail scene.
- Can — aluminum shoulder/top/opening details, thin wrap, beverage/convenience scene.

### Paper and peel

- `CornerPeelPresentation` is final visible label authority; the old simulation ribbon remains hidden.
- The printed face is one continuous segmented mesh with bounded cell stretch.
- Gameplay progress is visually compressed at early/mid stages so representative peel states keep most print readable and lift only a local corner/front.
- Printed face, fibrous backing, paper thickness, adhesive release surface, and vessel residue are separate material semantics.
- 100% produces a stiff bounded curl, then lifecycle hold/settle and removal from the hero.

### Post-peel residue rubbing

- `ResidueScrubModel` accepts only pressed movement inside the projected former-label region.
- Hover, stationary hold, and movement outside the region produce no cleaning.
- Short back-and-forth reversals receive extra tactile weight; one-frame fling contribution is capped.
- `ResidueVisual.set_cleanup_progress()` currently fades adhesive/fiber residue globally.
- The software hand cursor displays `RUB ↔` during the cleaning stage.
- The HUD switches to residue-clean progress.
- Continue and the exact-once completion record remain gated until residue reaches 100% clean.
- Input is quarantined at detach and cleanup completion, requiring a fresh press across boundaries.

## Engine state

- Verified project baseline before this workstream: Godot `4.7.1-stable`.
- Official Godot `4.7.2-stable` was published as a compatible maintenance release and is the active upgrade candidate.
- Do not claim 4.7.2 as project baseline until the exact-head full workflow passes, capture output is inspected, the change is merged, and merged `main` is separately verified.

## Ecosystem scan state

- `maantho/gpu-texture-painter`: MIT, Godot 4.4+, runtime GPU texture painting across meshes. Relevant to spatial/local residue masks. Decision: study architecture/pattern first; do not add a mandatory plugin dependency unless a native solution fails evidence-based evaluation.
- `alfredbaudisch/GodotRuntimeTextureSplatMapPainting`: relevant runtime paint/UV concepts, but inspected repository exposes no explicit license metadata/file. Decision: no copying of source/assets; idea-level research only.
- Record future candidates and decisions in `docs/research/ECOSYSTEM_WATCH.md`.

## Latest verified gameplay evidence

The 2026-08-20 merged baseline on `main` passed:

- deterministic object-only test runner;
- complete real pointer flow: grab → load → peel → settle → rub → clean → next scene;
- configured default project launch;
- five-scene reference/product-surface/presentation/reset/pause/input smokes;
- 35 runtime captures: attached / peel / release hold / settling / dirty residue / partial scrub / clean for every scene.

Exact detailed checkpoint:
`docs/superpowers/checkpoints/2026-08-20-reference-fidelity-final.md`

## Highest-value next work

1. **Spatial/local residue cleaning** — replace uniform whole-footprint fading with a local coverage/mask model so the exact rubbed area clears first. Use vetted runtime-paint research only as architectural inspiration; keep the implementation repository-native and deterministic.
2. **Residue visuals** — add restrained adhesive rolls/tack streaks/paper crumbs that appear where actual rubbing occurs without turning the vessel dirty or noisy.
3. **Cleaning Foley** — low dry friction and intermittent tack-release events driven by real scrub motion/reversals; stationary holds stay silent.
4. **Realtime realism** — continue improving hero silhouettes, glass/metal edge response, paper microstructure, contact shadows, reflections, and environment/live-surface integration.
5. **Release edge polish** — more irregular tear/release silhouette while preserving readable print and bounded stiffness.
6. **Optional vessel-specific post-clean object play** — subtle squeeze/wobble/shake/liquid inertia only when it reinforces vessel material identity and never replaces peel/clean authority.
7. **Settings/touch/performance** — after PC mouse feel is stable.

## Image-first rule

For a visible solution, make or record a practical target frame/template first, extract measurable constraints, implement in realtime Godot, capture the equivalent runtime state, compare directly, fix the largest mismatch, and repeat. CI green alone is never visual completion.

## Do not regress

- No rendered hands/arms.
- No fake still/video gameplay.
- No full-height ribbon peel or stretched printed text.
- No time-based progress from a stationary pointer.
- No immediate Continue at paper detach; residue cleaning remains part of the core completion loop.
- No unlicensed external code/assets.
- No unnecessary runtime plugin/dependency introduced solely because an external project looks sophisticated.
- No timer pressure, failure grind, or large meta/economy system before tactile quality is owner-approved.
- Do not claim subjective feel solved from CI alone.
