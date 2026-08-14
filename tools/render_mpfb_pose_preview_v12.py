"""Target-driven MPFB peel pinch preview.

v10 showed that unconstrained angle search can fake a small gap with gross loops.
v11 showed that anatomically bounded angle search cannot close the gap. v12 changes
control families entirely: thumb and index distal chains are driven toward two
opposing paper-flap contact targets with Blender IK, starting from modest pre-bend
priors. Metrics check the achieved tip gap and target-region error; rendered frames
remain the final anatomy gate.
"""
from __future__ import annotations
import importlib.util
import math
import sys
import traceback
from pathlib import Path
import bpy
from mathutils import Vector

BASE = Path(__file__).with_name('render_mpfb_pose_preview_v10.py')
spec = importlib.util.spec_from_file_location('mpfb_pose_v10', BASE)
if spec is None or spec.loader is None:
    raise RuntimeError('could not load v10 pose helpers')
v10 = importlib.util.module_from_spec(spec)
spec.loader.exec_module(v10)

SUCCESS='MPFB_POSE_PREVIEW_SUCCESS'
ERROR='MPFB_POSE_PREVIEW_ERROR'

def _empty(name, location):
    obj=bpy.data.objects.new(name, None)
    obj.empty_display_type='SPHERE'; obj.empty_display_size=.008
    obj.location=location
    bpy.context.scene.collection.objects.link(obj)
    return obj

def _remove_targets():
    for obj in list(bpy.context.scene.objects):
        if obj.name.startswith('PoseIK_'):
            bpy.data.objects.remove(obj, do_unlink=True)

def _relaxed_unused(arm):
    v10._curl_chain(arm,'middle',(20,32,18))
    v10._curl_chain(arm,'ring',(24,38,22))
    v10._curl_chain(arm,'pinky',(28,44,26))

def _prebend(arm, variant):
    _relaxed_unused(arm)
    if variant == 1:
        v10._curl_chain(arm,'index',(10,22,12))
        v10._set_xyz(arm,'thumb_01_r',(20,0,18)); v10._set_xyz(arm,'thumb_02_r',(0,0,8)); v10._set_xyz(arm,'thumb_03_r',(0,0,4))
    elif variant == 2:
        v10._curl_chain(arm,'index',(14,28,16))
        v10._set_xyz(arm,'thumb_01_r',(30,4,24)); v10._set_xyz(arm,'thumb_02_r',(0,0,10)); v10._set_xyz(arm,'thumb_03_r',(0,0,6))
    else:
        v10._curl_chain(arm,'index',(8,18,10))
        v10._set_xyz(arm,'thumb_01_r',(14,-4,14)); v10._set_xyz(arm,'thumb_02_r',(0,0,6)); v10._set_xyz(arm,'thumb_03_r',(0,0,3))
    bpy.context.view_layer.update()

def _apply_ik(arm, index_target, thumb_target):
    idx=arm.pose.bones.get('index_03_r'); th=arm.pose.bones.get('thumb_03_r')
    if idx is None or th is None: raise RuntimeError('missing distal pinch bones')
    idx_obj=_empty('PoseIK_Index', index_target); th_obj=_empty('PoseIK_Thumb', thumb_target)
    ci=idx.constraints.new('IK'); ci.name='PoseIK_IndexConstraint'; ci.target=idx_obj; ci.chain_count=3; ci.iterations=64; ci.influence=1.0
    ct=th.constraints.new('IK'); ct.name='PoseIK_ThumbConstraint'; ct.target=th_obj; ct.chain_count=3; ct.iterations=64; ct.influence=1.0
    # Position is authoritative; twist/orientation remains inherited from the rig.
    if hasattr(ci,'use_rotation'): ci.use_rotation=False
    if hasattr(ct,'use_rotation'): ct.use_rotation=False
    bpy.context.view_layer.update()

def _contact_targets(arm, anchor_shift=Vector((0,0,0))):
    idx=v10._world_pose(arm,'index_03_r',True); th=v10._world_pose(arm,'thumb_03_r',True)
    line=th-idx
    if line.length < 1e-6: line=Vector((1,0,0))
    line.normalize()
    anchor=idx.lerp(th,.36)+anchor_shift
    half=.003
    return anchor-line*half, anchor+line*half, anchor

def _state(arm, index_target, thumb_target, anchor):
    idx=v10._world_pose(arm,'index_03_r',True); th=v10._world_pose(arm,'thumb_03_r',True); mid=idx.lerp(th,.5)
    gap=(th-idx).length
    target_error=((idx-index_target).length+(th-thumb_target).length)*.5
    anchor_error=(mid-anchor).length
    return gap,target_error,anchor_error,idx,th,mid

def _render_pinches(arm,cam,target,offset):
    rows=[]
    shifts=[Vector((0,0,0)),Vector((.006,0,0)),Vector((-.006,0,0))]
    for rank,(variant,shift) in enumerate(zip((1,2,3),shifts),1):
        v10._clear_pose(arm); _remove_targets(); _prebend(arm,variant)
        it,tt,anchor=_contact_targets(arm,shift)
        _apply_ik(arm,it,tt); bpy.context.view_layer.update()
        gap,target_error,anchor_error,idx,th,mid=_state(arm,it,tt,anchor)
        v10._pinch_proxy(arm); bpy.context.view_layer.update()
        print('MPFB_POSE_IK pinch_ik rank',rank,'gap',f'{gap:.6f}','target_error',f'{target_error:.6f}','anchor_error',f'{anchor_error:.6f}')
        v10._render(cam,f'pinch_solved_{rank}',target,offset)
        rows.append((gap+target_error+anchor_error,gap,target_error,anchor_error,rank))
    rows.sort(key=lambda r:r[0])
    return rows

def _run():
    v10.INPUT,v10.OUT=v10._args(); v10.OUT.mkdir(parents=True,exist_ok=True)
    mesh,arm,cam=v10._setup()
    target=(v10._world_rest(arm,'hand_r')+v10._world_rest(arm,'middle_03_r',True))*.5
    offset=Vector((-.18,-.28,.10))
    v10._clear_pose(arm); _remove_targets(); v10._render(cam,'pose_neutral',target,offset)
    support=v10._solve_support(arm)
    for rank,row in enumerate(support,1):
        _,distance,params,goal,tip=row; v10._clear_pose(arm); _remove_targets(); v10._support_fingers(arm); v10._apply_thumb(arm,params); v10._support_proxy(arm); bpy.context.view_layer.update()
        print('MPFB_POSE_SOLVE support_solved rank',rank,'distance',f'{distance:.6f}','params',params)
        v10._render(cam,f'support_solved_{rank}',target,offset)
    pinch=_render_pinches(arm,cam,target,offset)
    best=pinch[0]
    print('MPFB_POSE_BEST support_distance',f'{support[0][1]:.6f}','pinch_gap',f'{best[1]:.6f}','pinch_target_error',f'{best[2]:.6f}','pinch_anchor_error',f'{best[3]:.6f}','rank',best[4])
    print('MPFB_POSE_PRIOR target_ik_v12')
    if best[1]>.012: raise RuntimeError(f'pinch gap gate failed: {best[1]:.6f} m > 0.012 m')
    if best[2]>.012: raise RuntimeError(f'IK target error gate failed: {best[2]:.6f} m > 0.012 m')
    if best[3]>.025: raise RuntimeError(f'pinch anchor error gate failed: {best[3]:.6f} m > 0.025 m')
    print(SUCCESS)

if __name__=='__main__':
    try:_run()
    except BaseException as e:
        print(f'{ERROR}: {e}'); traceback.print_exc(); raise
