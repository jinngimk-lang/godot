"""Render deterministic MPFB hand-pose diagnostics.

This stage intentionally isolates the GameEngine rig's natural finger flexion
axis before attempting vessel-wrap or label-pinch choreography. Earlier target-
driven IK and cross-product rotations both produced stretched/twisted claws.
The sweep below keeps every phalanx length unchanged and rotates only the right
index chain around one local cardinal axis at a time.
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
    bpy.context.view_layer.update()

def _rotate_local(arm,bone_name,axis,degrees):
    pb=arm.pose.bones.get(bone_name)
    if pb is None: raise RuntimeError(f'missing pose bone {bone_name}')
    axes={'x':Vector((1,0,0)),'y':Vector((0,1,0)),'z':Vector((0,0,1))}
    pb.rotation_mode='QUATERNION'; pb.rotation_quaternion=Quaternion(axes[axis],math.radians(degrees))

def _curl_index(arm,axis,sign):
    # Proximal / intermediate / distal flexion magnitudes approximate a relaxed
    # grasp. Only the axis/sign changes between diagnostic renders.
    for bone,deg in [('index_01_r',26),('index_02_r',42),('index_03_r',30)]:
        _rotate_local(arm,bone,axis,sign*deg)
    bpy.context.view_layer.update()

def _render(cam,name,target,offset):
    cam.location=target+offset; _look(cam,target); bpy.context.scene.render.filepath=str(OUT/f'{name}.png'); bpy.ops.render.render(write_still=True)
    p=OUT/f'{name}.png'
    if not p.is_file() or p.stat().st_size<=0: raise RuntimeError('render failed '+name)
    print('MPFB_POSE_FRAME',name,p.stat().st_size)

def _run():
    global INPUT,OUT; INPUT,OUT=_args(); OUT.mkdir(parents=True,exist_ok=True); mesh,arm,cam=_setup()
    target=(_world_rest(arm,'hand_r')+_world_rest(arm,'middle_03_r',True))*0.5
    camera_offset=Vector((-0.18,-0.28,0.10))
    _clear_pose(arm); _render(cam,'axis_neutral',target,camera_offset)
    for axis in ('x','z'):
        for sign,label in ((1,'pos'),(-1,'neg')):
            _clear_pose(arm); _curl_index(arm,axis,sign); _render(cam,f'axis_{axis}_{label}',target,camera_offset)
    print(SUCCESS)
if __name__=='__main__':
    try:_run()
    except BaseException as e:
        print(f'{ERROR}: {e}'); traceback.print_exc(); raise
