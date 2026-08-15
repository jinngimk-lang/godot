"""v47: one deliberately artist-authored whole-hand support grasp.

Checkpoint 16 rejects further CCD, endpoint, local-axis, generic curl and rigid-orbit
parameter searches. v47 therefore authors one coherent support pose directly in the proven
world-space vessel frame. Palm placement comes from the v35 whole-hand approach; every
finger segment and the thumb are then given an explicit world-space direction chosen as a
single silhouette composition so fingers travel around the far contour while the thumb
opposes them on the near/upper side.

There is no optimizer, tolerance relaxation, contact target or parameter sweep. The output is
one fixed-camera candidate plus a true thumbnail render. Macro/Meso silhouette is the gate.
"""
from __future__ import annotations

import importlib.util
import traceback
from pathlib import Path

import bpy
from mathutils import Vector

V45_PATH = Path(__file__).with_name("render_mpfb_reference_wrap_v45.py")
spec = importlib.util.spec_from_file_location("mpfb_v45", V45_PATH)
if spec is None or spec.loader is None:
    raise RuntimeError("could not load v45 helpers")
v45 = importlib.util.module_from_spec(spec)
spec.loader.exec_module(v45)
v44 = v45.v44
v43 = v45.v43
v42 = v45.v42
v35 = v45.v35
v23 = v45.v23
v38 = v45.v38
CHAINS = dict(v45.CHAINS)

# Artist-authored world-frame coefficients: (near, side, axial).
# Negative near travels around the vessel away from the viewer-facing palm surface.
# Side progresses from approach direction to the far contour; the final segment of each
# finger turns past the side tangent instead of remaining a parallel prong.
AUTHORED_FINGERS = {
    "index": (
        (-0.28, 0.92, -0.02),
        (-0.82, 0.52, -0.04),
        (-0.88, -0.34, -0.05),
    ),
    "middle": (
        (-0.36, 0.86, -0.05),
        (-0.88, 0.38, -0.07),
        (-0.80, -0.48, -0.08),
    ),
    "ring": (
        (-0.46, 0.78, -0.08),
        (-0.92, 0.20, -0.10),
        (-0.70, -0.60, -0.11),
    ),
    "pinky": (
        (-0.54, 0.70, -0.11),
        (-0.94, 0.08, -0.13),
        (-0.62, -0.68, -0.14),
    ),
}

# Independent thumb opposition. It begins on the opposite lateral direction, crosses toward
# the near/top contact zone, then points inward toward the index side. This is intentionally
# authored separately rather than mirroring the four-finger chain.
AUTHORED_THUMB = (
    (-0.08, -0.88, 0.24),
    (0.58, -0.62, 0.28),
    (0.84, -0.24, 0.20),
)


def _direction(near: Vector, side: Vector, axis: Vector, coeffs) -> Vector:
    n, s, a = coeffs
    value = near * n + side * s + axis * a
    if value.length < 1e-7:
        raise RuntimeError("v47 degenerate authored direction")
    return value.normalized()


def _apply_authored_pose(arm, center: Vector, vessel_axis: Vector):
    near, side, axis = v42._arc_basis(arm, center, vessel_axis)
    rotations = {}

    for digit in ("index", "middle", "ring", "pinky"):
        rotations[digit] = []
        for bone_name, coeffs in zip(CHAINS[digit], AUTHORED_FINGERS[digit]):
            pb = arm.pose.bones.get(bone_name)
            if pb is None:
                raise RuntimeError("missing v47 finger bone " + bone_name)
            desired = _direction(near, side, axis, coeffs)
            rotations[digit].append(v42._rotate_pose_bone_world_to_direction(arm, pb, desired))

    rotations["thumb"] = []
    for bone_name, coeffs in zip(CHAINS["thumb"], AUTHORED_THUMB):
        pb = arm.pose.bones.get(bone_name)
        if pb is None:
            raise RuntimeError("missing v47 thumb bone " + bone_name)
        desired = _direction(near, side, axis, coeffs)
        rotations["thumb"].append(v42._rotate_pose_bone_world_to_direction(arm, pb, desired))

    bpy.context.view_layer.update()
    return rotations


def _render_thumbnail(cam, out: Path, focus: Vector) -> None:
    scene = bpy.context.scene
    old_x, old_y, old_pct = scene.render.resolution_x, scene.render.resolution_y, scene.render.resolution_percentage
    scene.render.resolution_x = 192
    scene.render.resolution_y = 108
    scene.render.resolution_percentage = 100
    try:
        v35.v19._render(cam, out, "authored_support_v47_thumbnail", focus)
    finally:
        scene.render.resolution_x = old_x
        scene.render.resolution_y = old_y
        scene.render.resolution_percentage = old_pct


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

    v35.v19._clear(arm)
    v23._pose_seed(xr, arm, "Cup_Armature")
    center, axis, inward, _ = v35._fixture_from_seed(arm, 1.0)
    proxy = v35.v33._proxy(center, axis, "AuthoredSupportV47Vessel")
    focus = camera_target.lerp(center, 0.42)

    whole_rotation_deg, root_shift = v35._orient_whole_hand(arm, center, axis, inward)
    rotations = _apply_authored_pose(arm, center, axis)

    v35.v19._render(cam, out, "authored_support_v47_full", focus)
    _render_thumbnail(cam, out, focus)

    metrics = v38._metrics(arm, center, axis)
    print(
        "AUTHORED_SUPPORT_V47_RESULT",
        "whole_rotation_deg", round(whole_rotation_deg, 3),
        "root_shift", round(root_shift, 6),
        "palm_clearance", round(metrics["palm_clearance"], 6),
        "normal_alignment", round(metrics["normal_alignment"], 4),
        "min_tip_spacing", round(metrics["min_tip_spacing"], 6),
        "closest_pair", metrics["closest_pair"],
        "thumb_near_dot", round(metrics["thumb_near_dot"], 4),
        "finger_near_dots", [round(v, 4) for v in metrics["finger_near_dots"]],
        "segment_rotation_deg", {k: [round(v, 2) for v in vals] for k, vals in rotations.items()},
    )

    bpy.data.objects.remove(proxy, do_unlink=True)
    print("MPFB_AUTHORED_SUPPORT_V47_SUCCESS")


if __name__ == "__main__":
    try:
        _run()
    except BaseException as exc:
        print("MPFB_AUTHORED_SUPPORT_V47_ERROR:", exc)
        traceback.print_exc()
        raise
