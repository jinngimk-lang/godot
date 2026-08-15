"""v43: judge the accepted v42 native-helper `natural` seed in product-like cameras.

No pose algorithm changes are allowed in this harness.  It reuses MPFB Default-rig
FingerHelpers POINT mode and the exact v42 `natural` target layout, then replaces the
diagnostic camera with tight hero-object views whose image-up follows the vessel axis.
This isolates the falsifiable question: does the new grasp still read as a human wrap
when the vessel is upright in frame and the torso is cropped away?
"""
from __future__ import annotations

import importlib.util
import traceback
from pathlib import Path

import bpy
from mathutils import Matrix, Vector

V42_PATH = Path(__file__).with_name("render_mpfb_finger_helper_v42.py")
spec = importlib.util.spec_from_file_location("mpfb_v42", V42_PATH)
if spec is None or spec.loader is None:
    raise RuntimeError("could not load v42 helpers")
v42 = importlib.util.module_from_spec(spec)
spec.loader.exec_module(v42)

SUCCESS = "MPFB_PRODUCT_CAMERA_V43_SUCCESS"


def _camera_rotation(view_dir: Vector, image_up: Vector):
    view = view_dir.normalized()
    up = image_up - view * image_up.dot(view)
    if up.length < 1e-7:
        raise RuntimeError("v43 degenerate camera up")
    up.normalize()
    right = view.cross(up)
    if right.length < 1e-7:
        raise RuntimeError("v43 degenerate camera right")
    right.normalize()
    # Camera local axes: +X right, +Y up, -Z view direction.
    basis = Matrix((right, up, -view)).transposed()
    return basis.to_quaternion()


def _product_camera(center: Vector, axis: Vector, span: Vector, normal: Vector, variant: str):
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE_NEXT"
    scene.render.resolution_x = 700
    scene.render.resolution_y = 920
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.world.color = (0.025, 0.025, 0.025)

    # Tight framing intentionally removes torso/body contamination from v42.
    if variant == "oblique":
        offset = -normal * 0.34 - span * 0.16 + axis * 0.015
    elif variant == "thumbside":
        offset = -normal * 0.30 + span * 0.22 + axis * 0.005
    else:
        raise RuntimeError("unknown v43 camera variant " + variant)

    bpy.ops.object.camera_add(location=center + offset)
    cam = bpy.context.object
    scene.camera = cam
    direction = center - cam.location
    cam.rotation_mode = "QUATERNION"
    cam.rotation_quaternion = _camera_rotation(direction, axis)
    cam.data.lens = 74
    cam.data.clip_start = 0.025
    cam.data.clip_end = 10.0
    return cam


def _lights(center: Vector, axis: Vector, span: Vector, normal: Vector):
    bpy.ops.object.light_add(type="AREA", location=center - normal * 0.40 - span * 0.28 + axis * 0.30)
    key = bpy.context.object
    key.data.energy = 500
    key.data.size = 0.70
    bpy.ops.object.light_add(type="AREA", location=center - normal * 0.10 + span * 0.42 - axis * 0.05)
    fill = bpy.context.object
    fill.data.energy = 220
    fill.data.size = 0.55


def _skin(mesh):
    mat = bpy.data.materials.new("V43Skin")
    mat.use_nodes = True
    bsdf = next((n for n in mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED"), None)
    if bsdf:
        bsdf.inputs["Base Color"].default_value = (0.54, 0.34, 0.24, 1.0)
        bsdf.inputs["Roughness"].default_value = 0.62
    mesh.data.materials.clear()
    mesh.data.materials.append(mat)


def _render(out: Path, name: str):
    bpy.context.scene.render.filepath = str(out / (name + ".png"))
    bpy.ops.render.render(write_still=True)


def _build_pose(extension_module: str):
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
    if arm is None:
        raise RuntimeError("MPFB Default rig creation failed")
    helper = FingerHelpers.get_instance(
        "right", {"finger_helpers_type": "POINT", "hide_fk": False}, rigtype="Default"
    )
    helper.apply_ik(arm)
    center, axis, span, normal, radius = v42._fixture(arm)
    proxy = v42._make_proxy(center, axis, radius)
    v42._apply_layout(arm, center, axis, span, normal, radius, "natural")
    _skin(mesh)
    return mesh, arm, proxy, center, axis, span, normal


def _run():
    extension_module, out = v42._args()
    out.mkdir(parents=True, exist_ok=True)
    for variant in ("oblique", "thumbside"):
        v42._reset()
        mesh, arm, proxy, center, axis, span, normal = _build_pose(extension_module)
        _lights(center, axis, span, normal)
        _product_camera(center, axis, span, normal, variant)
        _render(out, "product_camera_v43_" + variant)
        print("PRODUCT_CAMERA_V43_RESULT", variant, "center", [round(v, 5) for v in center], "axis", [round(v, 5) for v in axis])
    print(SUCCESS)


if __name__ == "__main__":
    try:
        _run()
    except BaseException as exc:
        print("MPFB_PRODUCT_CAMERA_V43_ERROR:", exc)
        traceback.print_exc()
        raise
