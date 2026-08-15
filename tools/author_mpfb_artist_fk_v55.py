#!/usr/bin/env python3
"""v55: one fixed artist-authored FK support grasp on the continuous MPFB limb.

This is intentionally not a solver and not a sweep. v54 closed the procedural flex-axis
family after another visually green-but-wrong result. v55 keeps the same stable whole-hand
placement / vessel fixture / camera and applies one explicit per-bone local FK pose whose
closure rhythm is art-directed from the locked Peel Calm references and the CC0 MakeHuman
holding-wine-glass pose as anatomy guidance only.

No BVH transform is copied. No target point, distance minimization, CCD, contact servo,
axis inference, coefficient sweep or post-authoring optimizer exists here. The 192x108
silhouette is the promotion gate.
"""
from __future__ import annotations

import importlib.util
import json
import math
import traceback
from pathlib import Path

import bpy
from mathutils import Euler, Matrix

BASE = Path(__file__).resolve().parent
SPEC = importlib.util.spec_from_file_location("mpfb_v53_for_artist_v55", BASE / "author_mpfb_anatomical_controls_v53.py")
if SPEC is None or SPEC.loader is None:
    raise RuntimeError("could not load v53 base")
v53 = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(v53)

# One hand-authored pose, not a search grid. Degrees are additive local FK rotations on
# the current GameEngine pose bones after canonical whole-hand placement. The closure
# rhythm deliberately leaves index less closed and progressively deepens middle/ring/pinky,
# matching the broad anatomy pattern seen in the CC0 holding-object reference without
# copying its transforms.
ARTIST_LOCAL_DEG = {
    "index_01_r":  ( 0.0,  0.0, 18.0),
    "index_02_r":  ( 0.0,  0.0, 28.0),
    "index_03_r":  ( 0.0,  0.0, 18.0),
    "middle_01_r": (-2.0,  0.0, 26.0),
    "middle_02_r": ( 0.0,  0.0, 40.0),
    "middle_03_r": ( 0.0,  0.0, 30.0),
    "ring_01_r":   (-4.0,  0.0, 30.0),
    "ring_02_r":   ( 0.0,  0.0, 50.0),
    "ring_03_r":   ( 0.0,  0.0, 38.0),
    "pinky_01_r":  (-7.0,  0.0, 32.0),
    "pinky_02_r":  ( 0.0,  0.0, 54.0),
    "pinky_03_r":  ( 0.0,  0.0, 42.0),
}

# Thumb is authored independently as the opponent. It crosses the palm more strongly at
# the base, then curls through the distal chain. This is intentionally asymmetric with the
# four fingers.
THUMB_LOCAL_DEG = {
    "thumb_01_r": (18.0, -34.0, 18.0),
    "thumb_02_r": (10.0, -16.0, 24.0),
    "thumb_03_r": ( 6.0,  -8.0, 20.0),
}


def _apply_local_euler(arm, bone_name: str, xyz_deg) -> None:
    pb = arm.pose.bones.get(bone_name)
    if pb is None:
        raise RuntimeError("missing v55 bone " + bone_name)
    e = Euler(tuple(math.radians(float(v)) for v in xyz_deg), "XYZ")
    # Post-multiply: explicit artist delta in the pose bone's local basis. No inferred axis.
    pb.matrix_basis = pb.matrix_basis @ e.to_matrix().to_4x4()
    bpy.context.view_layer.update()


def _apply_artist_fingers(arm, _span, _normal) -> dict:
    for bone_name, xyz in ARTIST_LOCAL_DEG.items():
        _apply_local_euler(arm, bone_name, xyz)
    return {
        digit: {
            "semantic": "fixed artist-authored local FK; no solver/search",
            "joints": [
                {"bone": f"{digit}_0{i}_r", "xyz_deg": list(ARTIST_LOCAL_DEG[f"{digit}_0{i}_r"])}
                for i in (1, 2, 3)
            ],
        }
        for digit in ("index", "middle", "ring", "pinky")
    }


def _apply_artist_thumb(arm, _forward, _span, _normal) -> dict:
    for bone_name, xyz in THUMB_LOCAL_DEG.items():
        _apply_local_euler(arm, bone_name, xyz)
    return {
        "semantic": "fixed artist-authored independent thumb opposition",
        "joints": [
            {"bone": name, "xyz_deg": list(THUMB_LOCAL_DEG[name])}
            for name in ("thumb_01_r", "thumb_02_r", "thumb_03_r")
        ],
    }


if __name__ == "__main__":
    try:
        v53._apply_finger_controls = _apply_artist_fingers
        v53._apply_thumb_controls = _apply_artist_thumb
        original_run = v53.run
        original_run()
        print("MPFB_ARTIST_FK_V55_SUCCESS")
    except BaseException as exc:
        print("MPFB_ARTIST_FK_V55_ERROR:", exc)
        traceback.print_exc()
        raise
