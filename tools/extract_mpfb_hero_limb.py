"""Extract one skinned MPFB GameEngine hero limb from a full-body source GLB."""
from __future__ import annotations
import json, sys, traceback
from pathlib import Path
import bpy, bmesh
from mathutils import Vector

SUCCESS_MARKER='MPFB_HERO_LIMB_EXTRACT_SUCCESS'
ERROR_MARKER='MPFB_HERO_LIMB_EXTRACT_ERROR'

def _args():
    if '--' not in sys.argv: raise RuntimeError('expected -- <input.glb> <left|right> <output.glb> <report.json>')
    v=sys.argv[sys.argv.index('--')+1:]
    if len(v)!=4: raise RuntimeError('expected four arguments after --')
    side=v[1].lower()
    if side not in ('left','right'): raise RuntimeError('side must be left or right')
    return Path(v[0]).resolve(), side, Path(v[2]).resolve(), Path(v[3]).resolve()

def _reset():
    bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)

def _find_source():
    meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']
    arms=[o for o in bpy.context.scene.objects if o.type=='ARMATURE']
    if not meshes or not arms: raise RuntimeError('source must contain mesh and armature')
    return max(meshes,key=lambda o:len(o.data.vertices)), arms[0]

def _allowed(name, suffix):
    n=name.lower()
    if not n.endswith(suffix): return False
    return any(t in n for t in ('upperarm','lowerarm','hand','thumb','index','middle','ring','pinky'))

def _weighted_counts(obj, suffix):
    out={}
    for vg in obj.vertex_groups:
        if not _allowed(vg.name,suffix): continue
        count=0
        for vert in obj.data.vertices:
            try: w=vg.weight(vert.index)
            except RuntimeError: continue
            if w>0.0001: count+=1
        out[vg.name]=count
    return out

def _extract(obj, suffix):
    allowed={g.index for g in obj.vertex_groups if _allowed(g.name,suffix)}
    if not allowed: raise RuntimeError(f'no deform groups for {suffix}')
    keep=set()
    for v in obj.data.vertices:
        if any(e.group in allowed and e.weight>0.0001 for e in v.groups): keep.add(v.index)
    if not keep: raise RuntimeError('no vertices selected for limb')
    full=len(obj.data.vertices)
    bm=bmesh.new(); bm.from_mesh(obj.data); bm.verts.ensure_lookup_table()
    doomed=[v for v in bm.verts if v.index not in keep]
    bmesh.ops.delete(bm, geom=doomed, context='VERTS')
    bm.to_mesh(obj.data); bm.free(); obj.data.update()
    return full, len(obj.data.vertices)

def _bounds(obj):
    pts=[obj.matrix_world@Vector(c) for c in obj.bound_box]
    return {'min':[min(p[i] for p in pts) for i in range(3)], 'max':[max(p[i] for p in pts) for i in range(3)]}

def _export(path, mesh, arm):
    bpy.ops.object.select_all(action='DESELECT'); mesh.select_set(True); arm.select_set(True); bpy.context.view_layer.objects.active=arm
    bpy.ops.export_scene.gltf(filepath=str(path), export_format='GLB', use_selection=True, export_skins=True, export_animations=False, export_morph=False, export_apply=False)

def _run():
    inp, side, out, report=_args(); out.parent.mkdir(parents=True,exist_ok=True); report.parent.mkdir(parents=True,exist_ok=True)
    _reset(); bpy.ops.import_scene.gltf(filepath=str(inp)); mesh,arm=_find_source(); suffix='_r' if side=='right' else '_l'
    before_counts=_weighted_counts(mesh,suffix); full, retained=_extract(mesh,suffix); after_counts=_weighted_counts(mesh,suffix)
    mesh.name=f'MPFBHeroLimb_{side}'; mesh.data.name=f'MPFBHeroLimbMesh_{side}'
    _export(out,mesh,arm)
    if not out.is_file() or out.stat().st_size<=0: raise RuntimeError('limb GLB export failed')
    summary={
      'side':side,
      'mesh':{'source_vertices':full,'vertices':retained,'polygons':len(mesh.data.polygons),'bounds_world':_bounds(mesh)},
      'retained_groups':{
        'upperarm':sum(v for k,v in after_counts.items() if 'upperarm' in k.lower()),
        'lowerarm':sum(v for k,v in after_counts.items() if 'lowerarm' in k.lower()),
        'hand':sum(v for k,v in after_counts.items() if k.lower().startswith('hand_')),
        'fingers':sum(v for k,v in after_counts.items() if any(t in k.lower() for t in ('thumb','index','middle','ring','pinky'))),
      },
      'group_counts_before':before_counts,'group_counts_after':after_counts,
      'armature_bones':len(arm.data.bones),'output_bytes':out.stat().st_size,
    }
    report.write_text(json.dumps(summary,indent=2),encoding='utf-8'); print(json.dumps(summary,indent=2)); print(SUCCESS_MARKER)
if __name__=='__main__':
    try:_run()
    except BaseException as e:
        print(f'{ERROR_MARKER}: {e}'); traceback.print_exc(); raise
