#!/usr/bin/env python3
"""v54: per-phalanx geometric flexion planes on top of v53 semantic authoring.

Only one thing changes from v53: finger flexion axes. Each joint derives its own
axis from the current phalanx direction and the resolved palm/vessel-facing normal.
No targets, IK, distance minimization, BVH rotations, local-axis grids or sweeps.
"""
from __future__ import annotations

import importlib.util
import traceback
from pathlib import Path

import bpy
from mathutils import Vector

BASE = Path(__file__).resolve().parent
SPEC = importlib.util.spec_from_file_location("mpfb_anatomical_controls_v53_base", BASE / "author_mpfb_anatomical_controls_v53.py")
if SPEC is None or SPEC.loader is None:
    raise RuntimeError("could not load v53")
v53 = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(v53)


def _joint_flex_axis(arm, bone_name: str, normal: Vector) -> Vector:
    pb = arm.pose.bones.get(bone_name)
    if pb is None:
        raise RuntimeError("missing v54 bone " + bone_name)
    direction = pb.tail - pb.head
    if direction.length < 1e-6:
        raise RuntimeError("zero-length v54 bone " + bone_name)
    direction.normalize()
    axis = direction.cross(normal)
    if axis.length < 1e-6:
        # Degenerate only when a bone already points nearly normal to the palm; use the
        # v53 palm-span semantic axis as a stable fallback rather than guessing XYZ.
        _palm, _forward, span, _normal = v53._local_palm_frame(arm)
        axis = span - direction * span.dot(direction)
    if axis.length < 1e-6:
        raise RuntimeError("degenerate v54 geometric flex axis " + bone_name)
    axis.normalize()
    return axis


def _apply_per_joint_controls(arm, _shared_span: Vector, normal: Vector) -> dict:
    report = {}
    for digit in ("index", "middle", "ring", "pinky"):
        chain = [f"{digit}_01_r", f"{digit}_02_r", f"{digit}_03_r"]
        joint_rows = []
        for bone_name, magnitude in zip(chain, v53.FINGER_PROFILE_DEG[digit]):
            axis = _joint_flex_axis(arm, bone_name, normal)
            sign = v53._flex_sign(arm, bone_name, axis, normal)
            v53._rot_about_joint(arm, bone_name, axis, sign * magnitude)
            joint_rows.append({
                "bone": bone_name,
                "axis": [float(v) for v in axis],
                "sign": sign,
                "degrees": float(magnitude),
            })
        report[digit] = {"semantic": "per-joint phalanx_direction x palm_normal", "joints": joint_rows}
    return report


if __name__ == "__main__":
    try:
        v53._apply_finger_controls = _apply_per_joint_controls
        v53.run()
        print("MPFB_JOINT_PLANE_V54_SUCCESS")
    except BaseException as exc:
        print("MPFB_JOINT_PLANE_V54_ERROR:", exc)
        traceback.print_exc()
        raise
