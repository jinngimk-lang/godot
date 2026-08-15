"""Evidence-integrity wrapper for v34 whole-hand orientation.

The four structural candidates must start from exactly the same imported armature and
skin-mesh world transforms. v34's rigid whole-limb transform intentionally moves
unparented armature-driven meshes as well as the armature, so simply resetting the
armature object's location/rotation/scale is not sufficient between candidates.

This wrapper snapshots all relevant world matrices once after import, restores them
before every candidate, clears bone pose/proxy state, and then delegates to the v34
candidate implementation. It prevents candidate-order contamination without changing
the orientation hypothesis or its visual/numeric gates.
"""
from __future__ import annotations

import importlib.util
import traceback
from pathlib import Path

import bpy

BASE = Path(__file__).with_name("render_mpfb_whole_hand_orient_v34.py")
spec = importlib.util.spec_from_file_location("mpfb_v34", BASE)
if spec is None or spec.loader is None:
    raise RuntimeError("could not load v34 whole-hand orientation helpers")
v34 = importlib.util.module_from_spec(spec)
spec.loader.exec_module(v34)
v33 = v34.v33
v22 = v34.v22
v19 = v34.v19


def _snapshot_world(arm):
    return {
        "arm": arm.matrix_world.copy(),
        "meshes": {mesh.name: mesh.matrix_world.copy() for mesh in v34._driven_meshes(arm)},
    }


def _restore_world(arm, snapshot) -> None:
    v33._remove_v33_objects()
    v34._clean_targets()
    v19._remove_proxies()
    v19._clear(arm)
    arm.matrix_world = snapshot["arm"].copy()
    for name, matrix in snapshot["meshes"].items():
        mesh = bpy.data.objects.get(name)
        if mesh is not None:
            mesh.matrix_world = matrix.copy()
    bpy.context.view_layer.update()


def _run():
    xr_path, mpfb_path, out = v19._args()
    out.mkdir(parents=True, exist_ok=True)
    v19._reset()
    xr, xr_meshes = v19._import_armature(xr_path, "XR")
    for mesh in xr_meshes:
        mesh.hide_render = True
        mesh.hide_viewport = True
    mpfb, meshes = v19._import_armature(mpfb_path, "MPFB")
    cam = v19._setup_render(meshes)
    _, _, _, _, camera_target = v22._neutral_targets(mpfb)
    baseline = _snapshot_world(mpfb)

    passes = []
    for sign in (1.0, -1.0):
        for tangent_sign in (1.0, -1.0):
            _restore_world(mpfb, baseline)
            passes.append(v34._run_candidate(xr, mpfb, cam, out, sign, tangent_sign, camera_target))

    _restore_world(mpfb, baseline)
    print("WHOLE_HAND_V34_OBJECTIVE_PASS_COUNT", sum(1 for passed in passes if passed))
    print("MPFB_WHOLE_HAND_V34_SUCCESS")


if __name__ == "__main__":
    try:
        _run()
    except BaseException as exc:
        print("MPFB_WHOLE_HAND_V34_ERROR:", exc)
        traceback.print_exc()
        raise
