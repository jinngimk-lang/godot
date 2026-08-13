# Hand asset provenance

Peel Calm vendors two repository-local rigged hand GLBs derived from the CC0 hand assets in **Godot XR Tools**.

- Upstream repository: GodotVR/godot-xr-tools
- Pinned upstream commit: `2d8db860d1adbee97c0968c4b07afe9348263926`
- License: CC0 1.0 Universal; the upstream hand-model license copy is preserved in `GODOT_XR_TOOLS_HANDS_CC0.md`.

## Source reconstruction

The upstream hand authoring data is deliberately split:

- renderable hand/nail geometry + 26-bone armature: `hands/blend/hand_l.blend`, `hand_r.blend`;
- authored action library on the matching armature: `hands/blend/animations/animations_hand_l.blend`, `animations_hand_r.blend`.

An earlier project export incorrectly used the animation-only blends and therefore produced GLBs with skeletons/actions but **zero renderable meshes**. The current assets reconstruct the intended authored hand by opening the mesh-bearing source, joining the hand and nail geometry into one skinned mesh with two semantic material surfaces, appending the matching action library, and exporting a self-contained GLB.

## Project-local presentation transformation

The geometry topology and authored skeletal actions come from the pinned CC0 source. Peel Calm assigns simple repository-local PBR materials so normal play has no texture download dependency:

- `HandSkin`: warm semi-realistic skin, roughness 0.64;
- `HandNail`: slightly lighter nail material, roughness 0.48.

No Godot XR Tools addon code, Blender runtime, external service, login, secret, or network access is required to play the game.

## Generated asset checksums

- `hand_left.glb`: `afb268fac13da712cbf7b740375c4f05667452b5301b8f7411a41855f86da5fb`
- `hand_right.glb`: `2f0c6d5f769a237feadb4d201073f624d5328a2d18f7a60300eee8427c56e259`

The repository test contract requires both assets to import as `PackedScene`, contain `Skeleton3D`, an `AnimationPlayer` with `Cup` and `Pinch Tight`, non-empty renderable mesh vertices, and the semantic `HandSkin` / `HandNail` material surfaces.
