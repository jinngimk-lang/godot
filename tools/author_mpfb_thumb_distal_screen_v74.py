#!/usr/bin/env python3
"""v74: preserve thumb root/thenar and expose only the actual thumb digit in camera space.

v73 showed finger1-1.R owns a broad thenar/webbing region, while finger1-2/1-3 own the visible
thumb digit. v72 stretched the thenar because it moved all three. This script freezes finger1-1,
wrist, digits 2-5, vessel and camera, then performs one measured screen-space authoring move on
finger1-2 and finger1-3 only. No sweep, CCD, optimizer, or root motion.
"""
from __future__ import annotations
import importlib.util, json, sys, traceback
from pathlib import Path
import bpy
from mathutils import Vector

BASE=Path(__file__).resolve().parent

def _load(name,file):
    spec=importlib.util.spec_from_file_location(name,BASE/file)
    if spec is None or spec.loader is None: raise RuntimeError('could not load '+file)
    mod=importlib.util.module_from_spec(spec); spec.loader.exec_module(mod); return mod

v73=_load('mpfb_v73_for_v74','diagnose_mpfb_thumb_bone_id_v73.py')
v71=v73.v71; v65=v73.v65; v64=v65.v64; v64b=v65.v64b
v68=_load('mpfb_v68_for_v74','author_mpfb_thumb_chain_v68.py')
SUCCESS='MPFB_THUMB_DISTAL_SCREEN_V74_SUCCESS'; WIDTH=192; HEIGHT=108


def _args():
    if '--' not in sys.argv: raise RuntimeError('expected -- <extension-module> <outdir> <report.json>')
    vals=sys.argv[sys.argv.index('--')+1:]
    if len(vals)!=3: raise RuntimeError('expected three arguments')
    return vals[0],Path(vals[1]).resolve(),Path(vals[2]).resolve()


def _flat(pb): return [float(pb.matrix_basis[r][c]) for r in range(4) for c in range(4)]
def _delta(a,b): return max(abs(x-y) for x,y in zip(a,b))


def _assign_bone_id_materials(obj,weights):
    mats=[v73._mat('ThumbIDBaseV74',(0.18,0.18,0.20)),v73._mat('ThumbRootV74',(0.95,0.05,0.55),0.8),v73._mat('ThumbProxV74',(0.0,0.92,0.95),0.8),v73._mat('ThumbDistalV74',(1.0,0.72,0.03),0.8)]
    obj.data.materials.clear()
    for m in mats: obj.data.materials.append(m)
    for poly in obj.data.polygons:
        scores=[max(weights[name][i] for i in poly.vertices) for name in v73.BONES]
        best=max(range(3),key=lambda i:scores[i]); poly.material_index=best+1 if scores[best]>=0.30 else 0


def run():
    ext,out,report_path=_args(); out.mkdir(parents=True,exist_ok=True); report_path.parent.mkdir(parents=True,exist_ok=True)
    v65._reset(); mpfb,HumanService=v65._services(ext)
    base=HumanService.create_human(mask_helpers=True,detailed_helpers=False,extra_vertex_groups=True,feet_on_ground=False,scale=0.1,macro_detail_dict=None)
    arm=HumanService.add_builtin_rig(base,'default',import_weights=True,operator=None)
    vessel_center,vessel_radius,palm_center,longitudinal,span,palmar=v65._author_power_grasp(arm,-1.0); bpy.context.view_layer.update()
    segments=v64._selected_segments(arm); weights=v73._bone_weights(base)
    focus=palm_center.lerp(vessel_center,0.55); cam=v65._scene_camera(focus,longitudinal,span,palmar,'B74'); scene=bpy.context.scene

    metric_base=v73._static(base); baseline=v73._metrics(scene,cam,metric_base,weights,vessel_center,vessel_radius,longitudinal,focus); bpy.data.objects.remove(metric_base,do_unlink=True)
    frozen_names=['wrist.R','finger1-1.R']+[f'finger{d}-{j}.R' for d in range(2,6) for j in range(1,4)]
    frozen_before={n:_flat(arm.pose.bones[n]) for n in frozen_names}

    tip=v65._wp(arm,'finger1-3.R',True)
    cam_right=cam.matrix_world.to_quaternion()@Vector((1,0,0)); p0=v71._project(scene,cam,tip)['px_top_left'][0]
    p1=v71._project(scene,cam,tip+cam_right*0.01)['px_top_left'][0]
    if p1<p0: cam_right=-cam_right; p1=v71._project(scene,cam,tip+cam_right*0.01)['px_top_left'][0]
    px_per_m=(p1-p0)/0.01; radius_px=baseline['vessel_diameter_px']*0.5
    current_tip_x=v71._project(scene,cam,tip)['px_top_left'][0]; target_tip_x=baseline['vessel_x_px'][1]+0.16*radius_px
    needed_px=max(0.0,target_tip_x-current_tip_x); lateral=needed_px/max(px_per_m,1e-6)
    cam_down=-(cam.matrix_world.to_quaternion()@Vector((0,1,0)))

    # Root/thenar is deliberately untouched. Only proximal and distal segments form the opposing digit.
    for name,fraction,down_fraction in (('finger1-2.R',0.58,0.04),('finger1-3.R',1.00,0.08)):
        current=v65._wp(arm,name,True)
        v68._aim_pose_bone_world(arm,name,current+cam_right*(lateral*fraction)+cam_down*(lateral*down_fraction))
    bpy.context.view_layer.update()
    frozen_after={n:_flat(arm.pose.bones[n]) for n in frozen_names}
    frozen_delta=max(_delta(frozen_before[n],frozen_after[n]) for n in frozen_names)
    pose_path=out/'support-wrap-v74-canonical-pose.json'; v68._save_same_rig_pose(arm,pose_path)

    candidate=v73._static(base); _assign_bone_id_materials(candidate,weights); v64b._adaptive_crop(candidate,segments,palm_center)
    vessel=v65._vessel(vessel_center,longitudinal,vessel_radius,'B74'); base.hide_render=True; arm.hide_render=True; candidate.hide_render=False; vessel.hide_render=False
    full=out/'thumb-distal-with-vessel.png'; thumb=out/'thumb-distal-thumbnail.png'; v65._render(full,640,640); v65._render(thumb,WIDTH,HEIGHT)
    vessel.hide_render=True; anatomy=out/'thumb-distal-anatomy-oblique.png'; anatomy_thumb=out/'thumb-distal-anatomy-thumbnail.png'; v65._render(anatomy,640,640); v65._render(anatomy_thumb,WIDTH,HEIGHT)

    metric_candidate=v73._static(base); after=v73._metrics(scene,cam,metric_candidate,weights,vessel_center,vessel_radius,longitudinal,focus)
    root_before=baseline['bones']['finger1-1.R']['bbox']; root_after=after['bones']['finger1-1.R']['bbox']
    report={'staging_only':True,'production_candidate':False,'reference_set':['bar_v1','market_v1'],'base_pose':'pristine v65-B','single_screen_space_authoring':True,'thumb_root_frozen':True,'authored_bones':['finger1-2.R','finger1-3.R'],'parameter_sweep_used':False,'ccd_used':False,'endpoint_optimizer_used':False,'frozen_matrix_max_abs_delta':frozen_delta,'computed_needed_px':needed_px,'computed_lateral_world_m':lateral,'screen_target_margin_vessel_radius':0.16,'baseline':baseline,'candidate':after,'root_bbox_center_delta_px':[root_after['center_px'][0]-root_before['center_px'][0],root_after['center_px'][1]-root_before['center_px'][1]],'root_bbox_size_delta_px':[root_after['width_px']-root_before['width_px'],root_after['height_px']-root_before['height_px']],'same_rig_pose_path':str(pose_path),'mpfb_version':list(mpfb.VERSION),'visual_gate':'At 192x108 the cyan/yellow proximal+distal thumb must read as one continuous opposing digit beyond the vessel contour, while the magenta root/thenar remains compact and anatomy stays non-self-intersecting. Metrics are necessary, not sufficient.'}
    report_path.write_text(json.dumps(report,indent=2,sort_keys=True),encoding='utf-8'); print(json.dumps(report,indent=2,sort_keys=True)); print(SUCCESS)

if __name__=='__main__':
    try: run()
    except BaseException as exc:
        print('MPFB_THUMB_DISTAL_SCREEN_V74_ERROR:',exc); traceback.print_exc(); raise
