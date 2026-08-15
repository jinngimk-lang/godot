#!/usr/bin/env python3
"""v74: recover the already-opposing v72 distal thumb from top-frame clipping.

v73 decomposed the rejected v72 thumb and found the important partial success that the combined
thumb metric hid: the distal segment reached +12.0 px on the opposite vessel side. The remaining
failure is camera-space placement: distal bbox y=0..5 and proximal bbox y=0..27 are top-clipped,
while root correctly remains on the palm side. Therefore v74 does NOT increase whole-thumb
opposition. It reconstructs v72 exactly, freezes root/wrist/palm/vessel/four fingers/camera, and
makes one proximal+distal-only camera-basis recovery gesture toward the image interior.

No sweep, CCD, endpoint optimizer, contact servo, tolerance change, or camera change is permitted.
Acceptance is rendered at 192x108: distal must remain >= +4 px across the vessel centerline and
must clear the top by >= 6 px; proximal must also stop touching the top and approach the centerline.
A numeric pass still requires unobstructed anatomy visual review.
"""
from __future__ import annotations

import importlib.util
import json
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
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


v65 = _load("mpfb_v65_for_v74", "author_mpfb_reference_grasp_v65.py")
v68 = _load("mpfb_v68_for_v74", "author_mpfb_thumb_chain_v68.py")
v71b = _load("mpfb_v71b_for_v74", "diagnose_mpfb_digit_opposition_v71b.py")
v72 = _load("mpfb_v72_for_v74", "author_mpfb_screen_opposition_v72.py")
v73 = _load("mpfb_v73_for_v74", "diagnose_mpfb_thumb_segments_v73.py")
v64 = v65.v64
v64b = v65.v64b

SUCCESS = "MPFB_DISTAL_RECOVERY_V74_SUCCESS"
FROZEN = ["wrist.R", "finger1-1.R"] + [f"finger{d}-{j}.R" for d in range(2, 6) for j in range(1, 4)]
EDITABLE = ["finger1-2.R", "finger1-3.R"]
POSE_BONES = ["wrist.R"] + [f"finger{d}-{j}.R" for d in range(1, 6) for j in range(1, 4)]


def _args():
    if "--" not in sys.argv:
        raise RuntimeError("expected -- <extension-module> <outdir> <report.json>")
    values = sys.argv[sys.argv.index("--") + 1:]
    if len(values) != 3:
        raise RuntimeError("expected three arguments")
    return values[0], Path(values[1]).resolve(), Path(values[2]).resolve()


def _reset():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)


def _flat(m: Matrix):
    return [float(m[r][c]) for r in range(4) for c in range(4)]


def _snapshot(arm, names):
    return {name: _flat(arm.pose.bones[name].matrix_basis.copy()) for name in names}


def _delta(before, after):
    return max(abs(a-b) for name in before for a, b in zip(before[name], after[name])) if before else 0.0


def _camera_basis(cam):
    q = cam.matrix_world.to_quaternion()
    return (
        (q @ Vector((1.0, 0.0, 0.0))).normalized(),
        (q @ Vector((0.0, 1.0, 0.0))).normalized(),
        (q @ Vector((0.0, 0.0, -1.0))).normalized(),
    )


def _recover_into_frame(arm, cam):
    right, up, forward = _camera_basis(cam)
    # v72 used negative camera-up and drove proximal/distal into the top edge. Reverse only that
    # vertical component, with a tiny screen-right bias to preserve the already-correct distal side.
    offsets = {
        "finger1-2.R": (0.006, 0.034, 0.000),
        "finger1-3.R": (0.006, 0.044, 0.000),
    }
    applied = {}
    for name in EDITABLE:
        tail = v65._wp(arm, name, True)
        dx, dy, dz = offsets[name]
        target = tail + right * dx + up * dy + forward * dz
        v68._aim_pose_bone_world(arm, name, target)
        bpy.context.view_layer.update()
        applied[name] = {"offset_camera_m": [dx, dy, dz], "target_world": [float(x) for x in target]}
    return applied


def _build_id_mesh(basemesh, arm, palm_center):
    rows = v73._segment_weights(basemesh)
    states = v71b._disable_non_armature_modifiers(basemesh)
    try:
        diagnostic = v71b._evaluated_mesh_object(basemesh, "DistalRecoveryMeshV74")
        v73._assign_materials(diagnostic, rows)
    finally:
        v71b._restore_modifiers(states)
    segments = v64._selected_segments(arm)
    v64b._adaptive_crop(diagnostic, segments, palm_center)
    return diagnostic


def _evaluate(path: Path):
    coords, masks = v73._masks(path)
    line = v71b._fit_vessel_centerline(coords["vessel"])
    sides = {}
    for name in v73.SEGMENTS:
        centroid = masks[name]["centroid_px"]
        sides[name] = None if centroid is None else v71b._signed_side(centroid, line)
    distal = masks["thumb_distal"]
    proximal = masks["thumb_proximal"]
    distal_top = None if distal["bbox_px"] is None else int(distal["bbox_px"][1])
    proximal_top = None if proximal["bbox_px"] is None else int(proximal["bbox_px"][1])
    gate = bool(
        sides["thumb_distal"] is not None
        and sides["thumb_distal"] >= 4.0
        and distal_top is not None and distal_top >= 6
        and not distal["touches_top"]
        and proximal_top is not None and proximal_top >= 2
        and not proximal["touches_top"]
        and sides["thumb_proximal"] is not None and sides["thumb_proximal"] >= -8.0
    )
    return {
        "masks": masks,
        "vessel_centerline": line,
        "segment_signed_side_px": sides,
        "frame_recovery_gate": {
            "distal_min_positive_side_px": 4.0,
            "distal_min_top_margin_px": 6,
            "proximal_min_top_margin_px": 2,
            "proximal_min_side_px": -8.0,
            "pass": gate,
            "intent": "preserve v72 distal opposition while bringing proximal/distal fully into the 192x108 image interior",
        },
    }


def _save_pose(arm, path: Path, evaluation):
    payload = {
        "format": "peel-calm-mpfb-canonical-support-pose-v2",
        "rig": "mpfb-default-canonical",
        "side": "right",
        "label": "v74 recovered opposing distal-thumb staging pose",
        "production_candidate": False,
        "provenance": {
            "base": "rejected v72 over pristine v65-B",
            "authoring": "single proximal/distal camera-interior recovery gesture",
            "ccd": False,
            "endpoint_optimizer": False,
            "parameter_sweep": False,
            "camera_change": False,
        },
        "screen_gate_summary": evaluation["frame_recovery_gate"],
        "bones": {name: {"matrix_basis": _flat(arm.pose.bones[name].matrix_basis)} for name in POSE_BONES},
    }
    path.write_text(json.dumps(payload, indent=2, sort_keys=True), encoding="utf-8")


def run():
    extension_module, out, report_path = _args()
    out.mkdir(parents=True, exist_ok=True)
    report_path.parent.mkdir(parents=True, exist_ok=True)
    _reset()
    mpfb, HumanService = v65._services(extension_module)
    basemesh = HumanService.create_human(mask_helpers=True, detailed_helpers=False, extra_vertex_groups=True, feet_on_ground=False, scale=0.1, macro_detail_dict=None)
    if basemesh is None or basemesh.type != "MESH":
        raise RuntimeError("MPFB human creation failed")
    arm = HumanService.add_builtin_rig(basemesh, "default", import_weights=True, operator=None)
    if arm is None or arm.type != "ARMATURE":
        raise RuntimeError("MPFB canonical default rig creation failed")

    vessel_center, vessel_radius, palm_center, longitudinal, span, palmar = v65._author_power_grasp(arm, -1.0)
    focus = palm_center.lerp(vessel_center, 0.55)
    cam = v71b._camera(focus, longitudinal, span, palmar)
    v72._author_thumb_once(arm, cam)
    bpy.context.view_layer.update()

    frozen_before = _snapshot(arm, FROZEN)
    editable_before = _snapshot(arm, EDITABLE)
    applied = _recover_into_frame(arm, cam)
    frozen_after = _snapshot(arm, FROZEN)
    editable_after = _snapshot(arm, EDITABLE)
    frozen_delta = _delta(frozen_before, frozen_after)
    editable_delta = _delta(editable_before, editable_after)
    if frozen_delta > 1e-8:
        raise RuntimeError(f"v74 changed frozen root/wrist/four-finger pose: {frozen_delta}")
    if editable_delta <= 1e-5:
        raise RuntimeError("v74 proximal/distal gesture produced no material change")

    diagnostic = _build_id_mesh(basemesh, arm, palm_center)
    basemesh.hide_render = True
    arm.hide_render = True
    vessel = v73._make_vessel(vessel_center, longitudinal, vessel_radius)
    with_vessel = out / "thumb-segments-v74-192x108.png"
    anatomy = out / "thumb-segments-v74-anatomy-192x108.png"
    vessel.hide_render = False
    v71b._render(with_vessel)
    evaluation = _evaluate(with_vessel)
    vessel.hide_render = True
    v71b._render(anatomy)

    pose_path = out / "support-wrap-v74-canonical-pose.json"
    _save_pose(arm, pose_path, evaluation)
    report = {
        "staging_only": True,
        "production_candidate": False,
        "base_pose": "rejected v72 over pristine v65-B",
        "reference_set": ["bar_v1", "market_v1"],
        "mpfb_version": list(mpfb.VERSION),
        "one_shot_candidate": True,
        "only_thumb_proximal_distal_changed": True,
        "thumb_root_changed_from_v72": False,
        "wrist_changed_from_v72": False,
        "non_thumb_fingers_changed_from_v72": False,
        "palm_vessel_relationship_changed": False,
        "camera_changed": False,
        "crop_changed": False,
        "ccd_used": False,
        "endpoint_optimizer_used": False,
        "parameter_sweep_used": False,
        "iterative_solver_used": False,
        "frozen_matrix_max_delta": frozen_delta,
        "editable_matrix_max_delta": editable_delta,
        "authoring": applied,
        "render_space_evaluation": evaluation,
        "pose_asset": str(pose_path),
        "visual_gate": "Numeric gate is necessary but insufficient. The anatomy view must show a continuous thumb arc without self-intersection, and the with-vessel thumbnail must read as an opposing thumb rather than a clipped top blob.",
    }
    report_path.write_text(json.dumps(report, indent=2, sort_keys=True), encoding="utf-8")
    print(json.dumps(report, indent=2, sort_keys=True))
    print(SUCCESS)


if __name__ == "__main__":
    try:
        run()
    except BaseException as exc:
        print("MPFB_DISTAL_RECOVERY_V74_ERROR:", exc)
        traceback.print_exc()
        raise
