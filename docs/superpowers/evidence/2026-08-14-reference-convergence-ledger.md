# Peel Calm reference convergence ledger

## North-star target frames

The approved visual targets are the concrete café paper-cup peel, amber bar bottle peel, and clear yuzu market bottle peel images from the owner conversation. All visual changes use those images as the composition/material/anatomy standard rather than relying on prose alone.

Required loop for each visual batch:

`target frame -> important step/state frames -> exact-head Godot capture -> side-by-side audit -> objective mismatch list -> fix -> recapture`

## Candidate integration

- Branch: `feat/reference-convergence-main-v1`
- Current integration base: latest `main` plus the reference vertical-slice branch.
- First merged candidate: `f4d1bc217fcfd3936ce6174c44fa82185ef51b93`.
- V6 profile repair: `efb67479fb27252c8c642b1f2edaecf79e79fe73`.
- Exact-head run `31780728781`: GREEN after restoring bounded final ice profile.
- Follow-up runtime integration now restores `CupContentsPresentation` into the reference scene and restores its dedicated smoke to CI; this remains pending exact-head verification at the time of this ledger entry.

## Exact-head visual audit — `efb67479...`

### Café target vs runtime

1. **Forearm silhouette — BLOCKING.** Runtime dark sleeves form very large tapered wedges from lower corners and consume substantially more screen area than the target's believable cylindrical forearms/sleeves.
2. **Hand scale/contact — BLOCKING.** Runtime hands read small and pinchy; target support hand wraps the cup side with broad palm/finger contact while peel hand visibly pinches the lifted paper edge.
3. **Cup material — HIGH.** Runtime paper cup is a flat uniform tan surface. Target reads as fibrous matte paper with subtle roughness variation, realistic rolled lip and plastic lid response.
4. **Label deformation — HIGH.** Runtime label can peel and leave residue, but the lifted sheet still reads too clean/geometric compared with target creases, thin paper curl and ragged torn backing.
5. **Venue — ACCEPTABLE DIRECTION.** Warm café background, wood table and lighting now identify the place without HUD, but foreground material response is not yet at target fidelity.

### Bar target vs runtime

1. **Bottle silhouette — BLOCKING.** Runtime shoulder/neck is assembled from primitive cylinders and reads blocky compared with the target's continuous glass loft.
2. **Glass response — BLOCKING.** Runtime amber body is nearly black/red with weak environment reflections; target uses legible amber transmission, strong soft specular highlights and bright edge/refraction cues.
3. **Hands/forearms — BLOCKING.** Same oversized sleeve and undersized-hand issue as café; target support hand convincingly grips the bottle neck/body.
4. **Label fiber/contrast — HIGH.** Runtime dark label loses readability against the dark bottle; target shows a strongly legible printed face plus bright torn fibrous backing.
5. **Venue — ACCEPTABLE DIRECTION.** Warm bar shelf/bokeh composition reads as a bar without HUD.

### Market target vs runtime

1. **Bottle silhouette — BLOCKING.** Runtime clear bottle is a broad cylindrical ghost; target has continuous shoulder, narrow neck, defined lip and believable wall thickness.
2. **Transparency/liquid — BLOCKING.** Runtime body/liquid are washed out and visually merge. Target maintains separate glass, liquid, condensation and highlight layers.
3. **Hands/forearms — BLOCKING.** Target has natural left peel pinch and right stabilizing contact; runtime still reads as small hands attached to oversized wedges.
4. **Label/residue — HIGH.** Runtime label is readable, but residue needs more irregular local breakup and lifted-edge depth.
5. **Venue — ACCEPTABLE DIRECTION.** Cool market/cold-case background and pale counter clearly establish supermarket context.

## Ordered convergence queue

1. Preserve all current-main functional regressions while finishing the reference integration (contained ice node + smoke + actual scene state).
2. Fix forearm/sleeve silhouette and hand scale/contact first; recapture all three scenes.
3. Replace bottle primitive shoulder/body stack with a continuous authored/procedural loft and retune glass response; recapture bar + market.
4. Improve paper cup/lid material separation and paper micro-variation; recapture café.
5. Improve label curl/fiber/residue silhouette for untouched, edge-lift, mid-peel, rough peel, detached residue and inspection states.
6. Add/maintain step-state capture automation so interaction work is reviewed as a sequence, not one hero frame.
7. Run exact-head independent Challenger against both code and captured frames before merge.

## Release gate

Do not call a visual batch complete because tests are green. A batch is merge-ready only when exact-head runtime frames exist and no unresolved BLOCKING mismatch remains in the area changed by that batch. Owner-only subjective comfort remains explicitly distinct from machine-verifiable correctness.
