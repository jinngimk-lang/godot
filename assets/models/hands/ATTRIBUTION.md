# Hand model provenance

## Godot XR Tools hand models

- Upstream project: `GodotVR/godot-xr-tools`
- Upstream pinned commit: `2d8db860d1adbee97c0968c4b07afe9348263926`
- Source files: `addons/godot-xr-tools/hands/blend/animations/animations_hand_l.blend` and `animations_hand_r.blend`
- Original hand-model author credited upstream: DigitalN8m4r3 / Miodrag Sejic
- Upstream creation note: MakeHuman Community Edition base, modified in Blender 3D, textured in Substance Painter
- License: CC0 1.0 Universal; a verbatim upstream license copy is stored as `GODOT_XR_TOOLS_HANDS_CC0.md`
- Local files: `hand_left.glb`, `hand_right.glb`
- Local modification: format conversion from the pinned animated `.blend` sources to self-contained glTF 2.0 binary (`.glb`); cameras/lights removed; mesh, armature/skin, materials and source animations retained where exportable
- Runtime dependency: none on Blender or Godot XR Tools; these GLBs are repository-local presentation assets
- Runtime integration: `scripts/hands/hand_visual.gd` is Peel Calm's project-owned wrapper. It owns hand damping, five-finger validation, pinch anchors and selection of authored poses such as `Cup` and `Pinch Tight`.

The game does not vendor the Godot XR Tools addon. Its hand assets are consumed behind Peel Calm's own hand presentation contract, so upstream XR gameplay/input code is not part of the runtime dependency graph.
