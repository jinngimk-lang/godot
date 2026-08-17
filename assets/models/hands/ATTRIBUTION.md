# Hand asset provenance

Peel Calm currently vendors two repository-local rigged hand GLBs from different rights-safe sources while the hero-hand realism lane is under structural replacement.

## Left support hand — OpenGameArt / MakeHuman CC0 candidate

`hand_left.glb` on the `spike/cc0-makehuman-support-hand-v94` lane is generated from the CC0 FPS-arms source published on OpenGameArt and authored from MakeHuman-derived geometry/rig data.

- Source page: `https://opengameart.org/content/fps-arms-rigged-only`
- Source archive: `https://opengameart.org/sites/default/files/fps%20arms.7z`
- Pinned source archive SHA-256: `31f6c7bd5caea8856c4aafca8461f38a3c8bfdd3d8f05c898e403b9475e54562`
- Native authoring source inside the archive: `FPS ARMS RIG 1 test anim.blend`
- License: CC0 1.0 / public-domain dedication as published with the source.
- Project generator: `tools/build_cc0_support_hand.py`

The generator deliberately uses one fixed set of evaluated source-rig frames rather than a parameter search:

- `Default pose` -> source frame `1`
- `Pinch Up` -> source frame `14`
- `Cup` -> source frame `20`
- `Pinch Tight` -> source frame `28`

The generator structurally normalizes the source rig to the existing `HandVisual` convention (wrist origin; wrist-to-elbow axis; semantic finger-bone names), isolates the substantial left arm island, crops the bare forearm so the project sleeve/cuff owns clothing continuity, and preserves real source mesh surfaces as `HandSkin` and `HandNail`. `HandNail` is assigned to real fingertip polygons selected from distal-bone geometry; no hidden marker or proxy geometry is created.

The candidate build at commit `5d586b52cfe94df04cc8e15df21a860f9717a997` produced:

- 1,621 vertices / 1,609 polygons after forearm crop;
- 50-bone armature;
- semantic actions `Default pose`, `Pinch Up`, `Cup`, and `Pinch Tight`;
- 20 real fingertip polygons assigned to `HandNail`;
- a 275,340-byte GLB.

This is still an acceptance candidate, not a declared final hand. It may only replace the old support hand if exact-head Godot import/tests and fresh Café runtime captures show a material improvement in palm contact, finger enclosure, thumb opposition, and sleeve/wrist continuity. CCD, endpoint chasing, wrist/orbit/yaw/translation grids, and other disguised numeric pose searches remain prohibited by the project hand-authoring stop condition.

## Right peel hand — Godot XR Tools CC0

`hand_right.glb` remains derived from the CC0 hand assets in **Godot XR Tools**.

- Upstream repository: `GodotVR/godot-xr-tools`
- Pinned upstream commit: `2d8db860d1adbee97c0968c4b07afe9348263926`
- License: CC0 1.0 Universal; the upstream hand-model license copy is preserved in `GODOT_XR_TOOLS_HANDS_CC0.md`.
- Generated asset checksum: `hand_right.glb` SHA-256 `2f0c6d5f769a237feadb4d201073f624d5328a2d18f7a60300eee8427c56e259`.

The old left XR hand source remains documented in repository history and checkpoints, including the rejected subdivision experiment. It must not be reintroduced merely for smoothing: checkpoint 72 already proved that increasing density did not close the support-hand anatomy / vessel-enclosure RED.

## Runtime contract

Repository tests require the active authored hand assets to import as `PackedScene`, contain `Skeleton3D`, an `AnimationPlayer` with required semantic actions, non-empty renderable mesh vertices, and semantic `HandSkin` / `HandNail` material surfaces.

No Blender runtime, external service, login, secret, or network access is required to play the shipped game. Blender/network access is used only in evidence-producing asset-authoring workflows, and the generated GLBs are vendored into the repository.
