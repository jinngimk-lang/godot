"""Render deterministic MPFB hero-hand pose-family diagnostics.

Axis spike v4 established that local +Z flexion on the GameEngine finger chains
produces the first anatomically credible inward curl without changing phalanx
lengths. This stage uses that result to test whole-hand vessel-wrap and
thumb/index pinch candidates. It deliberately renders several thumb-opposition
variants rather than guessing one production pose.
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
        if o.name.startswith('PoseProxy_'):
            bpy.data.objects.remove(o,do_unlink=True)
    bpy.context.view_layer.update()

def _rotate_local(arm,bone_name,axis,degrees):
    pb=arm.pose.bones.get(bone_name)
    if pb is None: raise RuntimeError(f'missing pose bone {bone_name}')
    axes={'x':Vector((1,0,0)),'y':Vector((0,1,0)),'z':Vector((0,0,1))}
    pb.rotation_mode='QUATERNION'; pb.rotation_quaternion=Quaternion(axes[axis],math.radians(degrees))

def _curl_chain(arm,prefix,degrees):
    for index,deg in enumerate(degrees,1):
        _rotate_local(arm,f'{prefix}_0{index}_r','z',deg)

def _curl_support_fingers(arm):
    # Progressive curl: middle/ring/pinky wrap more deeply than index, matching
    # a relaxed cylindrical support grip rather than a uniform claw.
    _curl_chain(arm,'index',(31,48,32))
    _curl_chain(arm,'middle',(38,58,38))
    _curl_chain(arm,'ring',(43,63,42))
    _curl_chain(arm,'pinky',(47,67,45))

def _curl_pinch_index(arm):
    _curl_chain(arm,'index',(25,39,24))
    _curl_chain(arm,'middle',(20,28,18))
    _curl_chain(arm,'ring',(24,34,22))
    _curl_chain(arm,'pinky',(28,38,26))

def _pose_thumb(arm,axis,sign,mode):
    if mode=='support': vals=(26,34,24)
    else: vals=(18,30,20)
    for i,deg in enumerate(vals,1):
        _rotate_local(arm,f'thumb_0{i}_r',axis,sign*deg)

def _add_cylinder_proxy(arm):
    # A diagnostic vessel proxy located just beyond the knuckle line. It is a
    # scale/contact guide only; gameplay alignment is a later Godot gate.
    hand=_world_rest(arm,'hand_r'); mid=_world_rest(arm,'middle_02_r'); tip=_world_rest(arm,'middle_03_r',True)
    center=mid.lerp(tip,0.28)
    bpy.ops.mesh.primitive_cylinder_add(vertices=48,radius=.038,depth=.19,location=center)
    obj=bpy.context.object; obj.name='PoseProxy_Vessel'; obj.data.materials.append(_proxy_material('VesselProxy',(0.12,0.24,0.34,1),.38))
    # Orient the rod roughly across the hand so curled fingers visibly oppose it.
    direction=(hand-_world_rest(arm,'index_01_r')).normalized()
    obj.rotation_euler=direction.to_track_quat('Z','Y').to_euler()
    return obj

def _add_flap_proxy(arm):
    index_tip=_world_rest(arm,'index_03_r',True); thumb_tip=_world_rest(arm,'thumb_03_r',True)
    center=index_tip.lerp(thumb_tip,.5)
    bpy.ops.mesh.primitive_cube_add(size=1,location=center)
    obj=bpy.context.object; obj.name='PoseProxy_Flap'; obj.scale=(.026,.004,.018); obj.data.materials.append(_proxy_material('FlapProxy',(0.74,0.62,0.38,1),.82))
    return obj

def _render(cam,name,target,offset):
    cam.location=target+offset; _look(cam,target); bpy.context.scene.render.filepath=str(OUT/f'{name}.png'); bpy.ops.render.render(write_still=True)
    p=OUT/f'{name}.png'
    if not p.is_file() or p.stat().st_size<=0: raise RuntimeError('render failed '+name)
    print('MPFB_POSE_FRAME',name,p.stat().st_size)

def _run():
    global INPUT,OUT; INPUT,OUT=_args(); OUT.mkdir(parents=True,exist_ok=True); mesh,arm,cam=_setup()
    target=(_world_rest(arm,'hand_r')+_world_rest(arm,'middle_03_r',True))*0.5
    camera_offset=Vector((-0.18,-0.28,0.10))

    _clear_pose(arm); _render(cam,'pose_neutral',target,camera_offset)

    # Support-grip family. Finger flexion is fixed to the validated +Z axis;
    # only thumb opposition changes so visual evidence can choose the winner.
    for axis,sign,label in [('x',1,'xp'),('x',-1,'xn'),('z',1,'zp'),('z',-1,'zn')]:
        _clear_pose(arm); _curl_support_fingers(arm); _pose_thumb(arm,axis,sign,'support'); _add_cylinder_proxy(arm); bpy.context.view_layer.update()
        _render(cam,f'support_{label}',target,camera_offset)

    # Pinch family. Index is partially flexed while the other fingers relax;
    # thumb variants test which local opposition direction actually meets it.
    for axis,sign,label in [('x',1,'xp'),('x',-1,'xn'),('z',1,'zp'),('z',-1,'zn')]:
        _clear_pose(arm); _curl_pinch_index(arm); _pose_thumb(arm,axis,sign,'pinch'); _add_flap_proxy(arm); bpy.context.view_layer.update()
        _render(cam,f'pinch_{label}',target,camera_offset)

    print(SUCCESS)
if __name__=='__main__':
    try:_run()
    except BaseException as e:
        print(f'{ERROR}: {e}'); traceback.print_exc(); raise
