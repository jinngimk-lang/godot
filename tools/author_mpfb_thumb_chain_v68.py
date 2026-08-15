#!/usr/bin/env python3
"""v68: freeze pristine v65-B support grip and author the thumb as one visible chain.

Checkpoint 30 falsified scalar thumb-angle tuning: v66 and v67 moved the skeleton strongly to
opposite radial sides while producing almost the same inadequate thumbnail.  v68 therefore
changes abstraction.  It keeps the exact v65-B wrist, palm, vessel, camera and four non-thumb
finger chains, then directly aims thumb root/proximal/distal toward one deterministic set of
artist-authored world-space landmarks on the near/side surface of the vertical vessel.

There is no CCD, endpoint minimization, target-distance optimizer, angle sweep or one-axis
magnitude search.  The three thumb bones are treated as a coherent visual chain and the resulting
same-rig canonical pose matrices are persisted so an accepted silhouette can be reproduced.
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
SPEC = importlib.util.spec_from_file_location("mpfb_v65_for_v68", BASE / "author_mpfb_reference_grasp_v65.py")
if SPEC is None or SPEC.loader is None:
    raise RuntimeError("could not load v65 base")
v65 = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(v65)

SUCCESS = "MPFB_THUMB_CHAIN_V68_SUCCESS"
_ORIGINAL_AUTHOR = v65._author_power_grasp
_POSE_PATH: Path | None = None
_THUMB_REPORT: dict = {}

POSE_BONES = [
    "wrist.R",
    "finger1-1.R", "finger1-2.R", "finger1-3.R",
    "finger2-1.R", "finger2-2.R", "finger2-3.R",
    "finger3-1.R", "finger3-2.R", "finger3-3.R",
    "finger4-1.R", "finger4-2.R", "finger4-3.R",
    "finger5-1.R", "finger5-2.R", "finger5-3.R",
]


def _args():
    if "--" not in sys.argv:
        raise RuntimeError("expected -- <extension-module> <outdir> <report.json>")
    values = sys.argv[sys.argv.index("--") + 1:]
    if len(values) != 3:
        raise RuntimeError("expected three arguments")
    return values[0], Path(values[1]).resolve(), Path(values[2]).resolve()


def _flat(matrix: Matrix) -> list[float]:
    return [float(matrix[r][c]) for r in range(4) for c in range(4)]


def _aim_pose_bone_world(arm, bone_name: str, target_world: Vector) -> None:
    """Rotate a pose bone at its current head so its shaft points at a fixed visual landmark."""
    pb = arm.pose.bones.get(bone_name)
    if pb is None:
        raise RuntimeError("missing pose bone " + bone_name)
    current = (pb.tail - pb.head).normalized()
    target_arm = arm.matrix_world.inverted() @ target_world
    desired = target_arm - pb.head
    if desired.length_squared < 1e-8:
        raise RuntimeError("degenerate visual landmark for " + bone_name)
    desired.normalize()
    q = current.rotation_difference(desired)
    head = pb.head.copy()
    pb.matrix = Matrix.Translation(head) @ q.to_matrix().to_4x4() @ Matrix.Translation(-head) @ pb.matrix
    bpy.context.view_layer.update()


def _save_same_rig_pose(arm, path: Path) -> None:
    missing = [name for name in POSE_BONES if arm.pose.bones.get(name) is None]
    if missing:
        raise RuntimeError("canonical pose bones missing: " + str(missing))
    payload = {
        "format": "peel-calm-mpfb-canonical-support-pose-v1",
        "rig": "mpfb-default-canonical",
        "side": "right",
        "label": "v68 direct visual thumb-chain staging pose",
        "production_candidate": False,
        "provenance": {
            "base": "pristine v65-B",
            "authoring": "direct visual world-space thumb-chain landmarks",
            "ccd": False,
            "endpoint_optimizer": False,
            "parameter_sweep": False,
        },
        "bones": {name: {"matrix_basis": _flat(arm.pose.bones[name].matrix_basis)} for name in POSE_BONES},
    }
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2, sort_keys=True), encoding="utf-8")


def _thumb_chain_author(arm, palmar_sign: float):
    global _THUMB_REPORT
    if palmar_sign != -1.0:
        raise RuntimeError("v68 is locked to v65 candidate-B palmar sign")

    vessel_center, vessel_radius, palm_center, longitudinal, span, palmar = _ORIGINAL_AUTHOR(arm, palmar_sign)
    palm_radial = (palm_center - vessel_center).normalized()

    # One coherent visual gesture, authored as three landmarks rather than three independent angle
    # knobs.  The chain starts on the index/thumb side, stays visibly on the near vessel surface,
    # then crosses inward/downward so the distal thumb reads as the opposing digit in the same
    # silhouette where the frozen index-middle-ring-pinky chains enclose the far side.
    near = vessel_center + palm_radial * (vessel_radius + 0.012)
    root_target = near - span * (vessel_radius * 0.82) + longitudinal * (vessel_radius * 0.34)
    proximal_target = near - span * (vessel_radius * 0.28) + longitudinal * (vessel_radius * 0.07)
    distal_target = (
        vessel_center
        + palm_radial * (vessel_radius + 0.006)
        + span * (vessel_radius * 0.18)
        - longitudinal * (vessel_radius * 0.10)
    )

    targets = [
        ("finger1-1.R", root_target),
        ("finger1-2.R", proximal_target),
        ("finger1-3.R", distal_target),
    ]
    for name, target in targets:
        _aim_pose_bone_world(arm, name, target)

    bpy.context.view_layer.update()
    thumb_root = v65._wp(arm, "finger1-1.R")
    thumb_tip = v65._wp(arm, "finger1-3.R", True)
    index_root = v65._wp(arm, "finger2-1.R")
    thumb_radial = thumb_tip - vessel_center
    thumb_radial -= longitudinal * thumb_radial.dot(longitudinal)
    palm_radial_plane = palm_center - vessel_center
    palm_radial_plane -= longitudinal * palm_radial_plane.dot(longitudinal)
    radial_dot = (
        thumb_radial.normalized().dot(palm_radial_plane.normalized())
        if thumb_radial.length > 1e-6 and palm_radial_plane.length > 1e-6
        else 1.0
    )
    _THUMB_REPORT = {
        "root_world": [float(x) for x in thumb_root],
        "tip_world": [float(x) for x in thumb_tip],
        "tip_to_index_root": float((thumb_tip - index_root).length),
        "thumb_palm_side_dot": float(radial_dot),
        "landmarks": {
            "root_target": [float(x) for x in root_target],
            "proximal_target": [float(x) for x in proximal_target],
            "distal_target": [float(x) for x in distal_target],
        },
    }
    if _POSE_PATH is not None:
        _save_same_rig_pose(arm, _POSE_PATH)
    return vessel_center, vessel_radius, palm_center, longitudinal, span, palmar


def run():
    global _POSE_PATH
    extension_module, out, report_path = _args()
    out.mkdir(parents=True, exist_ok=True)
    report_path.parent.mkdir(parents=True, exist_ok=True)
    _POSE_PATH = out / "support-wrap-v68-canonical-pose.json"
    mpfb, HumanService = v65._services(extension_module)

    v65._author_power_grasp = _thumb_chain_author
    candidate = v65._build_candidate(HumanService, out, "B68", -1.0)
    if not _POSE_PATH.is_file() or _POSE_PATH.stat().st_size <= 0:
        raise RuntimeError("same-rig v68 pose asset was not persisted")

    report = {
        "staging_only": True,
        "production_candidate": False,
        "reference_set": ["bar_v1", "market_v1"],
        "base_candidate": "pristine v65-B",
        "base_palmar_sign": -1.0,
        "direct_visual_thumb_chain": True,
        "thumb_bones_authored_together": ["finger1-1.R", "finger1-2.R", "finger1-3.R"],
        "non_thumb_fingers_changed_from_v65_b": False,
        "wrist_changed_from_v65_b": False,
        "palm_vessel_relationship_changed_from_v65_b": False,
        "camera_changed_from_v65_b": False,
        "crop_changed_from_v65_b": False,
        "ccd_used": False,
        "endpoint_optimizer_used": False,
        "parameter_sweep_used": False,
        "single_axis_thumb_sweep_used": False,
        "same_rig_pose_persisted": True,
        "same_rig_pose_path": str(_POSE_PATH),
        "production_gameengine_rig_touched": False,
        "mpfb_version": list(mpfb.VERSION),
        "thumb_diagnostics": _THUMB_REPORT,
        "candidate": candidate,
        "visual_gate": "At 192x108 the thumb must read immediately as one continuous opposing digit while the frozen four-finger v65-B grip encloses the vessel; unobstructed oblique anatomy must remain continuous and non-self-intersecting.",
    }
    report_path.write_text(json.dumps(report, indent=2, sort_keys=True), encoding="utf-8")
    print(json.dumps(report, indent=2, sort_keys=True))
    print(SUCCESS)


if __name__ == "__main__":
    try:
        run()
    except BaseException as exc:
        print("MPFB_THUMB_CHAIN_V68_ERROR:", exc)
        traceback.print_exc()
        raise
