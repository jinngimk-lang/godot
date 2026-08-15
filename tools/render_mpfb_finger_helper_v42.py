"""v42: native MPFB finger-helper IK grasp candidates.

v38-v41 proved that scripted rotations on imported GameEngine finger bones are the
wrong abstraction.  v42 moves pose authority back into MPFB's canonical Default rig:
FingerHelpers POINT mode creates constrained fingertip IK targets, and this harness
moves only those helper controls around a simple vessel fixture.  MPFB's own
finger-chain IK limits/locks therefore decide the anatomical bend.

This is a visual staging experiment only.  It deliberately does not bake/export to the
GameEngine rig yet.  First gate: does native helper IK produce a human wrap silhouette?
"""
from __future__ import annotations

import importlib
import math
import sys
import traceback
from pathlib import Path

import bpy
from mathutils import Vector

SUCCESS = "MPFB_FINGER_HELPER_V42_SUCCESS"


def _args():
    if "--" not in sys.argv:
        raise RuntimeError("expected -- <extension-module> <output-dir>")
    values = sys.argv[sys.argv.index("--") + 1:]
    if len(values) != 2:
        raise RuntimeError("expected two args: extension-module output-dir")
    return values[0], Path(values[1]).resolve()


def _reset():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)


def _load(extension_module: str):
    importlib.import_module(extension_module)
    services = importlib.import_module(extension_module + ".services")
    human_service = getattr(services, "HumanService")
    finger_module = importlib.import_module(
        extension_module + ".entities.rigging.righelpers.fingerhelpers.fingerhelpers"
    )
    return human_service, getattr(finger_module, "FingerHelpers")


def _world(arm, point: Vector) -> Vector:
    return arm.matrix_world @ point


def _bone_world(arm, name: str, tail=False) -> Vector:
    pb = arm.pose.bones.get(name)
    if pb is None:
        raise RuntimeError("missing Default-rig bone " + name)
    return _world(arm, pb.tail if tail else pb.head)


def _palm_frame(arm):
    wrist = _bone_world(arm, "wrist.R")
    index = _bone_world(arm, "finger2-1.R")
    middle = _bone_world(arm, "finger3-1.R")
    pinky = _bone_world(arm, "finger5-1.R")
    forward = ((index + middle) * 0.5 - wrist).normalized()
    span = (index - pinky).normalized()
    normal = forward.cross(span)
    if normal.length < 1e-7:
        raise RuntimeError("degenerate palm frame")
    normal.normalize()
    # Orient normal toward the palm-facing side by using thumb-base location.
    thumb = _bone_world(arm, "finger1-1.R")
    if (thumb - middle).dot(normal) < 0.0:
        normal = -normal
    palm = (wrist + index + middle + pinky) * 0.25
    return palm, forward, span, normal


def _fixture(arm):
    palm, forward, span, normal = _palm_frame(arm)
    # Put a slender cup/bottle proxy just off the palm. The cylinder axis follows the
    # palm's longitudinal direction rather than the finger direction.
    radius = 0.043
    center = palm + normal * (radius + 0.010)
    axis = forward
    return center, axis, span, normal, radius


def _make_proxy(center: Vector, axis: Vector, radius: float):
    bpy.ops.mesh.primitive_cylinder_add(vertices=48, radius=radius, depth=0.22, location=center)
    obj = bpy.context.object
    obj.name = "FingerHelperV42Vessel"
    # Blender cylinder is Z-aligned: rotate Z onto desired world axis.
    z = Vector((0.0, 0.0, 1.0))
    obj.rotation_mode = "QUATERNION"
    obj.rotation_quaternion = z.rotation_difference(axis.normalized())
    mat = bpy.data.materials.new("V42VesselMaterial")
    mat.diffuse_color = (0.12, 0.20, 0.24, 1.0)
    obj.data.materials.append(mat)
    return obj


def _setup_render(mesh, arm, center: Vector):
    # Hide the rest of the body from rendering by using a tight camera crop; keeping the
    # original mesh intact preserves correct deformation around wrist/forearm.
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE_NEXT"
    scene.render.resolution_x = 768
    scene.render.resolution_y = 768
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.world.color = (0.035, 0.035, 0.035)

    bpy.ops.object.light_add(type="AREA")
    key = bpy.context.object
    key.data.energy = 650
    key.data.shape = "DISK"
    key.data.size = 1.4
    key.location = center + Vector((0.65, -0.45, 0.60))

    bpy.ops.object.light_add(type="AREA")
    fill = bpy.context.object
    fill.data.energy = 300
    fill.data.size = 1.0
    fill.location = center + Vector((-0.55, 0.30, 0.20))

    bpy.ops.object.camera_add()
    cam = bpy.context.object
    scene.camera = cam
    palm, forward, span, normal = _palm_frame(arm)
    # Look obliquely across the palm/vessel so wrap depth and thumb opposition are legible.
    cam.location = center - normal * 0.48 - span * 0.24 + Vector((0.0, 0.0, 0.05))
    direction = (center - cam.location).normalized()
    cam.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
    cam.data.lens = 62
    return cam


def _set_target_world(arm, helper_name: str, target_world: Vector):
    pb = arm.pose.bones.get(helper_name)
    if pb is None:
        raise RuntimeError("missing MPFB helper " + helper_name)
    target_arm = arm.matrix_world.inverted() @ target_world
    mat = pb.matrix.copy()
    mat.translation = target_arm
    pb.matrix = mat
    bpy.context.view_layer.update()


def _target_ring(center, axis, span, normal, radius, axial, angle_deg):
    # Around-cylinder artist target. normal=near side, span=lateral around circumference.
    a = math.radians(angle_deg)
    radial = normal * math.cos(a) + span * math.sin(a)
    return center + axis * axial + radial * radius


def _apply_layout(arm, center, axis, span, normal, radius, layout: str):
    # Finger 1 is thumb; 2..5 index..pinky. Four fingers are intentionally sent past the
    # far side while thumb stays on the near/opposite quadrant.
    layouts = {
        "natural": {
            2: (0.035, 142.0), 3: (0.012, 154.0), 4: (-0.012, 164.0), 5: (-0.032, 171.0),
            1: (0.010, 28.0),
        },
        "deep": {
            2: (0.032, 154.0), 3: (0.010, 166.0), 4: (-0.014, 176.0), 5: (-0.034, 184.0),
            1: (0.006, 18.0),
        },
        "open": {
            2: (0.040, 125.0), 3: (0.016, 138.0), 4: (-0.010, 149.0), 5: (-0.032, 158.0),
            1: (0.014, 36.0),
        },
    }
    for number, (axial, angle) in layouts[layout].items():
        target = _target_ring(center, axis, span, normal, radius * 1.03, axial, angle)
        _set_target_world(arm, f"right_finger{number}_point_ik", target)
    # Two depsgraph evaluations help settle child IK after all control targets move.
    bpy.context.view_layer.update()
    bpy.context.view_layer.update()


def _render(out: Path, name: str):
    scene = bpy.context.scene
    scene.render.filepath = str(out / (name + ".png"))
    bpy.ops.render.render(write_still=True)


def _run():
    extension_module, out = _args()
    out.mkdir(parents=True, exist_ok=True)
    _reset()
    HumanService, FingerHelpers = _load(extension_module)

    mesh = HumanService.create_human(
        mask_helpers=True,
        detailed_helpers=False,
        extra_vertex_groups=True,
        feet_on_ground=False,
        scale=0.1,
        macro_detail_dict=None,
    )
    arm = HumanService.add_builtin_rig(mesh, "default", import_weights=True, operator=None)
    if arm is None:
        raise RuntimeError("MPFB Default rig creation failed")

    # Native POINT helper mode. The helper implementation itself installs the IK chain,
    # joint rotation limits and locks defined by MPFB for the canonical Default rig.
    settings = {"finger_helpers_type": "POINT", "hide_fk": False}
    helper = FingerHelpers.get_instance("right", settings, rigtype="Default")
    helper.apply_ik(arm)

    center, axis, span, normal, radius = _fixture(arm)
    _make_proxy(center, axis, radius)
    _setup_render(mesh, arm, center)

    # Snapshot helper matrices so each candidate is independent.
    helper_names = [f"right_finger{i}_point_ik" for i in range(1, 6)]
    baseline = {name: arm.pose.bones[name].matrix.copy() for name in helper_names}
    for layout in ("open", "natural", "deep"):
        for name, mat in baseline.items():
            arm.pose.bones[name].matrix = mat.copy()
        bpy.context.view_layer.update()
        _apply_layout(arm, center, axis, span, normal, radius, layout)
        _render(out, "finger_helper_v42_" + layout)
        tips = []
        for i in range(1, 6):
            tip = _bone_world(arm, f"finger{i}-3.R", tail=True)
            tips.append([round(v, 5) for v in tip])
        print("FINGER_HELPER_V42_RESULT", layout, "tips_world", tips)

    print(SUCCESS)


if __name__ == "__main__":
    try:
        _run()
    except BaseException as exc:
        print("MPFB_FINGER_HELPER_V42_ERROR:", exc)
        traceback.print_exc()
        raise
