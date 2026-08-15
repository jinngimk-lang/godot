#!/usr/bin/env python3
"""v58: keep the v57 Henny-authored finger shape and fix only whole-hand clearance.

v57 transferred a visibly flexed CC0 cyclist shape prior safely, but the resulting
finger chains penetrated the staging vessel: distal curl disappeared *into* the cylinder
instead of reading around its surface. v58 does not change any finger or thumb joint.
After the v57 bone pose is authored, it moves the entire continuous limb outward along
the vessel's near radial until every sampled hero-finger joint lies outside the cylinder
surface plus a small clearance. This isolates placement from pose authoring.

Staging only. Thumbnail Macro/Meso evidence remains authoritative.
"""
from __future__ import annotations

import importlib.util
import json
import os
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


v57 = _load("mpfb_v57_for_v58", "author_mpfb_poses02_henny_v57.py")
v55 = v57.v55
v53 = v55.v53
v19 = v53.v19
v23 = v53.v23
v35 = v53.v35
v49 = v53.v49

SURFACE_CLEARANCE = 0.0015
MAX_OUTWARD_SHIFT = 0.065
SHIFT_STEP = 0.0005
HERO_DIGIT_BONES = [
    f"{digit}_{segment:02d}_r"
    for digit in ("thumb", "index", "middle", "ring", "pinky")
    for segment in (1, 2, 3)
]


def _args():
    if "--" not in sys.argv:
        raise RuntimeError("expected -- <xr.glb> <mpfb.glb> <outdir> <pose.json> <report.json>")
    values = sys.argv[sys.argv.index("--") + 1:]
    if len(values) != 5:
        raise RuntimeError("expected five arguments")
    return tuple(Path(v).resolve() for v in values)


def _radial_distance(point: Vector, center: Vector, axis: Vector) -> float:
    axis_n = axis.normalized()
    delta = point - center
    radial = delta - axis_n * delta.dot(axis_n)
    return radial.length


def _sample_world_points(arm) -> list[tuple[str, Vector]]:
    rows = []
    for bone_name in HERO_DIGIT_BONES:
        pb = arm.pose.bones.get(bone_name)
        if pb is None:
            raise RuntimeError("v58 missing target digit bone " + bone_name)
        rows.append((bone_name + ":head", arm.matrix_world @ pb.head))
        rows.append((bone_name + ":tail", arm.matrix_world @ pb.tail))
    return rows


def _minimum_radial(arm, center: Vector, axis: Vector) -> tuple[float, str]:
    samples = _sample_world_points(arm)
    name, point = min(samples, key=lambda row: _radial_distance(row[1], center, axis))
    return _radial_distance(point, center, axis), name


def _near_radial(arm, center: Vector, axis: Vector) -> Vector:
    palm, _forward, _span, _normal = v35.v33._palm_frame(arm)
    axis_n = axis.normalized()
    near = palm - center
    near -= axis_n * near.dot(axis_n)
    if near.length < 1e-7:
        raise RuntimeError("v58 degenerate near radial")
    return near.normalized()


def _find_clearance_shift(arm, center: Vector, axis: Vector, near: Vector) -> tuple[float, float, str]:
    target_radius = v35.VESSEL_RADIUS + SURFACE_CLEARANCE
    start_arm = arm.matrix_world.copy()
    meshes = {m.name: m.matrix_world.copy() for m in v35.v34._driven_meshes(arm)}

    best = None
    steps = int(MAX_OUTWARD_SHIFT / SHIFT_STEP) + 1
    for i in range(steps):
        shift = i * SHIFT_STEP
        arm.matrix_world = Matrix.Translation(near * shift) @ start_arm
        for name, matrix in meshes.items():
            mesh = bpy.data.objects.get(name)
            if mesh is not None and not v35.v34._is_descendant(mesh, arm):
                mesh.matrix_world = Matrix.Translation(near * shift) @ matrix
        bpy.context.view_layer.update()
        minimum, culprit = _minimum_radial(arm, center, axis)
        if best is None or minimum > best[1]:
            best = (shift, minimum, culprit)
        if minimum >= target_radius:
            return shift, minimum, culprit

    # Restore the best physically-separated staging placement if the strict clearance
    # cannot be reached within the bounded root shift. The report marks it objective
    # reject; visual evidence is still useful for diagnosing whether clearance alone is
    # the missing ingredient.
    assert best is not None
    shift = best[0]
    arm.matrix_world = Matrix.Translation(near * shift) @ start_arm
    for name, matrix in meshes.items():
        mesh = bpy.data.objects.get(name)
        if mesh is not None and not v35.v34._is_descendant(mesh, arm):
            mesh.matrix_world = Matrix.Translation(near * shift) @ matrix
    bpy.context.view_layer.update()
    minimum, culprit = _minimum_radial(arm, center, axis)
    return shift, minimum, culprit


def _render_thumbnail(cam, out: Path, focus: Vector) -> None:
    scene = bpy.context.scene
    old = (scene.render.resolution_x, scene.render.resolution_y, scene.render.resolution_percentage)
    scene.render.resolution_x = 192
    scene.render.resolution_y = 108
    scene.render.resolution_percentage = 100
    try:
        v19._render(cam, out, "henny_surface_clearance_v58_thumbnail", focus)
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
    proxy = v53._proxy(center, axis)
    whole_rotation_deg, root_shift = v35._orient_whole_hand(arm, center, axis, inward)

    _palm, forward, span, normal = v53._local_palm_frame(arm)
    world_normal = arm.matrix_world.to_3x3() @ normal
    if world_normal.dot(inward) < 0.0:
        normal *= -1.0

    # Freeze v57's screened source-direction authoring. No joint changes occur after
    # these two calls; v58 only moves the continuous limb as one rigid body.
    finger_controls = v55._apply_finger_controls(arm, span, normal)
    thumb_controls = v55._apply_thumb_controls(arm, forward, span, normal)

    pre_clearance_min, pre_culprit = _minimum_radial(arm, center, axis)
    near = _near_radial(arm, center, axis)
    outward_shift, post_clearance_min, post_culprit = _find_clearance_shift(arm, center, axis, near)
    target_radius = v35.VESSEL_RADIUS + SURFACE_CLEARANCE
    clearance_pass = post_clearance_min >= target_radius - 1e-6

    expected = {name: arm.pose.bones[name].matrix_basis.copy() for name in v49.BONES}
    payload = v49.save_pose(
        arm,
        pose_path,
        label="v58 Henny source-direction pose with surface-aware whole-hand staging",
        provenance={
            "kind": "cc0-poses02-henny-source-direction-plus-rigid-surface-clearance",
            "production_candidate": False,
            "automatic_retarget": False,
            "retarget_source_transforms_used": False,
            "source_direction_coefficients_only": True,
            "finger_joint_changes_after_v57": False,
            "whole_limb_clearance_only": True,
            "source_asset": "MakeHuman Poses02 / henny_cyclist_normal",
        },
    )

    # Pose persistence must stay bone-local. Whole-limb staging placement is deliberately
    # not baked into the pose file and is reported separately.
    v49.clear_pose(arm)
    v49.load_pose(arm, pose_path)
    errors = {name: _matrix_error(expected[name], arm.pose.bones[name].matrix_basis) for name in v49.BONES}
    max_reload_error = max(errors.values())
    if max_reload_error > 1e-6:
        raise RuntimeError(f"v58 durable pose reload changed matrices: {max_reload_error}")

    camera_target = v35.v22._neutral_targets(arm)[4]
    focus = camera_target.lerp(center, 0.55)
    v19._render(cam, out, "henny_surface_clearance_v58_candidate", focus)
    _render_thumbnail(cam, out, focus)

    source = v55._source_reference()
    report = {
        "staging_only": True,
        "production_candidate": False,
        "automatic_retarget": False,
        "retarget_source_transforms_used": False,
        "source_local_rotations_copied": False,
        "source_matrix_basis_copied": False,
        "source_bone_roll_modified": False,
        "source_direction_coefficients_only": True,
        "source_asset": "MakeHuman Poses02 / henny_cyclist_normal",
        "source_declared_license": "CC0",
        "source_url": "https://files2.makehumancommunity.org/asset_packs/poses02/poses02_cc0.zip",
        "source_bvh_sha256": source["source_bvh_sha256"],
        "target_solver_used": False,
        "bend_toward_center_used": False,
        "finger_joint_changes_after_v57": False,
        "whole_limb_clearance_only": True,
        "pose_bone_count": len(payload["bones"]),
        "whole_rotation_deg": whole_rotation_deg,
        "original_root_shift": root_shift,
        "surface_clearance_target_radius": target_radius,
        "surface_clearance_pre_min_radial": pre_clearance_min,
        "surface_clearance_pre_culprit": pre_culprit,
        "surface_clearance_outward_shift": outward_shift,
        "surface_clearance_post_min_radial": post_clearance_min,
        "surface_clearance_post_culprit": post_culprit,
        "surface_clearance_objective_pass": clearance_pass,
        "max_reload_matrix_error": max_reload_error,
        "finger_controls": finger_controls,
        "thumb_controls": thumb_controls,
        "visual_gate": "192x108 must immediately read as a human hand enclosing the vessel; clearance may not turn the hand into a floating open fan.",
    }
    report_path.write_text(json.dumps(report, indent=2, sort_keys=True), encoding="utf-8")
    print(json.dumps(report, indent=2, sort_keys=True))
    print("MPFB_HENNY_SURFACE_CLEARANCE_V58_SUCCESS")
    bpy.data.objects.remove(proxy, do_unlink=True)


if __name__ == "__main__":
    try:
        run()
    except BaseException as exc:
        print("MPFB_HENNY_SURFACE_CLEARANCE_V58_ERROR:", exc)
        traceback.print_exc()
        raise
