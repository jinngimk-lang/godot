"""Render deterministic support-wrap and label-pinch pose diagnostics for an extracted MPFB limb."""
from __future__ import annotations
import sys, traceback
from pathlib import Path
import bpy
from mathutils import Vector

SUCCESS='MPFB_POSE_PREVIEW_SUCCESS'; ERROR='MPFB_POSE_PREVIEW_ERROR'

def _args():
    if '--' not in sys.argv: raise RuntimeError('expected -- <input.glb> <output-dir>')
    v=sys.argv[sys.argv.index('--')+1:]
    if len(v)!=2: raise RuntimeError('expected two arguments after --')
    return Path(v[0]).resolve(),Path(v[1]).resolve()

def _reset(): bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)

def _look(camera,target): camera.rotation_euler=(target-camera.location).to_track_quat('-Z','Y').to_euler()

def _world(arm,bone,tail=False):
    pb=arm.pose.bones.get(bone)
    if pb is None: raise RuntimeError(f'missing bone {bone}')
    return arm.matrix_world@(pb.tail if tail else pb.head)

def _skin_material(mesh):
    mat=bpy.data.materials.new('PosePreviewSkin'); mat.use_nodes=True; mat.diffuse_color=(0.38,0.19,0.11,1)
    p=next((n for n in mat.node_tree.nodes if n.type=='BSDF_PRINCIPLED'),None)
    if p:
        p.inputs['Base Color'].default_value=(0.38,0.19,0.11,1)
        p.inputs['Roughness'].default_value=0.58
    mesh.data.materials.clear(); mesh.data.materials.append(mat)

def _mat(name,color,rough=.45):
    m=bpy.data.materials.new(name); m.use_nodes=True; m.diffuse_color=(*color,1)
    p=next((n for n in m.node_tree.nodes if n.type=='BSDF_PRINCIPLED'),None)
    if p: p.inputs['Base Color'].default_value=(*color,1); p.inputs['Roughness'].default_value=rough
    return m

def _setup():
    _reset(); bpy.ops.import_scene.gltf(filepath=str(INPUT))
    meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']; arms=[o for o in bpy.context.scene.objects if o.type=='ARMATURE']
    if not meshes or not arms: raise RuntimeError('pose source must contain mesh and armature')
    mesh=max(meshes,key=lambda o:len(o.data.vertices)); arm=arms[0]; _skin_material(mesh)
    sc=bpy.context.scene; sc.render.engine='BLENDER_EEVEE_NEXT'; sc.render.resolution_x=720; sc.render.resolution_y=720; sc.render.resolution_percentage=100; sc.render.image_settings.file_format='PNG'; sc.world.color=(0.025,0.028,0.035)
    cd=bpy.data.cameras.new('PoseCamera'); cam=bpy.data.objects.new('PoseCamera',cd); sc.collection.objects.link(cam); sc.camera=cam; cd.lens=62
    kd=bpy.data.lights.new('Key','AREA'); kd.energy=380; kd.size=0.8; key=bpy.data.objects.new('Key',kd); key.location=(-0.62,-0.58,0.58); sc.collection.objects.link(key)
    fd=bpy.data.lights.new('Fill','AREA'); fd.energy=120; fd.size=0.7; fill=bpy.data.objects.new('Fill',fd); fill.location=(-0.20,0.08,0.35); sc.collection.objects.link(fill)
    return mesh,arm,cam

def _clear_pose(arm):
    for pb in arm.pose.bones:
        pb.rotation_mode='QUATERNION'; pb.rotation_quaternion=(1,0,0,0); pb.location=(0,0,0); pb.scale=(1,1,1)
        for c in list(pb.constraints): pb.constraints.remove(c)
    for o in list(bpy.context.scene.objects):
        if o.get('pose_target'): bpy.data.objects.remove(o,do_unlink=True)
    bpy.context.view_layer.update()

def _target(name,loc):
    o=bpy.data.objects.new(name,None); o.empty_display_type='SPHERE'; o.empty_display_size=.006; o.location=loc; o['pose_target']=True; bpy.context.scene.collection.objects.link(o); return o

def _ik(arm,bone,target,chain=3):
    pb=arm.pose.bones.get(bone)
    if pb is None: raise RuntimeError(f'missing IK bone {bone}')
    c=pb.constraints.new('IK'); c.target=target; c.chain_count=chain; c.use_tail=True; c.iterations=64

def _proxy_cylinder(center):
    bpy.ops.mesh.primitive_cylinder_add(vertices=64, radius=.043, depth=.15, location=center)
    o=bpy.context.object; o.name='VesselProxy'; o.data.materials.append(_mat('VesselProxyMat',(0.12,0.28,0.40),.32)); return o

def _proxy_flap(center):
    bpy.ops.mesh.primitive_cube_add(size=1, location=center)
    o=bpy.context.object; o.name='FlapProxy'; o.scale=(.025,.004,.018); o.data.materials.append(_mat('FlapProxyMat',(0.70,0.52,0.20),.7)); return o

def _support_wrap(arm):
    palm=_world(arm,'hand_r'); center=palm+Vector((-0.008,-0.095,-0.055)); _proxy_cylinder(center)
    targets={
      'index_03_r':center+Vector((-0.047,-0.006,0.045)),
      'middle_03_r':center+Vector((-0.049,-0.004,0.012)),
      'ring_03_r':center+Vector((-0.047,-0.001,-0.020)),
      'pinky_03_r':center+Vector((-0.041,0.003,-0.048)),
      'thumb_03_r':center+Vector((0.045,-0.006,0.032)),
    }
    for b,p in targets.items(): _ik(arm,b,_target('T_'+b,p),3)
    bpy.context.view_layer.update(); return center

def _pinch(arm):
    palm=_world(arm,'hand_r'); center=palm+Vector((0.000,-0.108,-0.040)); _proxy_flap(center)
    _ik(arm,'index_03_r',_target('T_index',center+Vector((-0.004,-0.003,0.004))),3)
    _ik(arm,'thumb_03_r',_target('T_thumb',center+Vector((0.004,-0.003,-0.002))),3)
    for i,(bone,off) in enumerate([
      ('middle_03_r',Vector((-0.030,0.025,-0.015))),('ring_03_r',Vector((-0.022,0.030,-0.036))),('pinky_03_r',Vector((-0.012,0.034,-0.054))) ]):
        _ik(arm,bone,_target('T_relaxed_'+str(i),palm+off),3)
    bpy.context.view_layer.update(); return center

def _render(cam,name,target,offset):
    cam.location=target+offset; _look(cam,target); bpy.context.scene.render.filepath=str(OUT/f'{name}.png'); bpy.ops.render.render(write_still=True)
    p=OUT/f'{name}.png'
    if not p.is_file() or p.stat().st_size<=0: raise RuntimeError('render failed '+name)
    print('MPFB_POSE_FRAME',name,p.stat().st_size)

def _run():
    global INPUT,OUT; INPUT,OUT=_args(); OUT.mkdir(parents=True,exist_ok=True); mesh,arm,cam=_setup()
    _clear_pose(arm); c=_support_wrap(arm); _render(cam,'support_wrap_front',c,Vector((0.02,-0.34,0.06))); _render(cam,'support_wrap_oblique',c,Vector((-0.25,-0.23,0.14)))
    for o in list(bpy.context.scene.objects):
        if o.name=='VesselProxy': bpy.data.objects.remove(o,do_unlink=True)
    _clear_pose(arm); c=_pinch(arm); _render(cam,'peel_pinch_front',c,Vector((0.02,-0.34,0.06))); _render(cam,'peel_pinch_oblique',c,Vector((-0.25,-0.23,0.14)))
    print(SUCCESS)
if __name__=='__main__':
    try:_run()
    except BaseException as e:
        print(f'{ERROR}: {e}'); traceback.print_exc(); raise
