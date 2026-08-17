# OpenGameArt / MakeHuman FPS arms — CC0 source receipt

This file records the source used to generate the structural left support-hand candidate in Peel Calm.

## Upstream

- OpenGameArt page: `https://opengameart.org/content/fps-arms-rigged-only`
- Download archive: `https://opengameart.org/sites/default/files/fps%20arms.7z`
- Pinned archive SHA-256: `31f6c7bd5caea8856c4aafca8461f38a3c8bfdd3d8f05c898e403b9475e54562`
- Native Blender file used: `FPS ARMS RIG 1 test anim.blend`
- Texture carried by the source: `new_diff.png`
- License published with the asset: CC0 1.0 / public-domain dedication.
- Upstream description identifies the model as MakeHuman-derived FPS arms with a rig and finger-curl / IK controls.

## Project transformation

`tools/build_cc0_support_hand.py` is the auditable project-local generator. It performs these bounded transformations:

1. Open the pinned native Blender source.
2. Evaluate exactly four fixed native-rig frames: 1, 14, 20, and 28.
3. Separate disconnected mesh islands and select a substantial left-arm component (>=500 polygons) nearest the left wrist; tiny zero-polygon source islands are explicitly ignored.
4. Build a canonical wrist-centered coordinate basis from source bones, not from camera-space tuning.
5. Crop only arm-side skin beyond the wrist overlap so Peel Calm's sleeve/cuff presentation owns clothing continuity.
6. Rename left deform bones and vertex groups to the semantic names expected by `HandVisual`.
7. Preserve source skin as `HandSkin` and assign `HandNail` only to real fingertip polygons geometrically adjacent to distal bone tails.
8. Freeze the four evaluated source poses into semantic actions: `Default pose`, `Pinch Up`, `Cup`, `Pinch Tight`.
9. Apply a structural 1/2.25 pre-scale to cancel Peel Calm's legacy authored-root multiplier.
10. Export a self-contained GLB.

No CCD, endpoint solve, per-finger angle grid, wrist/orbit/yaw/translation sweep, or other numeric pose search is part of this generator.

## Candidate build receipt

The successful v94 binary build was produced by GitHub Actions run `32019802480` and committed as `5d586b52cfe94df04cc8e15df21a860f9717a997`.

The build log records:

- selected substantial source component: 2,049 vertices / 2,038 polygons;
- output after wrist-side crop: 1,621 vertices / 1,609 polygons;
- 50 bones;
- 20 real fingertip polygons on `HandNail`;
- maximum distal-bone-tail to assigned real fingertip-surface distance: about `0.028423` source units;
- semantic actions: `Default pose`, `Pinch Up`, `Cup`, `Pinch Tight`;
- output GLB size: 275,340 bytes.

This source receipt proves provenance and build structure only. Visual acceptance remains dependent on fresh Godot runtime captures against the locked Café reference.
