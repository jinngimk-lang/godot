#!/usr/bin/env python3
"""v70 diagnostic: prove whether canonical thumb pose changes reach the visible MPFB skin.

This is deliberately NOT a new pose candidate. It reconstructs pristine v65-B, captures the
baseline evaluated mesh, applies the exact rejected v69 thumb opposition arc, captures the same
mesh again, and measures deformation only. The goal is to distinguish a skin-weight/bone-mapping
failure from a silhouette/occlusion failure before any more authoring work.

MPFB's helper masks change evaluated topology, so for this diagnostic only we temporarily disable
all non-Armature modifiers. That preserves the source vertex indices/weights while retaining the
actual armature deformation being measured. Production rendering/import behavior is untouched.
"""
from __future__ import annotations

import importlib.util
import json
import sys
import traceback
from pathlib import Path

import bpy

BASE = Path(__file__).resolve().parent
SPEC = importlib.util.spec_from_file_location("mpfb_v69_for_v70", BASE / "author_mpfb_thumb_arc_v69.py")
if SPEC is None or SPEC.loader is None:
    raise RuntimeError("could not load v69 helpers")
v69 = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(v69)
v68 = v69.v68
v65 = v69.v65

SUCCESS = "MPFB_THUMB_SKIN_V70_SUCCESS"
THUMB_BONES = ["finger1-1.R", "finger1-2.R", "finger1-3.R"]


def _args():
    if "--" not in sys.argv:
        raise RuntimeError("expected -- <extension-module> <report.json>")
    values = sys.argv[sys.argv.index("--") + 1:]
    if len(values) != 2:
        raise RuntimeError("expected two arguments")
    return values[0], Path(values[1]).resolve()


def _reset():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)


def _is_armature_modifier(modifier) -> bool:
    return modifier.type == "ARMATURE"


def _disable_non_armature_modifiers(obj):
    states = []
    for modifier in obj.modifiers:
        states.append((modifier, bool(modifier.show_viewport), bool(modifier.show_render)))
        if not _is_armature_modifier(modifier):
            modifier.show_viewport = False
            modifier.show_render = False
    bpy.context.view_layer.update()
    return states


def _restore_modifiers(states):
    for modifier, show_viewport, show_render in states:
        modifier.show_viewport = show_viewport
        modifier.show_render = show_render
    bpy.context.view_layer.update()


def _evaluated_world_vertices(obj):
    depsgraph = bpy.context.evaluated_depsgraph_get()
    bpy.context.view_layer.update()
    evaluated = obj.evaluated_get(depsgraph)
    mesh = evaluated.to_mesh(preserve_all_data_layers=True, depsgraph=depsgraph)
    try:
        if len(mesh.vertices) != len(obj.data.vertices):
            raise RuntimeError(f"armature-only evaluated vertex count changed {len(obj.data.vertices)} -> {len(mesh.vertices)}")
        world = evaluated.matrix_world
        return [world @ v.co for v in mesh.vertices]
    finally:
        evaluated.to_mesh_clear()


def _thumb_weights(mesh_obj):
    group_by_index = {g.index: g.name for g in mesh_obj.vertex_groups}
    missing = [name for name in THUMB_BONES if mesh_obj.vertex_groups.get(name) is None]
    if missing:
        raise RuntimeError("MPFB skin is missing canonical thumb vertex groups: " + str(missing))
    weights = []
    per_bone_counts = {name: 0 for name in THUMB_BONES}
    for vertex in mesh_obj.data.vertices:
        total = 0.0
        for assignment in vertex.groups:
            name = group_by_index.get(assignment.group)
            if name in THUMB_BONES:
                total += float(assignment.weight)
                if assignment.weight > 0.01:
                    per_bone_counts[name] += 1
        weights.append(total)
    return weights, per_bone_counts


def _apply_v69_arc_only(arm, vessel_center, vessel_radius, palm_center, longitudinal, span):
    palm_radial = (palm_center - vessel_center).normalized()
    near = vessel_center + palm_radial * (vessel_radius + 0.014)
    targets = {
        "finger1-1.R": near - span * (vessel_radius * 1.38) + longitudinal * (vessel_radius * 0.38),
        "finger1-2.R": near - span * (vessel_radius * 0.72) + longitudinal * (vessel_radius * 0.03),
        "finger1-3.R": near - span * (vessel_radius * 0.10) - longitudinal * (vessel_radius * 0.28),
    }
    for name in THUMB_BONES:
        v68._aim_pose_bone_world(arm, name, targets[name])
    bpy.context.view_layer.update()
    return targets


def _stats(values):
    if not values:
        return {"count": 0, "mean_m": 0.0, "max_m": 0.0, "p95_m": 0.0}
    ordered = sorted(values)
    p95 = ordered[min(len(ordered)-1, int(round((len(ordered)-1)*0.95)))]
    return {
        "count": len(values),
        "mean_m": float(sum(values) / len(values)),
        "max_m": float(max(values)),
        "p95_m": float(p95),
    }


def run():
    extension_module, report_path = _args()
    report_path.parent.mkdir(parents=True, exist_ok=True)
    _reset()
    mpfb, HumanService = v65._services(extension_module)
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

    disabled_states = _disable_non_armature_modifiers(basemesh)
    disabled_names = [m.name for m, show_v, show_r in disabled_states if not _is_armature_modifier(m)]
    try:
        vessel_center, vessel_radius, palm_center, longitudinal, span, palmar = v68._ORIGINAL_AUTHOR(arm, -1.0)
        baseline_vertices = _evaluated_world_vertices(basemesh)
        baseline_heads_tails = {
            name: {"head": v65._wp(arm, name).copy(), "tail": v65._wp(arm, name, True).copy()}
            for name in THUMB_BONES
        }
        weights, per_bone_counts = _thumb_weights(basemesh)
        targets = _apply_v69_arc_only(arm, vessel_center, vessel_radius, palm_center, longitudinal, span)
        candidate_vertices = _evaluated_world_vertices(basemesh)
    finally:
        _restore_modifiers(disabled_states)

    displacements = [(b-a).length for a,b in zip(baseline_vertices, candidate_vertices)]
    by_threshold = {}
    for threshold in (0.01, 0.25, 0.50, 0.75):
        selected = [d for d,w in zip(displacements, weights) if w >= threshold]
        by_threshold[str(threshold)] = _stats(selected)

    non_thumb = [d for d,w in zip(displacements, weights) if w < 0.01]
    bone_motion = {}
    for name in THUMB_BONES:
        bone_motion[name] = {
            "head_displacement_m": float((v65._wp(arm, name) - baseline_heads_tails[name]["head"]).length),
            "tail_displacement_m": float((v65._wp(arm, name, True) - baseline_heads_tails[name]["tail"]).length),
        }

    report = {
        "diagnostic_only": True,
        "production_candidate": False,
        "base_pose": "pristine v65-B",
        "tested_change": "exact rejected v69 thumb opposition arc",
        "modifier_isolation": "non-Armature modifiers disabled only while measuring indexed deformation",
        "disabled_modifier_names": disabled_names,
        "source_vertex_count": len(basemesh.data.vertices),
        "mpfb_version": list(mpfb.VERSION),
        "thumb_bones": THUMB_BONES,
        "thumb_vertex_group_counts_weight_gt_0_01": per_bone_counts,
        "weighted_vertex_deformation": by_threshold,
        "non_thumb_vertex_deformation": _stats(non_thumb),
        "thumb_bone_motion": bone_motion,
        "targets": {name: [float(x) for x in target] for name,target in targets.items()},
        "interpretation_gate": "If thumb bones move materially and vertices with >=0.5 thumb weight also move materially, skin mapping is responsive and the remaining failure is pose silhouette/occlusion. If bones move but high-weight thumb vertices barely move, investigate weights/bone mapping before any more pose authoring.",
    }
    report_path.write_text(json.dumps(report, indent=2, sort_keys=True), encoding="utf-8")
    print(json.dumps(report, indent=2, sort_keys=True))
    print(SUCCESS)


if __name__ == "__main__":
    try:
        run()
    except BaseException as exc:
        print("MPFB_THUMB_SKIN_V70_ERROR:", exc)
        traceback.print_exc()
        raise
