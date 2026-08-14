"""v14: constrained full-chain IK for a photographic paper-flap pinch.

v12 let all three thumb/index bones solve freely and approached contact, but the
rendered thumb could form an oversized C arc. v13 froze the proximal opposition and
limited IK to the distal two bones; that preserved the palm/thumb base better but
stalled at a 16.4 mm fingertip gap and still allowed lateral distal bending.

v14 keeps the useful target-driven contact objective while restoring a small amount
of proximal participation. Every participating joint is bounded to a deliberately
narrow anatomical envelope and stretch is disabled. Index motion is restricted to
its flexion axis; the thumb base may oppose in three axes inside bounded ranges,
while distal thumb joints primarily flex. Runtime renders remain the final gate.
"""
from __future__ import annotations
import importlib.util
import math
from pathlib import Path
import bpy

BASE = Path(__file__).with_name('render_mpfb_pose_preview_v13.py')
spec = importlib.util.spec_from_file_location('mpfb_pose_v13', BASE)
if spec is None or spec.loader is None:
    raise RuntimeError('could not load v13')
v13 = importlib.util.module_from_spec(spec)
spec.loader.exec_module(v13)
v12 = v13.v12
v10 = v12.v10


def _limit_axis(pb, axis: str, lo_deg: float, hi_deg: float, lock_other: bool = False) -> None:
    if lock_other:
        for other in ('x', 'y', 'z'):
            setattr(pb, f'lock_ik_{other}', other != axis)
    setattr(pb, f'use_ik_limit_{axis}', True)
    setattr(pb, f'ik_min_{axis}', math.radians(lo_deg))
    setattr(pb, f'ik_max_{axis}', math.radians(hi_deg))
    pb.ik_stretch = 0.0


def _limit_xyz(pb, bounds) -> None:
    for axis, (lo_deg, hi_deg) in zip(('x', 'y', 'z'), bounds):
        setattr(pb, f'lock_ik_{axis}', False)
        setattr(pb, f'use_ik_limit_{axis}', True)
        setattr(pb, f'ik_min_{axis}', math.radians(lo_deg))
        setattr(pb, f'ik_max_{axis}', math.radians(hi_deg))
    pb.ik_stretch = 0.0


def _configure_anatomical_limits(arm) -> None:
    # Index: flex around the same local Z axis used by the proven authored curl
    # helpers. The proximal phalanx participates enough to close contact without
    # allowing the chain to swing sideways or invert.
    index_limits = {
        'index_01_r': (4.0, 34.0),
        'index_02_r': (10.0, 68.0),
        'index_03_r': (4.0, 48.0),
    }
    for name, (lo, hi) in index_limits.items():
        pb = arm.pose.bones.get(name)
        if pb is None:
            raise RuntimeError(f'missing IK-limit bone {name}')
        _limit_axis(pb, 'z', lo, hi, lock_other=True)

    # Thumb: opposition lives at the CMC/base, so permit bounded XYZ motion there.
    # Distal bones should mostly flex and must not corkscrew laterally around the
    # paper target.
    base = arm.pose.bones.get('thumb_01_r')
    mid = arm.pose.bones.get('thumb_02_r')
    tip = arm.pose.bones.get('thumb_03_r')
    if base is None or mid is None or tip is None:
        raise RuntimeError('missing thumb IK-limit bones')
    _limit_xyz(base, ((8.0, 52.0), (-20.0, 20.0), (8.0, 50.0)))
    _limit_axis(mid, 'z', -4.0, 42.0, lock_other=True)
    _limit_axis(tip, 'z', -4.0, 32.0, lock_other=True)


def _apply_ik(arm, index_target, thumb_target):
    _configure_anatomical_limits(arm)
    idx = arm.pose.bones.get('index_03_r')
    th = arm.pose.bones.get('thumb_03_r')
    if idx is None or th is None:
        raise RuntimeError('missing pinch IK bones')

    io = v12._empty('PoseIK_Index', index_target)
    to = v12._empty('PoseIK_Thumb', thumb_target)

    ci = idx.constraints.new('IK')
    ci.name = 'PoseIK_IndexConstraint'
    ci.target = io
    ci.chain_count = 3
    ci.iterations = 128
    ci.influence = 1.0

    ct = th.constraints.new('IK')
    ct.name = 'PoseIK_ThumbConstraint'
    ct.target = to
    ct.chain_count = 3
    ct.iterations = 128
    ct.influence = 1.0

    if hasattr(ci, 'use_rotation'):
        ci.use_rotation = False
    if hasattr(ct, 'use_rotation'):
        ct.use_rotation = False
    bpy.context.view_layer.update()


v12._apply_ik = _apply_ik


def _run() -> None:
    # Reuse v13's restrained prebend, v12's contact-region objective and hard
    # geometric gates. This is deliberately not a threshold relaxation.
    v12._run()


if __name__ == '__main__':
    _run()
