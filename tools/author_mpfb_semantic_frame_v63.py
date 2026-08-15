#!/usr/bin/env python3
"""v63: preserve v62 source pose angles but map their axes through coherent anatomy frames.

v62 was the first recent candidate whose thumbnail began to read as a vessel wrap, but its
full render still showed broken/blocky phalanges. This experiment changes only how a source
local rotation axis is related to the target local coordinate system.

For every digit, both rigs derive a stable rest-palm normal from wrist + MCP roots. For every
phalanx, a semantic right-handed frame is built from:
  Y = that phalanx's REST segment direction,
  Z = the shared palm normal projected orthogonal to Y,
  X = Y cross Z.

The source BVH matrix_basis rotation is reduced to axis+angle. Its axis is transformed from
source native bone coordinates into source armature space, expressed in the semantic frame,
reconstructed in the target semantic frame, then converted into the target native bone frame.
The source rotation angle is preserved exactly. No damping grid, curl multiplier, CCD, target
point, surface servo, per-joint bend-plane reconstruction, or source edit-bone roll copy exists.

The script reuses v62's proven fixture, durable v49 pose persistence, camera-focus path and
rest-structure guards. Output remains staging-only and visual-first.
"""
from __future__ import annotations

import importlib.util
import json
import math
import shutil
import sys
import traceback
from pathlib import Path

from mathutils import Quaternion, Vector

BASE = Path(__file__).resolve().parent
SPEC = importlib.util.spec_from_file_location("mpfb_v62_for_v63", BASE / "author_mpfb_rest_delta_v62.py")
if SPEC is None or SPEC.loader is None:
    raise RuntimeError("could not load v62 base")
v62 = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(v62)


def _rest_point(arm, bone_name: str, tail: bool = False) -> Vector:
    bone = arm.data.bones.get(bone_name)
    if bone is None:
        raise RuntimeError("missing rest bone " + bone_name)
    return (bone.tail_local if tail else bone.head_local).copy()


def _palm_normal(arm, source: bool) -> Vector:
    if source:
        wrist_name = "wrist.R"
        roots = ["finger2-1.R", "finger3-1.R", "finger4-1.R", "finger5-1.R"]
    else:
        wrist_name = "hand_r"
        roots = ["index_01_r", "middle_01_r", "ring_01_r", "pinky_01_r"]
    wrist = _rest_point(arm, wrist_name)
    points = [_rest_point(arm, name) for name in roots]
    forward = sum(points, Vector()) / 4.0 - wrist
    span = points[-1] - points[0]
    if forward.length < 1e-8 or span.length < 1e-8:
        raise RuntimeError("degenerate palm frame")
    forward.normalize()
    span = span - forward * span.dot(forward)
    if span.length < 1e-8:
        raise RuntimeError("degenerate palm span")
    span.normalize()
    normal = forward.cross(span)
    if normal.length < 1e-8:
        raise RuntimeError("degenerate palm normal")
    return normal.normalized()


def _semantic_frame(arm, bone_name: str, palm_normal: Vector) -> tuple[Vector, Vector, Vector]:
    y = _rest_point(arm, bone_name, True) - _rest_point(arm, bone_name, False)
    if y.length < 1e-8:
        raise RuntimeError("zero-length rest phalanx " + bone_name)
    y.normalize()
    z = palm_normal - y * palm_normal.dot(y)
    if z.length < 1e-8:
        # Extremely unlikely for a finger, but remain deterministic by using the bone's
        # native rest Z axis only as a fallback; this does not write or copy edit roll.
        bone = arm.data.bones[bone_name]
        z = bone.matrix_local.to_3x3() @ Vector((0.0, 0.0, 1.0))
        z = z - y * z.dot(y)
    if z.length < 1e-8:
        raise RuntimeError("degenerate semantic normal " + bone_name)
    z.normalize()
    x = y.cross(z)
    if x.length < 1e-8:
        raise RuntimeError("degenerate semantic binormal " + bone_name)
    x.normalize()
    z = x.cross(y).normalized()
    return x, y, z


def _native_rest_rotation(arm, bone_name: str) -> Quaternion:
    bone = arm.data.bones.get(bone_name)
    if bone is None:
        raise RuntimeError("missing native rest bone " + bone_name)
    return bone.matrix_local.to_quaternion().normalized()


def _semantic_mapped_delta(source_arm, target_arm, src_name: str, dst_name: str):
    pb = source_arm.pose.bones.get(src_name)
    if pb is None:
        raise RuntimeError("missing source pose bone " + src_name)
    q_src = pb.matrix_basis.to_quaternion().normalized()
    angle = q_src.angle
    if angle < 1e-9:
        mapped = Quaternion((1.0, 0.0, 0.0, 0.0))
        coeff = (0.0, 1.0, 0.0)
        axis_target_local = Vector((0.0, 1.0, 0.0))
    else:
        axis_src_local = q_src.axis.normalized()
        src_native = _native_rest_rotation(source_arm, src_name)
        dst_native = _native_rest_rotation(target_arm, dst_name)
        axis_src_arm = (src_native @ axis_src_local).normalized()

        src_frame = _semantic_frame(source_arm, src_name, _palm_normal(source_arm, True))
        dst_frame = _semantic_frame(target_arm, dst_name, _palm_normal(target_arm, False))
        coeff = tuple(float(axis_src_arm.dot(v)) for v in src_frame)
        axis_target_arm = dst_frame[0] * coeff[0] + dst_frame[1] * coeff[1] + dst_frame[2] * coeff[2]
        if axis_target_arm.length < 1e-8:
            raise RuntimeError("semantic mapped axis collapsed")
        axis_target_arm.normalize()
        axis_target_local = (dst_native.inverted() @ axis_target_arm).normalized()
        mapped = Quaternion(axis_target_local, angle).normalized()

    return mapped, {
        "source": src_name,
        "target": dst_name,
        "source_delta_angle_deg": float(math.degrees(angle)),
        "mapped_delta_angle_deg": float(math.degrees(mapped.angle)),
        "semantic_axis_coefficients": [float(v) for v in coeff],
        "target_local_axis": [float(v) for v in axis_target_local],
    }


def _parsed_paths() -> tuple[Path, Path]:
    if "--" not in sys.argv:
        raise RuntimeError("missing v63 args")
    values = sys.argv[sys.argv.index("--") + 1:]
    if len(values) != 6:
        raise RuntimeError("expected v62-compatible six arguments")
    return Path(values[3]).resolve(), Path(values[5]).resolve()


def run() -> None:
    out, report_path = _parsed_paths()
    v62._mapped_delta = _semantic_mapped_delta
    v62.run()

    old_full = out / "rest_delta_v62_candidate.png"
    old_thumb = out / "rest_delta_v62_thumbnail.png"
    new_full = out / "semantic_frame_v63_candidate.png"
    new_thumb = out / "semantic_frame_v63_thumbnail.png"
    if not old_full.is_file() or not old_thumb.is_file():
        raise RuntimeError("v63 base render outputs missing")
    shutil.copy2(old_full, new_full)
    shutil.copy2(old_thumb, new_thumb)

    report = json.loads(report_path.read_text(encoding="utf-8"))
    report["representation"] = "source pose axis+angle mapped through coherent phalanx-rest + shared-palm semantic frames"
    report["semantic_frame_transfer"] = True
    report["source_angle_preserved"] = True
    report["per_joint_bend_plane_reconstruction"] = False
    report["damping_or_curl_grid_used"] = False
    report["visual_gate"] = "Retain v62 thumbnail enclosure while removing broken/blocky phalanges and major self-intersection; thumb must oppose visibly."
    report_path.write_text(json.dumps(report, indent=2, sort_keys=True), encoding="utf-8")
    print(json.dumps({
        "semantic_frame_transfer": True,
        "source_angle_preserved": True,
        "full": str(new_full),
        "thumbnail": str(new_thumb),
    }, sort_keys=True))
    print("MPFB_SEMANTIC_FRAME_V63_SUCCESS")


if __name__ == "__main__":
    try:
        run()
    except BaseException as exc:
        print("MPFB_SEMANTIC_FRAME_V63_ERROR:", exc)
        traceback.print_exc()
        raise
