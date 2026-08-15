"""v33: whole-hand support staging before local finger closure.

Checkpoint 10 rejected v31/v32 because endpoint/contact metrics could pass while the
render still read as a hanging claw. This experiment changes the order of operations:

1. Build a fixed, upright product-equivalent cylinder beside the neutral palm plane.
2. Seed the conservative authored Cup pose.
3. Rigidly translate the whole continuous MPFB limb so the posed palm sits at a
   photographic clearance beside the fixed vessel.
4. Render that whole-hand staging *before* local closure.
5. Treat thumb opposition as a first-class target, then close thumb + four fingers
   locally with the existing bounded 24-degree CCD budget.
6. Render the result from the same camera and log palm clearance, opposition,
   pairwise fingertip spacing and endpoint error.

Two palm-normal signs are rendered because the imported rig does not encode which
side of the derived palm plane should face the product. Visual Macro/Meso review,
not the metric score, chooses/rejects the candidate.

This is a staging/falsification harness only. It does not change production assets.
"""
from __future__ import annotations

import importlib.util
import math
import traceback
from pathlib import Path

import bpy
from mathutils import Vector

BASE = Path(__file__).with_name("render_mpfb_contact_ik_v23.py")
spec = importlib.util.spec_from_file_location("mpfb_v23", BASE)
if spec is None or spec.loader is None:
    raise RuntimeError("could not load v23 contact IK helpers")
v23 = importlib.util.module_from_spec(spec)
spec.loader.exec_module(v23)
v22 = v23.v22
v19 = v23.v19

VESSEL_RADIUS = 0.038
VESSEL_DEPTH = 0.20
PALM_CLEARANCE = 0.014
MAX_ROOT_SHIFT = 0.060
THUMB_ANGLE_DEG = -58.0
MIN_TIP_SPACING = 0.007


def _rigid_translate_limb(arm, delta: Vector) -> None:
    arm.location += delta
    for obj in bpy.context.scene.objects:
        if obj.type != "MESH":
            continue
        driven = any(
            mod.type == "ARMATURE" and getattr(mod, "object", None) == arm
            for mod in obj.modifiers
        )
        if not driven:
            continue
        parent = obj.parent
        descendant = False
        while parent is not None:
            if parent == arm:
                descendant = True
                break
            parent = parent.parent
        if not descendant:
            obj.location += delta
    bpy.context.view_layer.update()


def _palm_frame(arm):
    wrist = v19._wp(arm, "hand_r")
    mcps = [v19._wp(arm, f"{name}_01_r") for name in ("index", "middle", "ring", "pinky")]
    palm = (wrist + sum(mcps, Vector())) / 5.0
    forward = (sum(mcps, Vector()) / len(mcps)) - wrist
    span = mcps[-1] - mcps[0]
    if forward.length < 1e-6 or span.length < 1e-6:
        raise RuntimeError("v33 degenerate palm frame")
    forward.normalize()
    span.normalize()
    normal = forward.cross(span)
    if normal.length < 1e-6:
        raise RuntimeError("v33 degenerate palm normal")
    normal.normalize()
    return palm, forward, span, normal


def _fixed_fixture(arm, sign: float):
    v19._clear(arm)
    bpy.context.view_layer.update()
    palm, _forward, _span, normal = _palm_frame(arm)
    facing = normal * sign
    # Blender is Z-up; keep product geometry independent of hand/forearm vectors.
    axis = Vector((0.0, 0.0, 1.0))
    center = palm + facing * (VESSEL_RADIUS + PALM_CLEARANCE)
    return center, axis, facing, palm


def _proxy(center: Vector, axis: Vector, name: str):
    bpy.ops.mesh.primitive_cylinder_add(vertices=64, radius=VESSEL_RADIUS, depth=VESSEL_DEPTH, location=center)
    obj = bpy.context.object
    obj.name = name
    obj.rotation_euler = axis.to_track_quat("Z", "Y").to_euler()
    obj.data.materials.append(v19._mat(name + "Mat", (0.11, 0.24, 0.34, 1.0), 0.38))
    return obj


def _stage_root(xr, arm, center: Vector, facing: Vector):
    rows = v23._pose_seed(xr, arm, "Cup_Armature")
    posed_palm, _, _, _ = _palm_frame(arm)
    desired_palm = center - facing * (VESSEL_RADIUS + PALM_CLEARANCE)
    raw_delta = desired_palm - posed_palm
    delta = raw_delta.copy()
    if delta.length > MAX_ROOT_SHIFT:
        delta = delta.normalized() * MAX_ROOT_SHIFT
    _rigid_translate_limb(arm, delta)
    print(
        "WHOLE_HAND_V33_ROOT",
        "raw_shift", f"{raw_delta.length:.6f}",
        "applied_shift", f"{delta.length:.6f}",
        "delta", tuple(round(v, 6) for v in delta),
    )
    return rows, delta


def _radial_basis(arm, center: Vector, axis: Vector):
    palm, _, _, _ = _palm_frame(arm)
    axis = axis.normalized()
    near = palm - center
    near -= axis * near.dot(axis)
    if near.length < 1e-6:
        raise RuntimeError("v33 degenerate vessel radial basis")
    near.normalize()
    side = axis.cross(near)
    if side.length < 1e-6:
        raise RuntimeError("v33 degenerate vessel side basis")
    side.normalize()
    return near, side


def _thumb_target(arm, center: Vector, axis: Vector, near: Vector, side: Vector):
    thumb_tip = v19._wp(arm, "thumb_03_r", True)
    axial = (thumb_tip - center).dot(axis)
    axial = max(-0.068, min(0.068, axial))
    angle = math.radians(THUMB_ANGLE_DEG)
    radial = near * math.cos(angle) + side * math.sin(angle)
    return center + radial * VESSEL_RADIUS + axis * axial


def _tip_separation(arm):
    names = ("thumb", "index", "middle", "ring", "pinky")
    pts = {name: v19._wp(arm, f"{name}_03_r", True) for name in names}
    minimum = float("inf")
    pair = None
    for i, a in enumerate(names):
        for b in names[i + 1:]:
            d = (pts[a] - pts[b]).length
            if d < minimum:
                minimum = d
                pair = (a, b)
    return minimum, pair


def _opposition_metrics(arm, center: Vector, axis: Vector, near: Vector):
    def radial_dot(name: str) -> float:
        p = v19._wp(arm, f"{name}_03_r", True) - center
        p -= axis * p.dot(axis)
        if p.length < 1e-6:
            return 0.0
        return p.normalized().dot(near)

    thumb_dot = radial_dot("thumb")
    finger_dots = [radial_dot(name) for name in ("index", "middle", "ring", "pinky")]
    return thumb_dot, finger_dots


def _run_candidate(xr, arm, cam, out, sign: float, camera_target: Vector):
    label = "positive" if sign > 0 else "negative"
    v19._remove_proxies()
    center, axis, facing, _ = _fixed_fixture(arm, sign)
    rows, root_delta = _stage_root(xr, arm, center, facing)
    _proxy(center, axis, f"WholeHandV33Vessel_{label}")

    # Evidence 1: whole-hand/root placement before fingertip optimization.
    focus = camera_target.lerp(center, 0.42)
    v19._render(cam, out, f"whole_hand_v33_{label}_before_closure", focus)

    near, side = _radial_basis(arm, center, axis)
    targets = v23._support_targets(arm, center, VESSEL_RADIUS, axis)
    thumb_target = _thumb_target(arm, center, axis, near, side)
    targets["thumb"] = thumb_target

    results = {}
    chains = dict(v23.SUPPORT_CHAINS)
    chains["thumb"] = v23.PINCH_CHAINS["thumb"]
    for name in ("thumb", "index", "middle", "ring", "pinky"):
        v23._marker(targets[name], "SupportTarget_" + name, (0.10, 0.72, 0.22, 1.0))
        results[name] = v23._ccd_to_target(arm, chains[name], targets[name])

    palm, _, _, _ = _palm_frame(arm)
    palm_radial = palm - center
    palm_radial -= axis * palm_radial.dot(axis)
    palm_clearance = abs(palm_radial.length - VESSEL_RADIUS)
    thumb_dot, finger_dots = _opposition_metrics(arm, center, axis, near)
    min_spacing, closest_pair = _tip_separation(arm)
    target_errors = {name: results[name]["error"] for name in results}
    max_added = max(max(result["added_deg"].values()) for result in results.values())

    print(
        "WHOLE_HAND_V33_RESULT", label,
        "target_errors", {k: round(v, 6) for k, v in target_errors.items()},
        "palm_clearance", f"{palm_clearance:.6f}",
        "thumb_near_dot", f"{thumb_dot:.4f}",
        "finger_near_dots", [round(v, 4) for v in finger_dots],
        "min_tip_spacing", f"{min_spacing:.6f}",
        "closest_pair", closest_pair,
        "root_shift", f"{root_delta.length:.6f}",
        "max_added_deg", f"{max_added:.3f}",
    )

    # Evidence 2: same camera after only local bounded digit closure.
    v19._render(cam, out, f"whole_hand_v33_{label}_after_closure", focus)

    objective_pass = (
        root_delta.length <= MAX_ROOT_SHIFT + 1e-6
        and palm_clearance <= 0.025
        and thumb_dot > 0.15
        and sum(finger_dots) / len(finger_dots) < -0.10
        and min_spacing >= MIN_TIP_SPACING
        and max_added <= v23.CCD_EXTRA_BUDGET_DEG + 1e-3
    )
    print("WHOLE_HAND_V33_OBJECTIVE", label, "PASS" if objective_pass else "REJECT")
    return objective_pass


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

    passes = []
    for sign in (1.0, -1.0):
        passes.append(_run_candidate(xr, mpfb, cam, out, sign, camera_target))

    print("WHOLE_HAND_V33_OBJECTIVE_PASS_COUNT", sum(1 for p in passes if p))
    print("MPFB_WHOLE_HAND_V33_SUCCESS")


if __name__ == "__main__":
    try:
        _run()
    except BaseException as exc:
        print("MPFB_WHOLE_HAND_V33_ERROR:", exc)
        traceback.print_exc()
        raise
