#!/usr/bin/env python3
"""v73: decompose thumb opposition into root/proximal/distal rendered segments.

v71b proved all digit families are on the same vessel side. v72 then made one large camera-basis
thumb gesture, but the combined thumb centroid moved only ~4 px and stayed top-clipped. The
combined thumb mask is too coarse for the next decision because a correct opposing thumb may
legitimately keep its root/thenar on the palm side while only the proximal/distal chain crosses the
vessel silhouette.

This diagnostic authors no new candidate. It renders two already-defined states under the exact
same v65 camera/crop/vessel: pristine v65-B and rejected v72. Within the thumb, faces are assigned
to root/proximal/distal IDs from canonical vertex weights. All acceptance measurements come from
192x108 pixels, not bone projection. The result tells the next authoring pass which segment must
cross the vessel centerline instead of asking the whole thumb centroid to cross.
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


def _load(name: str, filename: str):
    spec = importlib.util.spec_from_file_location(name, BASE / filename)
    if spec is None or spec.loader is None:
        raise RuntimeError("could not load " + filename)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


v65 = _load("mpfb_v65_for_v73", "author_mpfb_reference_grasp_v65.py")
v71b = _load("mpfb_v71b_for_v73", "diagnose_mpfb_digit_opposition_v71b.py")
v72 = _load("mpfb_v72_for_v73", "author_mpfb_screen_opposition_v72.py")
v64 = v65.v64
v64b = v65.v64b

SUCCESS = "MPFB_THUMB_SEGMENTS_V73_SUCCESS"
W, H = 192, 108
FACE_WEIGHT = 0.22
SEGMENTS = {
    "thumb_root": "finger1-1.R",
    "thumb_proximal": "finger1-2.R",
    "thumb_distal": "finger1-3.R",
}
COLORS = {
    "hand": (0.18, 0.18, 0.18, 1.0),
    "thumb_root": (1.0, 0.0, 0.55, 1.0),
    "thumb_proximal": (1.0, 0.78, 0.0, 1.0),
    "thumb_distal": (0.05, 1.0, 0.10, 1.0),
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


def _segment_weights(mesh_obj):
    group_names = {g.index: g.name for g in mesh_obj.vertex_groups}
    missing = [bone for bone in SEGMENTS.values() if mesh_obj.vertex_groups.get(bone) is None]
    if missing:
        raise RuntimeError("missing thumb segment groups: " + str(missing))
    rows = []
    for vertex in mesh_obj.data.vertices:
        values = {name: 0.0 for name in SEGMENTS}
        for assignment in vertex.groups:
            group_name = group_names.get(assignment.group)
            for name, bone in SEGMENTS.items():
                if group_name == bone:
                    values[name] += float(assignment.weight)
                    break
        rows.append(values)
    return rows


def _assign_materials(obj, rows):
    order = ["hand", "thumb_root", "thumb_proximal", "thumb_distal"]
    obj.data.materials.clear()
    for name in order:
        obj.data.materials.append(_emission("V73_" + name, COLORS[name]))
    index = {name: i for i, name in enumerate(order)}
    for poly in obj.data.polygons:
        score = {name: max(rows[i][name] for i in poly.vertices) for name in SEGMENTS}
        winner = max(score, key=score.get)
        poly.material_index = index[winner] if score[winner] >= FACE_WEIGHT else index["hand"]


def _classify(r, g, b, a):
    if a < 0.5:
        return None
    if g > 0.55 and b > 0.65 and r < 0.35:
        return "vessel"
    if r > 0.62 and b > 0.42 and g < 0.32:
        return "thumb_root"
    if r > 0.65 and g > 0.48 and b < 0.35:
        return "thumb_proximal"
    if g > 0.62 and r < 0.42 and b < 0.45:
        return "thumb_distal"
    return None


def _masks(path: Path):
    image = bpy.data.images.load(str(path), check_existing=False)
    try:
        width, height = image.size
        pixels = list(image.pixels)
        coords = {name: [] for name in [*SEGMENTS.keys(), "vessel"]}
        for y_bottom in range(height):
            y = height - 1 - y_bottom
            for x in range(width):
                i = (y_bottom * width + x) * 4
                label = _classify(*pixels[i:i+4])
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
    finally:
        bpy.data.images.remove(image)


def _make_vessel(center, axis, radius):
    obj = v71b._make_vessel(center, axis, radius)
    obj.name = "V73VesselID"
    obj.data.materials.clear()
    obj.data.materials.append(_emission("V73_vessel", COLORS["vessel"]))
    return obj


def _state(extension_module: str, out: Path, label: str, apply_v72: bool):
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

    vessel_center, vessel_radius, palm_center, longitudinal, span, palmar = v65._author_power_grasp(arm, -1.0)
    focus = palm_center.lerp(vessel_center, 0.55)
    cam = v71b._camera(focus, longitudinal, span, palmar)
    if apply_v72:
        v72._author_thumb_once(arm, cam)
        bpy.context.view_layer.update()

    rows = _segment_weights(basemesh)
    states = v71b._disable_non_armature_modifiers(basemesh)
    try:
        diagnostic = v71b._evaluated_mesh_object(basemesh, "ThumbSegments_" + label)
        _assign_materials(diagnostic, rows)
    finally:
        v71b._restore_modifiers(states)
    segments = v64._selected_segments(arm)
    v64b._adaptive_crop(diagnostic, segments, palm_center)
    basemesh.hide_render = True
    arm.hide_render = True
    vessel = _make_vessel(vessel_center, longitudinal, vessel_radius)

    with_vessel = out / f"thumb-segments-{label}-192x108.png"
    anatomy = out / f"thumb-segments-{label}-anatomy-192x108.png"
    vessel.hide_render = False
    v71b._render(with_vessel)
    coords, masks = _masks(with_vessel)
    line = v71b._fit_vessel_centerline(coords["vessel"])
    sides = {}
    for name in SEGMENTS:
        centroid = masks[name]["centroid_px"]
        sides[name] = None if centroid is None else v71b._signed_side(centroid, line)
    vessel.hide_render = True
    v71b._render(anatomy)
    return {
        "label": label,
        "v72_thumb_gesture_applied": apply_v72,
        "masks": masks,
        "vessel_centerline": line,
        "segment_signed_side_px": sides,
        "distal_opposition_gate": {
            "min_positive_side_clearance_px": 4.0,
            "distal_must_not_touch_top_frame": True,
            "pass": bool(
                sides["thumb_distal"] is not None
                and sides["thumb_distal"] >= 4.0
                and not masks["thumb_distal"]["touches_top"]
            ),
            "intent": "thumb root may remain on the palm side, but the visible distal segment must cross to the opposite rendered vessel side with readable clearance",
        },
    }, list(mpfb.VERSION)


def run():
    extension_module, out, report_path = _args()
    out.mkdir(parents=True, exist_ok=True)
    report_path.parent.mkdir(parents=True, exist_ok=True)
    baseline, version = _state(extension_module, out, "v65b", False)
    rejected_v72, version2 = _state(extension_module, out, "v72", True)
    if version != version2:
        raise RuntimeError("MPFB version drift between diagnostic states")

    delta = {}
    for name in SEGMENTS:
        a = baseline["segment_signed_side_px"][name]
        b = rejected_v72["segment_signed_side_px"][name]
        delta[name] = None if a is None or b is None else float(b-a)

    report = {
        "diagnostic_only": True,
        "production_candidate": False,
        "new_pose_authored_in_v73": False,
        "reference_set": ["bar_v1", "market_v1"],
        "mpfb_version": version,
        "screen": {"width": W, "height": H},
        "render_space_only": True,
        "bone_projection_used": False,
        "face_weight_threshold": FACE_WEIGHT,
        "states": {
            "pristine_v65_b": baseline,
            "rejected_v72": rejected_v72,
        },
        "v72_minus_v65b_segment_side_delta_px": delta,
        "interpretation": "Use the distal/proximal segment evidence to choose the next abstraction. Do not demand that the whole thumb/root cross the vessel. If v72 mostly moved root/proximal while distal stayed same-side, the next pass must directly author distal-chain silhouette instead of increasing a whole-chain camera offset.",
    }
    report_path.write_text(json.dumps(report, indent=2, sort_keys=True), encoding="utf-8")
    print(json.dumps(report, indent=2, sort_keys=True))
    print(SUCCESS)


if __name__ == "__main__":
    try:
        run()
    except BaseException as exc:
        print("MPFB_THUMB_SEGMENTS_V73_ERROR:", exc)
        traceback.print_exc()
        raise
