#!/usr/bin/env python3
"""Export the one permitted v93 relative-digit-depth support-hand candidate.

Checkpoint 51 explicitly forbids another wrist/palm translation grid, wrist-Y grid, grip
scalar escalation, endpoint solver, contact servo, orbit search, or scale sweep. v93 keeps
the exact v92 whole-hand staging pose and changes only the remaining structural variable:
the four non-thumb digits receive one progressive MCP-level depth fan toward the bottle's
far side in the locked authoring-camera space.

This is deliberately one authored gesture, not an optimizer. Internal PIP/DIP closure is
left untouched; only each proximal digit root is swung as a whole chain. Index receives the
smallest far-depth swing, then middle, ring and pinky progressively more, matching the
locked bar_v1/market_v1 requirement and the previously recorded real water-bottle grasp
ordering. If this does not materially improve the 192x108 opaque Macro silhouette, the
checkpoint stop condition requires abandoning code-authored transform guessing.
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
# Finger numbering on the MPFB canonical/GameEngine hand: 1 thumb, 2 index, 3 middle,
# 4 ring, 5 pinky. These are one fixed reference-derived gesture, not a candidate grid.
DIGIT_FAR_DEPTH_DEGREES = {
    "finger2-1.R": 4.0,
    "finger3-1.R": 8.0,
    "finger4-1.R": 13.0,
    "finger5-1.R": 18.0,
}
DEPTH_EPSILON_METERS = 0.00025


def _world_point(arm, bone_name: str, tail: bool = False) -> Vector:
    pb = arm.pose.bones.get(bone_name)
    if pb is None:
        raise RuntimeError("missing authored digit bone " + bone_name)
    return arm.matrix_world @ (pb.tail if tail else pb.head)


def _distal_tip_world(arm, digit: int) -> Vector:
    return _world_point(arm, f"finger{digit}-3.R", True)


def _far_depths(arm, vessel_center: Vector, far_dir: Vector) -> dict[str, float]:
    return {
        str(d): float((_distal_tip_world(arm, d) - vessel_center).dot(far_dir))
        for d in range(2, 6)
    }


def _rotate_proximal_toward_far_side(arm, bone_name: str, far_dir_world: Vector, degrees: float) -> None:
    """Swing one complete digit subtree toward camera-space far depth at its MCP root.

    The rotation axis is derived only from the current proximal direction and locked camera
    far direction. No target point, endpoint distance, iterative solve, or candidate search is
    used. Assigning the proximal pose matrix carries its child PIP/DIP chain rigidly while
    preserving the already-authored semantic closure within that chain.
    """
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

    inv_rot = arm.matrix_world.inverted().to_3x3()
    axis_arm = inv_rot @ axis_world
    if axis_arm.length_squared < 1e-12:
        raise RuntimeError("degenerate armature-space depth axis " + bone_name)
    axis_arm.normalize()

    # Check the sign with a tiny virtual rotation so the chosen direction always increases
    # far-side camera depth rather than relying on opaque MPFB local-axis conventions.
    head_arm = pb.head.copy()
    current_matrix = pb.matrix.copy()
    probe = Matrix.Translation(head_arm) @ Matrix.Rotation(math.radians(1.0), 4, axis_arm) @ Matrix.Translation(-head_arm) @ current_matrix
    original = pb.matrix.copy()
    pb.matrix = probe
    bpy.context.view_layer.update()
    probe_tail = arm.matrix_world @ pb.tail
    probe_gain = (probe_tail - tail_world).dot(far_dir_world)
    pb.matrix = original
    bpy.context.view_layer.update()
    if probe_gain < 0.0:
        axis_arm.negate()

    rotation = Matrix.Translation(head_arm) @ Matrix.Rotation(math.radians(degrees), 4, axis_arm) @ Matrix.Translation(-head_arm)
    pb.matrix = rotation @ current_matrix
    bpy.context.view_layer.update()


def _apply_single_v93_relative_depth_gesture(arm) -> None:
    # First reproduce the exact v92 candidate. That freezes the already-proven side-on limb,
    # v89 crop contract, v90 semantic closure, +12 mm flank placement and +24 degree whole-
    # hand depth turn. v93 then changes only relative digit depth topology.
    v92._apply_single_v92_artist_gesture(arm)

    vessel = bpy.data.objects.get(base.VESSEL)
    camera = bpy.data.objects.get(base.CAMERA)
    if vessel is None or camera is None:
        raise RuntimeError("locked vessel/camera missing for v93 relative-depth authoring")
    vessel_center = vessel.matrix_world.translation.copy()
    far_dir = vessel_center - camera.matrix_world.translation
    if far_dir.length_squared < 1e-12:
        raise RuntimeError("camera coincides with vessel center")
    far_dir.normalize()

    before = _far_depths(arm, vessel_center, far_dir)
    for bone_name, degrees in DIGIT_FAR_DEPTH_DEGREES.items():
        _rotate_proximal_toward_far_side(arm, bone_name, far_dir, degrees)
    after = _far_depths(arm, vessel_center, far_dir)
    deltas = {k: after[k] - before[k] for k in before}

    # Objective structural gate only: prove the single gesture actually creates positive,
    # progressively stronger far-depth displacement. This does NOT declare visual success.
    ordered = [deltas[str(d)] for d in range(2, 6)]
    if any(v <= DEPTH_EPSILON_METERS for v in ordered):
        raise RuntimeError("v93 gesture failed to move every distal digit into far depth: " + repr(deltas))
    if not all(ordered[i] < ordered[i + 1] for i in range(3)):
        raise RuntimeError("v93 far-depth displacement is not progressive index->pinky: " + repr(deltas))

    arm["v93_far_depth_before"] = json.dumps(before, sort_keys=True)
    arm["v93_far_depth_after"] = json.dumps(after, sort_keys=True)
    arm["v93_far_depth_deltas"] = json.dumps(deltas, sort_keys=True)
    bpy.context.view_layer.update()


def main() -> None:
    if "--" not in sys.argv:
        raise RuntimeError("expected -- <output.glb> <report.json>")
    values = sys.argv[sys.argv.index("--") + 1:]
    if len(values) != 2:
        raise RuntimeError("expected two arguments")
    report_path = Path(values[1]).resolve()

    base.WHOLE_HAND_SPATIAL_YAW_DEG = v92.WHOLE_HAND_SPATIAL_YAW_DEG
    base._apply_single_artist_edit = _apply_single_v93_relative_depth_gesture
    base.main()

    report = json.loads(report_path.read_text(encoding="utf-8"))
    arm = bpy.data.objects.get(base.ARM)
    if arm is None:
        # base.main() leaves the authoring rig available; guard against silent contract drift.
        raise RuntimeError("v93 report could not recover authoring rig")
    before = json.loads(arm["v93_far_depth_before"])
    after = json.loads(arm["v93_far_depth_after"])
    deltas = json.loads(arm["v93_far_depth_deltas"])
    report.update({
        "candidate_version": "v93",
        "single_relative_digit_depth_gesture": True,
        "digit_far_depth_degrees": DIGIT_FAR_DEPTH_DEGREES,
        "far_depth_before_meters": before,
        "far_depth_after_meters": after,
        "far_depth_delta_meters": deltas,
        "parameter_sweep_used": False,
        "optimizer_used": False,
        "automatic_retarget_used": False,
        "endpoint_target_used": False,
        "contact_servo_used": False,
        "relative_depth_reason": "one final reference-derived MCP-level whole-chain gesture after v92: preserve each digit's internal semantic closure but progressively swing index, middle, ring and pinky into locked-camera far depth so distal silhouettes can pass behind the bottle rather than stack on its front",
        "stop_condition": "If the same five Godot product-camera frames do not show a material 192x108 Macro enclosure improvement, reject v93 and stop code-authored transform guessing; resume only from a genuinely interactive/artist-authored native-rig pose source.",
        "next_gate": "Exact same Godot bar/market five-frame A/B. Visual Macro is authoritative; structural depth metrics are diagnostic only.",
    })
    report_path.write_text(json.dumps(report, indent=2, sort_keys=True), encoding="utf-8")
    print(json.dumps(report, indent=2, sort_keys=True))
    print(SUCCESS)


if __name__ == "__main__":
    main()
