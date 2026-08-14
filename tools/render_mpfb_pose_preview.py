"""Render deterministic MPFB support-wrap and label-pinch pose diagnostics.

This version deliberately does not use Blender IK. Two real-frame experiments
proved that target-driven IK produced unacceptable stretched/claw silhouettes.
Instead every phalanx keeps its authored length and receives a bounded local
rotation toward a contact region.
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

def _mat(name,color,rough=.45):
    m=bpy.data.materials.new(name); m.use_nodes=True
    p=next((n for n in m.node_tree.nodes if n.type=='BSDF_PRINCIPLED'),None)
    if p: p.inputs['Base Color'].default_value=(*color,1); p.inputs['Roughness'].default_value=rough
    return m

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
        if o.get('pose_proxy'): bpy.data.objects.remove(o,do_unlink=True)
    bpy.context.view_layer.update()

def _proxy_cylinder(center):
    bpy.ops.mesh.primitive_cylinder_add(vertices=48, radius=.030, depth=.105, location=center)
    o=bpy.context.object; o.name='VesselProxy'; o['pose_proxy']=True; o.data.materials.append(_mat('VesselProxyMat',(0.12,0.28,0.40),.32)); return o

def _proxy_flap(center):
    bpy.ops.mesh.primitive_cube_add(size=1, location=center)
    o=bpy.context.object; o.name='FlapProxy'; o['pose_proxy']=True; o.scale=(.020,.003,.014); o.data.materials.append(_mat('FlapProxyMat',(0.70,0.52,0.20),.7)); return o

def _bend_toward(arm,bone_name,target_world,degrees):
    """Rotate one pose bone locally toward target while preserving its length."""
    b=arm.data.bones.get(bone_name); pb=arm.pose.bones.get(bone_name)
    if b is None or pb is None: raise RuntimeError(f'missing bend bone {bone_name}')
    head=arm.matrix_world@b.head_local; tail=arm.matrix_world@b.tail_local
    direction=(tail-head).normalized(); desired=(target_world-head).normalized()
    axis_world=direction.cross(desired)
    if axis_world.length_squared<1e-8: return
    axis_world.normalize()
    axis_arm=arm.matrix_world.to_3x3().inverted()@axis_world
    axis_local=b.matrix_local.to_3x3().inverted()@axis_arm
    if axis_local.length_squared<1e-8: return
    axis_local.normalize()
    pb.rotation_mode='QUATERNION'; pb.rotation_quaternion=Quaternion(axis_local,math.radians(degrees))

def _curl_finger(arm,prefix,target,angles):
    for idx,deg in zip((1,2,3),angles): _bend_toward(arm,f'{prefix}_{idx:02d}_r',target,deg)

def _support_wrap(arm):
    index_tip=_world_rest(arm,'index_03_r',True); thumb_tip=_world_rest(arm,'thumb_03_r',True)
    center=(index_tip+thumb_tip)*0.5+Vector((0.0,0.022,-0.006)); _proxy_cylinder(center)
    far=center+Vector((-0.027,0.002,-0.002))
    _curl_finger(arm,'index',far,(24,38,28))
    _curl_finger(arm,'middle',far+Vector((-0.002,0.0,-0.010)),(28,42,30))
    _curl_finger(arm,'ring',far+Vector((-0.001,0.0,-0.020)),(30,44,32))
    _curl_finger(arm,'pinky',far+Vector((0.002,0.0,-0.030)),(28,42,32))
    _curl_finger(arm,'thumb',center+Vector((0.028,-0.003,0.008)),(18,30,24))
    _bend_toward(arm,'hand_r',center,14)
    bpy.context.view_layer.update(); return center

def _pinch(arm):
    index_tip=_world_rest(arm,'index_03_r',True); thumb_tip=_world_rest(arm,'thumb_03_r',True)
    center=(index_tip+thumb_tip)*0.5+Vector((0.0,0.012,0.002)); _proxy_flap(center)
    _curl_finger(arm,'index',center+Vector((-0.003,0.0,0.002)),(18,34,24))
    _curl_finger(arm,'thumb',center+Vector((0.003,0.0,-0.002)),(20,34,22))
    palm=_world_rest(arm,'hand_r')
    _curl_finger(arm,'middle',palm+Vector((-0.020,-0.085,-0.030)),(18,28,22))
    _curl_finger(arm,'ring',palm+Vector((-0.015,-0.072,-0.045)),(22,32,24))
    _curl_finger(arm,'pinky',palm+Vector((-0.010,-0.060,-0.052)),(24,34,26))
    _bend_toward(arm,'hand_r',center,9)
    bpy.context.view_layer.update(); return center

def _render(cam,name,target,offset):
    cam.location=target+offset; _look(cam,target); bpy.context.scene.render.filepath=str(OUT/f'{name}.png'); bpy.ops.render.render(write_still=True)
    p=OUT/f'{name}.png'
    if not p.is_file() or p.stat().st_size<=0: raise RuntimeError('render failed '+name)
    print('MPFB_POSE_FRAME',name,p.stat().st_size)

def _run():
    global INPUT,OUT; INPUT,OUT=_args(); OUT.mkdir(parents=True,exist_ok=True); mesh,arm,cam=_setup()
    _clear_pose(arm); neutral=(_world_rest(arm,'hand_r')+_world_rest(arm,'middle_03_r',True))*0.5; _render(cam,'neutral_limb',neutral,Vector((-0.18,-0.28,0.10)))
    _clear_pose(arm); c=_support_wrap(arm); _render(cam,'support_wrap_front',c,Vector((0.02,-0.28,0.07))); _render(cam,'support_wrap_oblique',c,Vector((-0.21,-0.20,0.13)))
    _clear_pose(arm); c=_pinch(arm); _render(cam,'peel_pinch_front',c,Vector((0.02,-0.28,0.07))); _render(cam,'peel_pinch_oblique',c,Vector((-0.21,-0.20,0.13)))
    print(SUCCESS)
if __name__=='__main__':
    try:_run()
    except BaseException as e:
        print(f'{ERROR}: {e}'); traceback.print_exc(); raise
