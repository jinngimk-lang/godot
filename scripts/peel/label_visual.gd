extends MeshInstance3D
class_name LabelVisual

@export var label_width := 1.25
@export var label_height := 0.42
@export var label_y := 0.72
@export var cup_radius := 0.53
@export var segments := 28
@export var surface_offset := 0.018

var _mesh := ImmediateMesh.new()
var _material := StandardMaterial3D.new()
var _phase_name := "ATTACHED"
var _detach_alpha := 0.0
var _held_direction := Vector3.LEFT
var _last_grip := Vector3.ZERO
var _last_progress := 0.0

func _ready() -> void:
	mesh = _mesh
	_material.albedo_color = Color(0.97, 0.955, 0.90, 1.0)
	_material.roughness = 0.9
	_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	set_peel(0.0, get_front_position(0.0))

func get_front_position(progress: float) -> Vector3:
	return CupSurface.attached_point(
		clampf(progress, 0.0, 1.0),
		label_width,
		cup_radius,
		label_y,
		surface_offset
	)

func set_phase(phase_name: String) -> void:
	if phase_name == _phase_name:
		return
	if phase_name in ["DETACHING", "HELD"] and not (_phase_name in ["DETACHING", "HELD"]):
		var front := get_front_position(1.0)
		var direction := front - _last_grip
		if direction.length_squared() > 0.000001:
			_held_direction = direction.normalized()
		else:
			_held_direction = Vector3.LEFT
	_phase_name = phase_name
	if _phase_name == "ATTACHED":
		_detach_alpha = 0.0
	elif _phase_name == "HELD":
		_detach_alpha = 1.0

func set_detach_alpha(alpha: float) -> void:
	_detach_alpha = clampf(alpha if is_finite(alpha) else 0.0, 0.0, 1.0)

func is_detached() -> bool:
	return _phase_name == "HELD"

func set_print_texture(texture: Texture2D) -> void:
	_material.albedo_texture = texture

func get_effective_grip(progress: float, desired_grip: Vector3) -> Vector3:
	if _phase_name == "HELD":
		return desired_grip
	return LabelGeometry.resolve_grip(
		progress,
		desired_grip,
		label_width,
		cup_radius,
		label_y,
		surface_offset
	)

func get_sample_points(progress: float, desired_grip: Vector3) -> PackedVector3Array:
	var p := clampf(progress, 0.0, 1.0)
	if _phase_name == "HELD":
		return LabelGeometry.held_points(desired_grip, _held_direction, label_width, segments)
	if _phase_name == "DETACHING":
		var peeling := LabelGeometry.peeling_points(
			1.0,
			desired_grip,
			label_width,
			cup_radius,
			label_y,
			surface_offset,
			segments
		)
		var held := LabelGeometry.held_points(desired_grip, _held_direction, label_width, segments)
		var blended := PackedVector3Array()
		for i in range(mini(peeling.size(), held.size())):
			blended.append(peeling[i].lerp(held[i], _detach_alpha))
		return blended
	return LabelGeometry.peeling_points(
		p,
		desired_grip,
		label_width,
		cup_radius,
		label_y,
		surface_offset,
		segments
	)

func set_peel(progress: float, grip_local: Vector3) -> void:
	_last_progress = clampf(progress, 0.0, 1.0)
	_last_grip = grip_local
	var points := get_sample_points(_last_progress, grip_local)
	if points.size() < 2:
		return

	_mesh.clear_surfaces()
	_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP, _material)
	var vertical := Vector3(0.0, label_height * 0.5, 0.0)
	for i in range(points.size()):
		var center := points[i]
		var normal := _normal_from_points(points, i)
		var u := float(i) / float(points.size() - 1)
		_mesh.surface_set_normal(normal)
		_mesh.surface_set_uv(Vector2(u, 0.0))
		_mesh.surface_add_vertex(center + vertical)
		_mesh.surface_set_normal(normal)
		_mesh.surface_set_uv(Vector2(u, 1.0))
		_mesh.surface_add_vertex(center - vertical)
	_mesh.surface_end()

func _normal_from_points(points: PackedVector3Array, index: int) -> Vector3:
	var left_index := maxi(index - 1, 0)
	var right_index := mini(index + 1, points.size() - 1)
	var tangent := points[right_index] - points[left_index]
	if tangent.length_squared() <= 0.000001:
		return Vector3.FORWARD
	var normal := tangent.normalized().cross(Vector3.UP).normalized()
	if normal.length_squared() <= 0.000001:
		return Vector3.FORWARD
	return normal
