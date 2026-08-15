#!/usr/bin/env python3
"""v71 diagnostic: make the frozen v65-B thumb silhouette measurable in camera space.

Checkpoint 31 proved that the canonical MPFB thumb bones strongly and selectively deform the
visible skin. The remaining R1 question is therefore not bone mapping or weights, but whether the
thumb is actually visible as an opposing digit in the locked support-grasp camera.

This script deliberately authors NO new pose. It reconstructs pristine v65-B, freezes wrist,
palm, vessel and all five digit chains exactly as v65 authored them, then renders a high-contrast
ID view where faces influenced by the three canonical thumb groups are magenta, other hand skin
is gray, and the vessel is cyan. It also projects thumb root/tip and a sampled vessel contour into
192x108 screen coordinates and reports visible thumb pixel area/bounds with and without vessel
occlusion. Those measurements define the next pose target; they do not promote this staging pose.
"""
from __future__ import annotations

import importlib.util
import json
import math
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
THUMB_BONES = ["finger1-1.R", "finger1-2.R", "finger1-3.R"]
THUMB_FACE_WEIGHT = 0.25
W = 192
H = 108


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


def _disable_non_armature_modifiers(obj):
    states = []
    for modifier in obj.modifiers:
        states.append((modifier, bool(modifier.show_viewport), bool(modifier.show_render)))
        if modifier.type != "ARMATURE":
            modifier.show_viewport = False
            modifier.show_render = False
    bpy.context.view_layer.update()
    return states


def _restore_modifiers(states):
    for modifier, show_viewport, show_render in states:
        modifier.show_viewport = show_viewport
        modifier.show_render = show_render
    bpy.context.view_layer.update()


def _thumb_weights(mesh_obj):
    group_by_index = {g.index: g.name for g in mesh_obj.vertex_groups}
    missing = [name for name in THUMB_BONES if mesh_obj.vertex_groups.get(name) is None]
    if missing:
        raise RuntimeError("missing canonical thumb groups: " + str(missing))
    weights = []
    for vertex in mesh_obj.data.vertices:
        total = 0.0
        for assignment in vertex.groups:
            if group_by_index.get(assignment.group) in THUMB_BONES:
                total += float(assignment.weight)
        weights.append(total)
    return weights


def _evaluated_mesh_object(source, name: str):
    depsgraph = bpy.context.evaluated_depsgraph_get()
    bpy.context.view_layer.update()
    evaluated = source.evaluated_get(depsgraph)
    mesh = bpy.data.meshes.new_from_object(evaluated, preserve_all_data_layers=True, depsgraph=depsgraph)
    if len(mesh.vertices) != len(source.data.vertices):
        raise RuntimeError(f"armature-only topology changed {len(source.data.vertices)} -> {len(mesh.vertices)}")
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(obj)
    obj.matrix_world = evaluated.matrix_world.copy()
    return obj


def _emission_material(name: str, rgba):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    nodes.clear()
    out = nodes.new("ShaderNodeOutputMaterial")
    emission = nodes.new("ShaderNodeEmission")
    emission.inputs["Color"].default_value = rgba
    emission.inputs["Strength"].default_value = 1.0
    links.new(emission.outputs["Emission"], out.inputs["Surface"])
    return mat


def _assign_id_materials(obj, weights):
    hand = _emission_material("V71HandID", (0.18, 0.18, 0.18, 1.0))
    thumb = _emission_material("V71ThumbID", (1.0, 0.0, 0.55, 1.0))
    obj.data.materials.clear()
    obj.data.materials.append(hand)
    obj.data.materials.append(thumb)
    for poly in obj.data.polygons:
        poly.material_index = 1 if max(weights[i] for i in poly.vertices) >= THUMB_FACE_WEIGHT else 0


def _make_vessel(center: Vector, axis: Vector, radius: float):
    bpy.ops.mesh.primitive_cylinder_add(vertices=64, radius=radius, depth=0.22, location=center)
    obj = bpy.context.object
    obj.name = "V71VesselID"
    obj.rotation_mode = "QUATERNION"
    obj.rotation_quaternion = Vector((0.0, 0.0, 1.0)).rotation_difference(axis.normalized())
    obj.data.materials.append(_emission_material("V71VesselMat", (0.0, 0.72, 1.0, 1.0)))
    return obj


def _configure_scene():
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE_NEXT"
    scene.render.image_settings.file_format = "PNG"
    scene.render.film_transparent = False
    scene.world.color = (0.0, 0.0, 0.0)
    scene.view_settings.view_transform = "Standard"
    scene.view_settings.look = "Medium High Contrast" if "Medium High Contrast" in [i.name for i in bpy.types.ColorManagedViewSettings.bl_rna.properties['look'].enum_items] else scene.view_settings.look
    return scene


def _look(cam, target):
    cam.rotation_euler = (target - cam.location).to_track_quat("-Z", "Y").to_euler()


def _camera(focus: Vector, longitudinal: Vector, span: Vector, palmar: Vector):
    scene = _configure_scene()
    cd = bpy.data.cameras.new("ThumbSilhouetteCameraV71")
    cam = bpy.data.objects.new("ThumbSilhouetteCameraV71", cd)
    scene.collection.objects.link(cam)
    scene.camera = cam
    cd.lens = 68
    # Exact same placement formula as v65 support-grasp evidence.
    cam.location = focus - palmar * 0.30 - span * 0.16 + longitudinal * 0.07
    _look(cam, focus)
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


def _project(cam, world: Vector):
    scene = bpy.context.scene
    ndc = world_to_camera_view(scene, cam, world)
    return [float(ndc.x * W), float((1.0 - ndc.y) * H), float(ndc.z)]


def _vessel_screen_samples(cam, center: Vector, longitudinal: Vector, span: Vector, palmar: Vector, radius: float):
    samples = []
    for axial in (-0.11, 0.0, 0.11):
        base = center + longitudinal * axial
        for degrees in range(0, 360, 15):
            a = math.radians(float(degrees))
            p = base + span * (math.cos(a) * radius) + palmar * (math.sin(a) * radius)
            samples.append(_project(cam, p))
    xs = [p[0] for p in samples]
    ys = [p[1] for p in samples]
    return {"samples": samples, "bbox_px": [min(xs), min(ys), max(xs), max(ys)]}


def _classify_thumb_pixels(path: Path):
    img = bpy.data.images.load(str(path), check_existing=False)
    try:
        width, height = img.size
        pixels = list(img.pixels)
        coords = []
        for y in range(height):
            for x in range(width):
                i = (y * width + x) * 4
                r, g, b, a = pixels[i:i+4]
                # Robust to AA/color-management: magenta thumb remains red-dominant with blue content.
                if a > 0.5 and r > 0.55 and r > g * 1.8 and b > g * 1.35:
                    coords.append((x, height - 1 - y))
        if not coords:
            return {"count": 0, "fraction": 0.0, "bbox_px": None, "width_px": 0, "height_px": 0}
        xs = [p[0] for p in coords]; ys = [p[1] for p in coords]
        bbox = [min(xs), min(ys), max(xs), max(ys)]
        return {
            "count": len(coords),
            "fraction": float(len(coords) / (width * height)),
            "bbox_px": bbox,
            "width_px": int(bbox[2] - bbox[0] + 1),
            "height_px": int(bbox[3] - bbox[1] + 1),
        }
    finally:
        bpy.data.images.remove(img)


def run():
    extension_module, out, report_path = _args()
    out.mkdir(parents=True, exist_ok=True)
    report_path.parent.mkdir(parents=True, exist_ok=True)
    _reset()
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

    # Freeze the exact v65-B pose. No new pose authoring occurs in v71.
    vessel_center, vessel_radius, palm_center, longitudinal, span, palmar = v65._author_power_grasp(arm, -1.0)
    weights = _thumb_weights(basemesh)
    modifier_states = _disable_non_armature_modifiers(basemesh)
    try:
        diagnostic = _evaluated_mesh_object(basemesh, "ThumbSilhouetteMeshV71")
    finally:
        _restore_modifiers(modifier_states)

    segments = v64._selected_segments(arm)
    v64b._adaptive_crop(diagnostic, segments, palm_center)
    # Material assignment must use pre-crop source weights. Crop preserves polygon material indices,
    # so assign before a second crop would remap indices; adaptive crop has already completed here.
    # Reconstruct a conservative post-crop thumb classification spatially from the retained groups
    # is impossible after baking, so apply materials to the uncropped indexed mesh then crop again.
    bpy.data.objects.remove(diagnostic, do_unlink=True)
    modifier_states = _disable_non_armature_modifiers(basemesh)
    try:
        diagnostic = _evaluated_mesh_object(basemesh, "ThumbSilhouetteMeshV71")
        _assign_id_materials(diagnostic, weights)
    finally:
        _restore_modifiers(modifier_states)
    v64b._adaptive_crop(diagnostic, segments, palm_center)

    basemesh.hide_render = True
    arm.hide_render = True
    vessel = _make_vessel(vessel_center, longitudinal, vessel_radius)
    focus = palm_center.lerp(vessel_center, 0.55)
    cam = _camera(focus, longitudinal, span, palmar)

    root_world = v65._wp(arm, "finger1-1.R")
    tip_world = v65._wp(arm, "finger1-3.R", True)
    root_px = _project(cam, root_world)
    tip_px = _project(cam, tip_world)
    vessel_projection = _vessel_screen_samples(cam, vessel_center, longitudinal, span, palmar, vessel_radius)

    with_vessel = out / "thumb-id-with-vessel-192x108.png"
    anatomy = out / "thumb-id-anatomy-192x108.png"
    full = out / "thumb-id-with-vessel-640.png"
    vessel.hide_render = False
    _render(with_vessel, W, H)
    _render(full, 640, 640)
    vessel.hide_render = True
    _render(anatomy, W, H)

    visible = _classify_thumb_pixels(with_vessel)
    unobstructed = _classify_thumb_pixels(anatomy)
    retention = float(visible["count"] / max(1, unobstructed["count"]))
    vb = vessel_projection["bbox_px"]
    tip_outside_vessel = bool(tip_px[0] < vb[0] - 4.0 or tip_px[0] > vb[2] + 4.0 or tip_px[1] < vb[1] - 4.0 or tip_px[1] > vb[3] + 4.0)

    # This is the explicit screen-space target for the NEXT single pose authoring pass.
    target_gate = {
        "thumbnail_size": [W, H],
        "min_visible_thumb_pixels": 120,
        "min_visible_fraction": 120.0 / (W * H),
        "min_visible_bbox_width_px": 8,
        "min_vessel_occlusion_retention": 0.35,
        "thumb_tip_must_clear_vessel_bbox_by_px": 4,
        "intent": "thumb must read as a separate opposing contour/region at thumbnail scale, not collapse into palm or disappear behind vessel",
    }
    current_pass = bool(
        visible["count"] >= target_gate["min_visible_thumb_pixels"]
        and visible["width_px"] >= target_gate["min_visible_bbox_width_px"]
        and retention >= target_gate["min_vessel_occlusion_retention"]
        and tip_outside_vessel
    )

    report = {
        "diagnostic_only": True,
        "production_candidate": False,
        "pose_authored_in_v71": False,
        "base_pose": "pristine v65-B",
        "reference_set": ["bar_v1", "market_v1"],
        "mpfb_version": list(mpfb.VERSION),
        "thumb_bones": THUMB_BONES,
        "thumb_face_weight_threshold": THUMB_FACE_WEIGHT,
        "screen": {"width": W, "height": H},
        "thumb_root_px": root_px,
        "thumb_tip_px": tip_px,
        "vessel_projection": vessel_projection,
        "visible_thumb_with_vessel": visible,
        "visible_thumb_without_vessel": unobstructed,
        "vessel_occlusion_retention": retention,
        "thumb_tip_outside_vessel_bbox_by_gate_margin": tip_outside_vessel,
        "target_gate_for_next_pose": target_gate,
        "current_v65_b_passes_target_gate": current_pass,
        "interpretation": "v71 does not change the pose. A fail is expected to quantify exactly how the current v65-B thumb disappears in camera space. The next pose may change only the thumb chain and must target this screen-space gate while preserving the frozen v65-B wrist/palm/vessel/four-finger grasp.",
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
