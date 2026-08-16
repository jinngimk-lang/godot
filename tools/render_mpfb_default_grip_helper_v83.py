#!/usr/bin/env python3
"""v83: test MPFB's official semantic GRIP_AND_MASTER finger helpers as one support-grasp candidate.

This is intentionally a new abstraction after checkpoint 39: it does not tune the 12
phalanx bones directly, chase endpoints, retarget ContactPose, or sweep candidates. MPFB's
Default-rig finger helper creates one master grip control plus per-digit grip controls whose
X rotation is distributed across the actual finger chains. We author exactly one staged grip,
bake the evaluated right hand/forearm to static geometry, and render Macro/Meso evidence.

The output is staging-only. A technical PASS never promotes the visual verdict.
"""
from __future__ import annotations

import importlib
import json
import math
import sys
import traceback
from pathlib import Path

import bpy
import bmesh
from mathutils import Vector

SUCCESS = "MPFB_DEFAULT_GRIP_HELPER_V83_SUCCESS"


def _args():
    if "--" not in sys.argv:
        raise RuntimeError("expected -- <extension-module> <outdir> <report.json>")
    values = sys.argv[sys.argv.index("--") + 1:]
    if len(values) != 3:
        raise RuntimeError("expected three arguments")
    return values[0], Path(values[1]).resolve(), Path(values[2]).resolve()


def _reset():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)


def _wp(arm, name: str, tail=False) -> Vector:
    pb = arm.pose.bones.get(name)
    if pb is None:
        raise RuntimeError("missing canonical bone " + name)
    return arm.matrix_world @ (pb.tail if tail else pb.head)


def _distance_to_segment(p: Vector, a: Vector, b: Vector) -> float:
    ab = b - a
    if ab.length_squared < 1e-12:
        return (p - a).length
    t = max(0.0, min(1.0, (p - a).dot(ab) / ab.length_squared))
    return (p - (a + ab * t)).length


def _segments(arm):
    names = ["lowerarm02.R", "wrist.R"]
    for digit in range(1, 6):
        for joint in range(1, 4):
            names.append(f"finger{digit}-{joint}.R")
    return [(n, _wp(arm, n), _wp(arm, n, True)) for n in names]


def _bake(basemesh):
    depsgraph = bpy.context.evaluated_depsgraph_get()
    evaluated = basemesh.evaluated_get(depsgraph)
    mesh = bpy.data.meshes.new_from_object(evaluated, preserve_all_data_layers=True, depsgraph=depsgraph)
    obj = bpy.data.objects.new("DefaultGripHelperV83Limb", mesh)
    bpy.context.scene.collection.objects.link(obj)
    obj.matrix_world = basemesh.matrix_world.copy()
    return obj


def _crop(baked, segments, palm_world):
    inv = baked.matrix_world.inverted()
    local_segments = [(name, inv @ a, inv @ b) for name, a, b in segments]
    palm = inv @ palm_world
    bm = bmesh.new(); bm.from_mesh(baked.data); bm.verts.ensure_lookup_table()
    remove = []
    for v in bm.verts:
        keep = (v.co - palm).length <= 0.046
        if not keep:
            for name, a, b in local_segments:
                radius = 0.035 if name in {"lowerarm02.R", "wrist.R"} else 0.0165
                if _distance_to_segment(v.co, a, b) <= radius:
                    keep = True; break
        if not keep:
            remove.append(v)
    bmesh.ops.delete(bm, geom=remove, context="VERTS")
    bm.to_mesh(baked.data); bm.free(); baked.data.update()
    if len(baked.data.vertices) < 500:
        raise RuntimeError(f"cropped v83 limb unexpectedly sparse: {len(baked.data.vertices)}")


def _material(obj, name, color, roughness):
    mat = bpy.data.materials.new(name); mat.use_nodes = True
    p = next((n for n in mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED"), None)
    if p:
        p.inputs["Base Color"].default_value = (*color, 1.0)
        p.inputs["Roughness"].default_value = roughness
    obj.data.materials.clear(); obj.data.materials.append(mat)


def _vessel(center: Vector):
    bpy.ops.mesh.primitive_cylinder_add(vertices=64, radius=0.038, depth=0.20, location=center)
    obj = bpy.context.object; obj.name = "DefaultGripHelperV83Vessel"
    _material(obj, "DefaultGripHelperV83VesselMat", (0.22, 0.32, 0.38), 0.35)
    return obj


def _look(cam, target):
    cam.rotation_euler = (target - cam.location).to_track_quat("-Z", "Y").to_euler()


def _camera(focus, oblique=False):
    scene = bpy.context.scene
    data = bpy.data.cameras.new("V83ObliqueCamera" if oblique else "V83Camera")
    cam = bpy.data.objects.new(data.name, data); scene.collection.objects.link(cam)
    data.lens = 68
    offset = Vector((0.23, -0.28, 0.11)) if oblique else Vector((-0.18, -0.28, 0.10))
    cam.location = focus + offset; _look(cam, focus)
    return cam


def _lighting(focus):
    scene = bpy.context.scene; scene.world.color = (0.025, 0.028, 0.035)
    kd = bpy.data.lights.new("V83Key", "AREA"); kd.energy = 300; kd.size = 0.8
    key = bpy.data.objects.new("V83Key", kd); key.location = focus + Vector((-0.35,-0.35,0.40)); scene.collection.objects.link(key)
    fd = bpy.data.lights.new("V83Fill", "AREA"); fd.energy = 100; fd.size = 0.7
    fill = bpy.data.objects.new("V83Fill", fd); fill.location = focus + Vector((0.20,0.10,0.25)); scene.collection.objects.link(fill)


def _render(path: Path, camera, width, height):
    scene = bpy.context.scene; scene.camera = camera; scene.render.engine = "BLENDER_EEVEE_NEXT"
    scene.render.image_settings.file_format = "PNG"; scene.render.resolution_x = width; scene.render.resolution_y = height
    scene.render.resolution_percentage = 100; scene.render.filepath = str(path)
    bpy.ops.render.render(write_still=True)
    if not path.is_file() or path.stat().st_size == 0:
        raise RuntimeError("render failed: " + str(path))


def run():
    ext, out, report_path = _args(); out.mkdir(parents=True, exist_ok=True); report_path.parent.mkdir(parents=True, exist_ok=True)
    _reset()
    mpfb = importlib.import_module(ext)
    services = importlib.import_module(ext + ".services")
    finger_mod = importlib.import_module(ext + ".entities.rigging.righelpers.fingerhelpers.fingerhelpers")
    HumanService = getattr(services, "HumanService"); FingerHelpers = getattr(finger_mod, "FingerHelpers")

    basemesh = HumanService.create_human(mask_helpers=True, detailed_helpers=False, extra_vertex_groups=True, feet_on_ground=False, scale=0.1, macro_detail_dict=None)
    arm = HumanService.add_builtin_rig(basemesh, "default", import_weights=True, operator=None)
    if arm is None:
        raise RuntimeError("failed to create MPFB default rig")

    helper = FingerHelpers.get_instance("right", {"finger_helpers_type": "GRIP_AND_MASTER", "hide_fk": False}, "Default")
    helper.apply_ik(arm)
    bpy.context.view_layer.update()

    # One authored semantic candidate, not a sweep. Finger numbering on the canonical rig is
    # 1 thumb, 2 index, 3 middle, 4 ring, 5 pinky. Master establishes common enclosure;
    # small per-digit additive differences reproduce the real-hand progression observed in
    # the ContactPose water-bottle evidence without copying its transforms.
    rotations_deg = {
        "right_master_grip": 34.0,
        "right_finger1_grip": 10.0,
        "right_finger2_grip": -12.0,
        "right_finger3_grip": 2.0,
        "right_finger4_grip": 10.0,
        "right_finger5_grip": 18.0,
    }
    for name, degrees in rotations_deg.items():
        pb = arm.pose.bones.get(name)
        if pb is None:
            raise RuntimeError("MPFB grip helper did not create " + name)
        pb.rotation_mode = "XYZ"; pb.rotation_euler.x = math.radians(degrees)
    bpy.context.view_layer.update()

    roots = [_wp(arm, f"finger{i}-1.R") for i in range(2, 6)]
    wrist = _wp(arm, "wrist.R")
    palm = (wrist + sum(roots, Vector())) / 5.0
    tips = [_wp(arm, f"finger{i}-3.R", True) for i in range(2, 6)]
    mean_tips = sum(tips, Vector()) / 4.0
    segs = _segments(arm)

    baked = _bake(basemesh); _crop(baked, segs, palm); _material(baked, "V83Skin", (0.47, 0.29, 0.21), 0.58)
    vessel_center = palm.lerp(mean_tips, 0.47); vessel = _vessel(vessel_center)
    focus = palm.lerp(vessel_center, 0.55); _lighting(focus)

    # The semantic-helper rig is staging only. Evidence renders are baked geometry.
    bpy.data.objects.remove(basemesh, do_unlink=True); bpy.data.objects.remove(arm, do_unlink=True)

    cam = _camera(focus, False); oblique = _camera(focus, True)
    full = out / "support-grip-helper-v83-full.png"; thumb = out / "support-grip-helper-v83-thumbnail.png"; anatomy = out / "support-grip-helper-v83-oblique.png"
    _render(full, cam, 640, 640); _render(thumb, cam, 192, 108)
    vessel.hide_render = True; _render(anatomy, oblique, 640, 640); vessel.hide_render = False

    report = {
        "staging_only": True,
        "production_candidate": False,
        "visual_verdict": "PENDING_HUMAN_MACRO_MESO_REVIEW",
        "mpfb_version": list(mpfb.VERSION),
        "rig": "MPFB canonical default (sacrificial)",
        "helper_mode": "GRIP_AND_MASTER",
        "semantic_grip_controls": rotations_deg,
        "candidate_count": 1,
        "parameter_sweep_used": False,
        "ccd_used": False,
        "endpoint_optimizer_used": False,
        "contact_servo_used": False,
        "contactpose_retarget_used": False,
        "direct_phalanx_pose_table_used": False,
        "production_gameengine_rig_touched": False,
        "baked_vertices": len(baked.data.vertices),
        "baked_polygons": len(baked.data.polygons),
        "visual_gate": "192x108 must immediately read as a natural human vessel wrap with opposing thumb; oblique must show separated progressive digit arcs without clawing/self-intersection.",
    }
    report_path.write_text(json.dumps(report, indent=2, sort_keys=True), encoding="utf-8")
    print(json.dumps(report, indent=2, sort_keys=True)); print(SUCCESS)


if __name__ == "__main__":
    try:
        run()
    except BaseException as exc:
        print("MPFB_DEFAULT_GRIP_HELPER_V83_ERROR:", exc); traceback.print_exc(); raise
