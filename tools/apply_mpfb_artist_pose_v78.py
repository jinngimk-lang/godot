#!/usr/bin/env python3
"""Apply one direct artist-authored support-grasp gesture to the v77 native MPFB rig.

This is intentionally NOT a solver or parameter search.  The artist gesture is fully specified by
one committed set of fixed-camera 192x108 tail handles.  This script only realizes those handles
on the existing twelve editable pose bones, parent-first, while preserving the v77 wrist and v74
thumb matrices exactly.  The purpose is equivalent to dragging those bones once in the fixed
Blender authoring view, while keeping the gesture reproducible in CI.
"""
from __future__ import annotations

import importlib.util
import json
import math
import sys
from pathlib import Path

import bpy
from bpy_extras.object_utils import world_to_camera_view
from mathutils import Vector

BASE = Path(__file__).resolve().parent
SPEC = importlib.util.spec_from_file_location("mpfb_v77_for_v78", BASE / "build_mpfb_artist_authoring_scene_v77.py")
if SPEC is None or SPEC.loader is None:
    raise RuntimeError("could not load v77 authoring helpers")
v77 = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(v77)

SUCCESS = "MPFB_ARTIST_POSE_V78_SUCCESS"
EDIT_BONES = [f"finger{digit}-{joint}.R" for digit in range(2, 6) for joint in range(1, 4)]
FROZEN_BONES = ["wrist.R", "finger1-1.R", "finger1-2.R", "finger1-3.R"]


def _args():
    if "--" not in sys.argv:
        raise RuntimeError("expected -- <artist-handles.json> <frames-dir> <report.json>")
    vals = sys.argv[sys.argv.index("--") + 1 :]
    if len(vals) != 3:
        raise RuntimeError("expected three arguments")
    return Path(vals[0]).resolve(), Path(vals[1]).resolve(), Path(vals[2]).resolve()


def _flat(pb):
    return [float(pb.matrix_basis[r][c]) for r in range(4) for c in range(4)]


def _max_delta(a, b):
    return max(abs(float(x) - float(y)) for x, y in zip(a, b))


def _screen_px(scene, cam, world):
    ndc = world_to_camera_view(scene, cam, world)
    return [float(ndc.x * 192.0), float((1.0 - ndc.y) * 108.0), float(ndc.z)]


def _bone_screen(arm, scene, cam, name):
    pb = arm.pose.bones[name]
    return {
        "head_px": _screen_px(scene, cam, arm.matrix_world @ pb.head),
        "tail_px": _screen_px(scene, cam, arm.matrix_world @ pb.tail),
    }


def _find_skinned_base(arm):
    candidates = []
    for obj in bpy.context.scene.objects:
        if obj.type != "MESH":
            continue
        for mod in obj.modifiers:
            if mod.type == "ARMATURE" and getattr(mod, "object", None) == arm:
                candidates.append(obj)
                break
    if not candidates:
        raise RuntimeError("could not find MPFB skinned base mesh in v77 scene")
    return max(candidates, key=lambda obj: len(obj.data.vertices))


def _aim_from_artist_handle(arm, scene, cam, bone_name: str, tail_px, away: float):
    """Realize one manually chosen screen-space handle with one deterministic bone rotation.

    The tail handle itself is the authored datum.  `away` is a fixed depth cue chosen alongside the
    handle so the chain wraps behind the vessel rather than merely drawing a 2D curl.  There is no
    iteration, objective function, scoring, target-distance minimization, or candidate sweep.
    """
    pb = arm.pose.bones.get(bone_name)
    if pb is None:
        raise RuntimeError("missing editable pose bone " + bone_name)
    head_world = arm.matrix_world @ pb.head
    current_head_px = _screen_px(scene, cam, head_world)
    dx = float(tail_px[0]) - current_head_px[0]
    dy = float(tail_px[1]) - current_head_px[1]
    if dx * dx + dy * dy < 0.25:
        raise RuntimeError("artist handle is degenerate for " + bone_name)

    q = cam.matrix_world.to_quaternion()
    right = q @ Vector((1.0, 0.0, 0.0))
    down = -(q @ Vector((0.0, 1.0, 0.0)))
    into_scene = q @ Vector((0.0, 0.0, -1.0))
    screen_direction = right * dx + down * dy
    screen_direction.normalize()
    desired_world = (screen_direction + into_scene * float(away)).normalized()

    world_length = ((arm.matrix_world @ pb.tail) - head_world).length
    target_world = head_world + desired_world * max(world_length, 1e-5)
    v77.v68._aim_pose_bone_world(arm, bone_name, target_world)


def _render_current_pose(arm, vessel, out: Path):
    base = _find_skinned_base(arm)
    # Ensure the rendered evidence comes from the newly posed deforming mesh, never the static v77
    # seed mesh left in the authoring .blend.
    for obj in bpy.context.scene.objects:
        if obj.type == "MESH" and obj != base and obj != vessel:
            obj.hide_render = True
    base.hide_render = True
    arm.hide_render = True

    posed = v77.v73._static(base)
    posed.name = "V78_DIRECT_ARTIST_POSED_LIMB"
    segments = v77.v64._selected_segments(arm)
    palm = v77.v65._wp(arm, "wrist.R", True).lerp(v77.v65._wp(arm, "finger3-1.R"), 0.65)
    v77.v64b._adaptive_crop(posed, segments, palm)
    v77.v65._skin(posed, "B78")
    posed.hide_render = False

    vessel.hide_render = False
    v77.v65._render(out / "support-wrap-v78-with-vessel.png", 640, 640)
    v77.v65._render(out / "support-wrap-v78-thumbnail.png", 192, 108)
    vessel.hide_render = True
    v77.v65._render(out / "support-wrap-v78-anatomy-oblique.png", 640, 640)
    v77.v65._render(out / "support-wrap-v78-anatomy-thumbnail.png", 192, 108)
    vessel.hide_render = False
    return posed


def main():
    handles_path, frames_dir, report_path = _args()
    frames_dir.mkdir(parents=True, exist_ok=True)
    report_path.parent.mkdir(parents=True, exist_ok=True)
    payload = json.loads(handles_path.read_text(encoding="utf-8"))
    if payload.get("format") != "peel-calm-mpfb-screen-space-artist-handles-v1":
        raise RuntimeError("unexpected artist-handle format")
    for key in ["parameter_sweep_used", "ccd_used", "endpoint_optimizer_used", "contact_servo_used", "root_orbit_motion_used"]:
        if payload.get(key) is not False:
            raise RuntimeError("v78 direct-artist contract violated: " + key)

    scene = bpy.context.scene
    arm = bpy.data.objects.get("PeelCalm_GameEngine_HeroRig_V77")
    vessel = bpy.data.objects.get("LOCKED_VESSEL_PROXY_V77")
    cam = scene.camera
    if arm is None or vessel is None or cam is None:
        raise RuntimeError("v77 authoring scene contract missing")
    if bpy.context.mode != "OBJECT":
        bpy.ops.object.mode_set(mode="OBJECT")

    missing = [name for name in EDIT_BONES + FROZEN_BONES if arm.pose.bones.get(name) is None]
    if missing:
        raise RuntimeError("pose bones missing: " + str(missing))
    handles = payload.get("handles", {})
    if sorted(handles.keys()) != sorted(EDIT_BONES):
        raise RuntimeError("artist handle set must contain exactly the twelve editable finger bones")

    frozen_before = {name: _flat(arm.pose.bones[name]) for name in FROZEN_BONES}
    before = {name: _bone_screen(arm, scene, cam, name) for name in EDIT_BONES}

    # Parent-first, digit by digit. Each target is a single manually selected screen-space handle.
    for digit in range(2, 6):
        for joint in range(1, 4):
            name = f"finger{digit}-{joint}.R"
            handle = handles[name]
            _aim_from_artist_handle(
                arm, scene, cam, name, handle["tail_px"], float(handle["away_from_camera"])
            )
    bpy.context.view_layer.update()

    after = {name: _bone_screen(arm, scene, cam, name) for name in EDIT_BONES}
    frozen_after = {name: _flat(arm.pose.bones[name]) for name in FROZEN_BONES}
    frozen_delta = max(_max_delta(frozen_before[name], frozen_after[name]) for name in FROZEN_BONES)
    if frozen_delta > 1e-6:
        raise RuntimeError(f"frozen wrist/thumb changed: {frozen_delta}")

    pose_path = frames_dir / "support-wrap-v78-canonical-pose.json"
    v77.v68._save_same_rig_pose(arm, pose_path)
    _render_current_pose(arm, vessel, frames_dir)
    bpy.ops.wm.save_as_mainfile(filepath=str(frames_dir / "peel-calm-support-grasp-v78.blend"), check_existing=False)

    report = {
        "staging_only": True,
        "production_candidate": False,
        "reference_set": payload["reference_set"],
        "authoring": "one-shot direct fixed-camera artist handles",
        "parameter_sweep_used": False,
        "ccd_used": False,
        "endpoint_optimizer_used": False,
        "contact_servo_used": False,
        "root_orbit_motion_used": False,
        "frozen_wrist_thumb_matrix_max_abs_delta": frozen_delta,
        "before": before,
        "after": after,
        "artist_handles": handles,
        "pose_asset": str(pose_path),
        "visual_verdict": "UNSET — must be judged from 192x108 + unobstructed anatomy renders",
        "next_gate": "Human Macro/Meso review against locked bar_v1/market_v1; metrics cannot auto-promote this pose."
    }
    report_path.write_text(json.dumps(report, indent=2, sort_keys=True), encoding="utf-8")
    print(json.dumps(report, indent=2, sort_keys=True))
    print(SUCCESS)


if __name__ == "__main__":
    main()
