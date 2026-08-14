"""v27: test Pinch Tight as the anatomical seed for the proven v26 surface servo.

v26 reduced the visible thumb flap-face error from ~30.9 mm (v25) to ~7.6 mm while
keeping the same 24-degree per-joint extra CCD budget. The index passed at ~2.4 mm
and the visible fingertip gap passed at ~7.9 mm; only the strict <=6 mm thumb face
gate remained red, with thumb joints at the extra-rotation ceiling.

This experiment changes exactly one structural variable: use the repository XR
`Pinch Tight` authored action instead of `Pinch Up` before running the same direct
evaluated-surface CCD. Thresholds and the 24-degree additional budget are unchanged.

This is staging/falsification evidence, not production runtime IK.
"""
from __future__ import annotations

import importlib.util
import traceback
from pathlib import Path

BASE = Path(__file__).with_name("render_mpfb_surface_servo_v26.py")
spec = importlib.util.spec_from_file_location("mpfb_v26", BASE)
if spec is None or spec.loader is None:
    raise RuntimeError("could not load v26 direct surface servo")
v26 = importlib.util.module_from_spec(spec)
spec.loader.exec_module(v26)

v25 = v26.v25
v23 = v26.v23
v22 = v26.v22
v19 = v26.v19


def _run_pinch(xr, mpfb, cam, out, flap_center, camera_target):
    v25._remove_contact_markers()
    rows = v23._pose_seed(xr, mpfb, "Pinch Tight_Armature")
    v19._remove_proxies()
    v22._paper_proxy(flap_center)

    desired_surface = v25._surface_targets(mpfb, flap_center)
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
        "PINCH_TIGHT_V27",
        "face_errors", [round(index_face_error, 6), round(thumb_face_error, 6)],
        "center_errors", [round(index_center_error, 6), round(thumb_center_error, 6)],
        "visible_gap", f"{visible_gap:.6f}",
        "surface_solver_errors", [round(results[d]["surface_error"], 6) for d in ("index", "thumb")],
        "max_added_deg", f"{max_added:.3f}",
    )

    pinch_camera_target = camera_target.lerp(flap_center, 0.50)
    v19._render(cam, out, "surface_v27_pinch_tight", pinch_camera_target)

    if max(index_face_error, thumb_face_error) > v25.SURFACE_TARGET_TOLERANCE:
        raise RuntimeError("v27 visible fingertip missed fixed flap-face target")
    if max(index_center_error, thumb_center_error) > v25.SURFACE_CENTER_TOLERANCE:
        raise RuntimeError("v27 visible fingertip remained too far from flap center")
    if visible_gap > v25.SURFACE_GAP_TOLERANCE:
        raise RuntimeError("v27 visible pinch gap exceeds 10 mm")
    if max_added > v26.SURFACE_CCD_EXTRA_BUDGET_DEG + 1e-3:
        raise RuntimeError("v27 exceeded anatomical CCD rotation budget")
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
        raise RuntimeError("v27 support control regressed: " + repr(support_target_errors))

    _run_pinch(xr, mpfb, cam, out, flap_center, camera_target)
    print("MPFB_PINCH_TIGHT_V27_SUCCESS")


if __name__ == "__main__":
    try:
        _run()
    except BaseException as exc:
        print("MPFB_PINCH_TIGHT_V27_ERROR:", exc)
        traceback.print_exc()
        raise
