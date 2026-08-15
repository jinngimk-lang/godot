#!/usr/bin/env python3
"""v69: retain pristine v65-B grip and author one longer visible thumb opposition arc.

v68 validated the abstraction change (the thumb was authored as one coherent chain), but the
actual landmarks compressed the digit into a short curled mass in both the 192x108 vessel view
and unobstructed oblique anatomy.  v69 is one structural correction, not a sweep: preserve the
exact v65-B wrist/palm/vessel/four-finger grasp/camera/crop and replace only the three visual
thumb landmarks with a longer camera-side arc that opens the web space, crosses the near vessel
surface, and finishes lower on the opposing side.
"""
from __future__ import annotations

import importlib.util
import json
import sys
import traceback
from pathlib import Path

import bpy

BASE = Path(__file__).resolve().parent
SPEC = importlib.util.spec_from_file_location("mpfb_v68_for_v69", BASE / "author_mpfb_thumb_chain_v68.py")
if SPEC is None or SPEC.loader is None:
    raise RuntimeError("could not load v68 helpers")
v68 = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(v68)
v65 = v68.v65

SUCCESS = "MPFB_THUMB_ARC_V69_SUCCESS"
_POSE_PATH: Path | None = None
_THUMB_REPORT: dict = {}


def _args():
    if "--" not in sys.argv:
        raise RuntimeError("expected -- <extension-module> <outdir> <report.json>")
    values = sys.argv[sys.argv.index("--") + 1:]
    if len(values) != 3:
        raise RuntimeError("expected three arguments")
    return values[0], Path(values[1]).resolve(), Path(values[2]).resolve()


def _thumb_arc_author(arm, palmar_sign: float):
    global _THUMB_REPORT
    if palmar_sign != -1.0:
        raise RuntimeError("v69 is locked to pristine v65 candidate-B palmar sign")

    vessel_center, vessel_radius, palm_center, longitudinal, span, palmar = v68._ORIGINAL_AUTHOR(arm, palmar_sign)
    palm_radial = (palm_center - vessel_center).normalized()
    near = vessel_center + palm_radial * (vessel_radius + 0.014)

    # One deliberately longer opposition arc.  The root opens toward the camera/index side,
    # proximal crosses inward over the near vessel contour, and distal finishes below/inside.
    # These are not optimized endpoints and no alternate magnitudes are generated.
    root_target = near - span * (vessel_radius * 1.38) + longitudinal * (vessel_radius * 0.38)
    proximal_target = near - span * (vessel_radius * 0.72) + longitudinal * (vessel_radius * 0.03)
    distal_target = near - span * (vessel_radius * 0.10) - longitudinal * (vessel_radius * 0.28)

    for name, target in (
        ("finger1-1.R", root_target),
        ("finger1-2.R", proximal_target),
        ("finger1-3.R", distal_target),
    ):
        v68._aim_pose_bone_world(arm, name, target)
    bpy.context.view_layer.update()

    thumb_tip = v65._wp(arm, "finger1-3.R", True)
    thumb_root = v65._wp(arm, "finger1-1.R")
    index_root = v65._wp(arm, "finger2-1.R")
    index_tip = v65._wp(arm, "finger2-3.R", True)
    thumb_radial = thumb_tip - vessel_center
    thumb_radial -= longitudinal * thumb_radial.dot(longitudinal)
    palm_plane = palm_center - vessel_center
    palm_plane -= longitudinal * palm_plane.dot(longitudinal)
    radial_dot = thumb_radial.normalized().dot(palm_plane.normalized()) if thumb_radial.length > 1e-6 else 1.0

    _THUMB_REPORT = {
        "root_world": [float(x) for x in thumb_root],
        "tip_world": [float(x) for x in thumb_tip],
        "tip_to_index_root": float((thumb_tip - index_root).length),
        "tip_to_index_tip": float((thumb_tip - index_tip).length),
        "thumb_palm_side_dot": float(radial_dot),
        "landmarks": {
            "root_target": [float(x) for x in root_target],
            "proximal_target": [float(x) for x in proximal_target],
            "distal_target": [float(x) for x in distal_target],
        },
    }
    if _POSE_PATH is not None:
        v68._save_same_rig_pose(arm, _POSE_PATH)
    return vessel_center, vessel_radius, palm_center, longitudinal, span, palmar


def run():
    global _POSE_PATH
    extension_module, out, report_path = _args()
    out.mkdir(parents=True, exist_ok=True)
    report_path.parent.mkdir(parents=True, exist_ok=True)
    _POSE_PATH = out / "support-wrap-v69-canonical-pose.json"
    mpfb, HumanService = v65._services(extension_module)

    v65._author_power_grasp = _thumb_arc_author
    candidate = v65._build_candidate(HumanService, out, "B69", -1.0)
    if not _POSE_PATH.is_file() or _POSE_PATH.stat().st_size <= 0:
        raise RuntimeError("same-rig v69 pose asset was not persisted")

    report = {
        "staging_only": True,
        "production_candidate": False,
        "reference_set": ["bar_v1", "market_v1"],
        "base_candidate": "pristine v65-B",
        "previous_candidate": "v68 direct visual thumb chain — rejected for compressed thumb silhouette",
        "single_structural_correction": "longer visible thumb opposition arc",
        "base_palmar_sign": -1.0,
        "direct_visual_thumb_chain": True,
        "thumb_bones_authored_together": ["finger1-1.R", "finger1-2.R", "finger1-3.R"],
        "non_thumb_fingers_changed_from_v65_b": False,
        "wrist_changed_from_v65_b": False,
        "palm_vessel_relationship_changed_from_v65_b": False,
        "camera_changed_from_v65_b": False,
        "crop_changed_from_v65_b": False,
        "ccd_used": False,
        "endpoint_optimizer_used": False,
        "parameter_sweep_used": False,
        "single_axis_thumb_sweep_used": False,
        "same_rig_pose_persisted": True,
        "same_rig_pose_path": str(_POSE_PATH),
        "production_gameengine_rig_touched": False,
        "mpfb_version": list(mpfb.VERSION),
        "thumb_diagnostics": _THUMB_REPORT,
        "candidate": candidate,
        "visual_gate": "At 192x108 the thumb must be independently legible as a longer opposing digit while the frozen v65-B fingers enclose the vessel; oblique anatomy must show continuous root/proximal/distal thumb shape without self-intersection.",
    }
    report_path.write_text(json.dumps(report, indent=2, sort_keys=True), encoding="utf-8")
    print(json.dumps(report, indent=2, sort_keys=True))
    print(SUCCESS)


if __name__ == "__main__":
    try:
        run()
    except BaseException as exc:
        print("MPFB_THUMB_ARC_V69_ERROR:", exc)
        traceback.print_exc()
        raise
