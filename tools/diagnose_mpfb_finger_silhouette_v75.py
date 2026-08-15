#!/usr/bin/env python3
"""v75: diagnose non-thumb finger enclosure in the exact v74 screen-space grasp.

v74 made the thumb digit independently visible, but visual review still reads the whole hand as
"fist + extended thumb" rather than a natural vessel wrap.  Do not change another pose parameter
until the four frozen non-thumb chains are visible as separate evidence.  This script reconstructs
the exact v74 pose, colors index/middle/ring/pinky by dominant skin influence, renders vessel and
unobstructed views, and records projected per-digit bboxes against the vessel contour.

Diagnostic only: no finger authoring, CCD, endpoint optimization, contact servo, angle sweep,
root motion, camera change, or production integration.
"""
from __future__ import annotations
import importlib.util, json, sys, traceback
from pathlib import Path
import bpy
from mathutils import Vector

BASE = Path(__file__).resolve().parent


def _load(name: str, file: str):
    spec = importlib.util.spec_from_file_location(name, BASE / file)
    if spec is None or spec.loader is None:
        raise RuntimeError("could not load " + file)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


v74 = _load("mpfb_v74_for_v75", "author_mpfb_thumb_distal_screen_v74.py")
v73 = v74.v73
v71 = v73.v71
v65 = v74.v65
v64 = v65.v64
v64b = v65.v64b
v68 = v74.v68

SUCCESS = "MPFB_FINGER_SILHOUETTE_V75_SUCCESS"
WIDTH = 192
HEIGHT = 108
DIGITS = {
    "index": ("finger2-1.R", "finger2-2.R", "finger2-3.R"),
    "middle": ("finger3-1.R", "finger3-2.R", "finger3-3.R"),
    "ring": ("finger4-1.R", "finger4-2.R", "finger4-3.R"),
    "pinky": ("finger5-1.R", "finger5-2.R", "finger5-3.R"),
}
COLORS = {
    "index": (0.15, 0.92, 0.28),
    "middle": (0.15, 0.48, 1.00),
    "ring": (1.00, 0.48, 0.08),
    "pinky": (0.90, 0.12, 0.78),
}


def _args():
    if "--" not in sys.argv:
        raise RuntimeError("expected -- <extension-module> <outdir> <report.json>")
    vals = sys.argv[sys.argv.index("--") + 1 :]
    if len(vals) != 3:
        raise RuntimeError("expected three arguments")
    return vals[0], Path(vals[1]).resolve(), Path(vals[2]).resolve()


def _weights(obj):
    names = [name for bones in DIGITS.values() for name in bones]
    ids = {name: obj.vertex_groups[name].index for name in names if obj.vertex_groups.get(name)}
    if len(ids) != len(names):
        missing = [name for name in names if name not in ids]
        raise RuntimeError("missing finger vertex groups: " + ",".join(missing))
    reverse = {idx: name for name, idx in ids.items()}
    out = {name: [0.0] * len(obj.data.vertices) for name in names}
    for vertex in obj.data.vertices:
        for entry in vertex.groups:
            name = reverse.get(entry.group)
            if name:
                out[name][vertex.index] = float(entry.weight)
    return out


def _digit_score(weights, digit, vertex_index):
    return max(weights[name][vertex_index] for name in DIGITS[digit])


def _assign_digit_materials(obj, weights):
    mats = [v73._mat("FingerIDBaseV75", (0.66, 0.66, 0.68))]
    order = list(DIGITS)
    for digit in order:
        mats.append(v73._mat("FingerID_" + digit + "_V75", COLORS[digit], 0.65))
    obj.data.materials.clear()
    for mat in mats:
        obj.data.materials.append(mat)
    marked = {digit: 0 for digit in order}
    for poly in obj.data.polygons:
        scores = [max(_digit_score(weights, digit, i) for i in poly.vertices) for digit in order]
        best = max(range(len(order)), key=lambda i: scores[i])
        if scores[best] >= 0.30:
            obj.data.polygons[poly.index].material_index = best + 1
            marked[order[best]] += 1
        else:
            obj.data.polygons[poly.index].material_index = 0
    return marked


def _screen_metrics(scene, cam, obj, weights, vessel_x):
    out = {}
    for digit, bones in DIGITS.items():
        indices = [
            i
            for i in range(len(obj.data.vertices))
            if max(weights[name][i] for name in bones) >= 0.50
        ]
        points = [obj.matrix_world @ obj.data.vertices[i].co for i in indices]
        bbox = v71._pixel_bbox(scene, cam, points)
        projected = [v71._project(scene, cam, point)["px_top_left"] for point in points]
        xs = [float(p[0]) for p in projected]
        inside = [x for x in xs if vessel_x[0] <= x <= vessel_x[1]]
        out[digit] = {
            "high_weight_vertex_count": len(indices),
            "bbox": bbox,
            "left_outside_px": max(0.0, vessel_x[0] - bbox["min"][0]),
            "right_outside_px": max(0.0, bbox["max"][0] - vessel_x[1]),
            "inside_vessel_x_fraction": float(len(inside)) / float(max(1, len(xs))),
            "center_x_px": float(bbox["center_px"][0]),
        }
    return out


def run():
    ext, out, report_path = _args()
    out.mkdir(parents=True, exist_ok=True)
    report_path.parent.mkdir(parents=True, exist_ok=True)

    v65._reset()
    mpfb, HumanService = v65._services(ext)
    base = HumanService.create_human(
        mask_helpers=True,
        detailed_helpers=False,
        extra_vertex_groups=True,
        feet_on_ground=False,
        scale=0.1,
        macro_detail_dict=None,
    )
    arm = HumanService.add_builtin_rig(base, "default", import_weights=True, operator=None)
    vessel_center, vessel_radius, palm_center, longitudinal, span, palmar = v65._author_power_grasp(arm, -1.0)
    bpy.context.view_layer.update()

    segments = v64._selected_segments(arm)
    finger_weights = _weights(base)
    thumb_weights = v73._bone_weights(base)
    focus = palm_center.lerp(vessel_center, 0.55)
    cam = v65._scene_camera(focus, longitudinal, span, palmar, "B75")
    scene = bpy.context.scene

    metric_base = v73._static(base)
    baseline = v73._metrics(
        scene, cam, metric_base, thumb_weights, vessel_center, vessel_radius, longitudinal, focus
    )
    bpy.data.objects.remove(metric_base, do_unlink=True)

    # Reconstruct the exact one-shot v74 distal-thumb authoring while leaving digits 2-5 untouched.
    tip = v65._wp(arm, "finger1-3.R", True)
    cam_right = cam.matrix_world.to_quaternion() @ Vector((1, 0, 0))
    p0 = v71._project(scene, cam, tip)["px_top_left"][0]
    p1 = v71._project(scene, cam, tip + cam_right * 0.01)["px_top_left"][0]
    if p1 < p0:
        cam_right = -cam_right
        p1 = v71._project(scene, cam, tip + cam_right * 0.01)["px_top_left"][0]
    px_per_m = (p1 - p0) / 0.01
    radius_px = baseline["vessel_diameter_px"] * 0.5
    current_tip_x = v71._project(scene, cam, tip)["px_top_left"][0]
    target_tip_x = baseline["vessel_x_px"][1] + 0.16 * radius_px
    needed_px = max(0.0, target_tip_x - current_tip_x)
    lateral = needed_px / max(px_per_m, 1e-6)
    cam_down = -(cam.matrix_world.to_quaternion() @ Vector((0, 1, 0)))
    for name, fraction, down_fraction in (
        ("finger1-2.R", 0.58, 0.04),
        ("finger1-3.R", 1.00, 0.08),
    ):
        current = v65._wp(arm, name, True)
        v68._aim_pose_bone_world(
            arm,
            name,
            current + cam_right * (lateral * fraction) + cam_down * (lateral * down_fraction),
        )
    bpy.context.view_layer.update()

    baked = v73._static(base)
    marked = _assign_digit_materials(baked, finger_weights)
    v64b._adaptive_crop(baked, segments, palm_center)
    vessel = v65._vessel(vessel_center, longitudinal, vessel_radius, "B75")
    base.hide_render = True
    arm.hide_render = True
    baked.hide_render = False
    vessel.hide_render = False

    with_vessel = out / "finger-id-with-vessel.png"
    thumbnail = out / "finger-id-thumbnail.png"
    v65._render(with_vessel, 640, 640)
    v65._render(thumbnail, WIDTH, HEIGHT)

    vessel.hide_render = True
    anatomy = out / "finger-id-anatomy-oblique.png"
    anatomy_thumb = out / "finger-id-anatomy-thumbnail.png"
    v65._render(anatomy, 640, 640)
    v65._render(anatomy_thumb, WIDTH, HEIGHT)

    metric_candidate = v73._static(base)
    screen = _screen_metrics(scene, cam, metric_candidate, finger_weights, baseline["vessel_x_px"])
    thumb_after = v73._metrics(
        scene, cam, metric_candidate, thumb_weights, vessel_center, vessel_radius, longitudinal, focus
    )

    report = {
        "diagnostic_only": True,
        "staging_only": True,
        "production_candidate": False,
        "reference_set": ["bar_v1", "market_v1"],
        "base_pose": "exact reconstructed v74 on pristine v65-B",
        "pose_authoring_in_v75": False,
        "thumb_pose_from_v74_frozen": True,
        "digits_2_to_5_changed_from_v65_b": False,
        "parameter_sweep_used": False,
        "ccd_used": False,
        "endpoint_optimizer_used": False,
        "contact_servo_used": False,
        "marked_faces_before_crop": marked,
        "vessel_x_px": baseline["vessel_x_px"],
        "vessel_diameter_px": baseline["vessel_diameter_px"],
        "thumb_distal_outside_vessel_px": thumb_after["bones"]["finger1-3.R"]["outside_vessel_px"],
        "finger_screen_metrics": screen,
        "mpfb_version": list(mpfb.VERSION),
        "interpretation_gate": (
            "At 192x108, use the four digit ID colors plus the vessel-occluded view to decide which "
            "finger chains fail to disappear around the vessel far side. Do not tune another thumb "
            "angle. The next authoring step may change only the specific non-thumb chain(s) shown by "
            "this diagnostic to break the fist-like near-side silhouette."
        ),
    }
    report_path.write_text(json.dumps(report, indent=2, sort_keys=True), encoding="utf-8")
    print(json.dumps(report, indent=2, sort_keys=True))
    print(SUCCESS)


if __name__ == "__main__":
    try:
        run()
    except BaseException as exc:
        print("MPFB_FINGER_SILHOUETTE_V75_ERROR:", exc)
        traceback.print_exc()
        raise
