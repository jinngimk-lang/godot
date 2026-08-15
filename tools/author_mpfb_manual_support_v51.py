#!/usr/bin/env python3
"""v51: author one durable GameEngine support grasp from visual anatomy evidence.

This is deliberately *not* another solver/search family. It freezes the previously useful
v44 distal66 chain state only as a non-twisted starting point, applies one fixed corrective
FK pass informed by the sacrificial MakeHuman holding-object reference, persists the final
17-bone matrix_basis pose through the v49 durable pose format, reloads it on the same rig,
and renders seed/candidate/thumbnail evidence from one fixed camera.

No source BVH transform is copied. No retargeting, CCD, endpoint chasing, tolerance sweep,
local-axis grid, or candidate parameter sweep exists in this file. Macro/Meso silhouette
remains the only promotion gate.
"""
from __future__ import annotations

import importlib.util
import json
import sys
import traceback
from pathlib import Path

import bpy
from mathutils import Matrix, Vector

BASE = Path(__file__).resolve().parent


def _load(name: str, filename: str):
    spec = importlib.util.spec_from_file_location(name, BASE / filename)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"could not load {filename}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


v44 = _load("mpfb_v44_for_v51", "render_mpfb_pinky_distal_v44.py")
v41 = v44.v43.v42.v41
v35 = v44.v35
v23 = v44.v23
v19 = v44.v19
v49 = _load("mpfb_manual_pose_v49_for_v51", "manual_pose_asset_v49.py")

# One art-directed correction only. These are modest additive joint rotations after the
# frozen v44 distal66 seed, chosen to move the visible long-prong digits into differentiated
# closure depths while preserving the already-stable pinky chain. Values are not searched.
CORRECTION_DEG = {
    "index": (8.0, 22.0, 18.0),
    "middle": (10.0, 28.0, 21.0),
    "ring": (12.0, 32.0, 24.0),
    "pinky": (0.0, 0.0, 0.0),
    "thumb": (18.0, 30.0, 22.0),
}

# A tiny one-time MCP fan breaks the remaining parallel-prong read without changing the
# pose abstraction into a sweep. Rotation is around the palm radial, independently from curl.
MCP_FAN_DEG = {"index": -4.0, "middle": -1.5, "ring": 2.5, "pinky": 5.0}


def _args():
    if "--" not in sys.argv:
        raise RuntimeError("expected -- <xr.glb> <mpfb.glb> <outdir> <pose.json> <report.json>")
    values = sys.argv[sys.argv.index("--") + 1:]
    if len(values) != 5:
        raise RuntimeError("expected <xr.glb> <mpfb.glb> <outdir> <pose.json> <report.json>")
    return tuple(Path(v).resolve() for v in values)


def _apply_manual_correction(arm, center: Vector, axis: Vector) -> None:
    chains = dict(v44.CHAINS)
    palm, _forward, _span, _normal = v35.v33._palm_frame(arm)
    radial = center - palm
    radial -= axis * radial.dot(axis)
    if radial.length < 1e-7:
        raise RuntimeError("v51 degenerate palm radial")
    radial.normalize()

    # Hand-authored MCP spacing first.
    for digit, degrees in MCP_FAN_DEG.items():
        pb = arm.pose.bones.get(chains[digit][0])
        if pb is None:
            raise RuntimeError("v51 missing MCP " + chains[digit][0])
        v41._rotate_pose_bone_about_head(arm, pb, radial, degrees)

    # Then one fixed corrective closure pass on the already stable v44 chains.
    for digit in ("index", "middle", "ring", "pinky"):
        for bone_name, degrees in zip(chains[digit], CORRECTION_DEG[digit]):
            if abs(degrees) < 1e-6:
                continue
            pb = arm.pose.bones.get(bone_name)
            if pb is None:
                raise RuntimeError("v51 missing finger bone " + bone_name)
            v41._bend_toward_center(arm, pb, center, axis, degrees)

    # Thumb remains a separately authored opponent, never mirrored from the fingers.
    for bone_name, degrees in zip(chains["thumb"], CORRECTION_DEG["thumb"]):
        pb = arm.pose.bones.get(bone_name)
        if pb is None:
            raise RuntimeError("v51 missing thumb bone " + bone_name)
        v41._bend_toward_center(arm, pb, center, axis, degrees)
    bpy.context.view_layer.update()


def _render_thumbnail(cam, out: Path, focus: Vector) -> None:
    scene = bpy.context.scene
    old = (scene.render.resolution_x, scene.render.resolution_y, scene.render.resolution_percentage)
    scene.render.resolution_x = 192
    scene.render.resolution_y = 108
    scene.render.resolution_percentage = 100
    try:
        v19._render(cam, out, "manual_support_v51_thumbnail", focus)
    finally:
        scene.render.resolution_x, scene.render.resolution_y, scene.render.resolution_percentage = old


def _matrix_error(a: Matrix, b: Matrix) -> float:
    return max(abs(a[r][c] - b[r][c]) for r in range(4) for c in range(4))


def run() -> None:
    xr_path, mpfb_path, out, pose_path, report_path = _args()
    out.mkdir(parents=True, exist_ok=True)
    pose_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.parent.mkdir(parents=True, exist_ok=True)

    v19._reset()
    xr, xr_meshes = v19._import_armature(xr_path, "XR")
    for mesh in xr_meshes:
        mesh.hide_render = True
        mesh.hide_viewport = True
    arm, meshes = v19._import_armature(mpfb_path, "MPFB")
    cam = v19._setup_render(meshes)
    _, _, _, _, camera_target = v35.v22._neutral_targets(arm)

    v19._clear(arm)
    v23._pose_seed(xr, arm, "Cup_Armature")
    center, axis, inward, _ = v35._fixture_from_seed(arm, 1.0)
    proxy = v35.v33._proxy(center, axis, "ManualSupportV51Vessel")
    focus = camera_target.lerp(center, 0.42)

    whole_rotation_deg, root_shift = v35._orient_whole_hand(arm, center, axis, inward)
    # Freeze exactly the v44 best non-twisted pinky/finger seed; do not search variants.
    v44._apply_candidate(arm, center, axis, 66.0)
    v19._render(cam, out, "manual_support_v51_v44_seed", focus)

    _apply_manual_correction(arm, center, axis)
    expected = {name: arm.pose.bones[name].matrix_basis.copy() for name in v49.BONES}
    payload = v49.save_pose(
        arm,
        pose_path,
        label="v51 manual support-wrap candidate",
        provenance={
            "kind": "manual-fk-support-wrap",
            "production_candidate": False,
            "automatic_retarget": False,
            "retarget_source_transforms_used": False,
            "visual_reference": "MakeHuman Poses 01 holding-wine-glass CC0, anatomy reference only",
            "source_pack_sha256": "67b1d14923adda85f371f81e1c529fcd058f975d0bf93848838e1a3860705b7d",
            "seed": "frozen v44 distal66 stable chain state",
            "note": "One fixed corrective FK candidate; must pass Macro/Meso review before any production use.",
        },
    )

    # Prove the durable asset, not hidden script state, reproduces the final finger shape.
    v49.clear_pose(arm)
    v49.load_pose(arm, pose_path)
    reload_errors = {name: _matrix_error(expected[name], arm.pose.bones[name].matrix_basis) for name in v49.BONES}
    max_reload_error = max(reload_errors.values())
    if max_reload_error > 1e-6:
        raise RuntimeError(f"v51 durable pose reload changed matrices: {max_reload_error}")

    v19._render(cam, out, "manual_support_v51_candidate", focus)
    _render_thumbnail(cam, out, focus)

    metrics = v44.v38._metrics(arm, center, axis)
    report = {
        "staging_only": True,
        "production_candidate": False,
        "automatic_retarget": False,
        "retarget_source_transforms_used": False,
        "pose_format": payload["format"],
        "pose_bone_count": len(payload["bones"]),
        "max_reload_matrix_error": max_reload_error,
        "whole_rotation_deg": whole_rotation_deg,
        "root_shift": root_shift,
        "palm_clearance": metrics["palm_clearance"],
        "normal_alignment": metrics["normal_alignment"],
        "min_tip_spacing": metrics["min_tip_spacing"],
        "closest_pair": metrics["closest_pair"],
        "thumb_near_dot": metrics["thumb_near_dot"],
        "finger_near_dots": metrics["finger_near_dots"],
        "visual_gate": "Human vessel-wrap silhouette, progressive finger depth, clear thumb opposition, no prongs/self-intersection. Metrics cannot promote the candidate.",
    }
    report_path.write_text(json.dumps(report, indent=2, sort_keys=True), encoding="utf-8")
    print(json.dumps(report, indent=2, sort_keys=True))
    print("MPFB_MANUAL_SUPPORT_V51_SUCCESS")

    bpy.data.objects.remove(proxy, do_unlink=True)


if __name__ == "__main__":
    try:
        run()
    except BaseException as exc:
        print("MPFB_MANUAL_SUPPORT_V51_ERROR:", exc)
        traceback.print_exc()
        raise
