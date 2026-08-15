#!/usr/bin/env python3
"""v71b: measure the frozen v65-B grasp purely from rendered 192x108 ID pixels.

v71 proved the thumb has plenty of visible skin area and is not mainly lost to vessel occlusion,
but its bone/world projection diagnostic was invalid for this staging scene.  v71b removes all
bone-landmark projection from acceptance and asks the actual Macro question instead: are thumb and
the four opposing digits visibly on opposite sides of the rendered vessel centerline?

No pose is authored here.  The exact pristine v65-B pose/camera/crop are frozen.  Five digit
families receive distinct emission IDs and the vessel receives cyan.  The report derives all
centroids, clipping, the vessel centerline, and opposition signs from the rendered pixels only.
"""
from __future__ import annotations

import importlib.util
import json
import statistics
import sys
import traceback
from pathlib import Path

import bpy

BASE = Path(__file__).resolve().parent
SPEC = importlib.util.spec_from_file_location("mpfb_v65_for_v71b", BASE / "author_mpfb_reference_grasp_v65.py")
if SPEC is None or SPEC.loader is None:
    raise RuntimeError("could not load v65 helpers")
v65 = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(v65)
v64 = v65.v64
v64b = v65.v64b

SUCCESS = "MPFB_DIGIT_OPPOSITION_V71B_SUCCESS"
W, H = 192, 108
FACE_WEIGHT = 0.25
DIGITS = {
    "thumb": 1,
    "index": 2,
    "middle": 3,
    "ring": 4,
    "pinky": 5,
}
# Linear emission colors deliberately occupy separated RGB sectors after Standard display transform.
COLORS = {
    "palm": (0.18, 0.18, 0.18, 1.0),
    "thumb": (1.0, 0.0, 0.55, 1.0),
    "index": (1.0, 0.80, 0.0, 1.0),
    "middle": (0.05, 1.0, 0.10, 1.0),
    "ring": (1.0, 0.18, 0.0, 1.0),
    "pinky": (0.38, 0.04, 1.0, 1.0),
    "vessel": (0.0, 0.72, 1.0, 1.0),
}


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


def _evaluated_mesh_object(source, name: str):
    depsgraph = bpy.context.evaluated_depsgraph_get()
    bpy.context.view_layer.update()
    evaluated = source.evaluated_get(depsgraph)
    mesh = bpy.data.meshes.new_from_object(evaluated, preserve_all_data_layers=True, depsgraph=depsgraph)
    if len(mesh.vertices) != len(source.data.vertices):
        raise RuntimeError(f"armature-only topology changed {len(source.data.vertices)} -> {len(mesh.vertices)}")
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(obj)
    obj.matrix_world = source.matrix_world.copy()
    return obj


def _digit_weights(mesh_obj):
    group_names = {g.index: g.name for g in mesh_obj.vertex_groups}
    wanted = {
        name: {f"finger{digit}-{joint}.R" for joint in range(1, 4)}
        for name, digit in DIGITS.items()
    }
    missing = [bone for bones in wanted.values() for bone in bones if mesh_obj.vertex_groups.get(bone) is None]
    if missing:
        raise RuntimeError("missing canonical digit groups: " + str(sorted(missing)))
    rows = []
    for vertex in mesh_obj.data.vertices:
        values = {name: 0.0 for name in DIGITS}
        for assignment in vertex.groups:
            group_name = group_names.get(assignment.group)
            for name, bones in wanted.items():
                if group_name in bones:
                    values[name] += float(assignment.weight)
                    break
        rows.append(values)
    return rows


def _emission(name: str, rgba):
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


def _assign_digit_materials(obj, weight_rows):
    order = ["palm", "thumb", "index", "middle", "ring", "pinky"]
    obj.data.materials.clear()
    for name in order:
        obj.data.materials.append(_emission("V71B_" + name, COLORS[name]))
    index_by_name = {name: i for i, name in enumerate(order)}
    for poly in obj.data.polygons:
        score = {name: max(weight_rows[i][name] for i in poly.vertices) for name in DIGITS}
        winner = max(score, key=score.get)
        poly.material_index = index_by_name[winner] if score[winner] >= FACE_WEIGHT else index_by_name["palm"]


def _make_vessel(center, axis, radius):
    bpy.ops.mesh.primitive_cylinder_add(vertices=64, radius=radius, depth=0.22, location=center)
    obj = bpy.context.object
    obj.name = "V71B_VesselID"
    obj.rotation_mode = "QUATERNION"
    obj.rotation_quaternion = v65.Vector((0.0, 0.0, 1.0)).rotation_difference(axis.normalized()) if hasattr(v65, 'Vector') else None
    if obj.rotation_quaternion is None:
        from mathutils import Vector
        obj.rotation_quaternion = Vector((0.0, 0.0, 1.0)).rotation_difference(axis.normalized())
    obj.data.materials.append(_emission("V71B_vessel", COLORS["vessel"]))
    return obj


def _look(cam, target):
    cam.rotation_euler = (target - cam.location).to_track_quat("-Z", "Y").to_euler()


def _camera(focus, longitudinal, span, palmar):
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE_NEXT"
    scene.render.image_settings.file_format = "PNG"
    scene.render.film_transparent = False
    scene.world.color = (0.0, 0.0, 0.0)
    scene.view_settings.view_transform = "Standard"
    cd = bpy.data.cameras.new("DigitOppositionCameraV71B")
    cam = bpy.data.objects.new("DigitOppositionCameraV71B", cd)
    scene.collection.objects.link(cam)
    scene.camera = cam
    cd.lens = 68
    cam.location = focus - palmar * 0.30 - span * 0.16 + longitudinal * 0.07
    _look(cam, focus)
    return cam


def _render(path: Path):
    scene = bpy.context.scene
    scene.render.resolution_x = W
    scene.render.resolution_y = H
    scene.render.resolution_percentage = 100
    scene.render.filepath = str(path)
    bpy.ops.render.render(write_still=True)
    if not path.is_file() or path.stat().st_size <= 0:
        raise RuntimeError("render failed: " + str(path))


def _pixel_rows(path: Path):
    image = bpy.data.images.load(str(path), check_existing=False)
    try:
        width, height = image.size
        pixels = list(image.pixels)
        return width, height, [pixels[i:i+4] for i in range(0, len(pixels), 4)]
    finally:
        bpy.data.images.remove(image)


def _classify(r, g, b, a):
    if a < 0.5:
        return None
    # Ordered sectors. Thresholds are intentionally broad for anti-aliased boundary pixels.
    if g > 0.55 and b > 0.65 and r < 0.35:
        return "vessel"
    if r > 0.62 and b > 0.42 and g < 0.32:
        return "thumb"
    if g > 0.62 and r < 0.42 and b < 0.45:
        return "middle"
    if b > 0.60 and r > 0.20 and g < 0.35:
        return "pinky"
    if r > 0.65 and g > 0.48 and b < 0.35:
        return "index"
    if r > 0.65 and 0.10 < g < 0.48 and b < 0.35:
        return "ring"
    return None


def _masks(path: Path):
    width, height, pixels = _pixel_rows(path)
    coords = {name: [] for name in [*DIGITS.keys(), "vessel"]}
    for y_bottom in range(height):
        y = height - 1 - y_bottom
        for x in range(width):
            label = _classify(*pixels[y_bottom * width + x])
            if label in coords:
                coords[label].append((x, y))
    result = {}
    for name, points in coords.items():
        if not points:
            result[name] = {"count": 0, "bbox_px": None, "centroid_px": None, "touches_top": False}
            continue
        xs = [p[0] for p in points]; ys = [p[1] for p in points]
        result[name] = {
            "count": len(points),
            "bbox_px": [min(xs), min(ys), max(xs), max(ys)],
            "centroid_px": [float(sum(xs)/len(xs)), float(sum(ys)/len(ys))],
            "touches_top": min(ys) == 0,
        }
    return coords, result


def _fit_vessel_centerline(vessel_points):
    # Fit x = a*y+b from row centers. Render pixels are the source of truth; no 3D projection.
    rows = {}
    for x, y in vessel_points:
        rows.setdefault(y, []).append(x)
    samples = [(float(y), (min(xs)+max(xs))/2.0) for y, xs in rows.items() if len(xs) >= 3]
    if len(samples) < 8:
        raise RuntimeError("insufficient rendered vessel rows for centerline")
    mean_y = sum(y for y, _ in samples)/len(samples)
    mean_x = sum(x for _, x in samples)/len(samples)
    denom = sum((y-mean_y)**2 for y, _ in samples)
    a = sum((y-mean_y)*(x-mean_x) for y, x in samples)/max(1e-9, denom)
    b = mean_x - a*mean_y
    residuals = [abs(x-(a*y+b)) for y, x in samples]
    return {"a_x_per_y": float(a), "b_x": float(b), "row_count": len(samples), "mean_abs_residual_px": float(sum(residuals)/len(residuals))}


def _signed_side(centroid, line):
    x, y = centroid
    center_x = line["a_x_per_y"]*y + line["b_x"]
    return float(x-center_x)


def run():
    extension_module, out, report_path = _args()
    out.mkdir(parents=True, exist_ok=True)
    report_path.parent.mkdir(parents=True, exist_ok=True)
    _reset()
    mpfb, HumanService = v65._services(extension_module)
    basemesh = HumanService.create_human(mask_helpers=True, detailed_helpers=False, extra_vertex_groups=True, feet_on_ground=False, scale=0.1, macro_detail_dict=None)
    if basemesh is None or basemesh.type != "MESH":
        raise RuntimeError("MPFB human creation failed")
    arm = HumanService.add_builtin_rig(basemesh, "default", import_weights=True, operator=None)
    if arm is None or arm.type != "ARMATURE":
        raise RuntimeError("MPFB canonical default rig creation failed")

    vessel_center, vessel_radius, palm_center, longitudinal, span, palmar = v65._author_power_grasp(arm, -1.0)
    weight_rows = _digit_weights(basemesh)
    states = _disable_non_armature_modifiers(basemesh)
    try:
        diagnostic = _evaluated_mesh_object(basemesh, "DigitOppositionMeshV71B")
        _assign_digit_materials(diagnostic, weight_rows)
    finally:
        _restore_modifiers(states)
    segments = v64._selected_segments(arm)
    v64b._adaptive_crop(diagnostic, segments, palm_center)
    basemesh.hide_render = True
    arm.hide_render = True
    vessel = _make_vessel(vessel_center, longitudinal, vessel_radius)
    focus = palm_center.lerp(vessel_center, 0.55)
    _camera(focus, longitudinal, span, palmar)

    image_path = out / "digit-opposition-v65b-192x108.png"
    _render(image_path)
    coords, masks = _masks(image_path)
    line = _fit_vessel_centerline(coords["vessel"])
    signed = {}
    for name in DIGITS:
        centroid = masks[name]["centroid_px"]
        signed[name] = None if centroid is None else _signed_side(centroid, line)

    finger_sides = [signed[name] for name in ("index", "middle", "ring", "pinky") if signed[name] is not None]
    if len(finger_sides) < 3 or signed["thumb"] is None:
        raise RuntimeError("insufficient rendered digit IDs to evaluate opposition")
    median_finger_side = float(statistics.median(finger_sides))
    thumb_side = float(signed["thumb"])
    opposite_sign = thumb_side * median_finger_side < 0.0
    min_clearance = 4.0
    opposition_pass = bool(opposite_sign and abs(thumb_side) >= min_clearance and abs(median_finger_side) >= min_clearance and not masks["thumb"]["touches_top"])

    report = {
        "diagnostic_only": True,
        "production_candidate": False,
        "pose_authored_in_v71b": False,
        "base_pose": "pristine v65-B",
        "reference_set": ["bar_v1", "market_v1"],
        "mpfb_version": list(mpfb.VERSION),
        "screen": {"width": W, "height": H},
        "render_space_only": True,
        "bone_projection_used": False,
        "face_weight_threshold": FACE_WEIGHT,
        "masks": masks,
        "vessel_centerline": line,
        "digit_signed_side_px": signed,
        "median_four_finger_side_px": median_finger_side,
        "thumb_side_px": thumb_side,
        "thumb_and_fingers_have_opposite_sign": opposite_sign,
        "screen_space_opposition_gate": {
            "min_side_clearance_px": min_clearance,
            "thumb_must_not_touch_top_frame": True,
            "pass": opposition_pass,
            "intent": "thumb and median four-finger mass must occupy opposite rendered sides of the vessel centerline with readable clearance at 192x108",
        },
        "interpretation": "This is a frozen-pose diagnostic. If it fails, the next authoring pass may change only the thumb chain and must reverse/create the rendered opposition sign without changing the proven v65-B wrist/palm/vessel/four-finger grasp. If the thumb is clipped, camera-space placement must be considered before any extra curl.",
    }
    report_path.write_text(json.dumps(report, indent=2, sort_keys=True), encoding="utf-8")
    print(json.dumps(report, indent=2, sort_keys=True))
    print(SUCCESS)


if __name__ == "__main__":
    try:
        run()
    except BaseException as exc:
        print("MPFB_DIGIT_OPPOSITION_V71B_ERROR:", exc)
        traceback.print_exc()
        raise
