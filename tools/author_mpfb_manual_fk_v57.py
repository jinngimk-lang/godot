#!/usr/bin/env python3
"""v57: true target-rig manual FK support-wrap candidate.

This is intentionally not a solver, retargeter, geometry fit, or parameter sweep.
It imports only the MPFB GameEngine human, clears the pose, and writes one explicit
17-bone target-rig FK pose. The pose is built in meaningful authoring stages and
rendered after each stage so visual review can freeze improvements joint-by-joint.

No XR pose, BVH matrix, source bone roll, source translation, endpoint target,
reference-derived direction, CCD, surface servo, or automatic contact optimizer is
read or applied to the target rig.
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


v19 = _load("mpfb_v19_for_v57", "render_mpfb_retarget_preview_v19.py")
v49 = _load("mpfb_manual_pose_v49_for_v57", "manual_pose_asset_v49.py")

# One deliberately explicit target-rig pose. Values are local XYZ degrees from
# target-rig rest, not deltas copied from any source asset. The ordering is the
# authoring order used below: whole-hand composition -> thumb opposition ->
# index enclosure -> middle/ring enclosure -> pinky finish.
MANUAL_FK_DEG = {
    "lowerarm_r": (-10.0, 5.0, -20.0),
    "hand_r": (12.0, -30.0, 34.0),
    "thumb_01_r": (24.0, -52.0, 38.0),
    "thumb_02_r": (34.0, -24.0, 20.0),
    "thumb_03_r": (26.0, -10.0, 12.0),
    "index_01_r": (-18.0, 18.0, 54.0),
    "index_02_r": (-10.0, 10.0, 68.0),
    "index_03_r": (-4.0, 6.0, 44.0),
    "middle_01_r": (-12.0, 13.0, 50.0),
    "middle_02_r": (-6.0, 8.0, 64.0),
    "middle_03_r": (-2.0, 4.0, 42.0),
    "ring_01_r": (-6.0, 8.0, 46.0),
    "ring_02_r": (0.0, 5.0, 59.0),
    "ring_03_r": (3.0, 2.0, 39.0),
    "pinky_01_r": (2.0, 2.0, 40.0),
    "pinky_02_r": (7.0, 1.0, 52.0),
    "pinky_03_r": (10.0, 0.0, 32.0),
}

STAGES = [
    ("01_palm", ["lowerarm_r", "hand_r"]),
    ("02_thumb", ["thumb_01_r", "thumb_02_r", "thumb_03_r"]),
    ("03_index", ["index_01_r", "index_02_r", "index_03_r"]),
    ("04_middle_ring", [
        "middle_01_r", "middle_02_r", "middle_03_r",
        "ring_01_r", "ring_02_r", "ring_03_r",
    ]),
    ("05_pinky", ["pinky_01_r", "pinky_02_r", "pinky_03_r"]),
]


def _args():
    if "--" not in sys.argv:
        raise RuntimeError("expected -- <mpfb.glb> <outdir> <pose.json> <report.json>")
    values = sys.argv[sys.argv.index("--") + 1:]
    if len(values) != 4:
        raise RuntimeError("expected four arguments")
    return tuple(Path(v).resolve() for v in values)


def _basis_from_deg(deg_xyz) -> Matrix:
    radians = tuple(math.radians(float(v)) for v in deg_xyz)
    return Euler(radians, "XYZ").to_matrix().to_4x4()


def _write_bone(arm, name: str) -> None:
    pb = arm.pose.bones.get(name)
    if pb is None:
        raise RuntimeError("missing v57 target bone " + name)
    pb.matrix_basis = _basis_from_deg(MANUAL_FK_DEG[name])
    bpy.context.view_layer.update()


def _palm_point(arm) -> Vector:
    names = ["hand_r", "index_01_r", "middle_01_r", "ring_01_r", "pinky_01_r"]
    return sum((arm.pose.bones[n].head for n in names), Vector()) / float(len(names))


def _make_proxy(arm):
    # Staging-only product prop. It is positioned after the manual hand pose and
    # never drives a bone. The upright cylinder approximates the locked bottle scale.
    palm = _palm_point(arm)
    center = palm + Vector((-0.035, 0.052, 0.006))
    bpy.ops.mesh.primitive_cylinder_add(vertices=64, radius=0.040, depth=0.155, location=center)
    proxy = bpy.context.object
    proxy.name = "ManualFKV57Vessel"
    mat = bpy.data.materials.new("ManualFKV57VesselMat")
    mat.diffuse_color = (0.12, 0.18, 0.24, 1.0)
    proxy.data.materials.append(mat)
    return proxy, center


def _render(cam, out: Path, stem: str, focus: Vector, thumb=False) -> None:
    v19._render(cam, out, stem, focus)
    if thumb:
        scene = bpy.context.scene
        old = (scene.render.resolution_x, scene.render.resolution_y, scene.render.resolution_percentage)
        scene.render.resolution_x = 192
        scene.render.resolution_y = 108
        scene.render.resolution_percentage = 100
        try:
            v19._render(cam, out, stem + "_thumbnail", focus)
        finally:
            scene.render.resolution_x, scene.render.resolution_y, scene.render.resolution_percentage = old


def _matrix_error(a: Matrix, b: Matrix) -> float:
    return max(abs(a[r][c] - b[r][c]) for r in range(4) for c in range(4))


def run() -> None:
    mpfb_path, out, pose_path, report_path = _args()
    out.mkdir(parents=True, exist_ok=True)
    pose_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.parent.mkdir(parents=True, exist_ok=True)

    v19._reset()
    arm, meshes = v19._import_armature(mpfb_path, "MPFB")
    cam = v19._setup_render(meshes)
    v19._clear(arm)

    if set(MANUAL_FK_DEG) != set(v49.BONES):
        missing = sorted(set(v49.BONES) - set(MANUAL_FK_DEG))
        extra = sorted(set(MANUAL_FK_DEG) - set(v49.BONES))
        raise RuntimeError(f"v57 manual table mismatch missing={missing} extra={extra}")

    # The proxy exists only to judge support enclosure. Place it after whole-hand
    # composition, then keep it frozen while later digit edits are authored.
    for name in STAGES[0][1]:
        _write_bone(arm, name)
    proxy, center = _make_proxy(arm)
    focus = _palm_point(arm).lerp(center, 0.55)
    _render(cam, out, "manual_fk_v57_01_palm", focus)

    for stage_name, names in STAGES[1:]:
        for name in names:
            _write_bone(arm, name)
        _render(cam, out, "manual_fk_v57_" + stage_name, focus)

    expected = {name: arm.pose.bones[name].matrix_basis.copy() for name in v49.BONES}
    payload = v49.save_pose(
        arm,
        pose_path,
        label="v57 artist-authored target-rig support wrap",
        provenance={
            "kind": "artist-authored-target-rig",
            "production_candidate": False,
            "automatic_retarget": False,
            "source_transforms_used": False,
            "source_directions_used": False,
            "target_solver_used": False,
            "visual_reference": "locked Peel Calm cafe_v1/bar_v1/market_v1; CC0 holding-object anatomy viewed side-by-side only",
            "authoring_order": [name for name, _ in STAGES],
            "note": "Single explicit 17-bone FK candidate. No parameter sweep. Promotion is Macro/Meso visual-only.",
        },
    )

    v49.clear_pose(arm)
    v49.load_pose(arm, pose_path)
    errors = {name: _matrix_error(expected[name], arm.pose.bones[name].matrix_basis) for name in v49.BONES}
    max_reload_error = max(errors.values())
    if max_reload_error > 1e-6:
        raise RuntimeError(f"v57 durable pose reload changed matrices: {max_reload_error}")

    _render(cam, out, "manual_fk_v57_final", focus, thumb=True)

    report = {
        "staging_only": True,
        "production_candidate": False,
        "kind": "artist-authored-target-rig",
        "automatic_retarget": False,
        "source_transforms_used": False,
        "source_directions_used": False,
        "target_solver_used": False,
        "pose_bone_count": len(payload["bones"]),
        "max_reload_matrix_error": max_reload_error,
        "manual_fk_deg": {k: list(v) for k, v in MANUAL_FK_DEG.items()},
        "authoring_stages": [name for name, _ in STAGES],
        "visual_gate": "192x108 must immediately read as a human support wrap: palm framing near side, thumb opposing the finger group, at least two non-thumb fingers disappearing around far contour, progressive non-parallel curl, no detached phalanges or solver kinks.",
    }
    report_path.write_text(json.dumps(report, indent=2, sort_keys=True), encoding="utf-8")
    print(json.dumps(report, indent=2, sort_keys=True))
    print("MPFB_MANUAL_FK_V57_SUCCESS")
    bpy.data.objects.remove(proxy, do_unlink=True)


if __name__ == "__main__":
    try:
        run()
    except BaseException as exc:
        print("MPFB_MANUAL_FK_V57_ERROR:", exc)
        traceback.print_exc()
        raise
