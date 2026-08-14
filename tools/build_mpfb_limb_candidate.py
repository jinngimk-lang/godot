"""Build and inspect an MPFB-derived hero-limb source candidate.

This is a staging tool, not a production dependency. It proves that a pinned
MPFB human + GameEngine rig can be generated reproducibly in headless Blender
and records the exact mesh/bone/vertex-group structure needed for a later
left/right hand-wrist-forearm extraction pass.

Usage:
  blender --background --python tools/build_mpfb_limb_candidate.py -- \
    <mpfb-src-dir> <output.glb> <report.json>
"""

from __future__ import annotations

import json
import os
import sys
from pathlib import Path

import bpy


def _args() -> tuple[Path, Path, Path]:
    if "--" not in sys.argv:
        raise SystemExit("expected -- <mpfb-src-dir> <output.glb> <report.json>")
    values = sys.argv[sys.argv.index("--") + 1 :]
    if len(values) != 3:
        raise SystemExit("expected exactly three arguments after --")
    return tuple(Path(value).resolve() for value in values)


def _reset_scene() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for collection in (bpy.data.meshes, bpy.data.armatures, bpy.data.materials):
        for block in list(collection):
            if block.users == 0:
                collection.remove(block)


def _load_mpfb(mpfb_src: Path):
    package_root = mpfb_src / "mpfb"
    if not (package_root / "__init__.py").is_file():
        raise RuntimeError(f"MPFB package not found under {mpfb_src}")
    sys.path.insert(0, str(mpfb_src))
    import mpfb  # pylint: disable=import-error,import-outside-toplevel

    # Source checkout is intentionally registered for this isolated Blender
    # process only. No user preferences or persistent Blender state are touched.
    mpfb.register()
    from mpfb.services import HumanService  # pylint: disable=import-error,import-outside-toplevel

    return mpfb, HumanService


def _mesh_stats(obj: bpy.types.Object) -> dict:
    mesh = obj.data
    if obj.type != "MESH" or mesh is None:
        return {}
    bounds = [obj.matrix_world @ corner for corner in obj.bound_box]
    xs = [point.x for point in bounds]
    ys = [point.y for point in bounds]
    zs = [point.z for point in bounds]
    material_names = [
        slot.material.name if slot.material is not None else ""
        for slot in obj.material_slots
    ]
    vertex_groups = []
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
        vertex_groups.append({
            "name": group.name,
            "weighted_vertices": weighted,
            "max_weight": round(max_weight, 6),
        })
    return {
        "name": obj.name,
        "vertices": len(mesh.vertices),
        "polygons": len(mesh.polygons),
        "materials": material_names,
        "bounds_world": {
            "min": [min(xs), min(ys), min(zs)],
            "max": [max(xs), max(ys), max(zs)],
        },
        "vertex_groups": vertex_groups,
    }


def _armature_stats(obj: bpy.types.Object) -> dict:
    bones = []
    for bone in obj.data.bones:
        bones.append({
            "name": bone.name,
            "parent": bone.parent.name if bone.parent is not None else None,
            "head_local": list(bone.head_local),
            "tail_local": list(bone.tail_local),
        })
    return {
        "name": obj.name,
        "bones": bones,
        "bone_count": len(bones),
    }


def _apply_simple_game_skin(basemesh: bpy.types.Object) -> None:
    """Give the staging mesh a predictable PBR skin material.

    The geometry/rig is what this first MPFB spike is evaluating. A simple
    Principled material avoids shader-export noise and keeps licensing/provenance
    trivial. A proper skin texture/material pass comes only after anatomy wins.
    """
    material = bpy.data.materials.new("HandSkinCandidate")
    material.use_nodes = True
    material.diffuse_color = (0.47, 0.29, 0.21, 1.0)
    principled = next(
        (node for node in material.node_tree.nodes if node.type == "BSDF_PRINCIPLED"),
        None,
    )
    if principled is not None:
        base = principled.inputs.get("Base Color")
        if base is not None:
            base.default_value = (0.47, 0.29, 0.21, 1.0)
        roughness = principled.inputs.get("Roughness")
        if roughness is not None:
            roughness.default_value = 0.58
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


def main() -> None:
    mpfb_src, output_path, report_path = _args()
    output_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.parent.mkdir(parents=True, exist_ok=True)

    _reset_scene()
    mpfb, HumanService = _load_mpfb(mpfb_src)

    # Use MPFB defaults for phenotype in the first structural experiment. The
    # exact sex/age/skin can be tuned only after the hand/wrist/forearm topology
    # and GameEngine rig prove useful at the Peel Calm camera distance.
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
        basemesh,
        "game_engine",
        import_weights=True,
        operator=None,
    )
    if armature is None or armature.type != "ARMATURE":
        raise RuntimeError("MPFB did not create GameEngine armature")

    _apply_simple_game_skin(basemesh)

    mesh_report = _mesh_stats(basemesh)
    rig_report = _armature_stats(armature)

    interesting_groups = [
        group for group in mesh_report.get("vertex_groups", [])
        if any(token in group["name"].lower() for token in (
            "hand", "forearm", "upperarm", "arm", "wrist", "thumb",
            "index", "middle", "ring", "pinky", "finger"
        ))
    ]
    interesting_bones = [
        bone for bone in rig_report["bones"]
        if any(token in bone["name"].lower() for token in (
            "hand", "forearm", "upperarm", "arm", "wrist", "thumb",
            "index", "middle", "ring", "pinky", "finger"
        ))
    ]

    _export_glb(output_path, basemesh, armature)
    if not output_path.is_file() or output_path.stat().st_size <= 0:
        raise RuntimeError("MPFB candidate GLB export failed")

    report = {
        "generator": {
            "mpfb_version": list(mpfb.VERSION),
            "mpfb_build_info": mpfb.BUILD_INFO,
            "blender_version": bpy.app.version_string,
            "mpfb_source": str(mpfb_src),
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


if __name__ == "__main__":
    main()
