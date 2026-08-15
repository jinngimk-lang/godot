#!/usr/bin/env python3
"""v61: non-destructive full-frame pose transfer for the continuous MPFB hero limb.

Checkpoint 25 closed blind local-Euler authoring and source-direction-only transfer.
This experiment changes the representation instead of tuning another curl table:

* source anatomy is the official CC0 MakeHuman holding-wine-glass BVH on a sacrificial rig;
* only posed bone directions and bend-plane orientation are read from that rig;
* the production-shaped MPFB GameEngine rig keeps its own edit-bone roll/rest matrices;
* each target phalanx receives a SWING that aligns its segment direction, followed by
  a bounded TWIST around the aligned segment to preserve the source bend-plane cue;
* no source edit-bone roll, BVH matrix, endpoint target, CCD, contact servo, or optimizer
  is copied into the target rig;
* the resulting 17-bone pose is persisted through the durable v49 matrix_basis format.

The candidate is staging-only. Promotion still requires the 192x108 image to read
immediately as a natural human vessel wrap.
"""
from __future__ import annotations

import importlib.util
import json
import math
import re
import sys
import traceback
from pathlib import Path

import bpy
from mathutils import Matrix, Quaternion, Vector

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

SOURCE_PREFIX = {
    "thumb": "finger1-",
    "index": "finger2-",
    "middle": "finger3-",
    "ring": "finger4-",
    "pinky": "finger5-",
}
TARGET_CHAINS = {
    digit: [f"{digit}_01_r", f"{digit}_02_r", f"{digit}_03_r"]
    for digit in ("thumb", "index", "middle", "ring", "pinky")
}
MAX_TWIST_DEG = 48.0


def _args():
    if "--" not in sys.argv:
        raise RuntimeError("expected -- <xr.glb> <mpfb.glb> <source.bvh> <outdir> <pose.json> <report.json>")
    values = sys.argv[sys.argv.index("--") + 1:]
    if len(values) != 6:
        raise RuntimeError("expected six arguments")
    return tuple(Path(v).resolve() for v in values)


def _world_point(arm, p: Vector) -> Vector:
    return arm.matrix_world @ p


def _world_dir(arm, d: Vector) -> Vector:
    v = arm.matrix_world.to_3x3() @ d
    if v.length < 1e-8:
        raise RuntimeError("degenerate world direction")
    return v.normalized()


def _source_chains(source_arm) -> dict[str, list[str]]:
    names = [pb.name for pb in source_arm.pose.bones]
    result: dict[str, list[str]] = {}
    for digit, prefix in SOURCE_PREFIX.items():
        candidates = [n for n in names if n.lower().startswith(prefix) and n.lower().endswith(".r")]
        def order(name: str) -> tuple[int, str]:
            m = re.search(r"-(\d+)", name)
            return (int(m.group(1)) if m else 999, name)
        candidates.sort(key=order)
        if len(candidates) < 3:
            raise RuntimeError(f"source {digit} chain incomplete: {candidates}")
        result[digit] = candidates[:3]
    return result


def _frame_from_world(wrist: Vector, roots: list[Vector]) -> tuple[Vector, Vector, Vector]:
    if len(roots) != 4:
        raise RuntimeError("frame requires index/middle/ring/pinky roots")
    mean_root = sum(roots, Vector()) / 4.0
    forward = mean_root - wrist
    span = roots[-1] - roots[0]
    if forward.length < 1e-7 or span.length < 1e-7:
        raise RuntimeError("degenerate hand frame")
    forward.normalize()
    # Gram-Schmidt makes the frame stable even if the posed knuckle line is skewed.
    span = span - forward * span.dot(forward)
    if span.length < 1e-7:
        raise RuntimeError("degenerate hand span")
    span.normalize()
    normal = forward.cross(span)
    if normal.length < 1e-7:
        raise RuntimeError("degenerate hand normal")
    normal.normalize()
    span = normal.cross(forward).normalized()
    return forward, span, normal


def _source_frame(source_arm, chains):
    wrist_pb = source_arm.pose.bones.get("wrist.R")
    if wrist_pb is None:
        raise RuntimeError("source BVH missing wrist.R")
    wrist = _world_point(source_arm, wrist_pb.head)
    roots = [_world_point(source_arm, source_arm.pose.bones[chains[d][0]].head) for d in ("index", "middle", "ring", "pinky")]
    return _frame_from_world(wrist, roots)


def _target_frame(target_arm):
    wrist = _world_point(target_arm, target_arm.pose.bones["hand_r"].head)
    roots = [_world_point(target_arm, target_arm.pose.bones[f"{d}_01_r"].head) for d in ("index", "middle", "ring", "pinky")]
    return _frame_from_world(wrist, roots)


def _map_frame_vector(v_world: Vector, src_frame, dst_frame) -> Vector:
    sf, ss, sn = src_frame
    df, ds, dn = dst_frame
    mapped = df * v_world.dot(sf) + ds * v_world.dot(ss) + dn * v_world.dot(sn)
    if mapped.length < 1e-8:
        raise RuntimeError("mapped source vector collapsed")
    return mapped.normalized()


def _source_segment_world(source_arm, bone_name: str) -> Vector:
    pb = source_arm.pose.bones[bone_name]
    return _world_dir(source_arm, pb.tail - pb.head)


def _source_plane_world(source_arm, chain: list[str], index: int, fallback_normal: Vector) -> Vector:
    d0 = _source_segment_world(source_arm, chain[index])
    if index + 1 < len(chain):
        d1 = _source_segment_world(source_arm, chain[index + 1])
        plane = d0.cross(d1)
        if plane.length > 1e-5:
            plane.normalize()
            # Keep plane sign stable relative to the source palm normal.
            if plane.dot(fallback_normal) < 0.0:
                plane *= -1.0
            return plane
    # Distal joints inherit the best available chain plane instead of inventing roll.
    if index > 0:
        dprev = _source_segment_world(source_arm, chain[index - 1])
        plane = dprev.cross(d0)
        if plane.length > 1e-5:
            plane.normalize()
            if plane.dot(fallback_normal) < 0.0:
                plane *= -1.0
            return plane
    return fallback_normal.copy()


def _signed_angle(a: Vector, b: Vector, axis: Vector) -> float:
    aa = a - axis * a.dot(axis)
    bb = b - axis * b.dot(axis)
    if aa.length < 1e-7 or bb.length < 1e-7:
        return 0.0
    aa.normalize(); bb.normalize(); axis = axis.normalized()
    return math.atan2(axis.dot(aa.cross(bb)), max(-1.0, min(1.0, aa.dot(bb))))


def _rotate_pose_bone_armature(arm, pb, q_arm: Quaternion) -> None:
    head = pb.head.copy()
    rot = q_arm.to_matrix().to_4x4()
    pb.matrix = Matrix.Translation(head) @ rot @ Matrix.Translation(-head) @ pb.matrix
    bpy.context.view_layer.update()


def _align_segment_and_plane(target_arm, pb, desired_world_dir: Vector, desired_world_plane: Vector) -> tuple[float, float]:
    world_rot = target_arm.matrix_world.to_quaternion().normalized()
    inv_world_rot = world_rot.inverted()
    desired_dir = (inv_world_rot @ desired_world_dir).normalized()
    desired_plane = (inv_world_rot @ desired_world_plane).normalized()

    current = pb.tail - pb.head
    if current.length < 1e-8:
        raise RuntimeError("zero-length target pose bone " + pb.name)
    current.normalize()
    swing = current.rotation_difference(desired_dir).normalized()
    swing_deg = math.degrees(swing.angle)
    _rotate_pose_bone_armature(target_arm, pb, swing)

    # After swing, align a roll-sensitive secondary vector. Blender bones run along
    # local Y, so local Z is a stable roll cue without changing edit-bone roll.
    current_secondary = pb.matrix.to_3x3() @ Vector((0.0, 0.0, 1.0))
    twist_rad = _signed_angle(current_secondary, desired_plane, desired_dir)
    twist_rad = max(-math.radians(MAX_TWIST_DEG), min(math.radians(MAX_TWIST_DEG), twist_rad))
    twist = Quaternion(desired_dir, twist_rad)
    _rotate_pose_bone_armature(target_arm, pb, twist)
    return swing_deg, math.degrees(twist_rad)


def _rest_snapshot(arm) -> dict[str, Matrix]:
    return {name: arm.data.bones[name].matrix_local.copy() for name in v49.BONES}


def _matrix_error(a: Matrix, b: Matrix) -> float:
    return max(abs(a[r][c] - b[r][c]) for r in range(4) for c in range(4))


def _apply_transfer(source_arm, target_arm, source_chains, src_frame, dst_frame) -> dict:
    rows = {}
    source_normal = src_frame[2]
    for digit in ("index", "middle", "ring", "pinky", "thumb"):
        s_chain = source_chains[digit]
        t_chain = TARGET_CHAINS[digit]
        digit_rows = []
        for i, (src_name, dst_name) in enumerate(zip(s_chain, t_chain)):
            src_dir = _source_segment_world(source_arm, src_name)
            src_plane = _source_plane_world(source_arm, s_chain, i, source_normal)
            desired_dir = _map_frame_vector(src_dir, src_frame, dst_frame)
            desired_plane = _map_frame_vector(src_plane, src_frame, dst_frame)
            pb = target_arm.pose.bones.get(dst_name)
            if pb is None:
                raise RuntimeError("missing target bone " + dst_name)
            swing_deg, twist_deg = _align_segment_and_plane(target_arm, pb, desired_dir, desired_plane)
            digit_rows.append({
                "source": src_name,
                "target": dst_name,
                "swing_deg": swing_deg,
                "twist_deg": twist_deg,
                "desired_world_direction": [float(x) for x in desired_dir],
                "desired_world_plane": [float(x) for x in desired_plane],
            })
        rows[digit] = digit_rows
    return rows


def _render_thumbnail(cam, out: Path, focus: Vector) -> None:
    scene = bpy.context.scene
    old = (scene.render.resolution_x, scene.render.resolution_y, scene.render.resolution_percentage)
    scene.render.resolution_x = 192
    scene.render.resolution_y = 108
    scene.render.resolution_percentage = 100
    try:
        v19._render(cam, out, "swing_twist_v61_thumbnail", focus)
    finally:
        scene.render.resolution_x, scene.render.resolution_y, scene.render.resolution_percentage = old


def run() -> None:
    xr_path, mpfb_path, source_bvh, out, pose_path, report_path = _args()
    out.mkdir(parents=True, exist_ok=True)
    pose_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.parent.mkdir(parents=True, exist_ok=True)

    v19._reset()
    xr, xr_meshes = v19._import_armature(xr_path, "XR")
    for mesh in xr_meshes:
        mesh.hide_render = True
        mesh.hide_viewport = True
    target, meshes = v19._import_armature(mpfb_path, "MPFB")
    cam = v19._setup_render(meshes)

    # Establish the already-validated whole-hand fixture/crop only. Finger pose is
    # replaced below by the source-derived swing/twist representation.
    v19._clear(target)
    v23._pose_seed(xr, target, "Cup_Armature")
    center, axis, inward, _ = v35._fixture_from_seed(target, 1.0)
    proxy = v35.v33._proxy(center, axis, "SwingTwistV61Vessel")
    whole_rotation_deg, root_shift = v35._orient_whole_hand(target, center, axis, inward)
    camera_target = v53._camera_target_preserving_pose(target)

    # Import source BVH only after target fixture is established. The source armature
    # is sacrificial and never becomes a production asset.
    before = set(bpy.context.scene.objects)
    bpy.ops.import_anim.bvh(filepath=str(source_bvh), frame_start=1, update_scene_fps=False)
    created = [o for o in bpy.context.scene.objects if o not in before]
    source_arms = [o for o in created if o.type == "ARMATURE"]
    if len(source_arms) != 1:
        raise RuntimeError(f"expected one sacrificial BVH armature, got {len(source_arms)}")
    source = source_arms[0]
    source.name = "SacrificialCC0HoldingPose"
    bpy.context.scene.frame_set(1)
    bpy.context.view_layer.update()

    chains = _source_chains(source)
    src_frame = _source_frame(source, chains)
    dst_frame = _target_frame(target)
    rest_before = _rest_snapshot(target)
    transfer = _apply_transfer(source, target, chains, src_frame, dst_frame)
    rest_after = _rest_snapshot(target)
    rest_error = max(_matrix_error(rest_before[n], rest_after[n]) for n in v49.BONES)
    if rest_error > 1e-10:
        raise RuntimeError(f"v61 modified target rest/edit structure: {rest_error}")

    expected = {name: target.pose.bones[name].matrix_basis.copy() for name in v49.BONES}
    payload = v49.save_pose(
        target,
        pose_path,
        label="v61 CC0 swing-twist support-wrap staging candidate",
        provenance={
            "kind": "source-frame-swing-twist",
            "source": "MakeHuman Community Poses 01 holding-wine-glass CC0 BVH",
            "production_candidate": False,
            "source_edit_bone_roll_copied": False,
            "source_pose_matrix_copied": False,
            "target_solver_used": False,
            "contact_servo_used": False,
            "target_rest_structure_modified": False,
            "max_twist_deg": MAX_TWIST_DEG,
        },
    )
    v49.clear_pose(target)
    v49.load_pose(target, pose_path)
    reload_error = max(_matrix_error(expected[n], target.pose.bones[n].matrix_basis) for n in v49.BONES)
    if reload_error > 1e-6:
        raise RuntimeError(f"v61 durable reload changed pose: {reload_error}")

    # Source is evidence input only; hide its proxy bones before rendering target anatomy.
    source.hide_render = True
    source.hide_viewport = True
    focus = camera_target.lerp(center, 0.55)
    v19._render(cam, out, "swing_twist_v61_candidate", focus)
    _render_thumbnail(cam, out, focus)

    report = {
        "staging_only": True,
        "production_candidate": False,
        "source_license": "CC0 (official MakeHuman Community Poses 01 pack)",
        "source_edit_bone_roll_copied": False,
        "source_pose_matrix_copied": False,
        "target_solver_used": False,
        "contact_servo_used": False,
        "camera_focus_preserves_pose": True,
        "pose_bone_count": len(payload["bones"]),
        "whole_rotation_deg": whole_rotation_deg,
        "root_shift": root_shift,
        "target_rest_structure_error": rest_error,
        "max_reload_matrix_error": reload_error,
        "max_twist_deg": MAX_TWIST_DEG,
        "source_chains": chains,
        "transfer": transfer,
        "visual_gate": "192x108 must immediately read as a natural vessel wrap: palm beside/around vessel, progressive far-contour finger disappearance, opposed thumb, no kinks/self-intersection.",
    }
    report_path.write_text(json.dumps(report, indent=2, sort_keys=True), encoding="utf-8")
    print(json.dumps(report, indent=2, sort_keys=True))
    print("MPFB_SWING_TWIST_V61_SUCCESS")
    bpy.data.objects.remove(proxy, do_unlink=True)


if __name__ == "__main__":
    try:
        run()
    except BaseException as exc:
        print("MPFB_SWING_TWIST_V61_ERROR:", exc)
        traceback.print_exc()
        raise
