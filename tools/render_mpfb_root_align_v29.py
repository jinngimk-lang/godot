"""v29: bounded rigid hand-root alignment before visible-surface pinch servo.

v28 established that the contact targets should be the actual +/-Y faces of the
fixed paper proxy. It reduced thumb face error to ~6.85 mm, but the visible digit
gap remained ~13 mm and the screenshot still read as fingers reaching from a fixed
palm rather than a hand tracking the flap.

In production Peel Calm the peel-hand root follows the flap target. Asking only
finger joints to absorb hand-to-flap translation is therefore the wrong staging
constraint. This experiment keeps:
- Pinch Tight anatomical seed;
- actual paper +/-Y face targets;
- v26 direct evaluated-surface CCD;
- 24-degree cumulative extra rotation budget per finger joint.

It adds one gameplay-realistic variable: a bounded rigid translation of the whole
MPFB limb so the current visible thumb/index surface midpoint reaches the fixed flap
center before finger CCD. The translation is capped at 50 mm and is logged. No
scale, morphology, or extra joint budget is added.

This is staging/falsification evidence, not production runtime IK.
"""
from __future__ import annotations

import importlib.util
import traceback
from pathlib import Path

import bpy
from mathutils import Vector

BASE = Path(__file__).with_name("render_mpfb_flap_normal_v28.py")
spec = importlib.util.spec_from_file_location("mpfb_v28", BASE)
if spec is None or spec.loader is None:
    raise RuntimeError("could not load v28 flap-normal helpers")
v28 = importlib.util.module_from_spec(spec)
spec.loader.exec_module(v28)

v26 = v28.v26
v25 = v28.v25
v23 = v28.v23
v22 = v28.v22
v19 = v28.v19

MAX_ROOT_SHIFT = 0.050


def _rigid_translate_limb(arm, delta: Vector) -> None:
    """Translate armature and any non-child skinned mesh exactly once."""
    arm.location += delta
    for obj in bpy.context.scene.objects:
        if obj.type != "MESH":
            continue
        driven_by_arm = any(
            mod.type == "ARMATURE" and getattr(mod, "object", None) == arm
            for mod in obj.modifiers
        )
        if not driven_by_arm:
            continue
        # Normal imported GLTF hierarchy parents the skinned mesh under armature;
        # in that case arm.location already carries it. Only translate separately
        # when it is not a descendant of the armature.
        parent = obj.parent
        descendant = False
        while parent is not None:
            if parent == arm:
                descendant = True
                break
            parent = parent.parent
        if not descendant:
            obj.location += delta
    bpy.context.view_layer.update()


def _align_visible_midpoint(mpfb, flap_center: Vector) -> Vector:
    index_surface = v25._weighted_surface_point("index_03_r", flap_center)
    thumb_surface = v25._weighted_surface_point("thumb_03_r", flap_center)
    midpoint = index_surface.lerp(thumb_surface, 0.5)
    raw_delta = flap_center - midpoint
    distance = raw_delta.length
    if distance > MAX_ROOT_SHIFT:
        delta = raw_delta.normalized() * MAX_ROOT_SHIFT
    else:
        delta = raw_delta
    _rigid_translate_limb(mpfb, delta)
    print(
        "ROOT_ALIGN_V29",
        "raw_shift", f"{distance:.6f}",
        "applied_shift", f"{delta.length:.6f}",
        "delta", tuple(round(v, 6) for v in delta),
    )
    return delta


def _run_pinch(xr, mpfb, cam, out, flap_center, camera_target):
    v25._remove_contact_markers()
    rows = v23._pose_seed(xr, mpfb, "Pinch Tight_Armature")
    v19._remove_proxies()

    root_delta = _align_visible_midpoint(mpfb, flap_center)
    v22._paper_proxy(flap_center)
    desired_surface = v28._actual_flap_face_targets(mpfb, flap_center)

    results = {}
    for digit in ("index", "thumb"):
        v23._marker(desired_surface[digit], "PinchTarget_" + digit, (0.12, 0.74, 0.24, 1.0))
        results[digit] = v26._surface_ccd_to_target(
            mpfb, v23.PINCH_CHAINS[digit], desired_surface[digit]
        )

    index_surface = v25._weighted_surface_point("index_03_r", desired_surface["index"])
    thumb_surface = v25._weighted_surface_point("thumb_03_r", desired_surface["thumb"])
    index_face_error = (index_surface - desired_surface["index"]).length
    thumb_face_error = (thumb_surface - desired_surface["thumb"]).length
    index_center_error = (index_surface - flap_center).length
    thumb_center_error = (thumb_surface - flap_center).length
    visible_gap = (index_surface - thumb_surface).length
    max_added = max(max(result["added_deg"].values()) for result in results.values())

    print(
        "ROOT_ALIGN_V29_PINCH",
        "face_errors", [round(index_face_error, 6), round(thumb_face_error, 6)],
        "center_errors", [round(index_center_error, 6), round(thumb_center_error, 6)],
        "visible_gap", f"{visible_gap:.6f}",
        "root_shift", f"{root_delta.length:.6f}",
        "max_added_deg", f"{max_added:.3f}",
    )

    pinch_camera_target = camera_target.lerp(flap_center, 0.50)
    v19._render(cam, out, "surface_v29_root_align", pinch_camera_target)

    if root_delta.length > MAX_ROOT_SHIFT + 1e-6:
        raise RuntimeError("v29 exceeded rigid hand-root shift budget")
    if max(index_face_error, thumb_face_error) > v25.SURFACE_TARGET_TOLERANCE:
        raise RuntimeError("v29 visible fingertip missed actual flap face")
    if max(index_center_error, thumb_center_error) > v25.SURFACE_CENTER_TOLERANCE:
        raise RuntimeError("v29 visible fingertip remained too far from flap center")
    if visible_gap > v25.SURFACE_GAP_TOLERANCE:
        raise RuntimeError("v29 visible pinch gap exceeds 10 mm")
    if max_added > v26.SURFACE_CCD_EXTRA_BUDGET_DEG + 1e-3:
        raise RuntimeError("v29 exceeded anatomical CCD rotation budget")
    return rows, results


def _run() -> None:
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

    # Support remains the unchanged v23 fixed-target control. Its pose function
    # clears the armature before use, so the later pinch root shift cannot affect it.
    support_target_errors, _, _, _, _ = v25._run_support(
        xr, mpfb, cam, out, support_center, support_radius, support_axis, camera_target
    )
    if max(support_target_errors) > 0.030:
        raise RuntimeError("v29 support control regressed: " + repr(support_target_errors))

    _run_pinch(xr, mpfb, cam, out, flap_center, camera_target)
    print("MPFB_ROOT_ALIGN_V29_SUCCESS")


if __name__ == "__main__":
    try:
        _run()
    except BaseException as exc:
        print("MPFB_ROOT_ALIGN_V29_ERROR:", exc)
        traceback.print_exc()
        raise
