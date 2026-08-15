#!/usr/bin/env python3
"""v67: freeze pristine v65-B and add only thumb-root abduction in the palm plane.

v66 proved that more thumb curl/opposition toward the vessel materially moved the thumb but did
not make it visually readable.  v67 therefore returns to pristine v65-B, preserves its original
thumb curl, and changes only root abduction about the frozen palm-normal axis.  A tiny +/-4° probe
selects the sign that increases thumb/index web-space; the authored magnitude is fixed at 28°.
"""
from __future__ import annotations

import importlib.util
import json
import math
import sys
import traceback
from pathlib import Path

import bpy
from mathutils import Matrix

BASE = Path(__file__).resolve().parent
SPEC = importlib.util.spec_from_file_location("mpfb_v65_for_v67", BASE / "author_mpfb_reference_grasp_v65.py")
if SPEC is None or SPEC.loader is None:
    raise RuntimeError("could not load v65 base")
v65 = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(v65)

SUCCESS = "MPFB_THUMB_ABDUCTION_V67_SUCCESS"
_ORIGINAL_AUTHOR = v65._author_power_grasp


def _args():
    if "--" not in sys.argv:
        raise RuntimeError("expected -- <extension-module> <outdir> <report.json>")
    values = sys.argv[sys.argv.index("--") + 1:]
    if len(values) != 3:
        raise RuntimeError("expected three arguments")
    return values[0], Path(values[1]).resolve(), Path(values[2]).resolve()


def _probe_web_space(arm, root_name: str, axis_world, angle_radians: float) -> float:
    pb = arm.pose.bones[root_name]
    original = pb.matrix.copy()
    try:
        v65._rotate_pose_bone_world(arm, root_name, axis_world, angle_radians)
        thumb_tip = v65._wp(arm, "finger1-3.R", True)
        index_root = v65._wp(arm, "finger2-1.R")
        return (thumb_tip - index_root).length
    finally:
        pb.matrix = original
        bpy.context.view_layer.update()


def _thumb_abduction_author(arm, palmar_sign: float):
    if palmar_sign != -1.0:
        raise RuntimeError("v67 is locked to v65 candidate-B palmar sign")

    result = _ORIGINAL_AUTHOR(arm, palmar_sign)
    vessel_center, vessel_radius, palm_center, longitudinal, span, palmar = result

    root = "finger1-1.R"
    probe = math.radians(4.0)
    plus = _probe_web_space(arm, root, palmar, probe)
    minus = _probe_web_space(arm, root, palmar, -probe)
    sign = 1.0 if plus >= minus else -1.0

    # Single fixed authored abduction magnitude.  No curl or other bone chain changes.
    v65._rotate_pose_bone_world(arm, root, palmar, sign * math.radians(28.0))
    bpy.context.view_layer.update()
    arm["v67_abduction_sign"] = sign
    arm["v67_probe_plus_web_space"] = plus
    arm["v67_probe_minus_web_space"] = minus
    return result


def run():
    extension_module, out, report_path = _args()
    out.mkdir(parents=True, exist_ok=True)
    report_path.parent.mkdir(parents=True, exist_ok=True)
    mpfb, HumanService = v65._services(extension_module)

    v65._author_power_grasp = _thumb_abduction_author
    candidate = v65._build_candidate(HumanService, out, "B67", -1.0)

    # The staging rig is deleted by _build_candidate, so record the intended invariant here.
    report = {
        "staging_only": True,
        "production_candidate": False,
        "reference_set": ["bar_v1", "market_v1"],
        "base_candidate": "pristine v65-B",
        "base_palmar_sign": -1.0,
        "thumb_root_abduction_only": True,
        "fixed_thumb_root_abduction_degrees": 28.0,
        "abduction_sign_selected_only_by_web_space_probe": True,
        "probe_degrees": 4.0,
        "thumb_curl_changed_from_v65_b": False,
        "non_thumb_fingers_changed_from_v65_b": False,
        "wrist_changed_from_v65_b": False,
        "palm_vessel_relationship_changed_from_v65_b": False,
        "camera_changed_from_v65_b": False,
        "crop_changed_from_v65_b": False,
        "ccd_used": False,
        "endpoint_optimizer_used": False,
        "parameter_sweep_used": False,
        "production_gameengine_rig_touched": False,
        "mpfb_version": list(mpfb.VERSION),
        "candidate": candidate,
        "visual_gate": "At 192x108 the thumb must separate visibly from the index-side digit mass and oppose the frozen four-finger support grip; oblique anatomy must remain continuous and non-self-intersecting.",
    }
    report_path.write_text(json.dumps(report, indent=2, sort_keys=True), encoding="utf-8")
    print(json.dumps(report, indent=2, sort_keys=True))
    print(SUCCESS)


if __name__ == "__main__":
    try:
        run()
    except BaseException as exc:
        print("MPFB_THUMB_ABDUCTION_V67_ERROR:", exc)
        traceback.print_exc()
        raise
