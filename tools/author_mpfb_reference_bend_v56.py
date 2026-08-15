#!/usr/bin/env python3
"""v56: transfer only bounded relative bend structure from the CC0 holding-glass reference.

v55 proved that copying absolute segment directions in a palm frame is still too aggressive:
it produced severe chain twisting/self-intersection even though no source transforms were copied.
v56 keeps the already-stable GameEngine whole-hand placement and transfers only two kinds of
anatomical evidence from the sacrificial CC0 BVH: a bounded proximal pitch and the relative
angle between adjacent source phalanges. Target directions are rebuilt recursively in the
GameEngine palm closing plane. No source matrix, bone roll, translation, scale, endpoint,
CCD, optimizer or parameter sweep is used. Staging-only; the 192x108 silhouette is binding.
"""
from __future__ import annotations

import importlib.util
import json
import math
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

v55 = _load("mpfb_v55_for_v56", "author_mpfb_reference_direction_v55.py")
v53 = _load("mpfb_v53_for_v56", "author_mpfb_anatomical_controls_v53.py")
v42 = v55.v42
v35 = v55.v35
v23 = v55.v23
v19 = v55.v19
v49 = v55.v49
CHAINS = dict(v55.CHAINS)
SOURCE_CHAINS = dict(v55.SOURCE_CHAINS)


def _args():
    if "--" not in sys.argv:
        raise RuntimeError("expected -- XR.glb MPFB.glb SOURCE.bvh OUTDIR POSE.json REPORT.json")
    values = sys.argv[sys.argv.index("--") + 1:]
    if len(values) != 6:
        raise RuntimeError("expected six arguments")
    return tuple(Path(v).resolve() for v in values)


def _source_bend_contract(source):
    forward, span, normal = v55._source_palm_frame(source)
    contract = {}
    for digit in ("index", "middle", "ring", "pinky"):
        dirs = [v55._world_segment(source, v55._find_pose_bone_ci(source, n)) for n in SOURCE_CHAINS[digit]]
        f = dirs[0].dot(forward)
        n = dirs[0].dot(normal)
        # Holding-glass references can contain extreme perspective/rig bends. Preserve the
        # anatomical tendency but bound it so a single source pose cannot explode the target.
        proximal_pitch = max(12.0, min(48.0, math.degrees(math.atan2(abs(n), max(1e-5, f)))))
        bends = []
        for a, b in zip(dirs, dirs[1:]):
            dot = max(-1.0, min(1.0, a.dot(b)))
            bends.append(max(10.0, min(52.0, math.degrees(math.acos(dot)))))
        lateral = max(-0.20, min(0.20, dirs[0].dot(span)))
        contract[digit] = {
            "proximal_pitch_deg": proximal_pitch,
            "relative_bend_deg": bends,
            "lateral": lateral,
        }
    return contract


def _target_palm_world(arm, inward: Vector):
    _palm, forward_l, span_l, normal_l = v53._local_palm_frame(arm)
    basis = arm.matrix_world.to_3x3()
    forward = (basis @ forward_l).normalized()
    span = (basis @ span_l).normalized()
    normal = (basis @ normal_l).normalized()
    if normal.dot(inward) < 0.0:
        normal *= -1.0
    return forward, span, normal


def _rotate_toward_normal(direction: Vector, normal: Vector, degrees: float) -> Vector:
    d = direction.normalized()
    n = normal.normalized()
    axis = d.cross(n)
    if axis.length < 1e-7:
        return d
    axis.normalize()
    # Choose the sign which increases the component toward the vessel-facing/palmar normal.
    r = math.radians(degrees)
    pos = Matrix.Rotation(r, 3, axis) @ d
    neg = Matrix.Rotation(-r, 3, axis) @ d
    return (pos if pos.dot(n) >= neg.dot(n) else neg).normalized()


def _apply_reference_bends(arm, inward: Vector, contract):
    forward, span, normal = _target_palm_world(arm, inward)
    rotations = {}
    desired_rows = {}
    for digit in ("index", "middle", "ring", "pinky"):
        row = contract[digit]
        pitch = math.radians(row["proximal_pitch_deg"])
        desired = forward * math.cos(pitch) + normal * math.sin(pitch) + span * row["lateral"]
        desired.normalize()
        rotations[digit] = []
        desired_rows[digit] = []
        chain = CHAINS[digit]
        for i, bone_name in enumerate(chain):
            if i > 0:
                desired = _rotate_toward_normal(desired, normal, row["relative_bend_deg"][i - 1])
            pb = arm.pose.bones.get(bone_name)
            if pb is None:
                raise RuntimeError("missing target bone " + bone_name)
            desired_rows[digit].append([float(v) for v in desired])
            rotations[digit].append(v42._rotate_pose_bone_world_to_direction(arm, pb, desired))
    # Keep the bounded semantic thumb opposition from v53. v55 proved that absolute source
    # thumb direction transfer is especially destructive (over 100 degrees at the base).
    _palm, f_l, s_l, n_l = v53._local_palm_frame(arm)
    basis = arm.matrix_world.to_3x3()
    n_w = (basis @ n_l).normalized()
    if n_w.dot(inward) < 0.0:
        n_l *= -1.0
    thumb = v53._apply_thumb_controls(arm, f_l, s_l, n_l)
    bpy.context.view_layer.update()
    return rotations, desired_rows, thumb


def _matrix_error(a, b):
    return max(abs(a[r][c] - b[r][c]) for r in range(4) for c in range(4))


def _render_thumbnail(cam, out: Path, focus: Vector):
    scene = bpy.context.scene
    old = (scene.render.resolution_x, scene.render.resolution_y, scene.render.resolution_percentage)
    scene.render.resolution_x, scene.render.resolution_y, scene.render.resolution_percentage = 192, 108, 100
    try:
        v19._render(cam, out, "reference_bend_v56_thumbnail", focus)
    finally:
        scene.render.resolution_x, scene.render.resolution_y, scene.render.resolution_percentage = old


def run():
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
    contract = _source_bend_contract(source)

    v19._clear(arm)
    v23._pose_seed(xr, arm, "Cup_Armature")
    center, axis, inward, _ = v35._fixture_from_seed(arm, 1.0)
    proxy = v35.v33._proxy(center, axis, "ReferenceBendV56Vessel")
    focus = camera_target.lerp(center, 0.42)
    whole_rotation_deg, root_shift = v35._orient_whole_hand(arm, center, axis, inward)
    rotations, desired_rows, thumb = _apply_reference_bends(arm, inward, contract)

    expected = {name: arm.pose.bones[name].matrix_basis.copy() for name in v49.BONES}
    payload = v49.save_pose(arm, pose_path, label="v56 bounded CC0-reference bend support-wrap candidate", provenance={
        "kind": "bounded-reference-relative-bend-transfer",
        "production_candidate": False,
        "source_pose": "MakeHuman Poses 01 holding-wine-glass",
        "source_license": "CC0",
        "automatic_retarget": False,
        "source_matrices_copied": False,
        "source_bone_roll_copied": False,
        "source_translations_copied": False,
        "source_absolute_directions_copied": False,
        "note": "Only bounded proximal pitch and adjacent-phalanx bend angles are used; target pose is rebuilt in the GameEngine palm closing plane.",
    })
    v49.clear_pose(arm)
    v49.load_pose(arm, pose_path)
    max_reload_error = max(_matrix_error(expected[n], arm.pose.bones[n].matrix_basis) for n in v49.BONES)
    if max_reload_error > 1e-6:
        raise RuntimeError(f"v56 durable pose reload changed matrices: {max_reload_error}")

    v19._render(cam, out, "reference_bend_v56_candidate", focus)
    _render_thumbnail(cam, out, focus)
    report = {
        "staging_only": True,
        "production_candidate": False,
        "automatic_retarget": False,
        "source_matrices_copied": False,
        "source_bone_roll_copied": False,
        "source_translations_copied": False,
        "source_absolute_directions_copied": False,
        "pose_bone_count": len(payload["bones"]),
        "max_reload_matrix_error": max_reload_error,
        "whole_rotation_deg": whole_rotation_deg,
        "root_shift": root_shift,
        "reference_bend_contract": contract,
        "segment_rotation_deg": rotations,
        "desired_segment_directions": desired_rows,
        "thumb_controls": thumb,
        "visual_gate": "192x108 must immediately read as a coherent human vessel wrap: no detached-looking phalanges, progressive far-contour enclosure, clear thumb opposition.",
    }
    report_path.write_text(json.dumps(report, indent=2, sort_keys=True), encoding="utf-8")
    bpy.data.objects.remove(proxy, do_unlink=True)
    print(json.dumps(report, indent=2, sort_keys=True))
    print("MPFB_REFERENCE_BEND_V56_SUCCESS")


if __name__ == "__main__":
    try:
        run()
    except BaseException as exc:
        print("MPFB_REFERENCE_BEND_V56_ERROR:", exc)
        traceback.print_exc()
        raise
