"""v46: narrow the v45 whole-hand orbit after visual bracketing.

v45 established two visual failure endpoints with all digit morphology frozen:
+22 degrees remained too open in front of the vessel, while -22 degrees pushed the hand
so far around the cylinder that palm/fingers became largely occluded. This experiment
changes only the rigid whole-hand orbit and samples two intermediate negative angles.

The stronger v45 thumb opposition, v42 soft index/middle/ring morphology, and v44 distal66
pinky remain frozen. No endpoint solving, CCD, contact-tolerance changes, or material work.
"""
from __future__ import annotations

import importlib.util
import traceback
from pathlib import Path

import bpy

V45_PATH = Path(__file__).with_name("render_mpfb_reference_wrap_v45.py")
spec = importlib.util.spec_from_file_location("mpfb_v45", V45_PATH)
if spec is None or spec.loader is None:
    raise RuntimeError("could not load v45 helpers")
v45 = importlib.util.module_from_spec(spec)
spec.loader.exec_module(v45)
v35 = v45.v35
v23 = v45.v23
v38 = v45.v38

CANDIDATES = {
    "orbit_minus08": {"orbit_deg": -8.0, "axial_shift": 0.016},
    "orbit_minus14": {"orbit_deg": -14.0, "axial_shift": 0.016},
}


def _run_candidate(xr, arm, cam, out: Path, label: str, cfg: dict, camera_target) -> None:
    v35.v19._clear(arm)
    v23._pose_seed(xr, arm, "Cup_Armature")
    center, axis, inward, _ = v35._fixture_from_seed(arm, 1.0)
    proxy = v35.v33._proxy(center, axis, "ReferenceBracketV46Vessel_" + label)
    focus = camera_target.lerp(center, 0.42)

    rotation_deg, root_shift = v35._orient_whole_hand(arm, center, axis, inward)
    v45._orbit_whole_hand(arm, center, axis, cfg["orbit_deg"], cfg["axial_shift"])
    rotations = v45._apply_frozen_v44_pose(arm, center, axis)
    v35.v19._render(cam, out, "reference_bracket_v46_" + label, focus)

    metrics = v38._metrics(arm, center, axis)
    print(
        "REFERENCE_BRACKET_V46_RESULT", label,
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
    print("MPFB_REFERENCE_BRACKET_V46_SUCCESS")


if __name__ == "__main__":
    try:
        _run()
    except BaseException as exc:
        print("MPFB_REFERENCE_BRACKET_V46_ERROR:", exc)
        traceback.print_exc()
        raise
