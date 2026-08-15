#!/usr/bin/env python3
"""Render a sacrificial BVH-source armature as an anatomical proxy.

The source BVH is imported into a throwaway Blender scene. Cylinders/spheres are
built along the posed right arm/hand bone chain. No MPFB GameEngine rig is
loaded, modified, or retargeted. Output is only a visual anatomy reference.
"""
from __future__ import annotations

import json
import math
import sys
from pathlib import Path

import bpy
from mathutils import Vector


def clear_scene() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)


def material(name: str, rgba: tuple[float, float, float, float]):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = rgba
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs["Base Color"].default_value = rgba
        bsdf.inputs["Roughness"].default_value = 0.7
    return mat


def bone_segment(a: Vector, b: Vector, radius: float, mat) -> None:
    direction = b - a
    length = direction.length
    if length <= 1e-6:
        return
    mid = (a + b) * 0.5
    bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=radius, depth=length, location=mid)
    obj = bpy.context.object
    obj.data.materials.append(mat)
    obj.rotation_mode = "QUATERNION"
    obj.rotation_quaternion = Vector((0.0, 0.0, 1.0)).rotation_difference(direction.normalized())


def joint_marker(p: Vector, radius: float, mat) -> None:
    bpy.ops.mesh.primitive_uv_sphere_add(segments=16, ring_count=8, radius=radius, location=p)
    bpy.context.object.data.materials.append(mat)


def is_right_arm_hand(name: str) -> bool:
    n = name.lower()
    side = any(k in n for k in ("right", "r_", "_r", ".r", "rhand", "rwrist"))
    anatomy = any(k in n for k in ("clav", "shoulder", "upperarm", "arm", "elbow", "forearm", "wrist", "hand", "thumb", "index", "middle", "ring", "pinky", "finger"))
    return side and anatomy


def fit_camera(points: list[Vector]) -> tuple[Vector, float]:
    if not points:
        return Vector((0, 0, 0)), 1.0
    center = sum(points, Vector()) / len(points)
    radius = max((p - center).length for p in points)
    return center, max(radius, 0.35)


def render(path: Path, size: int) -> None:
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE_NEXT"
    scene.render.resolution_x = size
    scene.render.resolution_y = size
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.filepath = str(path)
    scene.render.film_transparent = False
    scene.world.color = (0.035, 0.035, 0.035)
    bpy.ops.render.render(write_still=True)


def main() -> int:
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    if len(argv) != 4:
        raise SystemExit("usage: blender --background --python render_makehuman_pose_reference_v50.py -- SOURCE.bvh FULL.png THUMB.png REPORT.json")
    bvh_path, full_path, thumb_path, report_path = map(Path, argv)
    full_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.parent.mkdir(parents=True, exist_ok=True)

    clear_scene()
    bpy.ops.import_anim.bvh(filepath=str(bvh_path), frame_start=1, update_scene_fps=True)
    armatures = [o for o in bpy.context.scene.objects if o.type == "ARMATURE"]
    if len(armatures) != 1:
        raise RuntimeError(f"expected one sacrificial BVH armature, got {len(armatures)}")
    arm = armatures[0]
    bpy.context.scene.frame_set(1)

    limb_mat = material("SacrificialLimb", (0.72, 0.50, 0.35, 1.0))
    joint_mat = material("SacrificialJoint", (0.90, 0.72, 0.55, 1.0))
    vessel_mat = material("ReferenceVessel", (0.18, 0.30, 0.42, 1.0))

    selected = []
    points: list[Vector] = []
    for pb in arm.pose.bones:
        if not is_right_arm_hand(pb.name):
            continue
        head = arm.matrix_world @ pb.head
        tail = arm.matrix_world @ pb.tail
        length = (tail - head).length
        radius = max(min(length * 0.10, 0.028), 0.007)
        bone_segment(head, tail, radius, limb_mat)
        joint_marker(head, radius * 1.15, joint_mat)
        selected.append(pb.name)
        points.extend([head, tail])

    if len(selected) < 5:
        # Naming varies across MakeHuman source rigs; fall back to all descendants
        # of a right-hand-like bone so CI still yields useful evidence.
        candidates = [pb for pb in arm.pose.bones if any(k in pb.name.lower() for k in ("hand", "wrist"))]
        if not candidates:
            raise RuntimeError("could not identify a hand/wrist chain in source BVH")

    center, radius = fit_camera(points)

    # A neutral vertical proxy provides context for judging whether the source
    # thumb/finger relationship actually resembles an object-holding grasp.
    bpy.ops.mesh.primitive_cylinder_add(vertices=32, radius=max(radius * 0.14, 0.035), depth=max(radius * 0.8, 0.22), location=center + Vector((radius * 0.12, 0, 0)))
    bpy.context.object.data.materials.append(vessel_mat)

    bpy.ops.object.camera_add(location=center + Vector((radius * 2.4, -radius * 3.0, radius * 1.3)))
    cam = bpy.context.object
    direction = center - cam.location
    cam.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
    cam.data.lens = 58
    bpy.context.scene.camera = cam

    bpy.ops.object.light_add(type="AREA", location=center + Vector((radius * 1.2, -radius * 1.0, radius * 2.0)))
    key = bpy.context.object
    key.data.energy = 700
    key.data.shape = "DISK"
    key.data.size = radius * 2.0
    bpy.ops.object.light_add(type="AREA", location=center + Vector((-radius * 1.2, radius * 0.5, radius * 0.8)))
    fill = bpy.context.object
    fill.data.energy = 280
    fill.data.size = radius * 1.5

    render(full_path, 768)
    render(thumb_path, 128)
    report = {
        "staging_only": True,
        "production_candidate": False,
        "automatic_retarget_allowed": False,
        "source_armature": arm.name,
        "selected_bones": selected,
        "selected_bone_count": len(selected),
        "camera_center": list(center),
        "camera_radius": radius,
        "visual_gate": "Anatomical reference only. A useful result must show believable thumb/finger opposition; it never advances directly to production.",
    }
    report_path.write_text(json.dumps(report, indent=2, sort_keys=True), encoding="utf-8")
    print("MAKEHUMAN_POSE_REFERENCE_V50_RENDER_SUCCESS")
    print(json.dumps({"bones": len(selected), "full": str(full_path), "thumb": str(thumb_path)}, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
