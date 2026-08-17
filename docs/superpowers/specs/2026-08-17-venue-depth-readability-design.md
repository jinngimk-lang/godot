# Venue Depth Readability Design

Date: 2026-08-17

## Problem

Fresh merged-main runtime artifact `9277817340` was compared directly with locked `cafe_v1`, `bar_v1`, and `market_v1`. R1 hand anatomy/enclosure remains the largest red but is stop-conditioned until live Blender/native-rig visual authoring is available. The highest independent Macro defect is venue flattening: `ReferenceBackdrop` is an opaque Sprite3D at z=-1.43 and `reference_backdrop.gd` forcibly hides every visual/light child under the three `VenuePresentation` roots. The result keeps the photographic plate but suppresses the structural depth geometry that should make café/bar/market read as places rather than blurred wallpaper.

## Design

Move the reference plate behind the authored venue depth geometry instead of putting it in front and masking the stage. Place the plate around z=-2.52 and increase its world width from 7.45 to about 9.10 so projected coverage remains stable at the validated camera. Remove the blanket visual/light masking; the existing venue z-layout already puts large back walls/exterior fillers behind the plate while useful counters, shelves, products, cooler frames, chairs and practicals sit in front of it.

This preserves the locked plate as atmosphere while restoring real Godot geometry, parallax cues and practical-light depth. No hand pose, forearm, camera, vessel, label, gameplay or HUD values change in this batch.

## Acceptance

- `ReferenceBackdrop` remains present and covers the frame with no exposed side bars.
- The plate sits behind structural venue props rather than in front of them.
- Café, bar and market each retain visible representative depth geometry after profile switching.
- Fresh exact-head nine-frame captures improve venue readability at Macro scale without regressing hero-product composition or interaction-state ownership.
- If runtime evidence becomes more blockout-like or less reference-like, reject/revert even if CI is green.
- R1 hand stop condition remains unchanged.
