"""Render deterministic close-up diagnostics for an MPFB GameEngine-rig source GLB.

This does not claim reference convergence. It gives the model spike a visual gate
before production integration: neutral hand/forearm anatomy must be inspectable at
hero-camera scale, and later pose iterations can reuse the exact camera setup.
"""

from __future__ import annotations

import math
import sys
from pathlib import Path

import bpy
from mathutils import Vector


def _args() -> tuple[Path, Path]:
    if "--" not in sys.argv:
        raise RuntimeError("expected -- <input.glb> <output-dir>")
    values = sys.argv[sys.argv.index("--") + 1 :]
    if len(values) != 2:
        raise RuntimeError("expected exactly two arguments after --")
    return Path(values[0]).resolve(), Path(values[1]).resolve()


def _look_at(camera: bpy.types.Object, target: Vector) -> None:
    direction = target - camera.location
    camera.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()


def _world_bone_point(armature: bpy.types.Object, bone_name: str, tail: bool = False) -> Vector:
    pose_bone = armature.pose.bones.get(bone_name)
    if pose_bone is None:
        raise RuntimeError(f"missing required GameEngine bone: {bone_name}")
    point = pose_bone.tail if tail else pose_bone.head
    return armature.matrix_world @ point


def _setup_scene() -> tuple[bpy.types.Object, bpy.types.Object]:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    bpy.ops.import_scene.gltf(filepath=str(INPUT_GLB))

    meshes = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
    armatures = [obj for obj in bpy.context.scene.objects if obj.type == "ARMATURE"]
    if not meshes or not armatures:
        raise RuntimeError("preview source must contain mesh and armature")

    # Hide tiny helper meshes (for example an imported rig marker) so the anatomy
    # diagnostic is not polluted by non-skin geometry.
    skin = max(meshes, key=lambda obj: len(obj.data.vertices))
    for obj in meshes:
        obj.hide_render = obj is not skin

    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE_NEXT"
    scene.render.resolution_x = 720
    scene.render.resolution_y = 720
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.film_transparent = False
    scene.world.color = (0.035, 0.04, 0.05)

    camera_data = bpy.data.cameras.new("MPFBPreviewCamera")
    camera = bpy.data.objects.new("MPFBPreviewCamera", camera_data)
    scene.collection.objects.link(camera)
    scene.camera = camera
    camera_data.lens = 58.0

    key_data = bpy.data.lights.new("Key", "AREA")
    key_data.energy = 650.0
    key_data.shape = "DISK"
    key_data.size = 1.1
    key = bpy.data.objects.new("Key", key_data)
    key.location = (-0.55, -0.55, 0.65)
    scene.collection.objects.link(key)

    fill_data = bpy.data.lights.new("Fill", "AREA")
    fill_data.energy = 250.0
    fill_data.size = 0.8
    fill = bpy.data.objects.new("Fill", fill_data)
    fill.location = (-0.2, 0.2, 0.35)
    scene.collection.objects.link(fill)

    return armatures[0], camera


def _render_view(armature: bpy.types.Object, camera: bpy.types.Object, name: str, location: Vector, target: Vector) -> None:
    camera.location = location
    _look_at(camera, target)
    bpy.context.scene.render.filepath = str(OUTPUT_DIR / f"{name}.png")
    bpy.ops.render.render(write_still=True)
    output = OUTPUT_DIR / f"{name}.png"
    if not output.is_file() or output.stat().st_size <= 0:
        raise RuntimeError(f"failed to render {name}")
    print(f"MPFB_PREVIEW {name} {output.stat().st_size} bytes")


INPUT_GLB, OUTPUT_DIR = _args()
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
armature, camera = _setup_scene()

wrist = _world_bone_point(armature, "hand_r")
hand_tip = _world_bone_point(armature, "middle_03_r", tail=True)
elbow = _world_bone_point(armature, "lowerarm_r")
hand_center = wrist.lerp(hand_tip, 0.55)
forearm_center = elbow.lerp(wrist, 0.58)

# Front/palm-oriented diagnostic. The MPFB default character faces toward -Y,
# so a camera farther along -Y reads the hand/forearm without the torso filling
# the frame.
_render_view(
    armature,
    camera,
    "right_hand_front",
    hand_center + Vector((0.02, -0.38, 0.07)),
    hand_center,
)

# Oblique view exposes wrist continuity and finger volume/faceting.
_render_view(
    armature,
    camera,
    "right_hand_oblique",
    hand_center + Vector((-0.28, -0.25, 0.16)),
    hand_center,
)

# Wider forearm view is the Macro/Meso anatomy gate before any scene pose work.
_render_view(
    armature,
    camera,
    "right_forearm_oblique",
    forearm_center + Vector((-0.34, -0.48, 0.20)),
    forearm_center,
)

print("MPFB_PREVIEW_SUCCESS")
