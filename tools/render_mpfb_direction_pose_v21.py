"""v21: morphology-invariant semantic pose transfer by normalized phalanx directions.

v18-v20 proved that local rotation deltas do not transfer robustly between the XR
hand rig and the MPFB GameEngine hand morphology. This spike samples each authored
XR action as phalanx direction vectors in the XR wrist frame and aligns the MPFB
segments to those directions in the MPFB hand frame. MPFB segment lengths, mesh,
wrist and forearm remain untouched. No optimization or free IK search is used.
"""
from __future__ import annotations
import importlib.util, math, traceback
from pathlib import Path
import bpy
from mathutils import Matrix, Vector

BASE = Path(__file__).with_name('render_mpfb_retarget_preview_v19.py')
spec = importlib.util.spec_from_file_location('mpfb_v19', BASE)
if spec is None or spec.loader is None:
    raise RuntimeError('could not load v19 helpers')
v19 = importlib.util.module_from_spec(spec)
spec.loader.exec_module(v19)

ACTIONS = ('Cup_Armature', 'Pinch Up_Armature', 'Pinch Tight_Armature')
CHAINS = {
    'index': (('Index_Proximal_R','Index_Intermediate_R','Index_Distal_R'), ('index_01_r','index_02_r','index_03_r')),
    'middle': (('Middle_Proximal_R','Middle_Intermediate_R','Middle_Distal_R'), ('middle_01_r','middle_02_r','middle_03_r')),
    'ring': (('Ring_Proximal_R','Ring_Intermediate_R','Ring_Distal_R'), ('ring_01_r','ring_02_r','ring_03_r')),
    'pinky': (('Little_Proximal_R','Little_Intermediate_R','Little_Distal_R'), ('pinky_01_r','pinky_02_r','pinky_03_r')),
    # XR has two deforming thumb phalanges while GameEngine has three. Match
    # thumb_01 to source proximal, then carry source distal direction through
    # both remaining target phalanges rather than splitting an angle delta.
    'thumb': (('Thumb_Proximal_R','Thumb_Distal_R','Thumb_Distal_R'), ('thumb_01_r','thumb_02_r','thumb_03_r')),
}


def _frame_rotation(arm, bone_name):
    pb = arm.pose.bones.get(bone_name)
    if pb is None:
        raise RuntimeError('missing frame bone ' + bone_name)
    return pb.matrix.to_3x3().normalized()


def _segment_direction(arm, bone_name):
    pb = arm.pose.bones.get(bone_name)
    if pb is None:
        raise RuntimeError('missing segment bone ' + bone_name)
    d = pb.tail - pb.head
    if d.length < 1e-7:
        raise RuntimeError('zero-length segment ' + bone_name)
    return d.normalized()


def _semantic_directions(xr, action_name):
    v19._set_action(xr, action_name)
    wrist_rot = _frame_rotation(xr, 'Wrist_R')
    inv = wrist_rot.inverted()
    rows = {}
    for label, (src_chain, _) in CHAINS.items():
        dirs = []
        for src in src_chain:
            local = inv @ _segment_direction(xr, src)
            dirs.append(local.normalized())
        rows[label] = tuple(dirs)
    return rows


def _rotate_pose_bone_armature_space(pb, q):
    head = pb.head.copy()
    m = Matrix.Translation(head) @ q.to_matrix().to_4x4() @ Matrix.Translation(-head) @ pb.matrix
    pb.matrix = m


def _apply_directions(mpfb, semantic):
    v19._clear(mpfb)
    changes = []
    # Freeze hand_r itself; only digit phalanges are changed. Each child is
    # corrected after its parent, so inherited rotations are included in the
    # current direction before the next alignment.
    for label in ('index','middle','ring','pinky','thumb'):
        _, dst_chain = CHAINS[label]
        for dst, local_dir in zip(dst_chain, semantic[label]):
            hand_rot = _frame_rotation(mpfb, 'hand_r')
            desired = (hand_rot @ local_dir).normalized()
            pb = mpfb.pose.bones.get(dst)
            if pb is None:
                raise RuntimeError('missing MPFB pose bone ' + dst)
            current = _segment_direction(mpfb, dst)
            q = current.rotation_difference(desired)
            deg = math.degrees(q.angle)
            changes.append((dst, deg))
            _rotate_pose_bone_armature_space(pb, q)
            bpy.context.view_layer.update()
    return changes


def _pinch_metrics(arm):
    i = v19._wp(arm, 'index_03_r', True)
    t = v19._wp(arm, 'thumb_03_r', True)
    c = i.lerp(t, .5)
    return (t-i).length, c


def _paper_proxy(center):
    bpy.ops.mesh.primitive_cube_add(size=1, location=center)
    o=bpy.context.object; o.name='PoseProxy_Flap'; o.scale=(.024,.002,.016)
    o.data.materials.append(v19._mat('DirectionFlap',(.74,.62,.38,1),.82))


def _support_proxy(arm):
    tips=[v19._wp(arm,f'{n}_03_r',True) for n in ('index','middle','ring','pinky')]
    center=sum(tips,Vector())/4; radius=.038
    errors=[abs((p-center).length-radius) for p in tips]
    palm=v19._wp(arm,'hand_r'); axis=(palm-v19._wp(arm,'lowerarm_r')).normalized()
    bpy.ops.mesh.primitive_cylinder_add(vertices=48,radius=radius,depth=.20,location=center)
    o=bpy.context.object; o.name='PoseProxy_Vessel'; o.data.materials.append(v19._mat('DirectionVessel',(.10,.23,.34,1),.40)); o.rotation_euler=axis.to_track_quat('Z','Y').to_euler()
    return errors


def _run():
    xr_path,mpfb_path,out=v19._args(); out.mkdir(parents=True,exist_ok=True)
    v19._reset(); xr,xr_meshes=v19._import_armature(xr_path,'XR')
    for mesh in xr_meshes: mesh.hide_render=True; mesh.hide_viewport=True
    mpfb,meshes=v19._import_armature(mpfb_path,'MPFB'); cam=v19._setup_render(meshes)
    target=(v19._wr(mpfb,'hand_r')+v19._wr(mpfb,'middle_03_r',True))*.5

    for action_name in ACTIONS:
        v19._remove_proxies(); semantic=_semantic_directions(xr,action_name); changes=_apply_directions(mpfb,semantic)
        max_change=max(deg for _,deg in changes); over_120=[(name,round(deg,2)) for name,deg in changes if deg>120.0]
        print('DIRECTION_V21_CHANGES',action_name,'max_deg',f'{max_change:.3f}','over_120',over_120)
        if action_name.startswith('Cup'):
            errors=_support_proxy(mpfb); print('DIRECTION_V21_SUPPORT radial_errors',[round(e,6) for e in errors])
        else:
            gap,center=_pinch_metrics(mpfb); _paper_proxy(center); print('DIRECTION_V21_PINCH',action_name,'gap',f'{gap:.6f}','center',tuple(round(v,6) for v in center))
        safe=action_name.replace(' ','_').replace('_Armature','').lower(); v19._render(cam,out,'direction_v21_'+safe,target)

    print('MPFB_DIRECTION_V21_SUCCESS')


if __name__=='__main__':
    try:_run()
    except BaseException as exc:
        print('MPFB_DIRECTION_V21_ERROR:',exc); traceback.print_exc(); raise
