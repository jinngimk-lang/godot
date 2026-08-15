#!/usr/bin/env python3
"""v77: build a reproducible native-GameEngine artist-authoring Blender scene.

v76 closed the scripted fan/curl-correction path: the exact technical candidate passed but the
192x108 and unobstructed views still failed Macro/Meso. The next abstraction must therefore be
direct pose editing on the native rig rather than another numerical finger solver.

This script intentionally does NOT author a new support pose. It reconstructs the verified v74
thumb seed on the pristine v65-B continuous MPFB limb, freezes the camera/vessel/wrist/palm setup,
selects only the twelve non-thumb finger pose bones for direct editing, embeds acceptance/pose
rules inside the .blend, saves the durable seed pose, renders a baseline worksheet, and writes a
machine-readable report. The .blend is an ephemeral CI artifact; the script/report make it
reproducible so the project does not depend on artifact expiry.
"""
from __future__ import annotations

import importlib.util
import json
import sys
import traceback
from pathlib import Path

import bpy

BASE = Path(__file__).resolve().parent


def _load(name: str, file: str):
    spec = importlib.util.spec_from_file_location(name, BASE / file)
    if spec is None or spec.loader is None:
        raise RuntimeError("could not load " + file)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


v76 = _load("mpfb_v76_for_v77", "author_mpfb_finger_wrap_v76.py")
v73 = v76.v73
v65 = v76.v65
v64 = v76.v64
v64b = v76.v64b
v68 = v76.v68

SUCCESS = "MPFB_ARTIST_AUTHORING_SCENE_V77_SUCCESS"
EDIT_BONES = [f"finger{digit}-{joint}.R" for digit in range(2, 6) for joint in range(1, 4)]
FROZEN_BONES = ["wrist.R", "finger1-1.R", "finger1-2.R", "finger1-3.R"]

GUIDE = """PEEL CALM — SUPPORT-GRASP ARTIST AUTHORING v77

LOCKED ACCEPTANCE REFERENCES
- bar_v1: realistic bare support hand firmly grips the slender amber bottle.
- market_v1: realistic large support hand steadies the slender clear bottle.
Runtime/staging renders are evidence only and must not replace the locked references.

WHY THIS SCENE EXISTS
v76 proved that another scripted fan/curl correction does not fix the Macro/Meso grasp grammar.
Do not use CCD, endpoint chasing, contact servo, scalar angle sweeps, whole-hand orbit search, or
another procedural finger solver here. Pose the visible silhouette directly on this SAME native
GameEngine rig.

FROZEN / DO NOT MOVE
- wrist.R
- finger1-1.R / finger1-2.R / finger1-3.R (the verified v74 opposing-thumb seed)
- vessel proxy
- fixed camera / staging crop
- whole-hand placement and continuous MPFB hand-wrist-forearm baseline

EDIT AS ONE WHOLE SHAPE
The twelve selected finger2..finger5 pose bones are the intended controls.
- index: least closed; must not spear forward toward camera.
- middle: closes farther around the vessel.
- ring: closes farther than middle, without collapsing under the palm.
- pinky: deepest relaxed wrap, but remains anatomically separated and non-kinked.
- the four chains should progressively disappear around the vessel far contour.
- preserve readable web spaces / knuckle flow; avoid a fist/claw clump.

VISUAL GATES
1) Macro: at 192x108, first glance reads as a relaxed but firm HUMAN BOTTLE SUPPORT GRIP.
2) Meso: unobstructed oblique view has clean digit ordering, continuous palm/wrist anatomy,
   no severe self-intersection, no blocky/kinked distal chains, and a clear opposing thumb.
3) Only after both pass may the pose enter Godot product-camera staging against XR baseline.

SAVING
Use the repository's durable same-rig partial-pose format for any accepted result. Do not import
BVH edit-bone roll/rest transforms into the production GameEngine rig.
"""


def _args():
    if "--" not in sys.argv:
        raise RuntimeError("expected -- <extension-module> <outdir> <report.json>")
    vals = sys.argv[sys.argv.index("--") + 1 :]
    if len(vals) != 3:
        raise RuntimeError("expected three arguments")
    return vals[0], Path(vals[1]).resolve(), Path(vals[2]).resolve()


def _flat(pb):
    return [float(pb.matrix_basis[r][c]) for r in range(4) for c in range(4)]


def _max_delta(before, after):
    return max(abs(a - b) for a, b in zip(before, after))


def run():
    ext, out, report_path = _args()
    out.mkdir(parents=True, exist_ok=True)
    report_path.parent.mkdir(parents=True, exist_ok=True)

    v65._reset()
    mpfb, HumanService = v65._services(ext)
    base = HumanService.create_human(
        mask_helpers=True,
        detailed_helpers=False,
        extra_vertex_groups=True,
        feet_on_ground=False,
        scale=0.1,
        macro_detail_dict=None,
    )
    if base is None or base.type != "MESH":
        raise RuntimeError("MPFB human creation failed")
    arm = HumanService.add_builtin_rig(base, "default", import_weights=True, operator=None)
    if arm is None or arm.type != "ARMATURE":
        raise RuntimeError("MPFB native GameEngine rig creation failed")

    vessel_center, vessel_radius, palm_center, longitudinal, span, palmar = v65._author_power_grasp(arm, -1.0)
    bpy.context.view_layer.update()
    segments = v64._selected_segments(arm)
    thumb_weights = v73._bone_weights(base)
    focus = palm_center.lerp(vessel_center, 0.55)
    cam = v65._scene_camera(focus, longitudinal, span, palmar, "B77")
    scene = bpy.context.scene

    # Reconstruct the exact v74 thumb seed. This must not touch digits 2-5.
    digit_before = {name: _flat(arm.pose.bones[name]) for name in EDIT_BONES}
    v76._reconstruct_v74(
        base, arm, scene, cam, vessel_center, vessel_radius, longitudinal, focus, thumb_weights
    )
    digit_after = {name: _flat(arm.pose.bones[name]) for name in EDIT_BONES}
    non_thumb_seed_delta = max(_max_delta(digit_before[n], digit_after[n]) for n in EDIT_BONES)

    # Measure the thumb AFTER v74 reconstruction. The first v77 infrastructure run accidentally
    # reported the pre-v74 baseline metric; that was a report/gate bug, not a scene/pose failure.
    thumb_metric_mesh = v73._static(base)
    thumb_seed_metrics = v73._metrics(
        scene, cam, thumb_metric_mesh, thumb_weights, vessel_center, vessel_radius, longitudinal, focus
    )
    bpy.data.objects.remove(thumb_metric_mesh, do_unlink=True)

    frozen_seed = {name: _flat(arm.pose.bones[name]) for name in FROZEN_BONES}
    seed_pose_path = out / "support-wrap-v77-authoring-seed-pose.json"
    v68._save_same_rig_pose(arm, seed_pose_path)

    vessel = v65._vessel(vessel_center, longitudinal, vessel_radius, "B77")
    vessel.name = "LOCKED_VESSEL_PROXY_V77"
    vessel["peel_calm_locked"] = True
    vessel["peel_calm_reference_set"] = "bar_v1,market_v1"
    arm.name = "PeelCalm_GameEngine_HeroRig_V77"
    arm.show_in_front = True
    arm["peel_calm_authoring_scene"] = "v77"
    arm["peel_calm_edit_bones"] = ",".join(EDIT_BONES)
    arm["peel_calm_frozen_bones"] = ",".join(FROZEN_BONES)
    arm["peel_calm_reference_set"] = "bar_v1,market_v1"
    arm["peel_calm_rule"] = "Direct artist posing only; no solver/sweep."

    guide = bpy.data.texts.get("PEEL_CALM_V77_AUTHORING_GUIDE") or bpy.data.texts.new(
        "PEEL_CALM_V77_AUTHORING_GUIDE"
    )
    guide.clear()
    guide.write(GUIDE)

    marker = bpy.data.objects.new("READ_PEEL_CALM_V77_AUTHORING_GUIDE", None)
    marker.empty_display_type = "PLAIN_AXES"
    marker.empty_display_size = 0.02
    marker.location = palm_center
    marker["guide_text_datablock"] = "PEEL_CALM_V77_AUTHORING_GUIDE"
    marker["locked_reference_set"] = "bar_v1,market_v1"
    scene.collection.objects.link(marker)

    # Render the unmodified v74 authoring baseline before switching to Pose Mode.
    baked = v73._static(base)
    v64b._adaptive_crop(baked, segments, palm_center)
    v65._skin(baked, "B77")
    base.hide_render = True
    arm.hide_render = True
    baked.hide_render = False
    vessel.hide_render = False
    v65._render(out / "authoring-seed-with-vessel.png", 640, 640)
    v65._render(out / "authoring-seed-thumbnail.png", 192, 108)
    vessel.hide_render = True
    v65._render(out / "authoring-seed-anatomy-oblique.png", 640, 640)
    vessel.hide_render = False
    baked.hide_viewport = True

    # Leave the saved .blend in Pose Mode with ONLY digits 2-5 selected.
    bpy.context.view_layer.objects.active = arm
    arm.hide_set(False)
    arm.hide_viewport = False
    arm.select_set(True)
    bpy.ops.object.mode_set(mode="POSE")
    for bone in arm.data.bones:
        bone.select = False
    for name in EDIT_BONES:
        arm.data.bones[name].select = True
    arm.data.bones.active = arm.data.bones["finger2-1.R"]

    blend_path = out / "peel-calm-support-grasp-authoring-v77.blend"
    bpy.ops.wm.save_as_mainfile(filepath=str(blend_path), check_existing=False)

    frozen_after = {name: _flat(arm.pose.bones[name]) for name in FROZEN_BONES}
    frozen_delta = max(_max_delta(frozen_seed[n], frozen_after[n]) for n in FROZEN_BONES)

    report = {
        "staging_only": True,
        "production_candidate": False,
        "authoring_infrastructure_only": True,
        "reference_set": ["bar_v1", "market_v1"],
        "base_pose": "exact reconstructed v74 on pristine v65-B",
        "native_gameengine_rig": True,
        "direct_pose_editing_expected": True,
        "parameter_sweep_used": False,
        "ccd_used": False,
        "endpoint_optimizer_used": False,
        "contact_servo_used": False,
        "root_orbit_motion_used": False,
        "pose_authoring_in_v77": False,
        "edit_bones": EDIT_BONES,
        "frozen_bones": FROZEN_BONES,
        "non_thumb_seed_matrix_max_abs_delta": non_thumb_seed_delta,
        "frozen_seed_matrix_max_abs_delta_after_scene_save": frozen_delta,
        "thumb_distal_outside_vessel_px": thumb_seed_metrics["bones"]["finger1-3.R"]["outside_vessel_px"],
        "blend_path": str(blend_path),
        "seed_pose_path": str(seed_pose_path),
        "guide_text_datablock": guide.name,
        "selected_pose_bone_count": len(EDIT_BONES),
        "mpfb_version": list(mpfb.VERSION),
        "next_gate": (
            "Open/regenerate this scene and directly pose the twelve selected non-thumb bones as one whole "
            "reference-derived silhouette. Do not script another angle sweep. An accepted pose must pass the "
            "192x108 vessel Macro gate and unobstructed oblique Meso anatomy gate before Godot integration."
        ),
    }
    report_path.write_text(json.dumps(report, indent=2, sort_keys=True), encoding="utf-8")
    print(json.dumps(report, indent=2, sort_keys=True))
    print(SUCCESS)


if __name__ == "__main__":
    try:
        run()
    except BaseException as exc:
        print("MPFB_ARTIST_AUTHORING_SCENE_V77_ERROR:", exc)
        traceback.print_exc()
        raise
