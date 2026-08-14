"""v13: preserve proximal finger/thumb anatomy while IK solves distal contact.

v12 target-driven IK reduced contact-region error to ~4 mm and the fingertip gap to
~13.9 mm, but allowing the full 3-bone thumb chain to solve created an oversized
C-shaped thumb arc. v13 fixes the proximal thumb/index opposition as an anatomical
prior and limits IK to the two distal joints.
"""
from __future__ import annotations
import importlib.util
from pathlib import Path
import bpy

BASE=Path(__file__).with_name('render_mpfb_pose_preview_v12.py')
spec=importlib.util.spec_from_file_location('mpfb_pose_v12',BASE)
if spec is None or spec.loader is None: raise RuntimeError('could not load v12')
v12=importlib.util.module_from_spec(spec); spec.loader.exec_module(v12)
v10=v12.v10

# Hold proximal opposition deliberately; distal joints perform the actual paper pinch.
def _prebend(arm,variant):
    v12._relaxed_unused(arm)
    if variant==1:
        v10._set_axis(arm,'index_01_r','z',12)
        v10._set_axis(arm,'index_02_r','z',24); v10._set_axis(arm,'index_03_r','z',12)
        v10._set_xyz(arm,'thumb_01_r',(28,-4,28)); v10._set_xyz(arm,'thumb_02_r',(0,0,8)); v10._set_xyz(arm,'thumb_03_r',(0,0,4))
    elif variant==2:
        v10._set_axis(arm,'index_01_r','z',16)
        v10._set_axis(arm,'index_02_r','z',28); v10._set_axis(arm,'index_03_r','z',14)
        v10._set_xyz(arm,'thumb_01_r',(36,0,34)); v10._set_xyz(arm,'thumb_02_r',(0,0,10)); v10._set_xyz(arm,'thumb_03_r',(0,0,5))
    else:
        v10._set_axis(arm,'index_01_r','z',10)
        v10._set_axis(arm,'index_02_r','z',20); v10._set_axis(arm,'index_03_r','z',10)
        v10._set_xyz(arm,'thumb_01_r',(22,-8,24)); v10._set_xyz(arm,'thumb_02_r',(0,0,7)); v10._set_xyz(arm,'thumb_03_r',(0,0,3))
    bpy.context.view_layer.update()
v12._prebend=_prebend

def _apply_ik(arm,index_target,thumb_target):
    idx=arm.pose.bones.get('index_03_r'); th=arm.pose.bones.get('thumb_03_r')
    if idx is None or th is None: raise RuntimeError('missing distal pinch bones')
    io=v12._empty('PoseIK_Index',index_target); to=v12._empty('PoseIK_Thumb',thumb_target)
    ci=idx.constraints.new('IK'); ci.name='PoseIK_IndexConstraint'; ci.target=io; ci.chain_count=2; ci.iterations=96; ci.influence=1.0
    ct=th.constraints.new('IK'); ct.name='PoseIK_ThumbConstraint'; ct.target=to; ct.chain_count=2; ct.iterations=96; ct.influence=1.0
    if hasattr(ci,'use_rotation'): ci.use_rotation=False
    if hasattr(ct,'use_rotation'): ct.use_rotation=False
    bpy.context.view_layer.update()
v12._apply_ik=_apply_ik

if __name__=='__main__':
    v12._run()
