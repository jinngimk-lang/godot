import bpy
import json
import os
from mathutils import Matrix, Vector

SRC = "/tmp/oga-arms/FPS ARMS RIG 1 test anim.blend"
OUT = "assets/models/hands/hand_left.glb"
TARGET_PATH = "tools/support_hand_cafe_target_v94.json"
REPORT = "/tmp/support-hand-aligned/build-report.json"
# Keep the already machine-accepted scale correction fixed. This pass changes
# only source skin membership crop + one algebraic rigid frame alignment.
PRE_SCALE = 0.2542669875084634
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
FINGER_ROOTS = [
    "f_index.01.L",
    "f_middle.01.L",
    "f_ring.01.L",
    "f_pinky.01.L",
]
FINGER_DISTALS = [
    "f_index.03.L",
    "f_middle.03.L",
    "f_ring.03.L",
    "f_pinky.03.L",
]


def v3(values):
    return Vector((float(values[0]), float(values[1]), float(values[2])))


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


def hand_group_name(name):
    if name == "hand.L":
        return True
    if not name.endswith(".L"):
        return False
    return name.startswith(
        ("palm.", "thumb.", "f_index.", "f_middle.", "f_ring.", "f_pinky.")
    )


def frame_basis(radial, axis):
    axis = axis.normalized()
    radial = radial - axis * radial.dot(axis)
    if radial.length_squared <= 1e-10:
        raise RuntimeError("degenerate semantic radial axis")
    radial.normalize()
    tangent = axis.cross(radial)
    if tangent.length_squared <= 1e-10:
        raise RuntimeError("degenerate semantic tangent axis")
    tangent.normalize()
    # Columns are radial, tangent, vertical axis: r x t = axis.
    return Matrix((radial, tangent, axis)).transposed(), radial, tangent, axis


with open(TARGET_PATH, "r") as handle:
    target = json.load(handle)
target_center = v3(target["cup_center"])
target_axis = v3(target["cup_axis"])
target_radial = v3(target["cup_radial_from_wrist"])
target_basis, target_radial, target_tangent, target_axis = frame_basis(
    target_radial, target_axis
)

bpy.ops.wm.open_mainfile(filepath=SRC)
scene = bpy.context.scene
arm = next((obj for obj in scene.objects if obj.type == "ARMATURE"), None)
source_mesh = next((obj for obj in scene.objects if obj.type == "MESH"), None)
if arm is None or source_mesh is None:
    raise RuntimeError("native source missing armature or mesh")

# Snapshot fixed source-rig poses, plus the semantic Cup frame from frame 20.
snapshots = {}
for semantic_name, frame in POSE_FRAMES.items():
    scene.frame_set(frame)
    bpy.context.view_layer.update()
    snapshots[semantic_name] = {
        pose_bone.name: pose_bone.matrix.copy() for pose_bone in arm.pose.bones
    }

scene.frame_set(POSE_FRAMES["Cup"])
bpy.context.view_layer.update()
hand_head_world = arm.matrix_world @ arm.pose.bones["hand.L"].head
root_points_world = [arm.matrix_world @ arm.pose.bones[name].head for name in FINGER_ROOTS]
tip_points_world = [arm.matrix_world @ arm.pose.bones[name].tail for name in FINGER_DISTALS]
palm_world = (hand_head_world + sum(root_points_world, Vector())) / 5.0
fingers_world = sum(tip_points_world, Vector()) / 4.0
source_grip_world = fingers_world - palm_world
if source_grip_world.length_squared <= 1e-10:
    raise RuntimeError("source Cup pose has degenerate palm-to-finger direction")
source_grip_world.normalize()
source_width_world = root_points_world[0] - root_points_world[-1]
source_palm_width = source_width_world.length
source_axis_world = source_width_world.cross(source_grip_world)
if source_axis_world.length_squared <= 1e-10:
    raise RuntimeError("source Cup pose has degenerate cup axis")
source_axis_world.normalize()
source_radius = source_palm_width * 0.62
source_center_world = palm_world + source_grip_world * (source_radius * 0.80)

# Normalize source mode and isolate the substantial left arm island.
bpy.context.view_layer.objects.active = arm
if arm.mode != "OBJECT":
    bpy.ops.object.mode_set(mode="OBJECT")
for obj in scene.objects:
    obj.select_set(False)
source_mesh.select_set(True)
bpy.context.view_layer.objects.active = source_mesh
bpy.ops.object.mode_set(mode="EDIT")
bpy.ops.mesh.select_all(action="SELECT")
bpy.ops.mesh.separate(type="LOOSE")
bpy.ops.object.mode_set(mode="OBJECT")
parts = [obj for obj in scene.objects if obj.type == "MESH"]
left_wrist_world = arm.matrix_world @ arm.data.bones["hand.L"].head_local
substantial = [obj for obj in parts if len(obj.data.polygons) >= 500]
if not substantial:
    raise RuntimeError("source separation produced no substantial arm component")
keep = min(substantial, key=lambda obj: (bounds_center(obj) - left_wrist_world).length)
selected_component = {
    "name": keep.name,
    "vertices": len(keep.data.vertices),
    "polygons": len(keep.data.polygons),
}
for obj in list(parts):
    if obj != keep:
        bpy.data.objects.remove(obj, do_unlink=True)
keep.name = "SupportHandMesh"

# Canonical wrist basis derived from source bones, never from a camera-space tune.
wrist_world = arm.matrix_world @ arm.data.bones["hand.L"].head_local
elbow_world = arm.matrix_world @ arm.data.bones["forearm.L"].head_local
index_root_world = arm.matrix_world @ arm.data.bones["f_index.01.L"].head_local
pinky_root_world = arm.matrix_world @ arm.data.bones["f_pinky.01.L"].head_local
z_axis = (elbow_world - wrist_world).normalized()
x_axis = index_root_world - pinky_root_world
x_axis = (x_axis - z_axis * x_axis.dot(z_axis)).normalized()
y_axis = z_axis.cross(x_axis).normalized()
canonical = Matrix(
    (
        (x_axis.x, x_axis.y, x_axis.z, 0.0),
        (y_axis.x, y_axis.y, y_axis.z, 0.0),
        (z_axis.x, z_axis.y, z_axis.z, 0.0),
        (0.0, 0.0, 0.0, 1.0),
    )
) @ Matrix.Translation(-wrist_world)
arm.matrix_world = canonical @ arm.matrix_world
keep.matrix_world = canonical @ keep.matrix_world
bpy.context.view_layer.update()

# Transform source semantic Cup frame into canonical coordinates.
canonical3 = canonical.to_3x3()
source_center_canonical = canonical @ source_center_world
source_radial_canonical = (canonical3 @ source_grip_world).normalized()
source_axis_canonical = (canonical3 @ source_axis_world).normalized()
source_basis, source_radial_canonical, source_tangent_canonical, source_axis_canonical = frame_basis(
    source_radial_canonical, source_axis_canonical
)

# Structural forearm removal: preserve any vertex influenced by actual left
# hand/palm/finger deform groups. Delete forearm/upper-arm-only skin regardless
# of where the posed mesh happens to sit in space.
hand_groups = {
    group.index: group.name
    for group in keep.vertex_groups
    if hand_group_name(group.name)
}
if len(hand_groups) < 15:
    raise RuntimeError("too few semantic left-hand skin groups: %s" % sorted(hand_groups.values()))
for obj in scene.objects:
    obj.select_set(False)
keep.select_set(True)
bpy.context.view_layer.objects.active = keep
bpy.ops.object.mode_set(mode="EDIT")
bpy.ops.mesh.select_all(action="DESELECT")
bpy.ops.object.mode_set(mode="OBJECT")
kept_vertices = 0
removed_vertices = 0
for vertex in keep.data.vertices:
    belongs_to_hand = any(
        membership.group in hand_groups and membership.weight > 1e-6
        for membership in vertex.groups
    )
    vertex.select = not belongs_to_hand
    if belongs_to_hand:
        kept_vertices += 1
    else:
        removed_vertices += 1
bpy.ops.object.mode_set(mode="EDIT")
bpy.ops.mesh.delete(type="VERT")
bpy.ops.object.mode_set(mode="OBJECT")
if kept_vertices < 700 or len(keep.data.polygons) < 700:
    raise RuntimeError(
        "hand-bone crop retained implausibly little geometry: %dv/%dp"
        % (kept_vertices, len(keep.data.polygons))
    )

# Real distal bone tails are used to identify real fingertip/nail polygons.
tip_points = []
for bone_name in DISTAL:
    bone = arm.data.bones.get(bone_name)
    if bone is None:
        raise RuntimeError("missing distal bone " + bone_name)
    tip_points.append((bone_name, arm.matrix_world @ bone.tail_local))

if len(keep.data.materials) == 0 or keep.data.materials[0] is None:
    raise RuntimeError("source mesh imported without material")
skin = keep.data.materials[0]
skin.name = "HandSkin"
skin.diffuse_color = (0.83, 0.61, 0.49, 1.0)
if skin.use_nodes and skin.node_tree:
    principled = next(
        (node for node in skin.node_tree.nodes if node.type == "BSDF_PRINCIPLED"), None
    )
    if principled and "Roughness" in principled.inputs:
        principled.inputs["Roughness"].default_value = 0.62
nail = skin.copy()
nail.name = "HandNail"
if nail.use_nodes and nail.node_tree:
    principled = next(
        (node for node in nail.node_tree.nodes if node.type == "BSDF_PRINCIPLED"), None
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
# Palm width in canonical rest space is only a distance tolerance scale.
rest_index = arm.matrix_world @ arm.data.bones["f_index.01.L"].head_local
rest_pinky = arm.matrix_world @ arm.data.bones["f_pinky.01.L"].head_local
rest_palm_width = (rest_index - rest_pinky).length
for bone_name, tip in tip_points:
    nearest = sorted(
        [((center - tip).length, index) for index, center in poly_centers],
        key=lambda item: item[0],
    )[:4]
    if not nearest:
        raise RuntimeError("no real skin surface near " + bone_name)
    nearest_distance = nearest[0][0]
    tip_distances[bone_name] = nearest_distance
    if nearest_distance > rest_palm_width * 0.25:
        raise RuntimeError("%s distal tail too far from real surface" % bone_name)
    band = nearest_distance + rest_palm_width * 0.035
    for distance, polygon_index in nearest:
        if distance <= band:
            selected_nail_faces.add(polygon_index)
if len(selected_nail_faces) < 5:
    raise RuntimeError("fewer than five real fingertip faces selected for HandNail")
for polygon_index in selected_nail_faces:
    keep.data.polygons[polygon_index].material_index = 1

# Semantic bone/group names expected by HandVisual.
for old_name, new_name in RENAME.items():
    if arm.data.bones.get(old_name):
        arm.data.bones[old_name].name = new_name
    if keep.vertex_groups.get(old_name):
        keep.vertex_groups[old_name].name = new_name
new_to_old = {new_name: old_name for old_name, new_name in RENAME.items()}

# Freeze the four evaluated source-rig poses exactly as semantic actions.
for pose_bone in arm.pose.bones:
    while pose_bone.constraints:
        pose_bone.constraints.remove(pose_bone.constraints[0])
    pose_bone.rotation_mode = "QUATERNION"
arm.animation_data_clear()
for action in list(bpy.data.actions):
    bpy.data.actions.remove(action)
arm.animation_data_create()
ordered = sorted(list(arm.pose.bones), key=pose_depth)
actions = []
for semantic_name in POSE_FRAMES.keys():
    action = bpy.data.actions.new(semantic_name)
    action.use_fake_user = True
    arm.animation_data.action = action
    for pose_bone in arm.pose.bones:
        pose_bone.matrix_basis = Matrix.Identity(4)
    bpy.context.view_layer.update()
    snapshot = snapshots[semantic_name]
    for pose_bone in ordered:
        old_name = new_to_old.get(pose_bone.name, pose_bone.name)
        if old_name in snapshot:
            pose_bone.matrix = snapshot[old_name]
    bpy.context.view_layer.update()
    for pose_bone in arm.pose.bones:
        pose_bone.keyframe_insert(data_path="location", frame=0, group=pose_bone.name)
        pose_bone.keyframe_insert(data_path="rotation_quaternion", frame=0, group=pose_bone.name)
        pose_bone.keyframe_insert(data_path="scale", frame=0, group=pose_bone.name)
    actions.append(action)
arm.animation_data.action = None
for action in actions:
    track = arm.animation_data.nla_tracks.new()
    track.name = action.name
    strip = track.strips.new(action.name, 0, action)
    strip.name = action.name

# Keep the already accepted candidate scale fixed, then apply exactly one rigid
# transform that maps the source semantic Cup frame to the measured Godot frame.
scale_matrix = Matrix.Scale(PRE_SCALE, 4)
arm.matrix_world = scale_matrix @ arm.matrix_world
keep.matrix_world = scale_matrix @ keep.matrix_world
source_center_scaled = source_center_canonical * PRE_SCALE
rotation3 = target_basis @ source_basis.inverted()
alignment = Matrix.Translation(target_center) @ rotation3.to_4x4() @ Matrix.Translation(
    -source_center_scaled
)
arm.matrix_world = alignment @ arm.matrix_world
keep.matrix_world = alignment @ keep.matrix_world
bpy.context.view_layer.update()

# Algebraic gate: the semantic frame must map to the measured target before export.
mapped_center = alignment @ source_center_scaled
mapped_radial = (rotation3 @ source_radial_canonical).normalized()
mapped_axis = (rotation3 @ source_axis_canonical).normalized()
center_error = (mapped_center - target_center).length
radial_dot = mapped_radial.dot(target_radial)
axis_dot = mapped_axis.dot(target_axis)
if center_error > 1e-6 or radial_dot < 0.99999 or axis_dot < 0.99999:
    raise RuntimeError(
        "semantic Cup frame alignment failed: center=%.9f radial=%.9f axis=%.9f"
        % (center_error, radial_dot, axis_dot)
    )

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
    "source_archive_sha256": "31f6c7bd5caea8856c4aafca8461f38a3c8bfdd3d8f05c898e403b9475e54562",
    "target_measurement_run": target["measurement_run"],
    "pre_scale_fixed_from_previous_machine_green": PRE_SCALE,
    "selected_component": selected_component,
    "hand_skin_groups": sorted(hand_groups.values()),
    "vertices_kept_by_hand_bones": kept_vertices,
    "vertices_removed_as_forearm_only": removed_vertices,
    "mesh_vertices_after_crop": len(keep.data.vertices),
    "mesh_polygons_after_crop": len(keep.data.polygons),
    "nail_region_faces": len(selected_nail_faces),
    "source_semantic_cup_center_canonical": list(source_center_canonical),
    "source_semantic_cup_radial_canonical": list(source_radial_canonical),
    "source_semantic_cup_axis_canonical": list(source_axis_canonical),
    "target_cup_center": list(target_center),
    "target_cup_radial": list(target_radial),
    "target_cup_axis": list(target_axis),
    "alignment_center_error": center_error,
    "alignment_radial_dot": radial_dot,
    "alignment_axis_dot": axis_dot,
    "actions": [action.name for action in actions],
    "output_bytes": os.path.getsize(OUT),
}
with open(REPORT, "w") as handle:
    json.dump(report, handle, indent=2)
print(json.dumps(report, indent=2))
