#!/usr/bin/env python3
"""v61: non-destructive same-family anatomical swing retarget for the MPFB hero hand.

Checkpoint 25 closed blind Euler/axis-table tuning. This experiment changes the
abstraction: a CC0 MakeHuman holding-object BVH is loaded only on a sacrificial
source armature. Its *posed phalanx directions relative to its own palm frame*
are mapped into the already-positioned MPFB GameEngine palm frame. The target
receives swing-only pose rotations around each target joint.

Hard safety boundaries:
- source edit-bone roll is never copied;
- source pose matrices/quaternions are never assigned to target bones;
- target edit/rest bones are never modified;
- no CCD, endpoint/contact solver, distance servo, Euler sweep, or optimizer;
- the result is staging-only and is saved through the v49 17-bone same-rig
  matrix_basis format only after the pose has been applied to the target rig.

The only promotion gate is the persisted 192x108 silhouette.
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
        raise RuntimeError(f"could not load {filename}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


v19 = _load("mpfb_v19_for_v61", "render_mpfb_retarget_preview_v19.py")
v23 = _load("mpfb_v23_for_v61", "render_mpfb_contact_ik_v23.py")
v35 = _load("mpfb_v35_for_v61", "render_mpfb_canonical_grip_v35.py")
v49 = _load("mpfb_manual_pose_v49_for_v61", "manual_pose_asset_v49.py")
v53 = _load("mpfb_v53_for_v61", "author_mpfb_anatomical_controls_v53.py")

SOURCE_TO_TARGET = {
    "finger1-1.r": "thumb_01_r", "finger1-2.r": "thumb_02_r", "finger1-3.r": "thumb_03_r",
    "finger2-1.r": "index_01_r", "finger2-2.r": "index_02_r", "finger2-3.r": "index_03_r",
    "finger3-1.r": "middle_01_r", "finger3-2.r": "middle_02_r", "finger3-3.r": "middle_03_r",
    "finger4-1.r": "ring_01_r", "finger4-2.r": "ring_02_r", "finger4-3.r": "ring_03_r",
    "finger5-1.r": "pinky_01_r", "finger5-2.r": "pinky_02_r", "finger5-3.r": "pinky_03_r",
}


def _args():
    if "--" not in sys.argv:
        raise RuntimeError("expected -- <xr.glb> <target-mpfb.glb> <source.bvh> <outdir> <pose.json> <report.json>")
    values = sys.argv[sys.argv.index("--") + 1:]
    if len(values) != 6:
        raise RuntimeError("expected six arguments")
    return tuple(Path(v).resolve() for v in values)


def _orthonormal_frame(forward: Vector, span: Vector) -> tuple[Vector, Vector, Vector]:
    f = forward.normalized()
    s = span - f * span.dot(f)
    if s.length < 1e-6:
        raise RuntimeError("degenerate palm span")
    s.normalize()
    n = f.cross(s)
    if n.length < 1e-6:
        raise RuntimeError("degenerate palm normal")
    n.normalize()
    # Recompute span so numerical drift cannot make the basis non-orthogonal.
    s = n.cross(f).normalized()
    return f, s, n


def _source_frame(src):
    required = ["wrist.r", "finger2-1.r", "finger3-1.r", "finger4-1.r", "finger5-1.r"]
    missing = [name for name in required if src.pose.bones.get(name) is None]
    if missing:
        raise RuntimeError(f"source BVH missing palm landmarks: {missing}")
    wrist = src.pose.bones["wrist.r"].head.copy()
    mcps = [src.pose.bones[name].head.copy() for name in required[1:]]
    forward = (sum(mcps, Vector()) / len(mcps)) - wrist
    span = mcps[-1] - mcps[0]
    return _orthonormal_frame(forward, span)


def _target_frame(target):
    _palm, forward, span, _normal = v53._local_palm_frame(target)
    return _orthonormal_frame(forward, span)


def _map_direction(direction: Vector, source_frame, target_frame) -> Vector:
    sf, ss, sn = source_frame
    tf, ts, tn = target_frame
    d = direction.normalized()
    mapped = tf * d.dot(sf) + ts * d.dot(ss) + tn * d.dot(sn)
    if mapped.length < 1e-6:
        raise RuntimeError("mapped source direction collapsed")
    return mapped.normalized()


def _swing_pose_bone(target, bone_name: str, desired_direction: Vector) -> float:
    pb = target.pose.bones.get(bone_name)
    if pb is None:
        raise RuntimeError("target missing pose bone " + bone_name)
    current = pb.tail - pb.head
    if current.length < 1e-6:
        raise RuntimeError("zero-length target pose bone " + bone_name)
    current.normalize()
    desired = desired_direction.normalized()
    swing = current.rotation_difference(desired)
    head = pb.head.copy()
    rot = swing.to_matrix().to_4x4()
    pb.matrix = Matrix.Translation(head) @ rot @ Matrix.Translation(-head) @ pb.matrix
    bpy.context.view_layer.update()
    return float(current.angle(desired))


def _import_source_bvh(path: Path):
    before = set(bpy.context.scene.objects)
    bpy.ops.import_anim.bvh(filepath=str(path), frame_start=1, update_scene_fps=True)
    created = [obj for obj in bpy.context.scene.objects if obj not in before and obj.type == "ARMATURE"]
    if len(created) != 1:
        raise RuntimeError(f"expected one sacrificial BVH armature, got {len(created)}")
    src = created[0]
    bpy.context.scene.frame_set(1)
    bpy.context.view_layer.update()
    return src


def _matrix_error(a: Matrix, b: Matrix) -> float:
    return max(abs(a[r][c] - b[r][c]) for r in range(4) for c in range(4))


def _render_thumbnail(cam, out: Path, focus: Vector) -> None:
    scene = bpy.context.scene
    old = (scene.render.resolution_x, scene.render.resolution_y, scene.render.resolution_percentage)
    scene.render.resolution_x = 192
    scene.render.resolution_y = 108
    scene.render.resolution_percentage = 100
    try:
        v19._render(cam, out, "samefamily_swing_v61_thumbnail", focus)
    finally:
        scene.render.resolution_x, scene.render.resolution_y, scene.render.resolution_percentage = old


def run() -> None:
    xr_path, target_path, source_bvh, out, pose_path, report_path = _args()
    out.mkdir(parents=True, exist_ok=True)
    pose_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.parent.mkdir(parents=True, exist_ok=True)

    v19._reset()
    xr, xr_meshes = v19._import_armature(xr_path, "XR")
    for mesh in xr_meshes:
        mesh.hide_render = True
        mesh.hide_viewport = True
    target, meshes = v19._import_armature(target_path, "MPFB")
    cam = v19._setup_render(meshes)

    # Keep the already-proven whole-hand placement layer. v61 changes only the
    # anatomical representation used for the digit pose.
    v19._clear(target)
    v23._pose_seed(xr, target, "Cup_Armature")
    center, axis, inward, _ = v35._fixture_from_seed(target, 1.0)
    proxy = v35.v33._proxy(center, axis, "SameFamilySwingV61Vessel")
    whole_rotation_deg, root_shift = v35._orient_whole_hand(target, center, axis, inward)
    camera_target = v53._camera_target_preserving_pose(target)

    src = _import_source_bvh(source_bvh)
    source_frame = _source_frame(src)
    target_frame = _target_frame(target)

    swing_radians = {}
    # Parent-to-child order matters: each child correction is applied after its
    # parent has moved, so the final target phalanx direction is the mapped
    # anatomical source direction without importing source twist/roll.
    for source_name, target_name in SOURCE_TO_TARGET.items():
        source_pb = src.pose.bones.get(source_name)
        if source_pb is None:
            raise RuntimeError("source BVH missing mapped bone " + source_name)
        source_direction = source_pb.tail - source_pb.head
        desired = _map_direction(source_direction, source_frame, target_frame)
        swing_radians[target_name] = _swing_pose_bone(target, target_name, desired)

    expected = {name: target.pose.bones[name].matrix_basis.copy() for name in v49.BONES}
    payload = v49.save_pose(
        target,
        pose_path,
        label="v61 CC0 same-family palm-frame swing retarget support candidate",
        provenance={
            "kind": "same-family-palm-frame-swing-retarget",
            "production_candidate": False,
            "source_pack": "MakeHuman Community Poses 01 holding-wine-glass (CC0)",
            "source_edit_bone_roll_copied": False,
            "source_pose_matrices_copied": False,
            "source_twist_copied": False,
            "target_edit_rest_modified": False,
            "target_solver_used": False,
            "retarget_representation": "source phalanx directions in source palm frame -> target palm frame; target swing only",
        },
    )

    v49.clear_pose(target)
    v49.load_pose(target, pose_path)
    errors = {name: _matrix_error(expected[name], target.pose.bones[name].matrix_basis) for name in v49.BONES}
    max_reload_error = max(errors.values())
    if max_reload_error > 1e-6:
        raise RuntimeError(f"v61 durable pose reload changed matrices: {max_reload_error}")

    focus = camera_target.lerp(center, 0.55)
    v19._render(cam, out, "samefamily_swing_v61_candidate", focus)
    _render_thumbnail(cam, out, focus)

    report = {
        "staging_only": True,
        "production_candidate": False,
        "source_license": "CC0",
        "source_pose": "MakeHuman Community Poses 01 / holding-wine-glass",
        "source_edit_bone_roll_copied": False,
        "source_pose_matrices_copied": False,
        "source_twist_copied": False,
        "target_edit_rest_modified": False,
        "target_solver_used": False,
        "camera_focus_preserves_pose": True,
        "pose_bone_count": len(payload["bones"]),
        "mapped_digit_bone_count": len(SOURCE_TO_TARGET),
        "whole_rotation_deg": whole_rotation_deg,
        "root_shift": root_shift,
        "max_reload_matrix_error": max_reload_error,
        "swing_radians": swing_radians,
        "visual_gate": "192x108 must immediately read as a natural human vessel wrap: progressive far-contour enclosure, clean opposed thumb, no kinked/broken chains.",
    }
    report_path.write_text(json.dumps(report, indent=2, sort_keys=True), encoding="utf-8")
    print(json.dumps(report, indent=2, sort_keys=True))
    print("MPFB_SAMEFAMILY_SWING_V61_SUCCESS")

    bpy.data.objects.remove(proxy, do_unlink=True)
    bpy.data.objects.remove(src, do_unlink=True)


if __name__ == "__main__":
    try:
        run()
    except BaseException as exc:
        print("MPFB_SAMEFAMILY_SWING_V61_ERROR:", exc)
        traceback.print_exc()
        raise
