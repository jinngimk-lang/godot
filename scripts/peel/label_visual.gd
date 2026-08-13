extends MeshInstance3D
class_name LabelVisual

@export var label_width := 1.25
@export var label_height := 0.42
@export var label_y := 0.72
@export var cup_radius := 0.53
@export var segments := 28

var _mesh := ImmediateMesh.new()
var _material := StandardMaterial3D.new()

func _ready() -> void:
	mesh = _mesh
	_material.albedo_color = Color(0.94, 0.925, 0.86, 1.0)
	_material.roughness = 0.88
	_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	set_peel(0.0, get_front_position(0.0))

func get_front_position(progress: float) -> Vector3:
	var p := clampf(progress, 0.0, 1.0)
	return Vector3(lerpf(-label_width * 0.5, label_width * 0.5, p), label_y, cup_radius + 0.018)

func set_peel(progress: float, grip_local: Vector3) -> void:
	var p := clampf(progress, 0.0, 1.0)
	_mesh.clear_surfaces()
	_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP, _material)
	for i in range(segments + 1):
		var u := float(i) / float(segments)
		var center := _point_for(u, p, grip_local)
		var vertical := Vector3(0.0, label_height * 0.5, 0.0)
		_mesh.surface_set_normal(Vector3(0, 0, 1))
		_mesh.surface_set_uv(Vector2(u, 0.0))
		_mesh.surface_add_vertex(center + vertical)
		_mesh.surface_set_normal(Vector3(0, 0, 1))
		_mesh.surface_set_uv(Vector2(u, 1.0))
		_mesh.surface_add_vertex(center - vertical)
	_mesh.surface_end()

func _point_for(u: float, progress: float, grip: Vector3) -> Vector3:
	var attached := Vector3(lerpf(-label_width * 0.5, label_width * 0.5, u), label_y, cup_radius + 0.018)
	if progress <= 0.0001 or u > progress:
		return attached
	var front := get_front_position(progress)
	var t := clampf(u / progress, 0.0, 1.0)
	var arc := sin(t * PI)
	var curl := sin(t * PI * 2.0) * (1.0 - t)
	return grip.lerp(front, t) + Vector3(0.0, arc * 0.11 + curl * 0.035, arc * 0.16)
