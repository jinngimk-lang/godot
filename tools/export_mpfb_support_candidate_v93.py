#!/usr/bin/env python3
"""Export the one permitted v93 relative-digit-depth support-hand candidate.

Checkpoint 51 permits one last code-authored structural candidate before transform guessing
must stop. v93 preserves the exact v92 hand, crop, scale and side-on approach, then swings
only the four non-thumb proximal digit roots progressively into locked-camera far depth.
Internal PIP/DIP closure is untouched. This is one fixed gesture, not a sweep/optimizer.
"""
from __future__ import annotations

import json
import math
import sys
from pathlib import Path

import bpy
from mathutils import Matrix, Vector

TOOLS_DIR = str(Path(__file__).resolve().parent)
if TOOLS_DIR not in sys.path:
    sys.path.insert(0, TOOLS_DIR)
import export_mpfb_support_candidate_v88 as base
import export_mpfb_support_candidate_v92 as v92

SUCCESS = "MPFB_SUPPORT_CANDIDATE_V93_EXPORT_SUCCESS"
DIGIT_FAR_DEPTH_DEGREES = {
    "finger2-1.R": 4.0,
    "finger3-1.R": 8.0,
    "finger4-1.R": 13.0,
    "finger5-1.R": 18.0,
}
DEPTH_EPSILON_METERS = 0.00025


def _wp(arm, name: str, tail: bool = False) -> Vector:
    pb = arm.pose.bones.get(name)
    if pb is None:
        raise RuntimeError("missing authored digit bone " + name)
    return arm.matrix_world @ (pb.tail if tail else pb.head)


def _tip(arm, digit: int) -> Vector:
    return _wp(arm, f"finger{digit}-3.R", True)


def _depths(arm, vessel_center: Vector, far_dir: Vector) -> dict[str, float]:
    return {str(d): float((_tip(arm, d) - vessel_center).dot(far_dir)) for d in range(2, 6)}


def _rotate_digit(arm, digit: int, far_dir_world: Vector, degrees: float) -> None:
    """Swing one complete digit subtree toward far depth at its MCP root.

    A 1-degree response probe chooses only the sign of this fixed artist gesture. The probe
    observes the complete distal chain rather than the proximal tail; this fixes the first
    v93 attempt where MPFB child constraints made ring/pinky distal tips move opposite the
    proximal-tail response. It is not endpoint targeting: no desired point/distance is used.
    """
    bone_name = f"finger{digit}-1.R"
    pb = arm.pose.bones.get(bone_name)
    if pb is None:
        raise RuntimeError("missing proximal bone " + bone_name)

    head_world = arm.matrix_world @ pb.head
    tail_world = arm.matrix_world @ pb.tail
    direction_world = tail_world - head_world
    if direction_world.length_squared < 1e-12:
        raise RuntimeError("degenerate proximal direction " + bone_name)
    direction_world.normalize()

    axis_world = direction_world.cross(far_dir_world)
    if axis_world.length_squared < 1e-10:
        raise RuntimeError("cannot derive far-depth authoring axis for " + bone_name)
    axis_world.normalize()
    axis_arm = arm.matrix_world.inverted().to_3x3() @ axis_world
    if axis_arm.length_squared < 1e-12:
        raise RuntimeError("degenerate armature-space depth axis " + bone_name)
    axis_arm.normalize()

    head_arm = pb.head.copy()
    original = pb.matrix.copy()
    distal_before = _tip(arm, digit)
    probe_rotation = Matrix.Translation(head_arm) @ Matrix.Rotation(math.radians(1.0), 4, axis_arm) @ Matrix.Translation(-head_arm)
    pb.matrix = probe_rotation @ original
    bpy.context.view_layer.update()
    probe_gain = (_tip(arm, digit) - distal_before).dot(far_dir_world)
    pb.matrix = original
    bpy.context.view_layer.update()
    if probe_gain < 0.0:
        axis_arm.negate()

    rotation = Matrix.Translation(head_arm) @ Matrix.Rotation(math.radians(degrees), 4, axis_arm) @ Matrix.Translation(-head_arm)
    pb.matrix = rotation @ original
    bpy.context.view_layer.update()


def _apply_v93(arm) -> None:
    v92._apply_single_v92_artist_gesture(arm)
    vessel = bpy.data.objects.get(base.VESSEL)
    camera = bpy.data.objects.get(base.CAMERA)
    if vessel is None or camera is None:
        raise RuntimeError("locked vessel/camera missing for v93")
    vessel_center = vessel.matrix_world.translation.copy()
    far_dir = vessel_center - camera.matrix_world.translation
    if far_dir.length_squared < 1e-12:
        raise RuntimeError("camera coincides with vessel center")
    far_dir.normalize()

    before = _depths(arm, vessel_center, far_dir)
    for digit, degrees in zip(range(2, 6), DIGIT_FAR_DEPTH_DEGREES.values()):
        _rotate_digit(arm, digit, far_dir, degrees)
    after = _depths(arm, vessel_center, far_dir)
    deltas = {k: after[k] - before[k] for k in before}
    ordered = [deltas[str(d)] for d in range(2, 6)]
    if any(v <= DEPTH_EPSILON_METERS for v in ordered):
        raise RuntimeError("v93 gesture failed positive far-depth displacement: " + repr(deltas))
    if not all(ordered[i] < ordered[i + 1] for i in range(3)):
        raise RuntimeError("v93 displacement is not progressive index->pinky: " + repr(deltas))

    arm["v93_far_depth_before"] = json.dumps(before, sort_keys=True)
    arm["v93_far_depth_after"] = json.dumps(after, sort_keys=True)
    arm["v93_far_depth_deltas"] = json.dumps(deltas, sort_keys=True)


def main() -> None:
    if "--" not in sys.argv:
        raise RuntimeError("expected -- <output.glb> <report.json>")
    values = sys.argv[sys.argv.index("--") + 1:]
    if len(values) != 2:
        raise RuntimeError("expected two arguments")
    report_path = Path(values[1]).resolve()

    base.WHOLE_HAND_SPATIAL_YAW_DEG = v92.WHOLE_HAND_SPATIAL_YAW_DEG
    base._apply_single_artist_edit = _apply_v93
    base.main()

    report = json.loads(report_path.read_text(encoding="utf-8"))
    arm = bpy.data.objects.get(base.ARM)
    if arm is None:
        raise RuntimeError("v93 report could not recover authoring rig")
    report.update({
        "candidate_version": "v93",
        "single_relative_digit_depth_gesture": True,
        "digit_far_depth_degrees": DIGIT_FAR_DEPTH_DEGREES,
        "far_depth_before_meters": json.loads(arm["v93_far_depth_before"]),
        "far_depth_after_meters": json.loads(arm["v93_far_depth_after"]),
        "far_depth_delta_meters": json.loads(arm["v93_far_depth_deltas"]),
        "parameter_sweep_used": False,
        "optimizer_used": False,
        "automatic_retarget_used": False,
        "endpoint_target_used": False,
        "contact_servo_used": False,
        "sign_calibration_uses_distal_chain_response_only": True,
        "relative_depth_reason": "one final reference-derived MCP-level whole-chain gesture: preserve v92 internal closure, then progressively move index, middle, ring and pinky into locked-camera far depth",
        "stop_condition": "If the same five Godot product-camera frames do not show a material 192x108 Macro enclosure improvement, reject v93 and stop code-authored transform guessing; resume only from a genuinely interactive/artist-authored native-rig pose source.",
        "next_gate": "Exact same Godot bar/market five-frame A/B. Visual Macro is authoritative; structural depth metrics are diagnostic only.",
    })
    report_path.write_text(json.dumps(report, indent=2, sort_keys=True), encoding="utf-8")
    print(json.dumps(report, indent=2, sort_keys=True))
    print(SUCCESS)


if __name__ == "__main__":
    main()
