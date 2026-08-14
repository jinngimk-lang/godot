"""Solve and render MPFB hero-hand contact candidates with three-axis thumb opposition.

Evidence from prior spikes:
- local +Z is the credible flexion axis for the four long finger chains;
- single-axis thumb sweeps and an X/Z-only grid can reduce endpoint distance but
  still produce visually wrong opposition and cannot close label pinch contact.

This stage models the thumb as a coupled 3D chain. A bounded coordinate-descent
solver explores local X/Y/Z on the proximal thumb and smaller multi-axis motion
on the distal joints. The objective is physical endpoint contact, but all winners
must still pass visual anatomy review before gameplay integration.
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
    x,y,z=angles
    pb.rotation_mode='QUATERNION'
    # Stable local composition order. Bounds below keep this away from singular extremes.
    pb.rotation_quaternion=_axis_q('x',x)@_axis_q('y',y)@_axis_q('z',z)

def _curl_chain(arm,prefix,degrees):
    for index,deg in enumerate(degrees,1): _set_axis(arm,f'{prefix}_0{index}_r','z',deg)

def _support_fingers(arm):
    _curl_chain(arm,'index',(31,48,32)); _curl_chain(arm,'middle',(38,58,38)); _curl_chain(arm,'ring',(43,63,42)); _curl_chain(arm,'pinky',(47,67,45))

def _pinch_fingers(arm):
    _curl_chain(arm,'index',(25,39,24)); _curl_chain(arm,'middle',(14,20,12)); _curl_chain(arm,'ring',(18,25,16)); _curl_chain(arm,'pinky',(22,30,20))

def _apply_thumb(arm,p):
    _set_xyz(arm,'thumb_01_r',p[0:3]); _set_xyz(arm,'thumb_02_r',p[3:6]); _set_xyz(arm,'thumb_03_r',p[6:9]); bpy.context.view_layer.update()

# Anatomically conservative bounds: proximal joint gets the largest ab/adduction
# freedom; distal joints mostly flex but retain small transverse correction.
BOUNDS=[(-55,55),(-60,60),(-60,60),(-20,20),(-25,25),(-55,55),(-15,15),(-15,15),(-45,45)]

def _clamp(v,lo,hi): return max(lo,min(hi,v))
def _regularization(p): return sum(abs(v) for v in p)/900.0*0.0015

def _finger_centroid(arm):
    pts=[_world_pose(arm,'index_02_r',True),_world_pose(arm,'middle_02_r',True),_world_pose(arm,'ring_02_r',True)]
    return sum(pts,Vector((0,0,0)))/len(pts)

def _support_target(arm):
    # We want the thumb on the opposite side of a ~76 mm vessel gap from the
    # curled finger contact centroid. Direction is seeded from natural thumb side.
    fingers=_finger_centroid(arm); palm=_world_pose(arm,'hand_r'); rest_thumb=_world_rest(arm,'thumb_03_r',True)
    side=rest_thumb-palm
    if side.length<1e-6: side=Vector((1,0,0))
    side.normalize()
    return fingers+side*0.076

def _pinch_target(arm): return _world_pose(arm,'index_03_r',True)

def _score(arm,target_fn,p):
    _apply_thumb(arm,p); goal=target_fn(arm); tip=_world_pose(arm,'thumb_03_r',True)
    return (tip-goal).length+_regularization(p),(tip-goal).length,goal.copy(),tip.copy()

def _solve_seed(arm,base_pose,target_fn,seed):
    p=list(seed); _clear_pose(arm); base_pose(arm); best=_score(arm,target_fn,p)
    # Coarse-to-fine coordinate descent. Each stage touches at most 9*2 candidates,
    # dramatically cheaper than the previous 1080-point brute-force grid.
    for step in (24.0,12.0,6.0,3.0):
        changed=True; passes=0
        while changed and passes<3:
            changed=False; passes+=1
            for i,(lo,hi) in enumerate(BOUNDS):
                local_best=best; local_p=p
                for direction in (-1.0,1.0):
                    q=p.copy(); q[i]=_clamp(q[i]+direction*step,lo,hi)
                    if q[i]==p[i]: continue
                    _clear_pose(arm); base_pose(arm); cand=_score(arm,target_fn,q)
                    if cand[0]+1e-8<local_best[0]: local_best=cand; local_p=q
                if local_p is not p:
                    p=local_p; best=local_best; changed=True
                else:
                    _clear_pose(arm); base_pose(arm); best=_score(arm,target_fn,p)
    return best[0],best[1],tuple(round(v,3) for v in p),best[2],best[3]

def _solve_multi(arm,base_pose,target_fn):
    seeds=[
        (0,0,0, 0,0,0, 0,0,0),
        (25,25,15, 0,0,15, 0,0,10),
        (25,-25,15, 0,0,15, 0,0,10),
        (-20,30,-10, 0,0,20, 0,0,10),
        (40,0,30, 0,0,-15, 0,0,5),
    ]
    ranked=[_solve_seed(arm,base_pose,target_fn,s) for s in seeds]
    ranked.sort(key=lambda r:r[0])
    # Deduplicate near-identical coordinate-descent endpoints.
    unique=[]
    for row in ranked:
        if all(sum(abs(a-b) for a,b in zip(row[2],u[2]))>3.0 for u in unique): unique.append(row)
    return unique[:3]

def _support_proxy(arm):
    fingers=_finger_centroid(arm); thumb=_world_pose(arm,'thumb_03_r',True); center=(fingers+thumb)*0.5
    # Orient cylinder along the local hand/forearm direction; radius matches expected vessel scale.
    axis=(_world_pose(arm,'hand_r')-_world_pose(arm,'lowerarm_r')).normalized()
    bpy.ops.mesh.primitive_cylinder_add(vertices=48,radius=.038,depth=.20,location=center)
    obj=bpy.context.object; obj.name='PoseProxy_Vessel'; obj.data.materials.append(_proxy_material('VesselProxy',(0.12,0.24,0.34,1),.38)); obj.rotation_euler=axis.to_track_quat('Z','Y').to_euler()

def _pinch_proxy(arm):
    index_tip=_world_pose(arm,'index_03_r',True); thumb_tip=_world_pose(arm,'thumb_03_r',True); center=index_tip.lerp(thumb_tip,.5)
    bpy.ops.mesh.primitive_cube_add(size=1,location=center)
    obj=bpy.context.object; obj.name='PoseProxy_Flap'; obj.scale=(.024,.003,.016); obj.data.materials.append(_proxy_material('FlapProxy',(0.74,0.62,0.38,1),.82))

def _render(cam,name,target,offset):
    cam.location=target+offset; _look(cam,target); bpy.context.scene.render.filepath=str(OUT/f'{name}.png'); bpy.ops.render.render(write_still=True)
    p=OUT/f'{name}.png'
    if not p.is_file() or p.stat().st_size<=0: raise RuntimeError('render failed '+name)
    print('MPFB_POSE_FRAME',name,p.stat().st_size)

def _render_solved(arm,cam,target,offset,prefix,base_pose,target_fn,proxy_fn):
    ranked=_solve_multi(arm,base_pose,target_fn)
    for rank,row in enumerate(ranked,1):
        _,distance,params,goal,tip=row
        print('MPFB_POSE_SOLVE',prefix,'rank',rank,'distance',f'{distance:.6f}','params',params,'goal',tuple(round(v,5) for v in goal),'thumb_tip',tuple(round(v,5) for v in tip))
        _clear_pose(arm); base_pose(arm); _apply_thumb(arm,params); proxy_fn(arm); bpy.context.view_layer.update(); _render(cam,f'{prefix}_{rank}',target,offset)
    return ranked

def _run():
    global INPUT,OUT; INPUT,OUT=_args(); OUT.mkdir(parents=True,exist_ok=True); mesh,arm,cam=_setup()
    target=(_world_rest(arm,'hand_r')+_world_rest(arm,'middle_03_r',True))*0.5; offset=Vector((-0.18,-0.28,0.10))
    _clear_pose(arm); _render(cam,'pose_neutral',target,offset)
    support=_render_solved(arm,cam,target,offset,'support_solved',_support_fingers,_support_target,_support_proxy)
    pinch=_render_solved(arm,cam,target,offset,'pinch_solved',_pinch_fingers,_pinch_target,_pinch_proxy)
    print('MPFB_POSE_BEST support_distance',f'{support[0][1]:.6f}','pinch_distance',f'{pinch[0][1]:.6f}')
    print(SUCCESS)
if __name__=='__main__':
    try:_run()
    except BaseException as e:
        print(f'{ERROR}: {e}'); traceback.print_exc(); raise
