#!/usr/bin/env python3
"""Author exactly one v86 support-grasp candidate through MPFB semantic grip controls.

This is a staging-only, falsifiable visual experiment built on the verified v85 authoring
bridge. It deliberately does NOT sweep parameters and does NOT retarget ContactPose joints
onto pose bones. The selected ContactPose water-bottle sample is used only for a human
closure-depth grammar: index is lightest, middle/ring progressively close, pinky closes
most, while the thumb gets an independent semantic grip offset.

The opaque v85 vessel and camera are frozen before authoring. Only the six semantic grip
helper controls are changed; wrist.R remains unchanged in this candidate so the experiment
isolates grasp shape from whole-hand placement. Final acceptance is still visual: the
192x108 opaque-vessel render must immediately read as a stable human bottle grip and the
unobstructed anatomy render must preserve web space / separated digit arcs.
"""
from __future__ import annotations

import importlib.util
import json
import math
import sys
from pathlib import Path

import bpy

BASE = Path(__file__).resolve().parent
SUCCESS = "MPFB_GRIP_HELPER_CONTACTPOSE_V86_SUCCESS"

# One authored semantic candidate, not a sweep. Finger numbering follows MPFB Default
# helper controls: finger1=thumb, finger2=index, finger3=middle, finger4=ring,
# finger5=pinky. The non-thumb effective closure intent is derived from the repository's
# persisted ContactPose water_bottle reference (about 30.6 / 42.2 / 49.0 / 60.6 deg).
MASTER_DEG = 48.0
AUTHORED_OFFSETS_DEG = {
    "right_finger1_grip": 18.0,   # thumb: independent stronger opposing curl
    "right_finger2_grip": -17.4,  # index effective intent ~= 30.6
    "right_finger3_grip": -5.8,   # middle effective intent ~= 42.2
    "right_finger4_grip": 1.0,    # ring effective intent ~= 49.0
    "right_finger5_grip": 12.6,   # pinky effective intent ~= 60.6
}


def _load(name: str, filename: str):
    spec = importlib.util.spec_from_file_location(name, BASE / filename)
    if spec is None or spec.loader is None:
        raise RuntimeError("could not load " + filename)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


v85 = _load("mpfb_v85_for_v86", "build_mpfb_grip_helper_ghost_v85.py")
v84 = v85.v84


def _args():
    if "--" not in sys.argv:
        raise RuntimeError("expected -- <extension-module> <source.json> <outdir> <report.json>")
    vals = sys.argv[sys.argv.index("--") + 1:]
    if len(vals) != 4:
        raise RuntimeError("expected four arguments")
    return vals[0], Path(vals[1]).resolve(), Path(vals[2]).resolve(), Path(vals[3]).resolve()


def _matrix_rows(obj):
    return [list(row) for row in obj.matrix_world]


def _max_matrix_delta(a, b):
    return max(abs(a[r][c] - b[r][c]) for r in range(4) for c in range(4))


def _render(path: Path, x: int, y: int):
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE_NEXT"
    scene.render.resolution_x = x
    scene.render.resolution_y = y
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.filepath = str(path)
    scene.render.film_transparent = False
    bpy.ops.render.render(write_still=True)


def _set_collection_render(name: str, hidden: bool):
    coll = bpy.data.collections.get(name)
    if coll is None:
        raise RuntimeError("missing collection " + name)
    coll.hide_render = hidden
    for obj in coll.all_objects:
        obj.hide_render = hidden


def run():
    ext, source_path, out, report_path = _args()
    out.mkdir(parents=True, exist_ok=True)
    report_path.parent.mkdir(parents=True, exist_ok=True)

    # Rebuild the exact v85 bridge in this workflow so provenance, locked camera/vessel,
    # real-human ghost, and semantic helper setup are deterministic.
    v85_out = out / "v85_base"
    v85_report = v85_out / "build.json"
    old_argv = list(sys.argv)
    try:
        sys.argv = [old_argv[0], "--", ext, str(source_path), str(v85_out), str(v85_report)]
        v85.run()
    finally:
        sys.argv = old_argv

    base_blend = v85_out / "peel-calm-grip-helper-ghost-v85.blend"
    bpy.ops.wm.open_mainfile(filepath=str(base_blend))

    arm = bpy.data.objects.get("MPFB_V84_AuthoringRig")
    vessel = bpy.data.objects.get("LOCKED_VesselProxy")
    camera = bpy.data.objects.get("LOCKED_V84_Camera")
    wire = bpy.data.objects.get("AUTHORING_WireVesselGuide_V85")
    if arm is None or vessel is None or camera is None or wire is None:
        raise RuntimeError("v85 authoring contract missing after reopen")

    vessel_before = _matrix_rows(vessel)
    camera_before = _matrix_rows(camera)
    wrist_before = [list(row) for row in arm.pose.bones["wrist.R"].matrix_basis]

    # Apply exactly one deliberate semantic pose. No loops over candidate values, no
    # optimization, no ContactPose bone copy. The real skeleton remains visual guidance.
    master = arm.pose.bones.get("right_master_grip")
    if master is None:
        raise RuntimeError("missing right_master_grip")
    master.rotation_mode = "XYZ"
    master.rotation_euler.x = math.radians(MASTER_DEG)
    for name, deg in AUTHORED_OFFSETS_DEG.items():
        pb = arm.pose.bones.get(name)
        if pb is None:
            raise RuntimeError("missing semantic control " + name)
        pb.rotation_mode = "XYZ"
        pb.rotation_euler.x = math.radians(deg)
    bpy.context.view_layer.update()

    if _max_matrix_delta(vessel_before, _matrix_rows(vessel)) > 1e-12:
        raise RuntimeError("locked vessel moved during v86 authoring")
    if _max_matrix_delta(camera_before, _matrix_rows(camera)) > 1e-12:
        raise RuntimeError("locked camera moved during v86 authoring")
    wrist_after = [list(row) for row in arm.pose.bones["wrist.R"].matrix_basis]
    wrist_delta = max(abs(wrist_before[r][c] - wrist_after[r][c]) for r in range(4) for c in range(4))
    if wrist_delta > 1e-12:
        raise RuntimeError(f"wrist changed in grip-shape-only v86 candidate: {wrist_delta}")

    ghost_collection = "CONTACTPOSE_REAL_WATER_BOTTLE_GHOST_V85"

    # Final Macro evidence: opaque locked vessel, no ghost/wire contamination.
    _set_collection_render(ghost_collection, True)
    vessel.hide_render = False
    wire.hide_render = True
    _render(out / "v86-support-with-vessel.png", 640, 640)
    _render(out / "v86-support-thumbnail.png", 192, 108)

    # Meso evidence: same authored hand, vessel/ghost/wire hidden.
    vessel.hide_render = True
    wire.hide_render = True
    _render(out / "v86-support-anatomy.png", 640, 640)

    # Authoring diagnostic only: restore real-human ghost + wire vessel so the visual
    # difference can be inspected without changing final acceptance evidence.
    _set_collection_render(ghost_collection, False)
    vessel.hide_render = True
    wire.hide_render = False
    _render(out / "v86-guide-overlay.png", 640, 640)
    _render(out / "v86-guide-thumbnail.png", 192, 108)

    # Leave the saved scene in final opaque-vessel review mode, with semantic controls
    # selected for a future direct artist correction if this single candidate is rejected.
    _set_collection_render(ghost_collection, True)
    wire.hide_render = True
    vessel.hide_render = False
    arm["peel_calm_authoring_version"] = "v86"
    arm["v86_pose_source"] = "single ContactPose-derived semantic closure grammar; no retarget"
    arm["v86_master_grip_deg"] = MASTER_DEG
    arm["v86_offsets_deg"] = json.dumps(AUTHORED_OFFSETS_DEG, sort_keys=True)
    scene = bpy.context.scene
    scene["peel_calm_visual_verdict"] = "PENDING_VISUAL_REVIEW"
    scene["production_candidate"] = False
    scene["parameter_sweep_used"] = False
    scene["automatic_retarget_used"] = False
    scene["candidate_count"] = 1

    bpy.context.view_layer.objects.active = arm
    arm.select_set(True)
    bpy.ops.object.mode_set(mode="POSE")
    for pb in arm.pose.bones:
        pb.bone.select = pb.name in v84.CONTROLS
    arm.data.bones.active = arm.data.bones["right_master_grip"]
    bpy.ops.object.mode_set(mode="OBJECT")

    blend = out / "peel-calm-grip-helper-contactpose-v86.blend"
    bpy.ops.wm.save_as_mainfile(filepath=str(blend), check_existing=False)

    effective = {
        "index": MASTER_DEG + AUTHORED_OFFSETS_DEG["right_finger2_grip"],
        "middle": MASTER_DEG + AUTHORED_OFFSETS_DEG["right_finger3_grip"],
        "ring": MASTER_DEG + AUTHORED_OFFSETS_DEG["right_finger4_grip"],
        "pinky": MASTER_DEG + AUTHORED_OFFSETS_DEG["right_finger5_grip"],
    }
    report = {
        "staging_only": True,
        "production_candidate": False,
        "candidate_count": 1,
        "visual_verdict": "PENDING_VISUAL_REVIEW",
        "reference_set": ["bar_v1", "market_v1"],
        "guide_source": "ContactPose water_bottle full6_use hand1",
        "guide_used_for_bone_retarget": False,
        "automatic_retarget_used": False,
        "parameter_sweep_used": False,
        "endpoint_optimizer_used": False,
        "contact_servo_used": False,
        "editable_controls": v84.CONTROLS,
        "wrist_changed": False,
        "wrist_matrix_delta": wrist_delta,
        "vessel_locked": True,
        "camera_locked": True,
        "master_grip_deg": MASTER_DEG,
        "semantic_offsets_deg": AUTHORED_OFFSETS_DEG,
        "effective_non_thumb_closure_intent_deg": effective,
        "human_reference_non_thumb_closure_deg": {"index": 30.6, "middle": 42.2, "ring": 49.0, "pinky": 60.6},
        "blend": str(blend),
        "macro_gate": "v86-support-thumbnail.png must immediately read as stable human bottle grip with thumb opposing far-side fingers",
        "meso_gate": "v86-support-anatomy.png must show web space, natural knuckle flow, separated digit arcs, no obvious self-intersection",
        "next_action": "Human visual review only. If Macro or Meso fails, reject this one candidate; do not turn these semantic controls into a parameter sweep.",
    }
    report_path.write_text(json.dumps(report, indent=2, sort_keys=True), encoding="utf-8")
    print(json.dumps(report, indent=2, sort_keys=True))
    print(SUCCESS)


if __name__ == "__main__":
    run()
