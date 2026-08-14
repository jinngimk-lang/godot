"""v23: separate legal hand-root contact alignment from finger-pose quality.

v22 proved that fixed interaction targets expose the v21 proxy-following false
positive, and that bounded_60 preserves MPFB anatomy better than the full transfer.
However, v22 also mixed two errors: local hand pose and global hand placement.
Gameplay is allowed to translate the whole hand root to the vessel/flap, so this
experiment performs exactly one rigid translation after posing, then measures the
remaining shape error without moving the fixed proxy.

No bone is changed by the contact-alignment step. This makes the experiment useful
for deciding whether the bounded pose is good enough to enter a real Godot
presentation flag, or whether the finger pose itself still needs replacement.
"""
from __future__ import annotations

import importlib.util
import traceback
from pathlib import Path

import bpy
from mathutils import Vector

BASE = Path(__file__).with_name("render_mpfb_reference_pose_v22.py")
spec = importlib.util.spec_from_file_location("mpfb_v22", BASE)
if spec is None or spec.loader is None:
    raise RuntimeError("could not load v22 helpers")
v22 = importlib.util.module_from_spec(spec)
spec.loader.exec_module(v22)
v21 = v22.v21
v19 = v22.v19

# Only keep candidates that were visually defensible in v22. The full-v21 control
# remains represented by the prior artifact and is intentionally not promoted here.
VARIANTS = {
    "bounded_75": v22.VARIANTS["bounded_75"],
    "bounded_60": v22.VARIANTS["bounded_60"],
}
ACTIONS = ("Cup_Armature", "Pinch Up_Armature")


def _world_finger_mean(arm):
    tips = [v19._wp(arm, f"{name}_03_r", True) for name in ("index", "middle", "ring", "pinky")]
    return sum(tips, Vector()) / len(tips)


def _pinch_midpoint(arm):
    index_tip = v19._wp(arm, "index_03_r", True)
    thumb_tip = v19._wp(arm, "thumb_03_r", True)
    return index_tip.lerp(thumb_tip, 0.5)


def _rigid_translate_to(arm, source_world: Vector, target_world: Vector):
    delta = target_world - source_world
    arm.location += delta
    bpy.context.view_layer.update()
    return delta


def _run():
    xr_path, mpfb_path, out = v19._args()
    out.mkdir(parents=True, exist_ok=True)
    v19._reset()
    xr, xr_meshes = v19._import_armature(xr_path, "XR")
    for mesh in xr_meshes:
        mesh.hide_render = True
        mesh.hide_viewport = True
    mpfb, meshes = v19._import_armature(mpfb_path, "MPFB")
    cam = v19._setup_render(meshes)

    support_center, support_radius, support_axis, flap_center, camera_target = v22._neutral_targets(mpfb)
    print("RIGID_V23_FIXED_SUPPORT", tuple(round(v, 6) for v in support_center), "radius", support_radius)
    print("RIGID_V23_FIXED_FLAP", tuple(round(v, 6) for v in flap_center))

    neutral_location = mpfb.location.copy()

    for action_name in ACTIONS:
        semantic = v21._semantic_directions(xr, action_name)
        for variant_name, variant in VARIANTS.items():
            v19._remove_proxies()
            mpfb.location = neutral_location.copy()
            bpy.context.view_layer.update()
            rows = v22._apply_bounded_directions(mpfb, semantic, variant)

            if action_name.startswith("Cup"):
                pre_center = _world_finger_mean(mpfb)
                delta = _rigid_translate_to(mpfb, pre_center, support_center)
                v22._support_proxy(support_center, support_radius, support_axis)
                radial, palm_clearance = v22._support_metrics(mpfb, support_center, support_radius)
                post_center_error = (_world_finger_mean(mpfb) - support_center).length
                print(
                    "RIGID_V23_SUPPORT",
                    variant_name,
                    "root_shift_mm",
                    f"{delta.length * 1000.0:.3f}",
                    "centroid_error_mm",
                    f"{post_center_error * 1000.0:.3f}",
                    "radial_errors_mm",
                    [round(v * 1000.0, 3) for v in radial],
                    "palm_clearance_mm",
                    f"{palm_clearance * 1000.0:.3f}",
                )
                action = "cup"
            else:
                pre_mid = _pinch_midpoint(mpfb)
                delta = _rigid_translate_to(mpfb, pre_mid, flap_center)
                v22._paper_proxy(flap_center)
                gap, target_error, index_error, thumb_error = v22._pinch_metrics(mpfb, flap_center)
                print(
                    "RIGID_V23_PINCH",
                    variant_name,
                    "root_shift_mm",
                    f"{delta.length * 1000.0:.3f}",
                    "gap_mm",
                    f"{gap * 1000.0:.3f}",
                    "target_error_mm",
                    f"{target_error * 1000.0:.3f}",
                    "index_error_mm",
                    f"{index_error * 1000.0:.3f}",
                    "thumb_error_mm",
                    f"{thumb_error * 1000.0:.3f}",
                )
                action = "pinch_up"

            max_applied = max(applied for _, _, applied in rows)
            print("RIGID_V23_ROTATION", action, variant_name, "max_applied_deg", f"{max_applied:.3f}")
            v19._render(cam, out, f"rigid_v23_{action}_{variant_name}", camera_target)

    print("MPFB_RIGID_V23_SUCCESS")


if __name__ == "__main__":
    try:
        _run()
    except BaseException as exc:
        print("MPFB_RIGID_V23_ERROR:", exc)
        traceback.print_exc()
        raise
