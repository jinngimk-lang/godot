"""v41: artist-authored grasp in palm/world geometry after v40 local-axis rejection.

v40 proved that explicit per-joint imported-local XYZ tables are still the wrong
abstraction: technically valid candidates remained hovering/claw-like because the
meaning of local X/Y/Z varies across the imported GameEngine finger bones.

v41 keeps the successful v35 whole-hand/palm placement, but stops guessing local axes.
The *amount* of flexion is hand-authored per digit/joint.  The bend plane is derived
geometrically from each current bone segment toward the vessel center, then applied as
an armature-space rotation around the joint head.  MCP splay is a separate authored
correction.  This is deliberately not endpoint CCD: no target position is solved, no
error tolerance is relaxed, and no iterative optimizer is used.

Macro/Meso silhouette is authoritative.  Staging only.
"""
from __future__ import annotations

import importlib.util
import math
import traceback
from pathlib import Path

import bpy
from mathutils import Matrix, Vector

V40_PATH = Path(__file__).with_name("render_mpfb_anatomical_grasp_v40.py")
spec = importlib.util.spec_from_file_location("mpfb_v40", V40_PATH)
if spec is None or spec.loader is None:
    raise RuntimeError("could not load v40 helpers")
v40 = importlib.util.module_from_spec(spec)
spec.loader.exec_module(v40)
v39 = v40.v39
v38 = v40.v38
v35 = v40.v35
v23 = v40.v23
v19 = v35.v19
CHAINS = dict(v40.CHAINS)

# Degrees are explicitly art-directed, not solver outputs.  Progressive closure from
# index -> pinky avoids the four-parallel-fingers silhouette seen in v38-v40.
PROFILES = {
    "natural": {
        "index": (18.0, 34.0, 20.0),
        "middle": (22.0, 40.0, 24.0),
        "ring": (27.0, 45.0, 28.0),
        "pinky": (31.0, 49.0, 31.0),
        "thumb": (26.0, 34.0, 22.0),
    },
    "deep": {
        "index": (22.0, 39.0, 24.0),
        "middle": (27.0, 45.0, 28.0),
        "ring": (32.0, 50.0, 31.0),
        "pinky": (36.0, 54.0, 34.0),
        "thumb": (30.0, 39.0, 25.0),
    },
}

# Separate MCP fan, in degrees, around the palm-facing radial.  Signs are ordered so
# index opens slightly upward/away and pinky closes inward, matching a cylindrical grip.
SPLAY = {
    "compact": {"index": -3.0, "middle": -1.0, "ring": 2.0, "pinky": 5.0},
    "fan": {"index": -6.0, "middle": -2.0, "ring": 3.0, "pinky": 8.0},
}


def _rotate_pose_bone_about_head(arm, pb, axis_world: Vector, degrees: float) -> None:
    if abs(degrees) < 1e-6:
        return
    axis_arm = arm.matrix_world.to_3x3().inverted() @ axis_world
    if axis_arm.length < 1e-7:
        raise RuntimeError("v41 degenerate armature-space rotation axis")
    axis_arm.normalize()
    head = pb.head.copy()
    pivot = Matrix.Translation(head)
    unpivot = Matrix.Translation(-head)
    pb.matrix = pivot @ Matrix.Rotation(math.radians(degrees), 4, axis_arm) @ unpivot @ pb.matrix
    bpy.context.view_layer.update()


def _bend_toward_center(arm, pb, center: Vector, vessel_axis: Vector, degrees: float) -> None:
    # Work in world space so the imported bone-local XYZ convention cannot change the
    # semantic meaning of flexion.  The desired bend plane points the current segment
    # toward the cylinder's radial center, while ignoring axial height.
    head_w = arm.matrix_world @ pb.head
    tail_w = arm.matrix_world @ pb.tail
    segment = tail_w - head_w
    if segment.length < 1e-7:
        raise RuntimeError("v41 zero-length pose segment " + pb.name)
    segment.normalize()

    to_center = center - head_w
    axis = vessel_axis.normalized()
    to_center -= axis * to_center.dot(axis)
    # Remove the component along the segment; only the perpendicular bend direction
    # contributes to the hinge plane.
    to_center -= segment * to_center.dot(segment)
    if to_center.length < 1e-7:
        return
    to_center.normalize()
    hinge = segment.cross(to_center)
    if hinge.length < 1e-7:
        return
    hinge.normalize()
    _rotate_pose_bone_about_head(arm, pb, hinge, degrees)


def _apply_artist_pose(arm, center: Vector, vessel_axis: Vector, profile_name: str, splay_name: str) -> None:
    profile = PROFILES[profile_name]
    splay = SPLAY[splay_name]

    # First establish subtle MCP fan around the palm radial.  This is independent from
    # curl and prevents the parallel-prong silhouette that survived v38-v40.
    palm, _forward, _span, _normal = v35.v33._palm_frame(arm)
    radial = center - palm
    radial -= vessel_axis * radial.dot(vessel_axis)
    if radial.length < 1e-7:
        raise RuntimeError("v41 degenerate palm radial")
    radial.normalize()
    for digit in ("index", "middle", "ring", "pinky"):
        pb = arm.pose.bones.get(CHAINS[digit][0])
        if pb is None:
            raise RuntimeError("missing v41 MCP " + CHAINS[digit][0])
        _rotate_pose_bone_about_head(arm, pb, radial, splay[digit])

    # Then author progressive flexion toward the actual vessel center.  Re-evaluate the
    # pose after every joint because parent motion changes the child segment direction.
    for digit in ("index", "middle", "ring", "pinky"):
        for bone_name, degrees in zip(CHAINS[digit], profile[digit]):
            pb = arm.pose.bones.get(bone_name)
            if pb is None:
                raise RuntimeError("missing v41 finger bone " + bone_name)
            _bend_toward_center(arm, pb, center, vessel_axis, degrees)

    # Thumb opposition is authored separately and bends toward the opposite side of the
    # cylinder rather than sharing the four-finger splay model.
    for bone_name, degrees in zip(CHAINS["thumb"], profile["thumb"]):
        pb = arm.pose.bones.get(bone_name)
        if pb is None:
            raise RuntimeError("missing v41 thumb bone " + bone_name)
        _bend_toward_center(arm, pb, center, vessel_axis, degrees)
    bpy.context.view_layer.update()


def _run_candidate(xr, arm, cam, out: Path, profile_name: str, splay_name: str, camera_target: Vector) -> None:
    label = f"{profile_name}_{splay_name}"
    v35.v19._clear(arm)
    v23._pose_seed(xr, arm, "Cup_Armature")
    center, axis, inward, _ = v35._fixture_from_seed(arm, 1.0)
    proxy = v35.v33._proxy(center, axis, "ArtistGraspV41Vessel_" + label)
    focus = camera_target.lerp(center, 0.42)

    rotation_deg, root_shift = v35._orient_whole_hand(arm, center, axis, inward)
    _apply_artist_pose(arm, center, axis, profile_name, splay_name)
    v35.v19._render(cam, out, "artist_grasp_v41_" + label, focus)

    metrics = v38._metrics(arm, center, axis)
    print(
        "ARTIST_GRASP_V41_RESULT", label,
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

    for profile_name in ("natural", "deep"):
        for splay_name in ("compact", "fan"):
            v35._restore_world(arm, baseline)
            _run_candidate(xr, arm, cam, out, profile_name, splay_name, camera_target)

    v35._restore_world(arm, baseline)
    print("MPFB_ARTIST_GRASP_V41_SUCCESS")


if __name__ == "__main__":
    try:
        _run()
    except BaseException as exc:
        print("MPFB_ARTIST_GRASP_V41_ERROR:", exc)
        traceback.print_exc()
        raise
