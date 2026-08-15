"""v48: one reference-view authored support grasp derived from the rejected v47 frame.

v47 proved that late distal turning leaves index/middle/ring as parallel prongs. v48 keeps the
same continuous MPFB limb, vessel fixture, camera, and whole-hand placement, but authors a
single stronger *early* enclosure: proximal/intermediate segments turn around the cylinder
before the distal joint, fingers cross the visible vessel contour at progressively lower
heights, and the thumb is lifted toward a near/upper opposition contact.

This is one candidate, not a parameter search. Macro thumbnail silhouette is the gate.
"""
from __future__ import annotations

import importlib.util
import traceback
from pathlib import Path

import bpy
from mathutils import Vector

V47_PATH = Path(__file__).with_name("render_mpfb_authored_support_v47.py")
spec = importlib.util.spec_from_file_location("mpfb_v47", V47_PATH)
if spec is None or spec.loader is None:
    raise RuntimeError("could not load v47 helpers")
v47 = importlib.util.module_from_spec(spec)
spec.loader.exec_module(v47)
v45 = v47.v45
v42 = v47.v42
v35 = v47.v35
v23 = v47.v23
v38 = v47.v38
CHAINS = dict(v47.CHAINS)

# Deliberately early enclosure: each chain turns around the cylinder at proximal/intermediate
# rather than projecting toward the camera until the distal. Axial values stagger crossings.
REFERENCE_FINGERS = {
    "index": (
        (-0.62, 0.68, -0.01),
        (-0.98, 0.05, -0.03),
        (-0.62, -0.72, -0.04),
    ),
    "middle": (
        (-0.70, 0.58, -0.04),
        (-0.99, -0.05, -0.06),
        (-0.50, -0.82, -0.07),
    ),
    "ring": (
        (-0.76, 0.48, -0.07),
        (-0.96, -0.20, -0.09),
        (-0.38, -0.88, -0.10),
    ),
    "pinky": (
        (-0.80, 0.38, -0.10),
        (-0.90, -0.32, -0.12),
        (-0.28, -0.92, -0.13),
    ),
}

# Move opposition visibly upward relative to v47 while keeping it on the near side. The thumb
# gets its own composition instead of mirroring the finger arcs.
REFERENCE_THUMB = (
    (0.10, -0.72, 0.48),
    (0.72, -0.38, 0.46),
    (0.92, -0.05, 0.34),
)


def _direction(near: Vector, side: Vector, axis: Vector, coeffs) -> Vector:
    n, s, a = coeffs
    value = near * n + side * s + axis * a
    if value.length < 1e-7:
        raise RuntimeError("v48 degenerate direction")
    return value.normalized()


def _apply_pose(arm, center: Vector, vessel_axis: Vector):
    near, side, axis = v42._arc_basis(arm, center, vessel_axis)
    rotations = {}
    for digit in ("index", "middle", "ring", "pinky"):
        rotations[digit] = []
        for bone_name, coeffs in zip(CHAINS[digit], REFERENCE_FINGERS[digit]):
            pb = arm.pose.bones.get(bone_name)
            if pb is None:
                raise RuntimeError("missing v48 finger bone " + bone_name)
            rotations[digit].append(
                v42._rotate_pose_bone_world_to_direction(arm, pb, _direction(near, side, axis, coeffs))
            )
    rotations["thumb"] = []
    for bone_name, coeffs in zip(CHAINS["thumb"], REFERENCE_THUMB):
        pb = arm.pose.bones.get(bone_name)
        if pb is None:
            raise RuntimeError("missing v48 thumb bone " + bone_name)
        rotations["thumb"].append(
            v42._rotate_pose_bone_world_to_direction(arm, pb, _direction(near, side, axis, coeffs))
        )
    bpy.context.view_layer.update()
    return rotations


def _render_thumbnail(cam, out: Path, focus: Vector) -> None:
    scene = bpy.context.scene
    old_x, old_y, old_pct = scene.render.resolution_x, scene.render.resolution_y, scene.render.resolution_percentage
    scene.render.resolution_x = 192
    scene.render.resolution_y = 108
    scene.render.resolution_percentage = 100
    try:
        v35.v19._render(cam, out, "reference_view_v48_thumbnail", focus)
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
    proxy = v35.v33._proxy(center, axis, "ReferenceViewV48Vessel")
    focus = camera_target.lerp(center, 0.42)

    whole_rotation_deg, root_shift = v35._orient_whole_hand(arm, center, axis, inward)
    rotations = _apply_pose(arm, center, axis)

    v35.v19._render(cam, out, "reference_view_v48_full", focus)
    _render_thumbnail(cam, out, focus)

    metrics = v38._metrics(arm, center, axis)
    print(
        "REFERENCE_VIEW_V48_RESULT",
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
    print("MPFB_REFERENCE_VIEW_V48_SUCCESS")


if __name__ == "__main__":
    try:
        _run()
    except BaseException as exc:
        print("MPFB_REFERENCE_VIEW_V48_ERROR:", exc)
        traceback.print_exc()
        raise
