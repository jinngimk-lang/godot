"""v39: mixed-axis authored grasp candidates after v38 visual rejection.

v38 isolated the local-axis family. Axis X preserved the most anatomically readable open
hand but did not wrap the vessel; axis Z produced the only obvious wrap direction but
collapsed into an over-curled claw. v39 tests the next falsifiable abstraction: use a
bounded Z+ flexion profile for visible closure, add only a small X-axis digit spread to
preserve progressive finger ordering, and vary thumb opposition independently.

No endpoint CCD or fingertip target optimizer is used. Visual Macro/Meso review remains
the acceptance gate. Staging only; no production runtime changes.
"""
from __future__ import annotations

import importlib.util
import math
import traceback
from pathlib import Path

import bpy
from mathutils import Quaternion, Vector

V38_PATH = Path(__file__).with_name("render_mpfb_authored_grasp_v38.py")
spec = importlib.util.spec_from_file_location("mpfb_v38", V38_PATH)
if spec is None or spec.loader is None:
    raise RuntimeError("could not load v38 helpers")
v38 = importlib.util.module_from_spec(spec)
spec.loader.exec_module(v38)
v35 = v38.v35
v23 = v38.v23

CHAINS = dict(v38.CHAINS)

# Three intentionally bounded closure profiles. The strongest v38 Z candidate used
# 34-62 degree authored rotations and visibly over-curled; v39 stays below that range.
FINGER_PROFILES = {
    "soft": {
        "index": (22.0, 18.0, 10.0),
        "middle": (26.0, 21.0, 12.0),
        "ring": (30.0, 24.0, 14.0),
        "pinky": (34.0, 27.0, 16.0),
    },
    "medium": {
        "index": (28.0, 23.0, 13.0),
        "middle": (32.0, 26.0, 15.0),
        "ring": (36.0, 29.0, 17.0),
        "pinky": (40.0, 32.0, 19.0),
    },
    "firm": {
        "index": (34.0, 27.0, 16.0),
        "middle": (38.0, 30.0, 18.0),
        "ring": (42.0, 33.0, 20.0),
        "pinky": (46.0, 36.0, 22.0),
    },
}

# Small secondary local-X offsets are deliberately much smaller than the flexion angles.
# They are not used to hit endpoints; they only test whether finger fan/order can be kept
# while Z supplies the visible wrap direction.
DIGIT_SPREAD_X = {
    "index": 7.0,
    "middle": 2.0,
    "ring": -3.0,
    "pinky": -8.0,
}

THUMB_VARIANTS = {
    # v38 Z+ used the opposite Z sign for the thumb and curled it too aggressively.
    # Keep two bounded alternatives so visual review can identify the useful opposition axis.
    "thumb_x": (0, -1.0, (18.0, 24.0, 16.0)),
    "thumb_z": (2, -1.0, (16.0, 22.0, 14.0)),
}


def _rot(pb, axis_index: int, degrees: float) -> None:
    pb.rotation_mode = "QUATERNION"
    axis = (Vector((1, 0, 0)), Vector((0, 1, 0)), Vector((0, 0, 1)))[axis_index]
    pb.rotation_quaternion = pb.rotation_quaternion @ Quaternion(axis, math.radians(degrees))


def _apply_mixed_grasp(arm, profile_name: str, thumb_variant: str) -> None:
    profile = FINGER_PROFILES[profile_name]
    for digit in ("index", "middle", "ring", "pinky"):
        chain = CHAINS[digit]
        amounts = profile[digit]
        for joint_i, (bone_name, amount) in enumerate(zip(chain, amounts)):
            pb = arm.pose.bones.get(bone_name)
            if pb is None:
                raise RuntimeError("missing v39 finger bone " + bone_name)
            # Z+ supplies the visible curl found in v38, but at a bounded magnitude.
            _rot(pb, 2, amount)
            # Only the proximal joint receives a small X fan so fingers do not collapse
            # into parallel tines. This intentionally avoids per-joint waypoint steering.
            if joint_i == 0:
                _rot(pb, 0, DIGIT_SPREAD_X[digit])

    thumb_axis, thumb_sign, thumb_amounts = THUMB_VARIANTS[thumb_variant]
    for bone_name, amount in zip(CHAINS["thumb"], thumb_amounts):
        pb = arm.pose.bones.get(bone_name)
        if pb is None:
            raise RuntimeError("missing v39 thumb bone " + bone_name)
        _rot(pb, thumb_axis, thumb_sign * amount)
    bpy.context.view_layer.update()


def _run_candidate(xr, arm, cam, out: Path, profile_name: str, thumb_variant: str, camera_target: Vector) -> None:
    label = f"{profile_name}_{thumb_variant}"
    v35.v19._clear(arm)
    v23._pose_seed(xr, arm, "Cup_Armature")
    center, axis, inward, _ = v35._fixture_from_seed(arm, 1.0)
    proxy = v35.v33._proxy(center, axis, "AuthoredGraspV39Vessel_" + label)
    focus = camera_target.lerp(center, 0.42)

    rotation_deg, root_shift = v35._orient_whole_hand(arm, center, axis, inward)
    _apply_mixed_grasp(arm, profile_name, thumb_variant)
    v35.v19._render(cam, out, "authored_grasp_v39_" + label, focus)
    metrics = v38._metrics(arm, center, axis)
    print(
        "AUTHORED_GRASP_V39_RESULT", label,
        "whole_rotation_deg", round(rotation_deg, 3),
        "root_shift", round(root_shift, 6),
        "palm_clearance", round(metrics["palm_clearance"], 6),
        "normal_alignment", round(metrics["normal_alignment"], 4),
        "min_tip_spacing", round(metrics["min_tip_spacing"], 6),
        "closest_pair", metrics["closest_pair"],
        "thumb_near_dot", round(metrics["thumb_near_dot"], 4),
        "finger_near_dots", [round(v, 4) for v in metrics["finger_near_dots"]],
    )
    bpy.data.objects.remove(proxy, do_unlink=True)


def _run() -> None:
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

    # 3 closure strengths x 2 independent thumb opposition choices = 6 candidates.
    for profile_name in ("soft", "medium", "firm"):
        for thumb_variant in ("thumb_x", "thumb_z"):
            v35._restore_world(arm, baseline)
            _run_candidate(xr, arm, cam, out, profile_name, thumb_variant, camera_target)

    v35._restore_world(arm, baseline)
    print("MPFB_AUTHORED_GRASP_V39_SUCCESS")


if __name__ == "__main__":
    try:
        _run()
    except BaseException as exc:
        print("MPFB_AUTHORED_GRASP_V39_ERROR:", exc)
        traceback.print_exc()
        raise
