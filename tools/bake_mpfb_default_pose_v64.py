#!/usr/bin/env python3
"""v64: apply the CC0 MakeHuman holding pose on a sacrificial canonical MPFB rig and bake it.

Rationale
---------
v61-v63 show diminishing returns from translating finger rotations between skeletons. MPFB
ships a canonical ``default`` MakeHuman rig, while the official Poses 01 BVH uses canonical
MakeHuman bone names (wrist.R, finger1..5-*.R, lowerarm02.R). MPFB's documented BVH importer
copies source edit-bone roll destructively. That is unacceptable on a production GameEngine
rig, but safe on a throwaway default rig that is immediately discarded after deformation is
baked into mesh vertices.

This spike therefore:
1. creates a fresh MPFB human and canonical ``default`` rig;
2. applies the official CC0 holding-wine-glass BVH using MPFB's native importer;
3. evaluates/bakes the deformed human mesh to a new static mesh;
4. extracts only the right distal forearm / palm / digit region from the baked geometry;
5. discards the sacrificial rig and original full body;
6. renders the baked limb next to a simple upright vessel proxy and exports a static GLB.

The output is staging-only. It must pass the same Macro/Meso visual gate before any product
camera work. The baked asset contains no copied BVH rig, no altered production rig, and no
runtime finger solver.
"""
from __future__ import annotations

import importlib
import json
import math
import sys
import traceback
from pathlib import Path

import bpy
import bmesh
from mathutils import Vector

SUCCESS = "MPFB_BAKED_SOURCE_V64_SUCCESS"


def _args():
    if "--" not in sys.argv:
        raise RuntimeError("expected -- <extension-module> <source.bvh> <outdir> <output.glb> <report.json>")
    values = sys.argv[sys.argv.index("--") + 1:]
    if len(values) != 5:
        raise RuntimeError("expected five arguments")
    return values[0], Path(values[1]).resolve(), Path(values[2]).resolve(), Path(values[3]).resolve(), Path(values[4]).resolve()


def _reset():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)


def _load_services(extension_module: str):
    if not extension_module.startswith("bl_ext.") or not extension_module.endswith(".mpfb"):
        raise RuntimeError("MPFB extension namespace required")
    mpfb = importlib.import_module(extension_module)
    services = importlib.import_module(extension_module + ".services")
    animation_mod = importlib.import_module(extension_module + ".services.animationservice")
    HumanService = getattr(services, "HumanService")
    AnimationService = getattr(animation_mod, "AnimationService")
    return mpfb, HumanService, AnimationService


def _skin(mesh_obj):
    mat = bpy.data.materials.new("BakedSourceSkinV64")
    mat.use_nodes = True
    p = next((n for n in mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED"), None)
    if p:
        p.inputs["Base Color"].default_value = (0.47, 0.29, 0.21, 1.0)
        p.inputs["Roughness"].default_value = 0.58
    mesh_obj.data.materials.clear()
    mesh_obj.data.materials.append(mat)


def _wp(arm, bone_name: str, tail=False) -> Vector:
    pb = arm.pose.bones.get(bone_name)
    if pb is None:
        raise RuntimeError("sacrificial default rig missing " + bone_name)
    return arm.matrix_world @ (pb.tail if tail else pb.head)


def _selected_segments(arm):
    names = ["lowerarm02.R", "wrist.R"]
    for digit in range(1, 6):
        for joint in range(1, 4):
            names.append(f"finger{digit}-{joint}.R")
    segments = []
    for name in names:
        pb = arm.pose.bones.get(name)
        if pb is None:
            continue
        segments.append((name, _wp(arm, name), _wp(arm, name, True)))
    required = {"lowerarm02.R", "wrist.R", "finger1-1.R", "finger2-1.R", "finger5-3.R"}
    have = {name for name, _, _ in segments}
    missing = sorted(required - have)
    if missing:
        raise RuntimeError("canonical source rig missing required limb bones: " + str(missing))
    return segments


def _distance_to_segment(p: Vector, a: Vector, b: Vector) -> float:
    ab = b - a
    denom = ab.length_squared
    if denom < 1e-12:
        return (p - a).length
    t = max(0.0, min(1.0, (p - a).dot(ab) / denom))
    return (p - (a + ab * t)).length


def _bake_deformed_mesh(basemesh):
    depsgraph = bpy.context.evaluated_depsgraph_get()
    evaluated = basemesh.evaluated_get(depsgraph)
    baked_mesh = bpy.data.meshes.new_from_object(evaluated, preserve_all_data_layers=True, depsgraph=depsgraph)
    baked = bpy.data.objects.new("BakedHoldingLimbV64", baked_mesh)
    bpy.context.scene.collection.objects.link(baked)
    baked.matrix_world = basemesh.matrix_world.copy()
    return baked


def _crop_to_limb(baked, segments, palm_center_world: Vector):
    inv = baked.matrix_world.inverted()
    local_segments = [(name, inv @ a, inv @ b) for name, a, b in segments]
    palm_local = inv @ palm_center_world
    bm = bmesh.new()
    bm.from_mesh(baked.data)
    bm.verts.ensure_lookup_table()
    remove = []
    for v in bm.verts:
        # Palm sphere preserves the webbing/thenar region that is not represented by a
        # dedicated canonical palm bone. Segment tubes preserve forearm and digits.
        keep = (v.co - palm_local).length <= 0.043
        if not keep:
            for name, a, b in local_segments:
                radius = 0.034 if name in {"lowerarm02.R", "wrist.R"} else 0.0155
                if _distance_to_segment(v.co, a, b) <= radius:
                    keep = True
                    break
        if not keep:
            remove.append(v)
    bmesh.ops.delete(bm, geom=remove, context="VERTS")
    bm.to_mesh(baked.data)
    bm.free()
    baked.data.update()
    if len(baked.data.vertices) < 300:
        raise RuntimeError(f"v64 limb crop too small: {len(baked.data.vertices)} vertices")


def _proxy_material():
    mat = bpy.data.materials.new("BakedSourceVesselV64")
    mat.use_nodes = True
    p = next((n for n in mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED"), None)
    if p:
        p.inputs["Base Color"].default_value = (0.70, 0.86, 0.93, 1.0)
        p.inputs["Roughness"].default_value = 0.42
    return mat


def _make_vessel(center: Vector):
    bpy.ops.mesh.primitive_cylinder_add(vertices=64, radius=0.038, depth=0.20, location=center)
    obj = bpy.context.object
    obj.name = "BakedSourceV64Vessel"
    obj.data.materials.append(_proxy_material())
    return obj


def _look(cam, target):
    cam.rotation_euler = (target - cam.location).to_track_quat("-Z", "Y").to_euler()


def _setup_render(focus: Vector):
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE_NEXT"
    scene.render.image_settings.file_format = "PNG"
    scene.world.color = (0.025, 0.028, 0.035)
    cd = bpy.data.cameras.new("BakedSourceCameraV64")
    cam = bpy.data.objects.new("BakedSourceCameraV64", cd)
    scene.collection.objects.link(cam)
    scene.camera = cam
    cd.lens = 68
    cam.location = focus + Vector((-0.18, -0.28, 0.10))
    _look(cam, focus)
    kd = bpy.data.lights.new("BakedSourceKeyV64", "AREA"); kd.energy = 270; kd.size = 0.8
    key = bpy.data.objects.new("BakedSourceKeyV64", kd); key.location = focus + Vector((-0.35,-0.35,0.40)); scene.collection.objects.link(key)
    fd = bpy.data.lights.new("BakedSourceFillV64", "AREA"); fd.energy = 90; fd.size = 0.7
    fill = bpy.data.objects.new("BakedSourceFillV64", fd); fill.location = focus + Vector((0.15,0.10,0.25)); scene.collection.objects.link(fill)
    return cam


def _render(path: Path, width: int, height: int):
    scene = bpy.context.scene
    scene.render.resolution_x = width
    scene.render.resolution_y = height
    scene.render.resolution_percentage = 100
    scene.render.filepath = str(path)
    bpy.ops.render.render(write_still=True)
    if not path.is_file() or path.stat().st_size <= 0:
        raise RuntimeError("render failed: " + str(path))


def _export_static_glb(path: Path, baked):
    bpy.ops.object.select_all(action="DESELECT")
    baked.select_set(True)
    bpy.context.view_layer.objects.active = baked
    bpy.ops.export_scene.gltf(
        filepath=str(path),
        export_format="GLB",
        use_selection=True,
        export_skins=False,
        export_animations=False,
        export_morph=False,
        export_apply=True,
    )
    if not path.is_file() or path.stat().st_size <= 0:
        raise RuntimeError("static GLB export failed")


def run():
    extension_module, source_bvh, out, glb_path, report_path = _args()
    out.mkdir(parents=True, exist_ok=True)
    glb_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.parent.mkdir(parents=True, exist_ok=True)
    _reset()
    mpfb, HumanService, AnimationService = _load_services(extension_module)

    basemesh = HumanService.create_human(
        mask_helpers=True,
        detailed_helpers=False,
        extra_vertex_groups=True,
        feet_on_ground=False,
        scale=0.1,
        macro_detail_dict=None,
    )
    if basemesh is None or basemesh.type != "MESH":
        raise RuntimeError("MPFB human creation failed")
    arm = HumanService.add_builtin_rig(basemesh, "default", import_weights=True, operator=None)
    if arm is None or arm.type != "ARMATURE":
        raise RuntimeError("MPFB canonical default rig creation failed")

    # Explicitly allowed only because this entire rig is sacrificial and is deleted below.
    AnimationService.import_bvh_file_as_pose(arm, str(source_bvh))
    bpy.context.view_layer.update()
    segments = _selected_segments(arm)
    roots = [_wp(arm, f"finger{i}-1.R") for i in range(2, 6)]
    wrist = _wp(arm, "wrist.R")
    palm_center = (wrist + sum(roots, Vector())) / 5.0
    finger_tips = [_wp(arm, f"finger{i}-3.R", True) for i in range(2, 6)]
    mean_tips = sum(finger_tips, Vector()) / 4.0

    baked = _bake_deformed_mesh(basemesh)
    _crop_to_limb(baked, segments, palm_center)
    _skin(baked)

    # Product-like diagnostic proxy: vertical, bottle-radius cylinder placed between the
    # posed palm and finger tips. It does not change or solve the baked pose.
    vessel_center = palm_center.lerp(mean_tips, 0.48)
    vessel = _make_vessel(vessel_center)
    focus = palm_center.lerp(vessel_center, 0.55)

    # The sacrificial source body/rig are no longer needed. Deleting them proves the rendered
    # and exported evidence is a static baked mesh independent of the mutated source rig.
    bpy.data.objects.remove(basemesh, do_unlink=True)
    bpy.data.objects.remove(arm, do_unlink=True)

    cam = _setup_render(focus)
    full = out / "baked_source_v64_candidate.png"
    thumb = out / "baked_source_v64_thumbnail.png"
    _render(full, 640, 640)
    _render(thumb, 192, 108)
    _export_static_glb(glb_path, baked)

    report = {
        "staging_only": True,
        "production_candidate": False,
        "source_license": "CC0 (official MakeHuman Community Poses 01 pack)",
        "mpfb_version": list(mpfb.VERSION),
        "source_rig": "MPFB canonical default (sacrificial)",
        "source_bvh_applied_with_native_mpfb_import": True,
        "source_import_destructive_roll_copy": True,
        "destructive_roll_confined_to_sacrificial_rig": True,
        "sacrificial_rig_deleted_before_render_export": True,
        "production_gameengine_rig_touched": False,
        "pose_baked_static": True,
        "runtime_finger_solver_required": False,
        "baked_vertices": len(baked.data.vertices),
        "baked_polygons": len(baked.data.polygons),
        "output_glb": str(glb_path),
        "output_glb_bytes": glb_path.stat().st_size,
        "vessel_center": [float(x) for x in vessel_center],
        "visual_gate": "Thumbnail must read as a natural support wrap; full render must show continuous believable fingers/palm/wrist without cross-rig deformation artifacts.",
    }
    report_path.write_text(json.dumps(report, indent=2, sort_keys=True), encoding="utf-8")
    print(json.dumps(report, indent=2, sort_keys=True))
    print(SUCCESS)


if __name__ == "__main__":
    try:
        run()
    except BaseException as exc:
        print("MPFB_BAKED_SOURCE_V64_ERROR:", exc)
        traceback.print_exc()
        raise
