import bpy
import json
import os
from mathutils import Matrix, Vector

SRC = "/tmp/oga-arms/FPS ARMS RIG 1 test anim.blend"
OUT = "assets/models/hands/hand_left.glb"
REPORT = "/tmp/support-hand-build/build-report.json"
PRE_SCALE = 1.0 / 2.25
POSE_FRAMES = {
    "Default pose": 1,
    "Pinch Up": 14,
    "Cup": 20,
    "Pinch Tight": 28,
}
RENAME = {
    "hand.L": "Wrist_L",
    "thumb.01.L": "Thumb_Proximal_L",
    "thumb.02.L": "Thumb_Intermediate_L",
    "thumb.03.L": "Thumb_Distal_L",
    "f_index.01.L": "Index_Proximal_L",
    "f_index.02.L": "Index_Intermediate_L",
    "f_index.03.L": "Index_Distal_L",
    "f_middle.01.L": "Middle_Proximal_L",
    "f_middle.02.L": "Middle_Intermediate_L",
    "f_middle.03.L": "Middle_Distal_L",
    "f_ring.01.L": "Ring_Proximal_L",
    "f_ring.02.L": "Ring_Intermediate_L",
    "f_ring.03.L": "Ring_Distal_L",
    "f_pinky.01.L": "Little_Proximal_L",
    "f_pinky.02.L": "Little_Intermediate_L",
    "f_pinky.03.L": "Little_Distal_L",
}
DISTAL = [
    "thumb.03.L",
    "f_index.03.L",
    "f_middle.03.L",
    "f_ring.03.L",
    "f_pinky.03.L",
]


def bounds_center(obj):
    points = [obj.matrix_world @ Vector(corner) for corner in obj.bound_box]
    return sum(points, Vector()) / float(len(points))


def pose_depth(pose_bone):
    depth = 0
    parent = pose_bone.parent
    while parent is not None:
        depth += 1
        parent = parent.parent
    return depth


bpy.ops.wm.open_mainfile(filepath=SRC)
scene = bpy.context.scene
arm = next((obj for obj in scene.objects if obj.type == "ARMATURE"), None)
source_mesh = next((obj for obj in scene.objects if obj.type == "MESH"), None)
if arm is None or source_mesh is None:
    raise RuntimeError("native source missing armature or mesh")

# Snapshot four whole-hand poses from the source's evaluated native rig. These
# are fixed authored frames, not a parameter or pose search.
snapshots = {}
for semantic_name, frame in POSE_FRAMES.items():
    scene.frame_set(frame)
    bpy.context.view_layer.update()
    snapshots[semantic_name] = {
        pose_bone.name: pose_bone.matrix.copy() for pose_bone in arm.pose.bones
    }

# The source .blend is saved in Pose Mode. Normalize context first.
bpy.context.view_layer.objects.active = arm
if arm.mode != "OBJECT":
    bpy.ops.object.mode_set(mode="OBJECT")
for obj in scene.objects:
    obj.select_set(False)

# Split disconnected mesh islands. The archive contains tiny stray components,
# so never choose by center-distance alone; require a real substantial surface.
source_mesh.select_set(True)
bpy.context.view_layer.objects.active = source_mesh
bpy.ops.object.mode_set(mode="EDIT")
bpy.ops.mesh.select_all(action="SELECT")
bpy.ops.mesh.separate(type="LOOSE")
bpy.ops.object.mode_set(mode="OBJECT")
parts = [obj for obj in scene.objects if obj.type == "MESH"]
left_wrist_world = arm.matrix_world @ arm.data.bones["hand.L"].head_local
component_report = [
    {
        "name": obj.name,
        "vertices": len(obj.data.vertices),
        "polygons": len(obj.data.polygons),
        "center_distance_to_left_wrist": (bounds_center(obj) - left_wrist_world).length,
    }
    for obj in parts
]
substantial = [obj for obj in parts if len(obj.data.polygons) >= 500]
if not substantial:
    raise RuntimeError("source separation produced no substantial arm component")
keep = min(substantial, key=lambda obj: (bounds_center(obj) - left_wrist_world).length)
if len(keep.data.polygons) < 1000:
    raise RuntimeError("selected left arm component is structurally too small")
for obj in list(parts):
    if obj != keep:
        bpy.data.objects.remove(obj, do_unlink=True)
keep.name = "SupportHandMesh"

# Structural canonical basis: wrist origin, wrist->elbow +Z, pinky->index +X.
wrist = arm.matrix_world @ arm.data.bones["hand.L"].head_local
elbow = arm.matrix_world @ arm.data.bones["forearm.L"].head_local
index_root = arm.matrix_world @ arm.data.bones["f_index.01.L"].head_local
pinky_root = arm.matrix_world @ arm.data.bones["f_pinky.01.L"].head_local
z_axis = (elbow - wrist).normalized()
x_axis = index_root - pinky_root
x_axis = (x_axis - z_axis * x_axis.dot(z_axis)).normalized()
y_axis = z_axis.cross(x_axis).normalized()
canonical = Matrix(
    (
        (x_axis.x, x_axis.y, x_axis.z, 0.0),
        (y_axis.x, y_axis.y, y_axis.z, 0.0),
        (z_axis.x, z_axis.y, z_axis.z, 0.0),
        (0.0, 0.0, 0.0, 1.0),
    )
) @ Matrix.Translation(-wrist)
arm.matrix_world = canonical @ arm.matrix_world
keep.matrix_world = canonical @ keep.matrix_world
bpy.context.view_layer.update()
index_now = arm.matrix_world @ arm.data.bones["f_index.01.L"].head_local
pinky_now = arm.matrix_world @ arm.data.bones["f_pinky.01.L"].head_local
palm_width = (index_now - pinky_now).length
if palm_width <= 0.05:
    raise RuntimeError("implausible palm width after canonicalization")

# Record real distal bone tails before semantic renaming.
tip_points = []
for bone_name in DISTAL:
    bone = arm.data.bones.get(bone_name)
    if bone is None:
        raise RuntimeError("missing distal bone " + bone_name)
    tip_points.append((bone_name, arm.matrix_world @ bone.tail_local))

# The measured diagnosis proves fingers are negative Z and forearm is positive Z.
# Keep a narrow wrist overlap for the runtime sleeve, delete only arm-side skin.
cutoff = palm_width * 0.10
for obj in scene.objects:
    obj.select_set(False)
keep.select_set(True)
bpy.context.view_layer.objects.active = keep
bpy.ops.object.mode_set(mode="EDIT")
bpy.ops.mesh.select_all(action="DESELECT")
bpy.ops.object.mode_set(mode="OBJECT")
for vertex in keep.data.vertices:
    vertex.select = (keep.matrix_world @ vertex.co).z > cutoff
bpy.ops.object.mode_set(mode="EDIT")
bpy.ops.mesh.delete(type="VERT")
bpy.ops.object.mode_set(mode="OBJECT")
if len(keep.data.polygons) < 800:
    raise RuntimeError(
        "forearm crop removed implausibly much hand geometry: %d polygons"
        % len(keep.data.polygons)
    )

# Preserve the original textured material as HandSkin.
if len(keep.data.materials) == 0 or keep.data.materials[0] is None:
    raise RuntimeError("source mesh imported without material")
skin = keep.data.materials[0]
skin.name = "HandSkin"
skin.diffuse_color = (0.83, 0.61, 0.49, 1.0)
if skin.use_nodes and skin.node_tree:
    principled = next(
        (node for node in skin.node_tree.nodes if node.type == "BSDF_PRINCIPLED"),
        None,
    )
    if principled and "Roughness" in principled.inputs:
        principled.inputs["Roughness"].default_value = 0.62

# HandNail must own actual fingertip surface, never hidden proxy geometry.
nail = skin.copy()
nail.name = "HandNail"
if nail.use_nodes and nail.node_tree:
    principled = next(
        (node for node in nail.node_tree.nodes if node.type == "BSDF_PRINCIPLED"),
        None,
    )
    if principled and "Roughness" in principled.inputs:
        principled.inputs["Roughness"].default_value = 0.44
keep.data.materials.append(nail)

poly_centers = []
for polygon in keep.data.polygons:
    center_local = sum(
        (keep.data.vertices[index].co for index in polygon.vertices), Vector()
    ) / float(len(polygon.vertices))
    poly_centers.append((polygon.index, keep.matrix_world @ center_local))
selected_nail_faces = set()
tip_distances = {}
for bone_name, tip in tip_points:
    nearest = sorted(
        [((center - tip).length, index) for index, center in poly_centers],
        key=lambda item: item[0],
    )[:4]
    if not nearest:
        raise RuntimeError("no real skin surface near " + bone_name)
    nearest_distance = nearest[0][0]
    tip_distances[bone_name] = nearest_distance
    if nearest_distance > palm_width * 0.25:
        raise RuntimeError(
            "%s distal tail too far from real skin surface: %.6f"
            % (bone_name, nearest_distance)
        )
    band = nearest_distance + palm_width * 0.035
    for distance, polygon_index in nearest:
        if distance <= band:
            selected_nail_faces.add(polygon_index)
if len(selected_nail_faces) < 5:
    raise RuntimeError("fewer than five real fingertip faces selected for HandNail")
for polygon_index in selected_nail_faces:
    keep.data.polygons[polygon_index].material_index = 1
max_tip_surface_distance = max(tip_distances.values())

# Rename the semantic deform bones and matching vertex groups HandVisual uses.
for old_name, new_name in RENAME.items():
    if arm.data.bones.get(old_name):
        arm.data.bones[old_name].name = new_name
    if keep.vertex_groups.get(old_name):
        keep.vertex_groups[old_name].name = new_name
new_to_old = {new_name: old_name for old_name, new_name in RENAME.items()}

# Remove native constraints only after snapshots, then recreate the four exact
# evaluated whole-hand poses as static semantic actions.
for pose_bone in arm.pose.bones:
    while pose_bone.constraints:
        pose_bone.constraints.remove(pose_bone.constraints[0])
    pose_bone.rotation_mode = "QUATERNION"
arm.animation_data_clear()
for action in list(bpy.data.actions):
    bpy.data.actions.remove(action)
arm.animation_data_create()
ordered_bones = sorted(list(arm.pose.bones), key=pose_depth)
actions = []
for semantic_name in POSE_FRAMES.keys():
    action = bpy.data.actions.new(semantic_name)
    action.use_fake_user = True
    arm.animation_data.action = action
    for pose_bone in arm.pose.bones:
        pose_bone.matrix_basis = Matrix.Identity(4)
    bpy.context.view_layer.update()
    snapshot = snapshots[semantic_name]
    for pose_bone in ordered_bones:
        old_name = new_to_old.get(pose_bone.name, pose_bone.name)
        if old_name in snapshot:
            pose_bone.matrix = snapshot[old_name]
    bpy.context.view_layer.update()
    for pose_bone in arm.pose.bones:
        pose_bone.keyframe_insert(data_path="location", frame=0, group=pose_bone.name)
        pose_bone.keyframe_insert(
            data_path="rotation_quaternion", frame=0, group=pose_bone.name
        )
        pose_bone.keyframe_insert(data_path="scale", frame=0, group=pose_bone.name)
    actions.append(action)

# NLA tracks make all four semantic clips explicit to Blender 4.0's glTF exporter.
arm.animation_data.action = None
for action in actions:
    track = arm.animation_data.nla_tracks.new()
    track.name = action.name
    strip = track.strips.new(action.name, 0, action)
    strip.name = action.name

# Cancel HandVisual's legacy 2.25 authored-root multiplier structurally.
scale_matrix = Matrix.Scale(PRE_SCALE, 4)
arm.matrix_world = scale_matrix @ arm.matrix_world
keep.matrix_world = scale_matrix @ keep.matrix_world
bpy.context.view_layer.update()

for obj in scene.objects:
    obj.select_set(False)
keep.select_set(True)
arm.select_set(True)
bpy.context.view_layer.objects.active = arm
if arm.mode != "OBJECT":
    bpy.ops.object.mode_set(mode="OBJECT")
scene.frame_set(0)
bpy.ops.export_scene.gltf(
    filepath=OUT,
    export_format="GLB",
    use_selection=True,
    export_animations=True,
    export_nla_strips=True,
    export_force_sampling=True,
)
if not os.path.exists(OUT) or os.path.getsize(OUT) < 50000:
    raise RuntimeError("GLB export missing or implausibly small")

report = {
    "source": SRC,
    "source_archive_sha256": "31f6c7bd5caea8856c4aafca8461f38a3c8bfdd3d8f05c898e403b9475e54562",
    "source_pose_frames": POSE_FRAMES,
    "pre_scale": PRE_SCALE,
    "component_candidates": component_report,
    "selected_component_vertices_before_crop": next(
        item["vertices"] for item in component_report if item["name"] == keep.name
    ) if any(item["name"] == keep.name for item in component_report) else None,
    "palm_width_before_prescale": palm_width,
    "forearm_cutoff_before_prescale": cutoff,
    "mesh_vertices_after_crop": len(keep.data.vertices),
    "mesh_polygons_after_crop": len(keep.data.polygons),
    "nail_region_faces": len(selected_nail_faces),
    "tip_surface_distances": tip_distances,
    "max_nail_tip_surface_distance": max_tip_surface_distance,
    "bones": len(arm.data.bones),
    "actions": [action.name for action in actions],
    "output_bytes": os.path.getsize(OUT),
}
with open(REPORT, "w") as handle:
    json.dump(report, handle, indent=2)
print(json.dumps(report, indent=2))
