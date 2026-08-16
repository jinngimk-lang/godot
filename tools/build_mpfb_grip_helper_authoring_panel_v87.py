#!/usr/bin/env python3
"""Build v87: v86 direct-visual scene + persistent semantic-control authoring aids.

This is authoring infrastructure only. It deliberately DOES NOT change the pose, vessel,
camera, reference contract, or gameplay state. It reuses v86 and makes the seven approved
semantic controls easy to find in a real Blender viewport by assigning persistent custom
control shapes, grouping them in a dedicated bone collection, and embedding a compact
ordered artist brief in the .blend. No optimizer, retarget, sweep, CCD, contact servo, or
raw-phalanx authoring is introduced.
"""
from __future__ import annotations

import importlib.util
import json
import math
import sys
from pathlib import Path

import bpy

BASE = Path(__file__).resolve().parent
SUCCESS = "MPFB_GRIP_HELPER_AUTHORING_PANEL_V87_SUCCESS"


def _load(name: str, filename: str):
    spec = importlib.util.spec_from_file_location(name, BASE / filename)
    if spec is None or spec.loader is None:
        raise RuntimeError("could not load " + filename)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


v86 = _load("mpfb_v86_for_v87", "build_mpfb_grip_helper_authoring_overlay_v86.py")
v84 = v86.v84


def _args():
    if "--" not in sys.argv:
        raise RuntimeError("expected -- <extension-module> <source.json> <outdir> <report.json>")
    vals = sys.argv[sys.argv.index("--") + 1:]
    if len(vals) != 4:
        raise RuntimeError("expected four arguments")
    return vals[0], Path(vals[1]).resolve(), Path(vals[2]).resolve(), Path(vals[3]).resolve()


def _matrix(pb):
    return [list(row) for row in pb.matrix_basis]


def _max_matrix_delta(before, after):
    return max(abs(before[n][r][c] - after[n][r][c]) for n in before for r in range(4) for c in range(4))


def _shape(name: str, radius: float, points: int, diamond: bool = False):
    mesh = bpy.data.meshes.new(name + "_Mesh")
    if diamond:
        verts = [(0.0, radius, 0.0), (radius, 0.0, 0.0), (0.0, -radius, 0.0), (-radius, 0.0, 0.0)]
    else:
        verts = [(math.cos(i * 2.0 * math.pi / points) * radius,
                  math.sin(i * 2.0 * math.pi / points) * radius, 0.0) for i in range(points)]
    edges = [(i, (i + 1) % len(verts)) for i in range(len(verts))]
    mesh.from_pydata(verts, edges, [])
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    coll = bpy.data.collections.get("AUTHORING_CONTROL_SHAPES_V87")
    if coll is None:
        coll = bpy.data.collections.new("AUTHORING_CONTROL_SHAPES_V87")
        bpy.context.scene.collection.children.link(coll)
    coll.objects.link(obj)
    obj.hide_render = True
    obj.hide_select = True
    obj.hide_viewport = True
    obj["authoring_shape_only"] = True
    return obj


def run():
    ext, source_path, out, report_path = _args()
    out.mkdir(parents=True, exist_ok=True)
    report_path.parent.mkdir(parents=True, exist_ok=True)

    v86_report = out / "v86-base-report.json"
    old_argv = list(sys.argv)
    try:
        sys.argv = [old_argv[0], "--", ext, str(source_path), str(out), str(v86_report)]
        v86.run()
    finally:
        sys.argv = old_argv

    v86_blend = out / "peel-calm-grip-helper-authoring-overlay-v86.blend"
    if not v86_blend.exists():
        raise RuntimeError("v86 authoring blend was not generated")
    bpy.ops.wm.open_mainfile(filepath=str(v86_blend))

    arm = bpy.data.objects.get("MPFB_V84_AuthoringRig")
    vessel = bpy.data.objects.get("LOCKED_VesselProxy")
    cam = bpy.data.objects.get("LOCKED_V84_Camera")
    if arm is None or vessel is None or cam is None:
        raise RuntimeError("v86 authoring contract missing")
    if not vessel.hide_select or not cam.hide_select:
        raise RuntimeError("locked vessel/camera unexpectedly editable")

    before = {name: _matrix(arm.pose.bones[name]) for name in v84.CONTROLS}
    vessel_before = [list(row) for row in vessel.matrix_world]
    camera_before = [list(row) for row in cam.matrix_world]

    wrist_shape = _shape("V87_Wrist_ControlShape", 0.025, 24)
    grip_shape = _shape("V87_Grip_ControlShape", 0.020, 4, diamond=True)

    priorities = {
        "wrist.R": "1 palm beside bottle",
        "right_master_grip": "2 establish whole-hand enclosure",
        "right_finger1_grip": "6 thumb opposition after four-finger enclosure",
        "right_finger2_grip": "3 index: largest far-side/depth correction, lightest closure",
        "right_finger3_grip": "4 middle: progressively deeper enclosure",
        "right_finger4_grip": "5 ring: continue enclosure with separation",
        "right_finger5_grip": "5b pinky: minimal disturbance unless continuity requires",
    }

    # Dedicated collection makes the only approved controls obvious in Pose Mode.
    collection = arm.data.collections.get("PEEL_CALM_DIRECT_ARTIST_CONTROLS_V87")
    if collection is None:
        collection = arm.data.collections.new("PEEL_CALM_DIRECT_ARTIST_CONTROLS_V87")
    for name in v84.CONTROLS:
        pb = arm.pose.bones.get(name)
        if pb is None:
            raise RuntimeError("missing approved semantic control " + name)
        collection.assign(pb.bone)
        pb.custom_shape = wrist_shape if name == "wrist.R" else grip_shape
        pb.custom_shape_scale_xyz = (1.0, 1.0, 1.0)
        pb["peel_calm_edit_order"] = priorities[name]
        pb["peel_calm_semantic_control"] = True

    arm.show_in_front = True
    arm.data.display_type = "BBONE"
    arm["peel_calm_authoring_version"] = "v87"
    arm["editable_controls"] = json.dumps(v84.CONTROLS)
    arm["direct_artist_control_collection"] = collection.name

    scene = bpy.context.scene
    scene["peel_calm_visual_verdict"] = "PENDING_DIRECT_ARTIST_EDIT"
    scene["production_candidate"] = False
    scene["v87_panel_pose_mutation"] = False
    scene["v87_panel_is_optimizer"] = False
    scene["v87_panel_automatic_retarget"] = False
    scene["v87_panel_parameter_sweep"] = False
    scene["v87_artist_sequence"] = "palm -> index depth -> middle/ring enclosure -> minimal pinky -> thumb opposition"
    scene["v87_macro_gate"] = "opaque 192x108 must immediately read as natural stable bottle grip"
    scene["v87_meso_gate"] = "unobstructed anatomy must preserve web space, separated arcs, knuckle flow, no self-intersection"

    brief = bpy.data.texts.get("PEEL_CALM_V87_DIRECT_ARTIST_BRIEF") or bpy.data.texts.new("PEEL_CALM_V87_DIRECT_ARTIST_BRIEF")
    brief.clear()
    brief.write(
        "PEEL CALM v87 DIRECT ARTIST SUPPORT-GRASP BRIEF\n\n"
        "EDIT ONLY the seven semantic controls in bone collection PEEL_CALM_DIRECT_ARTIST_CONTROLS_V87.\n"
        "1. wrist.R: put palm BESIDE bottle, not hanging over the near face.\n"
        "2. index: largest coherent move toward far-side/depth arc; keep lightest closure.\n"
        "3. middle then ring: progressively deeper enclosure with visible separation.\n"
        "4. pinky: disturb minimally; do not use it to force global grip.\n"
        "5. thumb: final readable opposition against the four-finger group.\n\n"
        "Ghost, wire vessel and discrepancy arrows are GUIDES ONLY. Hide them for acceptance.\n"
        "MACRO PASS: opaque 192x108 immediately reads as a natural stable human bottle grip.\n"
        "MESO PASS: unobstructed anatomy has web space, separated digit arcs, natural knuckle flow and no obvious self-intersection.\n"
        "FORBIDDEN: CCD, endpoint/contact optimizer, retarget, raw-phalanx table, orbit/semantic sweep, moving locked vessel/camera.\n"
    )

    after = {name: _matrix(arm.pose.bones[name]) for name in v84.CONTROLS}
    max_delta = _max_matrix_delta(before, after)
    vessel_after = [list(row) for row in vessel.matrix_world]
    camera_after = [list(row) for row in cam.matrix_world]
    vessel_delta = max(abs(vessel_before[r][c] - vessel_after[r][c]) for r in range(4) for c in range(4))
    camera_delta = max(abs(camera_before[r][c] - camera_after[r][c]) for r in range(4) for c in range(4))
    if max_delta > 1e-9 or vessel_delta > 1e-9 or camera_delta > 1e-9:
        raise RuntimeError(f"v87 authoring aids mutated locked state: controls={max_delta} vessel={vessel_delta} camera={camera_delta}")

    scene["v87_panel_control_max_matrix_delta"] = max_delta
    scene["v87_panel_vessel_matrix_delta"] = vessel_delta
    scene["v87_panel_camera_matrix_delta"] = camera_delta

    bpy.context.view_layer.objects.active = arm
    arm.select_set(True)
    if bpy.context.object == arm:
        bpy.ops.object.mode_set(mode="POSE")
        bpy.ops.pose.select_all(action="DESELECT")
        for name in v84.CONTROLS:
            arm.data.bones[name].select = True
        arm.data.bones.active = arm.data.bones["wrist.R"]
        bpy.ops.object.mode_set(mode="OBJECT")

    blend = out / "peel-calm-grip-helper-authoring-panel-v87.blend"
    bpy.ops.wm.save_as_mainfile(filepath=str(blend), check_existing=False)

    report = {
        "staging_only": True,
        "production_candidate": False,
        "authoring_infrastructure_only": True,
        "visual_verdict": "PENDING_DIRECT_ARTIST_EDIT",
        "reference_set": ["bar_v1", "market_v1"],
        "editable_controls": v84.CONTROLS,
        "direct_artist_control_collection": collection.name,
        "custom_shapes_assigned": {name: arm.pose.bones[name].custom_shape.name for name in v84.CONTROLS},
        "control_priorities": priorities,
        "pose_control_max_matrix_delta_from_v86": max_delta,
        "vessel_matrix_delta_from_v86": vessel_delta,
        "camera_matrix_delta_from_v86": camera_delta,
        "vessel_locked": vessel.hide_select,
        "camera_locked": cam.hide_select,
        "automatic_retarget_used": False,
        "parameter_sweep_used": False,
        "optimizer_used": False,
        "artist_sequence": scene["v87_artist_sequence"],
        "macro_gate": scene["v87_macro_gate"],
        "meso_gate": scene["v87_meso_gate"],
        "blend": str(blend),
    }
    report_path.write_text(json.dumps(report, indent=2), encoding="utf-8")
    print(SUCCESS)
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    run()
