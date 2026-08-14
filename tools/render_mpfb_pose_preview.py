"""Solve and render deterministic MPFB hero-hand contact candidates.

The preceding axis/pose spikes established two useful facts from real renders:
(1) local +Z is the credible flexion direction for the four finger chains;
(2) single-axis thumb guesses do not create actual opposition/contact.

This stage therefore keeps the validated finger flexion and searches a bounded,
anatomically plausible thumb parameter family. It ranks candidates by real rig
endpoint distance for two product requirements: thumb-to-index pinch contact and
thumb-to-vessel-surface opposition. The top candidates are rendered for visual
rejection/selection; numerical proximity is evidence, not final acceptance.
"""
from __future__ import annotations
import itertools, math, sys, traceback
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

def _set_axis(arm,bone_name,axis,degrees):
    pb=arm.pose.bones.get(bone_name)
    if pb is None: raise RuntimeError(f'missing pose bone {bone_name}')
    axes={'x':Vector((1,0,0)),'y':Vector((0,1,0)),'z':Vector((0,0,1))}
    pb.rotation_mode='QUATERNION'; pb.rotation_quaternion=Quaternion(axes[axis],math.radians(degrees))

def _set_xz(arm,bone_name,xdeg,zdeg):
    pb=arm.pose.bones.get(bone_name)
    if pb is None: raise RuntimeError(f'missing pose bone {bone_name}')
    qx=Quaternion(Vector((1,0,0)),math.radians(xdeg)); qz=Quaternion(Vector((0,0,1)),math.radians(zdeg))
    pb.rotation_mode='QUATERNION'; pb.rotation_quaternion=qx@qz

def _curl_chain(arm,prefix,degrees):
    for index,deg in enumerate(degrees,1): _set_axis(arm,f'{prefix}_0{index}_r','z',deg)

def _support_fingers(arm):
    _curl_chain(arm,'index',(31,48,32)); _curl_chain(arm,'middle',(38,58,38)); _curl_chain(arm,'ring',(43,63,42)); _curl_chain(arm,'pinky',(47,67,45))

def _pinch_fingers(arm):
    _curl_chain(arm,'index',(25,39,24)); _curl_chain(arm,'middle',(16,23,14)); _curl_chain(arm,'ring',(20,28,18)); _curl_chain(arm,'pinky',(24,32,21))

def _apply_thumb(arm,p):
    x1,z1,z2,z3=p
    _set_xz(arm,'thumb_01_r',x1,z1); _set_axis(arm,'thumb_02_r','z',z2); _set_axis(arm,'thumb_03_r','z',z3)
    bpy.context.view_layer.update()

def _thumb_grid():
    # Bounded around plausible opposition/flexion; deliberately excludes 90°+
    # joint rotations that made prior claw/twist artifacts.
    return itertools.product((-45,-25,-5,15,35,55),(-55,-35,-15,5,25,45),(-45,-25,-5,15,35,55),(-35,-15,5,25,45))

def _regularization(params):
    # Tiny preference for lower total angular excursion; contact remains dominant.
    return sum(abs(v) for v in params)/720.0*0.003

def _rank_thumb(arm,base_pose,target_fn,limit=3):
    ranked=[]
    for params in _thumb_grid():
        _clear_pose(arm); base_pose(arm); _apply_thumb(arm,params)
        target=target_fn(arm)
        tip=_world_pose(arm,'thumb_03_r',True)
        distance=(tip-target).length
        ranked.append((distance+_regularization(params),distance,params,target.copy(),tip.copy()))
    ranked.sort(key=lambda row:row[0])
    return ranked[:limit]

def _vessel_geometry(arm):
    hand=_world_rest(arm,'hand_r'); index=_world_rest(arm,'index_01_r'); mid=_world_rest(arm,'middle_02_r'); tip=_world_rest(arm,'middle_03_r',True)
    center=mid.lerp(tip,.28); axis=(hand-index).normalized(); radius=.038
    return center,axis,radius

def _support_target(arm):
    center,axis,radius=_vessel_geometry(arm); rest_thumb=_world_rest(arm,'thumb_03_r',True)
    radial=rest_thumb-center; radial=radial-axis*radial.dot(axis)
    if radial.length<1e-6: radial=Vector((1,0,0))
    return center+radial.normalized()*radius

def _pinch_target(arm): return _world_pose(arm,'index_03_r',True)

def _add_cylinder_proxy(arm):
    center,axis,radius=_vessel_geometry(arm)
    bpy.ops.mesh.primitive_cylinder_add(vertices=48,radius=radius,depth=.19,location=center)
    obj=bpy.context.object; obj.name='PoseProxy_Vessel'; obj.data.materials.append(_proxy_material('VesselProxy',(0.12,0.24,0.34,1),.38)); obj.rotation_euler=axis.to_track_quat('Z','Y').to_euler()

def _add_flap_proxy(arm):
    index_tip=_world_pose(arm,'index_03_r',True); thumb_tip=_world_pose(arm,'thumb_03_r',True); center=index_tip.lerp(thumb_tip,.5)
    bpy.ops.mesh.primitive_cube_add(size=1,location=center)
    obj=bpy.context.object; obj.name='PoseProxy_Flap'; obj.scale=(.026,.004,.018); obj.data.materials.append(_proxy_material('FlapProxy',(0.74,0.62,0.38,1),.82))

def _render(cam,name,target,offset):
    cam.location=target+offset; _look(cam,target); bpy.context.scene.render.filepath=str(OUT/f'{name}.png'); bpy.ops.render.render(write_still=True)
    p=OUT/f'{name}.png'
    if not p.is_file() or p.stat().st_size<=0: raise RuntimeError('render failed '+name)
    print('MPFB_POSE_FRAME',name,p.stat().st_size)

def _render_ranked(arm,cam,target,camera_offset,prefix,base_pose,target_fn,proxy_fn):
    ranked=_rank_thumb(arm,base_pose,target_fn,3)
    for rank,(_,distance,params,goal,tip) in enumerate(ranked,1):
        print('MPFB_POSE_SOLVE',prefix,'rank',rank,'distance',f'{distance:.6f}','params',params,'goal',tuple(round(v,5) for v in goal),'thumb_tip',tuple(round(v,5) for v in tip))
        _clear_pose(arm); base_pose(arm); _apply_thumb(arm,params); proxy_fn(arm); bpy.context.view_layer.update(); _render(cam,f'{prefix}_{rank}',target,camera_offset)
    return ranked

def _run():
    global INPUT,OUT; INPUT,OUT=_args(); OUT.mkdir(parents=True,exist_ok=True); mesh,arm,cam=_setup()
    target=(_world_rest(arm,'hand_r')+_world_rest(arm,'middle_03_r',True))*0.5; camera_offset=Vector((-0.18,-0.28,0.10))
    _clear_pose(arm); _render(cam,'pose_neutral',target,camera_offset)
    support=_render_ranked(arm,cam,target,camera_offset,'support_solved',_support_fingers,_support_target,_add_cylinder_proxy)
    pinch=_render_ranked(arm,cam,target,camera_offset,'pinch_solved',_pinch_fingers,_pinch_target,_add_flap_proxy)
    print('MPFB_POSE_BEST support_distance',f'{support[0][1]:.6f}','pinch_distance',f'{pinch[0][1]:.6f}')
    print(SUCCESS)
if __name__=='__main__':
    try:_run()
    except BaseException as e:
        print(f'{ERROR}: {e}'); traceback.print_exc(); raise
