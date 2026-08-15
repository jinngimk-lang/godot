"""v37: whole-hand placement followed by explicit joint-arc finger choreography.

v35 improved the whole-hand frame, while v36 proved that merely changing CCD order is
insufficient: fingertip endpoint optimization still leaves long parallel tines. This
experiment changes the optimization target itself. After the accepted v35 whole-hand
orientation, each phalanx is steered toward a progressive cylindrical arc waypoint
before a small bounded fingertip refinement. The hypothesis is falsifiable: a winning
candidate must visibly read as fingers wrapping around the vessel at Macro/Meso scale,
not merely produce low endpoint error.

This is a staging/falsification harness only. It does not touch production runtime.
"""
from __future__ import annotations

import importlib.util
import math
import traceback
from pathlib import Path

import bpy
from mathutils import Vector

V35_PATH = Path(__file__).with_name("render_mpfb_canonical_grip_v35.py")
spec = importlib.util.spec_from_file_location("mpfb_v35", V35_PATH)
if spec is None or spec.loader is None:
    raise RuntimeError("could not load v35 helpers")
v35 = importlib.util.module_from_spec(spec)
spec.loader.exec_module(v35)
v23 = v35.v23
v21 = v23.v21

BUDGET_DEG = v23.CCD_EXTRA_BUDGET_DEG
JOINT_STEP_CAP_DEG = 12.0
REFINE_STEP_CAP_DEG = 4.0
REFINE_ITERATIONS = 4

CHAINS = dict(v23.SUPPORT_CHAINS)
CHAINS["thumb"] = v23.PINCH_CHAINS["thumb"]

# Each tuple is the desired cylindrical arc angle for the tail of proximal,
# intermediate and distal phalanges. Fingers progressively wrap to the far side;
# the thumb opposes them from the other direction.
JOINT_ARC_DEG = {
    "thumb": (-18.0, -48.0, -78.0),
    "index": (32.0, 72.0, 106.0),
    "middle": (36.0, 78.0, 113.0),
    "ring": (42.0, 86.0, 120.0),
    "pinky": (48.0, 94.0, 126.0),
}


def _world_point(arm, point_local: Vector) -> Vector:
    return arm.matrix_world @ point_local


def _rotate_bone_toward_world(arm, bone_name: str, target_world: Vector, remaining_deg: float, cap_deg: float) -> float:
    pb = arm.pose.bones.get(bone_name)
    if pb is None:
        raise RuntimeError("missing v37 pose bone " + bone_name)
    head_world = _world_point(arm, pb.head)
    tail_world = _world_point(arm, pb.tail)
    current = tail_world - head_world
    desired = target_world - head_world
    if current.length < 1e-7 or desired.length < 1e-7 or remaining_deg <= 1e-4:
        return 0.0
    raw_q = current.normalized().rotation_difference(desired.normalized())
    applied_q = v23._scaled_to_cap(raw_q, min(cap_deg, remaining_deg))
    applied_deg = math.degrees(applied_q.angle)
    if applied_deg < 1e-4:
        return 0.0
    v21._rotate_pose_bone_armature_space(pb, applied_q)
    bpy.context.view_layer.update()
    return applied_deg


def _joint_waypoint(arm, bone_name: str, center: Vector, axis: Vector, near: Vector, side: Vector, angle_deg: float) -> Vector:
    pb = arm.pose.bones.get(bone_name)
    if pb is None:
        raise RuntimeError("missing v37 waypoint bone " + bone_name)
    tail_world = _world_point(arm, pb.tail)
    axial = (tail_world - center).dot(axis)
    axial = max(-v35.VESSEL_DEPTH * 0.42, min(v35.VESSEL_DEPTH * 0.42, axial))
    angle = math.radians(angle_deg)
    radial = near * math.cos(angle) + side * math.sin(angle)
    # Intermediate joints should sit just outside the actual vessel surface.
    radius = v35.VESSEL_RADIUS + v35.SURFACE_CLEARANCE + 0.0025
    return center + radial * radius + axis * axial


def _joint_arc_close(arm, center: Vector, axis: Vector, final_targets):
    near, side = v35._wrap_basis(arm, center, axis)
    added = {digit: {bone: 0.0 for bone in chain} for digit, chain in CHAINS.items()}

    # Structural pass: establish curvature along the whole digit rather than chasing
    # only the fingertip. Two passes allow upstream joint rotation to propagate before
    # the downstream waypoint is recomputed.
    for _pass in range(2):
        for digit in ("thumb", "index", "middle", "ring", "pinky"):
            chain = CHAINS[digit]
            for bone_name, angle_deg in zip(chain, JOINT_ARC_DEG[digit]):
                target = _joint_waypoint(arm, bone_name, center, axis, near, side, angle_deg)
                remaining = BUDGET_DEG - added[digit][bone_name]
                used = _rotate_bone_toward_world(arm, bone_name, target, remaining, JOINT_STEP_CAP_DEG)
                added[digit][bone_name] += used

    # Small endpoint refinement only after the phalange arc exists. This is deliberately
    # much weaker than earlier CCD so it cannot straighten the digit to win the metric.
    errors = {}
    for digit in ("thumb", "index", "middle", "ring", "pinky"):
        chain = CHAINS[digit]
        target = final_targets[digit]
        for _ in range(REFINE_ITERATIONS):
            before = (v23._tip_world(arm, chain) - target).length
            if before <= v23.CONTACT_TOLERANCE:
                break
            for bone_name in chain:
                remaining = BUDGET_DEG - added[digit][bone_name]
                if remaining <= 1e-4:
                    continue
                pb = arm.pose.bones.get(bone_name)
                head_world = _world_point(arm, pb.head)
                tip_world = v23._tip_world(arm, chain)
                current = tip_world - head_world
                desired = target - head_world
                if current.length < 1e-7 or desired.length < 1e-7:
                    continue
                q = current.normalized().rotation_difference(desired.normalized())
                q = v23._scaled_to_cap(q, min(REFINE_STEP_CAP_DEG, remaining))
                deg = math.degrees(q.angle)
                if deg < 1e-4:
                    continue
                v21._rotate_pose_bone_armature_space(pb, q)
                added[digit][bone_name] += deg
                bpy.context.view_layer.update()
        errors[digit] = (v23._tip_world(arm, chain) - target).length

    return {
        digit: {"error": errors[digit], "added_deg": added[digit], "history": []}
        for digit in CHAINS
    }


def _run_candidate(xr, arm, cam, out: Path, sign: float, camera_target: Vector):
    label = "positive" if sign > 0 else "negative"
    v35.v19._clear(arm)
    v23._pose_seed(xr, arm, "Cup_Armature")
    center, axis, inward, _ = v35._fixture_from_seed(arm, sign)
    proxy = v35.v33._proxy(center, axis, f"WholeHandV37Vessel_{label}")
    focus = camera_target.lerp(center, 0.42)

    v35.v19._render(cam, out, f"joint_arc_v37_{label}_seed", focus)
    rotation_deg, root_shift = v35._orient_whole_hand(arm, center, axis, inward)
    v35.v19._render(cam, out, f"joint_arc_v37_{label}_oriented", focus)

    targets = v35._wrap_targets(arm, center, axis)
    results = _joint_arc_close(arm, center, axis, targets)
    v35._cleanup()
    proxy = v35.v33._proxy(center, axis, f"WholeHandV37Vessel_{label}")
    v35.v19._render(cam, out, f"joint_arc_v37_{label}_closed", focus)

    passed = v35._screen(arm, center, axis, inward, results, rotation_deg, root_shift)
    print("JOINT_ARC_V37_OBJECTIVE", label, "PASS" if passed else "REJECT")
    print("JOINT_ARC_V37_ERRORS", label, {k: round(v["error"], 6) for k, v in results.items()})
    print("JOINT_ARC_V37_ADDED", label, {
        digit: {bone: round(deg, 3) for bone, deg in result["added_deg"].items()}
        for digit, result in results.items()
    })
    bpy.data.objects.remove(proxy, do_unlink=True)
    return passed


def _run():
    xr_path, mpfb_path, out = v35.v19._args()
    out.mkdir(parents=True, exist_ok=True)
    v35.v19._reset()
    xr, xr_meshes = v35.v19._import_armature(xr_path, "XR")
    for mesh in xr_meshes:
        mesh.hide_render = True
        mesh.hide_viewport = True
    arm, meshes = v35.v19._import_armature(mpfb_path, "MPFB")
    cam = v35.v19._setup_render(meshes)
    _, _, _, _, camera_target = v35.v22._neutral_targets(arm)
    baseline = v35._snapshot_world(arm)

    passes = []
    for sign in (1.0, -1.0):
        v35._restore_world(arm, baseline)
        passes.append(_run_candidate(xr, arm, cam, out, sign, camera_target))

    v35._restore_world(arm, baseline)
    print("JOINT_ARC_V37_OBJECTIVE_PASS_COUNT", sum(1 for passed in passes if passed))
    print("MPFB_JOINT_ARC_V37_SUCCESS")


if __name__ == "__main__":
    try:
        _run()
    except BaseException as exc:
        print("MPFB_JOINT_ARC_V37_ERROR:", exc)
        traceback.print_exc()
        raise
