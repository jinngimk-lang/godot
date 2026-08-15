#!/usr/bin/env python3
"""v57: keep the MakeHuman holding-object pose on its native/default MPFB rig and bake it.

This is a category change after v54-v56 showed that translating holding-object anatomy into the
GameEngine hand rig destroys the grasp silhouette. MPFB's current AnimationService deliberately
loads MakeHuman BVH poses by replacing destination bone rolls. That is unacceptable for the
production GameEngine rig, but useful on a sacrificial Default rig whose only job is to produce a
visually correct posed hero limb. We therefore:

1. build a fresh MPFB human with the Default rig;
2. destructively load the official CC0 holding-wine-glass BVH on that sacrificial rig;
3. frame/render the right hand in the native pose;
4. bake the current pose as the rig's new rest pose using MPFB's own service;
5. render again and export the baked rig+mesh as a staging GLB.

No BVH transforms are ever copied into the GameEngine rig. No solver, endpoint target, joint-axis
search, candidate sweep, or production integration is performed here. Visual evidence is binding.
"""
from __future__ import annotations

import importlib
import json
import math
import sys
import traceback
from pathlib import Path

import bpy
from mathutils import Vector

SUCCESS = "MPFB_NATIVE_POSE_BAKE_V57_SUCCESS"
ERROR = "MPFB_NATIVE_POSE_BAKE_V57_ERROR"


def _args():
    if "--" not in sys.argv:
        raise RuntimeError("expected -- <extension-module> <pose.bvh> <previews-dir> <output.glb> <report.json>")
    values = sys.argv[sys.argv.index("--") + 1:]
    if len(values) != 5:
        raise RuntimeError("expected exactly five arguments after --")
    return values[0], Path(values[1]).resolve(), Path(values[2]).resolve(), Path(values[3]).resolve(), Path(values[4]).resolve()


def _reset():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for collection in (bpy.data.meshes, bpy.data.armatures, bpy.data.materials, bpy.data.cameras, bpy.data.lights):
        for block in list(collection):
            if block.users == 0:
                collection.remove(block)


def _load_mpfb(extension_module: str):
    if not extension_module.startswith("bl_ext.") or not extension_module.endswith(".mpfb"):
        raise RuntimeError(f"unexpected MPFB extension namespace: {extension_module}")
    mpfb = importlib.import_module(extension_module)
    services = importlib.import_module(extension_module + ".services")
    HumanService = getattr(services, "HumanService")
    AnimationService = getattr(services, "AnimationService")
    RigService = getattr(services, "RigService")
    if extension_module not in bpy.context.preferences.addons:
        raise RuntimeError("MPFB extension is not enabled")
    return mpfb, HumanService, AnimationService, RigService


def _skin_material():
    mat = bpy.data.materials.new("NativePoseSkin")
    mat.use_nodes = True
    mat.diffuse_color = (0.46, 0.29, 0.21, 1.0)
    principled = next((n for n in mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED"), None)
    if principled:
        if principled.inputs.get("Base Color"):
            principled.inputs["Base Color"].default_value = (0.46, 0.29, 0.21, 1.0)
        if principled.inputs.get("Roughness"):
            principled.inputs["Roughness"].default_value = 0.57
        if principled.inputs.get("IOR"):
            principled.inputs["IOR"].default_value = 1.42
    return mat


def _right_hand_bones(arm):
    names = []
    for pb in arm.pose.bones:
        low = pb.name.lower()
        right = low.endswith(".r") or low.endswith("_r") or low.startswith("r") or "right" in low
        handish = any(token in low for token in ("hand", "wrist", "finger", "thumb", "index", "middle", "ring", "pinky"))
        if right and handish:
            names.append(pb.name)
    # Default MakeHuman rigs commonly use finger1-1.R style names. If naming detection becomes
    # too strict, keep any right-side distal hand descendants as a diagnostics fallback.
    if len(names) < 8:
        for pb in arm.pose.bones:
            low = pb.name.lower()
            if (low.endswith(".r") or low.endswith("_r")) and any(t in low for t in ("finger", "hand")):
                if pb.name not in names:
                    names.append(pb.name)
    return names


def _world_points(arm, bone_names):
    pts = []
    for name in bone_names:
        pb = arm.pose.bones.get(name)
        if pb is None:
            continue
        pts.append(arm.matrix_world @ pb.head)
        pts.append(arm.matrix_world @ pb.tail)
    return pts


def _distal_tips(arm, bone_names):
    chosen = []
    for name in bone_names:
        pb = arm.pose.bones.get(name)
        if pb is None:
            continue
        low = name.lower()
        if "finger" not in low and not any(t in low for t in ("thumb", "index", "middle", "ring", "pinky")):
            continue
        hand_children = [c for c in pb.children if c.name in bone_names]
        if not hand_children:
            chosen.append(arm.matrix_world @ pb.tail)
    return chosen


def _look_at(obj, target: Vector):
    direction = target - obj.location
    obj.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()


def _setup_scene(arm, basemesh):
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE_NEXT"
    scene.render.image_settings.file_format = "PNG"
    scene.render.film_transparent = False
    scene.render.resolution_percentage = 100
    scene.world.color = (0.035, 0.035, 0.045)

    basemesh.data.materials.clear()
    basemesh.data.materials.append(_skin_material())

    names = _right_hand_bones(arm)
    points = _world_points(arm, names)
    if len(points) < 8:
        raise RuntimeError(f"could not identify enough right-hand bones on Default rig: {names}")
    center = sum(points, Vector()) / len(points)
    extent = max((p - center).length for p in points)
    extent = max(extent, 0.06)

    tips = _distal_tips(arm, names)
    grasp_center = sum(tips, Vector()) / len(tips) if tips else center + Vector((0.0, 0.0, 0.02))

    # The reference is a wine-glass holding pose, so a slim upright neutral vessel is an honest
    # diagnostic prop. Its location comes only from the posed fingertip cloud; it does not author
    # or solve the pose itself.
    bpy.ops.mesh.primitive_cylinder_add(vertices=64, radius=extent * 0.28, depth=extent * 2.5, location=grasp_center)
    vessel = bpy.context.object
    vessel.name = "NativePoseV57DiagnosticVessel"
    vm = bpy.data.materials.new("NativePoseVessel")
    vm.use_nodes = True
    vm.diffuse_color = (0.55, 0.75, 0.88, 0.68)
    p = next((n for n in vm.node_tree.nodes if n.type == "BSDF_PRINCIPLED"), None)
    if p:
        if p.inputs.get("Base Color"):
            p.inputs["Base Color"].default_value = (0.55, 0.75, 0.88, 1.0)
        if p.inputs.get("Roughness"):
            p.inputs["Roughness"].default_value = 0.38
    vessel.data.materials.append(vm)

    cam_data = bpy.data.cameras.new("NativePoseV57Camera")
    cam = bpy.data.objects.new("NativePoseV57Camera", cam_data)
    bpy.context.collection.objects.link(cam)
    # Camera offset is scaled to the hand extent; the diagonal view exposes palm, thumb opposition,
    # and whether fingers pass around the far contour rather than hiding failure in a side view.
    cam.location = center + Vector((extent * 2.8, -extent * 4.1, extent * 1.8))
    cam_data.lens = 70.0
    _look_at(cam, center.lerp(grasp_center, 0.35))
    scene.camera = cam

    key_data = bpy.data.lights.new("NativePoseV57Key", type="AREA")
    key_data.energy = 750.0
    key_data.shape = "DISK"
    key_data.size = extent * 4.5
    key = bpy.data.objects.new("NativePoseV57Key", key_data)
    bpy.context.collection.objects.link(key)
    key.location = center + Vector((extent * 2.5, -extent * 2.0, extent * 3.0))
    _look_at(key, center)

    fill_data = bpy.data.lights.new("NativePoseV57Fill", type="AREA")
    fill_data.energy = 350.0
    fill_data.size = extent * 3.5
    fill = bpy.data.objects.new("NativePoseV57Fill", fill_data)
    bpy.context.collection.objects.link(fill)
    fill.location = center + Vector((-extent * 2.5, -extent, extent))
    _look_at(fill, center)

    return cam, vessel, names, center, grasp_center, extent


def _render(path: Path, width: int, height: int):
    scene = bpy.context.scene
    scene.render.resolution_x = width
    scene.render.resolution_y = height
    scene.render.resolution_percentage = 100
    scene.render.filepath = str(path)
    bpy.ops.render.render(write_still=True)
    if not path.is_file() or path.stat().st_size == 0:
        raise RuntimeError(f"render failed: {path}")


def _export(output_path: Path, basemesh, armature):
    bpy.ops.object.select_all(action="DESELECT")
    basemesh.select_set(True)
    armature.select_set(True)
    bpy.context.view_layer.objects.active = armature
    bpy.ops.export_scene.gltf(
        filepath=str(output_path),
        export_format="GLB",
        use_selection=True,
        export_skins=True,
        export_animations=False,
        export_morph=False,
        export_apply=False,
    )
    if not output_path.is_file() or output_path.stat().st_size == 0:
        raise RuntimeError("baked native-pose GLB export failed")


def run():
    extension_module, bvh_path, previews, output_path, report_path = _args()
    previews.mkdir(parents=True, exist_ok=True)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.parent.mkdir(parents=True, exist_ok=True)
    _reset()
    mpfb, HumanService, AnimationService, RigService = _load_mpfb(extension_module)

    basemesh = HumanService.create_human(
        mask_helpers=True,
        detailed_helpers=False,
        extra_vertex_groups=True,
        feet_on_ground=False,
        scale=0.1,
        macro_detail_dict=None,
    )
    if basemesh is None or basemesh.type != "MESH":
        raise RuntimeError("MPFB did not create basemesh")
    arm = HumanService.add_builtin_rig(basemesh, "default", import_weights=True, operator=None)
    if arm is None or arm.type != "ARMATURE":
        raise RuntimeError("MPFB did not create Default armature")
    rig_before = RigService.identify_rig(arm)

    # This is intentionally destructive, but only on this disposable Default rig. Current MPFB
    # itself documents that it changes destination bone rolls to make MakeHuman BVH rotations
    # behave natively. The production GameEngine rig is never passed to this service.
    AnimationService.import_bvh_file_as_pose(arm, str(bvh_path))
    bpy.context.view_layer.update()
    cam, vessel, hand_bones, center, grasp_center, extent = _setup_scene(arm, basemesh)
    _render(previews / "native_pose_v57_before_bake.png", 640, 640)
    _render(previews / "native_pose_v57_before_bake_thumbnail.png", 192, 108)

    RigService.apply_pose_as_rest_pose(arm)
    bpy.context.view_layer.update()
    rig_after = RigService.identify_rig(arm)
    _render(previews / "native_pose_v57_after_bake.png", 640, 640)
    _render(previews / "native_pose_v57_after_bake_thumbnail.png", 192, 108)
    _export(output_path, basemesh, arm)

    report = {
        "staging_only": True,
        "production_candidate": False,
        "route": "native-default-rig-destructive-bvh-then-rest-pose-bake",
        "source_pose": bvh_path.name,
        "source_license": "CC0 (MakeHuman Poses 01 pack)",
        "gameengine_rig_modified": False,
        "default_rig_intentionally_destructive": True,
        "rig_identified_before": rig_before,
        "rig_identified_after": rig_after,
        "hand_bone_count": len(hand_bones),
        "hand_bones": hand_bones,
        "hand_center": list(center),
        "diagnostic_grasp_center": list(grasp_center),
        "hand_extent": extent,
        "mesh_vertices": len(basemesh.data.vertices),
        "mesh_polygons": len(basemesh.data.polygons),
        "armature_bone_count": len(arm.data.bones),
        "output_glb": str(output_path),
        "output_bytes": output_path.stat().st_size,
        "visual_gate": "Before-bake and after-bake 192x108 frames must both immediately read as the same coherent human object-holding hand; bake must not destroy the pose. Only then may the baked asset proceed to Godot staging.",
        "generator": {
            "mpfb_version": list(mpfb.VERSION),
            "mpfb_build_info": mpfb.BUILD_INFO,
            "blender": bpy.app.version_string,
        },
    }
    report_path.write_text(json.dumps(report, indent=2, sort_keys=True), encoding="utf-8")
    print(json.dumps(report, indent=2, sort_keys=True))
    print(SUCCESS)


if __name__ == "__main__":
    try:
        run()
    except BaseException as exc:
        print(ERROR + ":", exc)
        traceback.print_exc()
        raise
