#!/usr/bin/env python3
"""v81: embed a real ContactPose water-bottle skeleton as a visual ghost guide.

v80 proved that exact automatic direction retarget (0° direction error) still fails the
Peel Calm Macro vessel-wrap silhouette. The source anatomy is useful; automatic transfer
is not. This script therefore does NOT modify the GameEngine pose at all. It regenerates
the verified native-rig v77 artist-authoring scene, then overlays the selected real-human
ContactPose skeleton as visible geometry in the same palm-local frame and saves a new
editable .blend. The guide exists only to support direct visual artist posing.
"""
from __future__ import annotations

import importlib.util
import json
import sys
import traceback
from pathlib import Path

import bpy
from mathutils import Vector

BASE = Path(__file__).resolve().parent


def _load(name: str, filename: str):
    spec = importlib.util.spec_from_file_location(name, BASE / filename)
    if spec is None or spec.loader is None:
        raise RuntimeError("could not load " + filename)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


v77 = _load("mpfb_v77_for_v81", "build_mpfb_artist_authoring_scene_v77.py")
v65 = v77.v65

SUCCESS = "MPFB_CONTACTPOSE_GHOST_GUIDE_V81_SUCCESS"
CHAINS = {
    "thumb": [0, 1, 2, 3, 4],
    "index": [0, 5, 6, 7, 8],
    "middle": [0, 9, 10, 11, 12],
    "ring": [0, 13, 14, 15, 16],
    "pinky": [0, 17, 18, 19, 20],
}


def _args():
    if "--" not in sys.argv:
        raise RuntimeError("expected -- <extension-module> <source.json> <outdir> <report.json>")
    vals = sys.argv[sys.argv.index("--") + 1 :]
    if len(vals) != 4:
        raise RuntimeError("expected four arguments")
    return vals[0], Path(vals[1]).resolve(), Path(vals[2]).resolve(), Path(vals[3]).resolve()


def _unit(v: Vector) -> Vector:
    if v.length < 1e-8:
        raise RuntimeError("degenerate guide basis")
    return v.normalized()


def _wp(arm, name: str) -> Vector:
    return arm.matrix_world @ arm.pose.bones[name].head


def _target_frame(arm):
    wrist = _wp(arm, "wrist.R")
    index = _wp(arm, "finger2-1.R")
    middle = _wp(arm, "finger3-1.R")
    pinky = _wp(arm, "finger5-1.R")
    x = _unit(index - pinky)
    y_hint = _unit(middle - wrist)
    z = _unit(x.cross(y_hint))
    y = _unit(z.cross(x))
    palm_width = (index - pinky).length
    return wrist, x, y, z, palm_width


def _guide_material():
    mat = bpy.data.materials.new("CONTACTPOSE_REAL_GRASP_GUIDE_MIT")
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs["Base Color"].default_value = (0.05, 0.75, 1.0, 1.0)
        bsdf.inputs["Emission Color"].default_value = (0.05, 0.75, 1.0, 1.0)
        bsdf.inputs["Emission Strength"].default_value = 2.0
        bsdf.inputs["Roughness"].default_value = 0.4
    return mat


def _sphere(location: Vector, radius: float, mat, name: str):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=12, ring_count=8, radius=radius, location=location)
    obj = bpy.context.object
    obj.name = name
    obj.data.materials.append(mat)
    obj["contactpose_guide"] = True
    return obj


def _segment(a: Vector, b: Vector, radius: float, mat, name: str):
    d = b - a
    length = d.length
    if length < 1e-8:
        return None
    mid = (a + b) * 0.5
    bpy.ops.mesh.primitive_cylinder_add(vertices=10, radius=radius, depth=length, location=mid)
    obj = bpy.context.object
    obj.name = name
    obj.data.materials.append(mat)
    obj.rotation_mode = "QUATERNION"
    obj.rotation_quaternion = Vector((0.0, 0.0, 1.0)).rotation_difference(d.normalized())
    obj["contactpose_guide"] = True
    return obj


def _map_joints(arm, source):
    joints = source["normalized_openpose21"]
    if len(joints) != 21:
        raise RuntimeError("source requires exactly 21 normalized OpenPose hand joints")
    origin, x, y, z, palm_width = _target_frame(arm)
    mapped = []
    for xyz in joints:
        p = Vector((float(xyz[0]), float(xyz[1]), float(xyz[2])))
        mapped.append(origin + (x * p.x + y * p.y + z * p.z) * palm_width)
    return mapped, palm_width


def run():
    ext, source_path, out, report_path = _args()
    out.mkdir(parents=True, exist_ok=True)
    report_path.parent.mkdir(parents=True, exist_ok=True)
    source = json.loads(source_path.read_text(encoding="utf-8"))
    if source.get("object") != "water_bottle" or source.get("session") != "full6_use" or source.get("hand_index") != 1:
        raise RuntimeError("v81 is locked to selected full6_use hand1 water_bottle reference")

    # Generate the proven v77 native-rig authoring scene without authoring any new pose.
    v77_report = out / "v77-base-report.json"
    old_argv = list(sys.argv)
    try:
        sys.argv = [old_argv[0], "--", ext, str(out), str(v77_report)]
        v77.run()
    finally:
        sys.argv = old_argv

    v77_blend = out / "peel-calm-support-grasp-authoring-v77.blend"
    if not v77_blend.exists():
        raise RuntimeError("v77 base authoring scene was not produced")
    bpy.ops.wm.open_mainfile(filepath=str(v77_blend))

    arm = bpy.data.objects.get("PeelCalm_GameEngine_HeroRig_V77")
    vessel = bpy.data.objects.get("LOCKED_VESSEL_PROXY_V77")
    if arm is None or vessel is None:
        raise RuntimeError("v77 rig/vessel contract missing after reopen")
    arm.hide_set(False)
    arm.hide_viewport = False
    arm.show_in_front = True

    mapped, palm_width = _map_joints(arm, source)
    mat = _guide_material()
    guide_objects = []
    joint_radius = max(0.0012, palm_width * 0.035)
    bone_radius = max(0.00065, palm_width * 0.014)
    for i, p in enumerate(mapped):
        guide_objects.append(_sphere(p, joint_radius, mat, f"CP81_JOINT_{i:02d}"))
    for digit, chain in CHAINS.items():
        for seg_i, (ia, ib) in enumerate(zip(chain[:-1], chain[1:])):
            obj = _segment(mapped[ia], mapped[ib], bone_radius, mat, f"CP81_{digit.upper()}_{seg_i}")
            if obj is not None:
                guide_objects.append(obj)

    guide_collection = bpy.data.collections.new("CONTACTPOSE_REAL_WATER_BOTTLE_GUIDE_V81")
    bpy.context.scene.collection.children.link(guide_collection)
    for obj in guide_objects:
        for coll in list(obj.users_collection):
            coll.objects.unlink(obj)
        guide_collection.objects.link(obj)
        obj["source_dataset"] = "ContactPose public Explorer"
        obj["source_session"] = "full6_use"
        obj["source_hand_index"] = 1
        obj["license_scope"] = "MIT annotation data only"
        obj["guide_only"] = True

    text = bpy.data.texts.get("CONTACTPOSE_V81_GUIDE_CONTRACT") or bpy.data.texts.new("CONTACTPOSE_V81_GUIDE_CONTRACT")
    text.clear()
    text.write(
        "CONTACTPOSE REAL-GRASP GHOST GUIDE v81\n\n"
        "This cyan skeleton is a visual anatomical reference only. It is derived from the public ContactPose "
        "water_bottle full6_use hand1 21-joint annotation (MIT non-3D-model data).\n"
        "Do not auto-retarget, run CCD, chase endpoints, sweep angles, or copy edit-bone roll/rest transforms.\n"
        "Pose the selected native GameEngine finger bones visually so the final 192x108 silhouette matches "
        "the LOCKED Peel Calm bar_v1/market_v1 acceptance intent: fingers progressively wrap to the far side "
        "and thumb visibly opposes them. The ghost is anatomical guidance, not an acceptance replacement.\n"
    )
    arm["contactpose_ghost_guide"] = "full6_use hand1 water_bottle"
    arm["contactpose_guide_only"] = True
    arm["peel_calm_rule_v81"] = "Visual artist posing only; do not automatic-retarget the ghost."

    # Render current authoring seed + ghost. This is a capability worksheet, NOT a pose candidate.
    scene = bpy.context.scene
    scene.camera.data.lens = scene.camera.data.lens
    vessel.hide_render = False
    v65._render(out / "v81-ghost-guide-with-vessel.png", 640, 640)
    v65._render(out / "v81-ghost-guide-thumbnail.png", 192, 108)
    vessel.hide_render = True
    v65._render(out / "v81-ghost-guide-anatomy.png", 640, 640)
    vessel.hide_render = False

    # Return to Pose mode with only non-thumb fingers selected, preserving v77 interaction contract.
    bpy.context.view_layer.objects.active = arm
    arm.select_set(True)
    if arm.mode != "POSE":
        bpy.ops.object.mode_set(mode="POSE")
    for bone in arm.data.bones:
        bone.select = False
    for name in v77.EDIT_BONES:
        arm.data.bones[name].select = True
    arm.data.bones.active = arm.data.bones["finger2-1.R"]

    blend_path = out / "peel-calm-support-grasp-contactpose-guide-v81.blend"
    bpy.ops.wm.save_as_mainfile(filepath=str(blend_path), check_existing=False)

    report = {
        "staging_only": True,
        "production_candidate": False,
        "authoring_infrastructure_only": True,
        "native_gameengine_rig": True,
        "reference_set": ["bar_v1", "market_v1"],
        "ghost_source": {
            "dataset": "ContactPose public Explorer",
            "object": source["object"],
            "session": source["session"],
            "hand_index": source["hand_index"],
            "license_scope": source["license_scope"],
        },
        "automatic_retarget_used": False,
        "parameter_sweep_used": False,
        "ccd_used": False,
        "endpoint_optimizer_used": False,
        "contact_servo_used": False,
        "pose_modified_by_v81": False,
        "guide_joint_count": len(mapped),
        "guide_object_count": len(guide_objects),
        "target_palm_width_m": palm_width,
        "editable_pose_bones": v77.EDIT_BONES,
        "frozen_pose_bones": v77.FROZEN_BONES,
        "blend_path": str(blend_path),
        "next_gate": (
            "Use this .blend for direct visual native-rig posing only. The ghost supplies real-human cylindrical "
            "grasp anatomy but does not redefine the locked acceptance references. A future pose must still pass "
            "the 192x108 bar/market Macro grip silhouette and unobstructed Meso anatomy gates."
        ),
    }
    report_path.write_text(json.dumps(report, indent=2, sort_keys=True), encoding="utf-8")
    print(json.dumps(report, indent=2, sort_keys=True))
    print(SUCCESS)


if __name__ == "__main__":
    try:
        run()
    except BaseException as exc:
        print("MPFB_CONTACTPOSE_GHOST_GUIDE_V81_ERROR:", exc)
        traceback.print_exc()
        raise
