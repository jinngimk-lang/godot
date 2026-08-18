extends Node3D
class_name HandVisual

const RIGHT_ASSET_PATH := "res://assets/models/hands/hand_right.glb"
const LEFT_ASSET_PATH := "res://assets/models/hands/hand_left.glb"
const FINGER_NAMES := ["Thumb", "Index", "Middle", "Ring", "Little"]
const AUTHORED_PRESENTATION_SCALE := 2.25
const REALTIME_SPHERE_SEGMENTS := 28
const REALTIME_SPHERE_RINGS := 14
const REALTIME_CYLINDER_SIDES := 28

var follow_rate := 11.0
var pinch_follow_rate := 16.0

var _target := Vector3.ZERO
var _dynamic := false
var _mirror_sign := 1.0
var _pinch_target := 0.0
var _pinch_amount := 0.0
var _built := false
var _using_authored_asset := false
var _using_realtime_shell := false
var _last_authored_pose := ""
var _realtime_shell_vertex_budget := 0

var _authored_root: Node3D
var _animation_player: AnimationPlayer
var _skeleton: Skeleton3D
var _realtime_shell: CSGCombiner3D

var _skin: StandardMaterial3D
var _nail: StandardMaterial3D
var _sleeve_fabric: StandardMaterial3D
var _sleeve_rib: StandardMaterial3D
var _thumb_tip: Node3D
var _index_tip: Node3D
var _pinch_point: Node3D

func setup(dynamic_hand: bool) -> void:
	_dynamic = dynamic_hand
	_mirror_sign = 1.0 if dynamic_hand else -1.0
	_ensure_anchors()
	if not _built:
		_using_authored_asset = _try_build_authored_hand()
		_build_realtime_hand_shell()
		if not _using_realtime_shell and not _using_authored_asset:
			_build_fallback_hand()
		_built = true
	_pinch_target = 0.18 if dynamic_hand else 0.42
	_pinch_amount = _pinch_target
	_apply_pose()
	_refresh_pinch_anchors()

func is_using_authored_asset() -> bool:
	return _using_authored_asset

func is_using_realtime_shell() -> bool:
	return _using_realtime_shell and _realtime_shell != null

func get_realtime_shell_vertex_count() -> int:
	# CSG computes its final union asynchronously once it enters the tree. This
	# deterministic budget is the explicit tessellation budget of the primitives
	# feeding that union, and lets headless tests reject a return to coarse hands.
	return _realtime_shell_vertex_budget

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

func snap_to(target: Vector3) -> void:
	position = target
	_refresh_pinch_anchors()
	_target = to_global(_pinch_point.position) if _pinch_point != null else target

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
	_authored_root.position = Vector3.ZERO
	_authored_root.rotation = Vector3.ZERO
	_authored_root.scale = Vector3.ONE * AUTHORED_PRESENTATION_SCALE
	_build_authored_wrist_cover()
	_apply_authored_pose(required_pose)
	return true

func _build_authored_wrist_cover() -> void:
	if _authored_root == null:
		return
	_sleeve_fabric = StandardMaterial3D.new()
	_sleeve_fabric.resource_name = "SleeveFabric"
	_sleeve_fabric.albedo_color = Color(0.18, 0.13, 0.11, 1.0)
	_sleeve_fabric.roughness = 0.98
	_sleeve_rib = StandardMaterial3D.new()
	_sleeve_rib.resource_name = "SleeveRib"
	_sleeve_rib.albedo_color = Color(0.32, 0.25, 0.21, 1.0)
	_sleeve_rib.roughness = 0.97
	var sleeve_length := 0.34
	var sleeve := MeshInstance3D.new()
	sleeve.name = "WristSleeve"
	var sleeve_mesh := CylinderMesh.new()
	sleeve_mesh.bottom_radius = 0.034
	sleeve_mesh.top_radius = 0.048
	sleeve_mesh.height = sleeve_length
	sleeve_mesh.radial_segments = 28
	sleeve.mesh = sleeve_mesh
	sleeve.material_override = _sleeve_fabric
	sleeve.position = Vector3(0.0, 0.0, 0.020 + sleeve_length * 0.5)
	sleeve.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	sleeve.scale = Vector3(0.82, 1.0, 0.68)
	_authored_root.add_child(sleeve)
	var cuff := MeshInstance3D.new()
	cuff.name = "WristCuff"
	var cuff_mesh := CylinderMesh.new()
	cuff_mesh.top_radius = 0.037
	cuff_mesh.bottom_radius = 0.037
	cuff_mesh.height = 0.012
	cuff_mesh.radial_segments = 28
	cuff.mesh = cuff_mesh
	cuff.material_override = _sleeve_rib
	cuff.position = Vector3(0.0, 0.0, 0.028)
	cuff.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	cuff.scale = Vector3(0.86, 1.0, 0.72)
	_authored_root.add_child(cuff)

func _build_realtime_hand_shell() -> void:
	_skin = StandardMaterial3D.new()
	_skin.resource_name = "RealtimeHandSkin"
	_skin.albedo_color = Color(0.72, 0.50, 0.38, 1.0)
	_skin.roughness = 0.54
	_skin.metallic = 0.0
	_skin.metallic_specular = 0.34
	_nail = StandardMaterial3D.new()
	_nail.resource_name = "RealtimeHandNail"
	_nail.albedo_color = Color(0.86, 0.66, 0.58, 1.0)
	_nail.roughness = 0.40
	_nail.metallic_specular = 0.40

	_realtime_shell = CSGCombiner3D.new()
	_realtime_shell.name = "RealtimeHandShell"
	_realtime_shell.autosmooth = true
	_realtime_shell.smoothing_angle = deg_to_rad(72.0)
	add_child(_realtime_shell)
	_realtime_shell_vertex_budget = 0

	# One continuous CSG skin replaces the visibly faceted XR render mesh. The
	# XR skeleton stays hidden underneath as interaction/pose authority only.
	_add_ellipsoid(_realtime_shell, Vector3(0.0,-0.092,0.0), Vector3(0.090,0.112,0.041), "Palm")
	_add_ellipsoid(_realtime_shell, _mirror(Vector3(0.048,-0.105,-0.004)), Vector3(0.052,0.072,0.042), "Thenar")
	_add_ellipsoid(_realtime_shell, _mirror(Vector3(-0.050,-0.108,0.003)), Vector3(0.044,0.070,0.038), "Hypothenar")
	_add_capsule(_realtime_shell, Vector3(0.0,0.058,0.004), Vector3(0.0,-0.045,0.0), 0.043, "Wrist")

	var pose := _support_pose_points() if not _dynamic else _pinch_pose_points()
	for finger_name in ["Index", "Middle", "Ring", "Little", "Thumb"]:
		var points: Array = pose[finger_name]
		var radius := _realtime_finger_radius(finger_name)
		for index in range(points.size()-1):
			var taper := lerpf(1.08,0.82,float(index)/maxf(float(points.size()-2),1.0))
			_add_capsule(_realtime_shell, points[index], points[index+1], radius*taper, "%s%d" % [finger_name,index])

	_build_nail("Index", pose["Index"][pose["Index"].size()-1], pose["Index"][pose["Index"].size()-2], _realtime_finger_radius("Index"))
	_build_nail("Thumb", pose["Thumb"][pose["Thumb"].size()-1], pose["Thumb"][pose["Thumb"].size()-2], _realtime_finger_radius("Thumb"))
	_using_realtime_shell = true
	_set_render_mesh_visibility(_authored_root,false)

func _add_ellipsoid(parent: Node, center: Vector3, extents: Vector3, node_name: String) -> void:
	var sphere := CSGSphere3D.new()
	sphere.name = node_name
	sphere.radius = 1.0
	sphere.radial_segments = REALTIME_SPHERE_SEGMENTS
	sphere.rings = REALTIME_SPHERE_RINGS
	sphere.smooth_faces = true
	sphere.material = _skin
	sphere.position = center
	sphere.scale = extents
	parent.add_child(sphere)
	_realtime_shell_vertex_budget += REALTIME_SPHERE_SEGMENTS * REALTIME_SPHERE_RINGS * 6

func _add_capsule(parent: Node, a: Vector3, b: Vector3, radius: float, node_name: String) -> void:
	var delta := b-a
	var length := maxf(delta.length(),radius*2.05)
	var y_axis := delta.normalized()
	if y_axis.length_squared() <= 0.000001:
		y_axis = Vector3.DOWN
	var helper := Vector3.FORWARD
	if absf(y_axis.dot(helper)) > 0.95:
		helper = Vector3.RIGHT
	var x_axis := helper.cross(y_axis).normalized()
	var z_axis := y_axis.cross(x_axis).normalized()
	var cylinder := CSGCylinder3D.new()
	cylinder.name = "%sCore" % node_name
	cylinder.radius = radius
	cylinder.height = length
	cylinder.sides = REALTIME_CYLINDER_SIDES
	cylinder.smooth_faces = true
	cylinder.material = _skin
	cylinder.transform = Transform3D(Basis(x_axis,y_axis,z_axis),(a+b)*0.5)
	parent.add_child(cylinder)
	_realtime_shell_vertex_budget += REALTIME_CYLINDER_SIDES * 12
	_add_ellipsoid(parent,a,Vector3.ONE*radius,"%sA" % node_name)
	_add_ellipsoid(parent,b,Vector3.ONE*radius*0.94,"%sB" % node_name)

func _build_nail(node_name: String, tip: Vector3, previous: Vector3, radius: float) -> void:
	var nail := MeshInstance3D.new()
	nail.name = "%sNail" % node_name
	var mesh := SphereMesh.new()
	mesh.radius = radius*0.72
	mesh.height = radius*1.44
	mesh.radial_segments = 24
	mesh.rings = 12
	nail.mesh = mesh
	nail.material_override = _nail
	var direction := (tip-previous).normalized()
	nail.position = tip + Vector3(0.0,0.0,-radius*0.55) - direction*radius*0.12
	nail.scale = Vector3(0.72,0.90,0.18)
	add_child(nail)

func _pinch_pose_points() -> Dictionary:
	return {
		"Index":[Vector3(0.046,-0.174,0.000),Vector3(0.050,-0.230,-0.028),Vector3(0.047,-0.260,-0.076),Vector3(0.048,-0.244,-0.108)],
		"Middle":[Vector3(0.012,-0.180,0.006),Vector3(0.014,-0.238,-0.010),Vector3(0.010,-0.266,-0.052),Vector3(0.002,-0.236,-0.090)],
		"Ring":[Vector3(-0.022,-0.176,0.010),Vector3(-0.026,-0.232,-0.004),Vector3(-0.032,-0.252,-0.044),Vector3(-0.036,-0.222,-0.078)],
		"Little":[Vector3(-0.055,-0.164,0.012),Vector3(-0.061,-0.212,-0.004),Vector3(-0.069,-0.230,-0.038),Vector3(-0.073,-0.206,-0.066)],
		"Thumb":[Vector3(0.070,-0.080,-0.004),Vector3(0.111,-0.130,-0.028),Vector3(0.102,-0.181,-0.070),Vector3(0.062,-0.224,-0.108)]
	}

func _support_pose_points() -> Dictionary:
	var source := {
		"Index":[Vector3(0.046,-0.174,0.002),Vector3(0.052,-0.234,-0.008),Vector3(0.050,-0.284,-0.034),Vector3(0.043,-0.303,-0.074)],
		"Middle":[Vector3(0.012,-0.180,0.007),Vector3(0.014,-0.246,-0.004),Vector3(0.010,-0.298,-0.032),Vector3(0.002,-0.314,-0.073)],
		"Ring":[Vector3(-0.022,-0.176,0.010),Vector3(-0.026,-0.238,-0.002),Vector3(-0.032,-0.288,-0.028),Vector3(-0.040,-0.302,-0.066)],
		"Little":[Vector3(-0.055,-0.164,0.012),Vector3(-0.061,-0.218,-0.002),Vector3(-0.070,-0.259,-0.026),Vector3(-0.078,-0.270,-0.058)],
		"Thumb":[Vector3(0.070,-0.080,-0.004),Vector3(0.116,-0.130,-0.010),Vector3(0.124,-0.176,-0.036),Vector3(0.110,-0.206,-0.070)]
	}
	var mirrored := {}
	for key in source.keys():
		var points: Array[Vector3] = []
		for point in source[key]:
			points.append(_mirror(point))
		mirrored[key] = points
	return mirrored

func _realtime_finger_radius(finger_name: String) -> float:
	match finger_name:
		"Thumb": return 0.024
		"Index": return 0.020
		"Middle": return 0.0215
		"Ring": return 0.0205
		_: return 0.0175

func _apply_pose() -> void:
	if _using_authored_asset:
		var pose_name := "Cup" if not _dynamic else ("Pinch Tight" if _pinch_amount >= 0.42 else "Pinch Up")
		if _animation_player != null and not _animation_player.has_animation(pose_name):
			pose_name = "Pinch Up" if _dynamic else "Default pose"
		_apply_authored_pose(pose_name)

func _apply_authored_pose(pose_name: String) -> void:
	if _animation_player == null or not _animation_player.has_animation(pose_name):
		return
	if _last_authored_pose == pose_name:
		return
	_animation_player.play(pose_name)
	_animation_player.seek(0.0,true)
	_animation_player.pause()
	_last_authored_pose = pose_name

func _refresh_pinch_anchors() -> void:
	if _using_realtime_shell:
		_refresh_realtime_anchors()
	elif _using_authored_asset:
		_refresh_authored_anchors()

func _refresh_realtime_anchors() -> void:
	if _dynamic:
		_index_tip.position = Vector3(0.048,-0.244,-0.108)
		_thumb_tip.position = Vector3(0.062,-0.224,-0.108)
	else:
		_index_tip.position = Vector3(-0.043,-0.303,-0.074)
		_thumb_tip.position = Vector3(-0.110,-0.206,-0.070)
	_pinch_point.position = (_index_tip.position+_thumb_tip.position)*0.5

func _refresh_authored_anchors() -> void:
	if _skeleton == null:
		return
	var suffix := "R" if _dynamic else "L"
	var thumb_local = _estimate_bone_tip("Thumb_Proximal_%s" % suffix,"Thumb_Distal_%s" % suffix,0.020)
	var index_local = _estimate_bone_tip("Index_Intermediate_%s" % suffix,"Index_Distal_%s" % suffix,0.020)
	if thumb_local != null:
		_thumb_tip.position = thumb_local as Vector3
	if index_local != null:
		_index_tip.position = index_local as Vector3
	if thumb_local != null and index_local != null:
		_pinch_point.position = ((thumb_local as Vector3)+(index_local as Vector3))*0.5

func _estimate_bone_tip(previous_name: String, distal_name: String, extension: float):
	if _skeleton == null:
		return null
	var previous_id := _skeleton.find_bone(previous_name)
	var distal_id := _skeleton.find_bone(distal_name)
	if previous_id < 0 or distal_id < 0:
		return null
	var previous_pose := _skeleton.get_bone_global_pose(previous_id)
	var distal_pose := _skeleton.get_bone_global_pose(distal_id)
	var direction := distal_pose.origin-previous_pose.origin
	if direction.length_squared() <= 0.000001:
		return null
	return _descendant_point_to_local(_skeleton,distal_pose.origin+direction.normalized()*extension)

func _descendant_point_to_local(descendant: Node3D, point: Vector3):
	var current := descendant
	var converted := point
	while current != self:
		if current.is_set_as_top_level():
			return null
		converted = current.transform*converted
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

func _set_render_mesh_visibility(node: Node, visible: bool) -> void:
	if node == null:
		return
	if node is MeshInstance3D:
		(node as MeshInstance3D).visible = visible
	for child in node.get_children():
		_set_render_mesh_visibility(child,visible)

func _build_fallback_hand() -> void:
	var fallback := MeshInstance3D.new()
	fallback.name = "FallbackPalm"
	var mesh := SphereMesh.new()
	mesh.radius = 0.10
	mesh.height = 0.22
	mesh.radial_segments = 28
	mesh.rings = 14
	fallback.mesh = mesh
	fallback.material_override = _skin
	fallback.scale = Vector3(0.90,1.15,0.42)
	fallback.position = Vector3(0.0,-0.09,0.0)
	add_child(fallback)

func _mirror(point: Vector3) -> Vector3:
	return Vector3(point.x*_mirror_sign,point.y,point.z)
