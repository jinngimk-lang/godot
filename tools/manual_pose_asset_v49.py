"""Repository-local partial FK pose assets for the MPFB GameEngine hero hand.

This intentionally replaces the rejected solver/direction-table family with a durable authoring
boundary. A visually approved hand/wrist pose can be keyed in Blender, saved as local
``matrix_basis`` transforms, committed, and reapplied only to the same MPFB GameEngine rig
family without touching edit-bone rolls.

The format is staging-only until a pose passes the reference Macro/Meso gate.

CLI:
  blender --background --python tools/manual_pose_asset_v49.py -- \
      roundtrip <game-engine.glb> <pose.json> <report.json>

``roundtrip`` applies a deterministic non-neutral FK test pose, saves it, clears the armature,
reloads it, and verifies all selected matrices. This proves the serialization path without
claiming the test pose is a production grasp.
"""
from __future__ import annotations

import json
import math
import sys
import traceback
from pathlib import Path

import bpy
from mathutils import Matrix

FORMAT = "peel-calm-game-engine-partial-pose-v1"
RIG = "game_engine"
SIDE = "right"
SUCCESS = "MANUAL_POSE_ASSET_V49_SUCCESS"

BONES = [
    "lowerarm_r",
    "hand_r",
    "thumb_01_r", "thumb_02_r", "thumb_03_r",
    "index_01_r", "index_02_r", "index_03_r",
    "middle_01_r", "middle_02_r", "middle_03_r",
    "ring_01_r", "ring_02_r", "ring_03_r",
    "pinky_01_r", "pinky_02_r", "pinky_03_r",
]


def _args():
    if "--" not in sys.argv:
        raise RuntimeError("expected -- roundtrip <glb> <pose.json> <report.json>")
    values = sys.argv[sys.argv.index("--") + 1 :]
    if len(values) != 4 or values[0] != "roundtrip":
        raise RuntimeError("expected roundtrip <glb> <pose.json> <report.json>")
    return Path(values[1]).resolve(), Path(values[2]).resolve(), Path(values[3]).resolve()


def _reset() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)


def _import_armature(path: Path):
    _reset()
    bpy.ops.import_scene.gltf(filepath=str(path))
    armatures = [obj for obj in bpy.context.scene.objects if obj.type == "ARMATURE"]
    if len(armatures) != 1:
        raise RuntimeError(f"expected one armature, found {len(armatures)}")
    arm = armatures[0]
    missing = [name for name in BONES if arm.pose.bones.get(name) is None]
    if missing:
        raise RuntimeError(f"GameEngine hand pose bones missing: {missing}")
    return arm


def _flat_matrix(matrix: Matrix) -> list[float]:
    return [float(matrix[row][col]) for row in range(4) for col in range(4)]


def _matrix(values) -> Matrix:
    if not isinstance(values, list) or len(values) != 16:
        raise RuntimeError("pose matrix must contain 16 floats")
    return Matrix(tuple(tuple(float(values[row * 4 + col]) for col in range(4)) for row in range(4)))


def save_pose(arm, path: Path, *, label: str, provenance: dict) -> dict:
    entries = {}
    for name in BONES:
        pb = arm.pose.bones[name]
        entries[name] = {"matrix_basis": _flat_matrix(pb.matrix_basis)}
    payload = {
        "format": FORMAT,
        "rig": RIG,
        "side": SIDE,
        "label": label,
        "provenance": provenance,
        "bones": entries,
    }
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2, sort_keys=True), encoding="utf-8")
    return payload


def load_pose(arm, path: Path) -> dict:
    payload = json.loads(path.read_text(encoding="utf-8"))
    if payload.get("format") != FORMAT or payload.get("rig") != RIG or payload.get("side") != SIDE:
        raise RuntimeError("manual pose metadata is incompatible with right GameEngine hero hand")
    entries = payload.get("bones")
    if not isinstance(entries, dict):
        raise RuntimeError("manual pose is missing bones")
    missing = [name for name in BONES if name not in entries or arm.pose.bones.get(name) is None]
    if missing:
        raise RuntimeError(f"manual pose cannot be applied; missing bones: {missing}")
    for name in BONES:
        arm.pose.bones[name].matrix_basis = _matrix(entries[name]["matrix_basis"])
    bpy.context.view_layer.update()
    return payload


def clear_pose(arm) -> None:
    for name in BONES:
        arm.pose.bones[name].matrix_basis = Matrix.Identity(4)
    bpy.context.view_layer.update()


def _apply_roundtrip_fixture(arm) -> None:
    """Create a non-neutral transform fixture only to prove persistence.

    These values are deliberately *not* a grasp candidate and must never be promoted as one.
    """
    fixture = {
        "hand_r": (7.0, -4.0, 5.0),
        "thumb_01_r": (11.0, 8.0, -6.0),
        "thumb_02_r": (9.0, 3.0, -4.0),
        "index_01_r": (16.0, -5.0, 3.0),
        "index_02_r": (21.0, 2.0, 0.0),
        "middle_01_r": (18.0, -4.0, 2.0),
        "middle_02_r": (23.0, 1.0, 0.0),
        "ring_01_r": (20.0, -3.0, 1.0),
        "ring_02_r": (25.0, 0.0, 0.0),
        "pinky_01_r": (22.0, -2.0, 0.0),
        "pinky_02_r": (27.0, 0.0, 0.0),
    }
    from mathutils import Euler
    for name, degrees in fixture.items():
        pb = arm.pose.bones[name]
        pb.rotation_mode = "XYZ"
        pb.rotation_euler = Euler(tuple(math.radians(value) for value in degrees), "XYZ")
    bpy.context.view_layer.update()


def _matrix_error(a: Matrix, b: Matrix) -> float:
    return max(abs(a[r][c] - b[r][c]) for r in range(4) for c in range(4))


def run() -> None:
    glb, pose_path, report_path = _args()
    arm = _import_armature(glb)
    clear_pose(arm)
    _apply_roundtrip_fixture(arm)
    expected = {name: arm.pose.bones[name].matrix_basis.copy() for name in BONES}

    payload = save_pose(
        arm,
        pose_path,
        label="v49 serialization fixture — NOT a grasp candidate",
        provenance={
            "kind": "technical-roundtrip-fixture",
            "production_candidate": False,
            "note": "Only proves exact same-rig partial-pose persistence; visual acceptance is separate.",
        },
    )
    clear_pose(arm)
    load_pose(arm, pose_path)

    errors = {name: _matrix_error(expected[name], arm.pose.bones[name].matrix_basis) for name in BONES}
    max_error = max(errors.values())
    if max_error > 1e-6:
        raise RuntimeError(f"partial pose roundtrip changed matrices, max error={max_error}")

    report = {
        "format": FORMAT,
        "rig": RIG,
        "side": SIDE,
        "bone_count": len(BONES),
        "max_matrix_error": max_error,
        "production_candidate": False,
        "pose_label": payload["label"],
        "pose_path": str(pose_path),
    }
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(json.dumps(report, indent=2), encoding="utf-8")
    print(json.dumps(report, indent=2))
    print(SUCCESS)


if __name__ == "__main__":
    try:
        run()
    except BaseException as exc:
        print("MANUAL_POSE_ASSET_V49_ERROR:", exc)
        traceback.print_exc()
        raise
