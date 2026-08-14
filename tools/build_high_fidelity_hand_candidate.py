"""Build a higher-density hand candidate in Blender without changing source GLBs.

Run with:
  blender --background --python tools/build_high_fidelity_hand_candidate.py -- \
    <input.glb> <output.glb> <report.json>

The candidate deliberately keeps the existing CC0 rig/animation source and only
changes render topology/normals. This is a reversible model-spike step: runtime
comparison decides whether the result is worth promoting.
"""

import json
import math
import os
import sys
from pathlib import Path

import bpy


def argv_after_double_dash():
    if "--" not in sys.argv:
        raise SystemExit("expected -- <input.glb> <output.glb> <report.json>")
    args = sys.argv[sys.argv.index("--") + 1 :]
    if len(args) != 3:
        raise SystemExit("expected exactly three arguments after --")
    return [Path(value).resolve() for value in args]


def reset_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for datablocks in (bpy.data.meshes, bpy.data.armatures, bpy.data.materials):
        # Remove only orphaned blocks left by the default scene/import retries.
        for block in list(datablocks):
            if block.users == 0:
                datablocks.remove(block)


def mesh_stats():
    vertices = 0
    polygons = 0
    objects = []
    for obj in bpy.context.scene.objects:
        if obj.type != "MESH" or obj.data is None:
            continue
        mesh = obj.data
        vertices += len(mesh.vertices)
        polygons += len(mesh.polygons)
        objects.append({
            "name": obj.name,
            "vertices": len(mesh.vertices),
            "polygons": len(mesh.polygons),
            "modifiers": [modifier.type for modifier in obj.modifiers],
        })
    return {"vertices": vertices, "polygons": polygons, "objects": objects}


def animation_names():
    names = set()
    for action in bpy.data.actions:
        if action.name:
            names.add(action.name)
    for obj in bpy.context.scene.objects:
        data = obj.animation_data
        if data is None:
            continue
        if data.action is not None and data.action.name:
            names.add(data.action.name)
        for track in data.nla_tracks:
            if track.name:
                names.add(track.name)
            for strip in track.strips:
                if strip.action is not None and strip.action.name:
                    names.add(strip.action.name)
    return sorted(names)


def armature_report():
    result = []
    for obj in bpy.context.scene.objects:
        if obj.type != "ARMATURE" or obj.data is None:
            continue
        result.append({"name": obj.name, "bones": len(obj.data.bones)})
    return result


def set_all_polygons_smooth(mesh):
    for polygon in mesh.polygons:
        polygon.use_smooth = True
    mesh.update()


def move_modifier_to_top(obj, modifier_name):
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    while obj.modifiers.find(modifier_name) > 0:
        bpy.ops.object.modifier_move_up(modifier=modifier_name)


def apply_subdivision(obj):
    # One Catmull-Clark level is intentionally conservative. It removes the
    # visible planar finger/knuckle facets at the close reference camera while
    # keeping CI/runtime size bounded and allowing vertex groups to interpolate.
    modifier = obj.modifiers.new(name="HeroHandSubdivision", type="SUBSURF")
    modifier.subdivision_type = "CATMULL_CLARK"
    modifier.levels = 1
    modifier.render_levels = 1
    modifier.show_only_control_edges = False
    move_modifier_to_top(obj, modifier.name)

    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.modifier_apply(modifier=modifier.name)
    set_all_polygons_smooth(obj.data)


def calibrate_materials():
    # Keep source textures and semantic material names intact. Only normalize
    # physically implausible extremes when the imported Principled node exposes
    # a compatible input. Godot remains responsible for venue lighting.
    for material in bpy.data.materials:
        if not material.use_nodes or material.node_tree is None:
            continue
        principled = next(
            (node for node in material.node_tree.nodes if node.type == "BSDF_PRINCIPLED"),
            None,
        )
        if principled is None:
            continue
        if material.name == "HandSkin":
            roughness = principled.inputs.get("Roughness")
            if roughness is not None and not roughness.is_linked:
                roughness.default_value = min(max(float(roughness.default_value), 0.48), 0.72)
        elif material.name == "HandNail":
            roughness = principled.inputs.get("Roughness")
            if roughness is not None and not roughness.is_linked:
                roughness.default_value = min(max(float(roughness.default_value), 0.30), 0.56)


def main():
    source_path, output_path, report_path = argv_after_double_dash()
    if not source_path.is_file():
        raise SystemExit(f"source GLB missing: {source_path}")

    output_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.parent.mkdir(parents=True, exist_ok=True)

    reset_scene()
    bpy.ops.import_scene.gltf(filepath=str(source_path))

    before = mesh_stats()
    animations_before = animation_names()
    armatures_before = armature_report()
    if before["vertices"] <= 0 or not armatures_before:
        raise RuntimeError("candidate source must contain renderable mesh and armature")

    for obj in list(bpy.context.scene.objects):
        if obj.type == "MESH" and obj.data is not None:
            apply_subdivision(obj)
    calibrate_materials()

    after = mesh_stats()
    animations_after = animation_names()
    armatures_after = armature_report()

    if after["vertices"] <= before["vertices"] * 1.8:
        raise RuntimeError(
            f"subdivision did not materially increase topology: {before['vertices']} -> {after['vertices']}"
        )
    if len(armatures_after) != len(armatures_before):
        raise RuntimeError("armature count changed during candidate build")

    # Keep animations/skins. We do not apply armature deformation; only the
    # render mesh was subdivided in bind space, so the rig remains live.
    bpy.ops.export_scene.gltf(
        filepath=str(output_path),
        export_format="GLB",
        export_animations=True,
        export_skins=True,
        export_morph=True,
        export_apply=False,
    )

    if not output_path.is_file() or output_path.stat().st_size <= 0:
        raise RuntimeError("GLB export produced no candidate")

    report = {
        "source": str(source_path),
        "output": str(output_path),
        "blender_version": bpy.app.version_string,
        "before": before,
        "after": after,
        "armatures_before": armatures_before,
        "armatures_after": armatures_after,
        "animations_before": animations_before,
        "animations_after": animations_after,
        "output_bytes": output_path.stat().st_size,
    }
    report_path.write_text(json.dumps(report, indent=2), encoding="utf-8")
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    main()
