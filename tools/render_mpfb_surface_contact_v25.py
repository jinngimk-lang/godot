"""v25: visible-surface contact gate for MPFB support/pinch preview.

v24 tightened the bone-tail pinch gate and correctly rejected a 15.5 mm thumb/index
bone-tip gap, but the rendered evidence exposed a more important falsification:
small distal-bone errors do not guarantee that the *visible skinned fingertip surface*
contacts the flap. The MPFB distal bones end inside the fleshy fingertip, so validating
only bone tails can produce numerically attractive but visibly detached contact.

This experiment keeps the proven v23 bounded_60 morphology seed and 24-degree total
per-joint CCD budget, but derives each pinch CCD target from the evaluated skinned
mesh surface influenced by the distal digit bone. The target compensates for the
current bone-tail-to-surface offset so that the visible fingertip, not the skeleton
endpoint, is driven onto opposite faces of the fixed paper flap.

Winning condition is deliberately stricter and visual-first:
- support remains the unchanged v23 vessel-wrap control;
- evaluated index/thumb surface points must each be <= 6 mm from their fixed flap
  face target and <= 9 mm from the flap center;
- the two visible surface points must close to <= 10 mm;
- the run still renders evidence for direct Macro/Meso inspection.

This is a staging falsification harness, not production runtime IK.
"""
from __future__ import annotations

import importlib.util
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

SURFACE_WEIGHT_MIN = 0.20
SURFACE_TARGET_HALF_GAP = 0.0015
SURFACE_TARGET_TOLERANCE = 0.006
SURFACE_CENTER_TOLERANCE = 0.009
SURFACE_GAP_TOLERANCE = 0.010
PINCH_BONE_STOP_TOLERANCE = 0.004


def _remove_contact_markers() -> None:
    for obj in list(bpy.data.objects):
        if obj.name.startswith("SupportTarget_") or obj.name.startswith("PinchTarget_"):
            bpy.data.objects.remove(obj, do_unlink=True)


def _weighted_surface_point(bone_name: str, target_world: Vector) -> Vector:
    """Return the evaluated visible vertex influenced by bone_name nearest target."""
    depsgraph = bpy.context.evaluated_depsgraph_get()
    best_point = None
    best_distance = float("inf")
    matched = 0

    for obj in bpy.context.scene.objects:
        if obj.type != "MESH":
            continue
        group = obj.vertex_groups.get(bone_name)
        if group is None:
            continue
        group_index = group.index
        evaluated_obj = obj.evaluated_get(depsgraph)
        evaluated_mesh = evaluated_obj.to_mesh()
        try:
            for vertex in evaluated_mesh.vertices:
                weight = 0.0
                for membership in vertex.groups:
                    if membership.group == group_index:
                        weight = membership.weight
                        break
                if weight < SURFACE_WEIGHT_MIN:
                    continue
                matched += 1
                world = evaluated_obj.matrix_world @ vertex.co
                distance = (world - target_world).length
                if distance < best_distance:
                    best_distance = distance
                    best_point = world.copy()
        finally:
            evaluated_obj.to_mesh_clear()

    if best_point is None:
        raise RuntimeError(
            f"no evaluated surface vertices with weight >= {SURFACE_WEIGHT_MIN} for {bone_name}"
        )
    print("SURFACE_CONTACT_V25_SAMPLE", bone_name, "matched", matched, "nearest", f"{best_distance:.6f}")
    return best_point


def _surface_targets(mpfb, flap_center: Vector):
    index_surface = _weighted_surface_point("index_03_r", flap_center)
    thumb_surface = _weighted_surface_point("thumb_03_r", flap_center)
    separation = index_surface - thumb_surface
    if separation.length < 1e-6:
        separation = v19._wp(mpfb, "index_03_r", True) - v19._wp(mpfb, "thumb_03_r", True)
    if separation.length < 1e-6:
        separation = Vector((1.0, 0.0, 0.0))
    separation.normalize()
    return {
        "index": flap_center + separation * SURFACE_TARGET_HALF_GAP,
        "thumb": flap_center - separation * SURFACE_TARGET_HALF_GAP,
    }


def _surface_corrected_bone_target(mpfb, digit: str, desired_surface: Vector) -> Vector:
    chain = v23.PINCH_CHAINS[digit]
    bone_tail = v19._wp(mpfb, chain[-1], True)
    current_surface = _weighted_surface_point(chain[-1], desired_surface)
    # Preserve the current fleshy fingertip offset relative to the distal bone tail.
    # CCD then moves the skeleton to the point that should place the visible surface
    # on the fixed paper face without extending or scaling the MPFB morphology.
    surface_offset = current_surface - bone_tail
    target = desired_surface - surface_offset
    print(
        "SURFACE_CONTACT_V25_OFFSET",
        digit,
        "surface_offset", tuple(round(v, 6) for v in surface_offset),
        "bone_target", tuple(round(v, 6) for v in target),
    )
    return target


def _run_support(xr, mpfb, cam, out, center, radius, axis, camera_target):
    # Keep the last proven support implementation untouched so this iteration changes
    # only the pinch validation/targeting variable.
    v23.CONTACT_TOLERANCE = 0.014
    return v23._run_support(xr, mpfb, cam, out, center, radius, axis, camera_target)


def _run_pinch(xr, mpfb, cam, out, flap_center, camera_target):
    _remove_contact_markers()
    rows = v23._pose_seed(xr, mpfb, "Pinch Up_Armature")
    v19._remove_proxies()
    v22._paper_proxy(flap_center)

    desired_surface = _surface_targets(mpfb, flap_center)
    results = {}
    v23.CONTACT_TOLERANCE = PINCH_BONE_STOP_TOLERANCE
    for digit in ("index", "thumb"):
        v23._marker(desired_surface[digit], "PinchTarget_" + digit, (0.12, 0.74, 0.24, 1.0))
        corrected_bone_target = _surface_corrected_bone_target(mpfb, digit, desired_surface[digit])
        results[digit] = v23._ccd_to_target(mpfb, v23.PINCH_CHAINS[digit], corrected_bone_target)

    index_surface = _weighted_surface_point("index_03_r", desired_surface["index"])
    thumb_surface = _weighted_surface_point("thumb_03_r", desired_surface["thumb"])
    index_face_error = (index_surface - desired_surface["index"]).length
    thumb_face_error = (thumb_surface - desired_surface["thumb"]).length
    index_center_error = (index_surface - flap_center).length
    thumb_center_error = (thumb_surface - flap_center).length
    visible_gap = (index_surface - thumb_surface).length
    max_added = max(max(result["added_deg"].values()) for result in results.values())

    print(
        "SURFACE_CONTACT_V25_PINCH",
        "face_errors", [round(index_face_error, 6), round(thumb_face_error, 6)],
        "center_errors", [round(index_center_error, 6), round(thumb_center_error, 6)],
        "visible_gap", f"{visible_gap:.6f}",
        "bone_target_errors", [round(results[d]["error"], 6) for d in ("index", "thumb")],
        "max_added_deg", f"{max_added:.3f}",
    )

    # Focus halfway between the hand composition target and real flap so both anatomy
    # and actual surface contact remain visible in the evidence frame.
    pinch_camera_target = camera_target.lerp(flap_center, 0.50)
    v19._render(cam, out, "surface_v25_pinch", pinch_camera_target)

    if max(index_face_error, thumb_face_error) > SURFACE_TARGET_TOLERANCE:
        raise RuntimeError("v25 visible fingertip missed fixed flap-face target")
    if max(index_center_error, thumb_center_error) > SURFACE_CENTER_TOLERANCE:
        raise RuntimeError("v25 visible fingertip remained too far from flap center")
    if visible_gap > SURFACE_GAP_TOLERANCE:
        raise RuntimeError("v25 visible pinch gap exceeds 10 mm")
    return rows, results


def _run() -> None:
    xr_path, mpfb_path, out = v19._args()
    out.mkdir(parents=True, exist_ok=True)
    v19._reset()
    xr, xr_meshes = v19._import_armature(xr_path, "XR")
    for mesh in xr_meshes:
        mesh.hide_render = True
        mesh.hide_viewport = True
    mpfb, meshes = v19._import_armature(mpfb_path, "MPFB")
    cam = v19._setup_render(meshes)
    support_center, support_radius, support_axis, flap_center, camera_target = v22._neutral_targets(mpfb)

    support_target_errors, _, _, _, _ = _run_support(
        xr, mpfb, cam, out, support_center, support_radius, support_axis, camera_target
    )
    if max(support_target_errors) > 0.030:
        raise RuntimeError("v25 support control regressed: " + repr(support_target_errors))

    _run_pinch(xr, mpfb, cam, out, flap_center, camera_target)
    print("MPFB_SURFACE_CONTACT_V25_SUCCESS")


if __name__ == "__main__":
    try:
        _run()
    except BaseException as exc:
        print("MPFB_SURFACE_CONTACT_V25_ERROR:", exc)
        traceback.print_exc()
        raise
