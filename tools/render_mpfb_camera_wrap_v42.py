"""v42: isolate camera-relative whole-hand azimuth before further finger editing.

v41 proved that explicit per-joint authored flexion alone still produces a claw-like
support silhouette. The palm is anatomically oriented toward the vessel, but every
finger remains exposed on the camera-facing side. This experiment changes exactly one
structural variable: rotate the already-oriented whole hand rigidly around the vertical
vessel axis before applying the unchanged v41 bottle_wrap pose.

If one azimuth produces a photographic wrap silhouette, it becomes the seed for cup
and bottle adaptation. If all five fail, stop tuning the current MPFB pose tables and
move to a genuinely artist-authored/pose-source workflow.
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
v35 = v41.v35
v23 = v41.v23
v38 = v41.v38

AZIMUTH_DEG = (-45.0, -25.0, 0.0, 25.0, 45.0)


def _rigid_azimuth(arm, center: Vector, axis: Vector, degrees: float) -> None:
    if abs(degrees) < 1e-6:
        return
    transform = (
        Matrix.Translation(center)
        @ Matrix.Rotation(math.radians(degrees), 4, axis.normalized())
        @ Matrix.Translation(-center)
    )
    v35.v34._rigid_world_transform(arm, transform)
    bpy.context.view_layer.update()


def _run_candidate(xr, arm, cam, out: Path, degrees: float, camera_target: Vector) -> None:
    v35.v19._clear(arm)
    v23._pose_seed(xr, arm, "Cup_Armature")
    center, axis, inward, _ = v35._fixture_from_seed(arm, 1.0)
    proxy = v35.v33._proxy(center, axis, "CameraWrapV42Vessel")
    focus = camera_target.lerp(center, 0.42)

    rotation_deg, root_shift = v35._orient_whole_hand(arm, center, axis, inward)
    _rigid_azimuth(arm, center, axis, degrees)
    v41._apply_artist_pose(arm, "bottle_wrap")

    label = ("neg" if degrees < 0 else "pos" if degrees > 0 else "zero") + str(int(abs(degrees)))
    v35.v19._render(cam, out, "camera_wrap_v42_" + label, focus)
    metrics = v38._metrics(arm, center, axis)
    print(
        "CAMERA_WRAP_V42_RESULT", label,
        "azimuth_deg", degrees,
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

    for degrees in AZIMUTH_DEG:
        v35._restore_world(arm, baseline)
        _run_candidate(xr, arm, cam, out, degrees, camera_target)

    v35._restore_world(arm, baseline)
    print("MPFB_CAMERA_WRAP_V42_SUCCESS")


if __name__ == "__main__":
    try:
        _run()
    except BaseException as exc:
        print("MPFB_CAMERA_WRAP_V42_ERROR:", exc)
        traceback.print_exc()
        raise
