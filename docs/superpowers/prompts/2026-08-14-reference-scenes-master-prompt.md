# Peel Calm — Reference Scene Vertical Slice Master Prompt

You are simultaneously the art director, senior Godot 4.7.1 gameplay engineer, interaction designer, technical artist, test engineer, and adversarial owner of **Peel Calm**.

## Mission

Transform the current prototype into a production-quality tactile vertical slice that evokes the three approved reference frames:

1. **Café / paper takeaway cup** — warm afternoon window light, walnut tabletop, believable café depth, fibrous paper cup and black lid, receipt-style label, soft paper/adhesive residue.
2. **Bar / amber bottle** — dark glossy wooden bar, amber practical lights and shelf bokeh, reflective brown bottle, condensation-like highlights, fibrous label that can tear and leave residue.
3. **Market / clear sparkling bottle** — bright cool commercial light, refrigerator/shelf context, pale counter, clear bottle with pale citrus liquid, crisp printed label and visible residue.

The game must feel **real, beautiful, tactile, quiet, and smooth**, not like an editor prototype.

## Category reframe

The mandatory gold hotspot is an inherited prototype artifact. Delete it as the primary interaction interface. The **visible label itself** is the interaction substrate. A player can press anywhere on the projected label surface to begin a peel. A tiny edge affordance may exist only as an optional visual hint, never as the required input target.

## Interaction contract

- **LMB / touch**: press any visible label area, lift, then peel. Maintain continuous ownership until release.
- Adhesive is not a binary threshold. Pull force first loads a bond, the bond relaxes when force decreases, and sustained pull progressively releases the label.
- A brief force spike must not pop the label off immediately.
- Gentle/moderate pulling preserves label `integrity` and minimizes `residue`.
- Excess speed/force reduces `integrity` and increases `residue`.
- Residual torn paper/adhesive must remain visibly mapped to the product after rough pulls.
- **RMB drag**: inspect/rotate the product smoothly around Y while a support hand remains visually coherent. RMB must not steal LMB/touch peel ownership.
- **Q / E**: previous / next showcase scene. **1 / 2 / 3**: direct Café / Bar / Market navigation. Switching scenes resets transient peel state safely without erasing earned progression.
- **R**: reset current item or move to the next item after completion; **Shift+R**: restart run; **Esc**: pause.
- Paper cup keeps optional post-peel crumple ritual. Glass bottles do not crumple; after peel they stay available for inspection / scene navigation.

## Visual contract

### Composition

- First-person close-up with product centered and hands framing it.
- Camera is calm; no aggressive head-bob, FOV changes, or forced motion.
- Product occupies the dominant middle third; background communicates venue but remains subordinate.

### Café

- Walnut/dark warm tabletop with specular variation.
- Floor-to-ceiling window grammar: large panes, mullions, exterior light blocks / greenery silhouettes.
- Soft café depth: counter, shelves, chairs/tables, warm practical bulbs.
- Warm key from side/window, soft ambient fill, restrained cool rim.

### Bar

- Dark polished counter.
- Back-bar shelves with generic bottle silhouettes only; no real brands/trade dress.
- Amber practical lights and one subtle neon-like accent.
- High contrast but not crushed blacks; bottle silhouette and label remain readable.

### Market

- Pale clean counter.
- Cooler/fridge frames, illuminated shelves, generic product blocks and price-strip geometry.
- Cool white commercial illumination with enough warm skin fill to keep hands natural.

### Materials

- Paper cup: high roughness, subtle tonal variation and seam/base-fold cues.
- Black plastic lid: smoother, stronger grazing highlight, molded ring details.
- Amber bottle: transparent/tinted glass-like material, strong highlights, darker core.
- Clear bottle: transparent glass-like shell plus visible pale citrus liquid core.
- Label: paper/print surface, two-sided, curls during peel.
- Residue: thinner, lighter/rougher torn-paper/adhesive layer hugging the product surface.
- Table and venue surfaces must have distinct material identities rather than one brown roughness value.

## HUD contract

Replace debug-wall text with a restrained reference-style HUD:

- top-left: product/scene name + peel percentage + quality;
- one concise controls line: `LMB Peel anywhere  •  RMB Inspect  •  Q/E Scene  •  1/2/3`;
- contextual single-line coaching only when useful;
- reward text is quiet and brief;
- no timer pressure, punishment loop, streak casino, or oversized economy.

## Architecture

- `SessionModel` declares product and venue profiles; presentation reads them but gameplay authority remains in deterministic models.
- `VenuePresentation` owns scene-only geometry/material/light tuning and can switch profiles idempotently.
- `ProductPresentation` owns decorative product geometry/materials and follows inspection yaw.
- `ResidueVisual` is presentation-only and visualizes deterministic quality metrics.
- `InspectionController` owns deterministic yaw input state.
- `PeelModel` owns adhesive load/progress/integrity/residue.
- `PeelController` owns pointer state machine and projected-label hit region.
- `PeelLab` orchestrates, but does not hide physics rules inside presentation code.

## Verification loop

Use strict RED → GREEN → REFACTOR for behavior. On any failure, identify root cause before changing code.

A candidate is not done until:

- headless parse/import passes;
- unit tests pass;
- existing scene/input/reset/ritual smoke tests pass;
- new venue/product/inspection/residue/navigation smoke tests pass;
- all three scene profiles can be selected deterministically;
- visual capture artifacts exist for Café, Bar, Market and are inspected for composition/readability;
- an independent Challenger reviews the exact PR head;
- any Challenger defect gets a reproducing test before repair.

Do not claim photorealism merely because primitives are present. Optimize the actual viewport toward the approved reference feeling while keeping the implementation repository-local, generic, performant in Godot GL compatibility, reversible, and testable.