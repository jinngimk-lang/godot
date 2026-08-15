#!/usr/bin/env python3
"""v72: one camera-space thumb correction from the measured v71 baseline.

The v71 ID diagnostic proved the entire high-weight thumb skin bbox sits inside the projected
vessel contour in pristine v65-B.  This script freezes wrist, palm, vessel, camera and digits
2-5, then makes exactly one coherent thumb-chain authoring move derived from that measured
screen-space failure: shift the visible chain toward camera-right until the distal thumb is
outside the vessel contour by a small explicit margin.  No angle sweep, CCD or optimizer.
"""
from __future__ import annotations
import importlib.util, json, sys, traceback
from pathlib import Path
import bpy
from mathutils import Vector

BASE=Path(__file__).resolve().parent

def _load(name, filename):
    spec=importlib.util.spec_from_file_location(name, BASE/filename)
    if spec is None or spec.loader is None: raise RuntimeError('could not load '+filename)
    mod=importlib.util.module_from_spec(spec); spec.loader.exec_module(mod); return mod

v71=_load('mpfb_v71_for_v72','diagnose_mpfb_thumb_silhouette_v71.py')
v65=v71.v65
v68=_load('mpfb_v68_for_v72','author_mpfb_thumb_chain_v68.py')
v64=v65.v64; v64b=v65.v64b
SUCCESS='MPFB_THUMB_SCREEN_TARGET_V72_SUCCESS'
WIDTH=192; HEIGHT=108


def _args():
    if '--' not in sys.argv: raise RuntimeError('expected -- <extension-module> <outdir> <report.json>')
    vals=sys.argv[sys.argv.index('--')+1:]
    if len(vals)!=3: raise RuntimeError('expected three arguments')
    return vals[0],Path(vals[1]).resolve(),Path(vals[2]).resolve()


def _mat_snapshot(arm):
    names=['wrist.R']+[f'finger{d}-{j}.R' for d in range(2,6) for j in range(1,4)]
    return {n:[float(arm.pose.bones[n].matrix_basis[r][c]) for r in range(4) for c in range(4)] for n in names}


def _max_delta(a,b):
    return max(abs(x-y) for n in a for x,y in zip(a[n],b[n]))


def _screen_metrics(scene,cam,arm,vessel_center,vessel_radius,longitudinal,focus,weights,static_obj):
    root=v65._wp(arm,'finger1-1.R'); tip=v65._wp(arm,'finger1-3.R',True)
    view=(focus-cam.location).normalized(); axis=longitudinal.cross(view).normalized()
    if axis.length_squared<0.5: axis=Vector((1,0,0))
    ca=vessel_center+axis*vessel_radius; cb=vessel_center-axis*vessel_radius
    rp=v71._project(scene,cam,root); tp=v71._project(scene,cam,tip)
    cp=[v71._project(scene,cam,ca),v71._project(scene,cam,cb)]
    xs=sorted(p['px_top_left'][0] for p in cp); diameter=xs[1]-xs[0]
    pts=[static_obj.matrix_world@static_obj.data.vertices[i].co for i,w in enumerate(weights) if w>=0.5]
    bbox=v71._pixel_bbox(scene,cam,pts)
    outside=max(0.0,xs[0]-bbox['min'][0],bbox['max'][0]-xs[1])
    dx=rp['px_top_left'][0]-tp['px_top_left'][0]; dy=rp['px_top_left'][1]-tp['px_top_left'][1]
    return {'root':rp,'tip':tp,'vessel_contour':cp,'vessel_x_px':xs,'vessel_diameter_px':diameter,'bbox':bbox,'bbox_outside_px':outside,'root_tip_span_px':(dx*dx+dy*dy)**0.5}


def run():
    ext,out,report_path=_args(); out.mkdir(parents=True,exist_ok=True); report_path.parent.mkdir(parents=True,exist_ok=True)
    v65._reset(); mpfb,HumanService=v65._services(ext)
    base=HumanService.create_human(mask_helpers=True,detailed_helpers=False,extra_vertex_groups=True,feet_on_ground=False,scale=0.1,macro_detail_dict=None)
    arm=HumanService.add_builtin_rig(base,'default',import_weights=True,operator=None)
    if base is None or arm is None: raise RuntimeError('MPFB creation failed')
    vessel_center,vessel_radius,palm_center,longitudinal,span,palmar=v65._author_power_grasp(arm,-1.0)
    bpy.context.view_layer.update(); weights=v71._combined_thumb_weights(base); segments=v64._selected_segments(arm)
    focus=palm_center.lerp(vessel_center,0.55); cam=v65._scene_camera(focus,longitudinal,span,palmar,'B72'); scene=bpy.context.scene

    # Baseline geometry/metrics, with exact v65-B camera.
    base_static,_=v71._posed_static_with_thumb_materials(base,weights)
    base_metrics=_screen_metrics(scene,cam,arm,vessel_center,vessel_radius,longitudinal,focus,weights,base_static)
    bpy.data.objects.remove(base_static,do_unlink=True)
    frozen_before=_mat_snapshot(arm)

    # Convert the explicit camera-space target into one world-space lateral displacement.
    # Target: distal tip 0.22 projected vessel radius beyond the right contour measured by v71.
    tip=v65._wp(arm,'finger1-3.R',True)
    cam_right=cam.matrix_world.to_quaternion()@Vector((1.0,0.0,0.0))
    p0=v71._project(scene,cam,tip)['px_top_left'][0]
    probe=v71._project(scene,cam,tip+cam_right*0.01)['px_top_left'][0]
    if probe<p0: cam_right=-cam_right; probe=v71._project(scene,cam,tip+cam_right*0.01)['px_top_left'][0]
    px_per_m=(probe-p0)/0.01
    radius_px=base_metrics['vessel_diameter_px']*0.5
    target_tip_x=base_metrics['vessel_x_px'][1]+0.22*radius_px
    needed_px=max(0.0,target_tip_x-base_metrics['tip']['px_top_left'][0])
    lateral_m=needed_px/max(px_per_m,1e-6)
    cam_up=cam.matrix_world.to_quaternion()@Vector((0.0,1.0,0.0)); cam_down=-cam_up

    # One coherent chain; smaller displacement at the base, full displacement at distal tip.
    for name,fraction,down_fraction in (
        ('finger1-1.R',0.40,0.02),('finger1-2.R',0.72,0.05),('finger1-3.R',1.00,0.08)):
        current=v65._wp(arm,name,True)
        target=current+cam_right*(lateral_m*fraction)+cam_down*(lateral_m*down_fraction)
        v68._aim_pose_bone_world(arm,name,target)
    bpy.context.view_layer.update()
    frozen_after=_mat_snapshot(arm); non_thumb_delta=_max_delta(frozen_before,frozen_after)

    pose_path=out/'support-wrap-v72-canonical-pose.json'; v68._save_same_rig_pose(arm,pose_path)
    candidate,_=v71._posed_static_with_thumb_materials(base,weights)
    v64b._adaptive_crop(candidate,segments,palm_center)
    vessel=v65._vessel(vessel_center,longitudinal,vessel_radius,'B72')
    base.hide_render=True; arm.hide_render=True; candidate.hide_render=False; vessel.hide_render=False
    full=out/'thumb-screen-target-with-vessel.png'; thumb=out/'thumb-screen-target-thumbnail.png'
    v65._render(full,640,640); v65._render(thumb,WIDTH,HEIGHT)
    vessel.hide_render=True
    anatomy=out/'thumb-screen-target-anatomy-oblique.png'; anatomy_thumb=out/'thumb-screen-target-anatomy-thumbnail.png'
    v65._render(anatomy,640,640); v65._render(anatomy_thumb,WIDTH,HEIGHT)

    # Metrics use uncropped posed topology so high-weight vertex indices stay exact.
    metric_static,_=v71._posed_static_with_thumb_materials(base,weights)
    candidate_metrics=_screen_metrics(scene,cam,arm,vessel_center,vessel_radius,longitudinal,focus,weights,metric_static)
    report={
      'staging_only':True,'production_candidate':False,'reference_set':['bar_v1','market_v1'],
      'base_pose':'pristine v65-B','single_screen_space_authoring':True,'parameter_sweep_used':False,'ccd_used':False,'endpoint_optimizer_used':False,
      'wrist_changed_from_v65_b':False,'non_thumb_fingers_changed_from_v65_b':False,'vessel_changed_from_v65_b':False,'camera_changed_from_v65_b':False,
      'non_thumb_matrix_max_abs_delta':non_thumb_delta,'screen_target_margin_vessel_radius':0.22,'computed_needed_px':needed_px,'computed_lateral_world_m':lateral_m,
      'baseline':base_metrics,'candidate':candidate_metrics,'same_rig_pose_path':str(pose_path),'mpfb_version':list(mpfb.VERSION),
      'visual_gate':'Candidate must visibly expose one continuous opposing thumb in the 192x108 vessel view and preserve continuous anatomy in oblique view. Positive screen-space metrics are necessary but not sufficient.'
    }
    report_path.write_text(json.dumps(report,indent=2,sort_keys=True),encoding='utf-8'); print(json.dumps(report,indent=2,sort_keys=True)); print(SUCCESS)

if __name__=='__main__':
    try: run()
    except BaseException as exc:
        print('MPFB_THUMB_SCREEN_TARGET_V72_ERROR:',exc); traceback.print_exc(); raise
