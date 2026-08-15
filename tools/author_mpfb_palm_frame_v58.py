#!/usr/bin/env python3
"""v58: palm/root-only pre-grasp composition.

Exactly two target-rig bones are authored. All digit bones stay at rest. The
staging vessel is manually placed relative to the authored palm and never drives
a bone. This isolates the earliest failure found by v57 before any finger curl.
"""
from __future__ import annotations
import importlib.util, json, math, sys, traceback
from pathlib import Path
import bpy
from mathutils import Euler, Matrix, Vector
BASE = Path(__file__).resolve().parent

def load(name, filename):
    spec = importlib.util.spec_from_file_location(name, BASE / filename)
    module = importlib.util.module_from_spec(spec); spec.loader.exec_module(module); return module
v19 = load('v19_v58','render_mpfb_retarget_preview_v19.py')
v49 = load('v49_v58','manual_pose_asset_v49.py')
PALM_FK_DEG = {'lowerarm_r': (-6.0, 8.0, -32.0), 'hand_r': (8.0, -42.0, 52.0)}

def args():
    vals = sys.argv[sys.argv.index('--')+1:]
    if len(vals) != 4: raise RuntimeError('expected <mpfb.glb> <outdir> <pose.json> <report.json>')
    return tuple(Path(v).resolve() for v in vals)

def basis(deg): return Euler(tuple(math.radians(v) for v in deg),'XYZ').to_matrix().to_4x4()
def palm_point(arm):
    names=['hand_r','index_01_r','middle_01_r','ring_01_r','pinky_01_r']
    return sum((arm.pose.bones[n].head for n in names), Vector())/len(names)
def render(cam,out,stem,focus,thumb=False):
    v19._render(cam,out,stem,focus)
    if thumb:
        s=bpy.context.scene; old=(s.render.resolution_x,s.render.resolution_y,s.render.resolution_percentage)
        s.render.resolution_x=192; s.render.resolution_y=108; s.render.resolution_percentage=100
        try: v19._render(cam,out,stem+'_thumbnail',focus)
        finally: s.render.resolution_x,s.render.resolution_y,s.render.resolution_percentage=old

def run():
    src,out,pose_path,report_path=args(); out.mkdir(parents=True,exist_ok=True); pose_path.parent.mkdir(parents=True,exist_ok=True); report_path.parent.mkdir(parents=True,exist_ok=True)
    v19._reset(); arm,meshes=v19._import_armature(src,'MPFB'); cam=v19._setup_render(meshes); v19._clear(arm)
    for name,deg in PALM_FK_DEG.items():
        arm.pose.bones[name].matrix_basis=basis(deg); bpy.context.view_layer.update()
    palm=palm_point(arm)
    # v57 showed the vessel too far camera-left from the palm. Move the fixed
    # prop inward toward the MCP arc while keeping it upright and staging-only.
    center=palm+Vector((0.010,0.032,0.000))
    bpy.ops.mesh.primitive_cylinder_add(vertices=64,radius=0.040,depth=0.155,location=center)
    proxy=bpy.context.object; proxy.name='PalmFrameV58Vessel'
    mat=bpy.data.materials.new('PalmFrameV58VesselMat'); mat.diffuse_color=(0.12,0.18,0.24,1.0); proxy.data.materials.append(mat)
    focus=palm.lerp(center,0.55)
    render(cam,out,'palm_frame_v58',focus,thumb=True)
    payload=v49.save_pose(arm,pose_path,label='v58 palm/root-only pre-grasp',provenance={
        'kind':'artist-authored-target-rig-palm-frame','production_candidate':False,'automatic_retarget':False,
        'source_transforms_used':False,'source_directions_used':False,'target_solver_used':False,
        'authored_bones':['lowerarm_r','hand_r'],'note':'Digits intentionally remain rest. Visual gate precedes thumb/finger authoring.'})
    expected={n:arm.pose.bones[n].matrix_basis.copy() for n in v49.BONES}; v49.clear_pose(arm); v49.load_pose(arm,pose_path)
    err=max(max(abs(expected[n][r][c]-arm.pose.bones[n].matrix_basis[r][c]) for r in range(4) for c in range(4)) for n in v49.BONES)
    report={'staging_only':True,'production_candidate':False,'kind':'artist-authored-target-rig-palm-frame','authored_bones':['lowerarm_r','hand_r'],
            'digit_bones_authored':False,'automatic_retarget':False,'source_transforms_used':False,'source_directions_used':False,'target_solver_used':False,
            'pose_bone_count':len(payload['bones']),'max_reload_matrix_error':err,'palm_fk_deg':{k:list(v) for k,v in PALM_FK_DEG.items()},
            'vessel_offset_from_palm':[0.010,0.032,0.000],
            'visual_gate':'Before digit curl, thumbnail must show palm/MCP arc overlapping or straddling the vessel near contour with a credible far-side path for index/middle/ring and usable near/upper space for later thumb opposition.'}
    report_path.write_text(json.dumps(report,indent=2,sort_keys=True),encoding='utf-8')
    if err>1e-6: raise RuntimeError(f'pose reload error {err}')
    print(json.dumps(report,indent=2,sort_keys=True)); print('MPFB_PALM_FRAME_V58_SUCCESS')
if __name__=='__main__':
    try: run()
    except BaseException as e:
        print('MPFB_PALM_FRAME_V58_ERROR:',e); traceback.print_exc(); raise
