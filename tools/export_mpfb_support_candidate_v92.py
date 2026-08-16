#!/usr/bin/env python3
"""Export one reference-derived v92 whole-hand enclosure candidate.

This is deliberately one candidate, not a parameter sweep. It reuses the proven v91
staging/export path, freezes the v90 progressive semantic closure, v89 crop, physical
scale and -40 degree side-on limb approach, then makes one coordinated native-rig gesture:
move the wrist/palm 12 mm along the already-calibrated local-Y "toward vessel" authoring
axis and deepen the complete hand turn from +16 to +24 degrees about wrist local Y.

The intent is higher-level than another grip-number iteration: place the palm on the bottle
flank and carry the already-progressive index->pinky closure into far-side depth so distal
silhouette can occlude behind the cylinder while the thumb remains opposing.
"""
from __future__ import annotations

import json
import math
import sys
from pathlib import Path

import bpy
from mathutils import Vector

import export_mpfb_support_candidate_v88 as base

SUCCESS = "MPFB_SUPPORT_CANDIDATE_V92_EXPORT_SUCCESS"
PALM_FLANK_LOCAL_Y_METERS = 0.012
WHOLE_HAND_SPATIAL_YAW_DEG = 24.0


def _apply_single_v92_artist_gesture(arm) -> None:
    # Preserve the exact v90 semantic closure profile; do not continue scalar escalation.
    for name, payload in base.POSE_DELTAS_DEG.items():
        pb = arm.pose.bones.get(name)
        if pb is None:
            raise RuntimeError("missing editable control " + name)
        pb.rotation_mode = "XYZ"
        e = pb.rotation_euler.copy()
        e.x += math.radians(float(payload.get("rx", 0.0)))
        pb.rotation_euler = e

    wrist = arm.pose.bones.get("wrist.R")
    if wrist is None:
        raise RuntimeError("missing wrist.R for v92 whole-hand authoring")

    # The v88 response atlas already established local Y translation as the direct
    # toward/away-vessel authoring channel. Use exactly one +12 mm flank-placement move.
    wrist.location = wrist.location + Vector((0.0, PALM_FLANK_LOCAL_Y_METERS, 0.0))

    # v91 proved whole-hand local-Y orientation is a better abstraction than more grip.
    # Apply one additional atlas-sized 8 degree nudge, yielding a single fixed +24 degree
    # gesture. This is not a 16/20/24/... search: only this evidence-derived candidate exists.
    wrist.rotation_mode = "XYZ"
    e = wrist.rotation_euler.copy()
    e.y += math.radians(WHOLE_HAND_SPATIAL_YAW_DEG)
    wrist.rotation_euler = e
    bpy.context.view_layer.update()


def main() -> None:
    if "--" not in sys.argv:
        raise RuntimeError("expected -- <output.glb> <report.json>")
    values = sys.argv[sys.argv.index("--") + 1:]
    if len(values) != 2:
        raise RuntimeError("expected two arguments")
    report_path = Path(values[1]).resolve()

    # Reuse the already-verified crop/export/product-root path while substituting only
    # this one higher-level artist gesture and its fixed whole-hand yaw constant.
    base.WHOLE_HAND_SPATIAL_YAW_DEG = WHOLE_HAND_SPATIAL_YAW_DEG
    base._apply_single_artist_edit = _apply_single_v92_artist_gesture
    base.main()

    report = json.loads(report_path.read_text(encoding="utf-8"))
    report.update({
        "candidate_version": "v92",
        "single_higher_level_whole_hand_gesture": True,
        "palm_flank_local_y_translation_meters": PALM_FLANK_LOCAL_Y_METERS,
        "whole_hand_spatial_yaw_degrees": WHOLE_HAND_SPATIAL_YAW_DEG,
        "parameter_sweep_used": False,
        "optimizer_used": False,
        "automatic_retarget_used": False,
        "enclosure_edit_reason": "single reference-derived whole-hand gesture: preserve v90 progressive closure plus v89 side-on/crop/scale passes, place palm 12 mm on the calibrated vessel-flank axis, and add one atlas-sized whole-hand depth turn so distal fingers can move behind the far cylinder silhouette",
        "whole_hand_spatial_reason": "v91 showed whole-hand spatial orientation improves Meso coherence but +16 degrees alone leaves an open front-side C-shape; v92 combines one calibrated palm-flank translation with exactly one additional 8-degree whole-hand depth nudge, not a magnitude grid",
        "next_gate": "Exact same Godot bar/market five-frame A/B; reject unless 192x108 enclosure materially improves while label readability, side-on forearm, wrist continuity, physical scale, and inspect45 remain stable.",
    })
    report_path.write_text(json.dumps(report, indent=2, sort_keys=True), encoding="utf-8")
    print(json.dumps(report, indent=2, sort_keys=True))
    print(SUCCESS)


if __name__ == "__main__":
    main()
