#!/usr/bin/env python3
"""v72: one-shot screen-space thumb opposition authoring from pristine v65-B.

v71/v71b established the Macro failure with rendered pixels: the thumb is large and mostly
visible, but its centroid (-35.6 px) and the median four-finger mass (-51.1 px) sit on the same
side of the rendered vessel centerline; the thumb also clips the top edge. This script changes
exactly one thing: the canonical thumb chain. Wrist, palm/vessel relationship, four non-thumb
finger chains, crop and camera remain the pristine v65-B baseline.

Unlike earlier world/vessel-axis guesses, v72 derives the authoring gesture from the actual
camera basis. Each thumb phalanx is aimed once toward screen-right and screen-down relative to its
current tail. There is no CCD, endpoint optimizer, parameter sweep, tolerance relaxation or
iterative solver. Acceptance is computed from the same 192x108 render-space opposition metric as
v71b, then checked visually with an unobstructed anatomy ID render.
"""
from __future__ import annotations

import importlib.util
import json
import sys
import traceback
from pathlib import Path

import bpy
from mathutils import Matrix, Vector

BASE = Path(__file__).resolve().parent


def _load(name: str, filename: str):
    spec = importlib.util.spec_from_file_location(name, BASE / filename)
    if spec is None or spec.loader is None:
        raise RuntimeError("could not load " + filename)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


v65 = _load("mpfb_v65_for_v72", "author_mpfb_reference_grasp_v65.py")
v68 = _load("mpfb_v68_for_v72", "author_mpfb_thumb_chain_v68.py")
v71b = _load("mpfb_v71b_for_v72", "diagnose_mpfb_digit_opposition_v71b.py")
v64 = v65.v64
v64b = v65.v64b

SUCCESS = "MPFB_SCREEN_OPPOSITION_V72_SUCCESS"
THUMB = ["finger1-1.R", "finger1-2.R", "finger1-3.R"]
FROZEN = ["wrist.R"] + [f"finger{d}-{j}.R" for d in range(2, 6) for j in range(1, 4)]
ALL_POSE_BONES = ["wrist.R"] + [f"finger{d}-{j}.R" for d in range(1, 6) for j in range(1, 4)]
W, H = 192, 108


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


def _flat(m: Matrix):
    return [float(m[r][c]) for r in range(4) for c in range(4)]


def _snapshot(arm, names):
    missing = [name for name in names if arm.pose.bones.get(name) is None]
    if missing:
        raise RuntimeError("missing pose bones: " + str(missing))
    return {name: _flat(arm.pose.bones[name].matrix_basis.copy()) for name in names}


def _max_delta(before, after):
    return max(abs(a-b) for name in before for a, b in zip(before[name], after[name])) if before else 0.0


def _save_pose(arm, path: Path, report_stub: dict):
    payload = {
        "format": "peel-calm-mpfb-canonical-support-pose-v2",
        "rig": "mpfb-default-canonical",
        "side": "right",
        "label": "v72 one-shot render-space opposing-thumb staging pose",
        "production_candidate": False,
        "provenance": {
            "base": "pristine v65-B",
            "authoring": "single camera-basis thumb-chain gesture derived from v71b render-space failure",
            "ccd": False,
            "endpoint_optimizer": False,
            "parameter_sweep": False,
            "iterative_solver": False,
        },
        "screen_gate_summary": report_stub,
        "bones": {name: {"matrix_basis": _flat(arm.pose.bones[name].matrix_basis)} for name in ALL_POSE_BONES},
    }
    path.write_text(json.dumps(payload, indent=2, sort_keys=True), encoding="utf-8")


def _camera_basis(cam):
    q = cam.matrix_world.to_quaternion()
    right = (q @ Vector((1.0, 0.0, 0.0))).normalized()
    up = (q @ Vector((0.0, 1.0, 0.0))).normalized()
    forward = (q @ Vector((0.0, 0.0, -1.0))).normalized()
    return right, up, forward


def _author_thumb_once(arm, cam):
    right, up, forward = _camera_basis(cam)
    # Deliberately large single gesture because v71b requires crossing ~36 px plus a >=4 px
    # positive clearance. Offsets shrink distally to preserve a continuous anatomical arc.
    offsets = {
        "finger1-1.R": (0.052, -0.020, 0.004),
        "finger1-2.R": (0.044, -0.023, 0.002),
        "finger1-3.R": (0.036, -0.026, 0.000),
    }
    applied = {}
    for name in THUMB:
        tail = v65._wp(arm, name, True)
        dx, dy, dz = offsets[name]
        target = tail + right * dx + up * dy + forward * dz
        v68._aim_pose_bone_world(arm, name, target)
        bpy.context.view_layer.update()
        applied[name] = {
            "offset_camera_m": [dx, dy, dz],
            "target_world": [float(x) for x in target],
        }
    return applied


def _build_id_mesh(basemesh, arm, palm_center):
    rows = v71b._digit_weights(basemesh)
    states = v71b._disable_non_armature_modifiers(basemesh)
    try:
        diagnostic = v71b._evaluated_mesh_object(basemesh, "ScreenOppositionMeshV72")
        v71b._assign_digit_materials(diagnostic, rows)
    finally:
        v71b._restore_modifiers(states)
    segments = v64._selected_segments(arm)
    v64b._adaptive_crop(diagnostic, segments, palm_center)
    return diagnostic


def _evaluate(image_path: Path):
    coords, masks = v71b._masks(image_path)
    line = v71b._fit_vessel_centerline(coords["vessel"])
    signed = {}
    for name in v71b.DIGITS:
        centroid = masks[name]["centroid_px"]
        signed[name] = None if centroid is None else v71b._signed_side(centroid, line)
    finger_sides = [signed[name] for name in ("index", "middle", "ring", "pinky") if signed[name] is not None]
    if len(finger_sides) < 3 or signed["thumb"] is None:
        raise RuntimeError("insufficient rendered IDs for v72 opposition gate")
    import statistics
    median_fingers = float(statistics.median(finger_sides))
    thumb_side = float(signed["thumb"])
    opposite = thumb_side * median_fingers < 0.0
    gate = bool(opposite and abs(thumb_side) >= 4.0 and abs(median_fingers) >= 4.0 and not masks["thumb"]["touches_top"])
    return {
        "masks": masks,
        "vessel_centerline": line,
        "digit_signed_side_px": signed,
        "median_four_finger_side_px": median_fingers,
        "thumb_side_px": thumb_side,
        "thumb_and_fingers_have_opposite_sign": opposite,
        "screen_space_opposition_gate": {
            "min_side_clearance_px": 4.0,
            "thumb_must_not_touch_top_frame": True,
            "pass": gate,
        },
    }


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

    # Pristine v65-B is the frozen baseline.
    vessel_center, vessel_radius, palm_center, longitudinal, span, palmar = v65._author_power_grasp(arm, -1.0)
    frozen_before = _snapshot(arm, FROZEN)
    thumb_before = _snapshot(arm, THUMB)

    focus = palm_center.lerp(vessel_center, 0.55)
    cam = v71b._camera(focus, longitudinal, span, palmar)
    authoring = _author_thumb_once(arm, cam)

    frozen_after = _snapshot(arm, FROZEN)
    thumb_after = _snapshot(arm, THUMB)
    frozen_delta = _max_delta(frozen_before, frozen_after)
    thumb_delta = _max_delta(thumb_before, thumb_after)
    if frozen_delta > 1e-8:
        raise RuntimeError(f"v72 changed frozen wrist/four-finger matrices: {frozen_delta}")
    if thumb_delta <= 1e-5:
        raise RuntimeError("v72 thumb authoring produced no material matrix change")

    diagnostic = _build_id_mesh(basemesh, arm, palm_center)
    basemesh.hide_render = True
    arm.hide_render = True
    vessel = v71b._make_vessel(vessel_center, longitudinal, vessel_radius)

    with_vessel = out / "digit-opposition-v72-192x108.png"
    anatomy = out / "digit-opposition-v72-anatomy-192x108.png"
    vessel.hide_render = False
    v71b._render(with_vessel)
    evaluation = _evaluate(with_vessel)
    vessel.hide_render = True
    v71b._render(anatomy)

    pose_path = out / "support-wrap-v72-canonical-pose.json"
    _save_pose(arm, pose_path, {
        "thumb_side_px": evaluation["thumb_side_px"],
        "median_four_finger_side_px": evaluation["median_four_finger_side_px"],
        "pass": evaluation["screen_space_opposition_gate"]["pass"],
    })

    report = {
        "staging_only": True,
        "production_candidate": False,
        "base_pose": "pristine v65-B",
        "reference_set": ["bar_v1", "market_v1"],
        "mpfb_version": list(mpfb.VERSION),
        "one_shot_candidate": True,
        "camera_basis_authoring": True,
        "ccd_used": False,
        "endpoint_optimizer_used": False,
        "parameter_sweep_used": False,
        "iterative_solver_used": False,
        "wrist_changed_from_v65_b": False,
        "non_thumb_fingers_changed_from_v65_b": False,
        "palm_vessel_relationship_changed_from_v65_b": False,
        "camera_changed_from_v65_b": False,
        "crop_changed_from_v65_b": False,
        "frozen_matrix_max_delta": frozen_delta,
        "thumb_matrix_max_delta": thumb_delta,
        "thumb_authoring": authoring,
        "render_space_evaluation": evaluation,
        "pose_asset": str(pose_path),
        "visual_gate": "Pass only if the 192x108 render shows thumb and four-finger mass on opposite vessel sides with >=4 px clearance, thumb is not top-clipped, and the unobstructed anatomy ID render is continuous/non-self-intersecting. A numeric pass still requires visual review before product-camera staging.",
    }
    report_path.write_text(json.dumps(report, indent=2, sort_keys=True), encoding="utf-8")
    print(json.dumps(report, indent=2, sort_keys=True))
    print(SUCCESS)


if __name__ == "__main__":
    try:
        run()
    except BaseException as exc:
        print("MPFB_SCREEN_OPPOSITION_V72_ERROR:", exc)
        traceback.print_exc()
        raise
