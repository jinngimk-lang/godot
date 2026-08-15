#!/usr/bin/env python3
"""v78: measure the v77 artist-authoring scene without changing pose.

This diagnostic exists to support direct visual posing. It records world-space and fixed-camera
screen-space head/tail coordinates for the twelve editable non-thumb pose bones plus the locked
vessel projection. It does not author, solve, sweep, or optimize any pose parameter.
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

import bpy
from bpy_extras.object_utils import world_to_camera_view

EDIT_BONES = [f"finger{digit}-{joint}.R" for digit in range(2, 6) for joint in range(1, 4)]


def _args():
    if "--" not in sys.argv:
        raise RuntimeError("expected -- <report.json>")
    vals = sys.argv[sys.argv.index("--") + 1 :]
    if len(vals) != 1:
        raise RuntimeError("expected one report path")
    return Path(vals[0]).resolve()


def _vec(v):
    return [float(v.x), float(v.y), float(v.z)]


def _px(scene, cam, world):
    ndc = world_to_camera_view(scene, cam, world)
    return [float(ndc.x * 192.0), float((1.0 - ndc.y) * 108.0), float(ndc.z)]


def main():
    report_path = _args()
    report_path.parent.mkdir(parents=True, exist_ok=True)
    scene = bpy.context.scene
    arm = bpy.data.objects.get("PeelCalm_GameEngine_HeroRig_V77")
    vessel = bpy.data.objects.get("LOCKED_VESSEL_PROXY_V77")
    cam = scene.camera
    if arm is None or vessel is None or cam is None:
        raise RuntimeError("v77 authoring scene contract missing")

    bones = {}
    for name in EDIT_BONES:
        pb = arm.pose.bones.get(name)
        if pb is None:
            raise RuntimeError("missing editable bone " + name)
        head = arm.matrix_world @ pb.head
        tail = arm.matrix_world @ pb.tail
        bones[name] = {
            "head_world": _vec(head),
            "tail_world": _vec(tail),
            "head_px_192x108": _px(scene, cam, head),
            "tail_px_192x108": _px(scene, cam, tail),
            "matrix_basis": [float(pb.matrix_basis[r][c]) for r in range(4) for c in range(4)],
        }

    # Project eight local bounding-box corners to define the fixed vessel screen footprint.
    corners = [vessel.matrix_world @ __import__('mathutils').Vector(corner) for corner in vessel.bound_box]
    projected = [_px(scene, cam, p) for p in corners]
    xs = [p[0] for p in projected]
    ys = [p[1] for p in projected]
    result = {
        "staging_only": True,
        "pose_changed": False,
        "reference_set": ["bar_v1", "market_v1"],
        "editable_bones": EDIT_BONES,
        "bones": bones,
        "vessel_screen_bbox_192x108": [min(xs), min(ys), max(xs), max(ys)],
        "camera": cam.name,
        "next_gate": "Use these coordinates only to inform one direct artist-authored whole-finger silhouette; no sweep/solver.",
    }
    report_path.write_text(json.dumps(result, indent=2, sort_keys=True), encoding="utf-8")
    print(json.dumps(result, indent=2, sort_keys=True))
    print("MPFB_ARTIST_SCENE_DIAGNOSTIC_V78_SUCCESS")


if __name__ == "__main__":
    main()
