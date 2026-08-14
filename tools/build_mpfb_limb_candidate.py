"""Build and inspect an MPFB-derived hero-limb source candidate.

MPFB 2.x is a Blender Extension. This script must run after the pinned MPFB
package has been installed/enabled in an isolated local extension repository.
It never imports MPFB as a bare top-level package, because Blender 4.2 extension
storage/preferences rely on the repository-qualified ``bl_ext`` namespace.

Usage:
  blender --background --python tools/build_mpfb_limb_candidate.py -- \
    <extension-module> <output.glb> <report.json>

Example extension-module: ``bl_ext.mpfb_ci.mpfb``
"""

from __future__ import annotations

import importlib
import json
import sys
import traceback
from pathlib import Path

import bpy
from mathutils import Vector

SUCCESS_MARKER = "MPFB_LIMB_BUILD_SUCCESS"
ERROR_MARKER = "MPFB_LIMB_BUILD_ERROR"


def _args() -> tuple[str, Path, Path]:
    if "--" not in sys.argv:
        raise RuntimeError("expected -- <extension-module> <output.glb> <report.json>")
    values = sys.argv[sys.argv.index("--") + 1 :]
    if len(values) != 3:
        raise RuntimeError("expected exactly three arguments after --")
    return values[0], Path(values[1]).resolve(), Path(values[2]).resolve()


def _reset_scene() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for collection in (bpy.data.meshes, bpy.data.armatures, bpy.data.materials):
        for block in list(collection):
            if block.users == 0:
                collection.remove(block)


def _load_mpfb(extension_module: str):
    if not extension_module.startswith("bl_ext.") or not extension_module.endswith(".mpfb"):
        raise RuntimeError(f"MPFB must be loaded as Blender Extension namespace, got {extension_module}")
    mpfb = importlib.import_module(extension_module)
    services = importlib.import_module(extension_module + ".services")
    HumanService = getattr(services, "HumanService", None)
    if HumanService is None:
        raise RuntimeError("installed MPFB extension does not expose HumanService")
    if extension_module not in bpy.context.preferences.addons:
        raise RuntimeError(f"MPFB extension is not enabled in preferences: {extension_module}")
    return mpfb, HumanService


def _mesh_stats(obj: bpy.types.Object) -> dict:
    mesh = obj.data
    if obj.type != "MESH" or mesh is None:
        return {}
    # Blender exposes bound_box corners as bpy_prop_array values. Convert each
    # corner to mathutils.Vector before world-space matrix multiplication so the
    # diagnostic path works consistently in headless Blender 4.2.
    bounds = [obj.matrix_world @ Vector(corner) for corner in obj.bound_box]
    xs = [point.x for point in bounds]
    ys = [point.y for point in bounds]
    zs = [point.z for point in bounds]
    groups = []
    for group in obj.vertex_groups:
        weighted = 0
        max_weight = 0.0
        for vertex in mesh.vertices:
            try:
                weight = group.weight(vertex.index)
            except RuntimeError:
                continue
            if weight > 0.0001:
                weighted += 1
                max_weight = max(max_weight, weight)
        groups.append({
            "name": group.name,
            "weighted_vertices": weighted,
            "max_weight": round(max_weight, 6),
        })
    return {
        "name": obj.name,
        "vertices": len(mesh.vertices),
        "polygons": len(mesh.polygons),
        "materials": [slot.material.name if slot.material else "" for slot in obj.material_slots],
        "bounds_world": {
            "min": [min(xs), min(ys), min(zs)],
            "max": [max(xs), max(ys), max(zs)],
        },
        "vertex_groups": groups,
    }


def _armature_stats(obj: bpy.types.Object) -> dict:
    bones = []
    for bone in obj.data.bones:
        bones.append({
            "name": bone.name,
            "parent": bone.parent.name if bone.parent else None,
            "head_local": list(bone.head_local),
            "tail_local": list(bone.tail_local),
        })
    return {"name": obj.name, "bones": bones, "bone_count": len(bones)}


def _apply_simple_game_skin(basemesh: bpy.types.Object) -> None:
    material = bpy.data.materials.new("HandSkinCandidate")
    material.use_nodes = True
    material.diffuse_color = (0.47, 0.29, 0.21, 1.0)
    principled = next(
        (node for node in material.node_tree.nodes if node.type == "BSDF_PRINCIPLED"), None
    )
    if principled is not None:
        if principled.inputs.get("Base Color"):
            principled.inputs["Base Color"].default_value = (0.47, 0.29, 0.21, 1.0)
        if principled.inputs.get("Roughness"):
            principled.inputs["Roughness"].default_value = 0.58
    basemesh.data.materials.clear()
    basemesh.data.materials.append(material)


def _export_glb(output_path: Path, basemesh: bpy.types.Object, armature: bpy.types.Object) -> None:
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


def _run() -> None:
    extension_module, output_path, report_path = _args()
    output_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.parent.mkdir(parents=True, exist_ok=True)
    _reset_scene()
    mpfb, HumanService = _load_mpfb(extension_module)

    basemesh = HumanService.create_human(
        mask_helpers=True,
        detailed_helpers=False,
        extra_vertex_groups=True,
        feet_on_ground=False,
        scale=0.1,
        macro_detail_dict=None,
    )
    if basemesh is None or basemesh.type != "MESH":
        raise RuntimeError("MPFB did not create a basemesh")

    armature = HumanService.add_builtin_rig(
        basemesh, "game_engine", import_weights=True, operator=None
    )
    if armature is None or armature.type != "ARMATURE":
        raise RuntimeError("MPFB did not create GameEngine armature")

    _apply_simple_game_skin(basemesh)
    mesh_report = _mesh_stats(basemesh)
    rig_report = _armature_stats(armature)
    tokens = (
        "hand", "forearm", "upperarm", "arm", "wrist", "thumb",
        "index", "middle", "ring", "pinky", "finger", "lowerarm",
    )
    interesting_groups = [
        group for group in mesh_report.get("vertex_groups", [])
        if any(token in group["name"].lower() for token in tokens)
    ]
    interesting_bones = [
        bone for bone in rig_report["bones"]
        if any(token in bone["name"].lower() for token in tokens)
    ]

    _export_glb(output_path, basemesh, armature)
    if not output_path.is_file() or output_path.stat().st_size <= 0:
        raise RuntimeError("MPFB candidate GLB export failed")

    report = {
        "generator": {
            "mpfb_version": list(mpfb.VERSION),
            "mpfb_build_info": mpfb.BUILD_INFO,
            "blender_version": bpy.app.version_string,
            "extension_module": extension_module,
        },
        "mesh": mesh_report,
        "rig": rig_report,
        "interesting_vertex_groups": interesting_groups,
        "interesting_bones": interesting_bones,
        "output": str(output_path),
        "output_bytes": output_path.stat().st_size,
    }
    report_path.write_text(json.dumps(report, indent=2), encoding="utf-8")
    print(json.dumps(report, indent=2))
    print(SUCCESS_MARKER)


if __name__ == "__main__":
    try:
        _run()
    except BaseException as error:  # Blender may otherwise exit 0 after script exceptions.
        print(f"{ERROR_MARKER}: {error}")
        traceback.print_exc()
        # Do not trust Blender's process return code alone; workflow also checks
        # marker/output presence and rejects Traceback text.
