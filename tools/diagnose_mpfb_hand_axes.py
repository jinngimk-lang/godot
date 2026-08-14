"""Measure how local MPFB GameEngine hand-bone axes move pinch fingertips.

This diagnostic exists because v12-v14 showed that generic IK and guessed local
flexion axes can reduce numeric contact error while producing non-photographic
finger arcs. Rather than guessing another solver, perturb each relevant pose bone
by +/-10 degrees around each local axis and measure fingertip displacement and
thumb/index gap from the same restrained v13 pre-bend.

The resulting JSON/log is evidence for the next explicit anatomical pose template.
"""
from __future__ import annotations
import importlib.util
import json
import sys
from pathlib import Path

import bpy
from mathutils import Vector

BASE = Path(__file__).with_name('render_mpfb_pose_preview_v13.py')
spec = importlib.util.spec_from_file_location('mpfb_pose_v13', BASE)
if spec is None or spec.loader is None:
    raise RuntimeError('could not load v13 helpers')
v13 = importlib.util.module_from_spec(spec)
spec.loader.exec_module(v13)
v12 = v13.v12
v10 = v13.v10

BONES = [
    'index_01_r', 'index_02_r', 'index_03_r',
    'thumb_01_r', 'thumb_02_r', 'thumb_03_r',
]
AXES = ('x', 'y', 'z')
DEGREES = (-10.0, 10.0)


def _args():
    if '--' not in sys.argv:
        raise RuntimeError('expected -- <input.glb> <output.json>')
    args = sys.argv[sys.argv.index('--') + 1:]
    if len(args) != 2:
        raise RuntimeError('expected two arguments after --')
    return Path(args[0]).resolve(), Path(args[1]).resolve()


def _state(arm):
    index_tip = v10._world_pose(arm, 'index_03_r', True)
    thumb_tip = v10._world_pose(arm, 'thumb_03_r', True)
    return index_tip.copy(), thumb_tip.copy(), (thumb_tip - index_tip).length


def _apply_baseline(arm):
    v10._clear_pose(arm)
    v13._prebend(arm, 2)
    bpy.context.view_layer.update()


def _vec(v: Vector):
    return [round(float(v.x), 7), round(float(v.y), 7), round(float(v.z), 7)]


def _run():
    input_path, output_path = _args()
    output_path.parent.mkdir(parents=True, exist_ok=True)
    v10.INPUT = input_path
    v10.OUT = output_path.parent
    _, arm, _ = v10._setup()

    _apply_baseline(arm)
    base_index, base_thumb, base_gap = _state(arm)
    rows = []

    for bone_name in BONES:
        for axis in AXES:
            for degrees in DEGREES:
                _apply_baseline(arm)
                pb = arm.pose.bones.get(bone_name)
                if pb is None:
                    raise RuntimeError(f'missing pose bone {bone_name}')
                # Compose a small local-space delta on top of the restrained v13 prior.
                pb.rotation_quaternion = pb.rotation_quaternion @ v10._axis_q(axis, degrees)
                bpy.context.view_layer.update()
                index_tip, thumb_tip, gap = _state(arm)
                moved_tip = index_tip if bone_name.startswith('index_') else thumb_tip
                base_tip = base_index if bone_name.startswith('index_') else base_thumb
                delta = moved_tip - base_tip
                row = {
                    'bone': bone_name,
                    'axis': axis,
                    'degrees': degrees,
                    'gap_m': round(gap, 7),
                    'gap_delta_m': round(gap - base_gap, 7),
                    'tip_displacement_m': round(delta.length, 7),
                    'tip_delta_world': _vec(delta),
                }
                rows.append(row)
                print(
                    'MPFB_AXIS', bone_name, axis, f'{degrees:+.0f}',
                    'gap', f'{gap:.6f}', 'gap_delta', f'{gap-base_gap:+.6f}',
                    'tip_move', f'{delta.length:.6f}', 'delta', _vec(delta)
                )

    # Rank negative gap deltas first: these are the local axis/sign combinations
    # that actually close the pinch from this anatomical prior.
    ranked = sorted(rows, key=lambda row: (row['gap_delta_m'], -row['tip_displacement_m']))
    report = {
        'baseline': {
            'index_tip_world': _vec(base_index),
            'thumb_tip_world': _vec(base_thumb),
            'gap_m': round(base_gap, 7),
        },
        'samples': rows,
        'best_gap_closers': ranked[:12],
    }
    output_path.write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')

    if not rows or max(row['tip_displacement_m'] for row in rows) < 0.001:
        raise RuntimeError('axis diagnostic produced no meaningful fingertip motion')
    if not any(row['gap_delta_m'] < -0.001 for row in rows):
        raise RuntimeError('axis diagnostic found no single-axis direction that closes pinch by >=1 mm')

    print('MPFB_AXIS_DIAGNOSTIC_SUCCESS baseline_gap', f'{base_gap:.6f}')
    for rank, row in enumerate(ranked[:6], 1):
        print('MPFB_AXIS_BEST', rank, row['bone'], row['axis'], row['degrees'], 'gap_delta', row['gap_delta_m'])


if __name__ == '__main__':
    _run()
