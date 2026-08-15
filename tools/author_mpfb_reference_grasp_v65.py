#!/usr/bin/env python3
"""v65: derive a single native-canonical power grasp from the locked Peel Calm support-hand relationship.

This is deliberately not another endpoint/CCD/orbit/crop search.  Checkpoint 27 falsified the
CC0 wine-glass source pose itself.  v65 keeps the deformation-safe MPFB canonical ``default``
rig, authors one deterministic cylindrical support grasp directly on that same rig, then bakes
and crops the posed mesh before rendering.

The only two outputs are a palm-normal sign disambiguation (A/B).  They share one fixed grasp
shape and differ only in which side of the canonical palm plane is treated as the palmar side.
This resolves a coordinate-basis ambiguity; it is not a parameter sweep.  Visual acceptance is
still Macro/Meso-first: vessel enclosure + opposing thumb in the 192x108 view, then unobstructed
finger continuity in the oblique view.
"""
from __future__ import annotations

import importlib
import importlib.util
import json
import math
import sys
import traceback
from pathlib import Path

import bpy
from mathutils import Matrix, Vector

BASE = Path(__file__).resolve().parent
SPEC64 = importlib.util.spec_from_file_location("mpfb_v64_for_v65", BASE / "bake_mpfb_default_pose_v64.py")
if SPEC64 is None or SPEC64.loader is None:
    raise RuntimeError("could not load v64 helpers")
v64 = importlib.util.module_from_spec(SPEC64)
SPEC64.loader.exec_module(v64)

SPEC64B = importlib.util.spec_from_file_location("mpfb_v64b_for_v65", BASE / "bake_mpfb_default_pose_v64b.py")
if SPEC64B is None or SPEC64B.loader is None:
    raise RuntimeError("could not load v64b helpers")
v64b = importlib.util.module_from_spec(SPEC64B)
SPEC64B.loader.exec_module(v64b)

SUCCESS = "MPFB_REFERENCE_GRASP_V65_SUCCESS"


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


def _services(extension_module: str):
    if not extension_module.startswith("bl_ext.") or not extension_module.endswith(".mpfb"):
        raise RuntimeError("MPFB extension namespace required")
    mpfb = importlib.import_module(extension_module)
    services = importlib.import_module(extension_module + ".services")
    return mpfb, getattr(services, "HumanService")


def _wp(arm, name: str, tail=False) -> Vector:
    pb = arm.pose.bones.get(name)
    if pb is None:
        raise RuntimeError("canonical rig missing " + name)
    return arm.matrix_world @ (pb.tail if tail else pb.head)


def _palm_frame(arm):
    wrist = _wp(arm, "wrist.R")
    roots = [_wp(arm, f"finger{i}-1.R") for i in range(2, 6)]
    index_root, pinky_root = roots[0], roots[-1]
    palm_center = (wrist + sum(roots, Vector())) / 5.0
    longitudinal = ((sum(roots, Vector()) / 4.0) - wrist).normalized()
    span = (pinky_root - index_root).normalized()
    normal = span.cross(longitudinal).normalized()
    if normal.length_squared < 0.9:
        raise RuntimeError("degenerate canonical palm frame")
    return palm_center, longitudinal, span, normal


def _rotate_pose_bone_world(arm, bone_name: str, axis_world: Vector, angle_radians: float):
    """Rotate one pose bone around its current head in armature space, preserving translation.

    Assigning ``PoseBone.matrix`` avoids guessing the canonical rig's local Euler conventions.
    The angle/axis is deterministic and there is no iterative target solve.
    """
    pb = arm.pose.bones.get(bone_name)
    if pb is None:
        raise RuntimeError("missing pose bone " + bone_name)
    axis_arm = (arm.matrix_world.inverted().to_3x3() @ axis_world).normalized()
    head = pb.head.copy()
    q = Matrix.Rotation(angle_radians, 4, axis_arm)
    pb.matrix = Matrix.Translation(head) @ q @ Matrix.Translation(-head) @ pb.matrix
    bpy.context.view_layer.update()


def _choose_curl_axis(arm, bone_name: str, palm_normal_world: Vector, vessel_center_world: Vector) -> Vector:
    """Choose the fixed flexion-plane sign that bends this phalanx toward the vessel volume.

    This is a single sign disambiguation for an anatomically defined bend plane, not an endpoint
    optimizer: the magnitude is fixed by the authored pose table below.
    """
    pb = arm.pose.bones[bone_name]
    direction = (_wp(arm, bone_name, True) - _wp(arm, bone_name)).normalized()
    base_axis = direction.cross(palm_normal_world).normalized()
    if base_axis.length_squared < 0.5:
        base_axis = direction.cross(Vector((0.0, 0.0, 1.0))).normalized()
    if base_axis.length_squared < 0.5:
        raise RuntimeError("could not derive flexion plane for " + bone_name)

    # Compare +/- a tiny probe only to pick bend direction; authored angle magnitude is untouched.
    head = _wp(arm, bone_name)
    tail = _wp(arm, bone_name, True)
    rel = tail - head
    probe = math.radians(4.0)
    def rotated(axis):
        q = Matrix.Rotation(probe, 4, axis).to_3x3()
        return head + q @ rel
    plus = (rotated(base_axis) - vessel_center_world).length
    minus = (rotated(-base_axis) - vessel_center_world).length
    return base_axis if plus <= minus else -base_axis


def _author_power_grasp(arm, palmar_sign: float):
    palm_center, longitudinal, span, normal = _palm_frame(arm)
    palmar = normal * palmar_sign

    # Locked-reference relationship: upright bottle/cup axis approximately follows palm long axis;
    # palm sits on the near side; digits curl around the far contour; thumb opposes from above/side.
    vessel_radius = 0.040
    palm_clearance = 0.030
    vessel_center = palm_center + palmar * (vessel_radius + palm_clearance)

    # Whole-hand approach: a modest wrist pronation places the palm face on the vessel rather than
    # leaving the hand edge-on.  This is a single authored value, not swept.
    _rotate_pose_bone_world(arm, "wrist.R", longitudinal, math.radians(-12.0 * palmar_sign))
    bpy.context.view_layer.update()
    palm_center, longitudinal, span, normal = _palm_frame(arm)
    palmar = normal * palmar_sign
    vessel_center = palm_center + palmar * (vessel_radius + palm_clearance)

    # Reference-derived progressive enclosure: index is lighter; middle/ring/pinky close deeper.
    # MCP/PIP/DIP values intentionally differ so the silhouette is not four parallel hooks.
    flex_degrees = {
        2: (42.0, 62.0, 38.0),
        3: (50.0, 70.0, 44.0),
        4: (57.0, 76.0, 49.0),
        5: (63.0, 80.0, 54.0),
    }
    # Small MCP fan makes digit roots progress around the cylindrical contour before flexion.
    fan_degrees = {2: -7.0, 3: -2.0, 4: 4.0, 5: 10.0}

    for digit in range(2, 6):
        mcp = f"finger{digit}-1.R"
        _rotate_pose_bone_world(arm, mcp, palmar, math.radians(fan_degrees[digit]))
        for joint, angle in enumerate(flex_degrees[digit], start=1):
            name = f"finger{digit}-{joint}.R"
            axis = _choose_curl_axis(arm, name, palmar, vessel_center)
            _rotate_pose_bone_world(arm, name, axis, math.radians(angle))

    # Thumb opposition is independent from finger flexion.  First swing the metacarpal across the
    # palm toward the vessel, then curl proximal/distal segments.  Values are fixed and asymmetric.
    thumb_root = "finger1-1.R"
    thumb_dir = (_wp(arm, thumb_root, True) - _wp(arm, thumb_root)).normalized()
    opposition_axis = thumb_dir.cross((vessel_center - _wp(arm, thumb_root)).normalized()).normalized()
    if opposition_axis.length_squared < 0.5:
        opposition_axis = longitudinal
    _rotate_pose_bone_world(arm, thumb_root, opposition_axis, math.radians(38.0))
    for name, angle in (("finger1-2.R", 34.0), ("finger1-3.R", 28.0)):
        axis = _choose_curl_axis(arm, name, palmar, vessel_center)
        _rotate_pose_bone_world(arm, name, axis, math.radians(angle))

    bpy.context.view_layer.update()
    return vessel_center, vessel_radius, palm_center, longitudinal, span, palmar


def _skin(mesh_obj, suffix):
    mat = bpy.data.materials.new("ReferenceGraspSkinV65_" + suffix)
    mat.use_nodes = True
    p = next((n for n in mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED"), None)
    if p:
        p.inputs["Base Color"].default_value = (0.47, 0.29, 0.21, 1.0)
        p.inputs["Roughness"].default_value = 0.58
    mesh_obj.data.materials.clear()
    mesh_obj.data.materials.append(mat)


def _vessel(center: Vector, axis_world: Vector, radius: float, suffix: str):
    bpy.ops.mesh.primitive_cylinder_add(vertices=64, radius=radius, depth=0.22, location=center)
    obj = bpy.context.object
    obj.name = "ReferenceVesselV65_" + suffix
    # Blender cylinder defaults along Z; orient Z to the palm-longitudinal / bottle axis.
    obj.rotation_mode = "QUATERNION"
    obj.rotation_quaternion = Vector((0.0, 0.0, 1.0)).rotation_difference(axis_world.normalized())
    mat = bpy.data.materials.new("ReferenceVesselMatV65_" + suffix)
    mat.use_nodes = True
    p = next((n for n in mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED"), None)
    if p:
        p.inputs["Base Color"].default_value = (0.045, 0.11, 0.16, 1.0)
        p.inputs["Roughness"].default_value = 0.45
    obj.data.materials.append(mat)
    return obj


def _look(cam, target):
    cam.rotation_euler = (target - cam.location).to_track_quat("-Z", "Y").to_euler()


def _scene_camera(focus: Vector, longitudinal: Vector, span: Vector, palmar: Vector, suffix: str):
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE_NEXT"
    scene.render.image_settings.file_format = "PNG"
    scene.world.color = (0.025, 0.028, 0.035)
    cd = bpy.data.cameras.new("ReferenceGraspCameraV65_" + suffix)
    cam = bpy.data.objects.new("ReferenceGraspCameraV65_" + suffix, cd)
    scene.collection.objects.link(cam)
    scene.camera = cam
    cd.lens = 68
    # Oblique product-like diagnostic: enough palmar view to judge enclosure and thumb opposition.
    cam.location = focus - palmar * 0.30 - span * 0.16 + longitudinal * 0.07
    _look(cam, focus)
    kd = bpy.data.lights.new("ReferenceGraspKeyV65_" + suffix, "AREA")
    kd.energy = 300; kd.size = 0.8
    key = bpy.data.objects.new("ReferenceGraspKeyV65_" + suffix, kd)
    key.location = focus - palmar * 0.35 - span * 0.25 + longitudinal * 0.35
    scene.collection.objects.link(key)
    fd = bpy.data.lights.new("ReferenceGraspFillV65_" + suffix, "AREA")
    fd.energy = 95; fd.size = 0.7
    fill = bpy.data.objects.new("ReferenceGraspFillV65_" + suffix, fd)
    fill.location = focus + palmar * 0.12 + span * 0.20 + longitudinal * 0.18
    scene.collection.objects.link(fill)
    return cam


def _render(path: Path, width: int, height: int):
    scene = bpy.context.scene
    scene.render.resolution_x = width
    scene.render.resolution_y = height
    scene.render.resolution_percentage = 100
    scene.render.filepath = str(path)
    bpy.ops.render.render(write_still=True)
    if not path.is_file() or path.stat().st_size <= 0:
        raise RuntimeError("render failed: " + str(path))


def _set_visible(baked, vessel, vessel_visible=True):
    baked.hide_render = False
    vessel.hide_render = not vessel_visible


def _diagnostics(arm, vessel_center: Vector, longitudinal: Vector, palmar: Vector):
    palm_center, _, _, _ = _palm_frame(arm)
    palm_radial = (palm_center - vessel_center).normalized()
    tips = {}
    far_side = 0
    for digit in range(2, 6):
        tip = _wp(arm, f"finger{digit}-3.R", True)
        radial = tip - vessel_center
        axial = longitudinal * radial.dot(longitudinal)
        radial_plane = radial - axial
        score = radial_plane.normalized().dot(palm_radial) if radial_plane.length > 1e-6 else 1.0
        tips[str(digit)] = {"world": [float(x) for x in tip], "palm_side_dot": float(score)}
        if score < -0.05:
            far_side += 1
    thumb = _wp(arm, "finger1-3.R", True)
    thumb_radial = thumb - vessel_center
    thumb_radial -= longitudinal * thumb_radial.dot(longitudinal)
    thumb_dot = thumb_radial.normalized().dot(palm_radial) if thumb_radial.length > 1e-6 else 1.0
    return {"finger_tips": tips, "far_side_finger_count": far_side, "thumb_palm_side_dot": float(thumb_dot)}


def _build_candidate(HumanService, out: Path, suffix: str, palmar_sign: float):
    # Remove previous candidate before constructing the next sign branch.
    _reset()
    basemesh = HumanService.create_human(
        mask_helpers=True,
        detailed_helpers=False,
        extra_vertex_groups=True,
        feet_on_ground=False,
        scale=0.1,
        macro_detail_dict=None,
    )
    if basemesh is None or basemesh.type != "MESH":
        raise RuntimeError("MPFB human creation failed")
    arm = HumanService.add_builtin_rig(basemesh, "default", import_weights=True, operator=None)
    if arm is None or arm.type != "ARMATURE":
        raise RuntimeError("MPFB canonical default rig creation failed")

    vessel_center, vessel_radius, palm_center, longitudinal, span, palmar = _author_power_grasp(arm, palmar_sign)
    diagnostics = _diagnostics(arm, vessel_center, longitudinal, palmar)
    segments = v64._selected_segments(arm)

    baked = v64._bake_deformed_mesh(basemesh)
    baked.name = "ReferenceGraspBakedV65_" + suffix
    v64b._adaptive_crop(baked, segments, palm_center)
    _skin(baked, suffix)
    vessel = _vessel(vessel_center, longitudinal, vessel_radius, suffix)

    # Sacrificial rig is deleted before evidence and export; pose is now static baked geometry.
    bpy.data.objects.remove(basemesh, do_unlink=True)
    bpy.data.objects.remove(arm, do_unlink=True)

    focus = palm_center.lerp(vessel_center, 0.55)
    cam = _scene_camera(focus, longitudinal, span, palmar, suffix)
    with_vessel = out / f"support-wrap-{suffix}-with-vessel.png"
    thumb = out / f"support-wrap-{suffix}-thumbnail.png"
    _set_visible(baked, vessel, True)
    _render(with_vessel, 640, 640)
    _render(thumb, 192, 108)

    # Unobstructed anatomy evidence from the exact same baked mesh/pose.
    vessel.hide_render = True
    anatomy_oblique = out / f"support-wrap-{suffix}-anatomy-oblique.png"
    anatomy_thumb = out / f"support-wrap-{suffix}-anatomy-thumbnail.png"
    _render(anatomy_oblique, 640, 640)
    _render(anatomy_thumb, 192, 108)

    glb = out / f"right-support-wrap-v65-{suffix}-static.glb"
    v64._export_static_glb(glb, baked)
    return {
        "suffix": suffix,
        "palmar_sign": palmar_sign,
        "baked_vertices": len(baked.data.vertices),
        "baked_polygons": len(baked.data.polygons),
        "palm_vertex_coverage": int(baked.get("v64b_palm_vertex_coverage", 0)),
        "min_segment_vertex_coverage": int(baked.get("v64b_min_segment_vertex_coverage", 0)),
        "vessel_radius": vessel_radius,
        "diagnostics": diagnostics,
        "glb": str(glb),
        "glb_bytes": glb.stat().st_size,
    }


def run():
    extension_module, out, report_path = _args()
    out.mkdir(parents=True, exist_ok=True)
    report_path.parent.mkdir(parents=True, exist_ok=True)
    mpfb, HumanService = _services(extension_module)

    candidates = [
        _build_candidate(HumanService, out, "A", +1.0),
        _build_candidate(HumanService, out, "B", -1.0),
    ]
    report = {
        "staging_only": True,
        "production_candidate": False,
        "reference_set": ["bar_v1", "market_v1"],
        "pose_source": "reference-derived deterministic native canonical grasp",
        "external_pose_source_used": False,
        "ccd_used": False,
        "endpoint_optimizer_used": False,
        "parameter_sweep_used": False,
        "basis_sign_disambiguation_only": True,
        "production_gameengine_rig_touched": False,
        "mpfb_version": list(mpfb.VERSION),
        "candidate_count": len(candidates),
        "candidates": candidates,
        "visual_gate": "Choose neither unless the 192x108 with-vessel thumbnail clearly reads as palm-on-near-side + digits enclosing far contour + opposing thumb; then require continuous non-self-intersecting anatomy in oblique evidence.",
    }
    report_path.write_text(json.dumps(report, indent=2, sort_keys=True), encoding="utf-8")
    print(json.dumps(report, indent=2, sort_keys=True))
    print(SUCCESS)


if __name__ == "__main__":
    try:
        run()
    except BaseException as exc:
        print("MPFB_REFERENCE_GRASP_V65_ERROR:", exc)
        traceback.print_exc()
        raise
