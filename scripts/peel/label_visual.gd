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

func _ready() -> void:
	mesh = _mesh
	_material.albedo_color = Color(0.94, 0.925, 0.86, 1.0)
	_material.roughness = 0.88
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

func set_peel(progress: float, grip_local: Vector3) -> void:
	var p := clampf(progress, 0.0, 1.0)
	_mesh.clear_surfaces()
	_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP, _material)
	for i in range(segments + 1):
		var u := float(i) / float(segments)
		var center := _point_for(u, p, grip_local)
		var vertical := Vector3(0.0, label_height * 0.5, 0.0)
		var normal := _normal_for(u, p, center)
		_mesh.surface_set_normal(normal)
		_mesh.surface_set_uv(Vector2(u, 0.0))
		_mesh.surface_add_vertex(center + vertical)
		_mesh.surface_set_normal(normal)
		_mesh.surface_set_uv(Vector2(u, 1.0))
		_mesh.surface_add_vertex(center - vertical)
	_mesh.surface_end()

func _point_for(u: float, progress: float, grip: Vector3) -> Vector3:
	var attached := CupSurface.attached_point(u, label_width, cup_radius, label_y, surface_offset)
	if progress <= 0.0001 or u > progress:
		return attached
	var front := get_front_position(progress)
	var t := clampf(u / progress, 0.0, 1.0)
	var arc := sin(t * PI)
	var curl := sin(t * PI * 2.0) * (1.0 - t)
	return grip.lerp(front, t) + Vector3(0.0, arc * 0.11 + curl * 0.035, arc * 0.16)

func _normal_for(u: float, progress: float, center: Vector3) -> Vector3:
	if progress <= 0.0001 or u > progress:
		return CupSurface.attached_normal(u, label_width, cup_radius, surface_offset)
	var radial := Vector3(center.x, 0.0, center.z)
	if radial.length_squared() <= 0.000001:
		return Vector3(0, 0, 1)
	return radial.normalized()
