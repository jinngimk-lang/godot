"""Inspect repository XR hand pose animations against the MPFB GameEngine hand rig.

This is a discovery step for semantic pose retargeting. It records exact source and
target bone names, imported Blender actions, animation channels, and verifies the
intended digit-chain map before any pose delta is transferred.
"""
from __future__ import annotations
import json, sys
from pathlib import Path
import bpy

MAP = {
    'Thumb_Proximal_R': 'thumb_01_r',
    'Thumb_Distal_R': 'thumb_03_r',
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


def _args():
    if '--' not in sys.argv: raise RuntimeError('expected -- <xr.glb> <mpfb.glb> <report.json>')
    a=sys.argv[sys.argv.index('--')+1:]
    if len(a)!=3: raise RuntimeError('expected three args')
    return Path(a[0]).resolve(),Path(a[1]).resolve(),Path(a[2]).resolve()


def _reset():
    bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
    for action in list(bpy.data.actions): bpy.data.actions.remove(action)


def _import(path):
    bpy.ops.import_scene.gltf(filepath=str(path))
    arms=[o for o in bpy.context.scene.objects if o.type=='ARMATURE']
    if not arms: raise RuntimeError(f'no armature in {path}')
    return arms[0]


def _actions():
    rows=[]
    for action in bpy.data.actions:
        slots=[]
        # Blender 4.2 glTF imports may expose FCurves directly or through channel bags.
        curves=[]
        try: curves=list(action.fcurves)
        except Exception: curves=[]
        for fc in curves:
            slots.append({'data_path':fc.data_path,'array_index':fc.array_index,'keys':len(fc.keyframe_points)})
        rows.append({'name':action.name,'frame_range':[float(action.frame_range[0]),float(action.frame_range[1])],'channels':slots})
    return rows


def _run():
    xr_path,mpfb_path,out=_args(); out.parent.mkdir(parents=True,exist_ok=True)
    _reset(); xr=_import(xr_path); xr_bones=sorted(b.name for b in xr.data.bones); actions=_actions()
    source_hits={src:(src in xr_bones) for src in MAP}
    source_relevant=[b for b in xr_bones if any(k in b for k in ('Thumb','Index','Middle','Ring','Little','Wrist'))]

    _reset(); mpfb=_import(mpfb_path); target_bones=sorted(b.name for b in mpfb.data.bones)
    target_hits={dst:(dst in target_bones) for dst in MAP.values()}
    target_relevant=[b for b in target_bones if any(k in b for k in ('thumb_','index_','middle_','ring_','pinky_','hand_r','lowerarm_r'))]

    missing_source=[k for k,v in source_hits.items() if not v]
    missing_target=[k for k,v in target_hits.items() if not v]
    action_names=[r['name'] for r in actions]
    report={
        'source':str(xr_path),'target':str(mpfb_path),
        'xr_relevant_bones':source_relevant,'mpfb_relevant_bones':target_relevant,
        'mapping':MAP,'missing_source':missing_source,'missing_target':missing_target,
        'actions':actions,'action_names':action_names,
    }
    out.write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    print('RETARGET_XR_RELEVANT',source_relevant)
    print('RETARGET_MPFB_RELEVANT',target_relevant)
    print('RETARGET_ACTIONS',action_names)
    print('RETARGET_MISSING_SOURCE',missing_source)
    print('RETARGET_MISSING_TARGET',missing_target)
    if missing_target: raise RuntimeError('target mapping incomplete: '+str(missing_target))
    # Source naming is deliberately diagnostic; fail if too much of the assumed map is wrong.
    if len(missing_source)>4: raise RuntimeError('source mapping assumptions too incomplete: '+str(missing_source))
    if not any(any(token in name.lower() for token in ('cup','pinch')) for name in action_names):
        raise RuntimeError('XR import exposed no Cup/Pinch action names')
    print('XR_MPFB_RETARGET_DIAGNOSTIC_SUCCESS')

if __name__=='__main__': _run()
