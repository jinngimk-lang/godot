# Current Handoff — 2026-08-18

## Start here

Repository: `jinngimk-lang/godot`

Start from current `main`, not from old merged feature branches. Baseline before this handoff skill commit was:

`963ed7e582327f22dd7857efef40f5e5a65254ba`

The owner wants autonomous continuation. Do not ask for normal reversible implementation decisions. Inspect the repo, create a fresh branch, make evidence-backed changes, run exact-head Godot verification, inspect captures, and continue on the next visible/tactile defect.

## Owner feedback translated into non-negotiable product requirements

The label previously felt too soft, too eager to fall away, and too much like loose tape. The target is a relaxing paper-label peel with resistance: load first, break adhesive locally, progress only with new outward work, then fully detach at 100%.

The five showcase scenes also previously felt like one room with different objects. They must read as five places/products without relying on HUD labels.

Current approved presentation direction is object-only. **No visible hands/arms and no full-screen still/video gameplay overlay.** Older hand-oriented notes in repository history are not authority for this workstream.

## What is already merged

### Paper resistance / complete release

- Static pointer hold no longer consumes adhesive bond every frame.
- Peel progress requires new outward pointer displacement.
- Initial breakaway peak + deterministic micro-resistance are modeled.
- `CornerPeelPresentation` confines most bend to a narrow front and drives the detached area toward a stiff tangent sheet.
- Printed front and opaque matte backing are separate surfaces with thickness.
- 100% gameplay progress produces complete visual release.
- CI captures attached / mid / 100%-released states for all five products.

Primary checkpoint:
`docs/superpowers/checkpoints/2026-08-18-paper-resistance-and-scene-separation.md`

### Substrate-specific feel

Merged PR #158 introduced per-variant `peel_feel` profiles and runtime binding into controller + paper renderer.

Current relative order:
- Jar: heaviest / most resistant (`4.10 px`, `1.34x`, bend `0.09`, backing `0.0052`)
- Tin: resistant (`3.55 px`, `1.22x`, bend `0.11`, backing `0.0042`)
- Coffee: medium (`3.25 px`, `1.24x`, bend `0.12`, backing `0.0034`)
- Yuzu: cleaner/easier (`2.75 px`, `1.12x`, bend `0.15`, backing `0.0028`)
- Thin soda wrap: lightest/most compliant (`2.40 px`, `1.08x`, bend `0.19`, backing `0.0022`)

Exact-head run for the integrated v4 branch: `32117131925` passed import, default launch, deterministic tests, interaction smokes, and five scene triplet captures.

Checkpoint:
`docs/superpowers/checkpoints/2026-08-18-substrate-peel-feel-v4.md`

### Paper surface

Merged PR #159 added `art/shaders/peeled_paper.gdshader` and moved the printed paper face onto a real-time fibrous shader with micro albedo/roughness/normal response while keeping the backing separate and opaque.

Exact-head run `32117685152` passed all Godot 4.7.1 checks and scene triplet captures. Artifact id: `9317316615`.

### Pre-release tactile audio

Merged PR #160 added restrained audible paper/adhesive loading during real controller `EDGE_LIFT` / `PINCHED`, before actual release. Existing quiet adhesive loops and foreground `paper_flex` / `micro_release` / `final_release` events remain.

Exact-head run `32118119865` passed. `main` then advanced to `963ed7e582327f22dd7857efef40f5e5a65254ba`.

## What is still not proven by automation

Subjective hand-feel/ASMR satisfaction remains experiential. CI can prove no static creep, correct state transitions, full release, parameters, and rendered frames; it cannot prove the owner will judge the mouse motion as sufficiently resistant or satisfying.

Do not claim that subjective feel is solved merely because CI is green.

## Highest-value next work

Continue in this order unless current runtime evidence shows a larger defect:

1. **Product material realism** — glass thickness/refraction cues, metal edge/rim structure and reflection breakup, cup paper/pulp detail, believable contact shadows.
2. **Paper edge realism** — improve exposed paper thickness, torn/fibrous edge response, underside variation and adhesive boundary without making the sheet look fuzzy or dirty.
3. **Five genuinely different environments** — unique environment assets/geometry where reuse still reads as the same room; strengthen Jar pantry/kitchen, Tin grocery/cold-case, Supermarket refrigerated commercial space, Can beverage/convenience counter, Coffee warm café.
4. **Resistance tuning from visual mechanics** — preserve static stall and substrate ordering; if increasing resistance, require more deliberate pointer work rather than adding time-based delay.
5. **Tactile audio polish** — emphasize load → micro-release → final release rhythm while keeping continuous adhesive noise quiet.

For visible changes, always inspect the newest attached/mid/100% captures. A technically correct change that looks worse should be reverted or replaced, not defended.

## Verification rule for the next agent

Use a fresh branch from current `main`. Before merge, verify the exact proposed head with Godot 4.7.1 and inspect generated images. If merged-main CI is not separately observed after merge, say only that the pre-merge exact head was verified; do not silently upgrade that evidence into a post-merge-main claim.