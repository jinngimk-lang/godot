#!/usr/bin/env python3
"""Render a non-candidate visual response atlas for the v87 artist controls.

This is NOT a pose optimizer or parameter sweep. It is the headless equivalent of an
artist nudging each exposed semantic control once to learn its screen-space direction
before making one deliberate whole-hand edit. Every response starts from the exact same
v87 seed, applies one small signed nudge, renders the locked 192x108 opaque Macro view,
and restores the original matrix before the next response.

No response image is an acceptance candidate and none may be promoted on technical PASS.
"""
from __future__ import annotations

import json
import math
import sys
from pathlib import Path

import bpy
from mathutils import Matrix, Vector

SUCCESS = "MPFB_ARTIST_CONTROL_RESPONSE_V88_SUCCESS"
ARM = "MPFB_V84_AuthoringRig"
CAM = "LOCKED_V84_Camera"
VESSEL = "LOCKED_VesselProxy"
RESTORE_EPSILON = 1e-7  # Blender Matrix/Euler round-trip is float32-scale; this is far below any visible pose delta.


def args():
    if "--" not in sys.argv:
        raise RuntimeError("expected -- <outdir> <report.json>")
    values = sys.argv[sys.argv.index("--") + 1:]
    if len(values) != 2:
        raise RuntimeError("expected two arguments")
    return Path(values[0]).resolve(), Path(values[1]).resolve()


def hide_guides():
    for obj in bpy.data.objects:
        if obj.name.startswith("AUTHORING_") or "Ghost" in obj.name or "ghost" in obj.name or "Arrow" in obj.name:
            obj.hide_render = True
    vessel = bpy.data.objects.get(VESSEL)
    if vessel is not None:
        vessel.hide_render = False


def render(path: Path):
    scene = bpy.context.scene
    scene.camera = bpy.data.objects[CAM]
    scene.render.engine = "BLENDER_EEVEE_NEXT"
    scene.render.resolution_x = 192
    scene.render.resolution_y = 108
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.filepath = str(path)
    bpy.ops.render.render(write_still=True)
    if not path.is_file() or path.stat().st_size == 0:
        raise RuntimeError("render failed: " + str(path))


def max_matrix_delta(a: Matrix, b: Matrix) -> float:
    return max(abs(a[r][c] - b[r][c]) for r in range(4) for c in range(4))


def main():
    out, report_path = args()
    out.mkdir(parents=True, exist_ok=True)
    report_path.parent.mkdir(parents=True, exist_ok=True)
    arm = bpy.data.objects.get(ARM)
    if arm is None:
        raise RuntimeError("missing v87 authoring rig")
    controls = json.loads(arm["editable_controls"])
    if controls != ["wrist.R", "right_master_grip", "right_finger1_grip", "right_finger2_grip", "right_finger3_grip", "right_finger4_grip", "right_finger5_grip"]:
        raise RuntimeError("unexpected editable control contract")
    hide_guides()
    bpy.context.view_layer.update()

    originals = {name: arm.pose.bones[name].matrix_basis.copy() for name in controls}
    vessel_matrix = bpy.data.objects[VESSEL].matrix_world.copy()
    camera_matrix = bpy.data.objects[CAM].matrix_world.copy()

    render(out / "00-seed-opaque-macro.png")

    # These are directional calibration nudges only, analogous to one short viewport drag.
    # They are intentionally not a candidate grid and are never combined here.
    ops = [
        ("01-wrist-toward-vessel", "wrist.R", "translate_local_y", +0.012),
        ("02-wrist-away-vessel", "wrist.R", "translate_local_y", -0.012),
        ("03-wrist-rotate-x", "wrist.R", "rotate_x", math.radians(8.0)),
        ("04-wrist-rotate-y", "wrist.R", "rotate_y", math.radians(8.0)),
        ("05-wrist-rotate-z", "wrist.R", "rotate_z", math.radians(8.0)),
        ("06-master-more-wrap", "right_master_grip", "rotate_x", math.radians(10.0)),
        ("07-thumb-more-grip", "right_finger1_grip", "rotate_x", math.radians(10.0)),
        ("08-index-more-grip", "right_finger2_grip", "rotate_x", math.radians(10.0)),
        ("09-middle-more-grip", "right_finger3_grip", "rotate_x", math.radians(10.0)),
        ("10-ring-more-grip", "right_finger4_grip", "rotate_x", math.radians(10.0)),
        ("11-pinky-more-grip", "right_finger5_grip", "rotate_x", math.radians(10.0)),
    ]

    rendered = []
    for label, control, kind, amount in ops:
        # Hard restore every exposed control before each independent response.
        for name, mat in originals.items():
            arm.pose.bones[name].matrix_basis = mat.copy()
        pb = arm.pose.bones[control]
        if kind.startswith("rotate_"):
            axis = kind[-1]
            pb.rotation_mode = "XYZ"
            e = pb.rotation_euler.copy()
            setattr(e, axis, getattr(e, axis) + amount)
            pb.rotation_euler = e
        elif kind == "translate_local_y":
            pb.location = pb.location + Vector((0.0, amount, 0.0))
        else:
            raise RuntimeError("unknown operation " + kind)
        bpy.context.view_layer.update()
        path = out / f"{label}.png"
        render(path)
        rendered.append({"label": label, "control": control, "operation": kind, "amount": amount, "file": path.name})

    # Restore exact seed and prove the diagnostic itself is non-mutating within Blender's float precision.
    for name, mat in originals.items():
        arm.pose.bones[name].matrix_basis = mat.copy()
    bpy.context.view_layer.update()
    restore_delta = max(max_matrix_delta(arm.pose.bones[name].matrix_basis, originals[name]) for name in controls)
    vessel_delta = max_matrix_delta(bpy.data.objects[VESSEL].matrix_world, vessel_matrix)
    camera_delta = max_matrix_delta(bpy.data.objects[CAM].matrix_world, camera_matrix)
    if restore_delta > RESTORE_EPSILON or vessel_delta > RESTORE_EPSILON or camera_delta > RESTORE_EPSILON:
        raise RuntimeError(f"response atlas mutated locked state: controls={restore_delta} vessel={vessel_delta} camera={camera_delta}")

    report = {
        "staging_only": True,
        "production_candidate": False,
        "authoring_calibration_only": True,
        "visual_verdict": "NOT_A_CANDIDATE",
        "reference_set": ["bar_v1", "market_v1"],
        "source_authoring_version": arm.get("peel_calm_authoring_version", "unknown"),
        "editable_controls": controls,
        "response_count": len(rendered),
        "responses": rendered,
        "parameter_sweep_used": False,
        "optimizer_used": False,
        "automatic_retarget_used": False,
        "restore_epsilon": RESTORE_EPSILON,
        "control_restore_max_matrix_delta": restore_delta,
        "vessel_matrix_delta": vessel_delta,
        "camera_matrix_delta": camera_delta,
        "next_action": "Use the atlas only to inform one deliberate direct whole-hand edit. Do not rank or promote response frames as candidates."
    }
    report_path.write_text(json.dumps(report, indent=2, sort_keys=True), encoding="utf-8")
    print(json.dumps(report, indent=2, sort_keys=True))
    print(SUCCESS)


if __name__ == "__main__":
    main()
