#!/usr/bin/env python3
"""v56: one fixed anatomy-guided tri-axis artist FK support grasp.

v55 was a genuine fixed FK candidate but its almost-pure local-Z finger deltas rendered
as a flat/open hand beside the vessel. v56 changes only the authored pose table: the
continuous MPFB GameEngine limb, whole-hand placement, vessel fixture, camera, durable
17-bone pose format and no-solver contract remain unchanged.

The table is deliberately hand-authored as one candidate. It uses rounded, art-directed
multi-axis local deltas informed by the qualitative joint rhythm visible in the locked Peel
Calm references and the CC0 MakeHuman holding-object anatomy study. No BVH transform is
copied or retargeted; there is no target point, optimizer, CCD, contact servo, axis inference,
coefficient sweep or post-authoring solver. Promotion is decided by the 192x108 silhouette.
"""
from __future__ import annotations

import importlib.util
import math
import traceback
from pathlib import Path

import bpy
from mathutils import Euler

BASE = Path(__file__).resolve().parent
SPEC = importlib.util.spec_from_file_location(
    "mpfb_v53_for_artist_v56", BASE / "author_mpfb_anatomical_controls_v53.py"
)
if SPEC is None or SPEC.loader is None:
    raise RuntimeError("could not load v53 base")
v53 = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(v53)

# A single explicit tri-axis artist table. Compared with v55, proximal and intermediate
# joints receive substantial X/Y components so closure is no longer delegated to local Z.
# Index remains lightest while middle/ring/pinky progressively deepen to create depth
# ordering and encourage distal portions to disappear behind the far vessel contour.
ARTIST_LOCAL_DEG = {
    "index_01_r":  (  6.0, -16.0,  -8.0),
    "index_02_r":  ( 20.0, -18.0,  12.0),
    "index_03_r":  ( 16.0, -14.0,  10.0),
    "middle_01_r": ( 14.0, -20.0,  10.0),
    "middle_02_r": ( 32.0, -28.0,  24.0),
    "middle_03_r": ( 26.0, -22.0,  20.0),
    "ring_01_r":   ( 10.0, -22.0,  14.0),
    "ring_02_r":   ( 40.0, -32.0,  30.0),
    "ring_03_r":   ( 30.0, -26.0,  24.0),
    "pinky_01_r":  (  4.0, -24.0,  16.0),
    "pinky_02_r":  ( 44.0, -34.0,  32.0),
    "pinky_03_r":  ( 34.0, -28.0,  26.0),
}

# Thumb is authored independently. The base crosses toward the finger side while the
# second/third phalanges curl into a visible opponent rather than following the four-finger
# closure rhythm.
THUMB_LOCAL_DEG = {
    "thumb_01_r": ( 10.0,  24.0, -22.0),
    "thumb_02_r": ( 18.0,  12.0, -18.0),
    "thumb_03_r": ( 14.0,   8.0, -14.0),
}


def _apply_local_euler(arm, bone_name: str, xyz_deg) -> None:
    pb = arm.pose.bones.get(bone_name)
    if pb is None:
        raise RuntimeError("missing v56 bone " + bone_name)
    e = Euler(tuple(math.radians(float(v)) for v in xyz_deg), "XYZ")
    pb.matrix_basis = pb.matrix_basis @ e.to_matrix().to_4x4()
    bpy.context.view_layer.update()


def _apply_artist_fingers(arm, _span, _normal) -> dict:
    for bone_name, xyz in ARTIST_LOCAL_DEG.items():
        _apply_local_euler(arm, bone_name, xyz)
    return {
        digit: {
            "semantic": "fixed anatomy-guided tri-axis artist FK; no solver/search",
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
        "semantic": "fixed anatomy-guided independent thumb opposition",
        "joints": [
            {"bone": name, "xyz_deg": list(THUMB_LOCAL_DEG[name])}
            for name in ("thumb_01_r", "thumb_02_r", "thumb_03_r")
        ],
    }


if __name__ == "__main__":
    try:
        v53._apply_finger_controls = _apply_artist_fingers
        v53._apply_thumb_controls = _apply_artist_thumb
        v53.run()
        print("MPFB_ARTIST_FK_V56_SUCCESS")
    except BaseException as exc:
        print("MPFB_ARTIST_FK_V56_ERROR:", exc)
        traceback.print_exc()
        raise
