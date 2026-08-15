"""v32: structural support-wrap falsification using a transverse vessel axis.

Visual review of the persisted v31 support frame rejected the pose even though the
contact gate passed: the four fingers hang down the vessel like a claw. The v22/v23
fixture defines the support cylinder axis from lowerarm -> palm, which makes the
proxy longitudinal with the incoming forearm. That fixture rewards fingertips that
drape along the vessel instead of a photographic bottle/cup wrap.

This experiment changes one structural assumption only: the support-vessel axis is
derived across the neutral MPFB knuckles (index MCP -> pinky MCP). Support center,
radius, XR Cup seed, CCD budgets, contact tolerances, pinch target, morphology and
v30 surface-servo precision remain unchanged. The hypothesis is falsifiable in the
fixed camera: a transverse axis should make the fingers curl around the vessel's
circumference instead of hanging along its length.

This is staging evidence only; it does not change production assets or runtime IK.
"""
from __future__ import annotations

import importlib.util
import traceback
from pathlib import Path

BASE = Path(__file__).with_name("render_mpfb_precision_v30.py")
spec = importlib.util.spec_from_file_location("mpfb_v30", BASE)
if spec is None or spec.loader is None:
    raise RuntimeError("could not load v30 precision experiment")
v30 = importlib.util.module_from_spec(spec)
spec.loader.exec_module(v30)

v29 = v30.v29
v22 = v29.v22
v19 = v29.v19
_original_neutral_targets = v22._neutral_targets


def _transverse_neutral_targets(mpfb):
    support_center, support_radius, _old_axis, flap_center, camera_target = _original_neutral_targets(mpfb)

    # Keep the neutral pose used by the original fixture, but orient the vessel
    # along the MCP/knuckle row rather than along the incoming forearm. A vertical
    # cup/bottle is grasped around an axis approximately transverse to the fingers;
    # deriving that axis from the hand itself keeps this morphology-independent.
    v19._clear(mpfb)
    index_mcp = v19._wp(mpfb, "index_01_r")
    pinky_mcp = v19._wp(mpfb, "pinky_01_r")
    support_axis = pinky_mcp - index_mcp
    if support_axis.length < 1e-6:
        raise RuntimeError("v32 degenerate transverse knuckle axis")
    support_axis.normalize()

    print(
        "SUPPORT_AXIS_V32",
        "axis", tuple(round(v, 6) for v in support_axis),
        "center", tuple(round(v, 6) for v in support_center),
        "radius", f"{support_radius:.6f}",
    )
    return support_center, support_radius, support_axis, flap_center, camera_target


# Patch only the target-frame structural axis consumed by v29/v30. All solver and
# acceptance constants stay exactly as v30.
v22._neutral_targets = _transverse_neutral_targets


if __name__ == "__main__":
    try:
        v30.v29._run()
        print("MPFB_SUPPORT_AXIS_V32_SUCCESS")
    except BaseException as exc:
        print("MPFB_SUPPORT_AXIS_V32_ERROR:", exc)
        traceback.print_exc()
        raise
