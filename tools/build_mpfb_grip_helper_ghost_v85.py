#!/usr/bin/env python3
"""Build v85: v84 semantic-grip authoring scene + a read-only real-human grasp ghost.

This is authoring infrastructure, not a pose solver or production candidate. It keeps the
seven v84 semantic controls, locked vessel/camera, and PENDING visual verdict intact while
overlaying the verified ContactPose water-bottle 21-joint annotation as cyan geometry.
No ContactPose transform is copied into pose bones and no parameter sweep is performed.
"""
from __future__ import annotations

import importlib.util
import json
import sys
from pathlib import Path

import bpy
from mathutils import Vector

BASE = Path(__file__).resolve().parent
SUCCESS = "MPFB_GRIP_HELPER_GHOST_V85_SUCCESS"
CHAINS = {
    "thumb": [0, 1, 2, 3, 4],
    "index": [0, 5, 6, 7, 8],
    "middle": [0, 9, 10, 11, 12],
    "ring": [0, 13, 14, 15, 16],
    "pinky": [0, 17, 18, 19, 20],
}


def _load(name: str, filename: str):
    spec = importlib.util.spec_from_file_location(name, BASE / filename)
    if spec is None or spec.loader is None:
        raise RuntimeError("could not load " + filename)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


v84 = _load("mpfb_v84_for_v85", "build_mpfb_grip_helper_authoring_v84.py")


def _args():
    if "--" not in sys.argv:
        raise RuntimeError("expected -- <extension-module> <source.json> <outdir> <report.json>")
    vals = sys.argv[sys.argv.index("--") + 1:]
    if len(vals) != 4:
        raise RuntimeError("expected four arguments")
    return vals[0], Path(vals[1]).resolve(), Path(vals[2]).resolve(), Path(vals[3]).resolve()


def _unit(v: Vector) -> Vector:
    if v.length < 1e-8:
        raise RuntimeError("degenerate guide basis")
    return v.normalized()


def _wp(arm, name: str) -> Vector:
    pb = arm.pose.bones.get(name)
    if pb is None:
        raise RuntimeError("missing pose bone " + name)
    return arm.matrix_world @ pb.head


def _target_frame(arm):
    wrist = _wp(arm, "wrist.R")
    index = _wp(arm, "finger2-1.R")
    middle = _wp(arm, "finger3-1.R")
    pinky = _wp(arm, "finger5-1.R")
    x = _unit(index - pinky)
    y_hint = _unit(middle - wrist)
    z = _unit(x.cross(y_hint))
    y = _unit(z.cross(x))
    return wrist, x, y, z, (index - pinky).length


def _material():
    mat = bpy.data.materials.new("CONTACTPOSE_REAL_GRASP_GUIDE_MIT_V85")
    mat.diffuse_color = (0.03, 0.72, 1.0, 1.0)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs["Base Color"].default_value = (0.03, 0.72, 1.0, 1.0)
        bsdf.inputs["Emission Color"].default_value = (0.03, 0.72, 1.0, 1.0)
        bsdf.inputs["Emission Strength"].default_value = 1.6
        bsdf.inputs["Roughness"].default_value = 0.35
    return mat


def _sphere(p: Vector, radius: float, mat, name: str):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=12, ring_count=8, radius=radius, location=p)
    obj = bpy.context.object
    obj.name = name
    obj.data.materials.append(mat)
    obj["contactpose_guide"] = True
    obj.hide_select = True
    return obj


def _segment(a: Vector, b: Vector, radius: float, mat, name: str):
    d = b - a
    if d.length < 1e-8:
        return None
    bpy.ops.mesh.primitive_cylinder_add(vertices=10, radius=radius, depth=d.length, location=(a+b)*0.5)
    obj = bpy.context.object
    obj.name = name
    obj.data.materials.append(mat)
    obj.rotation_mode = "QUATERNION"
    obj.rotation_quaternion = Vector((0,0,1)).rotation_difference(d.normalized())
    obj["contactpose_guide"] = True
    obj.hide_select = True
    return obj


def _map(arm, source):
    joints = source.get("normalized_openpose21")
    if not isinstance(joints, list) or len(joints) != 21:
        raise RuntimeError("source requires normalized_openpose21 with 21 joints")
    origin, x, y, z, palm_width = _target_frame(arm)
    mapped = []
    for xyz in joints:
        p = Vector((float(xyz[0]), float(xyz[1]), float(xyz[2])))
        mapped.append(origin + (x*p.x + y*p.y + z*p.z)*palm_width)
    return mapped, palm_width


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
    source = json.loads(source_path.read_text(encoding="utf-8"))
    if source.get("object") != "water_bottle" or source.get("session") != "full6_use" or source.get("hand_index") != 1:
        raise RuntimeError("v85 is locked to ContactPose water_bottle full6_use hand1")

    base_blend = out / "peel-calm-grip-helper-v84-base.blend"
    base_report = out / "v84-base-report.json"
    old_argv = list(sys.argv)
    try:
        sys.argv = [old_argv[0], "--", ext, str(base_blend), str(base_report)]
        v84.main()
    finally:
        sys.argv = old_argv
    bpy.ops.wm.open_mainfile(filepath=str(base_blend))

    arm = bpy.data.objects.get("MPFB_V84_AuthoringRig")
    vessel = bpy.data.objects.get("LOCKED_VesselProxy")
    cam = bpy.data.objects.get("LOCKED_V84_Camera")
    if arm is None or vessel is None or cam is None:
        raise RuntimeError("v84 authoring contract missing after reopen")

    before = {name: [list(row) for row in arm.pose.bones[name].matrix_basis] for name in v84.CONTROLS}
    mapped, palm_width = _map(arm, source)
    mat = _material()
    coll = bpy.data.collections.new("CONTACTPOSE_REAL_WATER_BOTTLE_GHOST_V85")
    bpy.context.scene.collection.children.link(coll)
    objects = []
    jr = max(0.0012, palm_width*0.035)
    br = max(0.00065, palm_width*0.014)
    for i, p in enumerate(mapped):
        objects.append(_sphere(p, jr, mat, f"CP85_JOINT_{i:02d}"))
    for digit, chain in CHAINS.items():
        for s, (ia, ib) in enumerate(zip(chain[:-1], chain[1:])):
            obj = _segment(mapped[ia], mapped[ib], br, mat, f"CP85_{digit.upper()}_{s}")
            if obj:
                objects.append(obj)
    for obj in objects:
        for parent in list(obj.users_collection):
            parent.objects.unlink(obj)
        coll.objects.link(obj)
        obj["guide_only"] = True
        obj["source_dataset"] = "ContactPose public Explorer"
        obj["license_scope"] = "MIT annotation data only"

    after = {name: [list(row) for row in arm.pose.bones[name].matrix_basis] for name in v84.CONTROLS}
    max_delta = max(abs(before[n][r][c]-after[n][r][c]) for n in before for r in range(4) for c in range(4))
    if max_delta > 1e-9:
        raise RuntimeError(f"ghost overlay changed authoring controls: {max_delta}")

    arm["peel_calm_authoring_version"] = "v85"
    arm["contactpose_ghost_guide"] = "water_bottle full6_use hand1"
    arm["contactpose_guide_only"] = True
    arm["authoring_goal"] = (
        "Use wrist + six semantic grip controls to visually approach the cyan real-human grasp grammar; "
        "do not retarget the ghost. Final acceptance remains locked bar_v1/market_v1."
    )
    scene = bpy.context.scene
    scene["peel_calm_visual_verdict"] = "PENDING_DIRECT_ARTIST_EDIT"
    scene["production_candidate"] = False
    scene["contactpose_automatic_retarget"] = False
    scene["parameter_sweep_used"] = False

    text = bpy.data.texts.get("PEEL_CALM_V85_AUTHORING_GUIDE") or bpy.data.texts.new("PEEL_CALM_V85_AUTHORING_GUIDE")
    text.clear()
    text.write(
        "PEEL CALM v85 SEMANTIC GRIP + REAL HUMAN GHOST\n\n"
        "Cyan = ContactPose water_bottle full6_use hand1 21-joint annotation, guide only.\n"
        "Editable: wrist.R, right_master_grip, right_finger1_grip..right_finger5_grip.\n"
        "Locked: bottle, camera, bar_v1/market_v1 acceptance intent.\n"
        "Forbidden: automatic retarget, CCD, endpoint/contact optimizers, raw-phalanx tables, parameter sweeps.\n"
        "Macro gate: at 192x108 the hand must immediately read as a stable human vessel wrap.\n"
        "Meso gate: thumb opposition, web space, knuckle flow and progressive digit depth must remain human.\n"
    )

    vessel.hide_render = False
    _render(out / "v85-ghost-with-vessel.png", 640, 640)
    _render(out / "v85-ghost-thumbnail.png", 192, 108)
    vessel.hide_render = True
    _render(out / "v85-ghost-anatomy.png", 640, 640)
    vessel.hide_render = False

    bpy.context.view_layer.objects.active = arm
    arm.select_set(True)
    bpy.ops.object.mode_set(mode="POSE")
    for pb in arm.pose.bones:
        pb.bone.select = pb.name in v84.CONTROLS
    arm.data.bones.active = arm.data.bones["right_master_grip"]
    bpy.ops.object.mode_set(mode="OBJECT")

    blend = out / "peel-calm-grip-helper-ghost-v85.blend"
    bpy.ops.wm.save_as_mainfile(filepath=str(blend), check_existing=False)
    report = {
        "staging_only": True,
        "production_candidate": False,
        "authoring_infrastructure_only": True,
        "visual_verdict": "PENDING_DIRECT_ARTIST_EDIT",
        "reference_set": ["bar_v1", "market_v1"],
        "editable_controls": v84.CONTROLS,
        "ghost_source": "ContactPose water_bottle full6_use hand1",
        "ghost_joint_count": len(mapped),
        "ghost_object_count": len(objects),
        "automatic_retarget_used": False,
        "parameter_sweep_used": False,
        "pose_control_max_matrix_delta_from_v84": max_delta,
        "vessel_locked": True,
        "camera_locked": True,
        "blend": str(blend),
        "next_gate": "Directly visually author exactly one pose with the seven semantic controls; then render Macro/Meso and reject unless it reads as a natural human vessel wrap.",
    }
    report_path.write_text(json.dumps(report, indent=2, sort_keys=True), encoding="utf-8")
    print(json.dumps(report, indent=2, sort_keys=True))
    print(SUCCESS)


if __name__ == "__main__":
    run()
