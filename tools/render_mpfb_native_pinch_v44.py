"""v44: native MPFB FingerHelpers label-flap pinch staging.

R1 support-wrap finally passed structural Macro/Meso in v42/v43 using MPFB's POINT
finger helpers. v44 tests the same pose authority for R2: thumb/index converge on an
actual lifted paper flap while middle/ring/pinky retain a relaxed anatomical curl.
No direct deform-bone rotations or endpoint optimizer are used.
"""
from __future__ import annotations

import importlib.util
import traceback
from pathlib import Path

import bpy
from mathutils import Vector

V43_PATH = Path(__file__).with_name("render_mpfb_product_camera_v43.py")
spec = importlib.util.spec_from_file_location("mpfb_v43", V43_PATH)
if spec is None or spec.loader is None:
    raise RuntimeError("could not load v43 helpers")
v43 = importlib.util.module_from_spec(spec)
spec.loader.exec_module(v43)
v42 = v43.v42

SUCCESS = "MPFB_NATIVE_PINCH_V44_SUCCESS"


def _make_flap(center: Vector, axis: Vector, span: Vector, normal: Vector, radius: float):
    # Near-side label surface and lifted flap. Palm sits on -normal side of the vessel.
    surface = center - normal * (radius + 0.0015)
    width = 0.052
    height = 0.060
    base_low = surface - axis * (height * 0.5)
    base_high = surface + axis * (height * 0.5)
    # Only the upper half lifts toward the approaching pinch hand.
    tip_center = surface + axis * (height * 0.5) - normal * 0.046
    verts = [
        base_low - span * width * 0.5,
        base_low + span * width * 0.5,
        base_high + span * width * 0.5,
        base_high - span * width * 0.5,
        tip_center + span * width * 0.45,
        tip_center - span * width * 0.45,
    ]
    faces = [(0, 1, 2, 3), (3, 2, 4, 5)]
    mesh = bpy.data.meshes.new("V44LabelFlapMesh")
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    obj = bpy.data.objects.new("V44LabelFlap", mesh)
    bpy.context.collection.objects.link(obj)
    mat = bpy.data.materials.new("V44Paper")
    mat.diffuse_color = (0.72, 0.62, 0.47, 1.0)
    mat.roughness = 0.92
    mesh.materials.append(mat)
    return obj, tip_center


def _apply_pinch_layout(arm, center, axis, span, normal, radius, tip_center: Vector, variant: str):
    # Thumb/index straddle the actual paper tip by only a few millimeters. This encodes
    # visible pinch spacing rather than asking a solver to minimize arbitrary endpoint error.
    if variant == "gentle":
        pinch_gap = 0.007
        relax = {3: (0.026, 0.012), 4: (0.032, 0.015), 5: (0.038, 0.018)}
    elif variant == "closed":
        pinch_gap = 0.004
        relax = {3: (0.032, 0.016), 4: (0.038, 0.019), 5: (0.044, 0.022)}
    else:
        raise RuntimeError("unknown v44 variant " + variant)

    v42._set_target_world(arm, "right_finger1_point_ik", tip_center - span * (pinch_gap * 0.5) - axis * 0.002)
    v42._set_target_world(arm, "right_finger2_point_ik", tip_center + span * (pinch_gap * 0.5) + axis * 0.002)

    # Remaining digits curl toward the palm without approaching the flap. Starting from
    # their native fingertip locations preserves each finger's own anatomical length.
    for number, (back, inward) in relax.items():
        tip = v42._bone_world(arm, f"finger{number}-3.R", tail=True)
        target = tip - axis * back - normal * inward
        v42._set_target_world(arm, f"right_finger{number}_point_ik", target)
    bpy.context.view_layer.update()
    bpy.context.view_layer.update()


def _camera(center: Vector, axis: Vector, span: Vector, normal: Vector, focus: Vector, variant: str):
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE_NEXT"
    scene.render.resolution_x = 700
    scene.render.resolution_y = 920
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.world.color = (0.025, 0.025, 0.025)
    offset = -normal * 0.31 - span * (0.15 if variant == "gentle" else 0.20) + axis * 0.01
    bpy.ops.object.camera_add(location=focus + offset)
    cam = bpy.context.object
    scene.camera = cam
    cam.rotation_mode = "QUATERNION"
    cam.rotation_quaternion = v43._camera_rotation(focus - cam.location, axis)
    cam.data.lens = 72
    return cam


def _build(extension_module: str, variant: str):
    HumanService, FingerHelpers = v42._load(extension_module)
    mesh = HumanService.create_human(
        mask_helpers=True,
        detailed_helpers=False,
        extra_vertex_groups=True,
        feet_on_ground=False,
        scale=0.1,
        macro_detail_dict=None,
    )
    arm = HumanService.add_builtin_rig(mesh, "default", import_weights=True, operator=None)
    helper = FingerHelpers.get_instance("right", {"finger_helpers_type": "POINT", "hide_fk": False}, rigtype="Default")
    helper.apply_ik(arm)
    palm, forward, span, normal = v42._palm_frame(arm)
    radius = 0.043
    # Pinch hand should approach a flap rather than already rest on the vessel.
    center = palm + normal * (radius + 0.072)
    axis = forward
    v42._make_proxy(center, axis, radius)
    _, flap_tip = _make_flap(center, axis, span, normal, radius)
    _apply_pinch_layout(arm, center, axis, span, normal, radius, flap_tip, variant)
    v43._skin(mesh)
    v43._lights(center, axis, span, normal)
    focus = flap_tip.lerp(palm, 0.22)
    _camera(center, axis, span, normal, focus, variant)
    return arm, flap_tip


def _render(out: Path, variant: str):
    bpy.context.scene.render.filepath = str(out / f"native_pinch_v44_{variant}.png")
    bpy.ops.render.render(write_still=True)


def _run():
    extension_module, out = v42._args()
    out.mkdir(parents=True, exist_ok=True)
    for variant in ("gentle", "closed"):
        v42._reset()
        arm, flap_tip = _build(extension_module, variant)
        _render(out, variant)
        thumb = v42._bone_world(arm, "finger1-3.R", tail=True)
        index = v42._bone_world(arm, "finger2-3.R", tail=True)
        print(
            "NATIVE_PINCH_V44_RESULT", variant,
            "pinch_gap", round((thumb - index).length, 6),
            "thumb_to_flap", round((thumb - flap_tip).length, 6),
            "index_to_flap", round((index - flap_tip).length, 6),
        )
    print(SUCCESS)


if __name__ == "__main__":
    try:
        _run()
    except BaseException as exc:
        print("MPFB_NATIVE_PINCH_V44_ERROR:", exc)
        traceback.print_exc()
        raise
