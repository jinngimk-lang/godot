#!/usr/bin/env python3
"""v57: apply the screened Poses02 henny_cyclist_normal direction prior to GameEngine.

v55 proved that source-direction-only transfer is technically safe but its Poses01
wine-glass source was the wrong anatomical prior for a broad cylindrical vessel. v56
screened two official CC0 Poses02 cyclist sources and selected henny_cyclist_normal
because its finger chains visibly contain sustained flexion rather than an open hand.

The safety boundary is identical to v55: only source phalanx direction coefficients
in a palm-local frame are transferred. No source quaternion, matrix_basis, translation,
rest transform, bone roll, scale, topology, weights, or hierarchy may enter the target.
"""
from __future__ import annotations

import importlib.util
import json
import os
import traceback
from pathlib import Path

BASE = Path(__file__).resolve().parent
SPEC = importlib.util.spec_from_file_location(
    "mpfb_source_direction_v55_base_for_v57",
    BASE / "author_mpfb_source_direction_v55.py",
)
if SPEC is None or SPEC.loader is None:
    raise RuntimeError("could not load v55")
v55 = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(v55)


def _enrich_v57_outputs() -> None:
    out_env = os.environ.get("PEEL_V57_OUTDIR", "").strip()
    report_env = os.environ.get("PEEL_V57_REPORT", "").strip()
    pose_env = os.environ.get("PEEL_V57_POSE", "").strip()
    if not out_env or not report_env or not pose_env:
        raise RuntimeError("v57 output/report/pose environment is required")
    out = Path(out_env).resolve()
    report_path = Path(report_env).resolve()
    pose_path = Path(pose_env).resolve()

    renames = {
        out / "anatomical_controls_v53_candidate.png": out / "poses02_henny_v57_candidate.png",
        out / "anatomical_controls_v53_thumbnail.png": out / "poses02_henny_v57_thumbnail.png",
    }
    for old, new in renames.items():
        if not old.is_file():
            raise RuntimeError("v57 expected render missing: " + str(old))
        old.replace(new)

    source = v55._source_reference()
    report = json.loads(report_path.read_text(encoding="utf-8"))
    report.update({
        "staging_only": True,
        "production_candidate": False,
        "automatic_retarget": False,
        "retarget_source_transforms_used": False,
        "source_local_rotations_copied": False,
        "source_matrix_basis_copied": False,
        "source_bone_roll_modified": False,
        "source_direction_coefficients_only": True,
        "source_asset": "MakeHuman Poses02 / henny_cyclist_normal",
        "source_declared_license": "CC0",
        "source_url": "https://files2.makehumancommunity.org/asset_packs/poses02/poses02_cc0.zip",
        "source_bvh_sha256": source["source_bvh_sha256"],
        "source_screening_basis": "v56 source-only render showed sustained flexion across the four finger chains; punkduck_cyclist01 remained visibly more open",
        "visual_gate": "192x108 must immediately read as a human hand enclosing the vessel: opposed thumb, differentiated digit depth, and finger mass disappearing behind the far contour.",
    })
    report_path.write_text(json.dumps(report, indent=2, sort_keys=True), encoding="utf-8")

    pose = json.loads(pose_path.read_text(encoding="utf-8"))
    pose["label"] = "v57 Poses02 Henny source-direction support-wrap staging candidate"
    provenance = dict(pose.get("provenance", {}))
    provenance.update({
        "kind": "cc0-poses02-henny-source-direction-shape-prior",
        "production_candidate": False,
        "automatic_retarget": False,
        "retarget_source_transforms_used": False,
        "source_direction_coefficients_only": True,
        "source_asset": "MakeHuman Poses02 / henny_cyclist_normal",
        "source_bvh_sha256": source["source_bvh_sha256"],
    })
    pose["provenance"] = provenance
    pose_path.write_text(json.dumps(pose, indent=2, sort_keys=True), encoding="utf-8")


if __name__ == "__main__":
    try:
        # Reuse v55's proven direction-coefficient mapping and v53's stable
        # whole-hand placement / persistence / render harness.
        v55.v53._apply_finger_controls = v55._apply_finger_controls
        v55.v53._apply_thumb_controls = v55._apply_thumb_controls
        v55.v53.run()
        _enrich_v57_outputs()
        print("MPFB_POSES02_HENNY_V57_SUCCESS")
    except BaseException as exc:
        print("MPFB_POSES02_HENNY_V57_ERROR:", exc)
        traceback.print_exc()
        raise
