"""Export v30 MPFB hero-limb support/pinch poses as rigged staging GLBs.

This promotes the successful Blender-only contact experiment into a falsifiable
Godot import candidate without changing production assets. The source MPFB limb,
pose solver, anatomical budgets, and acceptance gates remain unchanged from v30.

Outputs are staging artifacts only. They are not production assets until they pass
Godot import/runtime framing, provenance, performance, and reference comparison.
"""
from __future__ import annotations

import importlib.util
import json
import sys
import traceback
from pathlib import Path

import bpy

BASE = Path(__file__).with_name("render_mpfb_root_align_v29.py")
spec = importlib.util.spec_from_file_location("mpfb_v29", BASE)
if spec is None or spec.loader is None:
    raise RuntimeError("could not load v29 root-align experiment")
v29 = importlib.util.module_from_spec(spec)
spec.loader.exec_module(v29)

# Match the successful precision configuration from v30 exactly.
v29.v26.SURFACE_EARLY_STOP = 0.0015


def _args() -> tuple[Path, Path, Path, Path]:
    argv = sys.argv
    if "--" not in argv:
        raise RuntimeError("expected -- XR_GLB MPFB_GLB OUT_DIR REPORT_JSON")
    args = argv[argv.index("--") + 1 :]
    if len(args) != 4:
        raise RuntimeError("expected XR_GLB MPFB_GLB OUT_DIR REPORT_JSON")
    return Path(args[0]), Path(args[1]), Path(args[2]), Path(args[3])


def _driven_meshes(arm: bpy.types.Object) -> list[bpy.types.Object]:
    meshes: list[bpy.types.Object] = []
    for obj in bpy.context.scene.objects:
        if obj.type != "MESH":
            continue
        if any(mod.type == "ARMATURE" and getattr(mod, "object", None) == arm for mod in obj.modifiers):
            meshes.append(obj)
            continue
        parent = obj.parent
        while parent is not None:
            if parent == arm:
                meshes.append(obj)
                break
            parent = parent.parent
    return meshes


def _remove_helpers() -> None:
    for obj in list(bpy.context.scene.objects):
        if obj.name.startswith(("PinchTarget_", "ContactMarker", "PaperProxy", "SupportTarget")):
            bpy.data.objects.remove(obj, do_unlink=True)


def _key_pose(arm: bpy.types.Object, action_name: str) -> None:
    action = bpy.data.actions.new(action_name)
    arm.animation_data_create()
    arm.animation_data.action = action
    bpy.context.scene.frame_set(1)
    for bone in arm.pose.bones:
        bone.keyframe_insert(data_path="location", frame=1, group=bone.name)
        if bone.rotation_mode == "QUATERNION":
            bone.keyframe_insert(data_path="rotation_quaternion", frame=1, group=bone.name)
        else:
            bone.keyframe_insert(data_path="rotation_euler", frame=1, group=bone.name)
        bone.keyframe_insert(data_path="scale", frame=1, group=bone.name)


def _export(arm: bpy.types.Object, out_path: Path, action_name: str) -> dict:
    _remove_helpers()
    meshes = _driven_meshes(arm)
    _key_pose(arm, action_name)
    bpy.ops.object.select_all(action="DESELECT")
    arm.select_set(True)
    for mesh in meshes:
        mesh.select_set(True)
    bpy.context.view_layer.objects.active = arm
    out_path.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.export_scene.gltf(
        filepath=str(out_path),
        export_format="GLB",
        use_selection=True,
        export_animations=True,
        export_frame_range=True,
        export_force_sampling=True,
        export_apply=False,
    )
    total_vertices = sum(len(mesh.data.vertices) for mesh in meshes if getattr(mesh, "data", None) is not None)
    return {
        "path": str(out_path),
        "armature": arm.name,
        "bone_count": len(arm.data.bones),
        "mesh_count": len(meshes),
        "vertex_count": total_vertices,
        "action": action_name,
        "bytes": out_path.stat().st_size,
    }


def _load_scene(xr_path: Path, mpfb_path: Path):
    v29.v19._reset()
    xr, xr_meshes = v29.v19._import_armature(xr_path, "XR")
    for mesh in xr_meshes:
        mesh.hide_render = True
        mesh.hide_viewport = True
    mpfb, meshes = v29.v19._import_armature(mpfb_path, "MPFB")
    cam = v29.v19._setup_render(meshes)
    support_center, support_radius, support_axis, flap_center, camera_target = v29.v22._neutral_targets(mpfb)
    return xr, mpfb, cam, support_center, support_radius, support_axis, flap_center, camera_target


def _run() -> None:
    xr_path, mpfb_path, out_dir, report_path = _args()
    out_dir.mkdir(parents=True, exist_ok=True)
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report = {"schema_version": 1, "source": "mpfb-v30-precision", "candidates": {}}

    # Support-wrap candidate: keep the exact v25/v23 control pose used by v30.
    xr, mpfb, cam, support_center, support_radius, support_axis, flap_center, camera_target = _load_scene(xr_path, mpfb_path)
    errors, _, _, _, _ = v29.v25._run_support(
        xr, mpfb, cam, out_dir, support_center, support_radius, support_axis, camera_target
    )
    if max(errors) > 0.030:
        raise RuntimeError("support candidate exceeded unchanged 30 mm contact gate")
    report["support_contact_errors_m"] = [float(v) for v in errors]
    report["candidates"]["support"] = _export(
        mpfb, out_dir / "mpfb-right-support-wrap-v31.glb", "SupportWrapV31"
    )

    # Pinch candidate: use the exact v30 precision servo and all v29 acceptance gates.
    xr, mpfb, cam, support_center, support_radius, support_axis, flap_center, camera_target = _load_scene(xr_path, mpfb_path)
    v29._run_pinch(xr, mpfb, cam, out_dir, flap_center, camera_target)
    report["candidates"]["pinch"] = _export(
        mpfb, out_dir / "mpfb-right-label-pinch-v31.glb", "LabelPinchV31"
    )

    report_path.write_text(json.dumps(report, indent=2, sort_keys=True), encoding="utf-8")
    print("MPFB_POSE_CANDIDATE_EXPORT_V31_SUCCESS")


if __name__ == "__main__":
    try:
        _run()
    except BaseException as exc:
        print("MPFB_POSE_CANDIDATE_EXPORT_V31_ERROR:", exc)
        traceback.print_exc()
        raise
