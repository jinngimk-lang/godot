"""v40: per-joint anatomical grasp table after v39 mixed-axis rejection.

v39 proved that one shared Z flexion family plus a proximal X fan still produces a
hovering/claw silhouette. v40 removes that shared-axis abstraction: each visible finger
joint receives an explicitly authored local-axis/sign/magnitude tuple. The candidates
are deliberately small variations around three anatomical tables so visual review can
identify which local joint families actually bend toward a human vessel wrap.

No endpoint CCD, no fingertip target chasing, and no relaxed contact tolerance are used.
Macro/Meso rendered silhouette remains the acceptance gate. Staging only.
"""
from __future__ import annotations

import importlib.util
import math
import traceback
from pathlib import Path

import bpy
from mathutils import Quaternion, Vector

V39_PATH = Path(__file__).with_name("render_mpfb_authored_grasp_v39.py")
spec = importlib.util.spec_from_file_location("mpfb_v39", V39_PATH)
if spec is None or spec.loader is None:
    raise RuntimeError("could not load v39 helpers")
v39 = importlib.util.module_from_spec(spec)
spec.loader.exec_module(v39)
v38 = v39.v38
v35 = v39.v35
v23 = v39.v23
CHAINS = dict(v39.CHAINS)

# Joint tuples are (axis_index, signed_degrees). Unlike v39, the proximal,
# intermediate and distal joints are not forced to share one local bend axis.
TABLES = {
    "prox_x_pip_z": {
        "index": ((0, 10.0), (2, 22.0), (2, 12.0)),
        "middle": ((0, 8.0), (2, 25.0), (2, 14.0)),
        "ring": ((0, 5.0), (2, 28.0), (2, 16.0)),
        "pinky": ((0, 2.0), (2, 30.0), (2, 18.0)),
    },
    "prox_z_pip_x": {
        "index": ((2, 18.0), (0, 12.0), (2, 9.0)),
        "middle": ((2, 20.0), (0, 14.0), (2, 10.0)),
        "ring": ((2, 22.0), (0, 16.0), (2, 11.0)),
        "pinky": ((2, 24.0), (0, 18.0), (2, 12.0)),
    },
    "alternating": {
        "index": ((0, 9.0), (2, 20.0), (0, 8.0)),
        "middle": ((0, 7.0), (2, 23.0), (0, 9.0)),
        "ring": ((0, 4.0), (2, 26.0), (0, 10.0)),
        "pinky": ((0, 1.0), (2, 28.0), (0, 11.0)),
    },
}

# Independent thumb base/opposition tables. The base joint gets the largest motion;
# later thumb joints close toward the vessel without mirroring the four fingers.
THUMBS = {
    "thumb_xy": ((0, -16.0), (1, 18.0), (2, -10.0)),
    "thumb_yz": ((1, 20.0), (2, -16.0), (2, -9.0)),
}


def _rot(pb, axis_index: int, degrees: float) -> None:
    pb.rotation_mode = "QUATERNION"
    axis = (Vector((1, 0, 0)), Vector((0, 1, 0)), Vector((0, 0, 1)))[axis_index]
    pb.rotation_quaternion = pb.rotation_quaternion @ Quaternion(axis, math.radians(degrees))


def _apply_table(arm, table_name: str, thumb_name: str) -> None:
    table = TABLES[table_name]
    for digit in ("index", "middle", "ring", "pinky"):
        for bone_name, (axis_index, degrees) in zip(CHAINS[digit], table[digit]):
            pb = arm.pose.bones.get(bone_name)
            if pb is None:
                raise RuntimeError("missing v40 finger bone " + bone_name)
            _rot(pb, axis_index, degrees)

    for bone_name, (axis_index, degrees) in zip(CHAINS["thumb"], THUMBS[thumb_name]):
        pb = arm.pose.bones.get(bone_name)
        if pb is None:
            raise RuntimeError("missing v40 thumb bone " + bone_name)
        _rot(pb, axis_index, degrees)
    bpy.context.view_layer.update()


def _run_candidate(xr, arm, cam, out: Path, table_name: str, thumb_name: str, camera_target: Vector) -> None:
    label = f"{table_name}_{thumb_name}"
    v35.v19._clear(arm)
    v23._pose_seed(xr, arm, "Cup_Armature")
    center, axis, inward, _ = v35._fixture_from_seed(arm, 1.0)
    proxy = v35.v33._proxy(center, axis, "AnatomicalGraspV40Vessel_" + label)
    focus = camera_target.lerp(center, 0.42)

    rotation_deg, root_shift = v35._orient_whole_hand(arm, center, axis, inward)
    _apply_table(arm, table_name, thumb_name)
    v35.v19._render(cam, out, "anatomical_grasp_v40_" + label, focus)
    metrics = v38._metrics(arm, center, axis)
    print(
        "ANATOMICAL_GRASP_V40_RESULT", label,
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

    for table_name in ("prox_x_pip_z", "prox_z_pip_x", "alternating"):
        for thumb_name in ("thumb_xy", "thumb_yz"):
            v35._restore_world(arm, baseline)
            _run_candidate(xr, arm, cam, out, table_name, thumb_name, camera_target)

    v35._restore_world(arm, baseline)
    print("MPFB_ANATOMICAL_GRASP_V40_SUCCESS")


if __name__ == "__main__":
    try:
        _run()
    except BaseException as exc:
        print("MPFB_ANATOMICAL_GRASP_V40_ERROR:", exc)
        traceback.print_exc()
        raise
