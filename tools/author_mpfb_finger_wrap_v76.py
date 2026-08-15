#!/usr/bin/env python3
"""v76: author one reference-derived four-finger support wrap on the exact v74 thumb seed.

Checkpoint 32 showed that the visible opposing thumb is no longer the dominant defect. The
remaining Macro/Meso failure is the non-thumb ordering inherited from v65-B: index protrudes to
the camera/right while ring and pinky fan left/down, so the silhouette reads as a compact fist
rather than fingers progressively wrapping around the far side of the vessel.

This script makes exactly one deterministic same-rig candidate. It reconstructs v74, freezes the
wrist/palm and all three thumb bones, then applies an explicit corrective FK pass to digits 2-5:
reduce the v65 lateral MCP fan toward a compact root ordering and add progressively deeper curl
from index -> middle -> ring -> pinky. There is no sweep, CCD, endpoint solve, contact servo,
root/orbit motion, camera change, or Micro/material optimization. Visual acceptance remains the
192x108 Macro enclosure first, then unobstructed Meso anatomy.
"""
from __future__ import annotations

import importlib.util
import json
import math
import sys
import traceback
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


v75 = _load("mpfb_v75_for_v76", "diagnose_mpfb_finger_silhouette_v75.py")
v74 = v75.v74
v73 = v75.v73
v71 = v75.v71
v65 = v75.v65
v64 = v75.v64
v64b = v75.v64b
v68 = v75.v68

SUCCESS = "MPFB_FINGER_WRAP_V76_SUCCESS"
WIDTH = 192
HEIGHT = 108

# One authored correction only. The first number counteracts most of v65's MCP lateral fan;
# the remaining three numbers deepen the already-authored MCP/PIP/DIP wrap progressively.
CORRECTION_DEGREES = {
    2: {"fan": +5.0, "curl": (3.0, 5.0, 3.0)},
    3: {"fan": +2.0, "curl": (5.0, 8.0, 5.0)},
    4: {"fan": -4.0, "curl": (8.0, 12.0, 7.0)},
    5: {"fan": -8.0, "curl": (10.0, 14.0, 8.0)},
}


def _args():
    if "--" not in sys.argv:
        raise RuntimeError("expected -- <extension-module> <outdir> <report.json>")
    vals = sys.argv[sys.argv.index("--") + 1 :]
    if len(vals) != 3:
        raise RuntimeError("expected three arguments")
    return vals[0], Path(vals[1]).resolve(), Path(vals[2]).resolve()


def _flat(pb):
    return [float(pb.matrix_basis[r][c]) for r in range(4) for c in range(4)]


def _max_delta(before, after):
    return max(abs(a - b) for a, b in zip(before, after))


def _reconstruct_v74(base, arm, scene, cam, vessel_center, vessel_radius, longitudinal, focus, thumb_weights):
    metric_base = v73._static(base)
    baseline = v73._metrics(
        scene, cam, metric_base, thumb_weights, vessel_center, vessel_radius, longitudinal, focus
    )
    bpy.data.objects.remove(metric_base, do_unlink=True)

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
    lateral = max(0.0, target_tip_x - current_tip_x) / max(px_per_m, 1e-6)
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
    return baseline


def _author_non_thumb_wrap(arm, vessel_center, palmar):
    for digit in range(2, 6):
        cfg = CORRECTION_DEGREES[digit]
        mcp = f"finger{digit}-1.R"
        v65._rotate_pose_bone_world(arm, mcp, palmar, math.radians(cfg["fan"]))
        for joint, extra in enumerate(cfg["curl"], start=1):
            name = f"finger{digit}-{joint}.R"
            axis = v65._choose_curl_axis(arm, name, palmar, vessel_center)
            v65._rotate_pose_bone_world(arm, name, axis, math.radians(extra))
    bpy.context.view_layer.update()


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
    if base is None or base.type != "MESH":
        raise RuntimeError("MPFB human creation failed")
    arm = HumanService.add_builtin_rig(base, "default", import_weights=True, operator=None)
    if arm is None or arm.type != "ARMATURE":
        raise RuntimeError("MPFB canonical rig creation failed")

    vessel_center, vessel_radius, palm_center, longitudinal, span, palmar = v65._author_power_grasp(arm, -1.0)
    bpy.context.view_layer.update()
    segments = v64._selected_segments(arm)
    finger_weights = v75._weights(base)
    thumb_weights = v73._bone_weights(base)
    focus = palm_center.lerp(vessel_center, 0.55)
    cam = v65._scene_camera(focus, longitudinal, span, palmar, "B76")
    scene = bpy.context.scene

    baseline = _reconstruct_v74(
        base, arm, scene, cam, vessel_center, vessel_radius, longitudinal, focus, thumb_weights
    )

    frozen_names = ["wrist.R", "finger1-1.R", "finger1-2.R", "finger1-3.R"]
    frozen_before = {name: _flat(arm.pose.bones[name]) for name in frozen_names}
    before_mesh = v73._static(base)
    before_screen = v75._screen_metrics(
        scene, cam, before_mesh, finger_weights, baseline["vessel_x_px"]
    )
    bpy.data.objects.remove(before_mesh, do_unlink=True)

    _author_non_thumb_wrap(arm, vessel_center, palmar)

    frozen_after = {name: _flat(arm.pose.bones[name]) for name in frozen_names}
    frozen_delta = max(
        _max_delta(frozen_before[name], frozen_after[name]) for name in frozen_names
    )
    pose_path = out / "support-wrap-v76-canonical-pose.json"
    v68._save_same_rig_pose(arm, pose_path)

    candidate_metric = v73._static(base)
    after_screen = v75._screen_metrics(
        scene, cam, candidate_metric, finger_weights, baseline["vessel_x_px"]
    )
    thumb_after = v73._metrics(
        scene, cam, candidate_metric, thumb_weights, vessel_center, vessel_radius, longitudinal, focus
    )

    baked = v73._static(base)
    v64b._adaptive_crop(baked, segments, palm_center)
    v65._skin(baked, "B76")
    vessel = v65._vessel(vessel_center, longitudinal, vessel_radius, "B76")
    base.hide_render = True
    arm.hide_render = True
    candidate_metric.hide_render = True
    baked.hide_render = False
    vessel.hide_render = False

    full = out / "support-wrap-with-vessel.png"
    thumb = out / "support-wrap-thumbnail.png"
    v65._render(full, 640, 640)
    v65._render(thumb, WIDTH, HEIGHT)

    vessel.hide_render = True
    anatomy = out / "support-wrap-anatomy-oblique.png"
    anatomy_thumb = out / "support-wrap-anatomy-thumbnail.png"
    v65._render(anatomy, 640, 640)
    v65._render(anatomy_thumb, WIDTH, HEIGHT)

    report = {
        "staging_only": True,
        "production_candidate": False,
        "reference_set": ["bar_v1", "market_v1"],
        "base_pose": "exact reconstructed v74 on pristine v65-B",
        "single_reference_derived_candidate": True,
        "thumb_pose_from_v74_frozen": True,
        "wrist_frozen": True,
        "parameter_sweep_used": False,
        "ccd_used": False,
        "endpoint_optimizer_used": False,
        "contact_servo_used": False,
        "root_orbit_motion_used": False,
        "camera_changed_from_v75": False,
        "frozen_matrix_max_abs_delta": frozen_delta,
        "correction_degrees": CORRECTION_DEGREES,
        "before_finger_screen_metrics": before_screen,
        "after_finger_screen_metrics": after_screen,
        "vessel_x_px": baseline["vessel_x_px"],
        "vessel_diameter_px": baseline["vessel_diameter_px"],
        "thumb_distal_outside_vessel_px": thumb_after["bones"]["finger1-3.R"]["outside_vessel_px"],
        "same_rig_pose_path": str(pose_path),
        "mpfb_version": list(mpfb.VERSION),
        "visual_gate": (
            "Macro at 192x108 must immediately read as a relaxed but firm human bottle-support wrap: "
            "thumb visibly opposes the four fingers and the non-thumb digits no longer fan into a fist/clump. "
            "Meso unobstructed view must preserve distinct index-to-pinky ordering, continuous palm/wrist anatomy, "
            "and avoid major self-intersection or sharp kinks. Metrics diagnose only; they cannot pass the pose."
        ),
    }
    report_path.write_text(json.dumps(report, indent=2, sort_keys=True), encoding="utf-8")
    print(json.dumps(report, indent=2, sort_keys=True))
    print(SUCCESS)


if __name__ == "__main__":
    try:
        run()
    except BaseException as exc:
        print("MPFB_FINGER_WRAP_V76_ERROR:", exc)
        traceback.print_exc()
        raise
