#!/usr/bin/env python3
"""v52: explicit GameEngine FK support grasp with no target solver/helper.

The only starting context borrowed from the XR asset is the coarse arm placement (`Cup_Armature`)
so the hand is staged in the same region as previous experiments. Every persisted hero-limb
pose bone is then written through a fixed, hand-authored local FK delta table. No CCD,
endpoint chasing, surface servo, world-direction alignment, `_bend_toward_center`, axis sweep,
or external BVH transform is used.

This is one falsifiable visual candidate, not a parameter search. Promotion is visual-only.
"""
from __future__ import annotations

import importlib.util
import json
import math
import sys
import traceback
from pathlib import Path

import bpy
from mathutils import Euler, Matrix, Vector

BASE = Path(__file__).resolve().parent


def _load(name: str, filename: str):
    spec = importlib.util.spec_from_file_location(name, BASE / filename)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"could not load {filename}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


v19 = _load("mpfb_v19_for_v52", "render_mpfb_retarget_preview_v19.py")
v23 = _load("mpfb_v23_for_v52", "render_mpfb_contact_ik_v23.py")
v35 = _load("mpfb_v35_for_v52", "render_mpfb_canonical_grip_v35.py")
v49 = _load("mpfb_manual_pose_v49_for_v52", "manual_pose_asset_v49.py")

# Explicit artist-authored local FK deltas, degrees XYZ, applied on top of the coarse Cup arm
# placement only. Each joint has its own values; there is no shared curl equation.
# The pattern intentionally differentiates depth: index closes soonest/deepest behind the far
# contour, then middle/ring/pinky step progressively toward the near side. Thumb is independent.
ARTIST_DELTA_DEG = {
    "lowerarm_r": (-6.0, 7.0, -12.0),
    "hand_r": (8.0, -18.0, 24.0),
    "thumb_01_r": (18.0, -34.0, 26.0),
    "thumb_02_r": (26.0, -18.0, 18.0),
    "thumb_03_r": (20.0, -8.0, 10.0),
    "index_01_r": (-12.0, 24.0, 34.0),
    "index_02_r": (-6.0, 12.0, 48.0),
    "index_03_r": (-2.0, 8.0, 34.0),
    "middle_01_r": (-8.0, 19.0, 31.0),
    "middle_02_r": (-4.0, 10.0, 43.0),
    "middle_03_r": (-1.0, 6.0, 31.0),
    "ring_01_r": (-3.0, 14.0, 28.0),
    "ring_02_r": (1.0, 8.0, 39.0),
    "ring_03_r": (3.0, 4.0, 28.0),
    "pinky_01_r": (3.0, 9.0, 24.0),
    "pinky_02_r": (6.0, 5.0, 34.0),
    "pinky_03_r": (8.0, 2.0, 24.0),
}


def _args():
    if "--" not in sys.argv:
        raise RuntimeError("expected -- <xr.glb> <mpfb.glb> <outdir> <pose.json> <report.json>")
    values = sys.argv[sys.argv.index("--") + 1:]
    if len(values) != 5:
        raise RuntimeError("expected <xr.glb> <mpfb.glb> <outdir> <pose.json> <report.json>")
    return tuple(Path(v).resolve() for v in values)


def _delta_matrix(deg_xyz) -> Matrix:
    radians = tuple(math.radians(float(v)) for v in deg_xyz)
    return Euler(radians, "XYZ").to_matrix().to_4x4()


def _apply_explicit_fk(arm) -> dict[str, list[float]]:
    written = {}
    missing = [name for name in v49.BONES if name not in ARTIST_DELTA_DEG or arm.pose.bones.get(name) is None]
    if missing:
        raise RuntimeError(f"v52 explicit FK table incomplete: {missing}")
    for name in v49.BONES:
        pb = arm.pose.bones[name]
        # Keep coarse pose-bone translation from the arm-placement seed, but replace rotation
        # with one explicit artist delta composed on the current local basis.
        base = pb.matrix_basis.copy()
        location = base.to_translation()
        scale = base.to_scale()
        rotation = base.to_quaternion().to_matrix().to_4x4() @ _delta_matrix(ARTIST_DELTA_DEG[name])
        basis = Matrix.Translation(location) @ rotation
        for axis in range(3):
            basis[axis][axis] *= scale[axis]
        pb.matrix_basis = basis
        written[name] = [float(basis[r][c]) for r in range(4) for c in range(4)]
    bpy.context.view_layer.update()
    return written


def _make_proxy(arm):
    hand = arm.pose.bones["hand_r"]
    index = arm.pose.bones["index_01_r"]
    middle = arm.pose.bones["middle_01_r"]
    palm = (hand.head + hand.tail + index.head + middle.head) * 0.25
    # Use world Z as vessel axis; place the proxy slightly palm-inward and forward from the MCP
    # cluster. This is staging geometry only and does not drive the hand pose.
    center = Vector((palm.x - 0.030, palm.y + 0.060, palm.z + 0.010))
    bpy.ops.mesh.primitive_cylinder_add(vertices=64, radius=0.040, depth=0.155, location=center)
    proxy = bpy.context.object
    proxy.name = "DirectFKV52Vessel"
    mat = bpy.data.materials.new("DirectFKV52VesselMat")
    mat.diffuse_color = (0.16, 0.22, 0.29, 1.0)
    proxy.data.materials.append(mat)
    return proxy, center


def _render_thumbnail(cam, out: Path, focus: Vector) -> None:
    scene = bpy.context.scene
    old = (scene.render.resolution_x, scene.render.resolution_y, scene.render.resolution_percentage)
    scene.render.resolution_x = 192
    scene.render.resolution_y = 108
    scene.render.resolution_percentage = 100
    try:
        v19._render(cam, out, "direct_fk_v52_thumbnail", focus)
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

    v19._clear(arm)
    # Coarse arm placement only; all 17 persisted hero-limb bones are subsequently rewritten.
    v23._pose_seed(xr, arm, "Cup_Armature")
    explicit = _apply_explicit_fk(arm)
    proxy, center = _make_proxy(arm)
    camera_target = v35.v22._neutral_targets(arm)[4]
    focus = camera_target.lerp(center, 0.55)

    expected = {name: arm.pose.bones[name].matrix_basis.copy() for name in v49.BONES}
    payload = v49.save_pose(
        arm,
        pose_path,
        label="v52 direct explicit FK support-wrap candidate",
        provenance={
            "kind": "direct-explicit-fk-support-wrap",
            "production_candidate": False,
            "automatic_retarget": False,
            "retarget_source_transforms_used": False,
            "target_solver_used": False,
            "bend_toward_center_used": False,
            "visual_reference": "MakeHuman Poses 01 holding-wine-glass CC0, anatomy guide only",
            "source_pack_sha256": "67b1d14923adda85f371f81e1c529fcd058f975d0bf93848838e1a3860705b7d",
            "note": "Single hand-authored per-joint FK candidate; Macro/Meso visual gate only.",
        },
    )

    v49.clear_pose(arm)
    v49.load_pose(arm, pose_path)
    reload_errors = {name: _matrix_error(expected[name], arm.pose.bones[name].matrix_basis) for name in v49.BONES}
    max_reload_error = max(reload_errors.values())
    if max_reload_error > 1e-6:
        raise RuntimeError(f"v52 durable pose reload changed matrices: {max_reload_error}")

    v19._render(cam, out, "direct_fk_v52_candidate", focus)
    _render_thumbnail(cam, out, focus)

    report = {
        "staging_only": True,
        "production_candidate": False,
        "automatic_retarget": False,
        "retarget_source_transforms_used": False,
        "target_solver_used": False,
        "bend_toward_center_used": False,
        "pose_format": payload["format"],
        "pose_bone_count": len(payload["bones"]),
        "max_reload_matrix_error": max_reload_error,
        "explicit_fk_bone_count": len(explicit),
        "visual_gate": "Thumbnail must read as hand wrapping vessel: differentiated finger depth, far-contour disappearance, opposing thumb, no prongs or torn-palm silhouette.",
    }
    report_path.write_text(json.dumps(report, indent=2, sort_keys=True), encoding="utf-8")
    print(json.dumps(report, indent=2, sort_keys=True))
    print("MPFB_DIRECT_FK_V52_SUCCESS")

    bpy.data.objects.remove(proxy, do_unlink=True)


if __name__ == "__main__":
    try:
        run()
    except BaseException as exc:
        print("MPFB_DIRECT_FK_V52_ERROR:", exc)
        traceback.print_exc()
        raise
