"""v23: morphology-preserving fingertip contact IK falsification harness.

v22 proved that simply transferring more of the XR authored bone direction is the
wrong optimization axis: the full pose gets closer to the support vessel but visibly
stretches/contorts the MPFB hand, while the conservative 60% seed preserves anatomy
but still misses real vessel/flap contact.

This experiment therefore keeps v22 bounded_60 as the anatomical seed and adds only
contact-driven CCD corrections to the finger chains. The interaction targets are
frozen before posing. CCD rotations are incremental and have a strict per-bone
additional budget, so the solver cannot win by rotating a joint without bound.

Winning condition:
- support fingertips must converge toward explicit points around the far side of a
  fixed cylindrical vessel while the palm remains on the near side;
- thumb/index must converge to opposite sides of one fixed flap target;
- rendered Macro/Meso anatomy must remain believable.

This is a preview/falsification tool, not production runtime IK.
"""
from __future__ import annotations

import importlib.util
import math
import traceback
from pathlib import Path

import bpy
from mathutils import Quaternion, Vector

BASE = Path(__file__).with_name("render_mpfb_reference_pose_v22.py")
spec = importlib.util.spec_from_file_location("mpfb_v22", BASE)
if spec is None or spec.loader is None:
    raise RuntimeError("could not load v22 helpers")
v22 = importlib.util.module_from_spec(spec)
spec.loader.exec_module(v22)
v21 = v22.v21
v19 = v22.v19

SEED = v22.VARIANTS["bounded_60"]
SUPPORT_CHAINS = {
    "index": ("index_01_r", "index_02_r", "index_03_r"),
    "middle": ("middle_01_r", "middle_02_r", "middle_03_r"),
    "ring": ("ring_01_r", "ring_02_r", "ring_03_r"),
    "pinky": ("pinky_01_r", "pinky_02_r", "pinky_03_r"),
}
PINCH_CHAINS = {
    "index": SUPPORT_CHAINS["index"],
    "thumb": ("thumb_01_r", "thumb_02_r", "thumb_03_r"),
}
CCD_ITERATIONS = 12
CCD_STEP_CAP_DEG = 7.0
CCD_EXTRA_BUDGET_DEG = 24.0
CONTACT_TOLERANCE = 0.014
PINCH_TOLERANCE = 0.012


def _arm_local(arm, point_world: Vector) -> Vector:
    return arm.matrix_world.inverted() @ point_world


def _tip_world(arm, chain) -> Vector:
    return v19._wp(arm, chain[-1], True)


def _scaled_to_cap(q: Quaternion, cap_deg: float) -> Quaternion:
    angle = q.angle
    if angle < 1e-8:
        return Quaternion((1.0, 0.0, 0.0, 0.0))
    cap = math.radians(cap_deg)
    weight = min(1.0, cap / angle)
    return Quaternion((1.0, 0.0, 0.0, 0.0)).slerp(q, weight).normalized()


def _ccd_to_target(arm, chain, target_world: Vector):
    """Move one skinned fingertip using only bounded pose-bone rotations."""
    added_deg = {name: 0.0 for name in chain}
    history = []
    for iteration in range(CCD_ITERATIONS):
        before = (_tip_world(arm, chain) - target_world).length
        if before <= CONTACT_TOLERANCE:
            break
        for bone_name in reversed(chain):
            pb = arm.pose.bones.get(bone_name)
            if pb is None:
                raise RuntimeError("missing CCD pose bone " + bone_name)
            remaining = CCD_EXTRA_BUDGET_DEG - added_deg[bone_name]
            if remaining <= 1e-4:
                continue
            joint_local = pb.head.copy()
            tip_local = _arm_local(arm, _tip_world(arm, chain))
            target_local = _arm_local(arm, target_world)
            current = tip_local - joint_local
            desired = target_local - joint_local
            if current.length < 1e-7 or desired.length < 1e-7:
                continue
            raw_q = current.normalized().rotation_difference(desired.normalized())
            cap = min(CCD_STEP_CAP_DEG, remaining)
            applied_q = _scaled_to_cap(raw_q, cap)
            applied_deg = math.degrees(applied_q.angle)
            if applied_deg < 1e-4:
                continue
            v21._rotate_pose_bone_armature_space(pb, applied_q)
            added_deg[bone_name] += applied_deg
            bpy.context.view_layer.update()
        after = (_tip_world(arm, chain) - target_world).length
        history.append((iteration, before, after))
        if abs(before - after) < 1e-5:
            break
    return {
        "error": (_tip_world(arm, chain) - target_world).length,
        "added_deg": added_deg,
        "history": history,
    }


def _support_targets(arm, center: Vector, radius: float, axis: Vector):
    """Create explicit wrap targets on the far half of the frozen vessel.

    Palm-facing radial direction defines the near side. Fingers are assigned around
    125-155 degrees around the cylinder so they must visibly curl around it instead
    of merely hanging beside its silhouette.
    """
    palm = v19._wp(arm, "hand_r")
    axis = axis.normalized()
    radial = palm - center
    radial -= axis * radial.dot(axis)
    if radial.length < 1e-6:
        raise RuntimeError("degenerate support radial basis")
    near = radial.normalized()
    side = axis.cross(near).normalized()
    angles = {
        "index": 122.0,
        "middle": 136.0,
        "ring": 148.0,
        "pinky": 156.0,
    }
    targets = {}
    for name, angle_deg in angles.items():
        neutral_tip = v19._wp(arm, f"{name}_03_r", True)
        axial = (neutral_tip - center).dot(axis)
        axial = max(-0.072, min(0.072, axial))
        angle = math.radians(angle_deg)
        wrap_radial = near * math.cos(angle) + side * math.sin(angle)
        targets[name] = center + wrap_radial * radius + axis * axial
    return targets


def _pinch_targets(arm, flap_center: Vector):
    index_tip = v19._wp(arm, "index_03_r", True)
    thumb_tip = v19._wp(arm, "thumb_03_r", True)
    sep = index_tip - thumb_tip
    if sep.length < 1e-6:
        sep = Vector((1.0, 0.0, 0.0))
    sep.normalize()
    half_gap = 0.004
    return {
        "index": flap_center + sep * half_gap,
        "thumb": flap_center - sep * half_gap,
    }


def _marker(location: Vector, name: str, color):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=16, ring_count=8, radius=0.006, location=location)
    obj = bpy.context.object
    obj.name = name
    obj.data.materials.append(v19._mat(name + "Mat", color, 0.45))


def _pose_seed(xr, mpfb, action_name):
    semantic = v21._semantic_directions(xr, action_name)
    return v22._apply_bounded_directions(mpfb, semantic, SEED)


def _run_support(xr, mpfb, cam, out, center, radius, axis, camera_target):
    rows = _pose_seed(xr, mpfb, "Cup_Armature")
    v19._remove_proxies()
    v22._support_proxy(center, radius, axis)
    targets = _support_targets(mpfb, center, radius, axis)
    results = {}
    for name in ("index", "middle", "ring", "pinky"):
        _marker(targets[name], "SupportTarget_" + name, (0.10, 0.72, 0.22, 1.0))
        results[name] = _ccd_to_target(mpfb, SUPPORT_CHAINS[name], targets[name])
    radial, palm_clearance = v22._support_metrics(mpfb, center, radius)
    target_errors = [results[name]["error"] for name in ("index", "middle", "ring", "pinky")]
    max_added = max(max(result["added_deg"].values()) for result in results.values())
    print(
        "CONTACT_IK_V23_SUPPORT",
        "target_errors", [round(v, 6) for v in target_errors],
        "radial_errors", [round(v, 6) for v in radial],
        "palm_clearance", f"{palm_clearance:.6f}",
        "max_added_deg", f"{max_added:.3f}",
    )
    v19._render(cam, out, "contact_v23_cup_ik", camera_target)
    return target_errors, radial, palm_clearance, rows, results


def _run_pinch(xr, mpfb, cam, out, flap_center, camera_target):
    rows = _pose_seed(xr, mpfb, "Pinch Up_Armature")
    v19._remove_proxies()
    v22._paper_proxy(flap_center)
    targets = _pinch_targets(mpfb, flap_center)
    results = {}
    for name in ("index", "thumb"):
        _marker(targets[name], "PinchTarget_" + name, (0.12, 0.74, 0.24, 1.0))
        results[name] = _ccd_to_target(mpfb, PINCH_CHAINS[name], targets[name])
    gap, target_error, index_error, thumb_error = v22._pinch_metrics(mpfb, flap_center)
    max_added = max(max(result["added_deg"].values()) for result in results.values())
    print(
        "CONTACT_IK_V23_PINCH",
        "ccd_errors", [round(results[name]["error"], 6) for name in ("index", "thumb")],
        "gap", f"{gap:.6f}",
        "target_error", f"{target_error:.6f}",
        "index_error", f"{index_error:.6f}",
        "thumb_error", f"{thumb_error:.6f}",
        "max_added_deg", f"{max_added:.3f}",
    )
    v19._render(cam, out, "contact_v23_pinch_ik", camera_target)
    return gap, target_error, index_error, thumb_error, rows, results


def _run():
    xr_path, mpfb_path, out = v19._args()
    out.mkdir(parents=True, exist_ok=True)
    v19._reset()
    xr, xr_meshes = v19._import_armature(xr_path, "XR")
    for mesh in xr_meshes:
        mesh.hide_render = True
        mesh.hide_viewport = True
    mpfb, meshes = v19._import_armature(mpfb_path, "MPFB")
    cam = v19._setup_render(meshes)
    support_center, support_radius, support_axis, flap_center, camera_target = v22._neutral_targets(mpfb)

    support_target_errors, radial, _, _, _ = _run_support(
        xr, mpfb, cam, out, support_center, support_radius, support_axis, camera_target
    )
    if max(support_target_errors) > 0.030:
        raise RuntimeError("support CCD failed fixed contact target gate: " + repr(support_target_errors))

    pinch = _run_pinch(xr, mpfb, cam, out, flap_center, camera_target)
    _, target_error, index_error, thumb_error, _, _ = pinch
    if max(index_error, thumb_error) > 0.040:
        raise RuntimeError(
            "pinch CCD failed fixed flap contact gate: " + repr((target_error, index_error, thumb_error))
        )

    print("MPFB_CONTACT_IK_V23_SUCCESS")


if __name__ == "__main__":
    try:
        _run()
    except BaseException as exc:
        print("MPFB_CONTACT_IK_V23_ERROR:", exc)
        traceback.print_exc()
        raise
