#!/usr/bin/env python3
"""Render the exported v57 baked GLB with no diagnostic vessel.

The first v57 prop view proved the native-pose+bake pipeline works, but the automatically sized
opaque vessel obscured the fingers. This second pass changes no pose or asset data: it imports the
already-exported GLB and frames only the right hand/wrist so the Macro/Meso silhouette can be
judged fairly.
"""
from __future__ import annotations

import sys
import traceback
from pathlib import Path

import bpy
from mathutils import Vector

SUCCESS = "MPFB_BAKED_HAND_ONLY_V57_SUCCESS"


def _args():
    if "--" not in sys.argv:
        raise RuntimeError("expected -- <baked.glb> <previews-dir>")
    vals = sys.argv[sys.argv.index("--") + 1:]
    if len(vals) != 2:
        raise RuntimeError("expected two arguments")
    return Path(vals[0]).resolve(), Path(vals[1]).resolve()


def _reset():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)


def _look_at(obj, target):
    obj.rotation_euler = (target - obj.location).to_track_quat("-Z", "Y").to_euler()


def _hand_bones(arm):
    names = []
    for pb in arm.pose.bones:
        low = pb.name.lower()
        right = low.endswith(".r") or low.endswith("_r") or "right" in low
        handish = any(t in low for t in ("hand", "wrist", "finger", "thumb", "index", "middle", "ring", "pinky"))
        if right and handish:
            names.append(pb.name)
    return names


def _render(path, w, h):
    s = bpy.context.scene
    s.render.resolution_x = w
    s.render.resolution_y = h
    s.render.resolution_percentage = 100
    s.render.filepath = str(path)
    bpy.ops.render.render(write_still=True)
    if not path.is_file() or path.stat().st_size == 0:
        raise RuntimeError("render failed: " + str(path))


def run():
    glb, out = _args()
    out.mkdir(parents=True, exist_ok=True)
    _reset()
    bpy.ops.import_scene.gltf(filepath=str(glb))
    arms = [o for o in bpy.context.scene.objects if o.type == "ARMATURE"]
    meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
    if len(arms) != 1 or not meshes:
        raise RuntimeError(f"expected one armature and mesh, got {len(arms)} / {len(meshes)}")
    arm = arms[0]
    names = _hand_bones(arm)
    if len(names) < 8:
        raise RuntimeError("could not identify baked right hand bones: " + repr(names))
    points = []
    for n in names:
        pb = arm.pose.bones[n]
        points.extend((arm.matrix_world @ pb.head, arm.matrix_world @ pb.tail))
    center = sum(points, Vector()) / len(points)
    extent = max((p - center).length for p in points)
    extent = max(extent, 0.06)

    # Hide any non-human diagnostic meshes if a future export includes them; current v57 selects
    # only basemesh+armature, so this is defensive.
    for m in meshes:
        if "Vessel" in m.name:
            m.hide_render = True

    s = bpy.context.scene
    s.render.engine = "BLENDER_EEVEE_NEXT"
    s.render.image_settings.file_format = "PNG"
    s.world.color = (0.035, 0.035, 0.045)

    camd = bpy.data.cameras.new("BakedHandOnlyCamera")
    cam = bpy.data.objects.new("BakedHandOnlyCamera", camd)
    bpy.context.collection.objects.link(cam)
    cam.location = center + Vector((extent * 2.7, -extent * 4.2, extent * 1.65))
    camd.lens = 72.0
    _look_at(cam, center)
    s.camera = cam

    kd = bpy.data.lights.new("BakedHandOnlyKey", "AREA")
    kd.energy = 650
    kd.size = extent * 4.0
    key = bpy.data.objects.new("BakedHandOnlyKey", kd)
    bpy.context.collection.objects.link(key)
    key.location = center + Vector((extent * 2.4, -extent * 2.0, extent * 2.8))
    _look_at(key, center)

    fd = bpy.data.lights.new("BakedHandOnlyFill", "AREA")
    fd.energy = 250
    fd.size = extent * 3.0
    fill = bpy.data.objects.new("BakedHandOnlyFill", fd)
    bpy.context.collection.objects.link(fill)
    fill.location = center + Vector((-extent * 2.0, -extent * 1.0, extent * 0.8))
    _look_at(fill, center)

    _render(out / "native_pose_v57_baked_hand_only.png", 640, 640)
    _render(out / "native_pose_v57_baked_hand_only_thumbnail.png", 192, 108)
    print("BAKED_HAND_ONLY_BONES", names)
    print(SUCCESS)


if __name__ == "__main__":
    try:
        run()
    except BaseException as exc:
        print("MPFB_BAKED_HAND_ONLY_V57_ERROR:", exc)
        traceback.print_exc()
        raise
