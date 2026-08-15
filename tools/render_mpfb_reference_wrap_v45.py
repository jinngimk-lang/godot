"""v45: reference-derived whole-hand placement + stronger thumb opposition.

Checkpoint 15 froze the useful v44 world-space finger morphology (including pinky distal66)
and identified the remaining Macro/Meso failure as whole-hand vessel enclosure rather than
another distal-joint problem. This experiment therefore changes only the rigid whole-hand
orbit around the upright vessel plus a stronger, explicitly opposed thumb arc.

Two signed orbit hypotheses are rendered from the same fixed camera. Fingers/pinky keep the
v44 world-space segment directions; no CCD, endpoint target solving, tolerance relaxation,
or material polish is introduced. Thumbnail silhouette is authoritative.
"""
from __future__ import annotations

import importlib.util
import math
import traceback
from pathlib import Path

import bpy
from mathutils import Matrix

V44_PATH = Path(__file__).with_name("render_mpfb_pinky_distal_v44.py")
spec = importlib.util.spec_from_file_location("mpfb_v44", V44_PATH)
if spec is None or spec.loader is None:
    raise RuntimeError("could not load v44 helpers")
v44 = importlib.util.module_from_spec(spec)
spec.loader.exec_module(v44)
v43 = v44.v43
v42 = v44.v42
v35 = v44.v35
v23 = v44.v23
v38 = v44.v38
CHAINS = dict(v44.CHAINS)

PROFILE = "soft"
PINKY_PROXIMAL = v44.PINKY_PROXIMAL
PINKY_INTERMEDIATE = v44.PINKY_INTERMEDIATE
PINKY_DISTAL = 66.0
PINKY_AXIAL = v44.PINKY_AXIAL

# The only structural variable in this experiment: orbit the already-oriented whole hand
# around the vessel so visible fingers can move toward/behind the far contour. A tiny upward
# shift approximates the approved references' higher thumb contact zone.
CANDIDATES = {
    "orbit_plus22": {"orbit_deg": 22.0, "axial_shift": 0.016},
    "orbit_minus22": {"orbit_deg": -22.0, "axial_shift": 0.016},
}

# Stronger opposition than v42 "opposed" (-24/-58/-92), but still bounded and authored.
THUMB_ARC = (30.0, 70.0, 108.0)
THUMB_AXIAL = 0.11


def _orbit_whole_hand(arm, center, axis, orbit_deg: float, axial_shift: float) -> None:
    rot = Matrix.Rotation(math.radians(orbit_deg), 4, axis.normalized())
    about_center = Matrix.Translation(center) @ rot @ Matrix.Translation(-center)
    v35.v34._rigid_world_transform(arm, about_center)
    if abs(axial_shift) > 1e-8:
        v35.v34._rigid_world_transform(arm, Matrix.Translation(axis.normalized() * axial_shift))
    bpy.context.view_layer.update()


def _apply_frozen_v44_pose(arm, center, vessel_axis):
    global_near, global_side, axis = v42._arc_basis(arm, center, vessel_axis)
    rotations = {}

    # Freeze the useful v42 soft morphology for the three main fingers.
    for digit in ("index", "middle", "ring"):
        rotations[digit] = []
        for bone_name, angle_deg in zip(CHAINS[digit], v42.FINGER_ARCS[PROFILE][digit]):
            pb = arm.pose.bones.get(bone_name)
            if pb is None:
                raise RuntimeError("missing v45 finger bone " + bone_name)
            desired = v42._tangent_direction(global_near, global_side, axis, angle_deg, v42.AXIAL_DROP[digit])
            rotations[digit].append(v42._rotate_pose_bone_world_to_direction(arm, pb, desired))

    # Freeze v44's cleaned pinky basis and distal66 morphology.
    pinky_near, pinky_side, _ = v43._digit_local_basis(arm, center, axis, "pinky", global_side)
    rotations["pinky"] = []
    for bone_name, angle_deg in zip(
        CHAINS["pinky"],
        (PINKY_PROXIMAL, PINKY_INTERMEDIATE, PINKY_DISTAL),
    ):
        pb = arm.pose.bones.get(bone_name)
        if pb is None:
            raise RuntimeError("missing v45 pinky bone " + bone_name)
        desired = v42._tangent_direction(pinky_near, pinky_side, axis, angle_deg, PINKY_AXIAL)
        rotations["pinky"].append(v42._rotate_pose_bone_world_to_direction(arm, pb, desired))

    # The thumb is the only digit whose authored segment directions change in v45.
    rotations["thumb"] = []
    for bone_name, angle_deg in zip(CHAINS["thumb"], THUMB_ARC):
        pb = arm.pose.bones.get(bone_name)
        if pb is None:
            raise RuntimeError("missing v45 thumb bone " + bone_name)
        desired = v42._tangent_direction(global_near, -global_side, axis, angle_deg, THUMB_AXIAL)
        rotations["thumb"].append(v42._rotate_pose_bone_world_to_direction(arm, pb, desired))

    bpy.context.view_layer.update()
    return rotations


def _run_candidate(xr, arm, cam, out: Path, label: str, cfg: dict, camera_target) -> None:
    v35.v19._clear(arm)
    v23._pose_seed(xr, arm, "Cup_Armature")
    center, axis, inward, _ = v35._fixture_from_seed(arm, 1.0)
    proxy = v35.v33._proxy(center, axis, "ReferenceWrapV45Vessel_" + label)
    focus = camera_target.lerp(center, 0.42)

    rotation_deg, root_shift = v35._orient_whole_hand(arm, center, axis, inward)
    _orbit_whole_hand(arm, center, axis, cfg["orbit_deg"], cfg["axial_shift"])
    rotations = _apply_frozen_v44_pose(arm, center, axis)
    v35.v19._render(cam, out, "reference_wrap_v45_" + label, focus)

    metrics = v38._metrics(arm, center, axis)
    print(
        "REFERENCE_WRAP_V45_RESULT", label,
        "whole_rotation_deg", round(rotation_deg, 3),
        "root_shift", round(root_shift, 6),
        "orbit_deg", cfg["orbit_deg"],
        "axial_shift", cfg["axial_shift"],
        "palm_clearance", round(metrics["palm_clearance"], 6),
        "normal_alignment", round(metrics["normal_alignment"], 4),
        "min_tip_spacing", round(metrics["min_tip_spacing"], 6),
        "closest_pair", metrics["closest_pair"],
        "thumb_near_dot", round(metrics["thumb_near_dot"], 4),
        "finger_near_dots", [round(v, 4) for v in metrics["finger_near_dots"]],
        "thumb_rotation_deg", [round(v, 2) for v in rotations["thumb"]],
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

    for label, cfg in CANDIDATES.items():
        v35._restore_world(arm, baseline)
        _run_candidate(xr, arm, cam, out, label, cfg, camera_target)

    v35._restore_world(arm, baseline)
    print("MPFB_REFERENCE_WRAP_V45_SUCCESS")


if __name__ == "__main__":
    try:
        _run()
    except BaseException as exc:
        print("MPFB_REFERENCE_WRAP_V45_ERROR:", exc)
        traceback.print_exc()
        raise
