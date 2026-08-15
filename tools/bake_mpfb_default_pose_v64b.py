#!/usr/bin/env python3
"""v64b: evidence-only correction for the v64 same-rig baked-pose experiment.

v64 proved the sacrificial canonical-rig -> static baked mesh pipeline, but the hard-coded
crop radii removed most of the hand before rendering. v64b changes no source pose, rig,
BVH import, deformation, camera placement, or product hypothesis. It only derives crop radii
from the posed canonical hand's own segment scale and darkens the diagnostic vessel so the
remaining silhouette is readable.

The crop gate is anatomical rather than a raw total-vertex proxy: every selected limb segment
must retain nearby surface vertices, and the palm/webbing envelope must retain substantial
coverage. This prevents a valid compact crop from failing merely because it contains fewer
unrelated body vertices while still rejecting missing fingers/palm/forearm geometry.
"""
from __future__ import annotations

import importlib.util
import json
import sys
from pathlib import Path

import bmesh
import bpy
from mathutils import Vector

BASE = Path(__file__).resolve().parent
SPEC = importlib.util.spec_from_file_location("mpfb_v64_for_v64b", BASE / "bake_mpfb_default_pose_v64.py")
if SPEC is None or SPEC.loader is None:
    raise RuntimeError("could not load v64 base")
v64 = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(v64)


def _adaptive_crop(baked, segments, palm_center_world: Vector):
    inv = baked.matrix_world.inverted()
    local_segments = [(name, inv @ a, inv @ b) for name, a, b in segments]
    palm_local = inv @ palm_center_world

    finger_segments = [(name, a, b) for name, a, b in local_segments if name.startswith("finger")]
    root_points = [a for name, a, _ in finger_segments if name.endswith("-1.R")]
    if len(root_points) < 5:
        raise RuntimeError("v64b could not derive five finger roots")
    palm_extent = max((p - palm_local).length for p in root_points)
    finger_lengths = [(b - a).length for _, a, b in finger_segments]
    finger_scale = sorted(finger_lengths)[len(finger_lengths) // 2]

    # The previous constants were far below the actual MPFB scale. Derive envelope size from
    # the posed skeleton and deliberately include webbing/thenar tissue around the palm.
    palm_radius = max(0.055, palm_extent * 1.38)
    finger_radius = max(0.021, finger_scale * 0.58)
    forearm_radius = max(finger_radius * 1.9, palm_radius * 0.54)

    bm = bmesh.new()
    bm.from_mesh(baked.data)
    bm.verts.ensure_lookup_table()
    remove = []
    for v in bm.verts:
        keep = (v.co - palm_local).length <= palm_radius
        if not keep:
            for name, a, b in local_segments:
                radius = forearm_radius if name in {"lowerarm02.R", "wrist.R"} else finger_radius
                if v64._distance_to_segment(v.co, a, b) <= radius:
                    keep = True
                    break
        if not keep:
            remove.append(v)
    bmesh.ops.delete(bm, geom=remove, context="VERTS")
    bm.to_mesh(baked.data)
    bm.free()
    baked.data.update()

    # Gate the crop by anatomical coverage rather than by an arbitrary total vertex count.
    # Count retained vertices near every source segment using the same local envelopes that
    # defined the crop. A missing digit/forearm fails even if the total vertex count is high.
    retained = [v.co.copy() for v in baked.data.vertices]
    segment_coverage = {}
    for name, a, b in local_segments:
        radius = forearm_radius if name in {"lowerarm02.R", "wrist.R"} else finger_radius
        segment_coverage[name] = sum(1 for p in retained if v64._distance_to_segment(p, a, b) <= radius)
    palm_coverage = sum(1 for p in retained if (p - palm_local).length <= palm_radius)

    required_segments = ["lowerarm02.R", "wrist.R"]
    required_segments += [f"finger{digit}-{joint}.R" for digit in range(1, 6) for joint in range(1, 4)]
    missing = [name for name in required_segments if segment_coverage.get(name, 0) < 12]
    if missing:
        raise RuntimeError(f"v64b adaptive crop lost anatomical segment coverage: {missing}")
    if palm_coverage < 220:
        raise RuntimeError(f"v64b adaptive crop lost palm/webbing coverage: {palm_coverage} vertices")
    if len(retained) < 1400:
        raise RuntimeError(f"v64b adaptive crop unexpectedly sparse despite coverage: {len(retained)} vertices")

    baked["v64b_palm_radius"] = palm_radius
    baked["v64b_finger_radius"] = finger_radius
    baked["v64b_forearm_radius"] = forearm_radius
    baked["v64b_palm_vertex_coverage"] = palm_coverage
    baked["v64b_min_segment_vertex_coverage"] = min(segment_coverage.values())
    baked["v64b_segment_vertex_coverage_json"] = json.dumps(segment_coverage, sort_keys=True)


def _dark_proxy_material():
    mat = bpy.data.materials.new("BakedSourceVesselV64b")
    mat.use_nodes = True
    p = next((n for n in mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED"), None)
    if p:
        p.inputs["Base Color"].default_value = (0.055, 0.16, 0.24, 1.0)
        p.inputs["Roughness"].default_value = 0.48
    return mat


def _report_path_from_args() -> Path:
    if "--" not in sys.argv:
        raise RuntimeError("missing v64b args")
    values = sys.argv[sys.argv.index("--") + 1:]
    if len(values) != 5:
        raise RuntimeError("expected v64-compatible five arguments")
    return Path(values[4]).resolve()


def run():
    report_path = _report_path_from_args()
    v64._crop_to_limb = _adaptive_crop
    v64._proxy_material = _dark_proxy_material
    v64.run()
    report = json.loads(report_path.read_text(encoding="utf-8"))
    baked = bpy.data.objects.get("BakedHoldingLimbV64")
    if baked is None:
        raise RuntimeError("v64b baked limb missing after base run")
    report["adaptive_crop_v64b"] = True
    report["pose_changed_from_v64"] = False
    report["evidence_only_fix"] = "crop envelope derived from posed skeleton scale; darker diagnostic vessel; anatomical coverage gate"
    report["palm_vertex_coverage"] = int(baked.get("v64b_palm_vertex_coverage", 0))
    report["min_segment_vertex_coverage"] = int(baked.get("v64b_min_segment_vertex_coverage", 0))
    report["segment_vertex_coverage"] = json.loads(str(baked.get("v64b_segment_vertex_coverage_json", "{}")))
    report_path.write_text(json.dumps(report, indent=2, sort_keys=True), encoding="utf-8")
    print("MPFB_BAKED_SOURCE_V64B_SUCCESS")


if __name__ == "__main__":
    run()
