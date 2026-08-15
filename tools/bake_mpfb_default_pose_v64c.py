#!/usr/bin/env python3
"""v64c: evidence-only multi-view proof for the native same-rig baked support pose.

v64b proved that the adaptive crop retains every canonical right-hand/forearm segment, but its
product-like vessel proxy occludes almost the entire hand in the persisted render. That image
cannot distinguish a bad pose from a bad evidence view. v64c changes no pose, crop, source,
rig, deformation, vessel transform, export or production hypothesis. After v64b finishes, it
renders the exact same baked static limb without the vessel from deterministic object-fit
front and oblique cameras, while preserving the original with-vessel render as the Macro view.
"""
from __future__ import annotations

import importlib.util
import json
import sys
from pathlib import Path

import bpy
from mathutils import Vector

BASE = Path(__file__).resolve().parent
SPEC = importlib.util.spec_from_file_location("mpfb_v64b_for_v64c", BASE / "bake_mpfb_default_pose_v64b.py")
if SPEC is None or SPEC.loader is None:
    raise RuntimeError("could not load v64b base")
v64b = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(v64b)


def _args_report_path() -> Path:
    if "--" not in sys.argv:
        raise RuntimeError("missing v64c args")
    values = sys.argv[sys.argv.index("--") + 1:]
    if len(values) != 5:
        raise RuntimeError("expected v64-compatible five arguments")
    return Path(values[4]).resolve()


def _world_bounds(obj):
    corners = [obj.matrix_world @ Vector(c) for c in obj.bound_box]
    minimum = Vector((min(p.x for p in corners), min(p.y for p in corners), min(p.z for p in corners)))
    maximum = Vector((max(p.x for p in corners), max(p.y for p in corners), max(p.z for p in corners)))
    return minimum, maximum


def _fit_camera(name: str, obj, direction: Vector):
    minimum, maximum = _world_bounds(obj)
    center = (minimum + maximum) * 0.5
    ext = maximum - minimum
    span = max(ext.x, ext.y, ext.z, 0.05)
    direction = direction.normalized()

    data = bpy.data.cameras.new(name)
    data.type = "ORTHO"
    data.ortho_scale = span * 1.28
    cam = bpy.data.objects.new(name, data)
    bpy.context.scene.collection.objects.link(cam)
    cam.location = center + direction * span * 2.6
    cam.rotation_euler = (center - cam.location).to_track_quat("-Z", "Y").to_euler()
    bpy.context.scene.camera = cam
    return cam, center, ext


def _render(path: Path, width=640, height=640):
    scene = bpy.context.scene
    scene.render.resolution_x = width
    scene.render.resolution_y = height
    scene.render.resolution_percentage = 100
    scene.render.filepath = str(path)
    bpy.ops.render.render(write_still=True)
    if not path.is_file() or path.stat().st_size <= 0:
        raise RuntimeError("v64c render failed: " + str(path))


def run():
    report_path = _args_report_path()
    v64b.run()

    baked = bpy.data.objects.get("BakedHoldingLimbV64")
    vessel = bpy.data.objects.get("BakedSourceV64Vessel")
    if baked is None or vessel is None:
        raise RuntimeError("v64c expected baked limb and vessel after v64b")

    values = sys.argv[sys.argv.index("--") + 1:]
    out = Path(values[2]).resolve()
    out.mkdir(parents=True, exist_ok=True)

    # Preserve the original product-like view produced by v64b. Diagnostic anatomy views are
    # deliberately vessel-free so occlusion cannot masquerade as missing/corrupt geometry.
    vessel.hide_render = True
    _, center_front, ext = _fit_camera("BakedAnatomyFrontV64c", baked, Vector((0.0, -1.0, 0.08)))
    anatomy_front = out / "baked_source_v64c_anatomy_front.png"
    _render(anatomy_front)

    _, center_oblique, _ = _fit_camera("BakedAnatomyObliqueV64c", baked, Vector((-0.75, -1.0, 0.52)))
    anatomy_oblique = out / "baked_source_v64c_anatomy_oblique.png"
    _render(anatomy_oblique)
    anatomy_thumb = out / "baked_source_v64c_anatomy_thumbnail.png"
    _render(anatomy_thumb, 192, 108)
    vessel.hide_render = False

    report = json.loads(report_path.read_text(encoding="utf-8"))
    report.update({
        "evidence_multiview_v64c": True,
        "pose_changed_from_v64b": False,
        "crop_changed_from_v64b": False,
        "vessel_transform_changed_from_v64b": False,
        "anatomy_front": str(anatomy_front),
        "anatomy_oblique": str(anatomy_oblique),
        "anatomy_thumbnail": str(anatomy_thumb),
        "baked_world_extents": [float(ext.x), float(ext.y), float(ext.z)],
        "anatomy_view_center_front": [float(x) for x in center_front],
        "anatomy_view_center_oblique": [float(x) for x in center_oblique],
        "visual_gate_v64c": "Original with-vessel thumbnail must read as support wrap; unobstructed front/oblique views must prove one continuous believable hand/palm/wrist/forearm rather than isolated fragments."
    })
    report_path.write_text(json.dumps(report, indent=2, sort_keys=True), encoding="utf-8")
    print("MPFB_BAKED_EVIDENCE_V64C_SUCCESS")


if __name__ == "__main__":
    run()
