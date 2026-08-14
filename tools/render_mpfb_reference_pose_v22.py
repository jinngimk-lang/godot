"""v22: fixed-target, bounded MPFB pose-transfer falsification harness.

v21 demonstrated a dangerous false positive: XR->MPFB direction transfer produced
small numeric pinch gaps while the rendered fingertips visibly folded/contorted.
Its proxies were also created from the already-posed fingertips, so contact could
look numerically good by construction.

This experiment keeps the continuous MPFB hand/wrist/forearm mesh, but changes the
validation harness in two ways:

1. Vessel/flap proxies are frozen from the neutral hand before any pose transfer.
   They never follow posed fingertips.
2. Candidate transfer variants bound and damp per-joint corrections. The full v21
   mapping is retained as a control, while conservative variants reduce distal
   rotations to preserve anatomy.

This is intentionally a preview/falsification tool, not production retargeting.
The winning condition is visual Macro/Meso improvement against the locked reference
family *and* honest fixed-target contact; numeric error alone cannot promote a pose.
"""
from __future__ import annotations

import importlib.util
import math
import traceback
from pathlib import Path

import bpy
from mathutils import Matrix, Quaternion, Vector

BASE = Path(__file__).with_name("render_mpfb_direction_pose_v21.py")
spec = importlib.util.spec_from_file_location("mpfb_v21", BASE)
if spec is None or spec.loader is None:
    raise RuntimeError("could not load v21 helpers")
v21 = importlib.util.module_from_spec(spec)
spec.loader.exec_module(v21)
v19 = v21.v19

# (proximal, intermediate, distal) semantic-direction correction weights.
# The full mapping is the v21 control. Bounded candidates deliberately preserve
# more MPFB anatomical rest orientation toward the fingertips.
VARIANTS = {
    "full_v21_control": {
        "finger": (1.0, 1.0, 1.0),
        "thumb": (1.0, 1.0, 1.0),
        "cap_deg": 180.0,
    },
    "bounded_75": {
        "finger": (0.82, 0.66, 0.48),
        "thumb": (0.78, 0.62, 0.46),
        "cap_deg": 75.0,
    },
    "bounded_60": {
        "finger": (0.68, 0.52, 0.36),
        "thumb": (0.66, 0.50, 0.34),
        "cap_deg": 60.0,
    },
}

ACTIONS = ("Cup_Armature", "Pinch Up_Armature")


def _scaled_rotation(q: Quaternion, weight: float, cap_deg: float) -> Quaternion:
    angle = q.angle
    if angle < 1e-8:
        return Quaternion((1.0, 0.0, 0.0, 0.0))
    cap = math.radians(cap_deg)
    cap_weight = min(1.0, cap / angle)
    final_weight = max(0.0, min(1.0, weight * cap_weight))
    return Quaternion((1.0, 0.0, 0.0, 0.0)).slerp(q, final_weight).normalized()


def _apply_bounded_directions(mpfb, semantic, variant):
    v19._clear(mpfb)
    rows = []
    for label in ("index", "middle", "ring", "pinky", "thumb"):
        _, dst_chain = v21.CHAINS[label]
        weights = variant["thumb"] if label == "thumb" else variant["finger"]
        for joint_i, (dst, local_dir) in enumerate(zip(dst_chain, semantic[label])):
            hand_rot = v21._frame_rotation(mpfb, "hand_r")
            desired = (hand_rot @ local_dir).normalized()
            pb = mpfb.pose.bones.get(dst)
            if pb is None:
                raise RuntimeError("missing MPFB pose bone " + dst)
            current = v21._segment_direction(mpfb, dst)
            raw_q = current.rotation_difference(desired)
            applied_q = _scaled_rotation(raw_q, weights[joint_i], variant["cap_deg"])
            raw_deg = math.degrees(raw_q.angle)
            applied_deg = math.degrees(applied_q.angle)
            rows.append((dst, raw_deg, applied_deg))
            v21._rotate_pose_bone_armature_space(pb, applied_q)
            bpy.context.view_layer.update()
    return rows


def _neutral_targets(mpfb):
    """Freeze interaction targets from the neutral MPFB anatomy.

    The support target is placed between palm and open fingertips so a successful
    pose must actually curl around a stationary vessel. The flap target is the
    neutral thumb/index midpoint; a successful pinch must move both digits toward
    the same stationary point instead of moving the target to follow the pose.
    """
    v19._clear(mpfb)
    bpy.context.view_layer.update()
    palm = v19._wp(mpfb, "hand_r")
    lowerarm = v19._wp(mpfb, "lowerarm_r")
    finger_tips = [v19._wp(mpfb, f"{name}_03_r", True) for name in ("index", "middle", "ring", "pinky")]
    mean_tips = sum(finger_tips, Vector()) / len(finger_tips)
    support_center = palm.lerp(mean_tips, 0.48)
    support_radius = 0.038
    support_axis = (palm - lowerarm).normalized()
    index_tip = v19._wp(mpfb, "index_03_r", True)
    thumb_tip = v19._wp(mpfb, "thumb_03_r", True)
    flap_center = index_tip.lerp(thumb_tip, 0.5)
    target = palm.lerp(mean_tips, 0.45)
    return support_center, support_radius, support_axis, flap_center, target


def _support_proxy(center, radius, axis):
    bpy.ops.mesh.primitive_cylinder_add(vertices=48, radius=radius, depth=0.20, location=center)
    obj = bpy.context.object
    obj.name = "PoseProxy_Vessel_Fixed"
    obj.data.materials.append(v19._mat("ReferenceVesselV22", (0.10, 0.23, 0.34, 1.0), 0.40))
    obj.rotation_euler = axis.to_track_quat("Z", "Y").to_euler()


def _paper_proxy(center):
    bpy.ops.mesh.primitive_cube_add(size=1, location=center)
    obj = bpy.context.object
    obj.name = "PoseProxy_Flap_Fixed"
    obj.scale = (0.024, 0.002, 0.016)
    obj.data.materials.append(v19._mat("ReferenceFlapV22", (0.74, 0.62, 0.38, 1.0), 0.82))


def _support_metrics(arm, center, radius):
    tips = [v19._wp(arm, f"{name}_03_r", True) for name in ("index", "middle", "ring", "pinky")]
    radial = [abs((tip - center).length - radius) for tip in tips]
    palm = v19._wp(arm, "hand_r")
    palm_clearance = abs((palm - center).length - radius)
    return radial, palm_clearance


def _pinch_metrics(arm, flap_center):
    index_tip = v19._wp(arm, "index_03_r", True)
    thumb_tip = v19._wp(arm, "thumb_03_r", True)
    midpoint = index_tip.lerp(thumb_tip, 0.5)
    gap = (index_tip - thumb_tip).length
    target_error = (midpoint - flap_center).length
    index_error = (index_tip - flap_center).length
    thumb_error = (thumb_tip - flap_center).length
    return gap, target_error, index_error, thumb_error


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

    support_center, support_radius, support_axis, flap_center, camera_target = _neutral_targets(mpfb)
    print("REFERENCE_V22_FIXED_SUPPORT", tuple(round(v, 6) for v in support_center), "radius", support_radius)
    print("REFERENCE_V22_FIXED_FLAP", tuple(round(v, 6) for v in flap_center))

    for action_name in ACTIONS:
        semantic = v21._semantic_directions(xr, action_name)
        for variant_name, variant in VARIANTS.items():
            v19._remove_proxies()
            rows = _apply_bounded_directions(mpfb, semantic, variant)
            max_raw = max(raw for _, raw, _ in rows)
            max_applied = max(applied for _, _, applied in rows)
            total_applied = sum(applied for _, _, applied in rows)

            if action_name.startswith("Cup"):
                _support_proxy(support_center, support_radius, support_axis)
                radial, palm_clearance = _support_metrics(mpfb, support_center, support_radius)
                print(
                    "REFERENCE_V22_SUPPORT",
                    variant_name,
                    "radial_errors",
                    [round(v, 6) for v in radial],
                    "palm_clearance",
                    f"{palm_clearance:.6f}",
                    "max_raw_deg",
                    f"{max_raw:.3f}",
                    "max_applied_deg",
                    f"{max_applied:.3f}",
                    "total_applied_deg",
                    f"{total_applied:.3f}",
                )
            else:
                _paper_proxy(flap_center)
                gap, target_error, index_error, thumb_error = _pinch_metrics(mpfb, flap_center)
                print(
                    "REFERENCE_V22_PINCH",
                    variant_name,
                    "gap",
                    f"{gap:.6f}",
                    "target_error",
                    f"{target_error:.6f}",
                    "index_error",
                    f"{index_error:.6f}",
                    "thumb_error",
                    f"{thumb_error:.6f}",
                    "max_raw_deg",
                    f"{max_raw:.3f}",
                    "max_applied_deg",
                    f"{max_applied:.3f}",
                    "total_applied_deg",
                    f"{total_applied:.3f}",
                )

            action = "cup" if action_name.startswith("Cup") else "pinch_up"
            v19._render(cam, out, f"reference_v22_{action}_{variant_name}", camera_target)

    print("MPFB_REFERENCE_V22_SUCCESS")


if __name__ == "__main__":
    try:
        _run()
    except BaseException as exc:
        print("MPFB_REFERENCE_V22_ERROR:", exc)
        traceback.print_exc()
        raise
