"""v34: orient the whole continuous limb to a real vertical-vessel grasp frame.

v33 falsified translation-only staging: a candidate could pass opposition/contact
metrics while still reading as a hanging claw. The missing structural operation is
whole-hand orientation.

For each palm side candidate this harness:
1. Seeds the conservative authored Cup pose.
2. Freezes a vertical product fixture in world space.
3. Builds a desired grasp frame:
   - palm normal points toward the vessel center;
   - wrist->MCP/palm-forward points around the vessel tangent;
   - index->pinky span therefore runs approximately along the vertical vessel axis.
4. Rigidly rotates the entire extracted hand/wrist/forearm around the palm to that
   frame, then repositions the palm to the fixed photographic clearance.
5. Renders the seed and oriented hand before any fingertip IK.
6. Performs only bounded local digit closure and renders the clean result.

This explicitly tests the "pose the whole hand, then close the fingers" hypothesis.
Primary evidence frames contain no target-marker spheres; numeric targets are logged
only. This is a staging/falsification tool and never mutates production gameplay.
"""
from __future__ import annotations

import importlib.util
import math
import traceback
from pathlib import Path

import bpy
from mathutils import Matrix, Vector

V33_PATH = Path(__file__).with_name("render_mpfb_whole_hand_v33.py")
spec = importlib.util.spec_from_file_location("mpfb_v33", V33_PATH)
if spec is None or spec.loader is None:
    raise RuntimeError("could not load v33 whole-hand helpers")
v33 = importlib.util.module_from_spec(spec)
spec.loader.exec_module(v33)
v23 = v33.v23
v22 = v33.v22
v19 = v33.v19

VESSEL_RADIUS = v33.VESSEL_RADIUS
VESSEL_DEPTH = v33.VESSEL_DEPTH
PALM_CLEARANCE = v33.PALM_CLEARANCE
MAX_ROOT_SHIFT = 0.065
MIN_TIP_SPACING = v33.MIN_TIP_SPACING
MAX_WHOLE_HAND_ROTATION_DEG = 110.0


def _driven_meshes(arm):
    result = []
    for obj in bpy.context.scene.objects:
        if obj.type != "MESH":
            continue
        if any(mod.type == "ARMATURE" and getattr(mod, "object", None) == arm for mod in obj.modifiers):
            result.append(obj)
    return result


def _is_descendant(obj, parent) -> bool:
    node = obj.parent
    while node is not None:
        if node == parent:
            return True
        node = node.parent
    return False


def _rigid_world_transform(arm, transform: Matrix) -> None:
    """Apply a world transform once to the armature and any unparented driven mesh."""
    meshes = _driven_meshes(arm)
    arm.matrix_world = transform @ arm.matrix_world
    for mesh in meshes:
        if not _is_descendant(mesh, arm):
            mesh.matrix_world = transform @ mesh.matrix_world
    bpy.context.view_layer.update()


def _basis_matrix(forward: Vector, span: Vector, normal: Vector) -> Matrix:
    # Matrix constructor takes rows; transpose so our semantic axes become columns.
    return Matrix((forward, span, normal)).transposed()


def _rotation_between_frames(cur_forward: Vector, cur_span: Vector, cur_normal: Vector,
                             dst_forward: Vector, dst_span: Vector, dst_normal: Vector) -> Matrix:
    current = _basis_matrix(cur_forward, cur_span, cur_normal)
    target = _basis_matrix(dst_forward, dst_span, dst_normal)
    return target @ current.transposed()


def _angle_deg(rotation: Matrix) -> float:
    quat = rotation.to_quaternion()
    return math.degrees(abs(quat.angle))


def _transform_about_pivot(rotation3: Matrix, pivot: Vector) -> Matrix:
    r4 = rotation3.to_4x4()
    return Matrix.Translation(pivot) @ r4 @ Matrix.Translation(-pivot)


def _fixture_from_seed(arm, sign: float):
    palm, _forward, _span, normal = v33._palm_frame(arm)
    inward = normal * sign
    center = palm + inward * (VESSEL_RADIUS + PALM_CLEARANCE)
    axis = Vector((0.0, 0.0, 1.0))
    return center, axis, inward, palm


def _desired_grasp_frame(inward: Vector, vessel_axis: Vector, tangent_sign: float):
    inward = inward.normalized()
    vessel_axis = vessel_axis.normalized()
    tangent = vessel_axis.cross(inward)
    if tangent.length < 1e-6:
        raise RuntimeError("v34 degenerate tangent")
    tangent.normalize()
    tangent *= tangent_sign
    span = inward.cross(tangent)
    if span.length < 1e-6:
        raise RuntimeError("v34 degenerate span")
    span.normalize()
    # Ensure span points broadly along +Z for deterministic camera/readability.
    if span.dot(vessel_axis) < 0.0:
        tangent *= -1.0
        span *= -1.0
    return tangent, span, inward


def _place_whole_hand(arm, center: Vector, axis: Vector, inward: Vector, tangent_sign: float):
    palm, forward, span, normal = v33._palm_frame(arm)
    dst_forward, dst_span, dst_normal = _desired_grasp_frame(inward, axis, tangent_sign)
    rotation = _rotation_between_frames(forward, span, normal, dst_forward, dst_span, dst_normal)
    rotation_deg = _angle_deg(rotation)
    _rigid_world_transform(arm, _transform_about_pivot(rotation, palm))

    posed_palm, _, _, _ = v33._palm_frame(arm)
    desired_palm = center - inward * (VESSEL_RADIUS + PALM_CLEARANCE)
    delta = desired_palm - posed_palm
    if delta.length > MAX_ROOT_SHIFT:
        delta = delta.normalized() * MAX_ROOT_SHIFT
    _rigid_world_transform(arm, Matrix.Translation(delta))

    print(
        "WHOLE_HAND_V34_STAGE",
        "rotation_deg", f"{rotation_deg:.3f}",
        "root_shift", f"{delta.length:.6f}",
        "dst_forward", tuple(round(v, 5) for v in dst_forward),
        "dst_span", tuple(round(v, 5) for v in dst_span),
        "dst_normal", tuple(round(v, 5) for v in dst_normal),
    )
    return rotation_deg, delta.length


def _clean_targets() -> None:
    for obj in list(bpy.data.objects):
        if obj.name.startswith("SupportTarget_") or obj.name.startswith("PinchTarget_"):
            bpy.data.objects.remove(obj, do_unlink=True)


def _objective(arm, center: Vector, axis: Vector, inward: Vector, results, rotation_deg: float, root_shift: float):
    palm, forward, span, normal = v33._palm_frame(arm)
    palm_radial = palm - center
    palm_radial -= axis * palm_radial.dot(axis)
    palm_clearance = abs(palm_radial.length - VESSEL_RADIUS)
    min_spacing, closest_pair = v33._tip_separation(arm)
    max_added = max(max(result["added_deg"].values()) for result in results.values())

    normal_to_center = (center - palm)
    normal_to_center -= axis * normal_to_center.dot(axis)
    normal_alignment = 0.0 if normal_to_center.length < 1e-6 else normal.normalized().dot(normal_to_center.normalized())
    span_vertical = abs(span.normalized().dot(axis.normalized()))
    forward_vertical = abs(forward.normalized().dot(axis.normalized()))

    # Opposition is measured around the vessel radial plane after closure.
    near, _side = v33._radial_basis(arm, center, axis)
    thumb_dot, finger_dots = v33._opposition_metrics(arm, center, axis, near)
    target_errors = {name: results[name]["error"] for name in results}

    print(
        "WHOLE_HAND_V34_RESULT",
        "target_errors", {k: round(v, 6) for k, v in target_errors.items()},
        "palm_clearance", f"{palm_clearance:.6f}",
        "normal_alignment", f"{normal_alignment:.4f}",
        "span_vertical", f"{span_vertical:.4f}",
        "forward_vertical", f"{forward_vertical:.4f}",
        "thumb_near_dot", f"{thumb_dot:.4f}",
        "finger_near_dots", [round(v, 4) for v in finger_dots],
        "min_tip_spacing", f"{min_spacing:.6f}",
        "closest_pair", closest_pair,
        "whole_rotation_deg", f"{rotation_deg:.3f}",
        "root_shift", f"{root_shift:.6f}",
        "max_added_deg", f"{max_added:.3f}",
    )

    # These are screening gates. Visual Macro/Meso review remains authoritative.
    return (
        rotation_deg <= MAX_WHOLE_HAND_ROTATION_DEG
        and root_shift <= MAX_ROOT_SHIFT + 1e-6
        and palm_clearance <= 0.025
        and normal_alignment >= 0.80
        and span_vertical >= 0.72
        and forward_vertical <= 0.35
        and min_spacing >= MIN_TIP_SPACING
        and max_added <= v23.CCD_EXTRA_BUDGET_DEG + 1e-3
    )


def _run_candidate(xr, arm, cam, out: Path, sign: float, tangent_sign: float, camera_target: Vector):
    side_label = "positive" if sign > 0 else "negative"
    tangent_label = "cw" if tangent_sign > 0 else "ccw"
    label = f"{side_label}_{tangent_label}"

    v33._remove_v33_objects()
    _clean_targets()
    v19._remove_proxies()
    v19._clear(arm)
    arm.location = Vector((0.0, 0.0, 0.0))
    arm.rotation_euler = (0.0, 0.0, 0.0)
    arm.scale = (1.0, 1.0, 1.0)
    bpy.context.view_layer.update()

    v23._pose_seed(xr, arm, "Cup_Armature")
    center, axis, inward, _seed_palm = _fixture_from_seed(arm, sign)
    proxy = v33._proxy(center, axis, f"WholeHandV34Vessel_{label}")

    focus = camera_target.lerp(center, 0.42)
    v19._render(cam, out, f"whole_hand_v34_{label}_seed", focus)

    rotation_deg, root_shift = _place_whole_hand(arm, center, axis, inward, tangent_sign)
    v19._render(cam, out, f"whole_hand_v34_{label}_oriented", focus)

    near, side = v33._radial_basis(arm, center, axis)
    targets = v23._support_targets(arm, center, VESSEL_RADIUS, axis)
    targets["thumb"] = v33._thumb_target(arm, center, axis, near, side)
    chains = dict(v23.SUPPORT_CHAINS)
    chains["thumb"] = v23.PINCH_CHAINS["thumb"]
    results = {}
    for name in ("thumb", "index", "middle", "ring", "pinky"):
        results[name] = v23._ccd_to_target(arm, chains[name], targets[name])

    _clean_targets()
    v19._render(cam, out, f"whole_hand_v34_{label}_closed", focus)
    passed = _objective(arm, center, axis, inward, results, rotation_deg, root_shift)
    print("WHOLE_HAND_V34_OBJECTIVE", label, "PASS" if passed else "REJECT")

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
    mpfb, meshes = v19._import_armature(mpfb_path, "MPFB")
    cam = v19._setup_render(meshes)
    _, _, _, _, camera_target = v22._neutral_targets(mpfb)

    passes = []
    # Both palm sides and both tangent directions are structural candidates, not
    # parameter tuning. The camera evidence decides which orientation is plausible.
    for sign in (1.0, -1.0):
        for tangent_sign in (1.0, -1.0):
            passes.append(_run_candidate(xr, mpfb, cam, out, sign, tangent_sign, camera_target))

    print("WHOLE_HAND_V34_OBJECTIVE_PASS_COUNT", sum(1 for p in passes if p))
    print("MPFB_WHOLE_HAND_V34_SUCCESS")


if __name__ == "__main__":
    try:
        _run()
    except BaseException as exc:
        print("MPFB_WHOLE_HAND_V34_ERROR:", exc)
        traceback.print_exc()
        raise
