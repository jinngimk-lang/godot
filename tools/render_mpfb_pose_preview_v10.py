"""Render MPFB support wrap and solve a coupled index/thumb peel pinch.

v9 proved that solving only the thumb cannot close a believable paper-flap pinch:
the best candidates still left roughly 18-22 mm of visible thumb/index separation.
This v10 spike makes that hypothesis falsifiable by optimizing the index flexion and
thumb opposition together while folding the unused fingers toward the palm.

The objective is deliberately contact-centric: target a 4 mm fingertip gap around a
thin paper proxy, keep the contact midpoint near the neutral index-tip region, and
regularize the joint angles so a mathematically small gap cannot win by creating a
looped or inverted digit. Runtime/visual review remains mandatory after the metric
passes.
"""
from __future__ import annotations
import math, sys, traceback
from pathlib import Path
import bpy
from mathutils import Vector, Quaternion

SUCCESS='MPFB_POSE_PREVIEW_SUCCESS'; ERROR='MPFB_POSE_PREVIEW_ERROR'

def _args():
    if '--' not in sys.argv: raise RuntimeError('expected -- <input.glb> <output-dir>')
    v=sys.argv[sys.argv.index('--')+1:]
    if len(v)!=2: raise RuntimeError('expected two arguments after --')
    return Path(v[0]).resolve(),Path(v[1]).resolve()

def _reset(): bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
def _look(camera,target): camera.rotation_euler=(target-camera.location).to_track_quat('-Z','Y').to_euler()

def _world_rest(arm,bone,tail=False):
    b=arm.data.bones.get(bone)
    if b is None: raise RuntimeError(f'missing bone {bone}')
    return arm.matrix_world@(b.tail_local if tail else b.head_local)

def _world_pose(arm,bone,tail=False):
    pb=arm.pose.bones.get(bone)
    if pb is None: raise RuntimeError(f'missing pose bone {bone}')
    return arm.matrix_world@(pb.tail if tail else pb.head)

def _skin_material(mesh):
    mat=bpy.data.materials.new('PosePreviewSkin'); mat.use_nodes=True
    p=next((n for n in mat.node_tree.nodes if n.type=='BSDF_PRINCIPLED'),None)
    if p:
        p.inputs['Base Color'].default_value=(0.34,0.16,0.085,1)
        p.inputs['Roughness'].default_value=0.64
    mesh.data.materials.clear(); mesh.data.materials.append(mat)

def _proxy_material(name,color,roughness=.55):
    mat=bpy.data.materials.new(name); mat.diffuse_color=color; mat.use_nodes=True
    p=next((n for n in mat.node_tree.nodes if n.type=='BSDF_PRINCIPLED'),None)
    if p:
        p.inputs['Base Color'].default_value=color
        p.inputs['Roughness'].default_value=roughness
        p.inputs['Metallic'].default_value=0.0
    return mat

def _setup():
    _reset(); bpy.ops.import_scene.gltf(filepath=str(INPUT))
    meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']; arms=[o for o in bpy.context.scene.objects if o.type=='ARMATURE']
    if not meshes or not arms: raise RuntimeError('pose source must contain mesh and armature')
    mesh=max(meshes,key=lambda o:len(o.data.vertices)); arm=arms[0]; _skin_material(mesh)
    sc=bpy.context.scene; sc.render.engine='BLENDER_EEVEE_NEXT'; sc.render.resolution_x=640; sc.render.resolution_y=640; sc.render.resolution_percentage=100; sc.render.image_settings.file_format='PNG'; sc.world.color=(0.025,0.028,0.035)
    cd=bpy.data.cameras.new('PoseCamera'); cam=bpy.data.objects.new('PoseCamera',cd); sc.collection.objects.link(cam); sc.camera=cam; cd.lens=68
    kd=bpy.data.lights.new('Key','AREA'); kd.energy=270; kd.size=0.8; key=bpy.data.objects.new('Key',kd); key.location=(-0.62,-0.58,0.58); sc.collection.objects.link(key)
    fd=bpy.data.lights.new('Fill','AREA'); fd.energy=80; fd.size=0.7; fill=bpy.data.objects.new('Fill',fd); fill.location=(-0.20,0.08,0.35); sc.collection.objects.link(fill)
    return mesh,arm,cam

def _clear_pose(arm):
    for pb in arm.pose.bones:
        pb.rotation_mode='QUATERNION'; pb.rotation_quaternion=Quaternion((1,0,0,0)); pb.location=(0,0,0); pb.scale=(1,1,1)
        for c in list(pb.constraints): pb.constraints.remove(c)
    for o in list(bpy.context.scene.objects):
        if o.name.startswith('PoseProxy_'): bpy.data.objects.remove(o,do_unlink=True)
    bpy.context.view_layer.update()

def _axis_q(axis,degrees):
    axes={'x':Vector((1,0,0)),'y':Vector((0,1,0)),'z':Vector((0,0,1))}
    return Quaternion(axes[axis],math.radians(degrees))

def _set_axis(arm,bone_name,axis,degrees):
    pb=arm.pose.bones.get(bone_name)
    if pb is None: raise RuntimeError(f'missing pose bone {bone_name}')
    pb.rotation_mode='QUATERNION'; pb.rotation_quaternion=_axis_q(axis,degrees)

def _set_xyz(arm,bone_name,angles):
    pb=arm.pose.bones.get(bone_name)
    if pb is None: raise RuntimeError(f'missing pose bone {bone_name}')
    x,y,z=angles; pb.rotation_mode='QUATERNION'; pb.rotation_quaternion=_axis_q('x',x)@_axis_q('y',y)@_axis_q('z',z)

def _curl_chain(arm,prefix,degrees):
    for index,deg in enumerate(degrees,1): _set_axis(arm,f'{prefix}_0{index}_r','z',deg)

def _support_fingers(arm):
    _curl_chain(arm,'index',(18,30,20)); _curl_chain(arm,'middle',(23,36,24)); _curl_chain(arm,'ring',(27,42,29)); _curl_chain(arm,'pinky',(31,47,33))

def _pinch_unused_fingers(arm):
    # Keep unused digits folded and staggered so they read as a relaxed fist behind
    # the pinch rather than three parallel hanging hooks.
    _curl_chain(arm,'middle',(48,66,44)); _curl_chain(arm,'ring',(54,74,50)); _curl_chain(arm,'pinky',(60,82,56))

def _apply_thumb(arm,p):
    _set_xyz(arm,'thumb_01_r',p[0:3]); _set_xyz(arm,'thumb_02_r',p[3:6]); _set_xyz(arm,'thumb_03_r',p[6:9]); bpy.context.view_layer.update()

def _apply_pinch(arm,p):
    _curl_chain(arm,'index',p[0:3]); _apply_thumb(arm,p[3:12])

SUPPORT_BOUNDS=[(-38,38),(-40,40),(-42,42),(-14,14),(-18,18),(-36,36),(-10,10),(-10,10),(-28,28)]
PINCH_BOUNDS=[
    (8,58),(10,72),(8,58),
    (-62,62),(-56,56),(-62,62),
    (-18,18),(-22,22),(-44,44),
    (-12,12),(-12,12),(-34,34),
]

def _clamp(v,lo,hi): return max(lo,min(hi,v))
def _regularization(p,bounds,weight):
    energy=0.0
    for value,(lo,hi) in zip(p,bounds):
        center=(lo+hi)*0.5; span=max((hi-lo)*0.5,1.0); energy+=((value-center)/span)**2
    return energy*weight

def _finger_centroid(arm):
    pts=[_world_pose(arm,'index_02_r',True),_world_pose(arm,'middle_02_r',True),_world_pose(arm,'ring_02_r',True)]
    return sum(pts,Vector((0,0,0)))/len(pts)

def _support_target(arm):
    fingers=_finger_centroid(arm); palm=_world_pose(arm,'hand_r'); rest_thumb=_world_rest(arm,'thumb_03_r',True)
    side=rest_thumb-palm
    if side.length<1e-6: side=Vector((1,0,0))
    side.normalize(); return fingers+side*0.070

def _score_support(arm,p):
    _apply_thumb(arm,p); goal=_support_target(arm); tip=_world_pose(arm,'thumb_03_r',True)
    return (tip-goal).length+_regularization(p,SUPPORT_BOUNDS,.0045),(tip-goal).length,goal.copy(),tip.copy()

def _pinch_contact_state(arm):
    index_tip=_world_pose(arm,'index_03_r',True); thumb_tip=_world_pose(arm,'thumb_03_r',True)
    return index_tip,thumb_tip,index_tip.lerp(thumb_tip,.5),(thumb_tip-index_tip).length

def _score_pinch(arm,p,contact_anchor):
    _apply_pinch(arm,p)
    index_tip,thumb_tip,mid,gap=_pinch_contact_state(arm)
    desired_gap=.004
    gap_error=abs(gap-desired_gap)
    anchor_error=(mid-contact_anchor).length
    # Contact dominates. Anchor and regularization prevent a tiny gap obtained by
    # folding both digits into an implausible location or loop.
    score=gap_error + anchor_error*.38 + _regularization(p,PINCH_BOUNDS,.0012)
    return score,gap_error,anchor_error,gap,index_tip.copy(),thumb_tip.copy(),mid.copy()

def _solve_support_seed(arm,seed):
    p=[_clamp(v,*SUPPORT_BOUNDS[i]) for i,v in enumerate(seed)]; _clear_pose(arm); _support_fingers(arm); best=_score_support(arm,p)
    for step in (20.0,10.0,5.0,2.5):
        for _ in range(3):
            changed=False
            for i,(lo,hi) in enumerate(SUPPORT_BOUNDS):
                local=(best,p)
                for direction in (-1.0,1.0):
                    q=p.copy(); q[i]=_clamp(q[i]+direction*step,lo,hi)
                    _clear_pose(arm); _support_fingers(arm); cand=_score_support(arm,q)
                    if cand[0]+1e-8<local[0][0]: local=(cand,q)
                if local[1] is not p: best,p=local; changed=True
            if not changed: break
    return best[0],best[1],tuple(round(v,3) for v in p),best[2],best[3]

def _solve_pinch_seed(arm,seed,contact_anchor):
    p=[_clamp(v,*PINCH_BOUNDS[i]) for i,v in enumerate(seed)]; _clear_pose(arm); _pinch_unused_fingers(arm); best=_score_pinch(arm,p,contact_anchor)
    for step in (18.0,9.0,4.5,2.25,1.125):
        for _ in range(4):
            changed=False
            for i,(lo,hi) in enumerate(PINCH_BOUNDS):
                local=(best,p)
                for direction in (-1.0,1.0):
                    q=p.copy(); q[i]=_clamp(q[i]+direction*step,lo,hi)
                    if q[i]==p[i]: continue
                    _clear_pose(arm); _pinch_unused_fingers(arm); cand=_score_pinch(arm,q,contact_anchor)
                    if cand[0]+1e-8<local[0][0]: local=(cand,q)
                if local[1] is not p: best,p=local; changed=True
            if not changed: break
    return best[0],best[1],best[2],best[3],tuple(round(v,3) for v in p),best[4],best[5],best[6]

def _solve_support(arm):
    seeds=[(0,0,0,0,0,0,0,0,0),(22,20,16,0,0,14,0,0,8),(-18,26,-10,0,0,16,0,0,8)]
    rows=[_solve_support_seed(arm,s) for s in seeds]; rows.sort(key=lambda r:r[0]); return rows[:3]

def _solve_pinch(arm,contact_anchor):
    seeds=[
        (24,38,24, 0,0,0, 0,0,0, 0,0,0),
        (32,48,30, 28,12,22, 0,0,8, 0,0,4),
        (38,56,34, 42,4,30, 0,0,-6, 0,0,-4),
        (20,34,20, -20,24,-10, 0,0,12, 0,0,6),
    ]
    rows=[_solve_pinch_seed(arm,s,contact_anchor) for s in seeds]; rows.sort(key=lambda r:r[0])
    unique=[]
    for row in rows:
        if all(sum(abs(a-b) for a,b in zip(row[4],u[4]))>5.0 for u in unique): unique.append(row)
    return unique[:3]

def _support_proxy(arm):
    fingers=_finger_centroid(arm); thumb=_world_pose(arm,'thumb_03_r',True); center=(fingers+thumb)*0.5
    axis=(_world_pose(arm,'hand_r')-_world_pose(arm,'lowerarm_r')).normalized()
    bpy.ops.mesh.primitive_cylinder_add(vertices=48,radius=.036,depth=.20,location=center)
    obj=bpy.context.object; obj.name='PoseProxy_Vessel'; obj.data.materials.append(_proxy_material('VesselProxy',(0.12,0.24,0.34,1),.38)); obj.rotation_euler=axis.to_track_quat('Z','Y').to_euler()

def _pinch_proxy(arm):
    index_tip,thumb_tip,center,_=_pinch_contact_state(arm)
    tangent=index_tip-thumb_tip
    if tangent.length<1e-6: tangent=Vector((1,0,0))
    bpy.ops.mesh.primitive_cube_add(size=1,location=center)
    obj=bpy.context.object; obj.name='PoseProxy_Flap'; obj.scale=(.024,.002,.016); obj.data.materials.append(_proxy_material('FlapProxy',(0.74,0.62,0.38,1),.82))

def _render(cam,name,target,offset):
    cam.location=target+offset; _look(cam,target); bpy.context.scene.render.filepath=str(OUT/f'{name}.png'); bpy.ops.render.render(write_still=True)
    p=OUT/f'{name}.png'
    if not p.is_file() or p.stat().st_size<=0: raise RuntimeError('render failed '+name)
    print('MPFB_POSE_FRAME',name,p.stat().st_size)

def _run():
    global INPUT,OUT; INPUT,OUT=_args(); OUT.mkdir(parents=True,exist_ok=True); mesh,arm,cam=_setup()
    target=(_world_rest(arm,'hand_r')+_world_rest(arm,'middle_03_r',True))*0.5; offset=Vector((-0.18,-0.28,0.10))
    _clear_pose(arm); neutral_index=_world_pose(arm,'index_03_r',True); neutral_thumb=_world_pose(arm,'thumb_03_r',True); contact_anchor=neutral_index.lerp(neutral_thumb,.32)
    _render(cam,'pose_neutral',target,offset)

    support=_solve_support(arm)
    for rank,row in enumerate(support,1):
        _,distance,params,goal,tip=row; _clear_pose(arm); _support_fingers(arm); _apply_thumb(arm,params); _support_proxy(arm); bpy.context.view_layer.update()
        print('MPFB_POSE_SOLVE support_solved rank',rank,'distance',f'{distance:.6f}','params',params)
        _render(cam,f'support_solved_{rank}',target,offset)

    pinch=_solve_pinch(arm,contact_anchor)
    for rank,row in enumerate(pinch,1):
        _,gap_error,anchor_error,gap,params,index_tip,thumb_tip,mid=row; _clear_pose(arm); _pinch_unused_fingers(arm); _apply_pinch(arm,params); _pinch_proxy(arm); bpy.context.view_layer.update()
        print('MPFB_POSE_SOLVE pinch_solved rank',rank,'gap',f'{gap:.6f}','gap_error',f'{gap_error:.6f}','anchor_error',f'{anchor_error:.6f}','params',params)
        _render(cam,f'pinch_solved_{rank}',target,offset)

    best_gap=pinch[0][3]
    print('MPFB_POSE_BEST support_distance',f'{support[0][1]:.6f}','pinch_gap',f'{best_gap:.6f}','pinch_anchor_error',f'{pinch[0][2]:.6f}')
    print('MPFB_POSE_PRIOR coupled_index_thumb_v10')
    if best_gap>0.010:
        raise RuntimeError(f'pinch contact gate failed: gap {best_gap:.6f} m > 0.010 m')
    print(SUCCESS)

if __name__=='__main__':
    try:_run()
    except BaseException as e:
        print(f'{ERROR}: {e}'); traceback.print_exc(); raise
