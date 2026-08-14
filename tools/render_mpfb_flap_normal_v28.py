"""v28: align surface-servo pinch targets to the actual fixed paper proxy faces.

v27 showed that changing the authored seed to Pinch Tight improved the non-pinching
finger silhouette but left the index/thumb contact metrics identical to v26. The
remaining contact error is therefore not primarily a seed-pose problem.

The v22 paper proxy is an axis-aligned cube with scale (0.024, 0.002, 0.016), so
its thin dimension — the two physical pinch faces — lies on world +/-Y at 2 mm
from flap_center. Earlier v25-v27 targets were instead split along the current
index/thumb separation vector. That was convenient numerically but did not represent
the paper surface being pinched.

This experiment keeps v27 Pinch Tight + v26 direct evaluated-surface CCD + the same
24-degree cumulative extra-rotation budget, and changes only the contact target:
visible index/thumb surfaces must approach opposite *actual* +/-Y flap faces.
Which digit receives +Y is chosen from its neutral visible-side ordering to avoid
forcing the digits to cross through one another.

This is staging/falsification evidence, not production runtime IK.
"""
from __future__ import annotations

import importlib.util
import traceback
from pathlib import Path

from mathutils import Vector

BASE = Path(__file__).with_name("render_mpfb_surface_servo_v26.py")
spec = importlib.util.spec_from_file_location("mpfb_v26", BASE)
if spec is None or spec.loader is None:
    raise RuntimeError("could not load v26 surface servo")
v26 = importlib.util.module_from_spec(spec)
spec.loader.exec_module(v26)

v25 = v26.v25
v23 = v26.v23
v22 = v26.v22
v19 = v26.v19

FLAP_HALF_THICKNESS = 0.002


def _actual_flap_face_targets(mpfb, flap_center: Vector):
    index_now = v25._weighted_surface_point("index_03_r", flap_center)
    thumb_now = v25._weighted_surface_point("thumb_03_r", flap_center)
    # v22's paper proxy is not rotated. Its physical faces are world +/-Y.
    # Preserve the current side ordering so the servo closes around the paper
    # instead of asking the digits to tunnel through one another.
    sign = 1.0 if index_now.y >= thumb_now.y else -1.0
    normal = Vector((0.0, sign, 0.0))
    targets = {
        "index": flap_center + normal * FLAP_HALF_THICKNESS,
        "thumb": flap_center - normal * FLAP_HALF_THICKNESS,
    }
    print(
        "FLAP_NORMAL_V28_TARGETS",
        "index", tuple(round(v, 6) for v in targets["index"]),
        "thumb", tuple(round(v, 6) for v in targets["thumb"]),
        "normal", tuple(round(v, 3) for v in normal),
    )
    return targets


def _run_pinch(xr, mpfb, cam, out, flap_center, camera_target):
    v25._remove_contact_markers()
    rows = v23._pose_seed(xr, mpfb, "Pinch Tight_Armature")
    v19._remove_proxies()
    v22._paper_proxy(flap_center)

    desired_surface = _actual_flap_face_targets(mpfb, flap_center)
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
        "FLAP_NORMAL_V28_PINCH",
        "face_errors", [round(index_face_error, 6), round(thumb_face_error, 6)],
        "center_errors", [round(index_center_error, 6), round(thumb_center_error, 6)],
        "visible_gap", f"{visible_gap:.6f}",
        "surface_solver_errors", [round(results[d]["surface_error"], 6) for d in ("index", "thumb")],
        "max_added_deg", f"{max_added:.3f}",
    )

    pinch_camera_target = camera_target.lerp(flap_center, 0.50)
    v19._render(cam, out, "surface_v28_flap_normal", pinch_camera_target)

    if max(index_face_error, thumb_face_error) > v25.SURFACE_TARGET_TOLERANCE:
        raise RuntimeError("v28 visible fingertip missed actual flap face")
    if max(index_center_error, thumb_center_error) > v25.SURFACE_CENTER_TOLERANCE:
        raise RuntimeError("v28 visible fingertip remained too far from flap center")
    if visible_gap > v25.SURFACE_GAP_TOLERANCE:
        raise RuntimeError("v28 visible pinch gap exceeds 10 mm")
    if max_added > v26.SURFACE_CCD_EXTRA_BUDGET_DEG + 1e-3:
        raise RuntimeError("v28 exceeded anatomical CCD rotation budget")
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

    support_target_errors, _, _, _, _ = v25._run_support(
        xr, mpfb, cam, out, support_center, support_radius, support_axis, camera_target
    )
    if max(support_target_errors) > 0.030:
        raise RuntimeError("v28 support control regressed: " + repr(support_target_errors))

    _run_pinch(xr, mpfb, cam, out, flap_center, camera_target)
    print("MPFB_FLAP_NORMAL_V28_SUCCESS")


if __name__ == "__main__":
    try:
        _run()
    except BaseException as exc:
        print("MPFB_FLAP_NORMAL_V28_ERROR:", exc)
        traceback.print_exc()
        raise
