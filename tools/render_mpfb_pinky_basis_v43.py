"""v43: isolate the remaining v42 pinky deformation with a digit-local arc basis.

v42 is the first MPFB support-hand experiment whose index/middle/ring silhouette visibly
improved at Macro/Meso scale. Its remaining dominant defect is concentrated in the pinky:
the chain twists even in the softer profile. This experiment therefore leaves the proven
v42 soft/opposed pose unchanged for index, middle, ring and thumb, and changes only the
pinky's cylindrical frame.

Hypothesis: one palm-global near/side basis is geometrically wrong for the pinky because its
MCP starts at a substantially different radial position around the vessel. A pinky-local
radial basis derived from the actual proximal-joint head should remove the twist while
preserving the useful world-space segment-direction abstraction.

No CCD, endpoint target, iterative optimizer, tolerance relaxation, or production runtime
integration is introduced. Macro/Meso visual evidence remains authoritative.
"""
from __future__ import annotations

import importlib.util
import traceback
from pathlib import Path

import bpy
from mathutils import Vector

V42_PATH = Path(__file__).with_name("render_mpfb_world_arc_grasp_v42.py")
spec = importlib.util.spec_from_file_location("mpfb_v42", V42_PATH)
if spec is None or spec.loader is None:
    raise RuntimeError("could not load v42 helpers")
v42 = importlib.util.module_from_spec(spec)
spec.loader.exec_module(v42)
v35 = v42.v35
v23 = v42.v23
v38 = v42.v38
v19 = v42.v19
CHAINS = dict(v42.CHAINS)

PROFILE = "soft"
THUMB = "opposed"

# The shared basis is the exact v42 baseline. Local candidates alter only the pinky basis
# and its axial slope, allowing the visual result to falsify a single geometric cause.
PINKY_VARIANTS = {
    "shared_baseline": {"local": False, "axial": v42.AXIAL_DROP["pinky"]},
    "local_drop08": {"local": True, "axial": -0.08},
    "local_drop10": {"local": True, "axial": -0.10},
    "local_drop12": {"local": True, "axial": -0.12},
}


def _digit_local_basis(arm, center: Vector, vessel_axis: Vector, digit: str, global_side: Vector):
    axis = vessel_axis.normalized()
    pb = arm.pose.bones.get(CHAINS[digit][0])
    if pb is None:
        raise RuntimeError("missing v43 proximal bone " + CHAINS[digit][0])
    head_w = arm.matrix_world @ pb.head
    near = head_w - center
    near -= axis * near.dot(axis)
    if near.length < 1e-7:
        raise RuntimeError("v43 degenerate digit radial " + digit)
    near.normalize()
    side = axis.cross(near)
    if side.length < 1e-7:
        raise RuntimeError("v43 degenerate digit tangent " + digit)
    side.normalize()
    if side.dot(global_side) < 0.0:
        side *= -1.0
    return near, side, axis


def _apply_candidate(arm, center: Vector, vessel_axis: Vector, variant_name: str):
    global_near, global_side, axis = v42._arc_basis(arm, center, vessel_axis)
    rotations = {}

    # Preserve v42 exactly for the three digits that visually improved.
    for digit in ("index", "middle", "ring"):
        rotations[digit] = []
        for bone_name, angle_deg in zip(CHAINS[digit], v42.FINGER_ARCS[PROFILE][digit]):
            pb = arm.pose.bones.get(bone_name)
            if pb is None:
                raise RuntimeError("missing v43 finger bone " + bone_name)
            desired = v42._tangent_direction(global_near, global_side, axis, angle_deg, v42.AXIAL_DROP[digit])
            rotations[digit].append(v42._rotate_pose_bone_world_to_direction(arm, pb, desired))

    variant = PINKY_VARIANTS[variant_name]
    if variant["local"]:
        pinky_near, pinky_side, _ = _digit_local_basis(arm, center, axis, "pinky", global_side)
    else:
        pinky_near, pinky_side = global_near, global_side
    rotations["pinky"] = []
    for bone_name, angle_deg in zip(CHAINS["pinky"], v42.FINGER_ARCS[PROFILE]["pinky"]):
        pb = arm.pose.bones.get(bone_name)
        if pb is None:
            raise RuntimeError("missing v43 pinky bone " + bone_name)
        desired = v42._tangent_direction(pinky_near, pinky_side, axis, angle_deg, variant["axial"])
        rotations["pinky"].append(v42._rotate_pose_bone_world_to_direction(arm, pb, desired))

    # Preserve v42 opposed thumb exactly.
    rotations["thumb"] = []
    for bone_name, angle_deg in zip(CHAINS["thumb"], v42.THUMB_ARCS[THUMB]):
        pb = arm.pose.bones.get(bone_name)
        if pb is None:
            raise RuntimeError("missing v43 thumb bone " + bone_name)
        desired = v42._tangent_direction(global_near, -global_side, axis, abs(angle_deg), 0.08)
        rotations["thumb"].append(v42._rotate_pose_bone_world_to_direction(arm, pb, desired))

    bpy.context.view_layer.update()
    return rotations


def _run_candidate(xr, arm, cam, out: Path, variant_name: str, camera_target: Vector) -> None:
    v35.v19._clear(arm)
    v23._pose_seed(xr, arm, "Cup_Armature")
    center, axis, inward, _ = v35._fixture_from_seed(arm, 1.0)
    proxy = v35.v33._proxy(center, axis, "PinkyBasisV43Vessel_" + variant_name)
    focus = camera_target.lerp(center, 0.42)

    rotation_deg, root_shift = v35._orient_whole_hand(arm, center, axis, inward)
    rotations = _apply_candidate(arm, center, axis, variant_name)
    v35.v19._render(cam, out, "pinky_basis_v43_" + variant_name, focus)

    metrics = v38._metrics(arm, center, axis)
    print(
        "PINKY_BASIS_V43_RESULT", variant_name,
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

    for variant_name in PINKY_VARIANTS:
        v35._restore_world(arm, baseline)
        _run_candidate(xr, arm, cam, out, variant_name, camera_target)

    v35._restore_world(arm, baseline)
    print("MPFB_PINKY_BASIS_V43_SUCCESS")


if __name__ == "__main__":
    try:
        _run()
    except BaseException as exc:
        print("MPFB_PINKY_BASIS_V43_ERROR:", exc)
        traceback.print_exc()
        raise
