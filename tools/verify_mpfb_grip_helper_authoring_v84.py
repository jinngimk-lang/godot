#!/usr/bin/env python3
"""Reopen and verify the v84 authoring .blend contract without modifying the pose."""
from __future__ import annotations
import json, sys
from pathlib import Path
import bpy

SUCCESS = "MPFB_GRIP_HELPER_AUTHORING_V84_REOPEN_PASS"
EXPECTED = ["wrist.R", "right_master_grip"] + [f"right_finger{i}_grip" for i in range(1, 6)]

if "--" not in sys.argv:
    raise RuntimeError("expected -- <report.json>")
args = sys.argv[sys.argv.index("--") + 1:]
if len(args) != 1:
    raise RuntimeError("expected one report path")
out = Path(args[0]).resolve(); out.parent.mkdir(parents=True, exist_ok=True)
arm = bpy.data.objects.get("MPFB_V84_AuthoringRig")
vessel = bpy.data.objects.get("LOCKED_VesselProxy")
cam = bpy.data.objects.get("LOCKED_V84_Camera")
if arm is None or vessel is None or cam is None:
    raise RuntimeError("missing locked v84 scene objects")
missing = [n for n in EXPECTED if arm.pose.bones.get(n) is None]
if missing:
    raise RuntimeError("missing editable controls: " + repr(missing))
embedded = json.loads(arm.get("editable_controls", "[]"))
if embedded != EXPECTED:
    raise RuntimeError(f"editable controls drifted: {embedded}")
if arm.get("acceptance_references") != "bar_v1,market_v1":
    raise RuntimeError("reference contract drifted")
if bool(arm.get("production_candidate")):
    raise RuntimeError("authoring scene must not self-promote")
if bpy.context.scene.get("peel_calm_visual_verdict") != "PENDING_DIRECT_ARTIST_EDIT":
    raise RuntimeError("visual verdict drifted")
if not vessel.hide_select or not cam.hide_select:
    raise RuntimeError("locked vessel/camera must remain non-selectable")
report = {
    "reopen_verified": True,
    "editable_controls": EXPECTED,
    "locked_references": arm.get("acceptance_references"),
    "visual_verdict": bpy.context.scene.get("peel_calm_visual_verdict"),
    "production_candidate": bool(arm.get("production_candidate")),
    "vessel_locked": bool(vessel.hide_select),
    "camera_locked": bool(cam.hide_select),
}
out.write_text(json.dumps(report, indent=2, sort_keys=True), encoding="utf-8")
print(json.dumps(report, indent=2, sort_keys=True)); print(SUCCESS)
