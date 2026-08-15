"""v44: isolate the remaining terminal pinky kink from the improved v43 local basis.

v42 established world-space cylindrical segment directions as a useful abstraction and v43
showed that a pinky-local MCP radial basis reduces the catastrophic chain fold. The remaining
visible red is now concentrated in the terminal pinky bend. This experiment freezes v43's
index/middle/ring/thumb and pinky local basis, keeps axial drop at the least aggressive
-0.08 candidate, and varies only the pinky distal arc angle.

No endpoint solving, CCD, tolerance relaxation, or production integration is introduced.
Macro/Meso silhouette remains authoritative.
"""
from __future__ import annotations

import importlib.util
import traceback
from pathlib import Path

import bpy

V43_PATH = Path(__file__).with_name("render_mpfb_pinky_basis_v43.py")
spec = importlib.util.spec_from_file_location("mpfb_v43", V43_PATH)
if spec is None or spec.loader is None:
    raise RuntimeError("could not load v43 helpers")
v43 = importlib.util.module_from_spec(spec)
spec.loader.exec_module(v43)
v42 = v43.v42
v35 = v43.v35
v23 = v43.v23
v38 = v43.v38
v19 = v43.v19
CHAINS = dict(v43.CHAINS)

PROFILE = "soft"
THUMB = "opposed"
PINKY_PROXIMAL = 20.0
PINKY_INTERMEDIATE = 62.0
PINKY_AXIAL = -0.08
DISTAL_VARIANTS = {
    "distal58": 58.0,
    "distal66": 66.0,
    "distal74": 74.0,
    "distal82": 82.0,
}


def _apply_candidate(arm, center, vessel_axis, distal_deg: float):
    global_near, global_side, axis = v42._arc_basis(arm, center, vessel_axis)
    rotations = {}

    for digit in ("index", "middle", "ring"):
        rotations[digit] = []
        for bone_name, angle_deg in zip(CHAINS[digit], v42.FINGER_ARCS[PROFILE][digit]):
            pb = arm.pose.bones.get(bone_name)
            if pb is None:
                raise RuntimeError("missing v44 finger bone " + bone_name)
            desired = v42._tangent_direction(global_near, global_side, axis, angle_deg, v42.AXIAL_DROP[digit])
            rotations[digit].append(v42._rotate_pose_bone_world_to_direction(arm, pb, desired))

    pinky_near, pinky_side, _ = v43._digit_local_basis(arm, center, axis, "pinky", global_side)
    rotations["pinky"] = []
    for bone_name, angle_deg in zip(
        CHAINS["pinky"],
        (PINKY_PROXIMAL, PINKY_INTERMEDIATE, distal_deg),
    ):
        pb = arm.pose.bones.get(bone_name)
        if pb is None:
            raise RuntimeError("missing v44 pinky bone " + bone_name)
        desired = v42._tangent_direction(pinky_near, pinky_side, axis, angle_deg, PINKY_AXIAL)
        rotations["pinky"].append(v42._rotate_pose_bone_world_to_direction(arm, pb, desired))

    rotations["thumb"] = []
    for bone_name, angle_deg in zip(CHAINS["thumb"], v42.THUMB_ARCS[THUMB]):
        pb = arm.pose.bones.get(bone_name)
        if pb is None:
            raise RuntimeError("missing v44 thumb bone " + bone_name)
        desired = v42._tangent_direction(global_near, -global_side, axis, abs(angle_deg), 0.08)
        rotations["thumb"].append(v42._rotate_pose_bone_world_to_direction(arm, pb, desired))

    bpy.context.view_layer.update()
    return rotations


def _run_candidate(xr, arm, cam, out: Path, label: str, distal_deg: float, camera_target) -> None:
    v35.v19._clear(arm)
    v23._pose_seed(xr, arm, "Cup_Armature")
    center, axis, inward, _ = v35._fixture_from_seed(arm, 1.0)
    proxy = v35.v33._proxy(center, axis, "PinkyDistalV44Vessel_" + label)
    focus = camera_target.lerp(center, 0.42)

    rotation_deg, root_shift = v35._orient_whole_hand(arm, center, axis, inward)
    rotations = _apply_candidate(arm, center, axis, distal_deg)
    v35.v19._render(cam, out, "pinky_distal_v44_" + label, focus)

    metrics = v38._metrics(arm, center, axis)
    print(
        "PINKY_DISTAL_V44_RESULT", label,
        "whole_rotation_deg", round(rotation_deg, 3),
        "root_shift", round(root_shift, 6),
        "palm_clearance", round(metrics["palm_clearance"], 6),
        "normal_alignment", round(metrics["normal_alignment"], 4),
        "min_tip_spacing", round(metrics["min_tip_spacing"], 6),
        "closest_pair", metrics["closest_pair"],
        "thumb_near_dot", round(metrics["thumb_near_dot"], 4),
        "finger_near_dots", [round(v, 4) for v in metrics["finger_near_dots"]],
        "pinky_rotation_deg", [round(v, 2) for v in rotations["pinky"]],
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

    for label, distal_deg in DISTAL_VARIANTS.items():
        v35._restore_world(arm, baseline)
        _run_candidate(xr, arm, cam, out, label, distal_deg, camera_target)

    v35._restore_world(arm, baseline)
    print("MPFB_PINKY_DISTAL_V44_SUCCESS")


if __name__ == "__main__":
    try:
        _run()
    except BaseException as exc:
        print("MPFB_PINKY_DISTAL_V44_ERROR:", exc)
        traceback.print_exc()
        raise
