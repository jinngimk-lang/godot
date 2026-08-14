"""v20: bounded, interpretable XR-distal -> MPFB three-joint thumb mapping comparison.

v19 established that XR metacarpal/base deltas are essential, reducing Pinch gap from
~95.6 mm to ~59.3 mm without destroying MPFB anatomy.  The remaining unverified
assumption is how the XR two-joint thumb's Distal delta should be distributed over
MPFB thumb_02_r/thumb_03_r.  This is not an optimizer: it renders a small fixed set
of anatomically interpretable mappings under identical camera/light/proxy conditions.
"""
from __future__ import annotations
import importlib.util, math, traceback
from pathlib import Path
import bpy
from mathutils import Quaternion, Vector

BASE = Path(__file__).with_name('render_mpfb_retarget_preview_v19.py')
spec = importlib.util.spec_from_file_location('mpfb_retarget_v19', BASE)
if spec is None or spec.loader is None:
    raise RuntimeError('could not load v19 retarget module')
v19 = importlib.util.module_from_spec(spec)
spec.loader.exec_module(v19)

VARIANTS = {
    'half_half': (0.50, 0.50),
    'full_second_only': (1.00, 0.00),
    'two_thirds_one_third': (2.0 / 3.0, 1.0 / 3.0),
    'full_both': (1.00, 1.00),
}


def _scaled(q: Quaternion, weight: float) -> Quaternion:
    return Quaternion((1, 0, 0, 0)).slerp(q, weight).normalized()


def _apply_variant(xr, mpfb, deltas, weights):
    # Freeze all non-thumb behavior to v19 exactly.
    v19._clear(mpfb)
    for _, (meta, prox, inter, dist, dst1, dst2, dst3) in v19.DIGITS.items():
        qmeta = v19._retarget_delta(xr, mpfb, meta, dst1, deltas[meta])
        qprox = v19._retarget_delta(xr, mpfb, prox, dst1, deltas[prox])
        mpfb.pose.bones[dst1].rotation_quaternion = (qmeta @ qprox).normalized()
        mpfb.pose.bones[dst2].rotation_quaternion = v19._retarget_delta(xr, mpfb, inter, dst2, deltas[inter])
        mpfb.pose.bones[dst3].rotation_quaternion = v19._retarget_delta(xr, mpfb, dist, dst3, deltas[dist])

    meta, prox, dist, dst1, dst2, dst3 = v19.THUMB
    qm = v19._retarget_delta(xr, mpfb, meta, dst1, deltas[meta])
    qp = v19._retarget_delta(xr, mpfb, prox, dst1, deltas[prox])
    qd2 = v19._retarget_delta(xr, mpfb, dist, dst2, deltas[dist])
    qd3 = v19._retarget_delta(xr, mpfb, dist, dst3, deltas[dist])
    mpfb.pose.bones[dst1].rotation_quaternion = (qm @ qp).normalized()
    mpfb.pose.bones[dst2].rotation_quaternion = _scaled(qd2, weights[0])
    mpfb.pose.bones[dst3].rotation_quaternion = _scaled(qd3, weights[1])
    bpy.context.view_layer.update()


def _pinch_metrics(arm):
    i = v19._wp(arm, 'index_03_r', True)
    t = v19._wp(arm, 'thumb_03_r', True)
    c = i.lerp(t, .5)
    return (t - i).length, c, i, t


def _paper_proxy(center):
    bpy.ops.mesh.primitive_cube_add(size=1, location=center)
    o = bpy.context.object
    o.name = 'PoseProxy_Flap'
    o.scale = (.024, .002, .016)
    o.data.materials.append(v19._mat('FlapProxyV20', (.74, .62, .38, 1), .82))


def _support_metrics(arm):
    tips = [v19._wp(arm, f'{n}_03_r', True) for n in ('index', 'middle', 'ring', 'pinky')]
    center = sum(tips, Vector()) / 4
    radius = .038
    errors = [abs((p - center).length - radius) for p in tips]
    return center, radius, errors


def _support_proxy(arm, center, radius):
    palm = v19._wp(arm, 'hand_r')
    axis = (palm - v19._wp(arm, 'lowerarm_r')).normalized()
    bpy.ops.mesh.primitive_cylinder_add(vertices=48, radius=radius, depth=.20, location=center)
    o = bpy.context.object
    o.name = 'PoseProxy_Vessel'
    o.data.materials.append(v19._mat('VesselProxyV20', (.10, .23, .34, 1), .40))
    o.rotation_euler = axis.to_track_quat('Z', 'Y').to_euler()


def _run():
    xr_path, mpfb_path, out = v19._args()
    out.mkdir(parents=True, exist_ok=True)
    v19._reset()
    xr, xr_meshes = v19._import_armature(xr_path, 'XR')
    deltas = v19._source_deltas(xr)
    for mesh in xr_meshes:
        mesh.hide_render = True
        mesh.hide_viewport = True
    mpfb, meshes = v19._import_armature(mpfb_path, 'MPFB')
    cam = v19._setup_render(meshes)
    target = (v19._wr(mpfb, 'hand_r') + v19._wr(mpfb, 'middle_03_r', True)) * .5

    pinch_rows = []
    for name, weights in VARIANTS.items():
        v19._remove_proxies()
        _apply_variant(xr, mpfb, deltas['Pinch Up_Armature'], weights)
        gap, center, _, _ = _pinch_metrics(mpfb)
        _paper_proxy(center)
        print('RETARGET_V20_PINCH', name, 'weights', tuple(round(w, 4) for w in weights), 'gap', f'{gap:.6f}', 'center', tuple(round(v, 6) for v in center))
        v19._render(cam, out, 'retarget_v20_pinch_' + name, target)
        pinch_rows.append((gap, name, weights))

    # Render Cup using the same fixed mapping candidates.  A mapping cannot win
    # merely by closing pinch if it breaks the support-hand silhouette.
    for name, weights in VARIANTS.items():
        v19._remove_proxies()
        _apply_variant(xr, mpfb, deltas['Cup_Armature'], weights)
        center, radius, errors = _support_metrics(mpfb)
        _support_proxy(mpfb, center, radius)
        print('RETARGET_V20_SUPPORT', name, 'weights', tuple(round(w, 4) for w in weights), 'radial_errors', [round(e, 6) for e in errors])
        v19._render(cam, out, 'retarget_v20_cup_' + name, target)

    pinch_rows.sort(key=lambda r: r[0])
    print('RETARGET_V20_BEST_NUMERIC', pinch_rows[0][1], 'gap', f'{pinch_rows[0][0]:.6f}')
    print('MPFB_RETARGET_V20_SUCCESS')


if __name__ == '__main__':
    try:
        _run()
    except BaseException as exc:
        print('MPFB_RETARGET_V20_ERROR:', exc)
        traceback.print_exc()
        raise
