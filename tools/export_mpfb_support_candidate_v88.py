#!/usr/bin/env python3
"""Export the single visually-authored v88 support-hand candidate for Godot product-camera staging.

Run this against the exact v87 authoring .blend. The deltas below are the one deliberate
native-rig edit that passed the local Macro/Meso gate; this is not a candidate sweep.
The result is a cropped, baked static limb centered on the proxy-vessel grip point so Godot
can stage it against the real amber/clear bottle without changing production hand logic.
"""
from __future__ import annotations

import json
import math
import sys
from pathlib import Path

import bpy
import bmesh
from mathutils import Vector

SUCCESS = "MPFB_SUPPORT_CANDIDATE_V88_EXPORT_SUCCESS"
ARM = "MPFB_V84_AuthoringRig"
HUMAN = "MPFB_V84_ReferenceHuman"
VESSEL = "LOCKED_VesselProxy"

POSE_DELTAS_DEG = {
    "wrist.R": {"rx": 10.0},
    "right_master_grip": {"rx": 8.0},
    "right_finger2_grip": {"rx": -6.0},
    "right_finger3_grip": {"rx": 4.0},
    "right_finger4_grip": {"rx": 4.0},
    "right_finger5_grip": {"rx": 0.0},
    "right_finger1_grip": {"rx": 0.0},
}


def _args():
    if "--" not in sys.argv:
        raise RuntimeError("expected -- <output.glb> <report.json>")
    values = sys.argv[sys.argv.index("--") + 1:]
    if len(values) != 2:
        raise RuntimeError("expected two arguments")
    return Path(values[0]).resolve(), Path(values[1]).resolve()


def _wp(arm, name: str, tail: bool = False) -> Vector:
    pb = arm.pose.bones.get(name)
    if pb is None:
        raise RuntimeError("missing bone " + name)
    return arm.matrix_world @ (pb.tail if tail else pb.head)


def _distance_to_segment(p: Vector, a: Vector, b: Vector) -> float:
    ab = b - a
    if ab.length_squared < 1e-12:
        return (p - a).length
    t = max(0.0, min(1.0, (p - a).dot(ab) / ab.length_squared))
    return (p - (a + ab * t)).length


def _apply_single_artist_edit(arm) -> None:
    for name, payload in POSE_DELTAS_DEG.items():
        pb = arm.pose.bones.get(name)
        if pb is None:
            raise RuntimeError("missing editable control " + name)
        pb.rotation_mode = "XYZ"
        e = pb.rotation_euler.copy()
        e.x += math.radians(float(payload.get("rx", 0.0)))
        pb.rotation_euler = e
    bpy.context.view_layer.update()


def _bake_and_crop(arm, basemesh):
    names = ["lowerarm02.R", "wrist.R"] + [f"finger{d}-{j}.R" for d in range(1, 6) for j in range(1, 4)]
    segments = [(n, _wp(arm, n), _wp(arm, n, True)) for n in names]
    roots = [_wp(arm, f"finger{i}-1.R") for i in range(2, 6)]
    wrist = _wp(arm, "wrist.R")
    palm = (wrist + sum(roots, Vector())) / 5.0

    depsgraph = bpy.context.evaluated_depsgraph_get()
    evaluated = basemesh.evaluated_get(depsgraph)
    mesh = bpy.data.meshes.new_from_object(evaluated, preserve_all_data_layers=True, depsgraph=depsgraph)
    obj = bpy.data.objects.new("PeelCalmSupportLimbV88", mesh)
    bpy.context.scene.collection.objects.link(obj)
    obj.matrix_world = basemesh.matrix_world.copy()

    inv = obj.matrix_world.inverted()
    local_segments = [(name, inv @ a, inv @ b) for name, a, b in segments]
    local_palm = inv @ palm
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    bm.verts.ensure_lookup_table()
    remove = []
    for vert in bm.verts:
        keep = (vert.co - local_palm).length <= 0.050
        if not keep:
            for name, a, b in local_segments:
                radius = 0.038 if name in {"lowerarm02.R", "wrist.R"} else 0.018
                if _distance_to_segment(vert.co, a, b) <= radius:
                    keep = True
                    break
        if not keep:
            remove.append(vert)
    bmesh.ops.delete(bm, geom=remove, context="VERTS")
    bm.to_mesh(obj.data)
    bm.free()
    obj.data.update()
    if len(obj.data.vertices) < 1200:
        raise RuntimeError("cropped v88 limb unexpectedly sparse")
    return obj, palm, wrist


def main() -> None:
    out_path, report_path = _args()
    out_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.parent.mkdir(parents=True, exist_ok=True)
    arm = bpy.data.objects.get(ARM)
    basemesh = bpy.data.objects.get(HUMAN)
    vessel = bpy.data.objects.get(VESSEL)
    if arm is None or basemesh is None or vessel is None:
        raise RuntimeError("v87 authoring scene contract missing")
    editable = json.loads(arm["editable_controls"])
    expected = ["wrist.R", "right_master_grip", "right_finger1_grip", "right_finger2_grip", "right_finger3_grip", "right_finger4_grip", "right_finger5_grip"]
    if editable != expected:
        raise RuntimeError("unexpected v87 semantic control contract")

    _apply_single_artist_edit(arm)
    baked, palm, wrist = _bake_and_crop(arm, basemesh)
    vessel_center = vessel.matrix_world.translation.copy()
    # Export root is the visual grip cylinder center. Blender's glTF exporter performs
    # the standard Z-up -> Y-up conversion; Godot then only needs a scale/yaw placement.
    baked.location -= vessel_center

    bpy.ops.object.select_all(action="DESELECT")
    baked.select_set(True)
    bpy.context.view_layer.objects.active = baked
    bpy.ops.export_scene.gltf(
        filepath=str(out_path),
        export_format="GLB",
        use_selection=True,
        export_apply=True,
        export_yup=True,
        export_materials="EXPORT",
    )
    if not out_path.is_file() or out_path.stat().st_size < 20000:
        raise RuntimeError("v88 GLB export missing or unexpectedly small")

    report = {
        "staging_only": True,
        "production_candidate": False,
        "reference_set": ["bar_v1", "market_v1"],
        "source_authoring_scene": "v87 semantic native-rig authoring panel",
        "single_artist_edit": True,
        "parameter_sweep_used": False,
        "optimizer_used": False,
        "automatic_retarget_used": False,
        "pose_deltas_degrees": POSE_DELTAS_DEG,
        "cropped_vertices": len(baked.data.vertices),
        "cropped_polygons": len(baked.data.polygons),
        "vessel_center_blender": list(vessel_center),
        "palm_blender": list(palm),
        "wrist_blender": list(wrist),
        "root_is_proxy_vessel_center": True,
        "next_gate": "Godot bar/market product-camera A/B versus current XR baseline; no production promotion on technical PASS alone.",
    }
    report_path.write_text(json.dumps(report, indent=2, sort_keys=True), encoding="utf-8")
    print(json.dumps(report, indent=2, sort_keys=True))
    print(SUCCESS)


if __name__ == "__main__":
    main()
