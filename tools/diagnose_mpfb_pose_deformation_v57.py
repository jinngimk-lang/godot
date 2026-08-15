#!/usr/bin/env python3
"""v57: isolate where MPFB artist FK changes are lost before visual review.

v55 and v56 persisted substantially different 17-bone ``matrix_basis`` values, yet their
final renders were visually indistinguishable. This diagnostic holds the MPFB source, Cup
seed, whole-hand placement, vessel fixture and camera constant and compares four states:

1. baseline after canonical whole-hand placement;
2. a deliberately large direct ``matrix_basis`` delta on ``index_02_r``;
3. that exact basis state after v49 save -> clear -> reload;
4. a deliberately large pose-space ``pb.matrix`` head-pivot delta on the same joint.

For each state it captures a render and evaluated skinned-mesh vertex positions. This is a
root-cause contract, not a grasp candidate. Matrix serialization is not enough: a durable
pose path is valid only if it preserves nontrivial evaluated-mesh deformation.
"""
from __future__ import annotations

import importlib.util
import json
import math
import sys
import traceback
from pathlib import Path

import bpy
from mathutils import Euler, Matrix, Vector

BASE = Path(__file__).resolve().parent


def _load(name: str, filename: str):
    spec = importlib.util.spec_from_file_location(name, BASE / filename)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"could not load {filename}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


v19 = _load("mpfb_v19_for_v57", "render_mpfb_retarget_preview_v19.py")
v23 = _load("mpfb_v23_for_v57", "render_mpfb_contact_ik_v23.py")
v35 = _load("mpfb_v35_for_v57", "render_mpfb_canonical_grip_v35.py")
v53 = _load("mpfb_v53_for_v57", "author_mpfb_anatomical_controls_v53.py")
v49 = _load("mpfb_v49_for_v57", "manual_pose_asset_v49.py")

JOINT = "index_02_r"
BASIS_DEG = (62.0, 37.0, -29.0)
POSE_SPACE_DEG = 62.0


def _args():
    if "--" not in sys.argv:
        raise RuntimeError("expected -- <xr.glb> <mpfb.glb> <outdir> <report.json>")
    values = sys.argv[sys.argv.index("--") + 1:]
    if len(values) != 4:
        raise RuntimeError("expected four arguments")
    return tuple(Path(v).resolve() for v in values)


def _flat_matrix(m: Matrix) -> list[float]:
    return [float(m[r][c]) for r in range(4) for c in range(4)]


def _matrix_max_abs_delta(a: Matrix, b: Matrix) -> float:
    return max(abs(float(a[r][c] - b[r][c])) for r in range(4) for c in range(4))


def _evaluated_vertices(meshes) -> list[Vector]:
    depsgraph = bpy.context.evaluated_depsgraph_get()
    result: list[Vector] = []
    for mesh_obj in meshes:
        evaluated = mesh_obj.evaluated_get(depsgraph)
        temp = evaluated.to_mesh()
        try:
            world = evaluated.matrix_world
            result.extend(world @ vertex.co for vertex in temp.vertices)
        finally:
            evaluated.to_mesh_clear()
    if not result:
        raise RuntimeError("v57 could not sample evaluated MPFB mesh vertices")
    return result


def _vertex_delta(a: list[Vector], b: list[Vector]) -> dict:
    if len(a) != len(b):
        raise RuntimeError(f"evaluated vertex count changed {len(a)} -> {len(b)}")
    distances = [(bv - av).length for av, bv in zip(a, b)]
    moved = [d for d in distances if d > 1e-7]
    return {
        "vertex_count": len(distances),
        "moved_vertex_count_gt_1e-7": len(moved),
        "moved_fraction": len(moved) / len(distances),
        "mean_distance": sum(distances) / len(distances),
        "max_distance": max(distances),
    }


def _render(cam, out: Path, stem: str, focus: Vector) -> None:
    out.mkdir(parents=True, exist_ok=True)
    v19._render(cam, out, stem, focus)


def _restore_basis(arm, saved: dict[str, Matrix]) -> None:
    for name, matrix in saved.items():
        arm.pose.bones[name].matrix_basis = matrix.copy()
    bpy.context.view_layer.update()


def run() -> None:
    xr_path, mpfb_path, out, report_path = _args()
    out.mkdir(parents=True, exist_ok=True)
    report_path.parent.mkdir(parents=True, exist_ok=True)
    durable_pose_path = report_path.parent / "matrix-basis-diagnostic.pose.json"

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
    proxy = v35.v33._proxy(center, axis, "PoseDeformationV57Vessel")
    whole_rotation_deg, root_shift = v35._orient_whole_hand(arm, center, axis, inward)
    bpy.context.view_layer.update()

    if arm.pose.bones.get(JOINT) is None:
        raise RuntimeError(f"missing diagnostic joint {JOINT}")

    baseline_basis = {pb.name: pb.matrix_basis.copy() for pb in arm.pose.bones}
    baseline_joint_basis = arm.pose.bones[JOINT].matrix_basis.copy()
    baseline_joint_pose = arm.pose.bones[JOINT].matrix.copy()
    baseline_vertices = _evaluated_vertices(meshes)
    focus = v35.v22._neutral_targets(arm)[4].lerp(center, 0.55)
    _render(cam, out, "baseline", focus)

    # Variant A: direct basis write, matching the representation used by v55/v56.
    basis_delta = Euler(tuple(math.radians(v) for v in BASIS_DEG), "XYZ").to_matrix().to_4x4()
    arm.pose.bones[JOINT].matrix_basis = arm.pose.bones[JOINT].matrix_basis @ basis_delta
    bpy.context.view_layer.update()
    basis_joint_basis = arm.pose.bones[JOINT].matrix_basis.copy()
    basis_joint_pose = arm.pose.bones[JOINT].matrix.copy()
    basis_vertices = _evaluated_vertices(meshes)
    _render(cam, out, "matrix_basis_delta", focus)

    # Variant B: persist that exact direct-basis state through the v49 durable boundary.
    v49.save_pose(
        arm,
        durable_pose_path,
        label="v57 deformation diagnostic — NOT a grasp",
        provenance={"kind": "deformation-contract", "production_candidate": False},
    )
    v49.clear_pose(arm)
    v49.load_pose(arm, durable_pose_path)
    reloaded_joint_basis = arm.pose.bones[JOINT].matrix_basis.copy()
    reloaded_joint_pose = arm.pose.bones[JOINT].matrix.copy()
    reloaded_vertices = _evaluated_vertices(meshes)
    _render(cam, out, "matrix_basis_reloaded", focus)

    # Variant C: restore canonical baseline and reproduce the older head-pivot pose-space
    # write used by v53's visibly active `_rot_about_joint` family.
    _restore_basis(arm, baseline_basis)
    _palm, _forward, span, normal = v53._local_palm_frame(arm)
    world_normal = arm.matrix_world.to_3x3() @ normal
    if world_normal.dot(inward) < 0.0:
        normal *= -1.0
    sign = v53._flex_sign(arm, JOINT, span, normal)
    v53._rot_about_joint(arm, JOINT, span, sign * POSE_SPACE_DEG)
    bpy.context.view_layer.update()
    pose_joint_basis = arm.pose.bones[JOINT].matrix_basis.copy()
    pose_joint_pose = arm.pose.bones[JOINT].matrix.copy()
    pose_vertices = _evaluated_vertices(meshes)
    _render(cam, out, "pose_space_delta", focus)

    basis_vertex = _vertex_delta(baseline_vertices, basis_vertices)
    reloaded_vertex = _vertex_delta(baseline_vertices, reloaded_vertices)
    basis_vs_reloaded_vertex = _vertex_delta(basis_vertices, reloaded_vertices)
    pose_vertex = _vertex_delta(baseline_vertices, pose_vertices)

    threshold = 1e-5
    report = {
        "staging_only": True,
        "production_candidate": False,
        "joint": JOINT,
        "whole_rotation_deg": float(whole_rotation_deg),
        "root_shift": float(root_shift),
        "basis_delta_xyz_deg": list(BASIS_DEG),
        "pose_space_delta_deg": POSE_SPACE_DEG,
        "pose_space_sign": sign,
        "matrix_deltas": {
            "basis_write_matrix_basis_max_abs": _matrix_max_abs_delta(baseline_joint_basis, basis_joint_basis),
            "basis_write_pose_matrix_max_abs": _matrix_max_abs_delta(baseline_joint_pose, basis_joint_pose),
            "reload_vs_direct_matrix_basis_max_abs": _matrix_max_abs_delta(basis_joint_basis, reloaded_joint_basis),
            "reload_vs_direct_pose_matrix_max_abs": _matrix_max_abs_delta(basis_joint_pose, reloaded_joint_pose),
            "pose_write_matrix_basis_max_abs": _matrix_max_abs_delta(baseline_joint_basis, pose_joint_basis),
            "pose_write_pose_matrix_max_abs": _matrix_max_abs_delta(baseline_joint_pose, pose_joint_pose),
        },
        "evaluated_mesh_delta_from_baseline": {
            "matrix_basis_write": basis_vertex,
            "matrix_basis_reloaded": reloaded_vertex,
            "pose_space_write": pose_vertex,
        },
        "evaluated_mesh_delta_direct_vs_reloaded": basis_vs_reloaded_vertex,
        "diagnostic_contract": {
            "nontrivial_vertex_delta_threshold": threshold,
            "matrix_basis_write_visibly_deforms": basis_vertex["max_distance"] > threshold,
            "matrix_basis_reload_preserves_deformation": (
                reloaded_vertex["max_distance"] > threshold
                and basis_vs_reloaded_vertex["max_distance"] <= threshold
            ),
            "pose_space_write_visibly_deforms": pose_vertex["max_distance"] > threshold,
        },
        "baseline_joint_basis": _flat_matrix(baseline_joint_basis),
        "basis_joint_basis": _flat_matrix(basis_joint_basis),
        "reloaded_joint_basis": _flat_matrix(reloaded_joint_basis),
        "pose_joint_basis": _flat_matrix(pose_joint_basis),
    }
    report_path.write_text(json.dumps(report, indent=2, sort_keys=True), encoding="utf-8")
    print(json.dumps(report, indent=2, sort_keys=True))
    print("MPFB_POSE_DEFORMATION_V57_SUCCESS")
    bpy.data.objects.remove(proxy, do_unlink=True)


if __name__ == "__main__":
    try:
        run()
    except BaseException as exc:
        print("MPFB_POSE_DEFORMATION_V57_ERROR:", exc)
        traceback.print_exc()
        raise
