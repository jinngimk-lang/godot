"""v16: explicit bounded pinch solve using empirically measured GameEngine rig axes.

v15 proved the old local-Z index-flex assumption wrong. This solver starts from the
restrained v13 prior and searches only axis/sign combinations that measurably close
the pinch. No generic IK, no stretch. Runtime renders remain the final anatomy gate.
"""
from __future__ import annotations
import importlib.util, math, traceback
from pathlib import Path
import bpy
from mathutils import Vector

BASE=Path(__file__).with_name('render_mpfb_pose_preview_v13.py')
spec=importlib.util.spec_from_file_location('mpfb_pose_v13',BASE)
if spec is None or spec.loader is None: raise RuntimeError('could not load v13')
v13=importlib.util.module_from_spec(spec); spec.loader.exec_module(v13)
v12=v13.v12; v10=v13.v10

# bone, axis, min delta deg, max delta deg. Directions come from v15 measured data.
PARAMS=[
 ('index_01_r','x',-34.0,0.0),('index_02_r','x',-38.0,0.0),('index_03_r','z',0.0,24.0),
 ('thumb_01_r','x',0.0,28.0),('thumb_01_r','y',0.0,28.0),('thumb_01_r','z',-32.0,0.0),
 ('thumb_02_r','x',0.0,24.0),('thumb_02_r','z',-34.0,0.0),
 ('thumb_03_r','x',0.0,20.0),('thumb_03_r','z',-26.0,0.0),
]

def _compose_delta(arm,bone,axis,degrees):
    pb=arm.pose.bones.get(bone)
    if pb is None: raise RuntimeError('missing '+bone)
    pb.rotation_quaternion=pb.rotation_quaternion @ v10._axis_q(axis,degrees)

def _apply(arm,p):
    v10._clear_pose(arm); v13._prebend(arm,2)
    for value,(bone,axis,_,_) in zip(p,PARAMS): _compose_delta(arm,bone,axis,value)
    bpy.context.view_layer.update()

def _state(arm):
    i=v10._world_pose(arm,'index_03_r',True); t=v10._world_pose(arm,'thumb_03_r',True)
    return i,t,i.lerp(t,.5),(t-i).length

def _score(arm,p,anchor):
    _apply(arm,p); i,t,mid,gap=_state(arm)
    reg=sum((v/max(abs(lo),abs(hi),1.0))**2 for v,(_,_,lo,hi) in zip(p,PARAMS))
    # Contact dominates; midpoint drift and regularization penalize loops.
    return abs(gap-.004)+(mid-anchor).length*.32+reg*.00065,gap,(mid-anchor).length,i,t,mid

def _solve(arm,seed,anchor):
    p=list(seed); best=_score(arm,p,anchor)
    for step in (12.0,6.0,3.0,1.5,.75):
        for _ in range(3):
            changed=False
            for j,(_,_,lo,hi) in enumerate(PARAMS):
                local=(best,p)
                for d in (-1,1):
                    q=p.copy(); q[j]=max(lo,min(hi,q[j]+d*step))
                    if q[j]==p[j]: continue
                    cand=_score(arm,q,anchor)
                    if cand[0]+1e-9<local[0][0]: local=(cand,q)
                if local[1] is not p: best,p=local; changed=True
            if not changed: break
    return best,tuple(round(x,3) for x in p)

def _run():
    v10.INPUT,v10.OUT=v10._args(); v10.OUT.mkdir(parents=True,exist_ok=True)
    _,arm,cam=v10._setup(); target=(v10._world_rest(arm,'hand_r')+v10._world_rest(arm,'middle_03_r',True))*.5; offset=Vector((-.18,-.28,.10))
    v10._clear_pose(arm); v13._prebend(arm,2); bi,bt,anchor,bgap=_state(arm)
    print('MPFB_POSE_V16_BASELINE gap',f'{bgap:.6f}')
    seeds=[(0.0,)*len(PARAMS),(-10,-10,10,10,10,-10,10,-10,10,-10),(-20,-16,8,12,16,-16,8,-18,6,-12)]
    rows=[]
    for seed in seeds:
        result,p=_solve(arm,seed,anchor); rows.append((result,p))
    rows.sort(key=lambda r:r[0][0])
    for rank,(result,p) in enumerate(rows[:3],1):
        _,gap,anchor_error,_,_,_=result; _apply(arm,p); v10._pinch_proxy(arm); bpy.context.view_layer.update()
        print('MPFB_POSE_V16',rank,'gap',f'{gap:.6f}','anchor_error',f'{anchor_error:.6f}','params',p)
        v10._render(cam,f'pinch_measured_{rank}',target,offset)
    best=rows[0][0]
    print('MPFB_POSE_BEST pinch_gap',f'{best[1]:.6f}','pinch_anchor_error',f'{best[2]:.6f}')
    print('MPFB_POSE_PRIOR measured_axes_v16')
    if best[1]>.012: raise RuntimeError(f'pinch gap gate failed: {best[1]:.6f} m > 0.012 m')
    if best[2]>.025: raise RuntimeError(f'pinch anchor error gate failed: {best[2]:.6f} m > 0.025 m')
    print('MPFB_POSE_PREVIEW_SUCCESS')

if __name__=='__main__':
    try:_run()
    except BaseException as e:
        print('MPFB_POSE_PREVIEW_ERROR:',e); traceback.print_exc(); raise
