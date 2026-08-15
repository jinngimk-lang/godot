"""v35: canonical whole-hand frame + explicit cylindrical wrap targets.

v34 established that whole-hand orientation is the first structural step that visibly
improves the support-hand silhouette, but it also exposed two frame-definition bugs:

* the derived palm normal was used as a vessel radial even when it contained a large
  vertical component, so the target frame was not orthogonal to the vertical vessel;
* v34 forced the anatomical index->pinky span toward +Z. For a natural upright bottle
  grip the index is above the pinky, so index->pinky should point down (-Z).

This experiment fixes those structural definitions and then replaces the old endpoint-
following support targets with explicit wrap arcs. The entire hand is oriented first;
only then may bounded digit CCD curl the tips around the cylinder.

Primary evidence is seed -> canonical-oriented -> closed from the same camera. Numeric
gates only screen obvious failures; Macro/Meso visual review remains authoritative.
"""
from __future__ import annotations

import importlib.util
import math
import traceback
from pathlib import Path

import bpy
from mathutils import Matrix, Vector

V34_PATH = Path(__file__).with_name("render_mpfb_whole_hand_orient_v34.py")
spec = importlib.util.spec_from_file_location("mpfb_v34", V34_PATH)
if spec is None or spec.loader is None:
    raise RuntimeError("could not load v34 helpers")
v34 = importlib.util.module_from_spec(spec)
spec.loader.exec_module(v34)
v33 = v34.v33
v23 = v34.v23
v22 = v34.v22
v19 = v34.v19

VESSEL_RADIUS = v34.VESSEL_RADIUS
VESSEL_DEPTH = v34.VESSEL_DEPTH
PALM_CLEARANCE = v34.PALM_CLEARANCE
MAX_ROOT_SHIFT = 0.065
MAX_WHOLE_ROTATION_DEG = 125.0
MIN_TIP_SPACING = 0.007
SURFACE_CLEARANCE = 0.0015

# Thumb opposes the four fingers. Finger angles are deliberately ordered so the
# silhouette reads as a progressive wrap rather than four coincident endpoints.
WRAP_ANGLE_DEG = {
    "thumb": -55.0,
    "index": 102.0,
    "middle": 112.0,
    "ring": 120.0,
    "pinky": 126.0,
}


def _cleanup() -> None:
    for obj in list(bpy.data.objects):
        if (
            obj.name.startswith("WholeHandV35Vessel_")
            or obj.name.startswith("SupportTarget_")
            or obj.name.startswith("PinchTarget_")
        ):
            bpy.data.objects.remove(obj, do_unlink=True)
    v19._remove_proxies()


def _snapshot_world(arm):
    return {
        "arm": arm.matrix_world.copy(),
        "meshes": {mesh.name: mesh.matrix_world.copy() for mesh in v34._driven_meshes(arm)},
    }


def _restore_world(arm, snapshot) -> None:
    _cleanup()
    v19._clear(arm)
    arm.matrix_world = snapshot["arm"].copy()
    for name, matrix in snapshot["meshes"].items():
        mesh = bpy.data.objects.get(name)
        if mesh is not None:
            mesh.matrix_world = matrix.copy()
    bpy.context.view_layer.update()


def _fixture_from_seed(arm, sign: float):
    palm, _forward, _span, normal = v33._palm_frame(arm)
    axis = Vector((0.0, 0.0, 1.0))
    # A cylindrical radial must be perpendicular to the cylinder axis.
    inward = normal - axis * normal.dot(axis)
    if inward.length < 1e-6:
        raise RuntimeError("v35 palm normal has no horizontal radial component")
    inward.normalize()
    inward *= sign
    center = palm + inward * (VESSEL_RADIUS + PALM_CLEARANCE)
    return center, axis, inward, palm


def _canonical_frame(axis: Vector, inward: Vector):
    axis = axis.normalized()
    inward = inward.normalized()
    # Anatomical span is index MCP -> pinky MCP. Index should be above pinky.
    span = -axis
    forward = span.cross(inward)
    if forward.length < 1e-6:
        raise RuntimeError("v35 degenerate canonical forward")
    forward.normalize()
    # f x span == inward by construction.
    return forward, span, inward


def _orient_whole_hand(arm, center: Vector, axis: Vector, inward: Vector):
    palm, forward, span, normal = v33._palm_frame(arm)
    dst_forward, dst_span, dst_normal = _canonical_frame(axis, inward)
    rotation = v34._rotation_between_frames(
        forward, span, normal,
        dst_forward, dst_span, dst_normal,
    )
    rotation_deg = v34._angle_deg(rotation)
    v34._rigid_world_transform(arm, v34._transform_about_pivot(rotation, palm))

    posed_palm, _, _, _ = v33._palm_frame(arm)
    desired_palm = center - inward * (VESSEL_RADIUS + PALM_CLEARANCE)
    delta = desired_palm - posed_palm
    if delta.length > MAX_ROOT_SHIFT:
        delta = delta.normalized() * MAX_ROOT_SHIFT
    v34._rigid_world_transform(arm, Matrix.Translation(delta))

    print(
        "CANONICAL_GRIP_V35_STAGE",
        "rotation_deg", f"{rotation_deg:.3f}",
        "root_shift", f"{delta.length:.6f}",
        "dst_forward", tuple(round(v, 5) for v in dst_forward),
        "dst_span", tuple(round(v, 5) for v in dst_span),
        "dst_normal", tuple(round(v, 5) for v in dst_normal),
    )
    return rotation_deg, delta.length


def _wrap_basis(arm, center: Vector, axis: Vector):
    palm, forward, _span, _normal = v33._palm_frame(arm)
    near = palm - center
    near -= axis * near.dot(axis)
    if near.length < 1e-6:
        raise RuntimeError("v35 degenerate near radial")
    near.normalize()
    side = forward - axis * forward.dot(axis) - near * forward.dot(near)
    if side.length < 1e-6:
        side = axis.cross(near)
    side.normalize()
    # Keep side aligned with anatomical palm-forward direction.
    if side.dot(forward) < 0.0:
        side *= -1.0
    return near, side


def _bone_tip(arm, digit: str) -> Vector:
    return v19._wp(arm, f"{digit}_03_r", True)


def _wrap_targets(arm, center: Vector, axis: Vector):
    near, side = _wrap_basis(arm, center, axis)
    radius = VESSEL_RADIUS + SURFACE_CLEARANCE
    targets = {}
    for digit, angle_deg in WRAP_ANGLE_DEG.items():
        tip = _bone_tip(arm, digit)
        axial = (tip - center).dot(axis)
        axial = max(-VESSEL_DEPTH * 0.40, min(VESSEL_DEPTH * 0.40, axial))
        angle = math.radians(angle_deg)
        radial = near * math.cos(angle) + side * math.sin(angle)
        targets[digit] = center + radial * radius + axis * axial
    return targets


def _close_digits(arm, targets):
    chains = dict(v23.SUPPORT_CHAINS)
    chains["thumb"] = v23.PINCH_CHAINS["thumb"]
    results = {}
    for digit in ("thumb", "index", "middle", "ring", "pinky"):
        results[digit] = v23._ccd_to_target(arm, chains[digit], targets[digit])
    return results


def _screen(arm, center: Vector, axis: Vector, inward: Vector, results, rotation_deg: float, root_shift: float):
    palm, forward, span, normal = v33._palm_frame(arm)
    to_center = center - palm
    to_center -= axis * to_center.dot(axis)
    normal_alignment = 0.0 if to_center.length < 1e-6 else normal.normalized().dot(to_center.normalized())
    span_down_alignment = span.normalized().dot((-axis).normalized())
    forward_vertical = abs(forward.normalized().dot(axis.normalized()))

    palm_radial = palm - center
    palm_radial -= axis * palm_radial.dot(axis)
    palm_clearance = abs(palm_radial.length - VESSEL_RADIUS)
    min_spacing, closest_pair = v33._tip_separation(arm)
    max_added = max(max(result["added_deg"].values()) for result in results.values())
    errors = {name: result["error"] for name, result in results.items()}

    near, _side = _wrap_basis(arm, center, axis)
    thumb_dot, finger_dots = v33._opposition_metrics(arm, center, axis, near)

    print(
        "CANONICAL_GRIP_V35_RESULT",
        "target_errors", {k: round(v, 6) for k, v in errors.items()},
        "palm_clearance", f"{palm_clearance:.6f}",
        "normal_alignment", f"{normal_alignment:.4f}",
        "span_down_alignment", f"{span_down_alignment:.4f}",
        "forward_vertical", f"{forward_vertical:.4f}",
        "thumb_near_dot", f"{thumb_dot:.4f}",
        "finger_near_dots", [round(v, 4) for v in finger_dots],
        "min_tip_spacing", f"{min_spacing:.6f}",
        "closest_pair", closest_pair,
        "whole_rotation_deg", f"{rotation_deg:.3f}",
        "root_shift", f"{root_shift:.6f}",
        "max_added_deg", f"{max_added:.3f}",
    )

    return (
        rotation_deg <= MAX_WHOLE_ROTATION_DEG
        and root_shift <= MAX_ROOT_SHIFT + 1e-6
        and palm_clearance <= 0.025
        and normal_alignment >= 0.90
        and span_down_alignment >= 0.90
        and forward_vertical <= 0.20
        and min_spacing >= MIN_TIP_SPACING
        and max_added <= v23.CCD_EXTRA_BUDGET_DEG + 1e-3
        and max(errors.values()) <= 0.060
    )


def _run_candidate(xr, arm, cam, out: Path, sign: float, camera_target: Vector):
    label = "positive" if sign > 0 else "negative"
    v19._clear(arm)
    v23._pose_seed(xr, arm, "Cup_Armature")
    center, axis, inward, _ = _fixture_from_seed(arm, sign)
    proxy = v33._proxy(center, axis, f"WholeHandV35Vessel_{label}")
    focus = camera_target.lerp(center, 0.42)

    v19._render(cam, out, f"canonical_grip_v35_{label}_seed", focus)
    rotation_deg, root_shift = _orient_whole_hand(arm, center, axis, inward)
    v19._render(cam, out, f"canonical_grip_v35_{label}_oriented", focus)

    targets = _wrap_targets(arm, center, axis)
    results = _close_digits(arm, targets)
    _cleanup()  # keep final visual evidence free of debug marker geometry
    # Re-create only the product fixture after cleanup removed transient proxies.
    proxy = v33._proxy(center, axis, f"WholeHandV35Vessel_{label}")
    v19._render(cam, out, f"canonical_grip_v35_{label}_closed", focus)

    passed = _screen(arm, center, axis, inward, results, rotation_deg, root_shift)
    print("CANONICAL_GRIP_V35_OBJECTIVE", label, "PASS" if passed else "REJECT")
    bpy.data.objects.remove(proxy, do_unlink=True)
    return passed


def _run():
    xr_path, mpfb_path, out = v19._args()
    out.mkdir(parents=True, exist_ok=True)
    v19._reset()
    xr, xr_meshes = v19._import_armature(xr_path, "XR")
    for mesh in xr_meshes:
        mesh.hide_render = True
        mesh.hide_viewport = True
    arm, meshes = v19._import_armature(mpfb_path, "MPFB")
    cam = v19._setup_render(meshes)
    _, _, _, _, camera_target = v22._neutral_targets(arm)
    baseline = _snapshot_world(arm)

    passes = []
    for sign in (1.0, -1.0):
        _restore_world(arm, baseline)
        passes.append(_run_candidate(xr, arm, cam, out, sign, camera_target))

    _restore_world(arm, baseline)
    print("CANONICAL_GRIP_V35_OBJECTIVE_PASS_COUNT", sum(1 for passed in passes if passed))
    print("MPFB_CANONICAL_GRIP_V35_SUCCESS")


if __name__ == "__main__":
    try:
        _run()
    except BaseException as exc:
        print("MPFB_CANONICAL_GRIP_V35_ERROR:", exc)
        traceback.print_exc()
        raise
