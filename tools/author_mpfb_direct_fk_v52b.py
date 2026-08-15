#!/usr/bin/env python3
"""v52b: rerender the exact v52 direct-FK pose with a valid palm-adjacent vessel fixture.

No pose value changes. This only corrects the diagnostic proxy placement so Macro/Meso
judgment is meaningful.
"""
from __future__ import annotations

import importlib.util
import traceback
from pathlib import Path

import bpy

BASE = Path(__file__).resolve().parent
SPEC = importlib.util.spec_from_file_location("mpfb_direct_fk_v52_base", BASE / "author_mpfb_direct_fk_v52.py")
if SPEC is None or SPEC.loader is None:
    raise RuntimeError("could not load v52")
v52 = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(v52)


def _make_proxy_against_palm(arm):
    # Pure staging geometry: derive a vertical cylinder center from the already-posed palm.
    # This does not mutate the hand or drive any bone.
    center, axis, _inward, _palm = v52.v35._fixture_from_seed(arm, 1.0)
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=64,
        radius=v52.v35.VESSEL_RADIUS,
        depth=v52.v35.VESSEL_DEPTH,
        location=center,
    )
    proxy = bpy.context.object
    proxy.name = "DirectFKV52bVessel"
    mat = bpy.data.materials.new("DirectFKV52bVesselMat")
    mat.diffuse_color = (0.16, 0.22, 0.29, 1.0)
    proxy.data.materials.append(mat)
    return proxy, center


if __name__ == "__main__":
    try:
        v52._make_proxy = _make_proxy_against_palm
        v52.run()
    except BaseException as exc:
        print("MPFB_DIRECT_FK_V52B_ERROR:", exc)
        traceback.print_exc()
        raise
