"""v24: interaction-specific convergence gate over the v23 contact IK harness.

v23 introduced morphology-preserving bounded CCD, but its generic solver always
stopped at CONTACT_TOLERANCE=14 mm. That was appropriate for support fingertips,
not for the paper-flap pinch: the module defined PINCH_TOLERANCE=12 mm but never
used it, allowing both pinch chains to stop around 10 mm from their *offset*
targets while the thumb remained >13 mm from the actual flap center.

This experiment changes only that falsifiable variable:
- support keeps the proven 14 mm early-stop tolerance;
- pinch must converge each offset fingertip target to 4 mm, while preserving the
  same bounded per-joint CCD budget and the same MPFB anatomy seed;
- stale support target markers are removed before the pinch render;
- the pinch camera focus is shifted halfway toward the frozen flap target so the
  visual evidence actually contains the contact area;
- the run hard-fails unless final thumb/index errors to the real flap center and
  their mutual gap are each <=12 mm.

This remains a preview/falsification harness, not production runtime IK.
"""
from __future__ import annotations

import importlib.util
import traceback
from pathlib import Path

import bpy

BASE = Path(__file__).with_name("render_mpfb_contact_ik_v23.py")
spec = importlib.util.spec_from_file_location("mpfb_v23", BASE)
if spec is None or spec.loader is None:
    raise RuntimeError("could not load v23 contact IK helpers")
v23 = importlib.util.module_from_spec(spec)
spec.loader.exec_module(v23)

SUPPORT_STOP_TOLERANCE = 0.014
PINCH_TARGET_STOP_TOLERANCE = 0.004
FINAL_PINCH_GATE = 0.012

_original_support = v23._run_support
_original_pinch = v23._run_pinch


def _remove_contact_markers() -> None:
    for obj in list(bpy.data.objects):
        if obj.name.startswith("SupportTarget_") or obj.name.startswith("PinchTarget_"):
            bpy.data.objects.remove(obj, do_unlink=True)


def _run_support_v24(xr, mpfb, cam, out, center, radius, axis, camera_target):
    v23.CONTACT_TOLERANCE = SUPPORT_STOP_TOLERANCE
    return _original_support(xr, mpfb, cam, out, center, radius, axis, camera_target)


def _run_pinch_v24(xr, mpfb, cam, out, flap_center, camera_target):
    _remove_contact_markers()
    v23.CONTACT_TOLERANCE = PINCH_TARGET_STOP_TOLERANCE
    # Keep the whole hand visible while giving the fixed flap/contact zone more
    # screen space than v23's support-oriented neutral camera target.
    pinch_camera_target = camera_target.lerp(flap_center, 0.50)
    result = _original_pinch(xr, mpfb, cam, out, flap_center, pinch_camera_target)
    gap, target_error, index_error, thumb_error, rows, results = result
    print(
        "CONTACT_IK_V24_PINCH_GATE",
        "gap", f"{gap:.6f}",
        "target_error", f"{target_error:.6f}",
        "index_error", f"{index_error:.6f}",
        "thumb_error", f"{thumb_error:.6f}",
        "offset_target_errors", [round(results[name]["error"], 6) for name in ("index", "thumb")],
    )
    if max(gap, index_error, thumb_error) > FINAL_PINCH_GATE:
        raise RuntimeError(
            "v24 pinch failed <=12 mm real-contact gate: "
            + repr((gap, target_error, index_error, thumb_error))
        )
    return result


v23._run_support = _run_support_v24
v23._run_pinch = _run_pinch_v24


def _run() -> None:
    v23._run()
    print("MPFB_CONTACT_IK_V24_SUCCESS")


if __name__ == "__main__":
    try:
        _run()
    except BaseException as exc:
        print("MPFB_CONTACT_IK_V24_ERROR:", exc)
        traceback.print_exc()
        raise
