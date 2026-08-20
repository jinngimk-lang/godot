# Reference Fidelity Baseline — 2026-08-20

## Exact source

- Branch: `feat/reference-fidelity-20260820`
- Baseline head: `e2d7cae`
- Engine: `Godot 4.7.1.stable.official.a13da4feb`
- Renderer: OpenGL 3.3 Compatibility on NVIDIA GeForce GT 730
- Locked target family: the four owner-supplied images dated 2026-08-18, with the object-only Coffee Shop gameplay frame as the primary runtime composition target and the three paper/adhesive boards as tactile/material targets.

## Baseline verification

- Godot editor import/parse: PASS.
- Deterministic runner: `PASS: all deterministic object-only tests`.
- Scene, reference scene, label cup-surface, café presentation, repeated reset, pause isolation, and reset isolation smokes: PASS.
- Live capture: `PASS: captured five paper-release triplets`.

## Frames inspected

Attached:

- `coffee.png`
- `jar.png`
- `tin.png`
- `market.png`
- `can.png`

Mid peel:

- `coffee_peel38.png`
- `jar_peel49.png`
- `tin_peel41.png`
- `market_peel45.png`
- `can_peel33.png`

Fully released:

- `coffee_done.png`
- `jar_done.png`
- `tin_done.png`
- `market_done.png`
- `can_done.png`

## Multiscale findings

### Macro

1. Tin shows a large dark diagonal wedge entering from the left edge.
2. Can shows a large grey diagonal wedge behind/through the right tutorial area.
3. Market and Can foreground surfaces read as flat grey screen bands rather than grounded environment surfaces.
4. Market bottle is vertically over-scaled and the cap/neck leaves the frame.
5. Jar, Tin and Can silhouettes still read as assembled primitives instead of believable hero products.
6. HUD is functionally correct but reads as large debug text panels; the owner target uses tighter control rows, a stronger hierarchy, and a richer four-step tutorial panel.

### Meso

1. All mid-peel frames form repeated triangular holes across a diagonal boundary. The result reads as missing mesh triangles, not a continuous paper sheet with an irregular fibrous release edge.
2. The detached label arm is a flat hard board with a single corner, not a stiff sheet with a narrow curved peel-front band and restrained curl.
3. Glass lacks convincing wall thickness, optical depth, and liquid separation.
4. Tin and soda-can top/bottom structures are too simple and material response is flat.
5. Coffee lid and paper cup are readable but materially simpler than the approved frame.
6. Residue exists but reads as repeated geometric patches rather than glue/paper-fiber breakup.

### Micro

1. Paper fibers, torn edge and adhesive boundary are not yet credible at product distance.
2. Metal highlight breakup, glass highlights, condensation, cup pulp and molded lid grooves remain under-resolved.
3. Tutorial imagery/glyph hierarchy and compact input keycaps are missing.

## Full-release finding

All five done frames prove complete geometric release, but the released label remains as a large floating plane that blocks the hero product. The approved lifecycle requires a short readable hold followed by deterministic settle/disposal/collection and an obvious next-ready state.

## Ranked execution order

1. Remove venue/foreground wedges and re-establish safe 16:9 composition for all five products.
2. Upgrade hero silhouettes/material separation, starting with the worst Jar/Tin/Can/Market defects.
3. Replace triangular mid-peel holes with one continuous stiff paper sheet, narrow bend band, irregular fibrous boundary, and vessel-local residue.
4. Add post-release settle/resolution so detached paper no longer floats indefinitely.
5. Tighten HUD hierarchy and tutorial chrome once the center composition is stable.
6. Run the complete interaction and exact-head visual gates.

## Acceptance discipline

The green baseline proves runtime stability, not visual acceptance. Every production change must keep these gates green and must improve freshly captured exact-state frames at Macro before Meso and Micro review.
