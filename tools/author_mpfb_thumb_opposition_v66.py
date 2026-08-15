#!/usr/bin/env python3
"""v66: freeze v65 candidate B and strengthen only thumb opposition.

Checkpoint 28 accepted the v65 B whole-hand shape as the first meaningful Macro support-grip
seed but held it back because the thumb is not clearly readable against the opposing curled
fingers.  This spike intentionally changes no wrist, palm, vessel, camera, crop, or non-thumb
finger choreography.  It applies one additional deterministic thumb swing/curl on top of the
frozen v65-B pose, then reuses the exact same bake/evidence path.
"""
from __future__ import annotations

import importlib
import importlib.util
import json
import math
import sys
import traceback
from pathlib import Path

import bpy
from mathutils import Vector

BASE = Path(__file__).resolve().parent
SPEC = importlib.util.spec_from_file_location("mpfb_v65_for_v66", BASE / "author_mpfb_reference_grasp_v65.py")
if SPEC is None or SPEC.loader is None:
    raise RuntimeError("could not load v65 base")
v65 = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(v65)

SUCCESS = "MPFB_THUMB_OPPOSITION_V66_SUCCESS"
_ORIGINAL_AUTHOR = v65._author_power_grasp


def _args():
    if "--" not in sys.argv:
        raise RuntimeError("expected -- <extension-module> <outdir> <report.json>")
    values = sys.argv[sys.argv.index("--") + 1:]
    if len(values) != 3:
        raise RuntimeError("expected three arguments")
    return values[0], Path(values[1]).resolve(), Path(values[2]).resolve()


def _thumb_only_author(arm, palmar_sign: float):
    if palmar_sign != -1.0:
        raise RuntimeError("v66 is intentionally locked to v65 candidate-B palmar sign")

    vessel_center, vessel_radius, palm_center, longitudinal, span, palmar = _ORIGINAL_AUTHOR(arm, palmar_sign)

    # Frozen v65-B already contains 38° thumb-root opposition + 34°/28° curl.  The thumbnail
    # showed a compact grip but the thumb remained hidden/bunched with the fingers.  Add exactly
    # one targeted opposition correction: more root swing across the vessel, then small extra
    # proximal/distal curl.  No other bone chain is touched.
    thumb_root = "finger1-1.R"
    thumb_dir = (v65._wp(arm, thumb_root, True) - v65._wp(arm, thumb_root)).normalized()
    toward_vessel = (vessel_center - v65._wp(arm, thumb_root)).normalized()
    opposition_axis = thumb_dir.cross(toward_vessel).normalized()
    if opposition_axis.length_squared < 0.5:
        opposition_axis = longitudinal
    v65._rotate_pose_bone_world(arm, thumb_root, opposition_axis, math.radians(24.0))

    for name, extra_angle in (("finger1-2.R", 10.0), ("finger1-3.R", 6.0)):
        axis = v65._choose_curl_axis(arm, name, palmar, vessel_center)
        v65._rotate_pose_bone_world(arm, name, axis, math.radians(extra_angle))

    bpy.context.view_layer.update()
    return vessel_center, vessel_radius, palm_center, longitudinal, span, palmar


def run():
    extension_module, out, report_path = _args()
    out.mkdir(parents=True, exist_ok=True)
    report_path.parent.mkdir(parents=True, exist_ok=True)

    mpfb, HumanService = v65._services(extension_module)
    v65._author_power_grasp = _thumb_only_author
    candidate = v65._build_candidate(HumanService, out, "B66", -1.0)

    report = {
        "staging_only": True,
        "production_candidate": False,
        "reference_set": ["bar_v1", "market_v1"],
        "base_candidate": "v65-B",
        "base_palmar_sign": -1.0,
        "non_thumb_fingers_changed_from_v65_b": False,
        "wrist_changed_from_v65_b": False,
        "palm_vessel_relationship_changed_from_v65_b": False,
        "camera_changed_from_v65_b": False,
        "crop_changed_from_v65_b": False,
        "thumb_only_change": True,
        "extra_thumb_root_opposition_degrees": 24.0,
        "extra_thumb_proximal_curl_degrees": 10.0,
        "extra_thumb_distal_curl_degrees": 6.0,
        "ccd_used": False,
        "endpoint_optimizer_used": False,
        "parameter_sweep_used": False,
        "production_gameengine_rig_touched": False,
        "mpfb_version": list(mpfb.VERSION),
        "candidate": candidate,
        "visual_gate": "At 192x108 the thumb must be immediately readable on the opposing near/upper side without self-intersection while the frozen v65-B four-finger grip remains intact; then inspect the unobstructed oblique anatomy view.",
    }
    report_path.write_text(json.dumps(report, indent=2, sort_keys=True), encoding="utf-8")
    print(json.dumps(report, indent=2, sort_keys=True))
    print(SUCCESS)


if __name__ == "__main__":
    try:
        run()
    except BaseException as exc:
        print("MPFB_THUMB_OPPOSITION_V66_ERROR:", exc)
        traceback.print_exc()
        raise
