"""v26: direct evaluated-surface CCD for MPFB pinch contact.

v25 proved that compensating a once-sampled bone-tail -> skin-surface offset is not
stable while the digit rotates: index surface approached the flap but thumb surface
remained ~31 mm away even though bone-based corrections continued to look smaller.

This experiment removes that approximation. Each CCD joint update re-evaluates the
skinned fingertip surface influenced by the distal digit bone, then rotates the
joint from the CURRENT VISIBLE SURFACE POINT toward the fixed flap-face target.
The same bounded_60 anatomical seed and the same 24-degree cumulative per-joint
extra rotation budget are retained. Thus the only falsifiable variable is the
feedback point used by CCD: rendered surface instead of internal distal-bone tail.

Winning gate:
- unchanged v23 support wrap remains within its existing fixed-target bound;
- index/thumb visible surfaces each <= 6 mm from their opposite fixed flap-face
  target and <= 9 mm from flap center;
- visible fingertip-to-fingertip gap <= 10 mm;
- no joint receives >24 degrees additional CCD rotation.

This is staging evidence only, not production runtime IK.
"""
from __future__ import annotations

import importlib.util
import math
import traceback
from pathlib import Path

import bpy
from mathutils import Quaternion, Vector

BASE = Path(__file__).with_name("render_mpfb_surface_contact_v25.py")
spec = importlib.util.spec_from_file_location("mpfb_v25", BASE)
if spec is None or spec.loader is None:
    raise RuntimeError("could not load v25 surface helpers")
v25 = importlib.util.module_from_spec(spec)
spec.loader.exec_module(v25)

v23 = v25.v23
v22 = v25.v22
v19 = v25.v19
v21 = v23.v22.v21

SURFACE_CCD_ITERATIONS = 12
SURFACE_CCD_STEP_CAP_DEG = 7.0
SURFACE_CCD_EXTRA_BUDGET_DEG = 24.0
SURFACE_EARLY_STOP = 0.004


def _scaled_to_cap(q: Quaternion, cap_deg: float) -> Quaternion:
    angle = q.angle
    if angle < 1e-8:
        return Quaternion((1.0, 0.0, 0.0, 0.0))
    cap = math.radians(cap_deg)
    weight = min(1.0, cap / angle)
    return Quaternion((1.0, 0.0, 0.0, 0.0)).slerp(q, weight).normalized()


def _surface_ccd_to_target(arm, chain, target_world: Vector):
    """Bounded CCD using evaluated skinned fingertip surface as the endpoint."""
    distal = chain[-1]
    added_deg = {name: 0.0 for name in chain}
    history = []

    for iteration in range(SURFACE_CCD_ITERATIONS):
        surface_before = v25._weighted_surface_point(distal, target_world)
        before = (surface_before - target_world).length
        if before <= SURFACE_EARLY_STOP:
            break

        for bone_name in reversed(chain):
            pb = arm.pose.bones.get(bone_name)
            if pb is None:
                raise RuntimeError("missing surface CCD pose bone " + bone_name)
            remaining = SURFACE_CCD_EXTRA_BUDGET_DEG - added_deg[bone_name]
            if remaining <= 1e-4:
                continue

            # Re-evaluate after every joint correction. This is the central v26
            # change: the endpoint follows the deformed visible skin, not a stale
            # offset from an internal bone tail.
            current_surface_world = v25._weighted_surface_point(distal, target_world)
            joint_local = pb.head.copy()
            surface_local = v23._arm_local(arm, current_surface_world)
            target_local = v23._arm_local(arm, target_world)
            current = surface_local - joint_local
            desired = target_local - joint_local
            if current.length < 1e-7 or desired.length < 1e-7:
                continue

            raw_q = current.normalized().rotation_difference(desired.normalized())
            cap = min(SURFACE_CCD_STEP_CAP_DEG, remaining)
            applied_q = _scaled_to_cap(raw_q, cap)
            applied_deg = math.degrees(applied_q.angle)
            if applied_deg < 1e-4:
                continue
            v21._rotate_pose_bone_armature_space(pb, applied_q)
            added_deg[bone_name] += applied_deg
            bpy.context.view_layer.update()

        surface_after = v25._weighted_surface_point(distal, target_world)
        after = (surface_after - target_world).length
        history.append((iteration, before, after))
        if abs(before - after) < 1e-5:
            break

    final_surface = v25._weighted_surface_point(distal, target_world)
    return {
        "surface_error": (final_surface - target_world).length,
        "surface_point": final_surface,
        "added_deg": added_deg,
        "history": history,
    }


def _run_pinch(xr, mpfb, cam, out, flap_center, camera_target):
    v25._remove_contact_markers()
    rows = v23._pose_seed(xr, mpfb, "Pinch Up_Armature")
    v19._remove_proxies()
    v22._paper_proxy(flap_center)

    desired_surface = v25._surface_targets(mpfb, flap_center)
    results = {}
    for digit in ("index", "thumb"):
        v23._marker(desired_surface[digit], "PinchTarget_" + digit, (0.12, 0.74, 0.24, 1.0))
        results[digit] = _surface_ccd_to_target(mpfb, v23.PINCH_CHAINS[digit], desired_surface[digit])

    index_surface = v25._weighted_surface_point("index_03_r", desired_surface["index"])
    thumb_surface = v25._weighted_surface_point("thumb_03_r", desired_surface["thumb"])
    index_face_error = (index_surface - desired_surface["index"]).length
    thumb_face_error = (thumb_surface - desired_surface["thumb"]).length
    index_center_error = (index_surface - flap_center).length
    thumb_center_error = (thumb_surface - flap_center).length
    visible_gap = (index_surface - thumb_surface).length
    max_added = max(max(result["added_deg"].values()) for result in results.values())

    print(
        "SURFACE_SERVO_V26_PINCH",
        "face_errors", [round(index_face_error, 6), round(thumb_face_error, 6)],
        "center_errors", [round(index_center_error, 6), round(thumb_center_error, 6)],
        "visible_gap", f"{visible_gap:.6f}",
        "surface_solver_errors", [round(results[d]["surface_error"], 6) for d in ("index", "thumb")],
        "max_added_deg", f"{max_added:.3f}",
    )

    pinch_camera_target = camera_target.lerp(flap_center, 0.50)
    v19._render(cam, out, "surface_v26_pinch", pinch_camera_target)

    if max(index_face_error, thumb_face_error) > v25.SURFACE_TARGET_TOLERANCE:
        raise RuntimeError("v26 visible fingertip missed fixed flap-face target")
    if max(index_center_error, thumb_center_error) > v25.SURFACE_CENTER_TOLERANCE:
        raise RuntimeError("v26 visible fingertip remained too far from flap center")
    if visible_gap > v25.SURFACE_GAP_TOLERANCE:
        raise RuntimeError("v26 visible pinch gap exceeds 10 mm")
    if max_added > SURFACE_CCD_EXTRA_BUDGET_DEG + 1e-3:
        raise RuntimeError("v26 exceeded anatomical CCD rotation budget")
    return rows, results


def _run() -> None:
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

    support_target_errors, _, _, _, _ = v25._run_support(
        xr, mpfb, cam, out, support_center, support_radius, support_axis, camera_target
    )
    if max(support_target_errors) > 0.030:
        raise RuntimeError("v26 support control regressed: " + repr(support_target_errors))

    _run_pinch(xr, mpfb, cam, out, flap_center, camera_target)
    print("MPFB_SURFACE_SERVO_V26_SUCCESS")


if __name__ == "__main__":
    try:
        _run()
    except BaseException as exc:
        print("MPFB_SURFACE_SERVO_V26_ERROR:", exc)
        traceback.print_exc()
        raise
