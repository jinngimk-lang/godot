#!/usr/bin/env python3
"""v71: freeze pristine v65-B and measure the thumb in camera space.

Checkpoint 31 proved that the canonical MPFB thumb bones strongly and selectively deform the
visible skin.  The remaining R1 is therefore not another 3D pose-search problem: it is whether
the thumb produces an independently legible opposing silhouette in the locked product-like
thumbnail view.

This script is diagnostic-only.  It does not change the v65-B pose, wrist, four non-thumb finger
chains, vessel, camera, crop, or rig.  It renders the exact v65-B hand with thumb-influenced skin
highlighted, then records projected thumb root/tip, the high-weight thumb-skin bounding box and
the projected vessel contour at 192x108 scale.  The resulting screen-space contract is the input
to the next single same-rig authoring step; it is not an optimizer and does not auto-promote the
candidate.
"""
from __future__ import annotations

import importlib.util
import json
import sys
import traceback
from pathlib import Path

import bpy
from bpy_extras.object_utils import world_to_camera_view
from mathutils import Vector

BASE = Path(__file__).resolve().parent
SPEC = importlib.util.spec_from_file_location("mpfb_v65_for_v71", BASE / "author_mpfb_reference_grasp_v65.py")
if SPEC is None or SPEC.loader is None:
    raise RuntimeError("could not load v65 helpers")
v65 = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(v65)
v64 = v65.v64
v64b = v65.v64b

SUCCESS = "MPFB_THUMB_SILHOUETTE_V71_SUCCESS"
THUMB_BONES = ("finger1-1.R", "finger1-2.R", "finger1-3.R")
WIDTH = 192
HEIGHT = 108


def _args():
    if "--" not in sys.argv:
        raise RuntimeError("expected -- <extension-module> <outdir> <report.json>")
    values = sys.argv[sys.argv.index("--") + 1:]
    if len(values) != 3:
        raise RuntimeError("expected three arguments")
    return values[0], Path(values[1]).resolve(), Path(values[2]).resolve()


def _combined_thumb_weights(obj):
    group_indices = []
    for name in THUMB_BONES:
        group = obj.vertex_groups.get(name)
        if group is None:
            raise RuntimeError("missing thumb vertex group " + name)
        group_indices.append(group.index)
    wanted = set(group_indices)
    result = []
    for vertex in obj.data.vertices:
        total = 0.0
        for element in vertex.groups:
            if element.group in wanted:
                total += float(element.weight)
        result.append(min(total, 1.0))
    return result


def _posed_static_with_thumb_materials(basemesh, weights):
    modifier_states = []
    for modifier in basemesh.modifiers:
        modifier_states.append((modifier, modifier.show_viewport, modifier.show_render))
        if modifier.type != "ARMATURE":
            modifier.show_viewport = False
            modifier.show_render = False
    try:
        bpy.context.view_layer.update()
        depsgraph = bpy.context.evaluated_depsgraph_get()
        evaluated = basemesh.evaluated_get(depsgraph)
        mesh = bpy.data.meshes.new_from_object(evaluated, preserve_all_data_layers=True, depsgraph=depsgraph)
        if len(mesh.vertices) != len(weights):
            raise RuntimeError(f"topology mismatch while building v71 ID mesh: {len(mesh.vertices)} != {len(weights)}")
        obj = bpy.data.objects.new("ThumbSilhouetteV71", mesh)
        bpy.context.scene.collection.objects.link(obj)
        obj.matrix_world = basemesh.matrix_world.copy()
    finally:
        for modifier, viewport, render in modifier_states:
            modifier.show_viewport = viewport
            modifier.show_render = render
        bpy.context.view_layer.update()

    base = bpy.data.materials.new("ThumbSilhouetteBaseV71")
    base.use_nodes = True
    bp = next((n for n in base.node_tree.nodes if n.type == "BSDF_PRINCIPLED"), None)
    if bp:
        bp.inputs["Base Color"].default_value = (0.16, 0.17, 0.19, 1.0)
        bp.inputs["Roughness"].default_value = 0.92

    thumb = bpy.data.materials.new("ThumbSilhouetteIDV71")
    thumb.use_nodes = True
    tp = next((n for n in thumb.node_tree.nodes if n.type == "BSDF_PRINCIPLED"), None)
    if tp:
        tp.inputs["Base Color"].default_value = (0.02, 0.95, 0.92, 1.0)
        tp.inputs["Roughness"].default_value = 0.45
        if "Emission Color" in tp.inputs:
            tp.inputs["Emission Color"].default_value = (0.0, 0.35, 0.32, 1.0)
            tp.inputs["Emission Strength"].default_value = 1.2

    obj.data.materials.clear()
    obj.data.materials.append(base)
    obj.data.materials.append(thumb)
    marked_faces = 0
    for polygon in obj.data.polygons:
        max_weight = max(weights[i] for i in polygon.vertices)
        if max_weight >= 0.35:
            polygon.material_index = 1
            marked_faces += 1
        else:
            polygon.material_index = 0
    if marked_faces <= 0:
        raise RuntimeError("v71 found no thumb-influenced faces")
    return obj, marked_faces


def _project(scene, cam, point: Vector):
    ndc = world_to_camera_view(scene, cam, point)
    # Blender NDC has origin at bottom-left; report both normalized and top-left pixel coordinates.
    return {
        "uv_bottom_left": [float(ndc.x), float(ndc.y)],
        "px_top_left": [float(ndc.x * WIDTH), float((1.0 - ndc.y) * HEIGHT)],
        "depth": float(ndc.z),
    }


def _pixel_bbox(scene, cam, points):
    projected = [_project(scene, cam, p)["px_top_left"] for p in points]
    xs = [p[0] for p in projected]
    ys = [p[1] for p in projected]
    return {
        "min": [float(min(xs)), float(min(ys))],
        "max": [float(max(xs)), float(max(ys))],
        "width_px": float(max(xs) - min(xs)),
        "height_px": float(max(ys) - min(ys)),
        "center_px": [float((min(xs) + max(xs)) * 0.5), float((min(ys) + max(ys)) * 0.5)],
        "projected_point_count": len(projected),
    }


def run():
    extension_module, out, report_path = _args()
    out.mkdir(parents=True, exist_ok=True)
    report_path.parent.mkdir(parents=True, exist_ok=True)
    v65._reset()
    mpfb, HumanService = v65._services(extension_module)

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

    # Freeze pristine v65-B exactly.  No v66-v70 pose mutation is called here.
    vessel_center, vessel_radius, palm_center, longitudinal, span, palmar = v65._author_power_grasp(arm, -1.0)
    bpy.context.view_layer.update()
    segments = v64._selected_segments(arm)
    weights = _combined_thumb_weights(basemesh)

    diagnostic, marked_faces = _posed_static_with_thumb_materials(basemesh, weights)
    high_weight_world = [diagnostic.matrix_world @ diagnostic.data.vertices[i].co for i, w in enumerate(weights) if w >= 0.5]
    if len(high_weight_world) < 20:
        raise RuntimeError("too few high-weight thumb skin vertices for screen-space diagnostic")
    v64b._adaptive_crop(diagnostic, segments, palm_center)

    vessel = v65._vessel(vessel_center, longitudinal, vessel_radius, "B71")
    # Darker vessel makes the cyan thumb-ID region unambiguous without changing geometry.
    if vessel.data.materials:
        mat = vessel.data.materials[0]
        p = next((n for n in mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED"), None) if mat and mat.use_nodes else None
        if p:
            p.inputs["Base Color"].default_value = (0.015, 0.035, 0.055, 1.0)
            p.inputs["Roughness"].default_value = 0.65

    focus = palm_center.lerp(vessel_center, 0.55)
    cam = v65._scene_camera(focus, longitudinal, span, palmar, "B71")
    scene = bpy.context.scene

    # Hide the live source rig/body: the evidence comes from the exact posed static diagnostic mesh.
    basemesh.hide_render = True
    arm.hide_render = True
    diagnostic.hide_render = False
    vessel.hide_render = False
    with_vessel = out / "thumb-id-with-vessel.png"
    thumb_image = out / "thumb-id-thumbnail.png"
    v65._render(with_vessel, 640, 640)
    v65._render(thumb_image, WIDTH, HEIGHT)

    vessel.hide_render = True
    anatomy = out / "thumb-id-anatomy-oblique.png"
    anatomy_thumb = out / "thumb-id-anatomy-thumbnail.png"
    v65._render(anatomy, 640, 640)
    v65._render(anatomy_thumb, WIDTH, HEIGHT)

    thumb_root = v65._wp(arm, "finger1-1.R")
    thumb_tip = v65._wp(arm, "finger1-3.R", True)
    view_dir = (focus - cam.location).normalized()
    contour_axis = longitudinal.cross(view_dir).normalized()
    if contour_axis.length_squared < 0.5:
        contour_axis = span.normalized()
    contour_a = vessel_center + contour_axis * vessel_radius
    contour_b = vessel_center - contour_axis * vessel_radius

    root_proj = _project(scene, cam, thumb_root)
    tip_proj = _project(scene, cam, thumb_tip)
    contour_proj = [_project(scene, cam, contour_a), _project(scene, cam, contour_b)]
    contour_xs = sorted(p["px_top_left"][0] for p in contour_proj)
    vessel_diameter_px = float(contour_xs[1] - contour_xs[0])
    bbox = _pixel_bbox(scene, cam, high_weight_world)
    root_tip_span_px = float(Vector(root_proj["px_top_left"]).xy.__sub__(Vector(tip_proj["px_top_left"]).xy).length)
    bbox_outside_left = max(0.0, contour_xs[0] - bbox["min"][0])
    bbox_outside_right = max(0.0, bbox["max"][0] - contour_xs[1])
    outside_px = float(max(bbox_outside_left, bbox_outside_right))
    radius_px = max(vessel_diameter_px * 0.5, 1e-6)

    report = {
        "diagnostic_only": True,
        "production_candidate": False,
        "base_pose": "pristine v65-B",
        "reference_set": ["bar_v1", "market_v1"],
        "pose_changed_from_v65_b": False,
        "wrist_changed_from_v65_b": False,
        "non_thumb_fingers_changed_from_v65_b": False,
        "vessel_changed_from_v65_b": False,
        "camera_changed_from_v65_b": False,
        "crop_policy_changed_from_v65_b": False,
        "thumb_bones": list(THUMB_BONES),
        "thumb_face_weight_threshold": 0.35,
        "high_weight_vertex_threshold": 0.5,
        "high_weight_thumb_vertex_count": len(high_weight_world),
        "marked_thumb_face_count_before_crop": marked_faces,
        "thumbnail_size": [WIDTH, HEIGHT],
        "projected_thumb_root": root_proj,
        "projected_thumb_tip": tip_proj,
        "projected_thumb_skin_bbox": bbox,
        "projected_vessel_contour": contour_proj,
        "projected_vessel_diameter_px": vessel_diameter_px,
        "projected_thumb_root_tip_span_px": root_tip_span_px,
        "projected_thumb_bbox_outside_vessel_px": outside_px,
        "normalized_root_tip_span_over_vessel_radius": float(root_tip_span_px / radius_px),
        "normalized_bbox_outside_over_vessel_radius": float(outside_px / radius_px),
        "screen_space_contract_for_next_pose": {
            "visual_requirement": "At 192x108 the cyan thumb-influenced skin must form an independently legible opposing contour/region rather than disappearing into the palm or vessel; the four frozen v65-B fingers must remain unchanged and enclosing.",
            "structural_target": "Increase visible camera-space opposition, not raw 3D bone travel. The next single pose must enlarge a continuous root-to-tip thumb silhouette on the near/opposing side while preserving unobstructed anatomy continuity.",
            "provisional_measurement_guard": "Use the v71 measurements as baseline evidence. A next pose is not accepted from metrics alone; it must visibly improve the 192x108 ID view and anatomy-oblique view. Root-tip span and thumb-skin area outside the vessel contour should both increase materially without self-intersection.",
        },
        "mpfb_version": list(mpfb.VERSION),
        "evidence": [str(with_vessel), str(thumb_image), str(anatomy), str(anatomy_thumb)],
    }
    report_path.write_text(json.dumps(report, indent=2, sort_keys=True), encoding="utf-8")
    print(json.dumps(report, indent=2, sort_keys=True))
    print(SUCCESS)


if __name__ == "__main__":
    try:
        run()
    except BaseException as exc:
        print("MPFB_THUMB_SILHOUETTE_V71_ERROR:", exc)
        traceback.print_exc()
        raise
