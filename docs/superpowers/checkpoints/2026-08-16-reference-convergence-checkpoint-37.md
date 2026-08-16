# Peel Calm reference convergence checkpoint 37

Date: 2026-08-16
Branch: `spike/mpfb-artist-ingest-gate-v1`
Verified implementation head before this checkpoint: `f63757b28ed8a35da502db7d29c88e7b2382cef8`
Production main baseline: `769d6452e75112084f537af99be90721c2629cd5`
Open product PRs at start of run: none

## Exact-head verification

- Godot Check: run `31918529198` — **PASS** on `f63757b28ed8a35da502db7d29c88e7b2382cef8`
- Godot reference-frame artifact: `9255640607` (`peel-calm-reference-frames`)
- MPFB Artist Blend Ingest Gate: run `31918529200` — **PASS** on the same head
- Artist-ingest artifact: `9255669737` (`mpfb-artist-ingest-gate`)
- Calibration source: v78 artifact from run `31915509197`, intentionally already known to be a Macro visual reject.

## Why this loop exists

Checkpoint 36 closed the screen-space numeric-handle family. The next required abstraction is genuinely visual native-rig posing, but the current automation runtime does not provide an interactive Blender viewport or a Blender/3D posing connector. Reopening tail-pixel, Euler, CCD, endpoint, contact-servo, or parameter-search logic would violate the evidence-backed stop condition.

The highest-value reversible work for this run was therefore to create a trustworthy handoff from a visually edited native-rig `.blend` into the existing evidence/verification loop, without generating or altering the pose.

## What changed

Added `tools/ingest_mpfb_artist_blend.py` and `.github/workflows/mpfb-artist-ingest-gate.yml`.

The ingest gate:

1. accepts a v77-derived artist-edited `.blend` from a workflow artifact;
2. verifies the native GameEngine authoring rig, locked vessel proxy, `bar_v1,market_v1` reference set, embedded guide, and exact editable/frozen bone contract;
3. compares `wrist.R` plus the three v74 thumb bones against the committed v77 seed and rejects any frozen-bone drift above `1e-5`;
4. requires at least one of the twelve allowed non-thumb finger bones to actually differ from the v77 seed;
5. does **not** run a pose generator, CCD, endpoint optimizer, contact servo, root orbit, or parameter sweep;
6. serializes the current same-rig canonical pose without touching edit-bone roll/rest structure;
7. renders fixed-camera `192x108` Macro evidence plus full and unobstructed Meso anatomy evidence;
8. leaves `visual_verdict` explicitly `UNSET` so a technical PASS can never auto-promote the candidate.

The workflow is reusable with `workflow_dispatch` inputs for a future artist-edited workflow run/artifact. Its push calibration deliberately downloads the known-rejected v78 `.blend` so the bridge can be proven without inventing another pose.

## Calibration result

The known v78 blend passed the **technical handoff** exactly as intended:

- native GameEngine rig: true;
- frozen wrist/thumb matrix max delta vs v77 seed: `0.0`;
- all 12 allowed non-thumb finger bones differ from the seed;
- max allowed edited-bone matrix delta vs seed: about `1.59587`;
- pose generator / sweep / CCD / endpoint optimizer / contact servo / root orbit: all false;
- visual verdict remained `UNSET — human Macro/Meso review required`.

The newly rendered evidence faithfully reproduces the existing v78 visual failure rather than hiding it. At `192x108` the hand still reads as a flattened/stacked finger shape against the vessel rather than a relaxed human bottle enclosure. The unobstructed oblique anatomy view still shows the fingers collapsing into a layered distal cluster instead of clean progressive index→middle→ring→pinky wrap. This is expected for the calibration source and proves the ingest gate does not confuse technical validity with visual acceptance.

## Closed risk

**Artist-edit handoff risk is closed.** A future visually edited native GameEngine `.blend` can now be consumed without rebuilding the pose numerically, while preserving the locked wrist/thumb/reference contract and producing the exact Macro/Meso evidence required for acceptance.

This is infrastructure progress, not a claim that R1 is visually solved.

## Current reds, ranked

### R1 — genuine native-rig whole-hand artist pose

Still the dominant blocker. The next candidate must be created by direct visual manipulation of the native GameEngine rig, not by another numeric pose table/search. At `192x108`, first glance must read as a relaxed but firm bottle support grip: palm near/around the vessel, index least closed, middle/ring/pinky progressively wrapping to the far contour, and the existing opposing thumb remaining readable.

### R2 — Godot product-camera proof

Only after R1 passes staging Macro/Meso: import the accepted same-rig pose/hero limb into bar and market product-camera staging, capture exact-head runtime frames, and compare against current XR baseline plus locked `bar_v1` / `market_v1` intent.

### R3 — peel-hand pinch

After support-hand replacement proves viable, author the peel-hand whole-hand approach/pinch so thumb/index meet the real flap while palm/wrist follow naturally.

### R4 — Micro polish

Skin PBR, paper fibers, glass/condensation/highlight breakup remain frozen until lower-frequency hand structure passes.

## Do not repeat

- CCD / endpoint chasing / contact-distance minimization;
- scalar angle or local-axis sweeps;
- whole-hand orbit sweeps;
- screen-space `tail_px` / `away_from_camera` authoring tables;
- calling fixed Euler tables “artist posing”;
- changing reference/camera/vessel to make a bad grasp look better;
- promoting a technical PASS without the `192x108` Macro and unobstructed Meso visual gates.

## Next exact action

Acquire or use a genuinely visual native-rig pose-editing path and start from the durable v78/v77-derived authoring scene. Directly manipulate the twelve non-thumb finger bones as one whole silhouette while initially preserving wrist and v74 thumb. Feed the resulting `.blend` into `MPFB Artist Blend Ingest Gate` via its source run/artifact inputs. Inspect `artist-candidate-thumbnail.png` first, then the unobstructed anatomy views. If Macro/Meso passes, stop pose research and proceed to Godot bar/market product-camera comparison; if it fails, make one direct visual correction in the authoring scene rather than reopening procedural search.
