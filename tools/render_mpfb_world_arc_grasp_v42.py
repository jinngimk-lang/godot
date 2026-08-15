"""v42: world-space cylindrical-arc grasp after v41 artist-axis rejection.

v41 still produced straight index/middle fingers plus catastrophic ring/pinky twists even
though every bend was computed in world space. The failure shows that rotating an imported
pose bone by an angle around a derived hinge remains too dependent on each bone's existing
orientation/roll and parent deformation.

v42 removes angle-table semantics entirely. After the proven v35 whole-hand placement, each
phalanx is pointed toward an explicit *world-space desired segment direction* sampled from a
cylindrical wrap arc. A shortest-arc quaternion aligns the current world segment to that
world direction about the joint head. The imported local X/Y/Z convention therefore cannot
change the meaning of the pose.

This is not endpoint CCD: there is no positional target, error tolerance, iterative solver,
or relaxed contact gate. Macro/Meso silhouette remains authoritative. Staging only.
"""
from __future__ import annotations

import importlib.util
import math
import traceback
from pathlib import Path

import bpy
from mathutils import Matrix, Vector

V41_PATH = Path(__file__).with_name("render_mpfb_artist_grasp_v41.py")
spec = importlib.util.spec_from_file_location("mpfb_v41", V41_PATH)
if spec is None or spec.loader is None:
    raise RuntimeError("could not load v41 helpers")
v41 = importlib.util.module_from_spec(spec)
spec.loader.exec_module(v41)
v40 = v41.v40
v38 = v41.v38
v35 = v41.v35
v23 = v41.v23
v19 = v41.v19
CHAINS = dict(v41.CHAINS)

# Arc angles describe where the *tangent direction* of each phalanx sits around the
# cylinder. Progressive angles produce a real wrap silhouette rather than parallel prongs.
# The second profile adds only bounded closure; it does not change the abstraction.
FINGER_ARCS = {
    "soft": {
        "index": (12.0, 42.0, 72.0),
        "middle": (15.0, 48.0, 82.0),
        "ring": (18.0, 55.0, 94.0),
        "pinky": (20.0, 62.0, 106.0),
    },
    "wrap": {
        "index": (16.0, 50.0, 84.0),
        "middle": (19.0, 57.0, 96.0),
        "ring": (22.0, 64.0, 108.0),
        "pinky": (24.0, 70.0, 118.0),
    },
}

# Index sits above pinky in the canonical frame. Small axial drops separate the fingers
# without creating the fan/claw artifact from earlier local-axis experiments.
AXIAL_DROP = {"index": -0.02, "middle": -0.06, "ring": -0.10, "pinky": -0.14}

# Thumb takes the opposite side of the cylinder. Two bounded opposition depths let visual
# review choose between a gentle and stronger opposition without an optimizer.
THUMB_ARCS = {
    "gentle": (-18.0, -48.0, -76.0),
    "opposed": (-24.0, -58.0, -92.0),
}


def _world_segment(arm, pb) -> Vector:
    head = arm.matrix_world @ pb.head
    tail = arm.matrix_world @ pb.tail
    seg = tail - head
    if seg.length < 1e-7:
        raise RuntimeError("v42 zero-length segment " + pb.name)
    return seg.normalized()


def _rotate_pose_bone_world_to_direction(arm, pb, desired_world: Vector) -> float:
    desired = desired_world.normalized()
    current = _world_segment(arm, pb)
    dot = max(-1.0, min(1.0, current.dot(desired)))
    angle_deg = math.degrees(math.acos(dot))
    if angle_deg < 0.01:
        return angle_deg

    # Shortest world-space rotation from current segment to desired segment.
    q_world = current.rotation_difference(desired)
    r_world = q_world.to_matrix().to_4x4()
    world_basis = arm.matrix_world.to_3x3()
    r_arm3 = world_basis.inverted() @ r_world.to_3x3() @ world_basis
    r_arm = r_arm3.to_4x4()

    head = pb.head.copy()
    pb.matrix = Matrix.Translation(head) @ r_arm @ Matrix.Translation(-head) @ pb.matrix
    bpy.context.view_layer.update()
    return angle_deg


def _arc_basis(arm, center: Vector, vessel_axis: Vector):
    near, side = v35._wrap_basis(arm, center, vessel_axis)
    axis = vessel_axis.normalized()
    # Make side point roughly with the currently extended index finger. This preserves
    # the already-successful whole-hand approach direction while defining wrap sign once.
    index_pb = arm.pose.bones.get(CHAINS["index"][0])
    if index_pb is None:
        raise RuntimeError("missing v42 index proximal")
    if _world_segment(arm, index_pb).dot(side) < 0.0:
        side *= -1.0
    return near.normalized(), side.normalized(), axis


def _tangent_direction(near: Vector, side: Vector, axis: Vector, angle_deg: float, axial: float) -> Vector:
    a = math.radians(angle_deg)
    # Radial at angle a is near*cos(a) + side*sin(a); derivative is cylindrical tangent.
    tangent = (-near * math.sin(a)) + (side * math.cos(a))
    direction = tangent + axis * axial
    if direction.length < 1e-7:
        raise RuntimeError("v42 degenerate tangent")
    return direction.normalized()


def _apply_world_arc_pose(arm, center: Vector, vessel_axis: Vector, profile_name: str, thumb_name: str):
    near, side, axis = _arc_basis(arm, center, vessel_axis)
    rotations = {}

    for digit in ("index", "middle", "ring", "pinky"):
        rotations[digit] = []
        axial = AXIAL_DROP[digit]
        for bone_name, angle_deg in zip(CHAINS[digit], FINGER_ARCS[profile_name][digit]):
            pb = arm.pose.bones.get(bone_name)
            if pb is None:
                raise RuntimeError("missing v42 finger bone " + bone_name)
            desired = _tangent_direction(near, side, axis, angle_deg, axial)
            rotations[digit].append(_rotate_pose_bone_world_to_direction(arm, pb, desired))

    rotations["thumb"] = []
    # Thumb travels the opposite circumference direction. Reverse side and keep a small
    # upward axial component so it visibly opposes the index rather than hanging below it.
    for bone_name, angle_deg in zip(CHAINS["thumb"], THUMB_ARCS[thumb_name]):
        pb = arm.pose.bones.get(bone_name)
        if pb is None:
            raise RuntimeError("missing v42 thumb bone " + bone_name)
        desired = _tangent_direction(near, -side, axis, abs(angle_deg), 0.08)
        rotations["thumb"].append(_rotate_pose_bone_world_to_direction(arm, pb, desired))

    bpy.context.view_layer.update()
    return rotations


def _run_candidate(xr, arm, cam, out: Path, profile_name: str, thumb_name: str, camera_target: Vector) -> None:
    label = f"{profile_name}_{thumb_name}"
    v35.v19._clear(arm)
    v23._pose_seed(xr, arm, "Cup_Armature")
    center, axis, inward, _ = v35._fixture_from_seed(arm, 1.0)
    proxy = v35.v33._proxy(center, axis, "WorldArcV42Vessel_" + label)
    focus = camera_target.lerp(center, 0.42)

    rotation_deg, root_shift = v35._orient_whole_hand(arm, center, axis, inward)
    rotations = _apply_world_arc_pose(arm, center, axis, profile_name, thumb_name)
    v35.v19._render(cam, out, "world_arc_v42_" + label, focus)

    metrics = v38._metrics(arm, center, axis)
    print(
        "WORLD_ARC_V42_RESULT", label,
        "whole_rotation_deg", round(rotation_deg, 3),
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

    for profile_name in ("soft", "wrap"):
        for thumb_name in ("gentle", "opposed"):
            v35._restore_world(arm, baseline)
            _run_candidate(xr, arm, cam, out, profile_name, thumb_name, camera_target)

    v35._restore_world(arm, baseline)
    print("MPFB_WORLD_ARC_V42_SUCCESS")


if __name__ == "__main__":
    try:
        _run()
    except BaseException as exc:
        print("MPFB_WORLD_ARC_V42_ERROR:", exc)
        traceback.print_exc()
        raise
