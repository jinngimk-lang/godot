"""Build a rig-preserving hero hand + forearm candidate in Blender.

Run with:
  blender --background --python tools/build_high_fidelity_hand_candidate.py -- \
    <input.glb> <output.glb> <report.json>

The source Godot XR Tools hands are CC0 and already provide a working 26-bone
rig plus a large authored pose library. This spike keeps that proven rig,
subdivides the hand render mesh, and adds an armature-skinned anatomical
forearm plus a café sleeve in the same GLB. Runtime comparison decides whether
this structural candidate is worth promoting; the script never rewrites source
assets in the repository checkout.
"""

import json
import math
import sys
from pathlib import Path

import bpy

FOREARM_RINGS = 28
FOREARM_SIDES = 36
FOREARM_START_Z = 0.020
FOREARM_END_Z = 0.655


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
        for block in list(datablocks):
            if block.users == 0:
                datablocks.remove(block)


def mesh_bounds(obj):
    if obj.type != "MESH" or obj.data is None or not obj.data.vertices:
        return None
    xs = [v.co.x for v in obj.data.vertices]
    ys = [v.co.y for v in obj.data.vertices]
    zs = [v.co.z for v in obj.data.vertices]
    return {
        "min": [min(xs), min(ys), min(zs)],
        "max": [max(xs), max(ys), max(zs)],
    }


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
            "bounds": mesh_bounds(obj),
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


def armature_objects():
    return [obj for obj in bpy.context.scene.objects if obj.type == "ARMATURE" and obj.data is not None]


def armature_report():
    return [{"name": obj.name, "bones": len(obj.data.bones)} for obj in armature_objects()]


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
    # Only the existing imported meshes are subdivided. Generated forearm/sleeve
    # topology already has enough radial/ring density and should remain bounded.
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


def find_primary_skinned_mesh():
    candidates = []
    for obj in bpy.context.scene.objects:
        if obj.type != "MESH" or obj.data is None:
            continue
        has_armature = any(mod.type == "ARMATURE" for mod in obj.modifiers)
        if has_armature:
            candidates.append(obj)
    if not candidates:
        raise RuntimeError("source contains no armature-skinned mesh")
    return max(candidates, key=lambda obj: len(obj.data.vertices))


def find_material(name):
    for material in bpy.data.materials:
        if material.name == name:
            return material
    return None


def make_sleeve_material():
    material = find_material("SleeveFabric")
    if material is not None:
        return material
    material = bpy.data.materials.new("SleeveFabric")
    material.use_nodes = True
    material.diffuse_color = (0.055, 0.052, 0.050, 1.0)
    principled = next(
        (node for node in material.node_tree.nodes if node.type == "BSDF_PRINCIPLED"),
        None,
    )
    if principled is not None:
        base = principled.inputs.get("Base Color")
        if base is not None:
            base.default_value = (0.055, 0.052, 0.050, 1.0)
        roughness = principled.inputs.get("Roughness")
        if roughness is not None:
            roughness.default_value = 0.93
    return material


def radius_profile(t):
    # Anatomical read rather than a constant tube: narrow wrist, gradual flexor
    # mass, broadest around the proximal forearm, then a subtle elbow taper.
    keys = [
        (0.00, 0.036, 0.028),
        (0.08, 0.041, 0.032),
        (0.22, 0.052, 0.039),
        (0.48, 0.069, 0.049),
        (0.72, 0.077, 0.055),
        (1.00, 0.073, 0.053),
    ]
    for index in range(len(keys) - 1):
        a = keys[index]
        b = keys[index + 1]
        if t <= b[0]:
            span = max(b[0] - a[0], 1e-6)
            w = (t - a[0]) / span
            smooth = w * w * (3.0 - 2.0 * w)
            return (
                a[1] + (b[1] - a[1]) * smooth,
                a[2] + (b[2] - a[2]) * smooth,
            )
    return keys[-1][1], keys[-1][2]


def build_tapered_limb_mesh(name, sleeve=False):
    rings = FOREARM_RINGS - (4 if sleeve else 0)
    sides = FOREARM_SIDES
    start_z = 0.025 if sleeve else FOREARM_START_Z
    end_z = 0.675 if sleeve else FOREARM_END_Z
    vertices = []
    faces = []

    for ring_index in range(rings):
        t = ring_index / float(rings - 1)
        z = start_z + (end_z - start_z) * t
        rx, ry = radius_profile(t)
        # Small asymmetric center line avoids the lathed-pipe read. The bend is
        # intentionally subtle because HandVisual root rotation supplies the
        # large screen-space arm direction.
        center_x = 0.006 * math.sin(math.pi * t)
        center_y = -0.010 * math.sin(math.pi * t) - 0.004 * t
        if sleeve:
            rx += 0.007 + 0.004 * t
            ry += 0.006 + 0.003 * t
            if t < 0.10:
                cuff = (0.10 - t) / 0.10
                rx += 0.005 * cuff
                ry += 0.004 * cuff
        for side_index in range(sides):
            angle = 2.0 * math.pi * side_index / float(sides)
            # Mild second harmonic gives a less perfect ellipse without noisy
            # low-poly lumps.
            anatomy = 1.0 + 0.018 * math.cos(angle * 2.0 + t * 1.5)
            vertices.append((
                center_x + math.cos(angle) * rx * anatomy,
                center_y + math.sin(angle) * ry * anatomy,
                z,
            ))

    for ring_index in range(rings - 1):
        current = ring_index * sides
        nxt = (ring_index + 1) * sides
        for side_index in range(sides):
            side_next = (side_index + 1) % sides
            a = current + side_index
            b = current + side_next
            c = nxt + side_next
            d = nxt + side_index
            faces.append((a, d, c, b))

    # Far cap only; the wrist intentionally stays open and overlaps the source
    # hand wrist surface so no visible disc can appear at the tactile seam.
    far_center = len(vertices)
    vertices.append((0.006 * math.sin(math.pi), -0.014, end_z))
    last = (rings - 1) * sides
    for side_index in range(sides):
        side_next = (side_index + 1) % sides
        faces.append((far_center, last + side_index, last + side_next))

    mesh = bpy.data.meshes.new(name + "Data")
    mesh.from_pydata(vertices, [], faces)
    mesh.update()
    set_all_polygons_smooth(mesh)
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    return obj


def mirror_parenting_and_rig(obj, primary, armature, wrist_bone_name):
    obj.parent = primary.parent
    obj.matrix_parent_inverse = primary.matrix_parent_inverse.copy()
    obj.matrix_basis = primary.matrix_basis.copy()

    group = obj.vertex_groups.new(name=wrist_bone_name)
    group.add(list(range(len(obj.data.vertices))), 1.0, "REPLACE")
    modifier = obj.modifiers.new(name="Armature", type="ARMATURE")
    modifier.object = armature


def add_integrated_forearm(source_path):
    armatures = armature_objects()
    if len(armatures) != 1:
        raise RuntimeError(f"expected one hand armature, got {len(armatures)}")
    armature = armatures[0]
    primary = find_primary_skinned_mesh()

    suffix = "L" if "left" in source_path.name.lower() else "R"
    wrist_name = f"Wrist_{suffix}"
    if armature.data.bones.get(wrist_name) is None:
        matches = [bone.name for bone in armature.data.bones if bone.name.lower().startswith("wrist")]
        if len(matches) != 1:
            raise RuntimeError(f"cannot resolve wrist bone for {source_path.name}: {matches}")
        wrist_name = matches[0]

    skin = find_material("HandSkin")
    if skin is None:
        raise RuntimeError("source candidate is missing HandSkin material")

    forearm = build_tapered_limb_mesh("IntegratedForearmMesh", sleeve=False)
    forearm.data.materials.append(skin)
    mirror_parenting_and_rig(forearm, primary, armature, wrist_name)

    sleeve = build_tapered_limb_mesh("IntegratedSleeveMesh", sleeve=True)
    sleeve.data.materials.append(make_sleeve_material())
    mirror_parenting_and_rig(sleeve, primary, armature, wrist_name)

    return {
        "wrist_bone": wrist_name,
        "forearm_vertices": len(forearm.data.vertices),
        "forearm_polygons": len(forearm.data.polygons),
        "sleeve_vertices": len(sleeve.data.vertices),
        "sleeve_polygons": len(sleeve.data.polygons),
        "forearm_bounds": mesh_bounds(forearm),
        "sleeve_bounds": mesh_bounds(sleeve),
    }


def calibrate_materials():
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
                roughness.default_value = min(max(float(roughness.default_value), 0.50), 0.70)
        elif material.name == "HandNail":
            roughness = principled.inputs.get("Roughness")
            if roughness is not None and not roughness.is_linked:
                roughness.default_value = min(max(float(roughness.default_value), 0.32), 0.55)


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

    imported_meshes = [
        obj for obj in list(bpy.context.scene.objects)
        if obj.type == "MESH" and obj.data is not None
    ]
    for obj in imported_meshes:
        apply_subdivision(obj)

    integrated = add_integrated_forearm(source_path)
    calibrate_materials()

    after = mesh_stats()
    animations_after = animation_names()
    armatures_after = armature_report()

    if after["vertices"] <= before["vertices"] * 1.8:
        raise RuntimeError(
            f"candidate did not materially increase topology: {before['vertices']} -> {after['vertices']}"
        )
    if len(armatures_after) != len(armatures_before):
        raise RuntimeError("armature count changed during candidate build")
    if not any(obj["name"] == "IntegratedForearmMesh" for obj in after["objects"]):
        raise RuntimeError("integrated forearm was not created")
    if not any(obj["name"] == "IntegratedSleeveMesh" for obj in after["objects"]):
        raise RuntimeError("integrated café sleeve was not created")

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
        "integrated_limb": integrated,
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
