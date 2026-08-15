#!/usr/bin/env python3
"""Render a sacrificial BVH-source hand/forearm as an anatomical proxy.

The source BVH is imported into a throwaway Blender scene. Cylinders/spheres are
built only for the posed right distal forearm, wrist and fingers. No MPFB
GameEngine rig is loaded, modified, or retargeted. Output is only a close-up
visual anatomy reference; the thumb is colored separately so opposition is easy
to judge at Macro/Meso scale.
"""
from __future__ import annotations

import json
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
        bsdf.inputs["Roughness"].default_value = 0.72
    return mat


def bone_segment(a: Vector, b: Vector, radius: float, mat) -> None:
    direction = b - a
    length = direction.length
    if length <= 1e-6:
        return
    mid = (a + b) * 0.5
    bpy.ops.mesh.primitive_cylinder_add(vertices=18, radius=radius, depth=length, location=mid)
    obj = bpy.context.object
    obj.data.materials.append(mat)
    obj.rotation_mode = "QUATERNION"
    obj.rotation_quaternion = Vector((0.0, 0.0, 1.0)).rotation_difference(direction.normalized())


def joint_marker(p: Vector, radius: float, mat) -> None:
    bpy.ops.mesh.primitive_uv_sphere_add(segments=18, ring_count=10, radius=radius, location=p)
    bpy.context.object.data.materials.append(mat)


def classify_bone(name: str) -> str | None:
    """Return forearm/wrist/thumb/finger for the known MakeHuman BVH naming."""
    n = name.lower()
    if not n.endswith(".r"):
        return None
    if n == "lowerarm02.r":
        return "forearm"
    if n == "wrist.r":
        return "wrist"
    if n.startswith("finger1-"):
        return "thumb"
    if any(n.startswith(f"finger{i}-") for i in range(2, 6)):
        return "finger"
    return None


def fit_camera(points: list[Vector]) -> tuple[Vector, float]:
    if not points:
        raise RuntimeError("no right hand/distal-forearm points selected")
    mins = Vector((min(p.x for p in points), min(p.y for p in points), min(p.z for p in points)))
    maxs = Vector((max(p.x for p in points), max(p.y for p in points), max(p.z for p in points)))
    center = (mins + maxs) * 0.5
    radius = max((p - center).length for p in points)
    return center, max(radius, 0.08)


def render(path: Path, size: int) -> None:
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE_NEXT"
    scene.render.resolution_x = size
    scene.render.resolution_y = size
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.filepath = str(path)
    scene.render.film_transparent = False
    scene.world.color = (0.025, 0.025, 0.025)
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

    limb_mat = material("SacrificialLimb", (0.76, 0.54, 0.39, 1.0))
    thumb_mat = material("SacrificialThumb", (0.96, 0.52, 0.22, 1.0))
    joint_mat = material("SacrificialJoint", (0.93, 0.76, 0.58, 1.0))
    wrist_mat = material("SacrificialWrist", (0.58, 0.70, 0.82, 1.0))

    selected: list[str] = []
    selected_by_class: dict[str, list[str]] = {"forearm": [], "wrist": [], "thumb": [], "finger": []}
    points: list[Vector] = []
    for pb in arm.pose.bones:
        category = classify_bone(pb.name)
        if category is None:
            continue
        head = arm.matrix_world @ pb.head
        tail = arm.matrix_world @ pb.tail
        length = (tail - head).length
        radius = max(min(length * (0.12 if category in {"forearm", "wrist"} else 0.16), 0.022), 0.0045)
        seg_mat = thumb_mat if category == "thumb" else (wrist_mat if category == "wrist" else limb_mat)
        bone_segment(head, tail, radius, seg_mat)
        joint_marker(head, radius * 1.10, joint_mat)
        selected.append(pb.name)
        selected_by_class[category].append(pb.name)
        points.extend([head, tail])

    expected = {"forearm": 1, "wrist": 1, "thumb": 3, "finger": 12}
    for category, minimum in expected.items():
        if len(selected_by_class[category]) < minimum:
            raise RuntimeError(f"insufficient {category} bones: {selected_by_class[category]}")

    center, radius = fit_camera(points)

    # Close-up orthographic view: no invented vessel geometry. This isolates the
    # only question v50 is allowed to answer — whether the source hand anatomy
    # contains useful progressive finger curl and thumb opposition.
    bpy.ops.object.camera_add(location=center + Vector((radius * 2.2, -radius * 3.0, radius * 1.35)))
    cam = bpy.context.object
    direction = center - cam.location
    cam.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
    cam.data.type = "ORTHO"
    cam.data.ortho_scale = radius * 2.35
    bpy.context.scene.camera = cam

    bpy.ops.object.light_add(type="AREA", location=center + Vector((radius * 1.4, -radius * 1.2, radius * 2.2)))
    key = bpy.context.object
    key.data.energy = 650
    key.data.shape = "DISK"
    key.data.size = radius * 2.0
    bpy.ops.object.light_add(type="AREA", location=center + Vector((-radius * 1.4, radius * 0.7, radius * 0.9)))
    fill = bpy.context.object
    fill.data.energy = 240
    fill.data.size = radius * 1.5

    render(full_path, 768)
    render(thumb_path, 128)
    report = {
        "staging_only": True,
        "production_candidate": False,
        "automatic_retarget_allowed": False,
        "source_armature": arm.name,
        "selected_bones": selected,
        "selected_bones_by_class": selected_by_class,
        "selected_bone_count": len(selected),
        "camera_center": list(center),
        "camera_radius": radius,
        "camera_scope": "right lowerarm02 + wrist + finger1..5 only",
        "thumb_material": "SacrificialThumb",
        "visual_gate": "Anatomical reference only. Useful only if the close-up shows progressive finger curl and clear thumb opposition; it never advances directly to production.",
    }
    report_path.write_text(json.dumps(report, indent=2, sort_keys=True), encoding="utf-8")
    print("MAKEHUMAN_POSE_REFERENCE_V50_RENDER_SUCCESS")
    print(json.dumps({"bones": len(selected), "full": str(full_path), "thumb": str(thumb_path)}, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
