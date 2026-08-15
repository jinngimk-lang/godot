#!/usr/bin/env python3
"""v58: relax the visually coherent native holding pose once, on its own Default rig.

v57 proved the category change: when the official MakeHuman holding-object BVH stays on the
compatible MPFB Default rig, the hand is a coherent closed grasp rather than the twisted
cross-rig shapes from v54-v56. Its failure is now simpler: the hand is too tightly closed for the
wider cup/bottle support grip in Peel Calm.

This experiment does not retarget or solve anything. It scales the already-authored native Euler
pose toward the rig rest pose with one fixed per-digit relaxation profile, then bakes the result as
rest pose and renders it around a non-occluding wireframe vessel. There is one candidate only.
"""
from __future__ import annotations

import importlib.util
import json
import statistics
import sys
import traceback
from pathlib import Path

import bpy
from mathutils import Vector

BASE = Path(__file__).resolve().parent
SPEC = importlib.util.spec_from_file_location("native_v57", BASE / "build_mpfb_native_pose_bake_v57.py")
if SPEC is None or SPEC.loader is None:
    raise RuntimeError("could not load v57 helpers")
v57 = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(v57)

SUCCESS = "MPFB_NATIVE_GRASP_OPEN_V58_SUCCESS"

# finger1 is thumb on the MPFB Default rig; 2..5 are index..pinky.
# Values are deliberately fixed, not swept. 1.0 = original tight holding-glass pose; 0 = rest.
RELAX = {
    1: 0.86,
    2: 0.62,
    3: 0.66,
    4: 0.70,
    5: 0.74,
}


def _args():
    if "--" not in sys.argv:
        raise RuntimeError("expected -- <extension-module> <pose.bvh> <previews> <output.glb> <report.json>")
    vals = sys.argv[sys.argv.index("--") + 1:]
    if len(vals) != 5:
        raise RuntimeError("expected five arguments")
    return vals[0], Path(vals[1]).resolve(), Path(vals[2]).resolve(), Path(vals[3]).resolve(), Path(vals[4]).resolve()


def _digit_number(name: str):
    low = name.lower()
    if not low.startswith("finger") or not low.endswith(".r"):
        return None
    prefix = low.split("-", 1)[0]
    try:
        return int(prefix.replace("finger", ""))
    except ValueError:
        return None


def _relax_native_pose(arm):
    rows = {}
    for pb in arm.pose.bones:
        digit = _digit_number(pb.name)
        if digit not in RELAX:
            continue
        factor = RELAX[digit]
        before = tuple(float(v) for v in pb.rotation_euler)
        pb.rotation_euler = tuple(v * factor for v in pb.rotation_euler)
        rows[pb.name] = {
            "factor": factor,
            "before_euler": before,
            "after_euler": tuple(float(v) for v in pb.rotation_euler),
        }
    bpy.context.view_layer.update()
    if len(rows) < 15:
        raise RuntimeError(f"expected 15 right finger bones, adjusted {len(rows)}")
    return rows


def _hand_geometry(arm):
    names = v57._right_hand_bones(arm)
    points = v57._world_points(arm, names)
    if len(points) < 8:
        raise RuntimeError("could not identify right hand geometry")
    center = sum(points, Vector()) / len(points)
    extent = max((p - center).length for p in points)
    extent = max(extent, 0.06)
    tips = v57._distal_tips(arm, names)
    if len(tips) < 4:
        raise RuntimeError(f"not enough distal tips: {len(tips)}")
    grasp_center = sum(tips, Vector()) / len(tips)
    horizontal = [Vector((p.x - grasp_center.x, p.y - grasp_center.y, 0.0)).length for p in tips]
    radius = max(extent * 0.16, statistics.median(horizontal) * 0.9)
    return names, center, extent, tips, grasp_center, radius


def _wire_vessel(grasp_center, radius, extent):
    bpy.ops.mesh.primitive_cylinder_add(vertices=48, radius=radius, depth=extent * 2.5, location=grasp_center)
    vessel = bpy.context.object
    vessel.name = "NativeGraspV58WireVessel"
    wire = vessel.modifiers.new("DiagnosticWire", "WIREFRAME")
    wire.thickness = max(radius * 0.035, 0.0008)
    wire.use_replace = True
    mat = bpy.data.materials.new("NativeGraspV58Wire")
    mat.use_nodes = True
    mat.diffuse_color = (0.18, 0.54, 0.95, 1.0)
    p = next((n for n in mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED"), None)
    if p and p.inputs.get("Base Color"):
        p.inputs["Base Color"].default_value = (0.18, 0.54, 0.95, 1.0)
    if p and p.inputs.get("Roughness"):
        p.inputs["Roughness"].default_value = 0.35
    vessel.data.materials.append(mat)
    return vessel


def _setup_render(basemesh, center, grasp_center, extent):
    s = bpy.context.scene
    s.render.engine = "BLENDER_EEVEE_NEXT"
    s.render.image_settings.file_format = "PNG"
    s.world.color = (0.035, 0.035, 0.045)
    basemesh.data.materials.clear()
    basemesh.data.materials.append(v57._skin_material())

    camd = bpy.data.cameras.new("NativeGraspV58Camera")
    cam = bpy.data.objects.new("NativeGraspV58Camera", camd)
    bpy.context.collection.objects.link(cam)
    cam.location = center + Vector((extent * 2.7, -extent * 4.2, extent * 1.7))
    camd.lens = 72.0
    v57._look_at(cam, center.lerp(grasp_center, 0.30))
    s.camera = cam

    kd = bpy.data.lights.new("NativeGraspV58Key", "AREA")
    kd.energy = 650
    kd.size = extent * 4.0
    key = bpy.data.objects.new("NativeGraspV58Key", kd)
    bpy.context.collection.objects.link(key)
    key.location = center + Vector((extent * 2.4, -extent * 2.0, extent * 2.8))
    v57._look_at(key, center)

    fd = bpy.data.lights.new("NativeGraspV58Fill", "AREA")
    fd.energy = 250
    fd.size = extent * 3.0
    fill = bpy.data.objects.new("NativeGraspV58Fill", fd)
    bpy.context.collection.objects.link(fill)
    fill.location = center + Vector((-extent * 2.0, -extent, extent))
    v57._look_at(fill, center)


def _render(path, w, h):
    s = bpy.context.scene
    s.render.resolution_x = w
    s.render.resolution_y = h
    s.render.resolution_percentage = 100
    s.render.filepath = str(path)
    bpy.ops.render.render(write_still=True)
    if not path.is_file() or path.stat().st_size == 0:
        raise RuntimeError("render failed: " + str(path))


def run():
    extension_module, bvh, previews, output_glb, report = _args()
    previews.mkdir(parents=True, exist_ok=True)
    output_glb.parent.mkdir(parents=True, exist_ok=True)
    report.parent.mkdir(parents=True, exist_ok=True)
    v57._reset()
    mpfb, HumanService, AnimationService, RigService = v57._load_mpfb(extension_module)

    basemesh = HumanService.create_human(
        mask_helpers=True, detailed_helpers=False, extra_vertex_groups=True,
        feet_on_ground=False, scale=0.1, macro_detail_dict=None,
    )
    arm = HumanService.add_builtin_rig(basemesh, "default", import_weights=True, operator=None)
    if arm is None:
        raise RuntimeError("could not build Default rig")
    AnimationService.import_bvh_file_as_pose(arm, str(bvh))
    bpy.context.view_layer.update()

    edited = _relax_native_pose(arm)
    names, center, extent, tips, grasp_center, radius = _hand_geometry(arm)
    _wire_vessel(grasp_center, radius, extent)
    _setup_render(basemesh, center, grasp_center, extent)

    _render(previews / "native_grasp_open_v58_before_bake.png", 640, 640)
    _render(previews / "native_grasp_open_v58_before_bake_thumbnail.png", 192, 108)

    RigService.apply_pose_as_rest_pose(arm)
    bpy.context.view_layer.update()
    _render(previews / "native_grasp_open_v58_after_bake.png", 640, 640)
    _render(previews / "native_grasp_open_v58_after_bake_thumbnail.png", 192, 108)
    v57._export(output_glb, basemesh, arm)

    payload = {
        "staging_only": True,
        "production_candidate": False,
        "route": "native-default-rig-single-authored-relaxation",
        "source_pose": bvh.name,
        "source_license": "CC0 (MakeHuman Poses 01 pack)",
        "gameengine_rig_modified": False,
        "candidate_count": 1,
        "relaxation_factors": RELAX,
        "edited_bones": edited,
        "hand_bones": names,
        "diagnostic_vessel_radius": radius,
        "diagnostic_grasp_center": list(grasp_center),
        "output_glb": str(output_glb),
        "output_bytes": output_glb.stat().st_size,
        "visual_gate": "192x108 must read as a relaxed human hand enclosing the wireframe vessel, with non-parallel finger curl and visible thumb opposition. If it still reads fist/touch/claw, reject without a factor sweep.",
        "generator": {"mpfb_version": list(mpfb.VERSION), "blender": bpy.app.version_string},
    }
    report.write_text(json.dumps(payload, indent=2, sort_keys=True), encoding="utf-8")
    print(json.dumps(payload, indent=2, sort_keys=True))
    print(SUCCESS)


if __name__ == "__main__":
    try:
        run()
    except BaseException as exc:
        print("MPFB_NATIVE_GRASP_OPEN_V58_ERROR:", exc)
        traceback.print_exc()
        raise
