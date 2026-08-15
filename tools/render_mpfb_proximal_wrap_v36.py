"""v36: keep v35 whole-hand orientation, change only local digit closure order.

Visual review of v35 accepted the structural whole-hand orientation but rejected the
final grip: four fingers remained long parallel tines and the thumb curled underneath.
The falsifiable hypothesis for v36 is that v23/v35 distal-first CCD spends too much of
its bounded correction at distal joints before the MCP/proximal joints have wrapped
the digits around the cylinder.

This experiment preserves v35's vertical vessel, palm/root placement, canonical frame,
wrap targets, camera, seed pose, and 24-degree per-bone budget. The only changed axis is
solver choreography: each digit receives a proximal->distal pass before a short
proximal->distal refinement loop. Macro/Meso render evidence remains authoritative.
"""
from __future__ import annotations

import importlib.util
import math
import traceback
from pathlib import Path

import bpy
from mathutils import Vector

V35_PATH = Path(__file__).with_name("render_mpfb_canonical_grip_v35.py")
spec = importlib.util.spec_from_file_location("mpfb_v35", V35_PATH)
if spec is None or spec.loader is None:
    raise RuntimeError("could not load v35 helpers")
v35 = importlib.util.module_from_spec(spec)
spec.loader.exec_module(v35)
v23 = v35.v23
v21 = v23.v21

# Preserve the v35 anatomical correction ceiling. We only redistribute when it is spent.
BUDGET_DEG = v23.CCD_EXTRA_BUDGET_DEG
STEP_CAP_DEG = 6.0
ITERATIONS = 10


def _proximal_first_to_target(arm, chain, target_world: Vector):
    added_deg = {name: 0.0 for name in chain}
    history = []
    for iteration in range(ITERATIONS):
        before = (v23._tip_world(arm, chain) - target_world).length
        if before <= v23.CONTACT_TOLERANCE:
            break
        # Critical v36 difference: MCP/proximal -> intermediate -> distal.
        for bone_name in chain:
            pb = arm.pose.bones.get(bone_name)
            if pb is None:
                raise RuntimeError("missing v36 pose bone " + bone_name)
            remaining = BUDGET_DEG - added_deg[bone_name]
            if remaining <= 1e-4:
                continue
            joint_local = pb.head.copy()
            tip_local = v23._arm_local(arm, v23._tip_world(arm, chain))
            target_local = v23._arm_local(arm, target_world)
            current = tip_local - joint_local
            desired = target_local - joint_local
            if current.length < 1e-7 or desired.length < 1e-7:
                continue
            raw_q = current.normalized().rotation_difference(desired.normalized())
            cap = min(STEP_CAP_DEG, remaining)
            applied_q = v23._scaled_to_cap(raw_q, cap)
            applied_deg = math.degrees(applied_q.angle)
            if applied_deg < 1e-4:
                continue
            v21._rotate_pose_bone_armature_space(pb, applied_q)
            added_deg[bone_name] += applied_deg
            bpy.context.view_layer.update()
        after = (v23._tip_world(arm, chain) - target_world).length
        history.append((iteration, before, after))
        if abs(before - after) < 1e-5:
            break
    return {
        "error": (v23._tip_world(arm, chain) - target_world).length,
        "added_deg": added_deg,
        "history": history,
    }


def _close_digits(arm, targets):
    chains = dict(v23.SUPPORT_CHAINS)
    chains["thumb"] = v23.PINCH_CHAINS["thumb"]
    results = {}
    for digit in ("thumb", "index", "middle", "ring", "pinky"):
        results[digit] = _proximal_first_to_target(arm, chains[digit], targets[digit])
    return results


def _run_candidate(xr, arm, cam, out: Path, sign: float, camera_target: Vector):
    label = "positive" if sign > 0 else "negative"
    v35.v19._clear(arm)
    v23._pose_seed(xr, arm, "Cup_Armature")
    center, axis, inward, _ = v35._fixture_from_seed(arm, sign)
    proxy = v35.v33._proxy(center, axis, f"WholeHandV36Vessel_{label}")
    focus = camera_target.lerp(center, 0.42)

    v35.v19._render(cam, out, f"proximal_wrap_v36_{label}_seed", focus)
    rotation_deg, root_shift = v35._orient_whole_hand(arm, center, axis, inward)
    v35.v19._render(cam, out, f"proximal_wrap_v36_{label}_oriented", focus)

    targets = v35._wrap_targets(arm, center, axis)
    results = _close_digits(arm, targets)
    v35._cleanup()
    proxy = v35.v33._proxy(center, axis, f"WholeHandV36Vessel_{label}")
    v35.v19._render(cam, out, f"proximal_wrap_v36_{label}_closed", focus)

    passed = v35._screen(arm, center, axis, inward, results, rotation_deg, root_shift)
    print("PROXIMAL_WRAP_V36_OBJECTIVE", label, "PASS" if passed else "REJECT")
    print("PROXIMAL_WRAP_V36_ADDED", label, {
        digit: {bone: round(deg, 3) for bone, deg in result["added_deg"].items()}
        for digit, result in results.items()
    })
    bpy.data.objects.remove(proxy, do_unlink=True)
    return passed


def _run():
    xr_path, mpfb_path, out = v35.v19._args()
    out.mkdir(parents=True, exist_ok=True)
    v35.v19._reset()
    xr, xr_meshes = v35.v19._import_armature(xr_path, "XR")
    for mesh in xr_meshes:
        mesh.hide_render = True
        mesh.hide_viewport = True
    arm, meshes = v35.v19._import_armature(mpfb_path, "MPFB")
    cam = v35.v19._setup_render(meshes)
    _, _, _, _, camera_target = v35.v22._neutral_targets(arm)
    baseline = v35._snapshot_world(arm)

    passes = []
    for sign in (1.0, -1.0):
        v35._restore_world(arm, baseline)
        passes.append(_run_candidate(xr, arm, cam, out, sign, camera_target))

    v35._restore_world(arm, baseline)
    print("PROXIMAL_WRAP_V36_OBJECTIVE_PASS_COUNT", sum(1 for passed in passes if passed))
    print("MPFB_PROXIMAL_WRAP_V36_SUCCESS")


if __name__ == "__main__":
    try:
        _run()
    except BaseException as exc:
        print("MPFB_PROXIMAL_WRAP_V36_ERROR:", exc)
        traceback.print_exc()
        raise
