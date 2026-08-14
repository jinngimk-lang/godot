# Peel Calm reference convergence checkpoint 01

Date: 2026-08-14
Branch: `feat/reference-scenes-v2-latest-main`
Verified production head before this checkpoint: `cb9eb1eb5f42d99c268834dd873846faf9e994bb`
Exact-head Godot Check: run `31787703685` — PASS
Captured visual artifact: `peel-calm-reference-frames`, artifact id `9214159817`

## Acceptance references

The game is judged against the user-approved close-up reference frames, not against the old prototype screenshot.

1. **Window café / paper cup**
   - Warm window-lit café and real wood table.
   - Cup occupies a strong but not oversized center foreground.
   - Two large, believable human hands; support hand wraps the cup and peel hand pinches a lifted paper flap.
   - Matte fibrous paper, layered black lid, label fibers/residue visible during partial peel.
2. **Amber bar bottle**
   - Slender dark amber glass with strong edge/specular highlights and visible optical depth.
   - Warm practical-light bar background with rich bokeh, not a recolored café.
   - Natural bare forearms/hands; support hand grips bottle rather than points at it.
   - Fibrous dark label, rough torn backing and residue during peel.
3. **Market citrus bottle**
   - Slender transparent glass bottle, pale citrus liquid and condensation.
   - Cooler/supermarket environment with bright neutral light.
   - Large natural hands; clear support contact and lifted label flap.
   - Glass remains transparent enough to read liquid/ice and background distortion.

## What this checkpoint fixed

- Rebased/reference-scene work onto the latest V6 content baseline rather than replacing it.
- Three venue profiles now drive separate café, bar and market presentation.
- Amber and clear bottles use continuous lathed presentation meshes instead of stacked cylinder silhouettes.
- Glass interaction authority is separate from visible glass rendering.
- Paper crumple presentation no longer re-enables the hidden glass interaction cylinder.
- Fresh item reset restores attached label visibility after crumple/inspection stages.
- Paper label is opaque/depth-writing and physically offset outside glass.
- Forearms continue past frame edges instead of ending as visible capped tubes.
- Camera was moved toward tactile close-up framing.
- CI captures nine mandatory frames: café/bar/market base, partial peel, and crumple/inspect states.
- Existing V6 market contents contract remains three deterministic ice cubes.

## Current visual reds, ranked

### R1 — Hands are still prototype quality

The enlarged Godot XR hand assets expose faceted topology, flat skin response, and unsuitable stock poses. This is now the largest mismatch in all three reference comparisons. The support hand looks open/pointing rather than wrapping the cup/bottle, especially in bar and market frames.

**Next loop:** evaluate higher-fidelity CC0/permissive hand assets and, if necessary, an image-to-3D/multiview reconstruction staging pipeline. Any candidate must pass license/provenance, retopology/poly budget, PBR, rig/pose, import and real-frame checks before replacing the production hand.

### R2 — Forearm anatomy still reads as a generated tube

Reach/crop is correct, but cross-section and wrist/hand transition are too smooth and cylindrical. Café sleeve also lacks fabric construction at the cuff.

**Next loop:** replace generated forearm tube with a hand/forearm-integrated mesh or a better skinned extension; do not solve by merely adding radius.

### R3 — Glass still needs photographic optical cues

The visible bottle is now the correct glass presentation model, but it needs environment reflections/highlight breakup, more convincing wall thickness, and better liquid/ice readability. Amber should be glossy dark brown rather than uniformly red/brown; market should be clearer and brighter.

### R4 — Product surface detail is too clean

Paper cup needs micro-roughness/fiber breakup; black lid needs grooves/rings; labels need fiber edge breakup, torn paper thickness and stronger residue patterns. Current residue is procedural and readable but still synthetic.

### R5 — Hand-object contact and pose choreography

Peel hand must pinch the actual flap corner; support hand must wrap the vessel with thumb/fingers on opposite sides. Inspection should preserve contact while rotating. Partial-peel capture must show a clear lifted arc rather than a flat printed strip.

### R6 — HUD still competes with photography

The overlay is quieter than the prototype but still too dense. Keep controls discoverable while reducing persistent status text and removing debug-like language from the normal presentation.

## Continuous loop protocol

For every subsequent visual change:

1. Start from the latest exact branch head and read the most recent checkpoint.
2. Compare the nine production captures with the three approved reference families.
3. Pick the highest-impact visible mismatch; avoid broad speculative rewrites.
4. Make one reversible production change and add/adjust a regression gate when the defect is objective.
5. Run the full Godot Check on the exact head.
6. Download and inspect all nine captured frames, including interaction steps.
7. Do not call the loop successful merely because tests are green.
8. Commit a new checkpoint when a meaningful visual milestone is stable or before context/tool changes.

## Asset pipeline rule

External/generated 3D is a staging source, never an automatic production dependency. Candidate assets must have documented rights, clean topology/retopology, bounded triangle/material counts, PBR textures with known provenance, predictable scale/origin, a useful hand rig or pose path, Godot 4.7.1 import success, deterministic tests where applicable, and direct screenshot comparison before promotion.
