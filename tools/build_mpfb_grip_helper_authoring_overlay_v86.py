#!/usr/bin/env python3
"""Build v86: v85 ghost-guided semantic-grip scene + non-mutating discrepancy arrows.

This is authoring infrastructure only. It does not change any pose bone, vessel transform,
camera transform, acceptance reference, or gameplay state. It reuses the locked v85 scene
and draws read-only colored arrows from the current fingertip positions toward the mapped
ContactPose real-human fingertip landmarks so a human artist can see the remaining depth /
enclosure mismatch directly in the Blender viewport.

The arrows are diagnostics, not optimizer targets. No retarget, CCD, endpoint solver,
contact servo, raw phalanx table, semantic-value sweep, or automatic pose modification is
performed. Final acceptance remains the unchanged opaque-vessel Macro render and the
unobstructed Meso anatomy render.
"""
from __future__ import annotations

import importlib.util
import json
import sys
from pathlib import Path

import bpy
from mathutils import Vector

BASE = Path(__file__).resolve().parent
SUCCESS = "MPFB_GRIP_HELPER_AUTHORING_OVERLAY_V86_SUCCESS"
TIP_BONES = {
    "thumb": "finger1-3.R",
    "index": "finger2-3.R",
    "middle": "finger3-3.R",
    "ring": "finger4-3.R",
    "pinky": "finger5-3.R",
}
GHOST_TIP_INDEX = {"thumb": 4, "index": 8, "middle": 12, "ring": 16, "pinky": 20}
COLORS = {
    "thumb": (0.95, 0.35, 0.20, 1.0),
    "index": (0.35, 1.00, 0.35, 1.0),
    "middle": (1.00, 0.88, 0.20, 1.0),
    "ring": (1.00, 0.48, 0.12, 1.0),
    "pinky": (0.95, 0.20, 0.85, 1.0),
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


def _mat(name: str, color):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = color
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs["Base Color"].default_value = color
        bsdf.inputs["Emission Color"].default_value = color
        bsdf.inputs["Emission Strength"].default_value = 2.0
        bsdf.inputs["Roughness"].default_value = 0.32
    return mat


def _cylinder(a: Vector, b: Vector, radius: float, material, name: str):
    d = b - a
    if d.length < 1e-8:
        return None
    bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=radius, depth=d.length, location=(a + b) * 0.5)
    obj = bpy.context.object
    obj.name = name
    obj.data.materials.append(material)
    obj.rotation_mode = "QUATERNION"
    obj.rotation_quaternion = Vector((0, 0, 1)).rotation_difference(d.normalized())
    obj.hide_select = True
    obj["authoring_overlay_only"] = True
    return obj


def _cone(tip: Vector, direction: Vector, length: float, radius: float, material, name: str):
    if direction.length < 1e-8:
        return None
    d = direction.normalized()
    center = tip - d * length * 0.5
    bpy.ops.mesh.primitive_cone_add(vertices=12, radius1=radius, radius2=0.0, depth=length, location=center)
    obj = bpy.context.object
    obj.name = name
    obj.data.materials.append(material)
    obj.rotation_mode = "QUATERNION"
    obj.rotation_quaternion = Vector((0, 0, 1)).rotation_difference(d)
    obj.hide_select = True
    obj["authoring_overlay_only"] = True
    return obj


def _actual_tip(arm, bone_name: str) -> Vector:
    pb = arm.pose.bones.get(bone_name)
    if pb is None:
        raise RuntimeError("missing fingertip pose bone " + bone_name)
    return arm.matrix_world @ pb.tail


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


def run():
    ext, source_path, out, report_path = _args()
    out.mkdir(parents=True, exist_ok=True)
    report_path.parent.mkdir(parents=True, exist_ok=True)

    v85_blend = out / "peel-calm-grip-helper-ghost-v85-base.blend"
    v85_report = out / "v85-base-report.json"
    old_argv = list(sys.argv)
    try:
        sys.argv = [old_argv[0], "--", ext, str(source_path), str(out), str(v85_report)]
        v85.run()
    finally:
        sys.argv = old_argv

    generated = out / "peel-calm-grip-helper-ghost-v85.blend"
    if not generated.exists():
        raise RuntimeError("v85 base blend was not generated")
    generated.replace(v85_blend)
    bpy.ops.wm.open_mainfile(filepath=str(v85_blend))

    source = json.loads(source_path.read_text(encoding="utf-8"))
    arm = bpy.data.objects.get("MPFB_V84_AuthoringRig")
    vessel = bpy.data.objects.get("LOCKED_VesselProxy")
    wire = bpy.data.objects.get("AUTHORING_WireVesselGuide_V85")
    cam = bpy.data.objects.get("LOCKED_V84_Camera")
    if arm is None or vessel is None or wire is None or cam is None:
        raise RuntimeError("v85 authoring contract missing")

    before = {name: [list(row) for row in arm.pose.bones[name].matrix_basis] for name in v84.CONTROLS}
    mapped, palm_width = v85._map(arm, source)

    coll = bpy.data.collections.new("AUTHORING_FINGERTIP_DISCREPANCY_OVERLAY_V86")
    bpy.context.scene.collection.children.link(coll)
    deltas = {}
    overlay_objects = []
    shaft_radius = max(0.00055, palm_width * 0.010)
    head_len = max(0.0030, palm_width * 0.075)
    head_radius = max(0.0016, palm_width * 0.030)

    for digit in ("thumb", "index", "middle", "ring", "pinky"):
        actual = _actual_tip(arm, TIP_BONES[digit])
        target = mapped[GHOST_TIP_INDEX[digit]]
        delta = target - actual
        material = _mat("V86_" + digit.upper() + "_DISCREPANCY", COLORS[digit])
        shaft_end = target - delta.normalized() * head_len if delta.length > head_len else actual
        shaft = _cylinder(actual, shaft_end, shaft_radius, material, "V86_" + digit.upper() + "_TO_GHOST")
        arrow = _cone(target, delta, min(head_len, max(delta.length * 0.35, head_len * 0.45)), head_radius, material, "V86_" + digit.upper() + "_TARGET_ARROW")
        for obj in (shaft, arrow):
            if obj is None:
                continue
            for parent in list(obj.users_collection):
                parent.objects.unlink(obj)
            coll.objects.link(obj)
            obj["digit"] = digit
            obj["diagnostic_not_optimizer"] = True
            overlay_objects.append(obj)
        deltas[digit] = {
            "distance_m": delta.length,
            "current_tip_world": list(actual),
            "ghost_tip_world": list(target),
        }

    after = {name: [list(row) for row in arm.pose.bones[name].matrix_basis] for name in v84.CONTROLS}
    max_delta = max(abs(before[n][r][c] - after[n][r][c]) for n in before for r in range(4) for c in range(4))
    if max_delta > 1e-9:
        raise RuntimeError(f"v86 overlay changed authoring controls: {max_delta}")

    scene = bpy.context.scene
    scene["peel_calm_visual_verdict"] = "PENDING_DIRECT_ARTIST_EDIT"
    scene["production_candidate"] = False
    scene["v86_overlay_pose_mutation"] = False
    scene["v86_overlay_is_optimizer"] = False
    scene["v86_overlay_control_max_matrix_delta"] = max_delta
    arm["peel_calm_authoring_version"] = "v86"
    arm["authoring_overlay"] = "colored fingertip-to-ContactPose discrepancy arrows; guide only"

    text = bpy.data.texts.get("PEEL_CALM_V86_AUTHORING_OVERLAY") or bpy.data.texts.new("PEEL_CALM_V86_AUTHORING_OVERLAY")
    text.clear()
    text.write(
        "PEEL CALM v86 DIRECT-VISUAL AUTHORING OVERLAY\n\n"
        "Colored arrows show current fingertip -> ContactPose real-human fingertip discrepancy.\n"
        "They are visual landmarks only, NOT optimizer targets and NOT acceptance criteria.\n"
        "Do not mechanically place every fingertip on an arrow endpoint. Preserve natural web space, knuckle flow, and reference silhouette.\n"
        "Editable remains ONLY: wrist.R, right_master_grip, right_finger1_grip..right_finger5_grip.\n"
        "Locked: vessel, camera, bar_v1/market_v1 acceptance intent.\n"
        "Final Macro judgment still uses opaque vessel with overlays hidden.\n"
    )

    # Authoring-only diagnostic render: wire vessel + ghost + discrepancy arrows.
    vessel.hide_render = True
    wire.hide_render = False
    for obj in overlay_objects:
        obj.hide_render = False
    _render(out / "v86-authoring-overlay-wire.png", 640, 640)
    _render(out / "v86-authoring-overlay-thumbnail.png", 192, 108)

    # Unobstructed anatomy diagnostic with overlay.
    wire.hide_render = True
    _render(out / "v86-authoring-overlay-anatomy.png", 640, 640)

    # Preserve the unchanged final Macro context with all authoring overlays hidden.
    for obj in overlay_objects:
        obj.hide_render = True
    vessel.hide_render = False
    _render(out / "v86-unchanged-opaque-macro.png", 192, 108)

    # Restore authoring visibility for the editable .blend viewport.
    vessel.hide_render = True
    wire.hide_render = False
    for obj in overlay_objects:
        obj.hide_render = False

    blend = out / "peel-calm-grip-helper-authoring-overlay-v86.blend"
    bpy.context.view_layer.objects.active = arm
    arm.select_set(True)
    bpy.ops.wm.save_as_mainfile(filepath=str(blend), check_existing=False)

    report = {
        "staging_only": True,
        "production_candidate": False,
        "authoring_infrastructure_only": True,
        "visual_verdict": "PENDING_DIRECT_ARTIST_EDIT",
        "reference_set": ["bar_v1", "market_v1"],
        "editable_controls": v84.CONTROLS,
        "ghost_source": "ContactPose water_bottle full6_use hand1",
        "overlay_kind": "fingertip discrepancy arrows",
        "overlay_is_optimizer": False,
        "automatic_retarget_used": False,
        "parameter_sweep_used": False,
        "pose_control_max_matrix_delta_from_v85": max_delta,
        "vessel_locked": True,
        "camera_locked": True,
        "digit_discrepancies": deltas,
        "blend": str(blend),
        "next_gate": "Use the overlay only to visually author exactly one whole-hand pose with the seven semantic controls. Hide all authoring overlays and judge final Macro on the unchanged opaque vessel; then judge unobstructed Meso anatomy.",
    }
    report_path.write_text(json.dumps(report, indent=2, sort_keys=True), encoding="utf-8")
    print(json.dumps(report, indent=2, sort_keys=True))
    print(SUCCESS)


if __name__ == "__main__":
    run()
