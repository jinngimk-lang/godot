#!/usr/bin/env python3
"""v73: map pristine v65-B thumb skin influence by bone in the locked camera.

v72 proved that moving the whole thumb chain can expose pixels but drags a broad thenar/webbing
region into a spike.  Before another pose change, identify which of finger1-1/1-2/1-3 actually
owns which visible skin.  This script changes no pose.  It colors each face by the dominant thumb
bone weight (root=magenta, proximal=cyan, distal=yellow), renders the exact v65-B vessel/anatomy
views, and reports projected per-bone high-weight bboxes relative to the vessel contour.
"""
from __future__ import annotations
import importlib.util, json, sys, traceback
from pathlib import Path
import bpy
from mathutils import Vector

BASE=Path(__file__).resolve().parent
SPEC=importlib.util.spec_from_file_location('mpfb_v71_for_v73',BASE/'diagnose_mpfb_thumb_silhouette_v71.py')
if SPEC is None or SPEC.loader is None: raise RuntimeError('could not load v71 helpers')
v71=importlib.util.module_from_spec(SPEC); SPEC.loader.exec_module(v71)
v65=v71.v65; v64=v65.v64; v64b=v65.v64b
SUCCESS='MPFB_THUMB_BONE_ID_V73_SUCCESS'
BONES=('finger1-1.R','finger1-2.R','finger1-3.R'); WIDTH=192; HEIGHT=108


def _args():
    if '--' not in sys.argv: raise RuntimeError('expected -- <extension-module> <outdir> <report.json>')
    vals=sys.argv[sys.argv.index('--')+1:]
    if len(vals)!=3: raise RuntimeError('expected three arguments')
    return vals[0],Path(vals[1]).resolve(),Path(vals[2]).resolve()


def _bone_weights(obj):
    ids={name:obj.vertex_groups[name].index for name in BONES if obj.vertex_groups.get(name)}
    if len(ids)!=len(BONES): raise RuntimeError('missing thumb vertex group')
    out={name:[0.0]*len(obj.data.vertices) for name in BONES}
    reverse={idx:name for name,idx in ids.items()}
    for v in obj.data.vertices:
        for e in v.groups:
            name=reverse.get(e.group)
            if name: out[name][v.index]=float(e.weight)
    return out


def _static(obj):
    states=[]
    for m in obj.modifiers:
        states.append((m,m.show_viewport,m.show_render))
        if m.type!='ARMATURE': m.show_viewport=False; m.show_render=False
    try:
        bpy.context.view_layer.update(); dg=bpy.context.evaluated_depsgraph_get(); ev=obj.evaluated_get(dg)
        mesh=bpy.data.meshes.new_from_object(ev,preserve_all_data_layers=True,depsgraph=dg)
        if len(mesh.vertices)!=len(obj.data.vertices): raise RuntimeError('topology mismatch')
        baked=bpy.data.objects.new('ThumbBoneIDV73',mesh); bpy.context.scene.collection.objects.link(baked); baked.matrix_world=obj.matrix_world.copy()
    finally:
        for m,v,r in states: m.show_viewport=v; m.show_render=r
        bpy.context.view_layer.update()
    return baked


def _mat(name,color,emission=0.0):
    mat=bpy.data.materials.new(name); mat.use_nodes=True
    p=next((n for n in mat.node_tree.nodes if n.type=='BSDF_PRINCIPLED'),None)
    if p:
        p.inputs['Base Color'].default_value=(*color,1.0); p.inputs['Roughness'].default_value=0.7
        if emission and 'Emission Color' in p.inputs:
            p.inputs['Emission Color'].default_value=(*color,1.0); p.inputs['Emission Strength'].default_value=emission
    return mat


def _metrics(scene,cam,obj,weights,vessel_center,vessel_radius,longitudinal,focus):
    view=(focus-cam.location).normalized(); axis=longitudinal.cross(view).normalized()
    if axis.length_squared<0.5: axis=Vector((1,0,0))
    cp=[v71._project(scene,cam,vessel_center+axis*vessel_radius),v71._project(scene,cam,vessel_center-axis*vessel_radius)]
    xs=sorted(p['px_top_left'][0] for p in cp)
    result={}
    for name in BONES:
        pts=[obj.matrix_world@obj.data.vertices[i].co for i,w in enumerate(weights[name]) if w>=0.5]
        if not pts:
            result[name]={'count':0}; continue
        bbox=v71._pixel_bbox(scene,cam,pts)
        outside=max(0.0,xs[0]-bbox['min'][0],bbox['max'][0]-xs[1])
        result[name]={'count':len(pts),'bbox':bbox,'outside_vessel_px':float(outside)}
    return {'vessel_x_px':xs,'vessel_diameter_px':float(xs[1]-xs[0]),'bones':result}


def run():
    ext,out,report_path=_args(); out.mkdir(parents=True,exist_ok=True); report_path.parent.mkdir(parents=True,exist_ok=True)
    v65._reset(); mpfb,HumanService=v65._services(ext)
    base=HumanService.create_human(mask_helpers=True,detailed_helpers=False,extra_vertex_groups=True,feet_on_ground=False,scale=0.1,macro_detail_dict=None)
    arm=HumanService.add_builtin_rig(base,'default',import_weights=True,operator=None)
    vessel_center,vessel_radius,palm_center,longitudinal,span,palmar=v65._author_power_grasp(arm,-1.0); bpy.context.view_layer.update()
    segments=v64._selected_segments(arm); weights=_bone_weights(base); baked=_static(base)
    mats=[_mat('ThumbIDBaseV73',(0.18,0.18,0.20)),_mat('ThumbRootV73',(0.95,0.05,0.55),0.8),_mat('ThumbProxV73',(0.0,0.92,0.95),0.8),_mat('ThumbDistalV73',(1.0,0.72,0.03),0.8)]
    baked.data.materials.clear()
    for m in mats: baked.data.materials.append(m)
    marked={name:0 for name in BONES}
    for poly in baked.data.polygons:
        scores=[max(weights[name][i] for i in poly.vertices) for name in BONES]
        best=max(range(3),key=lambda i:scores[i])
        if scores[best]>=0.30:
            poly.material_index=best+1; marked[BONES[best]]+=1
        else: poly.material_index=0
    v64b._adaptive_crop(baked,segments,palm_center)
    vessel=v65._vessel(vessel_center,longitudinal,vessel_radius,'B73')
    focus=palm_center.lerp(vessel_center,0.55); cam=v65._scene_camera(focus,longitudinal,span,palmar,'B73'); scene=bpy.context.scene
    base.hide_render=True; arm.hide_render=True; baked.hide_render=False; vessel.hide_render=False
    full=out/'thumb-bone-id-with-vessel.png'; thumb=out/'thumb-bone-id-thumbnail.png'; v65._render(full,640,640); v65._render(thumb,WIDTH,HEIGHT)
    vessel.hide_render=True
    anatomy=out/'thumb-bone-id-anatomy-oblique.png'; anatomy_thumb=out/'thumb-bone-id-anatomy-thumbnail.png'; v65._render(anatomy,640,640); v65._render(anatomy_thumb,WIDTH,HEIGHT)
    # Metrics use the same posed uncropped topology to preserve source vertex indices.
    metric_obj=_static(base); metrics=_metrics(scene,cam,metric_obj,weights,vessel_center,vessel_radius,longitudinal,focus)
    report={'diagnostic_only':True,'production_candidate':False,'base_pose':'pristine v65-B','reference_set':['bar_v1','market_v1'],'pose_changed_from_v65_b':False,'camera_changed_from_v65_b':False,'vessel_changed_from_v65_b':False,'bones':list(BONES),'dominant_face_threshold':0.30,'high_weight_metric_threshold':0.5,'marked_faces_before_crop':marked,'screen_metrics':metrics,'mpfb_version':list(mpfb.VERSION),'interpretation_gate':'Use the per-bone colors to identify which segment owns broad thenar/webbing versus the independently visible digit. Do not author another whole-chain translation if root/prox influence is the stretched region; next authoring may move only the anatomically distal segment(s) supported by this evidence.'}
    report_path.write_text(json.dumps(report,indent=2,sort_keys=True),encoding='utf-8'); print(json.dumps(report,indent=2,sort_keys=True)); print(SUCCESS)

if __name__=='__main__':
    try: run()
    except BaseException as exc:
        print('MPFB_THUMB_BONE_ID_V73_ERROR:',exc); traceback.print_exc(); raise
