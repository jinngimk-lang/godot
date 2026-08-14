"""v19: retarget XR semantic pose deltas onto MPFB, including digit-base spread/opposition.

v18 proved that transferring only proximal/intermediate/distal deltas preserves MPFB
anatomy but leaves Cup as a hanging claw and Pinch Up/Tight at ~95.6 mm thumb/index
separation. This experiment tests the structural hypothesis that the omitted XR
metacarpal/base channels contain essential finger spread and thumb opposition.

The MPFB GameEngine hand has no one-to-one digit metacarpal deform bones, so each XR
metacarpal delta is folded into the corresponding MPFB proximal joint before the XR
proximal delta. Thumb metacarpal + proximal are both folded into thumb_01_r, while
XR distal is split over thumb_02_r/thumb_03_r as in v18.
"""
from __future__ import annotations
import math, sys, traceback
from pathlib import Path
import bpy
from mathutils import Quaternion, Vector

DIGITS = {
    'index': ('Index_Metacarpal_R','Index_Proximal_R','Index_Intermediate_R','Index_Distal_R','index_01_r','index_02_r','index_03_r'),
    'middle': ('Middle_Metacarpal_R','Middle_Proximal_R','Middle_Intermediate_R','Middle_Distal_R','middle_01_r','middle_02_r','middle_03_r'),
    'ring': ('Ring_Metacarpal_R','Ring_Proximal_R','Ring_Intermediate_R','Ring_Distal_R','ring_01_r','ring_02_r','ring_03_r'),
    'pinky': ('Little_Metacarpal_R','Little_Proximal_R','Little_Intermediate_R','Little_Distal_R','pinky_01_r','pinky_02_r','pinky_03_r'),
}
THUMB = ('Thumb_Metacarpal_R','Thumb_Proximal_R','Thumb_Distal_R','thumb_01_r','thumb_02_r','thumb_03_r')
ACTIONS = ('Cup_Armature','Pinch Up_Armature','Pinch Tight_Armature')


def _args():
    if '--' not in sys.argv: raise RuntimeError('expected -- <xr.glb> <mpfb.glb> <output-dir>')
    v=sys.argv[sys.argv.index('--')+1:]
    if len(v)!=3: raise RuntimeError('expected three args')
    return tuple(Path(x).resolve() for x in v)


def _reset():
    bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
    for a in list(bpy.data.actions): bpy.data.actions.remove(a)


def _import_armature(path,prefix):
    before=set(bpy.context.scene.objects); bpy.ops.import_scene.gltf(filepath=str(path))
    made=[o for o in bpy.context.scene.objects if o not in before]
    arms=[o for o in made if o.type=='ARMATURE']; meshes=[o for o in made if o.type=='MESH']
    if not arms: raise RuntimeError('no armature in '+str(path))
    arms[0].name=prefix+'_Armature'
    return arms[0],meshes


def _action(name):
    a=bpy.data.actions.get(name)
    if a: return a
    for candidate in bpy.data.actions:
        if candidate.name.startswith(name): return candidate
    raise RuntimeError(f'missing action {name}; have {[a.name for a in bpy.data.actions]}')


def _set_action(arm,name):
    if arm.animation_data is None: arm.animation_data_create()
    a=_action(name); arm.animation_data.action=a
    bpy.context.scene.frame_set(int(round(float(a.frame_range[0])))); bpy.context.view_layer.update()


def _basis_q(pb): return pb.matrix_basis.to_quaternion().normalized()


def _rest_local_q(arm,name):
    b=arm.data.bones.get(name)
    if b is None: raise RuntimeError('missing rest bone '+name)
    m=b.matrix_local.copy()
    if b.parent is not None: m=b.parent.matrix_local.inverted()@m
    return m.to_quaternion().normalized()


def _needed_sources():
    names=[]
    for row in DIGITS.values(): names.extend(row[:4])
    names.extend(THUMB[:3])
    return names


def _source_deltas(xr):
    names=_needed_sources(); _set_action(xr,'Default pose_Armature')
    missing=[n for n in names if xr.pose.bones.get(n) is None]
    if missing: raise RuntimeError('missing XR source bones '+str(missing))
    default={n:_basis_q(xr.pose.bones[n]) for n in names}
    out={}
    for action_name in ACTIONS:
        _set_action(xr,action_name); pose={}
        for n,q0 in default.items():
            q1=_basis_q(xr.pose.bones[n]); pose[n]=(q0.inverted()@q1).normalized()
        out[action_name]=pose
        base_angles={n:round(math.degrees(pose[n].angle),3) for n in names if 'Metacarpal' in n}
        print('RETARGET_V19_BASE_DELTAS',action_name,base_angles)
    return out


def _retarget_delta(xr,mpfb,src,dst,delta):
    sr=_rest_local_q(xr,src); dr=_rest_local_q(mpfb,dst)
    align=(dr.inverted()@sr).normalized()
    return (align@delta@align.inverted()).normalized()


def _clear(arm):
    if arm.animation_data: arm.animation_data.action=None
    for pb in arm.pose.bones:
        pb.rotation_mode='QUATERNION'; pb.rotation_quaternion=Quaternion((1,0,0,0)); pb.location=(0,0,0); pb.scale=(1,1,1)
    bpy.context.view_layer.update()


def _half(q): return Quaternion((1,0,0,0)).slerp(q,.5).normalized()


def _apply(xr,mpfb,d):
    _clear(mpfb)
    for _,(meta,prox,inter,dist,dst1,dst2,dst3) in DIGITS.items():
        qmeta=_retarget_delta(xr,mpfb,meta,dst1,d[meta]); qprox=_retarget_delta(xr,mpfb,prox,dst1,d[prox])
        mpfb.pose.bones[dst1].rotation_quaternion=(qmeta@qprox).normalized()
        mpfb.pose.bones[dst2].rotation_quaternion=_retarget_delta(xr,mpfb,inter,dst2,d[inter])
        mpfb.pose.bones[dst3].rotation_quaternion=_retarget_delta(xr,mpfb,dist,dst3,d[dist])
    meta,prox,dist,dst1,dst2,dst3=THUMB
    qm=_retarget_delta(xr,mpfb,meta,dst1,d[meta]); qp=_retarget_delta(xr,mpfb,prox,dst1,d[prox])
    qd2=_retarget_delta(xr,mpfb,dist,dst2,d[dist]); qd3=_retarget_delta(xr,mpfb,dist,dst3,d[dist])
    mpfb.pose.bones[dst1].rotation_quaternion=(qm@qp).normalized()
    mpfb.pose.bones[dst2].rotation_quaternion=_half(qd2)
    mpfb.pose.bones[dst3].rotation_quaternion=_half(qd3)
    bpy.context.view_layer.update()


def _wp(arm,name,tail=False):
    pb=arm.pose.bones.get(name)
    if pb is None: raise RuntimeError('missing pose bone '+name)
    return arm.matrix_world@(pb.tail if tail else pb.head)


def _wr(arm,name,tail=False):
    b=arm.data.bones.get(name)
    if b is None: raise RuntimeError('missing rest bone '+name)
    return arm.matrix_world@(b.tail_local if tail else b.head_local)


def _mat(name,color,roughness):
    m=bpy.data.materials.new(name); m.use_nodes=True; m.diffuse_color=color
    p=next((n for n in m.node_tree.nodes if n.type=='BSDF_PRINCIPLED'),None)
    if p: p.inputs['Base Color'].default_value=color; p.inputs['Roughness'].default_value=roughness
    return m


def _setup_render(meshes):
    skin=_mat('RetargetV19Skin',(0.34,0.16,0.085,1),.64)
    for mesh in meshes: mesh.data.materials.clear(); mesh.data.materials.append(skin)
    sc=bpy.context.scene; sc.render.engine='BLENDER_EEVEE_NEXT'; sc.render.resolution_x=640; sc.render.resolution_y=640; sc.render.resolution_percentage=100; sc.render.image_settings.file_format='PNG'; sc.world.color=(.025,.028,.035)
    cd=bpy.data.cameras.new('Camera'); cam=bpy.data.objects.new('Camera',cd); sc.collection.objects.link(cam); sc.camera=cam; cd.lens=68
    kd=bpy.data.lights.new('Key','AREA'); kd.energy=270; kd.size=.8; key=bpy.data.objects.new('Key',kd); key.location=(-.62,-.58,.58); sc.collection.objects.link(key)
    fd=bpy.data.lights.new('Fill','AREA'); fd.energy=80; fd.size=.7; fill=bpy.data.objects.new('Fill',fd); fill.location=(-.20,.08,.35); sc.collection.objects.link(fill)
    return cam


def _remove_proxies():
    for o in list(bpy.context.scene.objects):
        if o.name.startswith('PoseProxy_'): bpy.data.objects.remove(o,do_unlink=True)


def _support_proxy(arm):
    tips=[_wp(arm,f'{n}_03_r',True) for n in ('index','middle','ring','pinky')]; center=sum(tips,Vector())/4; palm=_wp(arm,'hand_r'); axis=(palm-_wp(arm,'lowerarm_r')).normalized()
    bpy.ops.mesh.primitive_cylinder_add(vertices=48,radius=.038,depth=.20,location=center); o=bpy.context.object; o.name='PoseProxy_Vessel'; o.data.materials.append(_mat('VesselProxy',(.10,.23,.34,1),.40)); o.rotation_euler=axis.to_track_quat('Z','Y').to_euler()
    return center,.038


def _pinch_proxy(arm):
    i=_wp(arm,'index_03_r',True); t=_wp(arm,'thumb_03_r',True); c=i.lerp(t,.5)
    bpy.ops.mesh.primitive_cube_add(size=1,location=c); o=bpy.context.object; o.name='PoseProxy_Flap'; o.scale=(.024,.002,.016); o.data.materials.append(_mat('FlapProxy',(.74,.62,.38,1),.82))
    return i,t,c


def _render(cam,out,name,target):
    cam.location=target+Vector((-.18,-.28,.10)); cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler(); bpy.context.scene.render.filepath=str(out/f'{name}.png'); bpy.ops.render.render(write_still=True)
    p=out/f'{name}.png'
    if not p.is_file() or p.stat().st_size<=0: raise RuntimeError('render failed '+name)
    print('RETARGET_V19_FRAME',name,p.stat().st_size)


def _run():
    xr_path,mpfb_path,out=_args(); out.mkdir(parents=True,exist_ok=True); _reset(); xr,xr_meshes=_import_armature(xr_path,'XR'); deltas=_source_deltas(xr)
    for mesh in xr_meshes: mesh.hide_render=True; mesh.hide_viewport=True
    mpfb,meshes=_import_armature(mpfb_path,'MPFB'); cam=_setup_render(meshes); target=(_wr(mpfb,'hand_r')+_wr(mpfb,'middle_03_r',True))*.5
    _clear(mpfb); _render(cam,out,'retarget_v19_neutral',target)
    for action_name in ACTIONS:
        _remove_proxies(); _apply(xr,mpfb,deltas[action_name])
        if action_name.startswith('Cup'):
            center,radius=_support_proxy(mpfb); tips=[_wp(mpfb,f'{n}_03_r',True) for n in ('index','middle','ring','pinky')]; errors=[round(abs((p-center).length-radius),6) for p in tips]; print('RETARGET_V19_SUPPORT radial_errors',errors)
        else:
            i,t,c=_pinch_proxy(mpfb); gap=(t-i).length; print('RETARGET_V19_PINCH',action_name,'gap',f'{gap:.6f}','center',tuple(round(v,6) for v in c))
        safe=action_name.replace(' ','_').replace('_Armature','').lower(); _render(cam,out,'retarget_v19_'+safe,target)
    print('MPFB_RETARGET_V19_SUCCESS')

if __name__=='__main__':
    try:_run()
    except BaseException as e:
        print('MPFB_RETARGET_V19_ERROR:',e); traceback.print_exc(); raise
