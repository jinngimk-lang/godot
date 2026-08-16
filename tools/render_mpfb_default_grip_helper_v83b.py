#!/usr/bin/env python3
"""v83b evidence-only wrapper.

Runs the frozen v83 semantic grip candidate unchanged, then renders the same baked geometry,
vessel and pose from the already-created oblique camera with the vessel visible. No grip
control, rig, crop, vessel transform, material, or pose value is changed.
"""
from __future__ import annotations

import importlib.util
import sys
from pathlib import Path

import bpy


def main():
    base_path = Path(__file__).with_name("render_mpfb_default_grip_helper_v83.py")
    spec = importlib.util.spec_from_file_location("v83_base", base_path)
    if spec is None or spec.loader is None:
        raise RuntimeError("cannot load frozen v83 script")
    base = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(base)
    base.run()

    if "--" not in sys.argv:
        raise RuntimeError("expected v83 arguments")
    values = sys.argv[sys.argv.index("--") + 1:]
    out = Path(values[1]).resolve()
    vessel = bpy.data.objects.get("DefaultGripHelperV83Vessel")
    cam = bpy.data.objects.get("V83ObliqueCamera")
    if vessel is None or cam is None:
        raise RuntimeError("v83 scene did not preserve vessel/oblique camera")
    vessel.hide_render = False
    base._render(out / "support-grip-helper-v83-vessel-oblique.png", cam, 640, 640)
    base._render(out / "support-grip-helper-v83-vessel-oblique-thumbnail.png", cam, 192, 108)
    print("MPFB_DEFAULT_GRIP_HELPER_V83B_EVIDENCE_SUCCESS")


if __name__ == "__main__":
    main()
