"""v40: per-joint anatomical grasp table after v39 visual rejection.

v38 showed that local X+ best preserves readable human hand volume but does not visibly
wrap a vessel when used for every joint. Local Z+ is the only tested direction that
visibly curls around the vessel, but using it at every joint creates long parallel claws.
v39 bounded Z+ and added proximal X fan offsets; it reduced catastrophic deformation but
still rendered four parallel hanging digits with weak thumb opposition.

v40 tests the next structural abstraction required by checkpoint 13: different joint
families get different authored bend axes. Proximal joints use X+ to preserve the hand
arc/knuckle volume; intermediate and distal joints use bounded Z+ to supply wrap. Thumb
opposition remains independent. No CCD, endpoint chasing, or relaxed target tolerance is
used. Macro/Meso rendered evidence is authoritative.
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

# Each tuple is (proximal X+, intermediate Z+, distal Z+). Values stay below the
# rejected v38 over-curl range and increase progressively index -> pinky.
POSE_TABLES = {
    "balanced": {
        "index": (18.0, 20.0, 10.0),
        "middle": (21.0, 23.0, 12.0),
        "ring": (24.0, 26.0, 14.0),
        "pinky": (27.0, 29.0, 16.0),
    },
    "proximal": {
        "index": (24.0, 16.0, 8.0),
        "middle": (27.0, 19.0, 10.0),
        "ring": (30.0, 22.0, 12.0),
        "pinky": (33.0, 25.0, 14.0),
    },
    "wrap": {
        "index": (14.0, 25.0, 13.0),
        "middle": (17.0, 28.0, 15.0),
        "ring": (20.0, 31.0, 17.0),
        "pinky": (23.0, 34.0, 19.0),
    },
}

THUMB_VARIANTS = {
    # Keep opposition bounded and independent of the four-finger table.
    "thumb_x": (0, -1.0, (20.0, 26.0, 17.0)),
    "thumb_z": (2, -1.0, (18.0, 24.0, 16.0)),
}


def _rot(pb, axis_index: int, degrees: float) -> None:
    pb.rotation_mode = "QUATERNION"
    axis = (Vector((1, 0, 0)), Vector((0, 1, 0)), Vector((0, 0, 1)))[axis_index]
    pb.rotation_quaternion = pb.rotation_quaternion @ Quaternion(axis, math.radians(degrees))


def _apply_anatomical_table(arm, table_name: str, thumb_variant: str) -> None:
    table = POSE_TABLES[table_name]
    for digit in ("index", "middle", "ring", "pinky"):
        chain = CHAINS[digit]
        prox_x, mid_z, distal_z = table[digit]
        amounts = (prox_x, mid_z, distal_z)
        axes = (0, 2, 2)
        for bone_name, axis_index, amount in zip(chain, axes, amounts):
            pb = arm.pose.bones.get(bone_name)
            if pb is None:
                raise RuntimeError("missing v40 finger bone " + bone_name)
            _rot(pb, axis_index, amount)

    thumb_axis, thumb_sign, thumb_amounts = THUMB_VARIANTS[thumb_variant]
    for bone_name, amount in zip(CHAINS["thumb"], thumb_amounts):
        pb = arm.pose.bones.get(bone_name)
        if pb is None:
            raise RuntimeError("missing v40 thumb bone " + bone_name)
        _rot(pb, thumb_axis, thumb_sign * amount)
    bpy.context.view_layer.update()


def _run_candidate(xr, arm, cam, out: Path, table_name: str, thumb_variant: str, camera_target: Vector) -> None:
    label = f"{table_name}_{thumb_variant}"
    v35.v19._clear(arm)
    v23._pose_seed(xr, arm, "Cup_Armature")
    center, axis, inward, _ = v35._fixture_from_seed(arm, 1.0)
    proxy = v35.v33._proxy(center, axis, "AnatomicalGraspV40Vessel_" + label)
    focus = camera_target.lerp(center, 0.42)

    rotation_deg, root_shift = v35._orient_whole_hand(arm, center, axis, inward)
    _apply_anatomical_table(arm, table_name, thumb_variant)
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

    # Three per-joint balance tables x two independent thumb axes = six candidates.
    for table_name in ("balanced", "proximal", "wrap"):
        for thumb_variant in ("thumb_x", "thumb_z"):
            v35._restore_world(arm, baseline)
            _run_candidate(xr, arm, cam, out, table_name, thumb_variant, camera_target)

    v35._restore_world(arm, baseline)
    print("MPFB_ANATOMICAL_GRASP_V40_SUCCESS")


if __name__ == "__main__":
    try:
        _run()
    except BaseException as exc:
        print("MPFB_ANATOMICAL_GRASP_V40_ERROR:", exc)
        traceback.print_exc()
        raise
