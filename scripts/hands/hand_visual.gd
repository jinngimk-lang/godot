extends Node3D
class_name HandVisual

const RIGHT_ASSET_PATH := "res://assets/models/hands/hand_right.glb"
const LEFT_ASSET_PATH := "res://assets/models/hands/hand_left.glb"
const FINGER_NAMES := ["Thumb", "Index", "Middle", "Ring", "Little"]
const AUTHORED_PRESENTATION_SCALE := 2.25

var follow_rate := 11.0
var pinch_follow_rate := 16.0

var _target := Vector3.ZERO
var _dynamic := false
var _mirror_sign := 1.0
var _pinch_target := 0.0
var _pinch_amount := 0.0
var _built := false
var _using_authored_asset := false
var _last_authored_pose := ""

var _authored_root: Node3D
var _animation_player: AnimationPlayer
var _skeleton: Skeleton3D

var _skin: StandardMaterial3D
var _nail: StandardMaterial3D
var _sleeve_fabric: StandardMaterial3D
var _sleeve_rib: StandardMaterial3D
var _finger_segments: Dictionary = {}
var _finger_tips: Dictionary = {}
var _nails: Dictionary = {}
var _thumb_tip: Node3D
var _index_tip: Node3D
var _pinch_point: Node3D

func setup(dynamic_hand: bool) -> void:
	_dynamic = dynamic_hand
	_mirror_sign = 1.0 if dynamic_hand else -1.0
	_ensure_anchors()
	if not _built:
		_using_authored_asset = _try_build_authored_hand()
		if not _using_authored_asset:
			_build_procedural_hand()
		_built = true
	_pinch_target = 0.18 if dynamic_hand else 0.42
	_pinch_amount = _pinch_target
	_apply_pose()

func is_using_authored_asset() -> bool:
	return _using_authored_asset

# Target is the world-space point that thumb and index should pinch around.
func set_grip_target(target: Vector3) -> void:
	_target = target

func set_target(target: Vector3) -> void:
	set_grip_target(target)

func set_pinch_amount(amount: float) -> void:
	_pinch_target = clampf(amount if is_finite(amount) else 0.0, 0.0, 1.0)

func get_finger_count() -> int:
	return FINGER_NAMES.size()

func get_pinch_world_position() -> Vector3:
	if _pinch_point == null:
		return global_position
	return to_global(_pinch_point.position)

# Snap keeps legacy root-position semantics for initial scene placement.
func snap_to(target: Vector3) -> void:
	position = target
	_refresh_pinch_anchors()
	if _pinch_point != null:
		_target = to_global(_pinch_point.position)
	else:
		_target = target

func tick(delta: float) -> void:
	var safe_delta := clampf(delta if is_finite(delta) else 0.0, 0.0, 0.1)
	var pinch_weight := 1.0 - exp(-pinch_follow_rate * safe_delta)
	_pinch_amount = lerpf(_pinch_amount, _pinch_target, pinch_weight)
	_apply_pose()
	_refresh_pinch_anchors()
	if _dynamic:
		var desired_root := _target
		if _pinch_point != null:
			desired_root = _target - basis * _pinch_point.position
		var weight := 1.0 - exp(-follow_rate * safe_delta)
		position = position.lerp(desired_root, weight)

func _ensure_anchors() -> void:
	if _thumb_tip == null:
		_thumb_tip = Node3D.new()
		_thumb_tip.name = "ThumbTip"
		add_child(_thumb_tip)
	if _index_tip == null:
		_index_tip = Node3D.new()
		_index_tip.name = "IndexTip"
		add_child(_index_tip)
	if _pinch_point == null:
		_pinch_point = Node3D.new()
		_pinch_point.name = "PinchPoint"
		add_child(_pinch_point)

func _try_build_authored_hand() -> bool:
	var asset_path := RIGHT_ASSET_PATH if _dynamic else LEFT_ASSET_PATH
	if not ResourceLoader.exists(asset_path):
		return false
	var packed = load(asset_path)
	if packed == null or not (packed is PackedScene):
		return false
	var instance = packed.instantiate()
	if instance == null or not (instance is Node3D):
		if instance != null:
			instance.free()
		return false

	_authored_root = instance as Node3D
	_authored_root.name = "AuthoredHand"
	add_child(_authored_root)
	_animation_player = _find_animation_player(_authored_root)
	_skeleton = _find_skeleton(_authored_root)
	if _animation_player == null or _skeleton == null:
		remove_child(_authored_root)
		_authored_root.free()
		_authored_root = null
		_animation_player = null
		_skeleton = null
		return false

	var required_pose := "Pinch Up" if _dynamic else "Cup"
	if not _animation_player.has_animation(required_pose):
		remove_child(_authored_root)
		_authored_root.free()
		_authored_root = null
		_animation_player = null
		_skeleton = null
		return false

	# GLBs are authored in XR-scale units; presentation scale makes them read beside the game cup.
	_authored_root.position = Vector3.ZERO
	_authored_root.rotation = Vector3.ZERO
	_authored_root.scale = Vector3.ONE * AUTHORED_PRESENTATION_SCALE
	_build_authored_wrist_cover()
	_apply_authored_pose(required_pose)
	_refresh_authored_anchors()
	return true

func _build_authored_wrist_cover() -> void:
	if _authored_root == null:
		return

	# Real-render diagnostics show both imported hand meshes ending at local
	# +Z ~= 0.026, with Wrist_L/Wrist_R rooted at +Z ~= 0.027. The cloth starts
	# just inside that plane and extends beyond the camera edge. Keeping the
	# forearm narrow and dark makes the hand/label interaction remain primary.
	_sleeve_fabric = StandardMaterial3D.new()
	_sleeve_fabric.resource_name = "SleeveFabric"
	_sleeve_fabric.albedo_color = Color(0.18, 0.13, 0.11, 1.0)
	_sleeve_fabric.roughness = 0.98

	_sleeve_rib = StandardMaterial3D.new()
	_sleeve_rib.resource_name = "SleeveRib"
	_sleeve_rib.albedo_color = Color(0.32, 0.25, 0.21, 1.0)
	_sleeve_rib.roughness = 0.97

	var sleeve_length := 0.64 if _dynamic else 0.70
	var far_radius := 0.052 if _dynamic else 0.056
	var sleeve := MeshInstance3D.new()
	sleeve.name = "WristSleeve"
	var sleeve_mesh := CylinderMesh.new()
	# After the +90° X rotation the mesh's -Y end is the wrist and +Y points
	# outward along authored local +Z.
	sleeve_mesh.bottom_radius = 0.034
	sleeve_mesh.top_radius = far_radius
	sleeve_mesh.height = sleeve_length
	sleeve.mesh = sleeve_mesh
	sleeve.material_override = _sleeve_fabric
	sleeve.position = Vector3(0.0, 0.0, 0.020 + sleeve_length * 0.5)
	sleeve.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	# A slim oval cross-section reads more like a cloth-covered forearm and
	# removes the previous oversized tube silhouette.
	sleeve.scale = Vector3(0.82, 1.0, 0.68)
	_authored_root.add_child(sleeve)

	# A very short rib band hides the exact skin/cloth join without creating a
	# second visible tube.
	var cuff := MeshInstance3D.new()
	cuff.name = "WristCuff"
	var cuff_mesh := CylinderMesh.new()
	cuff_mesh.top_radius = 0.037
	cuff_mesh.bottom_radius = 0.037
	cuff_mesh.height = 0.012
	cuff.mesh = cuff_mesh
	cuff.material_override = _sleeve_rib
	cuff.position = Vector3(0.0, 0.0, 0.028)
	cuff.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	cuff.scale = Vector3(0.86, 1.0, 0.72)
	_authored_root.add_child(cuff)

func _apply_pose() -> void:
	if not _built and not _using_authored_asset:
		return
	if _using_authored_asset:
		var pose_name := "Cup" if not _dynamic else ("Pinch Tight" if _pinch_amount >= 0.42 else "Pinch Up")
		if _animation_player != null and not _animation_player.has_animation(pose_name):
			pose_name = "Pinch Up" if _dynamic else "Default pose"
		_apply_authored_pose(pose_name)
		return
	_apply_procedural_pose()

func _apply_authored_pose(pose_name: String) -> void:
	if _animation_player == null or not _animation_player.has_animation(pose_name):
		return
	if _last_authored_pose == pose_name:
		return
	_animation_player.play(pose_name)
	_animation_player.seek(0.0, true)
	_animation_player.pause()
	_last_authored_pose = pose_name

func _refresh_pinch_anchors() -> void:
	if _using_authored_asset:
		_refresh_authored_anchors()
	else:
		_refresh_procedural_anchors()

func _refresh_authored_anchors() -> void:
	if _skeleton == null:
		return
	var suffix := "R" if _dynamic else "L"
	var thumb_local = _estimate_bone_tip("Thumb_Proximal_%s" % suffix, "Thumb_Distal_%s" % suffix, 0.020)
	var index_local = _estimate_bone_tip("Index_Intermediate_%s" % suffix, "Index_Distal_%s" % suffix, 0.020)
	if thumb_local != null:
		_thumb_tip.position = thumb_local as Vector3
	if index_local != null:
		_index_tip.position = index_local as Vector3
	if thumb_local != null and index_local != null:
		_pinch_point.position = ((thumb_local as Vector3) + (index_local as Vector3)) * 0.5
	elif _dynamic:
		# Conservative fallback near the authored palm if an importer changes bone names.
		_pinch_point.position = Vector3(-0.03, -0.08, -0.13)
	else:
		_pinch_point.position = Vector3(0.03, -0.08, -0.13)

func _estimate_bone_tip(previous_name: String, distal_name: String, extension: float):
	if _skeleton == null:
		return null
	var previous_id := _skeleton.find_bone(previous_name)
	var distal_id := _skeleton.find_bone(distal_name)
	if previous_id < 0 or distal_id < 0:
		return null
	var previous_pose := _skeleton.get_bone_global_pose(previous_id)
	var distal_pose := _skeleton.get_bone_global_pose(distal_id)
	var direction := distal_pose.origin - previous_pose.origin
	if direction.length_squared() <= 0.000001:
		return null
	var skeleton_local_tip := distal_pose.origin + direction.normalized() * extension
	return _descendant_point_to_local(_skeleton, skeleton_local_tip)

func _descendant_point_to_local(descendant: Node3D, point: Vector3):
	var current := descendant
	var converted := point
	while current != self:
		if current.is_set_as_top_level():
			return null
		converted = current.transform * converted
		var parent := current.get_parent()
		if not (parent is Node3D):
			return null
		current = parent as Node3D
	return converted

func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var found := _find_animation_player(child)
		if found != null:
			return found
	return null

func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node as Skeleton3D
	for child in node.get_children():
		var found := _find_skeleton(child)
		if found != null:
			return found
	return null

func _build_procedural_hand() -> void:
	_skin = StandardMaterial3D.new()
	_skin.albedo_color = Color(0.86, 0.67, 0.56, 1.0)
	_skin.roughness = 0.72

	_nail = StandardMaterial3D.new()
	_nail.albedo_color = Color(0.96, 0.80, 0.74, 1.0)
	_nail.roughness = 0.52

	var wrist := MeshInstance3D.new()
	wrist.name = "Wrist"
	var wrist_mesh := CapsuleMesh.new()
	wrist_mesh.radius = 0.115
	wrist_mesh.height = 0.30
	wrist.mesh = wrist_mesh
	wrist.material_override = _skin
	wrist.position = Vector3(0.0, 0.17, -0.025)
	wrist.rotation_degrees = Vector3(0.0, 0.0, 90.0)
	wrist.scale = Vector3(1.0, 1.0, 0.82)
	add_child(wrist)

	var palm := MeshInstance3D.new()
	palm.name = "Palm"
	var palm_mesh := SphereMesh.new()
	palm_mesh.radius = 0.20
	palm_mesh.height = 0.40
	palm.mesh = palm_mesh
	palm.material_override = _skin
	palm.position = Vector3(0.0, -0.005, 0.0)
	palm.scale = Vector3(1.08, 1.32, 0.52)
	add_child(palm)

	var thenar := MeshInstance3D.new()
	thenar.name = "Thenar"
	var thenar_mesh := SphereMesh.new()
	thenar_mesh.radius = 0.105
	thenar_mesh.height = 0.21
	thenar.mesh = thenar_mesh
	thenar.material_override = _skin
	thenar.position = _mirror(Vector3(-0.145, -0.07, 0.035))
	thenar.scale = Vector3(1.0, 1.25, 0.62)
	add_child(thenar)

	for finger_name in FINGER_NAMES:
		var segments: Array[MeshInstance3D] = []
		for segment_index in range(3):
			var segment := MeshInstance3D.new()
			segment.name = "%sSegment%d" % [finger_name, segment_index]
			segment.material_override = _skin
			add_child(segment)
			segments.append(segment)
		_finger_segments[finger_name] = segments

		var tip := MeshInstance3D.new()
		tip.name = "%sTipShape" % finger_name
		var tip_mesh := SphereMesh.new()
		tip_mesh.radius = _finger_radius(finger_name) * 1.03
		tip_mesh.height = _finger_radius(finger_name) * 2.06
		tip.mesh = tip_mesh
		tip.material_override = _skin
		add_child(tip)
		_finger_tips[finger_name] = tip

		if finger_name in ["Thumb", "Index"]:
			var nail := MeshInstance3D.new()
			nail.name = "%sNail" % finger_name
			var nail_mesh := SphereMesh.new()
			nail_mesh.radius = _finger_radius(finger_name) * 0.70
			nail_mesh.height = _finger_radius(finger_name) * 1.40
			nail.mesh = nail_mesh
			nail.material_override = _nail
			nail.scale = Vector3(0.82, 0.70, 0.22)
			add_child(nail)
			_nails[finger_name] = nail

func _apply_procedural_pose() -> void:
	for finger_name in FINGER_NAMES:
		var joints := _pose_points(finger_name)
		var segments: Array = _finger_segments.get(finger_name, [])
		for i in range(mini(3, segments.size())):
			_place_capsule(segments[i] as MeshInstance3D, joints[i], joints[i + 1], _finger_radius(finger_name))
		var tip := _finger_tips.get(finger_name) as MeshInstance3D
		if tip != null:
			tip.position = joints[3]
			var tip_scale := 1.0 if finger_name in ["Thumb", "Index"] else 0.96
			tip.scale = Vector3(tip_scale, 1.10, 0.90)
		if _nails.has(finger_name):
			var nail := _nails[finger_name] as MeshInstance3D
			var previous := joints[2]
			var end := joints[3]
			var direction := (end - previous).normalized()
			nail.position = end + Vector3(0.0, 0.0, 1.0) * _finger_radius(finger_name) * 0.72 - direction * _finger_radius(finger_name) * 0.30
	_refresh_procedural_anchors()

func _refresh_procedural_anchors() -> void:
	_thumb_tip.position = _pose_points("Thumb")[3]
	_index_tip.position = _pose_points("Index")[3]
	_pinch_point.position = (_thumb_tip.position + _index_tip.position) * 0.5

func _pose_points(finger_name: String) -> Array[Vector3]:
	var relaxed: Array[Vector3]
	var pinched: Array[Vector3]
	match finger_name:
		"Thumb":
			relaxed = [Vector3(-0.185, -0.02, 0.015), Vector3(-0.255, -0.125, 0.025), Vector3(-0.215, -0.245, 0.055), Vector3(-0.135, -0.335, 0.080)]
			pinched = [Vector3(-0.185, -0.02, 0.015), Vector3(-0.190, -0.150, 0.055), Vector3(-0.125, -0.265, 0.115), Vector3(-0.052, -0.345, 0.145)]
		"Index":
			relaxed = [Vector3(-0.090, -0.105, 0.005), Vector3(-0.085, -0.265, 0.015), Vector3(-0.085, -0.405, 0.045), Vector3(-0.095, -0.525, 0.060)]
			pinched = [Vector3(-0.090, -0.105, 0.005), Vector3(-0.090, -0.235, 0.050), Vector3(-0.080, -0.305, 0.115), Vector3(-0.058, -0.350, 0.155)]
		"Middle":
			relaxed = [Vector3(0.005, -0.100, 0.000), Vector3(0.020, -0.270, -0.010), Vector3(0.040, -0.395, 0.035), Vector3(0.070, -0.480, 0.095)]
			pinched = relaxed
		"Ring":
			relaxed = [Vector3(0.095, -0.090, -0.005), Vector3(0.120, -0.245, -0.005), Vector3(0.150, -0.350, 0.045), Vector3(0.175, -0.420, 0.110)]
			pinched = relaxed
		_:
			relaxed = [Vector3(0.175, -0.070, -0.010), Vector3(0.205, -0.205, 0.000), Vector3(0.235, -0.290, 0.050), Vector3(0.250, -0.345, 0.110)]
			pinched = relaxed

	var points: Array[Vector3] = []
	for i in range(4):
		points.append(_mirror(relaxed[i].lerp(pinched[i], _pinch_amount)))
	return points

func _place_capsule(instance: MeshInstance3D, a: Vector3, b: Vector3, radius: float) -> void:
	var delta := b - a
	var length := maxf(delta.length(), radius * 2.05)
	var y_axis := delta.normalized()
	if y_axis.length_squared() <= 0.000001:
		y_axis = Vector3.DOWN
	var helper := Vector3.FORWARD
	if absf(y_axis.dot(helper)) > 0.96:
		helper = Vector3.RIGHT
	var x_axis := helper.cross(y_axis).normalized()
	var z_axis := x_axis.cross(y_axis).normalized()
	var capsule := CapsuleMesh.new()
	capsule.radius = radius
	capsule.height = length
	instance.mesh = capsule
	instance.transform = Transform3D(Basis(x_axis, y_axis, z_axis), (a + b) * 0.5)

func _finger_radius(finger_name: String) -> float:
	match finger_name:
		"Thumb":
			return 0.052
		"Index":
			return 0.044
		"Middle":
			return 0.046
		"Ring":
			return 0.043
		_:
			return 0.038

func _mirror(point: Vector3) -> Vector3:
	return Vector3(point.x * _mirror_sign, point.y, point.z)