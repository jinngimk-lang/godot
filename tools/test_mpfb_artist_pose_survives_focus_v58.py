#!/usr/bin/env python3
"""Regression contract for the v55/v56 invisible-artist-pose root cause.

The durable pose is restored by ``v49.load_pose``. Nothing after that point may call the
legacy ``v22._neutral_targets`` helper because that helper begins by clearing every MPFB
pose bone. The visual artifact must therefore be rendered from the restored author pose,
not from a hidden neutral reset.

This small source-level gate is paired with v57's evaluated-mesh deformation contract. The
latter proves matrix_basis + durable reload deform skin; this gate prevents the exact
post-reload side effect that erased those deformations before rendering.
"""
from pathlib import Path

PATH = Path(__file__).with_name("author_mpfb_anatomical_controls_v53.py")
text = PATH.read_text(encoding="utf-8")
marker = "v49.load_pose(arm, pose_path)"
if marker not in text:
    raise SystemExit("RED: v53 durable load marker missing")
after_reload = text.split(marker, 1)[1]
if "_neutral_targets(arm)" in after_reload:
    raise SystemExit(
        "RED: artist preview clears its restored pose while computing camera focus via _neutral_targets"
    )
print("MPFB_ARTIST_POSE_SURVIVES_FOCUS_V58_PASS")
