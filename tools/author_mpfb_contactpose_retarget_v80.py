#!/usr/bin/env python3
"""v80: one-shot anatomical retarget from a real ContactPose water-bottle grasp.

Checkpoint 36 closed numeric/screen-space pose searches. v79 then found a public,
MIT-licensed ContactPose water-bottle annotation whose real 21-joint anatomy matches
the locked Peel Calm support-grip grammar. This script performs exactly ONE direct
reference transfer: normalized source phalanx directions -> the native MPFB
GameEngine right-hand palm frame.

There is deliberately no CCD, endpoint optimization, contact servo, coefficient
search, angle sweep, or post-retarget correction. If this exact anatomical transfer
fails the 192x108 Macro/Meso visual gate, the route is rejected rather than tuned.
Only annotation joints are used; ContactPose object meshes and MANO assets are not.
"""
from __future__ import annotations

import importlib.util
import json
import math
import sys
import traceback
from pathlib import Path

import bpy
from mathutils import Matrix, Vector

BASE = Path(__file__).resolve().parent


def _load(name: str, filename: str):
    spec = importlib.util.spec_from_file_location(name, BASE / filename)
    if spec is None or spec.loader is None:
        raise RuntimeError("could not load " + filename)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


v77 = _load("mpfb_v77_for_v80", "build_mpfb_artist_authoring_scene_v77.py")
v76 = v77.v76
v73 = v76.v73
v65 = v77.v65
v64 = v77.v64
v64b = v77.v64b
v68 = v77.v68

SUCCESS = "MPFB_CONTACTPOSE_RETARGET_V80_SUCCESS"
SOURCE_CHAINS = {
    "thumb": ([1, 2, 3, 4], ["finger1-1.R", "finger1-2.R", "finger1-3.R"]),
    "index": ([5, 6, 7, 8], ["finger2-1.R", "finger2-2.R", "finger2-3.R"]),
    "middle": ([9, 10, 11, 12], ["finger3-1.R", "finger3-2.R", "finger3-3.R"]),
    "ring": ([13, 14, 15, 16], ["finger4-1.R", "finger4-2.R", "finger4-3.R"]),
    "pinky": ([17, 18, 19, 20], ["finger5-1.R", "finger5-2.R", "finger5-3.R"]),
}
DIGIT_BONES = [name for _, dst in SOURCE_CHAINS.values() for name in dst]


def _args():
    if "--" not in sys.argv:
        raise RuntimeError("expected -- <extension-module> <source.json> <outdir> <report.json>")
    vals = sys.argv[sys.argv.index("--") + 1 :]
    if len(vals) != 4:
        raise RuntimeError("expected four arguments")
    return vals[0], Path(vals[1]).resolve(), Path(vals[2]).resolve(), Path(vals[3]).resolve()


def _flat(pb):
    return [float(pb.matrix_basis[r][c]) for r in range(4) for c in range(4)]


def _max_delta(a, b):
    return max(abs(x - y) for x, y in zip(a, b))


def _unit(v: Vector) -> Vector:
    if v.length < 1e-8:
        raise RuntimeError("degenerate reference direction")
    return v.normalized()


def _target_palm_basis(arm):
    """Match the semantic frame used by the v79 ContactPose normalizer.

    source +X = pinky -> index across MCP row
    source +Y = wrist -> middle MCP
    source +Z = X cross Y (toward the curled digit volume for selected full6_use h1)
    """
    wrist = v65._wp(arm, "wrist.R")
    index = v65._wp(arm, "finger2-1.R")
    middle = v65._wp(arm, "finger3-1.R")
    pinky = v65._wp(arm, "finger5-1.R")
    x = _unit(index - pinky)
    y_hint = _unit(middle - wrist)
    z = _unit(x.cross(y_hint))
    y = _unit(z.cross(x))
    return x, y, z


def _source_dirs(joints, ids):
    out = []
    for a, b in zip(ids[:-1], ids[1:]):
        va = Vector(joints[a])
        vb = Vector(joints[b])
        out.append(_unit(vb - va))
    return out


def _world_from_local(local: Vector, basis):
    x, y, z = basis
    return _unit(x * local.x + y * local.y + z * local.z)


def _bone_world_direction(arm, name):
    return _unit(v65._wp(arm, name, True) - v65._wp(arm, name))


def _align_bone_world(arm, name, desired_world):
    current = _bone_world_direction(arm, name)
    q = current.rotation_difference(desired_world)
    angle = float(q.angle)
    if angle > 1e-8:
        axis = Vector(q.axis)
        v65._rotate_pose_bone_world(arm, name, axis, angle)
    bpy.context.view_layer.update()
    actual = _bone_world_direction(arm, name)
    err = math.degrees(actual.angle(desired_world))
    return math.degrees(angle), err


def _clear_digits(arm):
    for name in DIGIT_BONES:
        pb = arm.pose.bones.get(name)
        if pb is None:
            raise RuntimeError("missing GameEngine digit bone " + name)
        pb.matrix_basis = Matrix.Identity(4)
    bpy.context.view_layer.update()


def _apply_reference(arm, joints):
    basis = _target_palm_basis(arm)
    rows = []
    # Align each chain parent-to-child. Parent inheritance is therefore already
    # present when the child is aligned to its absolute source direction.
    for label in ("thumb", "index", "middle", "ring", "pinky"):
        ids, dst = SOURCE_CHAINS[label]
        src_dirs = _source_dirs(joints, ids)
        for source_dir, target_name in zip(src_dirs, dst):
            desired = _world_from_local(source_dir, basis)
            applied_deg, error_deg = _align_bone_world(arm, target_name, desired)
            rows.append({
                "digit": label,
                "bone": target_name,
                "source_local_direction": [float(source_dir.x), float(source_dir.y), float(source_dir.z)],
                "desired_world_direction": [float(desired.x), float(desired.y), float(desired.z)],
                "applied_rotation_deg": applied_deg,
                "post_alignment_error_deg": error_deg,
            })
    return rows


def run():
    ext, source_path, out, report_path = _args()
    out.mkdir(parents=True, exist_ok=True)
    report_path.parent.mkdir(parents=True, exist_ok=True)
    source = json.loads(source_path.read_text(encoding="utf-8"))
    joints = source.get("normalized_openpose21")
    if not isinstance(joints, list) or len(joints) != 21:
        raise RuntimeError("source must contain normalized_openpose21 with 21 joints")
    if source.get("object") != "water_bottle" or source.get("session") != "full6_use" or source.get("hand_index") != 1:
        raise RuntimeError("v80 is intentionally locked to exactly full6_use hand1 water_bottle")

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

    # Reuse the proven v65-B whole-hand/wrist/vessel relationship, then clear
    # ALL finger-chain pose deltas. This keeps wrist/palm placement and camera
    # semantics while ensuring the resulting digit shape comes only from the
    # ContactPose reference, not from v65's authored finger angles.
    vessel_center, vessel_radius, palm_center, longitudinal, span, palmar = v65._author_power_grasp(arm, -1.0)
    wrist_before = _flat(arm.pose.bones["wrist.R"])
    _clear_digits(arm)
    wrist_after_clear = _flat(arm.pose.bones["wrist.R"])
    wrist_clear_delta = _max_delta(wrist_before, wrist_after_clear)
    if wrist_clear_delta > 1e-7:
        raise RuntimeError("clearing digit pose unexpectedly changed wrist")

    # Recompute palm geometry after clearing digits; root locations remain on
    # the same native rig and the v65-B wrist pronation remains frozen.
    palm_center, longitudinal, span_v65, normal_v65 = v65._palm_frame(arm)
    palmar = normal_v65 * -1.0
    vessel_center = palm_center + palmar * (vessel_radius + 0.030)
    focus = palm_center.lerp(vessel_center, 0.55)
    cam = v65._scene_camera(focus, longitudinal, span_v65, palmar, "CP80")

    rows = _apply_reference(arm, joints)
    wrist_after = _flat(arm.pose.bones["wrist.R"])
    wrist_retarget_delta = _max_delta(wrist_before, wrist_after)
    if wrist_retarget_delta > 1e-7:
        raise RuntimeError("direct digit retarget unexpectedly changed wrist")

    pose_path = out / "support-wrap-contactpose-v80-same-rig-pose.json"
    v68._save_same_rig_pose(arm, pose_path)

    # Render the exact posed mesh at both evidence scales.
    bpy.context.view_layer.update()
    segments = v64._selected_segments(arm)
    baked = v73._static(base)
    v64b._adaptive_crop(baked, segments, palm_center)
    v65._skin(baked, "CP80")
    vessel = v65._vessel(vessel_center, longitudinal, vessel_radius, "CP80")
    base.hide_render = True
    arm.hide_render = True
    baked.hide_render = False
    vessel.hide_render = False
    v65._render(out / "support-wrap-contactpose-v80-with-vessel.png", 640, 640)
    v65._render(out / "support-wrap-contactpose-v80-thumbnail.png", 192, 108)
    vessel.hide_render = True
    v65._render(out / "support-wrap-contactpose-v80-anatomy-oblique.png", 640, 640)
    v65._render(out / "support-wrap-contactpose-v80-anatomy-thumbnail.png", 192, 108)

    diagnostics = v65._diagnostics(arm, vessel_center, longitudinal, palmar)
    max_alignment_error = max(r["post_alignment_error_deg"] for r in rows)
    max_applied = max(r["applied_rotation_deg"] for r in rows)
    report = {
        "staging_only": True,
        "production_candidate": False,
        "reference_set": ["bar_v1", "market_v1"],
        "source": {
            "dataset": "ContactPose public Explorer",
            "object": source["object"],
            "session": source["session"],
            "hand_index": source["hand_index"],
            "license_scope": source["license_scope"],
            "source_path": str(source_path),
        },
        "native_gameengine_rig": True,
        "direct_reference_retarget": True,
        "retarget_candidate_count": 1,
        "parameter_sweep_used": False,
        "ccd_used": False,
        "endpoint_optimizer_used": False,
        "contact_servo_used": False,
        "post_retarget_pose_correction_used": False,
        "wrist_matrix_max_abs_delta_after_digit_clear": wrist_clear_delta,
        "wrist_matrix_max_abs_delta_after_retarget": wrist_retarget_delta,
        "max_post_alignment_error_deg": max_alignment_error,
        "max_applied_digit_rotation_deg": max_applied,
        "alignment_rows": rows,
        "grasp_diagnostics": diagnostics,
        "source_metrics": source.get("metrics", {}),
        "pose_path": str(pose_path),
        "mpfb_version": list(mpfb.VERSION),
        "visual_gate": (
            "Manual visual decision only. PASS requires 192x108 first-glance cylindrical enclosure, "
            "progressive index->pinky far-side wrap, clear opposing thumb, and clean unobstructed oblique anatomy. "
            "If this exact candidate fails, reject direct ContactPose retarget; do not tune coefficients."
        ),
    }
    report_path.write_text(json.dumps(report, indent=2, sort_keys=True), encoding="utf-8")
    print(json.dumps(report, indent=2, sort_keys=True))
    print(SUCCESS)


if __name__ == "__main__":
    try:
        run()
    except BaseException as exc:
        print("MPFB_CONTACTPOSE_RETARGET_V80_ERROR:", exc)
        traceback.print_exc()
        raise
