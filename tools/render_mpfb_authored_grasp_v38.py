"""v38: authored support-grasp silhouette before any endpoint/contact optimization.

v37 proved that endpoint CCD, ordering permutations, and independent joint waypoints are
not a reliable grasp generator. This harness keeps the accepted v35 whole-hand frame and
then applies deterministic artist-authored local finger curls. It deliberately renders a
small axis/sign family because the MPFB GameEngine finger local bend axis is not assumed.
The winner is chosen by Macro/Meso silhouette, palm enclosure, thumb opposition, visible
finger ordering, and lack of self-intersection; no fingertip target error can make a pose
pass visually.

Staging only. No production runtime changes.
"""
from __future__ import annotations

import importlib.util
import math
import traceback
from pathlib import Path

import bpy
from mathutils import Quaternion, Vector

V35_PATH = Path(__file__).with_name("render_mpfb_canonical_grip_v35.py")
spec = importlib.util.spec_from_file_location("mpfb_v35", V35_PATH)
if spec is None or spec.loader is None:
    raise RuntimeError("could not load v35 helpers")
v35 = importlib.util.module_from_spec(spec)
spec.loader.exec_module(v35)
v23 = v35.v23

# Fixed authored flexion profile: strong proximal closure with softer distal curl.
# The thumb uses a separate opposition profile rather than copying the four fingers.
FINGER_FLEX_DEG = {
    "index": (34.0, 48.0, 36.0),
    "middle": (40.0, 54.0, 40.0),
    "ring": (44.0, 58.0, 44.0),
    "pinky": (48.0, 62.0, 46.0),
}
THUMB_FLEX_DEG = (28.0, 36.0, 30.0)
CHAINS = dict(v23.SUPPORT_CHAINS)
CHAINS["thumb"] = v23.PINCH_CHAINS["thumb"]


def _apply_local_axis_rotation(pb, axis_index: int, degrees: float) -> None:
    pb.rotation_mode = "QUATERNION"
    axis = [Vector((1, 0, 0)), Vector((0, 1, 0)), Vector((0, 0, 1))][axis_index]
    pb.rotation_quaternion = pb.rotation_quaternion @ Quaternion(axis, math.radians(degrees))


def _apply_authored_curl(arm, axis_index: int, sign: float) -> None:
    for digit in ("index", "middle", "ring", "pinky"):
        for bone_name, amount in zip(CHAINS[digit], FINGER_FLEX_DEG[digit]):
            pb = arm.pose.bones.get(bone_name)
            if pb is None:
                raise RuntimeError("missing authored-grasp bone " + bone_name)
            _apply_local_axis_rotation(pb, axis_index, sign * amount)
    # Oppose thumb with the opposite flexion sign; the whole-hand v35 frame already
    # positions the palm against the cylinder, so this is authored choreography only.
    for bone_name, amount in zip(CHAINS["thumb"], THUMB_FLEX_DEG):
        pb = arm.pose.bones.get(bone_name)
        if pb is None:
            raise RuntimeError("missing authored-grasp thumb bone " + bone_name)
        _apply_local_axis_rotation(pb, axis_index, -sign * amount)
    bpy.context.view_layer.update()


def _metrics(arm, center: Vector, axis: Vector):
    palm, _forward, _span, normal = v35.v33._palm_frame(arm)
    palm_radial = palm - center
    palm_radial -= axis * palm_radial.dot(axis)
    palm_clearance = abs(palm_radial.length - v35.VESSEL_RADIUS)
    min_spacing, closest_pair = v35.v33._tip_separation(arm)
    to_center = center - palm
    to_center -= axis * to_center.dot(axis)
    normal_alignment = 0.0 if to_center.length < 1e-6 else normal.normalized().dot(to_center.normalized())
    near, _side = v35._wrap_basis(arm, center, axis)
    thumb_dot, finger_dots = v35.v33._opposition_metrics(arm, center, axis, near)
    return {
        "palm_clearance": palm_clearance,
        "min_tip_spacing": min_spacing,
        "closest_pair": closest_pair,
        "normal_alignment": normal_alignment,
        "thumb_near_dot": thumb_dot,
        "finger_near_dots": finger_dots,
    }


def _run_candidate(xr, arm, cam, out: Path, vessel_sign: float, axis_index: int, curl_sign: float, camera_target: Vector):
    label = f"v{'p' if vessel_sign > 0 else 'n'}_axis{'XYZ'[axis_index]}_{'p' if curl_sign > 0 else 'n'}"
    v35.v19._clear(arm)
    v23._pose_seed(xr, arm, "Cup_Armature")
    center, axis, inward, _ = v35._fixture_from_seed(arm, vessel_sign)
    proxy = v35.v33._proxy(center, axis, "AuthoredGraspV38Vessel_" + label)
    focus = camera_target.lerp(center, 0.42)

    rotation_deg, root_shift = v35._orient_whole_hand(arm, center, axis, inward)
    _apply_authored_curl(arm, axis_index, curl_sign)
    v35.v19._render(cam, out, "authored_grasp_v38_" + label, focus)
    metrics = _metrics(arm, center, axis)
    print("AUTHORED_GRASP_V38_RESULT", label,
          "whole_rotation_deg", round(rotation_deg, 3),
          "root_shift", round(root_shift, 6),
          "palm_clearance", round(metrics["palm_clearance"], 6),
          "normal_alignment", round(metrics["normal_alignment"], 4),
          "min_tip_spacing", round(metrics["min_tip_spacing"], 6),
          "closest_pair", metrics["closest_pair"],
          "thumb_near_dot", round(metrics["thumb_near_dot"], 4),
          "finger_near_dots", [round(v, 4) for v in metrics["finger_near_dots"]])
    bpy.data.objects.remove(proxy, do_unlink=True)


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

    # Use the v35-positive vessel side first (the visually stronger root/palm family),
    # and sweep only the unknown local bend axis/sign. This is six authored poses, not
    # endpoint optimization. Visual review picks the axis and rejects the others.
    for axis_index in range(3):
        for curl_sign in (1.0, -1.0):
            v35._restore_world(arm, baseline)
            _run_candidate(xr, arm, cam, out, 1.0, axis_index, curl_sign, camera_target)

    v35._restore_world(arm, baseline)
    print("MPFB_AUTHORED_GRASP_V38_SUCCESS")


if __name__ == "__main__":
    try:
        _run()
    except BaseException as exc:
        print("MPFB_AUTHORED_GRASP_V38_ERROR:", exc)
        traceback.print_exc()
        raise
