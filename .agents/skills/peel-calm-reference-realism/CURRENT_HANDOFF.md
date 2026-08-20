# Current Handoff — 2026-08-20

## Start here

Repository: `jinngimk-lang/godot`

Active long-running visual/completion branch:

`feat/completion-lifecycle-and-visual-pass-v7`

Active PR: `#163` — keep it open/draft until the owner-level visual bar is met. Do not merge merely because CI is green.

The owner wants autonomous continuation. Do not ask for normal reversible implementation decisions. Inspect the repo, make evidence-backed changes, run exact-head Godot verification, inspect captures, and continue on the next visible/tactile defect.

Before meaningful continuation reread:

1. `.agents/PROJECT_NORTH_STAR.md`
2. `.agents/skills/peel-calm-reference-realism/SKILL.md`
3. this handoff
4. newest checkpoint(s), especially `docs/superpowers/checkpoints/2026-08-20-post-peel-object-play.md`
5. current PR head, CI and runtime captures

## Owner feedback translated into non-negotiable product requirements

- Object-only direction stays locked: no visible hands/arms and no full-screen still/video gameplay overlay.
- Label must feel like bonded paper, not soft tape: pointer work -> load -> breakaway -> local release.
- Five showcase scenes must read as five places/products, not one room with swapped props.
- `100%` means all printed paper is off the product; the released sheet then settles/resolves out of the hero view.
- The interaction does **not** end when the label disappears. After resolution the bare object gets a short tactile play phase before Continue: squeeze compliant containers, shake products/liquid, RMB inspect, then continue to the next scene.
- Project completion order remains: scene quality -> model quality -> label material -> post-peel handling -> complete interaction flow.
- Visual work uses image-first convergence: practical target -> Godot implementation -> runtime capture -> explicit comparison -> iterate largest mismatch. CI green is necessary but not sufficient.

## Current implemented work on PR #163

### Paper / peel

- Static hold no longer creeps peel progress.
- Initial breakaway and bounded stick-slip resistance are modeled.
- Per-substrate profiles remain distinct: Jar > Tin/Coffee > Yuzu > Soda Can.
- `CornerPeelPresentation` uses a left-origin localized paper flap rather than the old full-width ribbon/tape silhouette.
- Printed front, opaque fibrous backing, paper thickness, adhesive trace and residue are distinct.
- Fully released paper enters lifecycle settle/resolution and no longer floats forever over the product.

### Product / visual passes

- Coffee, Jar, Tin, Yuzu bottle and Soda Can have separate hero-detail paths.
- Tin has been rebuilt toward readable brushed/rolled metal rather than dark plastic.
- Yuzu path includes dedicated bottle polish, clear-glass cues, liquid separation and cap treatment.
- Completion UI/presentation exists but must remain secondary to the hero product.

### Post-peel object play — new owner requirement

Checkpoint: `docs/superpowers/checkpoints/2026-08-20-post-peel-object-play.md`

Runtime files:

- `scripts/interaction/post_peel_object_play.gd`
- `scripts/presentation/post_peel_object_play_presentation.gd`
- scene node `PostPeelObjectPlayPresentation`
- deterministic contract `tests/test_post_peel_object_play.gd`

Approved behavior:

`PEEL -> FULL RELEASE -> LABEL LEAVES -> BARE OBJECT PLAY -> INSPECT/CONTINUE -> NEXT SCENE`

After `LabelLifecycle.is_resolved()`:

- LMB drag becomes object play instead of peel;
- slow/medium drag produces bounded squeeze on compliant paper/aluminum containers;
- fast alternating horizontal drag produces damped shake;
- glass jar/bottle are effectively rigid under squeeze;
- bottle/jar liquid gets lag/tilt inertia during shake;
- RMB still rotates/inspects;
- Continue advances to the next product;
- releasing input lets deformation/shake recover calmly.

## Verification status at this handoff update

The first post-peel object-play RED correctly failed because shake amplitude was too weak. The implementation was strengthened with immediate angular input impulse plus damped follow-through; deterministic tests then passed through unit/smoke stages.

A separate historical CI issue remains in the GL/Xvfb capture harness: after all 15 captures print `PASS`, Godot/llvmpipe can emit a late `resources still in use at exit` diagnostic. The workflow has been tightened to require the explicit capture PASS and all expected image files, while treating only that known post-success renderer teardown line as non-fatal. Any other script/runtime/capture ERROR remains fatal. Do not generalize this exception.

Re-run exact-head CI after every subsequent visual/gameplay change and inspect artifacts. Do not claim exact-head green until the latest commit's run is actually complete.

## Highest-value next work

Continue without changing direction:

1. Capture/verify the new **resolved object-play state**, not only attached/mid/done states. Add practical visual evidence for at least Coffee squeeze, Yuzu shake/liquid lag and Soda Can squeeze/shake.
2. Continue scene realism: Coffee warm café, Jar pantry/kitchen food prep, Tin grocery/cold-case, Yuzu bright refrigerated supermarket, Can convenience/beverage counter. They must remain distinguishable with HUD hidden.
3. Continue hero model realism: glass thickness/highlight breakup, believable metal rims/top seams, paper cup pulp/kraft detail, can shoulder/top structure and contact shadows.
4. Continue paper realism: narrower realistic bend front, exposed fibrous edge, underside variation, adhesive boundary; never regress into ribbon/tape behavior.
5. Finish interaction completeness and feedback: post-peel object play must feel optional, calm and tactile; Continue remains obvious and no state can dead-end.

For visible changes, make/refresh a practical target first, then inspect the newest Godot capture against it. Reject technically-green visual regressions rather than defending them.
