#!/usr/bin/env python3
"""v55: one anatomical-reference direction-transfer support grasp.

v54 proved that deriving a flexion axis from the target phalanx itself still produces a
straight/fanned Macro silhouette. v55 stops axis/angle search. It imports the official CC0
MakeHuman holding-wine-glass BVH into a sacrificial armature, measures each posed finger
segment direction in that source palm frame, maps only those normalized directions into the
MPFB GameEngine palm frame, and aligns the target phalanges by shortest-arc world rotations.

No BVH matrix, bone roll, translation, scale or pose-bone transform is copied. No CCD,
endpoint target, tolerance, optimizer or candidate sweep exists. The resulting 17-bone
matrix_basis pose is persisted through the durable v49 format and remains staging-only until
its full + 192x108 renders pass Macro/Meso review.
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


v42 = _load("mpfb_v42_for_v55", "render_mpfb_world_arc_grasp_v42.py")
v35 = v42.v35
v23 = v42.v23
v19 = v42.v19
v49 = _load("mpfb_manual_pose_v49_for_v55", "manual_pose_asset_v49.py")
CHAINS = dict(v42.CHAINS)
SOURCE_CHAINS = {
    "thumb": ("finger1-1.r", "finger1-2.r", "finger1-3.r"),
    "index": ("finger2-1.r", "finger2-2.r", "finger2-3.r"),
    "middle": ("finger3-1.r", "finger3-2.r", "finger3-3.r"),
    "ring": ("finger4-1.r", "finger4-2.r", "finger4-3.r"),
    "pinky": ("finger5-1.r", "finger5-2.r", "finger5-3.r"),
}


def _args():
    if "--" not in sys.argv:
        raise RuntimeError("expected -- XR.glb MPFB.glb SOURCE.bvh OUTDIR POSE.json REPORT.json")
    values = sys.argv[sys.argv.index("--") + 1:]
    if len(values) != 6:
        raise RuntimeError("expected XR.glb MPFB.glb SOURCE.bvh OUTDIR POSE.json REPORT.json")
    return tuple(Path(v).resolve() for v in values)


def _find_pose_bone_ci(arm, name: str):
    wanted = name.lower()
    for pb in arm.pose.bones:
        if pb.name.lower() == wanted:
            return pb
    raise RuntimeError("missing source bone " + name)


def _world_head(arm, pb) -> Vector:
    return arm.matrix_world @ pb.head


def _world_segment(arm, pb) -> Vector:
    d = (arm.matrix_world @ pb.tail) - (arm.matrix_world @ pb.head)
    if d.length < 1e-7:
        raise RuntimeError("zero-length source segment " + pb.name)
    return d.normalized()


def _source_palm_frame(arm):
    wrist = _find_pose_bone_ci(arm, "wrist.r")
    index = _find_pose_bone_ci(arm, SOURCE_CHAINS["index"][0])
    middle = _find_pose_bone_ci(arm, SOURCE_CHAINS["middle"][0])
    pinky = _find_pose_bone_ci(arm, SOURCE_CHAINS["pinky"][0])
    forward = _world_head(arm, middle) - _world_head(arm, wrist)
    span = _world_head(arm, index) - _world_head(arm, pinky)
    if forward.length < 1e-7 or span.length < 1e-7:
        raise RuntimeError("degenerate source palm frame")
    forward.normalize()
    span -= forward * span.dot(forward)
    span.normalize()
    normal = forward.cross(span)
    if normal.length < 1e-7:
        raise RuntimeError("degenerate source palm normal")
    normal.normalize()
    span = normal.cross(forward).normalized()
    return forward, span, normal


def _source_direction_coefficients(source):
    forward, span, normal = _source_palm_frame(source)
    result = {}
    for digit, names in SOURCE_CHAINS.items():
        result[digit] = []
        for name in names:
            pb = _find_pose_bone_ci(source, name)
            d = _world_segment(source, pb)
            result[digit].append((d.dot(forward), d.dot(span), d.dot(normal)))
    return result


def _target_direction(coeff, forward: Vector, span: Vector, normal: Vector) -> Vector:
    d = forward * coeff[0] + span * coeff[1] + normal * coeff[2]
    if d.length < 1e-7:
        raise RuntimeError("degenerate mapped direction")
    return d.normalized()


def _apply_reference_directions(arm, coefficients):
    _palm, forward, span, normal = v35.v33._palm_frame(arm)
    rotations = {}
    for digit in ("index", "middle", "ring", "pinky", "thumb"):
        rotations[digit] = []
        for target_name, coeff in zip(CHAINS[digit], coefficients[digit]):
            pb = arm.pose.bones.get(target_name)
            if pb is None:
                raise RuntimeError("missing target bone " + target_name)
            desired = _target_direction(coeff, forward, span, normal)
            rotations[digit].append(v42._rotate_pose_bone_world_to_direction(arm, pb, desired))
    bpy.context.view_layer.update()
    return rotations


def _render_thumbnail(cam, out: Path, focus: Vector) -> None:
    scene = bpy.context.scene
    old = (scene.render.resolution_x, scene.render.resolution_y, scene.render.resolution_percentage)
    scene.render.resolution_x, scene.render.resolution_y, scene.render.resolution_percentage = 192, 108, 100
    try:
        v19._render(cam, out, "reference_direction_v55_thumbnail", focus)
    finally:
        scene.render.resolution_x, scene.render.resolution_y, scene.render.resolution_percentage = old


def _matrix_error(a: Matrix, b: Matrix) -> float:
    return max(abs(a[r][c] - b[r][c]) for r in range(4) for c in range(4))


def run() -> None:
    xr_path, mpfb_path, bvh_path, out, pose_path, report_path = _args()
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

    bpy.ops.import_anim.bvh(filepath=str(bvh_path), frame_start=1, update_scene_fps=True)
    sources = [o for o in bpy.context.scene.objects if o.type == "ARMATURE" and o not in {xr, arm}]
    if len(sources) != 1:
        raise RuntimeError(f"expected one sacrificial source armature, got {len(sources)}")
    source = sources[0]
    source.hide_render = True
    source.hide_viewport = True
    bpy.context.scene.frame_set(1)
    coefficients = _source_direction_coefficients(source)

    v19._clear(arm)
    v23._pose_seed(xr, arm, "Cup_Armature")
    center, axis, inward, _ = v35._fixture_from_seed(arm, 1.0)
    proxy = v35.v33._proxy(center, axis, "ReferenceDirectionV55Vessel")
    focus = camera_target.lerp(center, 0.42)
    whole_rotation_deg, root_shift = v35._orient_whole_hand(arm, center, axis, inward)
    rotations = _apply_reference_directions(arm, coefficients)

    expected = {name: arm.pose.bones[name].matrix_basis.copy() for name in v49.BONES}
    payload = v49.save_pose(
        arm,
        pose_path,
        label="v55 CC0-reference directional support-wrap candidate",
        provenance={
            "kind": "anatomical-reference-direction-transfer",
            "production_candidate": False,
            "source_pose": "MakeHuman Poses 01 holding-wine-glass",
            "source_license": "CC0",
            "automatic_retarget": False,
            "source_matrices_copied": False,
            "source_bone_roll_copied": False,
            "source_translations_copied": False,
            "note": "Only normalized segment directions in a sacrificial palm coordinate frame are mapped; Macro/Meso review remains authoritative.",
        },
    )
    v49.clear_pose(arm)
    v49.load_pose(arm, pose_path)
    max_reload_error = max(_matrix_error(expected[name], arm.pose.bones[name].matrix_basis) for name in v49.BONES)
    if max_reload_error > 1e-6:
        raise RuntimeError(f"v55 durable pose reload changed matrices: {max_reload_error}")

    v19._render(cam, out, "reference_direction_v55_candidate", focus)
    _render_thumbnail(cam, out, focus)
    report = {
        "staging_only": True,
        "production_candidate": False,
        "automatic_retarget": False,
        "source_matrices_copied": False,
        "source_bone_roll_copied": False,
        "source_translations_copied": False,
        "pose_format": payload["format"],
        "pose_bone_count": len(payload["bones"]),
        "max_reload_matrix_error": max_reload_error,
        "whole_rotation_deg": whole_rotation_deg,
        "root_shift": root_shift,
        "source_direction_coefficients": {k: [list(v) for v in vals] for k, vals in coefficients.items()},
        "segment_rotation_deg": rotations,
        "visual_gate": "192x108 must immediately read as human vessel wrap with progressive far-contour enclosure and clear thumb opposition; technical success cannot promote it.",
    }
    report_path.write_text(json.dumps(report, indent=2, sort_keys=True), encoding="utf-8")
    bpy.data.objects.remove(proxy, do_unlink=True)
    print(json.dumps(report, indent=2, sort_keys=True))
    print("MPFB_REFERENCE_DIRECTION_V55_SUCCESS")


if __name__ == "__main__":
    try:
        run()
    except BaseException as exc:
        print("MPFB_REFERENCE_DIRECTION_V55_ERROR:", exc)
        traceback.print_exc()
        raise
