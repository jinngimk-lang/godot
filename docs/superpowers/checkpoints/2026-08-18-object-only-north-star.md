# Object-Only North Star — Visual Convergence Checkpoint

Last reviewed: 2026-08-18

Re-read together with:
- `docs/superpowers/specs/2026-08-18-realtime-reference-rebuild-v2-design.md`
- `docs/superpowers/plans/2026-08-18-realtime-reference-rebuild-v2.md`

## Direction lock

Do not reintroduce visible hands/arms or video/still gameplay playback. The approved target is the latest object-only Coffee Shop mockup: photoreal hero object, real-time label peel, small white hand cursor, left controls, right HOW TO PLAY, persistent five-scene rail.

## Exact-head verified baseline

Head: `1c73a9269905369d50358015749e1f1027a8dec0`
Workflow: `Godot Check` run `32109578906`
Result: **SUCCESS**

Verified in GitHub Actions with Godot 4.7.1:
- import/parse guard: PASS
- configured project launch: PASS
- deterministic tests: PASS
- object-only scene smoke: PASS
- five-scene navigation smoke: PASS
- label surface smoke: PASS
- Coffee Shop presentation smoke: PASS
- reset loop: PASS
- pause input isolation: PASS
- reset input isolation: PASS
- five base + five mid-peel screenshot captures: PASS
- screenshot artifact upload: PASS

Artifact: `peel-calm-object-only-reference-frames`, id `9314370774`.

## What improved versus the hand-era build

- No visible hand or arm geometry remains in the gameplay scene.
- Mouse position drives the real LabelVisual directly.
- Repository-owned hand-shaped cursor is rendered in the viewport and therefore appears in runtime evidence.
- Five scenes exist and are directly selectable: Coffee Shop / Jar / Tin Can / Supermarket / Can.
- Hero scale is materially closer to the approved mockup.
- Coffee Shop cup is now warm kraft rather than white plastic-looking paper.
- Camera is higher and reveals more lid/product top surface.
- HUD contains the approved progress/controls/how-to/rail structure.

## Current visual REDs — do not merge

### 1. Label peel topology is wrong for the approved mockup

Current `coffee_peel38.png` still peels an entire full-height strip and twists printed copy. The approved image shows a localized corner/edge lift: most label copy stays flat/readable while one corner curls and exposes an irregular adhesive patch.

**Next architectural fix:** stop using the old hand-era full-height ribbon as final render authority. Build a real-time corner-peel presentation driven by the existing scalar peel progress and pointer grip. The simulation can remain scalar, but the visible mesh should advance diagonally from a corner rather than translating a full-height vertical front.

Acceptance at ~38%:
- at least ~60% of label face remains visually flat/readable;
- one corner forms a broad paper flap, not a ribbon;
- flap tip aligns with the software hand cursor;
- adhesive/residue patch has an irregular paper/glue boundary.

### 2. Counter/table still looks procedural

Current lower half is a large dark homogeneous polygon. The approved mockup has visible wood grain, warm specular streaks, photographic depth, and a believable contact surface.

**Next fix:** strengthen procedural wood structure/clearcoat and reduce the visual seam between backdrop and live table. If the underlying backdrop has a usable counter region, bias the live surface toward translucent integration rather than an opaque stage block.

### 3. Coffee lid/body still need product-level detail

Current lid reads as stacked black geometry but remains too simple; cup paper lacks enough micro-variation compared with the approved mockup.

**Next fix:** lid crown/inset/rim proportions, warmer paper response, subtle seam/base fold, better local highlight balance.

### 4. Jar silhouette is still a primitive cylinder

Current jar lacks shoulder/neck geometry, glass thickness read, and realistic metal lid threading. Sauce contents occupy too much of the glass and make it read as a red cylinder.

**Next fix:** lathed jar silhouette with base thickness, shoulder, short neck, threaded lid bands, inset sauce volume.

### 5. Tin Can and Soda Can need manufactured-metal silhouettes

Current tin/can are readable but still basic cylinders. Need shoulder taper, rolled seams, top disk/tab detail, brushed-metal response, and better label-to-metal contrast.

### 6. Supermarket glass needs stronger separation

Bottle silhouette is acceptable, but glass/liquid/condensation still merge into a pale translucent mass. Need clearer glass edge response, liquid meniscus/volume, and more readable label/residue separation.

### 7. HUD is structurally correct but not pixel-converged

Current panels are heavier and more rectangular than the approved mockup. Typography, margins, progress bar, right tutorial hierarchy, and rail proportions need another visual pass after hero/label topology is fixed.

## Next execution order

1. Corner-peel render topology + cursor contact.
2. Coffee Shop table/cup/lid convergence.
3. Jar silhouette/material.
4. Tin Can silhouette/material.
5. Supermarket glass/liquid separation.
6. Soda Can silhouette/material.
7. HUD pixel/proportion pass.
8. Re-capture all ten frames and update this checkpoint.
9. Delete remaining unreferenced crumple/contents/ritual code/tests.
10. Only then mark PR ready and merge.
