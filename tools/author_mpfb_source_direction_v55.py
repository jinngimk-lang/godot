#!/usr/bin/env python3
"""v55: transfer only human-authored phalanx *directions* from a sacrificial CC0 BVH.

v54 proved that geometric flex axes derived from the target GameEngine phalanges still
produce an open hand beside the vessel. v55 changes the abstraction rather than tuning
another axis: use the MakeHuman Poses 01 holding-wine-glass pose as a human-authored
shape prior.

Safety boundary:
- the source BVH is imported into a throwaway armature only;
- no source local quaternion, matrix_basis, translation, edit-bone roll, or rest matrix
  is copied into the MPFB GameEngine rig;
- each source phalanx is reduced to three direction coefficients in a source palm-local
  orthonormal frame;
- those coefficients are reconstructed in the target GameEngine palm frame after the
  already-proven whole-hand placement, then each target segment is shortest-arc aligned
  to that desired direction;
- target scale, topology, weights, hierarchy, bone roll, and persistent pose format stay
  native to the GameEngine rig.

This is staging-only. Macro/Meso thumbnail silhouette remains authoritative.
"""
from __future__ import annotations

import hashlib
import importlib.util
import json
import os
import traceback
from pathlib import Path

import bpy
from mathutils import Matrix, Vector

BASE = Path(__file__).resolve().parent
SPEC = importlib.util.spec_from_file_location(
    "mpfb_anatomical_controls_v53_base_for_v55",
    BASE / "author_mpfb_anatomical_controls_v53.py",
)
if SPEC is None or SPEC.loader is None:
    raise RuntimeError("could not load v53")
v53 = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(v53)

SOURCE_TO_TARGET = {
    "thumb": [("finger1-1.R", "thumb_01_r"), ("finger1-2.R", "thumb_02_r"), ("finger1-3.R", "thumb_03_r")],
    "index": [("finger2-1.R", "index_01_r"), ("finger2-2.R", "index_02_r"), ("finger2-3.R", "index_03_r")],
    "middle": [("finger3-1.R", "middle_01_r"), ("finger3-2.R", "middle_02_r"), ("finger3-3.R", "middle_03_r")],
    "ring": [("finger4-1.R", "ring_01_r"), ("finger4-2.R", "ring_02_r"), ("finger4-3.R", "ring_03_r")],
    "pinky": [("finger5-1.R", "pinky_01_r"), ("finger5-2.R", "pinky_02_r"), ("finger5-3.R", "pinky_03_r")],
}

_SOURCE_CACHE: dict | None = None
_SOURCE_BVH_SHA256 = ""


def _sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as fh:
        for block in iter(lambda: fh.read(1024 * 1024), b""):
            h.update(block)
    return h.hexdigest()


def _orthonormal_palm_frame(wrist: Vector, mcps: list[Vector]) -> tuple[Vector, Vector, Vector, Vector]:
    palm = (wrist + sum(mcps, Vector())) / float(len(mcps) + 1)
    forward = (sum(mcps, Vector()) / float(len(mcps))) - wrist
    span = mcps[-1] - mcps[0]
    if forward.length < 1e-7 or span.length < 1e-7:
        raise RuntimeError("degenerate v55 palm frame")
    forward.normalize()
    # Gram-Schmidt keeps the coefficients independent of the source/target rig's
    # non-orthogonal MCP layout.
    span = span - forward * span.dot(forward)
    if span.length < 1e-7:
        raise RuntimeError("degenerate v55 palm span")
    span.normalize()
    normal = forward.cross(span)
    if normal.length < 1e-7:
        raise RuntimeError("degenerate v55 palm normal")
    normal.normalize()
    span = normal.cross(forward)
    span.normalize()
    return palm, forward, span, normal


def _direction_coefficients(direction: Vector, forward: Vector, span: Vector, normal: Vector) -> list[float]:
    d = direction.normalized()
    return [float(d.dot(forward)), float(d.dot(span)), float(d.dot(normal))]


def _extract_source_reference() -> dict:
    global _SOURCE_BVH_SHA256
    bvh_env = os.environ.get("PEEL_MH_SOURCE_BVH", "").strip()
    if not bvh_env:
        raise RuntimeError("PEEL_MH_SOURCE_BVH is required for v55")
    bvh_path = Path(bvh_env).resolve()
    if not bvh_path.is_file():
        raise RuntimeError("v55 source BVH missing: " + str(bvh_path))
    _SOURCE_BVH_SHA256 = _sha256(bvh_path)

    before = set(bpy.context.scene.objects)
    bpy.ops.import_anim.bvh(filepath=str(bvh_path), frame_start=1, update_scene_fps=True)
    imported = [obj for obj in bpy.context.scene.objects if obj not in before]
    arms = [obj for obj in imported if obj.type == "ARMATURE"]
    if len(arms) != 1:
        raise RuntimeError(f"expected one sacrificial v55 source armature, got {len(arms)}")
    src = arms[0]
    bpy.context.scene.frame_set(1)
    bpy.context.view_layer.update()

    required = ["wrist.R"] + [f"finger{i}-1.R" for i in range(2, 6)]
    missing = [name for name in required if src.pose.bones.get(name) is None]
    if missing:
        raise RuntimeError("v55 source missing palm landmarks: " + ",".join(missing))

    wrist = src.pose.bones["wrist.R"].head.copy()
    mcps = [src.pose.bones[f"finger{i}-1.R"].head.copy() for i in range(2, 6)]
    _palm, forward, span, normal = _orthonormal_palm_frame(wrist, mcps)

    rows: dict[str, list[dict]] = {}
    for digit, pairs in SOURCE_TO_TARGET.items():
        digit_rows = []
        for source_name, target_name in pairs:
            pb = src.pose.bones.get(source_name)
            if pb is None:
                raise RuntimeError("v55 source missing phalanx " + source_name)
            direction = pb.tail - pb.head
            if direction.length < 1e-7:
                raise RuntimeError("v55 zero-length source phalanx " + source_name)
            digit_rows.append({
                "source_bone": source_name,
                "target_bone": target_name,
                "palm_direction_coefficients": _direction_coefficients(direction, forward, span, normal),
            })
        rows[digit] = digit_rows

    # The BVH armature is evidence only. Remove every object created by import before
    # target rendering so the source can never become part of a candidate asset.
    for obj in imported:
        if obj.name in bpy.context.scene.objects:
            bpy.data.objects.remove(obj, do_unlink=True)
    bpy.context.view_layer.update()

    return {
        "source_bvh": str(bvh_path),
        "source_bvh_sha256": _SOURCE_BVH_SHA256,
        "directions": rows,
    }


def _source_reference() -> dict:
    global _SOURCE_CACHE
    if _SOURCE_CACHE is None:
        _SOURCE_CACHE = _extract_source_reference()
    return _SOURCE_CACHE


def _target_frame(arm, requested_normal: Vector) -> tuple[Vector, Vector, Vector]:
    wrist = arm.pose.bones["hand_r"].head.copy()
    mcps = [arm.pose.bones[f"{digit}_01_r"].head.copy() for digit in ("index", "middle", "ring", "pinky")]
    _palm, forward, span, normal = _orthonormal_palm_frame(wrist, mcps)
    # v53 has already resolved the semantic vessel-facing normal sign. Preserve it.
    if normal.dot(requested_normal) < 0.0:
        normal *= -1.0
        span *= -1.0
    return forward, span, normal


def _mapped_direction(coeffs: list[float], forward: Vector, span: Vector, normal: Vector) -> Vector:
    direction = forward * coeffs[0] + span * coeffs[1] + normal * coeffs[2]
    if direction.length < 1e-7:
        raise RuntimeError("degenerate v55 reconstructed direction")
    return direction.normalized()


def _align_pose_segment(arm, bone_name: str, desired_local: Vector) -> float:
    pb = arm.pose.bones.get(bone_name)
    if pb is None:
        raise RuntimeError("missing v55 target bone " + bone_name)
    current = pb.tail - pb.head
    if current.length < 1e-7:
        raise RuntimeError("zero-length v55 target bone " + bone_name)
    current.normalize()
    desired = desired_local.normalized()
    q = current.rotation_difference(desired)
    angle = float(q.angle)
    rot = q.to_matrix().to_4x4()
    head = pb.head.copy()
    pb.matrix = Matrix.Translation(head) @ rot @ Matrix.Translation(-head) @ pb.matrix
    bpy.context.view_layer.update()
    return angle


def _transfer_digit(arm, digit: str, forward: Vector, span: Vector, normal: Vector) -> dict:
    reference = _source_reference()["directions"][digit]
    rows = []
    for row in reference:
        desired = _mapped_direction(row["palm_direction_coefficients"], forward, span, normal)
        angle_rad = _align_pose_segment(arm, row["target_bone"], desired)
        rows.append({
            **row,
            "mapped_target_direction": [float(v) for v in desired],
            "target_alignment_degrees": angle_rad * 57.29577951308232,
        })
    return {
        "semantic": "CC0 source phalanx direction coefficients mapped into native GameEngine palm frame",
        "joints": rows,
    }


def _apply_finger_controls(arm, _span: Vector, normal: Vector) -> dict:
    forward, target_span, target_normal = _target_frame(arm, normal)
    return {
        digit: _transfer_digit(arm, digit, forward, target_span, target_normal)
        for digit in ("index", "middle", "ring", "pinky")
    }


def _apply_thumb_controls(arm, _forward: Vector, _span: Vector, normal: Vector) -> dict:
    forward, target_span, target_normal = _target_frame(arm, normal)
    return _transfer_digit(arm, "thumb", forward, target_span, target_normal)


def _enrich_outputs() -> None:
    # v53 owns the stable build/orient/save/reload/render pipeline. Rename the evidence
    # so later checkpoints cannot confuse this structurally different v55 candidate with v53.
    out_env = os.environ.get("PEEL_V55_OUTDIR", "").strip()
    report_env = os.environ.get("PEEL_V55_REPORT", "").strip()
    pose_env = os.environ.get("PEEL_V55_POSE", "").strip()
    if not out_env or not report_env or not pose_env:
        raise RuntimeError("v55 output/report/pose environment is required")
    out = Path(out_env).resolve()
    report_path = Path(report_env).resolve()
    pose_path = Path(pose_env).resolve()

    renames = {
        out / "anatomical_controls_v53_candidate.png": out / "source_direction_v55_candidate.png",
        out / "anatomical_controls_v53_thumbnail.png": out / "source_direction_v55_thumbnail.png",
    }
    for old, new in renames.items():
        if not old.is_file():
            raise RuntimeError("v55 expected render missing: " + str(old))
        old.replace(new)

    report = json.loads(report_path.read_text(encoding="utf-8"))
    source = _source_reference()
    report.update({
        "staging_only": True,
        "production_candidate": False,
        "automatic_retarget": False,
        "retarget_source_transforms_used": False,
        "source_local_rotations_copied": False,
        "source_matrix_basis_copied": False,
        "source_bone_roll_modified": False,
        "source_direction_coefficients_only": True,
        "source_asset": "MakeHuman Poses 01 / mindfront_sitting_in_armchair_holding_wine_glass",
        "source_declared_license": "CC0",
        "source_url": "https://files2.makehumancommunity.org/asset_packs/poses01/poses01_cc0.zip",
        "source_bvh_sha256": source["source_bvh_sha256"],
        "visual_gate": "192x108 must immediately read as a human hand enclosing the vessel: opposed thumb, differentiated digit depth, and finger mass disappearing behind the far contour.",
    })
    report_path.write_text(json.dumps(report, indent=2, sort_keys=True), encoding="utf-8")

    pose = json.loads(pose_path.read_text(encoding="utf-8"))
    pose["label"] = "v55 CC0 source-direction support-wrap staging candidate"
    provenance = dict(pose.get("provenance", {}))
    provenance.update({
        "kind": "cc0-source-direction-shape-prior",
        "production_candidate": False,
        "automatic_retarget": False,
        "retarget_source_transforms_used": False,
        "source_direction_coefficients_only": True,
        "source_bvh_sha256": source["source_bvh_sha256"],
    })
    pose["provenance"] = provenance
    pose_path.write_text(json.dumps(pose, indent=2, sort_keys=True), encoding="utf-8")


if __name__ == "__main__":
    try:
        v53._apply_finger_controls = _apply_finger_controls
        v53._apply_thumb_controls = _apply_thumb_controls
        v53.run()
        _enrich_outputs()
        print("MPFB_SOURCE_DIRECTION_V55_SUCCESS")
    except BaseException as exc:
        print("MPFB_SOURCE_DIRECTION_V55_ERROR:", exc)
        traceback.print_exc()
        raise
