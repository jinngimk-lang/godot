#!/usr/bin/env python3
"""v62: transfer a CC0 holding-object pose as rest-frame local rotation deltas.

v61 proved that reconstructing twist from per-phalanx geometric bend planes is unstable:
multiple joints saturated the twist bound and the rendered silhouette became worse. v62
changes representation again. The sacrificial MakeHuman BVH is imported only to read the
first-frame local pose rotation of its right-hand finger bones. Each source local pose delta
is conjugated through source-rest -> target-rest orientation alignment and written to the
corresponding MPFB GameEngine pose bone.

Safety properties:
- source edit-bone roll is never written to the target rig;
- source pose matrices are never copied verbatim;
- target edit/rest matrices are snapshotted and must remain bit-level unchanged;
- no CCD, endpoint target, contact servo, direction solver, twist reconstruction, or sweep;
- lowerarm/hand retain the already-established whole-hand placement; only 15 finger/thumb
  pose bones are cleared then receive mapped local rotation deltas;
- final 17-bone target pose persists through the v49 durable matrix_basis format.

The candidate is staging-only and is promoted solely by full + 192x108 visual evidence.
"""
from __future__ import annotations

import importlib.util
import json
import re
import sys
import traceback
from pathlib import Path

import bpy
from mathutils import Matrix, Quaternion, Vector

BASE = Path(__file__).resolve().parent


def _load(name: str, filename: str):
    spec = importlib.util.spec_from_file_location(name, BASE / filename)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"could not load {filename}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


v19 = _load("mpfb_v19_for_v62", "render_mpfb_retarget_preview_v19.py")
v23 = _load("mpfb_v23_for_v62", "render_mpfb_contact_ik_v23.py")
v35 = _load("mpfb_v35_for_v62", "render_mpfb_canonical_grip_v35.py")
v49 = _load("mpfb_v49_for_v62", "manual_pose_asset_v49.py")
v53 = _load("mpfb_v53_for_v62", "author_mpfb_anatomical_controls_v53.py")

SOURCE_PREFIX = {
    "thumb": "finger1-",
    "index": "finger2-",
    "middle": "finger3-",
    "ring": "finger4-",
    "pinky": "finger5-",
}
TARGET_CHAINS = {
    digit: [f"{digit}_01_r", f"{digit}_02_r", f"{digit}_03_r"]
    for digit in ("thumb", "index", "middle", "ring", "pinky")
}
FINGER_BONES = [name for chain in TARGET_CHAINS.values() for name in chain]


def _args():
    if "--" not in sys.argv:
        raise RuntimeError("expected -- <xr.glb> <mpfb.glb> <source.bvh> <outdir> <pose.json> <report.json>")
    values = sys.argv[sys.argv.index("--") + 1:]
    if len(values) != 6:
        raise RuntimeError("expected six arguments")
    return tuple(Path(v).resolve() for v in values)


def _source_chains(source_arm) -> dict[str, list[str]]:
    names = [pb.name for pb in source_arm.pose.bones]
    result = {}
    for digit, prefix in SOURCE_PREFIX.items():
        candidates = [n for n in names if n.lower().startswith(prefix) and n.lower().endswith('.r')]
        def key(name):
            m = re.search(r"-(\d+)", name)
            return (int(m.group(1)) if m else 999, name)
        candidates.sort(key=key)
        if len(candidates) < 3:
            raise RuntimeError(f"source {digit} chain incomplete: {candidates}")
        result[digit] = candidates[:3]
    return result


def _rest_local_rotation(arm, bone_name: str) -> Quaternion:
    bone = arm.data.bones.get(bone_name)
    if bone is None:
        raise RuntimeError("missing rest bone " + bone_name)
    m = bone.matrix_local.copy()
    if bone.parent is not None:
        m = bone.parent.matrix_local.inverted() @ m
    return m.to_quaternion().normalized()


def _source_local_pose_delta(source_arm, bone_name: str) -> Quaternion:
    pb = source_arm.pose.bones.get(bone_name)
    if pb is None:
        raise RuntimeError("missing source pose bone " + bone_name)
    # BVH importer stores the first-frame animation in pose basis relative to the imported
    # skeleton rest. Reading matrix_basis does not mutate or reinterpret source edit roll.
    return pb.matrix_basis.to_quaternion().normalized()


def _mapped_delta(source_arm, target_arm, src_name: str, dst_name: str) -> tuple[Quaternion, dict]:
    src_rest = _rest_local_rotation(source_arm, src_name)
    dst_rest = _rest_local_rotation(target_arm, dst_name)
    source_delta = _source_local_pose_delta(source_arm, src_name)
    align = (dst_rest.inverted() @ src_rest).normalized()
    mapped = (align @ source_delta @ align.inverted()).normalized()
    return mapped, {
        "source": src_name,
        "target": dst_name,
        "source_delta_angle_deg": float(source_delta.angle * 57.29577951308232),
        "mapped_delta_angle_deg": float(mapped.angle * 57.29577951308232),
    }


def _clear_target_fingers(target_arm) -> None:
    for name in FINGER_BONES:
        pb = target_arm.pose.bones.get(name)
        if pb is None:
            raise RuntimeError("missing target pose bone " + name)
        pb.rotation_mode = 'QUATERNION'
        pb.rotation_quaternion = Quaternion((1.0, 0.0, 0.0, 0.0))
        pb.location = Vector((0.0, 0.0, 0.0))
        pb.scale = Vector((1.0, 1.0, 1.0))
    bpy.context.view_layer.update()


def _apply_rest_delta_transfer(source_arm, target_arm, chains) -> dict:
    _clear_target_fingers(target_arm)
    report = {}
    for digit in ("index", "middle", "ring", "pinky", "thumb"):
        rows = []
        for src_name, dst_name in zip(chains[digit], TARGET_CHAINS[digit]):
            q, row = _mapped_delta(source_arm, target_arm, src_name, dst_name)
            pb = target_arm.pose.bones[dst_name]
            pb.rotation_mode = 'QUATERNION'
            pb.rotation_quaternion = q
            bpy.context.view_layer.update()
            rows.append(row)
        report[digit] = rows
    return report


def _snapshot_rest(arm):
    return {name: arm.data.bones[name].matrix_local.copy() for name in v49.BONES}


def _matrix_error(a: Matrix, b: Matrix) -> float:
    return max(abs(a[r][c] - b[r][c]) for r in range(4) for c in range(4))


def _render_thumbnail(cam, out: Path, focus: Vector) -> None:
    scene = bpy.context.scene
    old = (scene.render.resolution_x, scene.render.resolution_y, scene.render.resolution_percentage)
    scene.render.resolution_x = 192
    scene.render.resolution_y = 108
    scene.render.resolution_percentage = 100
    try:
        v19._render(cam, out, "rest_delta_v62_thumbnail", focus)
    finally:
        scene.render.resolution_x, scene.render.resolution_y, scene.render.resolution_percentage = old


def run() -> None:
    xr_path, mpfb_path, source_bvh, out, pose_path, report_path = _args()
    out.mkdir(parents=True, exist_ok=True)
    pose_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.parent.mkdir(parents=True, exist_ok=True)

    v19._reset()
    xr, xr_meshes = v19._import_armature(xr_path, "XR")
    for mesh in xr_meshes:
        mesh.hide_render = True
        mesh.hide_viewport = True
    target, meshes = v19._import_armature(mpfb_path, "MPFB")
    cam = v19._setup_render(meshes)

    # Reuse only the stable whole-hand fixture/crop established in the prior experiments.
    v19._clear(target)
    v23._pose_seed(xr, target, "Cup_Armature")
    center, axis, inward, _ = v35._fixture_from_seed(target, 1.0)
    proxy = v35.v33._proxy(center, axis, "RestDeltaV62Vessel")
    whole_rotation_deg, root_shift = v35._orient_whole_hand(target, center, axis, inward)
    camera_target = v53._camera_target_preserving_pose(target)

    before = set(bpy.context.scene.objects)
    bpy.ops.import_anim.bvh(filepath=str(source_bvh), frame_start=1, update_scene_fps=False)
    created = [o for o in bpy.context.scene.objects if o not in before]
    source_arms = [o for o in created if o.type == 'ARMATURE']
    if len(source_arms) != 1:
        raise RuntimeError(f"expected one sacrificial BVH armature, got {len(source_arms)}")
    source = source_arms[0]
    source.name = "SacrificialCC0HoldingPose"
    bpy.context.scene.frame_set(1)
    bpy.context.view_layer.update()

    chains = _source_chains(source)
    rest_before = _snapshot_rest(target)
    transfer = _apply_rest_delta_transfer(source, target, chains)
    rest_after = _snapshot_rest(target)
    rest_error = max(_matrix_error(rest_before[n], rest_after[n]) for n in v49.BONES)
    if rest_error > 1e-10:
        raise RuntimeError(f"v62 modified target rest/edit structure: {rest_error}")

    expected = {name: target.pose.bones[name].matrix_basis.copy() for name in v49.BONES}
    payload = v49.save_pose(
        target,
        pose_path,
        label="v62 CC0 rest-frame local-delta support-wrap staging candidate",
        provenance={
            "kind": "rest-frame-local-rotation-delta",
            "source": "MakeHuman Community Poses 01 holding-wine-glass CC0 BVH",
            "production_candidate": False,
            "source_edit_bone_roll_copied": False,
            "source_pose_matrix_copied": False,
            "target_solver_used": False,
            "contact_servo_used": False,
            "direction_only_transfer": False,
            "target_rest_structure_modified": False,
        },
    )
    v49.clear_pose(target)
    v49.load_pose(target, pose_path)
    reload_error = max(_matrix_error(expected[n], target.pose.bones[n].matrix_basis) for n in v49.BONES)
    if reload_error > 1e-6:
        raise RuntimeError(f"v62 durable reload changed pose: {reload_error}")

    source.hide_render = True
    source.hide_viewport = True
    focus = camera_target.lerp(center, 0.55)
    v19._render(cam, out, "rest_delta_v62_candidate", focus)
    _render_thumbnail(cam, out, focus)

    report = {
        "staging_only": True,
        "production_candidate": False,
        "source_license": "CC0 (official MakeHuman Community Poses 01 pack)",
        "representation": "source local pose rotation delta conjugated source-rest -> target-rest",
        "source_edit_bone_roll_copied": False,
        "source_pose_matrix_copied": False,
        "direction_only_transfer": False,
        "target_solver_used": False,
        "contact_servo_used": False,
        "camera_focus_preserves_pose": True,
        "pose_bone_count": len(payload["bones"]),
        "whole_rotation_deg": whole_rotation_deg,
        "root_shift": root_shift,
        "target_rest_structure_error": rest_error,
        "max_reload_matrix_error": reload_error,
        "source_chains": chains,
        "transfer": transfer,
        "visual_gate": "192x108 must immediately read as a natural vessel wrap with progressive finger curl/disappearance, opposed thumb, and no broken-joint silhouette.",
    }
    report_path.write_text(json.dumps(report, indent=2, sort_keys=True), encoding='utf-8')
    print(json.dumps(report, indent=2, sort_keys=True))
    print("MPFB_REST_DELTA_V62_SUCCESS")
    bpy.data.objects.remove(proxy, do_unlink=True)


if __name__ == '__main__':
    try:
        run()
    except BaseException as exc:
        print("MPFB_REST_DELTA_V62_ERROR:", exc)
        traceback.print_exc()
        raise
