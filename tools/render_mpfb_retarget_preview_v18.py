"""v18: retarget repository XR semantic pose deltas onto the continuous MPFB limb.

The v10-v16 experiments showed that solving MPFB finger contact from scratch can
manufacture small numeric gaps while producing claw-like silhouettes.  This spike
uses the repository-local XR animations only as semantic pose priors: measure each
mapped digit bone's Default-pose -> target-pose local rotation delta, conjugate that
delta through the source/target rest-frame alignment, and apply it to the MPFB
GameEngine rig.  The low-fidelity XR mesh is never rendered or promoted.
"""
from __future__ import annotations
import math, sys, traceback
from pathlib import Path
import bpy
from mathutils import Matrix, Quaternion, Vector

MAP = {
    'Index_Proximal_R': 'index_01_r',
    'Index_Intermediate_R': 'index_02_r',
    'Index_Distal_R': 'index_03_r',
    'Middle_Proximal_R': 'middle_01_r',
    'Middle_Intermediate_R': 'middle_02_r',
    'Middle_Distal_R': 'middle_03_r',
    'Ring_Proximal_R': 'ring_01_r',
    'Ring_Intermediate_R': 'ring_02_r',
    'Ring_Distal_R': 'ring_03_r',
    'Little_Proximal_R': 'pinky_01_r',
    'Little_Intermediate_R': 'pinky_02_r',
    'Little_Distal_R': 'pinky_03_r',
}
THUMB_SOURCE = ('Thumb_Proximal_R', 'Thumb_Distal_R')
THUMB_TARGET = ('thumb_01_r', 'thumb_02_r', 'thumb_03_r')
ACTIONS = ('Cup_Armature', 'Pinch Up_Armature', 'Pinch Tight_Armature')


def _args():
    if '--' not in sys.argv:
        raise RuntimeError('expected -- <xr.glb> <mpfb.glb> <output-dir>')
    values = sys.argv[sys.argv.index('--') + 1:]
    if len(values) != 3:
        raise RuntimeError('expected three arguments')
    return tuple(Path(v).resolve() for v in values)


def _reset():
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)
    for action in list(bpy.data.actions):
        bpy.data.actions.remove(action)


def _import_armature(path: Path, prefix: str):
    before = set(bpy.context.scene.objects)
    bpy.ops.import_scene.gltf(filepath=str(path))
    created = [o for o in bpy.context.scene.objects if o not in before]
    arms = [o for o in created if o.type == 'ARMATURE']
    meshes = [o for o in created if o.type == 'MESH']
    if not arms:
        raise RuntimeError(f'no armature imported from {path}')
    arm = arms[0]
    arm.name = prefix + '_Armature'
    for i, mesh in enumerate(meshes):
        mesh.name = f'{prefix}_Mesh_{i}'
    return arm, meshes


def _action(name: str):
    exact = bpy.data.actions.get(name)
    if exact is not None:
        return exact
    for action in bpy.data.actions:
        if action.name.startswith(name):
            return action
    raise RuntimeError(f'missing imported action {name}; have {[a.name for a in bpy.data.actions]}')


def _set_action(arm, action_name: str):
    if arm.animation_data is None:
        arm.animation_data_create()
    action = _action(action_name)
    arm.animation_data.action = action
    frame = float(action.frame_range[0])
    bpy.context.scene.frame_set(int(round(frame)))
    bpy.context.view_layer.update()


def _basis_rotation(pb):
    return pb.matrix_basis.to_quaternion().normalized()


def _rest_local_rotation(arm, bone_name: str):
    bone = arm.data.bones.get(bone_name)
    if bone is None:
        raise RuntimeError(f'missing rest bone {bone_name}')
    matrix = bone.matrix_local.copy()
    if bone.parent is not None:
        matrix = bone.parent.matrix_local.inverted() @ matrix
    return matrix.to_quaternion().normalized()


def _source_pose_deltas(xr):
    _set_action(xr, 'Default pose_Armature')
    default = {name: _basis_rotation(xr.pose.bones[name]) for name in list(MAP) + list(THUMB_SOURCE)}
    out = {}
    for action_name in ACTIONS:
        _set_action(xr, action_name)
        pose = {}
        for name, q0 in default.items():
            q1 = _basis_rotation(xr.pose.bones[name])
            pose[name] = (q0.inverted() @ q1).normalized()
        out[action_name] = pose
    return out


def _retarget_delta(xr, mpfb, src_name: str, dst_name: str, delta: Quaternion):
    src_rest = _rest_local_rotation(xr, src_name)
    dst_rest = _rest_local_rotation(mpfb, dst_name)
    align = (dst_rest.inverted() @ src_rest).normalized()
    return (align @ delta @ align.inverted()).normalized()


def _clear_target_pose(arm):
    if arm.animation_data is not None:
        arm.animation_data.action = None
    for pb in arm.pose.bones:
        pb.rotation_mode = 'QUATERNION'
        pb.rotation_quaternion = Quaternion((1.0, 0.0, 0.0, 0.0))
        pb.location = Vector((0.0, 0.0, 0.0))
        pb.scale = Vector((1.0, 1.0, 1.0))
    bpy.context.view_layer.update()


def _half(q: Quaternion):
    return Quaternion((1.0, 0.0, 0.0, 0.0)).slerp(q, 0.5).normalized()


def _apply_retarget(xr, mpfb, deltas):
    _clear_target_pose(mpfb)
    for src, dst in MAP.items():
        mpfb.pose.bones[dst].rotation_quaternion = _retarget_delta(xr, mpfb, src, dst, deltas[src])

    # The XR rig has two deforming thumb rotation joints while GameEngine has
    # three. Preserve proximal opposition on thumb_01 and split the XR distal
    # bend across thumb_02/thumb_03 rather than dumping it into one joint.
    prox = _retarget_delta(xr, mpfb, THUMB_SOURCE[0], THUMB_TARGET[0], deltas[THUMB_SOURCE[0]])
    distal2 = _retarget_delta(xr, mpfb, THUMB_SOURCE[1], THUMB_TARGET[1], deltas[THUMB_SOURCE[1]])
    distal3 = _retarget_delta(xr, mpfb, THUMB_SOURCE[1], THUMB_TARGET[2], deltas[THUMB_SOURCE[1]])
    mpfb.pose.bones[THUMB_TARGET[0]].rotation_quaternion = prox
    mpfb.pose.bones[THUMB_TARGET[1]].rotation_quaternion = _half(distal2)
    mpfb.pose.bones[THUMB_TARGET[2]].rotation_quaternion = _half(distal3)
    bpy.context.view_layer.update()


def _world_pose(arm, bone_name: str, tail=False):
    pb = arm.pose.bones.get(bone_name)
    if pb is None:
        raise RuntimeError('missing pose bone ' + bone_name)
    return arm.matrix_world @ (pb.tail if tail else pb.head)


def _world_rest(arm, bone_name: str, tail=False):
    bone = arm.data.bones.get(bone_name)
    if bone is None:
        raise RuntimeError('missing rest bone ' + bone_name)
    return arm.matrix_world @ (bone.tail_local if tail else bone.head_local)


def _skin_material(meshes):
    mat = bpy.data.materials.new('RetargetPreviewSkin')
    mat.use_nodes = True
    p = next((n for n in mat.node_tree.nodes if n.type == 'BSDF_PRINCIPLED'), None)
    if p:
        p.inputs['Base Color'].default_value = (0.34, 0.16, 0.085, 1.0)
        p.inputs['Roughness'].default_value = 0.64
    for mesh in meshes:
        mesh.data.materials.clear()
        mesh.data.materials.append(mat)


def _proxy_material(name, color, roughness=.55):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    mat.diffuse_color = color
    p = next((n for n in mat.node_tree.nodes if n.type == 'BSDF_PRINCIPLED'), None)
    if p:
        p.inputs['Base Color'].default_value = color
        p.inputs['Roughness'].default_value = roughness
    return mat


def _support_proxy(arm):
    tips = [_world_pose(arm, f'{name}_03_r', True) for name in ('index', 'middle', 'ring', 'pinky')]
    center = sum(tips, Vector((0,0,0))) / len(tips)
    palm = _world_pose(arm, 'hand_r')
    axis = (palm - _world_pose(arm, 'lowerarm_r')).normalized()
    bpy.ops.mesh.primitive_cylinder_add(vertices=48, radius=.038, depth=.20, location=center)
    obj = bpy.context.object
    obj.name = 'PoseProxy_Vessel'
    obj.data.materials.append(_proxy_material('VesselProxy', (0.10,0.23,0.34,1), .40))
    obj.rotation_euler = axis.to_track_quat('Z','Y').to_euler()
    return center, .038


def _pinch_proxy(arm):
    index_tip = _world_pose(arm, 'index_03_r', True)
    thumb_tip = _world_pose(arm, 'thumb_03_r', True)
    center = index_tip.lerp(thumb_tip, .5)
    bpy.ops.mesh.primitive_cube_add(size=1, location=center)
    obj = bpy.context.object
    obj.name = 'PoseProxy_Flap'
    obj.scale = (.024,.002,.016)
    obj.data.materials.append(_proxy_material('FlapProxy', (0.74,0.62,0.38,1), .82))
    return index_tip, thumb_tip, center


def _remove_proxies():
    for obj in list(bpy.context.scene.objects):
        if obj.name.startswith('PoseProxy_'):
            bpy.data.objects.remove(obj, do_unlink=True)


def _look(cam, target):
    cam.rotation_euler = (target - cam.location).to_track_quat('-Z','Y').to_euler()


def _setup_render(meshes):
    _skin_material(meshes)
    scene = bpy.context.scene
    scene.render.engine = 'BLENDER_EEVEE_NEXT'
    scene.render.resolution_x = 640
    scene.render.resolution_y = 640
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = 'PNG'
    scene.world.color = (0.025,0.028,0.035)
    cd = bpy.data.cameras.new('RetargetCamera')
    cam = bpy.data.objects.new('RetargetCamera', cd)
    scene.collection.objects.link(cam)
    scene.camera = cam
    cd.lens = 68
    kd = bpy.data.lights.new('Key','AREA'); kd.energy=270; kd.size=.8
    key=bpy.data.objects.new('Key',kd); key.location=(-.62,-.58,.58); scene.collection.objects.link(key)
    fd = bpy.data.lights.new('Fill','AREA'); fd.energy=80; fd.size=.7
    fill=bpy.data.objects.new('Fill',fd); fill.location=(-.20,.08,.35); scene.collection.objects.link(fill)
    return cam


def _render(cam, out: Path, name: str, target: Vector):
    cam.location = target + Vector((-.18,-.28,.10))
    _look(cam, target)
    bpy.context.scene.render.filepath = str(out / f'{name}.png')
    bpy.ops.render.render(write_still=True)
    p = out / f'{name}.png'
    if not p.is_file() or p.stat().st_size <= 0:
        raise RuntimeError('render failed ' + name)
    print('RETARGET_FRAME', name, p.stat().st_size)


def _run():
    xr_path, mpfb_path, out = _args()
    out.mkdir(parents=True, exist_ok=True)
    _reset()
    xr, xr_meshes = _import_armature(xr_path, 'XRSource')
    deltas = _source_pose_deltas(xr)
    # Keep actions alive, but hide the source mesh completely.  The rendered
    # evidence is MPFB anatomy only.
    for mesh in xr_meshes:
        mesh.hide_render = True
        mesh.hide_viewport = True

    mpfb, meshes = _import_armature(mpfb_path, 'MPFBTarget')
    cam = _setup_render(meshes)
    target = (_world_rest(mpfb,'hand_r') + _world_rest(mpfb,'middle_03_r',True)) * .5

    _clear_target_pose(mpfb)
    _render(cam, out, 'retarget_neutral', target)

    for action_name in ACTIONS:
        _remove_proxies()
        _apply_retarget(xr, mpfb, deltas[action_name])
        if action_name.startswith('Cup'):
            vessel_center, radius = _support_proxy(mpfb)
            fingertips = [_world_pose(mpfb,f'{name}_03_r',True) for name in ('index','middle','ring','pinky')]
            distances = [(p-vessel_center).length for p in fingertips]
            print('RETARGET_SUPPORT radial_errors', [round(abs(d-radius),6) for d in distances])
        else:
            index_tip, thumb_tip, center = _pinch_proxy(mpfb)
            gap = (thumb_tip-index_tip).length
            print('RETARGET_PINCH', action_name, 'gap', f'{gap:.6f}', 'center', tuple(round(v,6) for v in center))
        safe = action_name.replace(' ','_').replace('_Armature','').lower()
        _render(cam, out, 'retarget_' + safe, target)

    print('MPFB_RETARGET_V18_SUCCESS')


if __name__ == '__main__':
    try:
        _run()
    except BaseException as exc:
        print('MPFB_RETARGET_V18_ERROR:', exc)
        traceback.print_exc()
        raise
