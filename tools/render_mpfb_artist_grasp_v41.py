"""v41: explicit artist-authored whole-hand vessel wraps.

v39 and v40 proved that a single bend axis policy cannot create a photographic grip on
this MPFB GameEngine rig. v41 deliberately stops treating fingers as four copies of the
same kinematic chain. Every visible phalanx gets an explicit pair of local rotations:
X for digit-specific fan/knuckle shaping and Z for wrap closure. The thumb has its own
X/Z opposition table. There is no CCD, endpoint solver, target chasing, or threshold
relaxation. The fixed-camera render is the acceptance evidence.

The three candidates are intentionally few and semantic:
- cup_wrap: broad, soft wrap for a paper cup;
- bottle_wrap: narrower, deeper wrap for a bottle;
- relaxed_wrap: a less closed sanity candidate to detect over-articulation.
"""
from __future__ import annotations

import importlib.util
import math
import traceback
from pathlib import Path

import bpy
from mathutils import Quaternion, Vector

V40_PATH = Path(__file__).with_name("render_mpfb_anatomical_grasp_v40.py")
spec = importlib.util.spec_from_file_location("mpfb_v40", V40_PATH)
if spec is None or spec.loader is None:
    raise RuntimeError("could not load v40 helpers")
v40 = importlib.util.module_from_spec(spec)
spec.loader.exec_module(v40)
v39 = v40.v39
v38 = v39.v38
v35 = v40.v35
v23 = v40.v23
CHAINS = dict(v40.CHAINS)

# Per joint values are (local X degrees, local Z degrees).
# X changes the visible fan/knuckle arc; Z supplies wrap. The values intentionally differ
# per digit and per joint rather than following one global rule.
POSES = {
    "relaxed_wrap": {
        "index": ((9.0, 18.0), (3.0, 22.0), (1.0, 10.0)),
        "middle": ((4.0, 21.0), (1.0, 25.0), (0.0, 12.0)),
        "ring": ((-4.0, 24.0), (-1.0, 28.0), (0.0, 14.0)),
        "pinky": ((-11.0, 27.0), (-3.0, 30.0), (-1.0, 16.0)),
        "thumb": ((-14.0, -12.0), (-18.0, -18.0), (-8.0, -12.0)),
    },
    "cup_wrap": {
        "index": ((12.0, 23.0), (5.0, 29.0), (2.0, 14.0)),
        "middle": ((5.0, 27.0), (2.0, 33.0), (1.0, 17.0)),
        "ring": ((-5.0, 31.0), (-2.0, 36.0), (-1.0, 19.0)),
        "pinky": ((-14.0, 34.0), (-5.0, 38.0), (-2.0, 21.0)),
        "thumb": ((-20.0, -15.0), (-24.0, -22.0), (-12.0, -15.0)),
    },
    "bottle_wrap": {
        "index": ((10.0, 28.0), (4.0, 37.0), (2.0, 20.0)),
        "middle": ((3.0, 32.0), (1.0, 41.0), (0.0, 23.0)),
        "ring": ((-7.0, 36.0), (-3.0, 44.0), (-1.0, 25.0)),
        "pinky": ((-16.0, 40.0), (-6.0, 46.0), (-2.0, 27.0)),
        "thumb": ((-24.0, -18.0), (-28.0, -26.0), (-15.0, -18.0)),
    },
}


def _rot(pb, axis_index: int, degrees: float) -> None:
    if abs(degrees) < 1e-6:
        return
    pb.rotation_mode = "QUATERNION"
    axis = (Vector((1, 0, 0)), Vector((0, 1, 0)), Vector((0, 0, 1)))[axis_index]
    pb.rotation_quaternion = pb.rotation_quaternion @ Quaternion(axis, math.radians(degrees))


def _apply_artist_pose(arm, pose_name: str) -> None:
    table = POSES[pose_name]
    for digit in ("index", "middle", "ring", "pinky", "thumb"):
        chain = CHAINS[digit]
        joint_table = table[digit]
        if len(chain) != len(joint_table):
            raise RuntimeError(f"v41 table/chain mismatch for {digit}")
        for bone_name, (x_deg, z_deg) in zip(chain, joint_table):
            pb = arm.pose.bones.get(bone_name)
            if pb is None:
                raise RuntimeError("missing v41 bone " + bone_name)
            # Apply fan/knuckle shaping first, then wrap closure. Keeping the order fixed is
            # intentional: these values are an authored pose, not an optimizer search.
            _rot(pb, 0, x_deg)
            _rot(pb, 2, z_deg)
    bpy.context.view_layer.update()


def _run_candidate(xr, arm, cam, out: Path, pose_name: str, camera_target: Vector) -> None:
    v35.v19._clear(arm)
    v23._pose_seed(xr, arm, "Cup_Armature")
    center, axis, inward, _ = v35._fixture_from_seed(arm, 1.0)
    proxy = v35.v33._proxy(center, axis, "ArtistGraspV41Vessel_" + pose_name)
    focus = camera_target.lerp(center, 0.42)

    rotation_deg, root_shift = v35._orient_whole_hand(arm, center, axis, inward)
    _apply_artist_pose(arm, pose_name)
    v35.v19._render(cam, out, "artist_grasp_v41_" + pose_name, focus)
    metrics = v38._metrics(arm, center, axis)
    print(
        "ARTIST_GRASP_V41_RESULT", pose_name,
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

    for pose_name in ("relaxed_wrap", "cup_wrap", "bottle_wrap"):
        v35._restore_world(arm, baseline)
        _run_candidate(xr, arm, cam, out, pose_name, camera_target)

    v35._restore_world(arm, baseline)
    print("MPFB_ARTIST_GRASP_V41_SUCCESS")


if __name__ == "__main__":
    try:
        _run()
    except BaseException as exc:
        print("MPFB_ARTIST_GRASP_V41_ERROR:", exc)
        traceback.print_exc()
        raise
