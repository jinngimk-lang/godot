#!/usr/bin/env python3
"""Build a native MPFB Default-rig support-grasp authoring scene.

This is an authoring bridge, not a solver. It exposes only semantic controls:
- wrist.R for whole-hand orientation/placement
- right_master_grip
- right_finger1_grip .. right_finger5_grip

The scene starts from the single v83 semantic seed, preserves a fixed bottle proxy and
camera, embeds the anti-drift visual contract, and saves a .blend that can be edited
interactively. It does not retarget ContactPose, sweep parameters, or edit raw phalanx bones.
"""
from __future__ import annotations

import importlib
import json
import math
import sys
from pathlib import Path

import bpy
from mathutils import Vector

SUCCESS = "MPFB_GRIP_HELPER_AUTHORING_V84_SUCCESS"
CONTROLS = ["wrist.R", "right_master_grip"] + [f"right_finger{i}_grip" for i in range(1, 6)]
SEED = {
    "right_master_grip": 34.0,
    "right_finger1_grip": 10.0,
    "right_finger2_grip": -12.0,
    "right_finger3_grip": 2.0,
    "right_finger4_grip": 10.0,
    "right_finger5_grip": 18.0,
}


def args():
    if "--" not in sys.argv:
        raise RuntimeError("expected -- <extension-module> <output.blend> <report.json>")
    v = sys.argv[sys.argv.index("--") + 1:]
    if len(v) != 3:
        raise RuntimeError("expected three arguments")
    return v[0], Path(v[1]).resolve(), Path(v[2]).resolve()


def reset():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)


def wp(arm, name: str, tail=False):
    pb = arm.pose.bones.get(name)
    if pb is None:
        raise RuntimeError("missing bone " + name)
    return arm.matrix_world @ (pb.tail if tail else pb.head)


def material(name, color, roughness):
    m = bpy.data.materials.new(name); m.use_nodes = True
    p = next((n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED"), None)
    if p:
        p.inputs["Base Color"].default_value = (*color, 1.0)
        p.inputs["Roughness"].default_value = roughness
    return m


def look(cam, target):
    cam.rotation_euler = (target - cam.location).to_track_quat("-Z", "Y").to_euler()


def main():
    ext, blend_path, report_path = args()
    blend_path.parent.mkdir(parents=True, exist_ok=True); report_path.parent.mkdir(parents=True, exist_ok=True)
    reset()
    mpfb = importlib.import_module(ext)
    services = importlib.import_module(ext + ".services")
    finger_mod = importlib.import_module(ext + ".entities.rigging.righelpers.fingerhelpers.fingerhelpers")
    HumanService = getattr(services, "HumanService"); FingerHelpers = getattr(finger_mod, "FingerHelpers")

    basemesh = HumanService.create_human(mask_helpers=True, detailed_helpers=False, extra_vertex_groups=True, feet_on_ground=False, scale=0.1, macro_detail_dict=None)
    basemesh.name = "MPFB_V84_ReferenceHuman"
    arm = HumanService.add_builtin_rig(basemesh, "default", import_weights=True, operator=None)
    if arm is None:
        raise RuntimeError("failed to create Default rig")
    arm.name = "MPFB_V84_AuthoringRig"

    helper = FingerHelpers.get_instance("right", {"finger_helpers_type": "GRIP_AND_MASTER", "hide_fk": False}, "Default")
    helper.apply_ik(arm)
    for name, deg in SEED.items():
        pb = arm.pose.bones.get(name)
        if pb is None:
            raise RuntimeError("missing semantic grip helper " + name)
        pb.rotation_mode = "XYZ"; pb.rotation_euler.x = math.radians(deg)
    bpy.context.view_layer.update()

    roots = [wp(arm, f"finger{i}-1.R") for i in range(2, 6)]
    wrist = wp(arm, "wrist.R")
    palm = (wrist + sum(roots, Vector())) / 5.0
    tips = [wp(arm, f"finger{i}-3.R", True) for i in range(2, 6)]
    mean_tips = sum(tips, Vector()) / 4.0
    vessel_center = palm.lerp(mean_tips, 0.47)

    bpy.ops.mesh.primitive_cylinder_add(vertices=64, radius=0.038, depth=0.20, location=vessel_center)
    vessel = bpy.context.object; vessel.name = "LOCKED_VesselProxy"
    vessel.data.materials.append(material("V84_Vessel", (0.18, 0.28, 0.34), 0.38))
    vessel.hide_select = True

    focus = palm.lerp(vessel_center, 0.55)
    cam_data = bpy.data.cameras.new("LOCKED_V84_Camera")
    cam = bpy.data.objects.new("LOCKED_V84_Camera", cam_data); bpy.context.scene.collection.objects.link(cam)
    cam_data.lens = 68; cam.location = focus + Vector((0.23, -0.28, 0.11)); look(cam, focus)
    bpy.context.scene.camera = cam; cam.hide_select = True

    for name, energy, size, offset in [
        ("LOCKED_V84_Key", 300, 0.8, Vector((-0.35,-0.35,0.40))),
        ("LOCKED_V84_Fill", 100, 0.7, Vector((0.20,0.10,0.25))),
    ]:
        ld = bpy.data.lights.new(name, "AREA"); ld.energy = energy; ld.size = size
        lo = bpy.data.objects.new(name, ld); lo.location = focus + offset; lo.hide_select = True; bpy.context.scene.collection.objects.link(lo)

    # Embed the authoring contract in the scene so a reopened file carries the rules.
    arm["peel_calm_authoring_version"] = "v84"
    arm["acceptance_references"] = "bar_v1,market_v1"
    arm["authoring_goal"] = "Natural human vessel wrap: palm beside vessel, thumb opposing four fingers, index lighter and middle/ring/pinky progressively deeper around far contour."
    arm["macro_gate"] = "At 192x108 the silhouette must immediately read as a stable human bottle grip."
    arm["meso_gate"] = "Oblique anatomy must preserve web space, knuckle flow, separated progressive digit arcs and no self-intersection."
    arm["forbidden"] = "CCD; endpoint optimizer; contact servo; ContactPose exact retarget; raw phalanx angle sweep; whole-hand orbit sweep"
    arm["editable_controls"] = json.dumps(CONTROLS)
    arm["seed_source"] = "v83 single semantic Grip Helper candidate; visual REJECT but anatomically smoother than v82"
    arm["production_candidate"] = False

    # Select exactly the semantic authoring controls plus wrist.
    bpy.context.view_layer.objects.active = arm; arm.select_set(True); bpy.ops.object.mode_set(mode="POSE")
    for pb in arm.pose.bones:
        pb.bone.select = pb.name in CONTROLS
    active = arm.pose.bones.get("right_master_grip")
    if active is not None:
        arm.data.bones.active = active.bone
    bpy.ops.object.mode_set(mode="OBJECT")

    bpy.context.scene["peel_calm_visual_verdict"] = "PENDING_DIRECT_ARTIST_EDIT"
    bpy.context.scene["locked_vessel_object"] = vessel.name
    bpy.context.scene["locked_camera_object"] = cam.name
    bpy.context.scene["candidate_count"] = 1
    bpy.context.scene["parameter_sweep_used"] = False

    bpy.ops.wm.save_as_mainfile(filepath=str(blend_path))
    report = {
        "blend": str(blend_path),
        "bytes": blend_path.stat().st_size,
        "mpfb_version": list(mpfb.VERSION),
        "rig": "MPFB Default",
        "helper_mode": "GRIP_AND_MASTER",
        "editable_controls": CONTROLS,
        "semantic_seed_degrees": SEED,
        "candidate_count": 1,
        "parameter_sweep_used": False,
        "visual_verdict": "PENDING_DIRECT_ARTIST_EDIT",
        "production_candidate": False,
        "locked_acceptance_references": ["bar_v1", "market_v1"],
        "vessel_locked": True,
        "camera_locked": True,
    }
    report_path.write_text(json.dumps(report, indent=2, sort_keys=True), encoding="utf-8")
    print(json.dumps(report, indent=2, sort_keys=True)); print(SUCCESS)


if __name__ == "__main__":
    main()
