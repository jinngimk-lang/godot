#!/usr/bin/env python3
"""Validate and ingest a genuinely artist-edited Peel Calm MPFB support-grasp .blend.

This is deliberately a *handoff/acceptance bridge*, not another pose generator. Blender must open
an already visually edited v77-derived authoring scene before running this script. The script:

- verifies the locked bar_v1/market_v1 authoring-scene contract;
- proves wrist + v74 thumb stayed identical to the committed v77 seed;
- requires at least one of the twelve non-thumb finger pose bones to differ from that seed;
- serializes the current same-rig canonical pose without changing edit-bone roll/rest data;
- renders the fixed-camera 192x108 Macro view plus unobstructed Meso anatomy views;
- saves a validated copy of the .blend and a machine-readable report.

It never optimizes, searches, sweeps, aims, or mutates pose bones. Human visual review remains the
acceptance authority after this technical gate passes.
"""
from __future__ import annotations

import importlib.util
import json
import sys
from pathlib import Path

import bpy
from mathutils import Matrix

BASE = Path(__file__).resolve().parent
SPEC = importlib.util.spec_from_file_location(
    "mpfb_v77_ingest_helpers", BASE / "build_mpfb_artist_authoring_scene_v77.py"
)
if SPEC is None or SPEC.loader is None:
    raise RuntimeError("could not load v77 authoring helpers")
v77 = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(v77)

SUCCESS = "MPFB_ARTIST_BLEND_INGEST_SUCCESS"
EDIT_BONES = [f"finger{digit}-{joint}.R" for digit in range(2, 6) for joint in range(1, 4)]
FROZEN_BONES = ["wrist.R", "finger1-1.R", "finger1-2.R", "finger1-3.R"]
REFERENCE_SET = ["bar_v1", "market_v1"]


def _args():
    if "--" not in sys.argv:
        raise RuntimeError("expected -- <seed-pose.json> <out-dir> <pose.json> <report.json>")
    vals = sys.argv[sys.argv.index("--") + 1 :]
    if len(vals) != 4:
        raise RuntimeError("expected four arguments")
    return tuple(Path(v).resolve() for v in vals)


def _matrix(values) -> Matrix:
    if not isinstance(values, list) or len(values) != 16:
        raise RuntimeError("seed matrix_basis must contain 16 floats")
    return Matrix(tuple(tuple(float(values[r * 4 + c]) for c in range(4)) for r in range(4)))


def _matrix_error(a: Matrix, b: Matrix) -> float:
    return max(abs(float(a[r][c]) - float(b[r][c])) for r in range(4) for c in range(4))


def _load_seed(path: Path) -> dict:
    payload = json.loads(path.read_text(encoding="utf-8"))
    if payload.get("format") != "peel-calm-mpfb-canonical-support-pose-v1":
        raise RuntimeError("unexpected v77 seed pose format")
    if payload.get("rig") != "mpfb-default-canonical" or payload.get("side") != "right":
        raise RuntimeError("seed pose rig/side mismatch")
    bones = payload.get("bones")
    if not isinstance(bones, dict):
        raise RuntimeError("seed pose is missing bones")
    missing = [name for name in EDIT_BONES + FROZEN_BONES if name not in bones]
    if missing:
        raise RuntimeError(f"seed pose missing required bones: {missing}")
    return payload


def _find_contract():
    scene = bpy.context.scene
    arm = bpy.data.objects.get("PeelCalm_GameEngine_HeroRig_V77")
    vessel = bpy.data.objects.get("LOCKED_VESSEL_PROXY_V77")
    cam = scene.camera
    if arm is None or arm.type != "ARMATURE":
        raise RuntimeError("native v77 GameEngine authoring armature missing")
    if vessel is None or vessel.type != "MESH":
        raise RuntimeError("locked v77 vessel proxy missing")
    if cam is None or cam.type != "CAMERA":
        raise RuntimeError("fixed authoring camera missing")
    if arm.get("peel_calm_authoring_scene") != "v77":
        raise RuntimeError("armature is not a v77 artist-authoring scene")
    if arm.get("peel_calm_reference_set") != "bar_v1,market_v1":
        raise RuntimeError("locked reference set drifted")
    if vessel.get("peel_calm_locked") is not True:
        raise RuntimeError("vessel proxy is no longer marked locked")
    if vessel.get("peel_calm_reference_set") != "bar_v1,market_v1":
        raise RuntimeError("vessel reference set drifted")
    expected_edit = set(EDIT_BONES)
    expected_frozen = set(FROZEN_BONES)
    if set(str(arm.get("peel_calm_edit_bones", "")).split(",")) != expected_edit:
        raise RuntimeError("editable-bone contract drifted")
    if set(str(arm.get("peel_calm_frozen_bones", "")).split(",")) != expected_frozen:
        raise RuntimeError("frozen-bone contract drifted")
    if bpy.data.texts.get("PEEL_CALM_V77_AUTHORING_GUIDE") is None:
        raise RuntimeError("embedded artist-authoring guide missing")
    missing = [name for name in EDIT_BONES + FROZEN_BONES if arm.pose.bones.get(name) is None]
    if missing:
        raise RuntimeError(f"candidate rig missing pose bones: {missing}")
    return scene, arm, vessel, cam


def _find_skinned_base(arm):
    candidates = []
    for obj in bpy.context.scene.objects:
        if obj.type != "MESH":
            continue
        for mod in obj.modifiers:
            if mod.type == "ARMATURE" and getattr(mod, "object", None) == arm:
                candidates.append(obj)
                break
    if not candidates:
        raise RuntimeError("could not find MPFB deforming base mesh")
    return max(candidates, key=lambda obj: len(obj.data.vertices))


def _render_evidence(arm, vessel, out: Path):
    base = _find_skinned_base(arm)
    if bpy.context.mode != "OBJECT":
        bpy.ops.object.mode_set(mode="OBJECT")
    for obj in bpy.context.scene.objects:
        if obj.type == "MESH" and obj != base and obj != vessel:
            obj.hide_render = True
    base.hide_render = True
    arm.hide_render = True

    posed = v77.v73._static(base)
    posed.name = "ARTIST_EDITED_NATIVE_RIG_INGEST"
    segments = v77.v64._selected_segments(arm)
    palm = v77.v65._wp(arm, "wrist.R", True).lerp(v77.v65._wp(arm, "finger3-1.R"), 0.65)
    v77.v64b._adaptive_crop(posed, segments, palm)
    v77.v65._skin(posed, "ARTIST_INGEST")
    posed.hide_render = False

    vessel.hide_render = False
    v77.v65._render(out / "artist-candidate-with-vessel.png", 640, 640)
    v77.v65._render(out / "artist-candidate-thumbnail.png", 192, 108)
    vessel.hide_render = True
    v77.v65._render(out / "artist-candidate-anatomy-oblique.png", 640, 640)
    v77.v65._render(out / "artist-candidate-anatomy-thumbnail.png", 192, 108)
    vessel.hide_render = False


def run():
    seed_path, out, pose_path, report_path = _args()
    out.mkdir(parents=True, exist_ok=True)
    pose_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.parent.mkdir(parents=True, exist_ok=True)

    seed = _load_seed(seed_path)
    scene, arm, vessel, cam = _find_contract()
    if bpy.context.mode != "OBJECT":
        bpy.ops.object.mode_set(mode="OBJECT")
    bpy.context.view_layer.update()

    seed_bones = seed["bones"]
    frozen_errors = {}
    edit_errors = {}
    for name in FROZEN_BONES:
        frozen_errors[name] = _matrix_error(
            arm.pose.bones[name].matrix_basis, _matrix(seed_bones[name]["matrix_basis"])
        )
    for name in EDIT_BONES:
        edit_errors[name] = _matrix_error(
            arm.pose.bones[name].matrix_basis, _matrix(seed_bones[name]["matrix_basis"])
        )

    frozen_max = max(frozen_errors.values())
    edit_max = max(edit_errors.values())
    changed_edit_count = sum(1 for value in edit_errors.values() if value > 1e-5)
    if frozen_max > 1e-5:
        raise RuntimeError(f"artist candidate changed frozen wrist/thumb, max matrix delta={frozen_max}")
    if changed_edit_count == 0 or edit_max <= 1e-5:
        raise RuntimeError("artist candidate did not actually edit any allowed finger pose bone")

    # Persist exactly the current native-rig pose. This helper only serializes matrix_basis values;
    # it does not alter the pose or edit-bone roll/rest structure.
    v77.v68._save_same_rig_pose(arm, pose_path)
    _render_evidence(arm, vessel, out)
    validated_blend = out / "peel-calm-support-grasp-artist-validated.blend"
    bpy.ops.wm.save_as_mainfile(filepath=str(validated_blend), check_existing=False)

    report = {
        "staging_only": True,
        "production_candidate": False,
        "visual_verdict": "UNSET — human Macro/Meso review required",
        "reference_set": REFERENCE_SET,
        "native_gameengine_rig": True,
        "source_authoring_scene": "v77-derived direct visual pose edit",
        "pose_generator_used": False,
        "parameter_sweep_used": False,
        "ccd_used": False,
        "endpoint_optimizer_used": False,
        "contact_servo_used": False,
        "root_orbit_motion_used": False,
        "frozen_bones": FROZEN_BONES,
        "editable_bones": EDIT_BONES,
        "frozen_matrix_max_abs_delta_vs_v77_seed": frozen_max,
        "edited_bone_count_vs_v77_seed": changed_edit_count,
        "edited_matrix_max_abs_delta_vs_v77_seed": edit_max,
        "edited_bone_matrix_deltas": edit_errors,
        "pose_asset": str(pose_path),
        "validated_blend": str(validated_blend),
        "evidence": [
            "artist-candidate-thumbnail.png",
            "artist-candidate-with-vessel.png",
            "artist-candidate-anatomy-thumbnail.png",
            "artist-candidate-anatomy-oblique.png",
        ],
        "next_gate": (
            "Judge the 192x108 vessel image first: it must read immediately as a relaxed human bottle grip "
            "with progressive far-side finger enclosure and opposing thumb. Then inspect unobstructed anatomy. "
            "Technical PASS cannot promote a visually failing pose."
        ),
    }
    report_path.write_text(json.dumps(report, indent=2, sort_keys=True), encoding="utf-8")
    print(json.dumps(report, indent=2, sort_keys=True))
    print(SUCCESS)


if __name__ == "__main__":
    run()
