extends Node3D
class_name HandVisual

var follow_rate := 11.0
var pinch_follow_rate := 16.0

var _target := Vector3.ZERO
var _dynamic := false
var _mirror_sign := 1.0
var _pinch_target := 0.0
var _pinch_amount := 0.0
var _built := false

var _skin: StandardMaterial3D
var _nail: StandardMaterial3D
var _finger_segments: Dictionary = {}
var _finger_tips: Dictionary = {}
var _nails: Dictionary = {}
var _thumb_tip: Node3D
var _index_tip: Node3D
var _pinch_point: Node3D

const FINGER_NAMES := ["Thumb", "Index", "Middle", "Ring", "Little"]

func setup(dynamic_hand: bool) -> void:
	_dynamic = dynamic_hand
	_mirror_sign = 1.0 if dynamic_hand else -1.0
	if not _built:
		_build_hand()
	_pinch_target = 0.18 if dynamic_hand else 0.42
	_pinch_amount = _pinch_target
	_apply_pose()

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
	if _pinch_point != null:
		_target = to_global(_pinch_point.position)
	else:
		_target = target

func tick(delta: float) -> void:
	var safe_delta := clampf(delta if is_finite(delta) else 0.0, 0.0, 0.1)
	var pinch_weight := 1.0 - exp(-pinch_follow_rate * safe_delta)
	_pinch_amount = lerpf(_pinch_amount, _pinch_target, pinch_weight)
	_apply_pose()
	if _dynamic:
		var desired_root := _target
		if _pinch_point != null:
			desired_root = _target - basis * _pinch_point.position
		var weight := 1.0 - exp(-follow_rate * safe_delta)
		position = position.lerp(desired_root, weight)

func _build_hand() -> void:
	_built = true
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

	_thumb_tip = Node3D.new()
	_thumb_tip.name = "ThumbTip"
	add_child(_thumb_tip)
	_index_tip = Node3D.new()
	_index_tip.name = "IndexTip"
	add_child(_index_tip)
	_pinch_point = Node3D.new()
	_pinch_point.name = "PinchPoint"
	add_child(_pinch_point)

func _apply_pose() -> void:
	if not _built:
		return
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

	_thumb_tip.position = _pose_points("Thumb")[3]
	_index_tip.position = _pose_points("Index")[3]
	_pinch_point.position = (_thumb_tip.position + _index_tip.position) * 0.5

func _pose_points(finger_name: String) -> Array[Vector3]:
	var relaxed: Array[Vector3]
	var pinched: Array[Vector3]
	match finger_name:
		"Thumb":
			relaxed = [
				Vector3(-0.185, -0.02, 0.015),
				Vector3(-0.255, -0.125, 0.025),
				Vector3(-0.215, -0.245, 0.055),
				Vector3(-0.135, -0.335, 0.080)
			]
			pinched = [
				Vector3(-0.185, -0.02, 0.015),
				Vector3(-0.190, -0.150, 0.055),
				Vector3(-0.125, -0.265, 0.115),
				Vector3(-0.052, -0.345, 0.145)
			]
		"Index":
			relaxed = [
				Vector3(-0.090, -0.105, 0.005),
				Vector3(-0.085, -0.265, 0.015),
				Vector3(-0.085, -0.405, 0.045),
				Vector3(-0.095, -0.525, 0.060)
			]
			pinched = [
				Vector3(-0.090, -0.105, 0.005),
				Vector3(-0.090, -0.235, 0.050),
				Vector3(-0.080, -0.305, 0.115),
				Vector3(-0.058, -0.350, 0.155)
			]
		"Middle":
			relaxed = [
				Vector3(0.005, -0.100, 0.000),
				Vector3(0.020, -0.270, -0.010),
				Vector3(0.040, -0.395, 0.035),
				Vector3(0.070, -0.480, 0.095)
			]
			pinched = relaxed
		"Ring":
			relaxed = [
				Vector3(0.095, -0.090, -0.005),
				Vector3(0.120, -0.245, -0.005),
				Vector3(0.150, -0.350, 0.045),
				Vector3(0.175, -0.420, 0.110)
			]
			pinched = relaxed
		_:
			relaxed = [
				Vector3(0.175, -0.070, -0.010),
				Vector3(0.205, -0.205, 0.000),
				Vector3(0.235, -0.290, 0.050),
				Vector3(0.250, -0.345, 0.110)
			]
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
