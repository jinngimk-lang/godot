#!/usr/bin/env python3
"""v53: one semantic anatomical-control support grasp for the MPFB GameEngine hand.

This candidate exists to test the missing authoring layer identified in checkpoint 21.
It does NOT use raw local XYZ Euler guesses, endpoint targets, CCD, surface servo,
world-direction bone alignment, BVH transforms, or `_bend_toward_center`.

Instead it derives a palm-local anatomical frame from the GameEngine rig itself:
  * finger flexion axis = index-to-pinky palm span;
  * flexion sign = whichever direction bends an extended phalanx toward the palm's
    vessel-facing normal after canonical whole-hand placement;
  * MCP/PIP/DIP flexion magnitudes are fixed artist-authored semantic controls;
  * thumb opposition uses a single palm-frame desired direction and bounded fixed
    opposition/curl controls.

The output is staging-only. 192x108 silhouette remains the acceptance gate.
"""
from __future__ import annotations

import importlib.util
import json
import math
import sys
import traceback
from pathlib import Path

import bpy
from mathutils import Matrix, Vector

BASE = Path(__file__).resolve().parent


def _load(name: str, filename: str):
    spec = importlib.util.spec_from_file_location(name, BASE / filename)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"could not load {filename}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


v19 = _load("mpfb_v19_for_v53", "render_mpfb_retarget_preview_v19.py")
v23 = _load("mpfb_v23_for_v53", "render_mpfb_contact_ik_v23.py")
v35 = _load("mpfb_v35_for_v53", "render_mpfb_canonical_grip_v35.py")
v49 = _load("mpfb_manual_pose_v49_for_v53", "manual_pose_asset_v49.py")

FINGER_PROFILE_DEG = {
    "index": (38.0, 50.0, 30.0),
    "middle": (37.0, 49.0, 32.0),
    "ring": (35.0, 47.0, 34.0),
    "pinky": (32.0, 44.0, 35.0),
}
THUMB_OPPOSITION_DEG = 44.0
THUMB_CURL_DEG = (28.0, 22.0)


def _args():
    if "--" not in sys.argv:
        raise RuntimeError("expected -- <xr.glb> <mpfb.glb> <outdir> <pose.json> <report.json>")
    values = sys.argv[sys.argv.index("--") + 1:]
    if len(values) != 5:
        raise RuntimeError("expected five arguments")
    return tuple(Path(v).resolve() for v in values)


def _local_palm_frame(arm):
    wrist = arm.pose.bones["hand_r"].head.copy()
    mcps = [arm.pose.bones[f"{digit}_01_r"].head.copy() for digit in ("index", "middle", "ring", "pinky")]
    palm = (wrist + sum(mcps, Vector())) / 5.0
    forward = (sum(mcps, Vector()) / 4.0) - wrist
    span = mcps[-1] - mcps[0]
    if forward.length < 1e-6 or span.length < 1e-6:
        raise RuntimeError("degenerate v53 palm frame")
    forward.normalize()
    span.normalize()
    normal = forward.cross(span)
    if normal.length < 1e-6:
        raise RuntimeError("degenerate v53 palm normal")
    normal.normalize()
    return palm, forward, span, normal


def _camera_target_preserving_pose(arm) -> Vector:
    """Return the legacy neutral-target framing point without mutating the pose.

    ``v22._neutral_targets`` begins by calling ``v19._clear``. v55/v56 invoked it after
    restoring the durable 17-bone artist pose, so every supposedly authored preview was
    silently reset to the baseline immediately before rendering. The camera only needs the
    geometric focus point, therefore compute the same palm->mean-fingertips landmark directly
    from the current staged rig and never touch pose state.
    """
    palm = v19._wp(arm, "hand_r")
    finger_tips = [
        v19._wp(arm, f"{name}_03_r", True)
        for name in ("index", "middle", "ring", "pinky")
    ]
    mean_tips = sum(finger_tips, Vector()) / len(finger_tips)
    return palm.lerp(mean_tips, 0.45)


def _rot_about_joint(arm, bone_name: str, axis_local: Vector, degrees: float) -> None:
    pb = arm.pose.bones.get(bone_name)
    if pb is None:
        raise RuntimeError("missing v53 bone " + bone_name)
    axis = axis_local.normalized()
    head = pb.head.copy()
    rot = Matrix.Rotation(math.radians(degrees), 4, axis)
    pb.matrix = Matrix.Translation(head) @ rot @ Matrix.Translation(-head) @ pb.matrix
    bpy.context.view_layer.update()


def _flex_sign(arm, bone_name: str, axis_local: Vector, vessel_normal_local: Vector) -> float:
    pb = arm.pose.bones[bone_name]
    direction = pb.tail - pb.head
    if direction.length < 1e-6:
        raise RuntimeError("zero-length v53 bone " + bone_name)
    direction.normalize()
    probe = math.radians(5.0)
    pos = Matrix.Rotation(probe, 3, axis_local.normalized()) @ direction
    neg = Matrix.Rotation(-probe, 3, axis_local.normalized()) @ direction
    return 1.0 if pos.dot(vessel_normal_local) >= neg.dot(vessel_normal_local) else -1.0


def _apply_finger_controls(arm, span: Vector, normal: Vector) -> dict:
    report = {}
    for digit in ("index", "middle", "ring", "pinky"):
        chain = [f"{digit}_01_r", f"{digit}_02_r", f"{digit}_03_r"]
        sign = _flex_sign(arm, chain[0], span, normal)
        for bone_name, magnitude in zip(chain, FINGER_PROFILE_DEG[digit]):
            _rot_about_joint(arm, bone_name, span, sign * magnitude)
        report[digit] = {"flex_axis": [float(v) for v in span], "sign": sign, "degrees": list(FINGER_PROFILE_DEG[digit])}
    return report


def _apply_thumb_controls(arm, forward: Vector, span: Vector, normal: Vector) -> dict:
    base = arm.pose.bones["thumb_01_r"]
    current = base.tail - base.head
    current.normalize()
    desired = normal * 0.68 - forward * 0.66 - span * 0.20
    desired.normalize()
    opposition_axis = current.cross(desired)
    if opposition_axis.length < 1e-6:
        opposition_axis = span.copy()
    opposition_axis.normalize()
    probe = math.radians(THUMB_OPPOSITION_DEG)
    pos = Matrix.Rotation(probe, 3, opposition_axis) @ current
    neg = Matrix.Rotation(-probe, 3, opposition_axis) @ current
    sign = 1.0 if pos.dot(desired) >= neg.dot(desired) else -1.0
    _rot_about_joint(arm, "thumb_01_r", opposition_axis, sign * THUMB_OPPOSITION_DEG)

    curl_sign = _flex_sign(arm, "thumb_02_r", span, normal)
    _rot_about_joint(arm, "thumb_02_r", span, curl_sign * THUMB_CURL_DEG[0])
    _rot_about_joint(arm, "thumb_03_r", span, curl_sign * THUMB_CURL_DEG[1])
    return {
        "opposition_axis": [float(v) for v in opposition_axis],
        "opposition_sign": sign,
        "opposition_deg": THUMB_OPPOSITION_DEG,
        "curl_axis": [float(v) for v in span],
        "curl_sign": curl_sign,
        "curl_deg": list(THUMB_CURL_DEG),
    }


def _proxy(center: Vector, axis: Vector):
    return v35.v33._proxy(center, axis, "AnatomicalControlsV53Vessel")


def _render_thumbnail(cam, out: Path, focus: Vector) -> None:
    scene = bpy.context.scene
    old = (scene.render.resolution_x, scene.render.resolution_y, scene.render.resolution_percentage)
    scene.render.resolution_x = 192
    scene.render.resolution_y = 108
    scene.render.resolution_percentage = 100
    try:
        v19._render(cam, out, "anatomical_controls_v53_thumbnail", focus)
    finally:
        scene.render.resolution_x, scene.render.resolution_y, scene.render.resolution_percentage = old


def _matrix_error(a: Matrix, b: Matrix) -> float:
    return max(abs(a[r][c] - b[r][c]) for r in range(4) for c in range(4))


def run() -> None:
    xr_path, mpfb_path, out, pose_path, report_path = _args()
    out.mkdir(parents=True, exist_ok=True)
    pose_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.parent.mkdir(parents=True, exist_ok=True)

    v19._reset()
    xr, xr_meshes = v19._import_armature(xr_path, "XR")
    for mesh in xr_meshes:
        mesh.hide_render = True
        mesh.hide_viewport = True
    arm, meshes = v19._import_armature(mpfb_path, "MPFB")
    cam = v19._setup_render(meshes)

    v19._clear(arm)
    v23._pose_seed(xr, arm, "Cup_Armature")
    center, axis, inward, _ = v35._fixture_from_seed(arm, 1.0)
    proxy = _proxy(center, axis)
    whole_rotation_deg, root_shift = v35._orient_whole_hand(arm, center, axis, inward)

    # Freeze camera framing before authoring. This helper is deliberately side-effect free;
    # unlike v22._neutral_targets it does not clear the pose.
    camera_target = _camera_target_preserving_pose(arm)

    _palm, forward, span, normal = _local_palm_frame(arm)
    world_normal = arm.matrix_world.to_3x3() @ normal
    if world_normal.dot(inward) < 0.0:
        normal *= -1.0
    finger_controls = _apply_finger_controls(arm, span, normal)
    thumb_controls = _apply_thumb_controls(arm, forward, span, normal)

    expected = {name: arm.pose.bones[name].matrix_basis.copy() for name in v49.BONES}
    payload = v49.save_pose(
        arm,
        pose_path,
        label="v53 semantic anatomical-control support-wrap candidate",
        provenance={
            "kind": "semantic-anatomical-controls",
            "production_candidate": False,
            "automatic_retarget": False,
            "retarget_source_transforms_used": False,
            "target_solver_used": False,
            "bend_toward_center_used": False,
            "blind_local_euler_table_used": False,
            "anatomical_frame_source": "GameEngine palm/phalange geometry",
            "visual_reference": "locked Peel Calm references + MakeHuman Poses 01 holding-object close-up as anatomy guide only",
        },
    )

    v49.clear_pose(arm)
    v49.load_pose(arm, pose_path)
    errors = {name: _matrix_error(expected[name], arm.pose.bones[name].matrix_basis) for name in v49.BONES}
    max_reload_error = max(errors.values())
    if max_reload_error > 1e-6:
        raise RuntimeError(f"v53 durable pose reload changed matrices: {max_reload_error}")

    focus = camera_target.lerp(center, 0.55)
    v19._render(cam, out, "anatomical_controls_v53_candidate", focus)
    _render_thumbnail(cam, out, focus)

    report = {
        "staging_only": True,
        "production_candidate": False,
        "automatic_retarget": False,
        "retarget_source_transforms_used": False,
        "target_solver_used": False,
        "bend_toward_center_used": False,
        "blind_local_euler_table_used": False,
        "camera_focus_preserves_pose": True,
        "pose_bone_count": len(payload["bones"]),
        "whole_rotation_deg": whole_rotation_deg,
        "root_shift": root_shift,
        "max_reload_matrix_error": max_reload_error,
        "finger_controls": finger_controls,
        "thumb_controls": thumb_controls,
        "visual_gate": "192x108 must immediately read as human vessel wrap with opposed thumb and fingers progressively disappearing behind far contour.",
    }
    report_path.write_text(json.dumps(report, indent=2, sort_keys=True), encoding="utf-8")
    print(json.dumps(report, indent=2, sort_keys=True))
    print("MPFB_ANATOMICAL_CONTROLS_V53_SUCCESS")
    bpy.data.objects.remove(proxy, do_unlink=True)


if __name__ == "__main__":
    try:
        run()
    except BaseException as exc:
        print("MPFB_ANATOMICAL_CONTROLS_V53_ERROR:", exc)
        traceback.print_exc()
        raise
