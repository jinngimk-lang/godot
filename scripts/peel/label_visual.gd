extends MeshInstance3D
class_name LabelVisual

@export var label_width := 1.25
@export var label_height := 0.42
@export var label_y := 0.72
@export var cup_radius := 0.53
@export var segments := 28
@export var surface_offset := 0.022

var _mesh := ImmediateMesh.new()
var _material := StandardMaterial3D.new()
var _phase_name := "ATTACHED"
var _detach_alpha := 0.0
var _held_direction := Vector3.LEFT
var _last_grip := Vector3.ZERO
var _last_progress := 0.0
var _uses_frustum_profile := false
var _cup_bottom_radius := 0.0
var _cup_top_radius := 0.0
var _cup_height := 0.0
var _cup_center_y := 0.0

func _ready() -> void:
	mesh = _mesh
	_material.albedo_color = Color(0.97,0.955,0.90,1.0)
	_material.roughness = 0.90
	_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	_sync_from_runtime_cup()
	set_peel(0.0,get_front_position(0.0))

func configure_cup_frustum(bottom_radius: float, top_radius: float, cup_height: float, cup_center_y: float) -> void:
	_cup_bottom_radius = maxf(bottom_radius,0.001)
	_cup_top_radius = maxf(top_radius,0.001)
	_cup_height = maxf(absf(cup_height),0.001)
	_cup_center_y = cup_center_y
	_uses_frustum_profile = true
	cup_radius = CupSurface.frustum_radius_at_y(label_y,_cup_bottom_radius,_cup_top_radius,_cup_height,_cup_center_y)
	if is_inside_tree() and mesh != null:
		var grip := _last_grip
		if grip.length_squared() <= 0.000001:
			grip = get_front_position(_last_progress)
		set_peel(_last_progress,grip)

func get_center_cup_radius() -> float:
	_sync_from_runtime_cup()
	if not _uses_frustum_profile:
		return cup_radius
	return CupSurface.frustum_radius_at_y(label_y,_cup_bottom_radius,_cup_top_radius,_cup_height,_cup_center_y)

func get_front_position(progress: float) -> Vector3:
	return CupSurface.attached_point(clampf(progress,0.0,1.0),label_width,get_center_cup_radius(),label_y,surface_offset)

func set_phase(phase_name: String) -> void:
	if phase_name == _phase_name:
		# ATTACHED is also the lifecycle reset command. A prior presentation stage
		# may have hidden the label, so idempotent resets must restore visibility.
		if phase_name == "ATTACHED":
			visible = true
		return
	if phase_name in ["DETACHING","HELD"] and not (_phase_name in ["DETACHING","HELD"]):
		var front := get_front_position(1.0)
		var direction := front-_last_grip
		_held_direction = direction.normalized() if direction.length_squared()>0.000001 else Vector3.LEFT
	_phase_name = phase_name
	if _phase_name == "ATTACHED":
		visible = true
		_detach_alpha = 0.0
	elif _phase_name == "HELD":
		_detach_alpha = 1.0

func set_detach_alpha(alpha: float) -> void:
	_detach_alpha = clampf(alpha if is_finite(alpha) else 0.0,0.0,1.0)

func is_detached() -> bool:
	return _phase_name == "HELD"

func set_print_texture(texture: Texture2D) -> void:
	_material.albedo_texture = texture

func get_effective_grip(progress: float, desired_grip: Vector3) -> Vector3:
	if _phase_name == "HELD":
		return desired_grip
	return LabelGeometry.resolve_grip(progress,desired_grip,label_width,get_center_cup_radius(),label_y,surface_offset)

func get_sample_points(progress: float, desired_grip: Vector3) -> PackedVector3Array:
	var p := clampf(progress,0.0,1.0)
	var center_radius := get_center_cup_radius()
	if _phase_name == "HELD":
		return LabelGeometry.held_points(desired_grip,_held_direction,label_width,segments)
	if _phase_name == "DETACHING":
		var peeling := LabelGeometry.peeling_points(1.0,desired_grip,label_width,center_radius,label_y,surface_offset,segments)
		var held := LabelGeometry.held_points(desired_grip,_held_direction,label_width,segments)
		var blended := PackedVector3Array()
		for i in range(mini(peeling.size(),held.size())):
			blended.append(peeling[i].lerp(held[i],_detach_alpha))
		return blended
	return LabelGeometry.peeling_points(p,desired_grip,label_width,center_radius,label_y,surface_offset,segments)

func set_peel(progress: float, grip_local: Vector3) -> void:
	_last_progress = clampf(progress,0.0,1.0)
	_last_grip = grip_local
	var points := get_sample_points(_last_progress,grip_local)
	if points.size()<2:
		return
	_mesh.clear_surfaces()
	_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP,_material)
	var vertical := Vector3(0.0,label_height*0.5,0.0)
	for i in range(points.size()):
		var center := points[i]
		var curve_normal := _normal_from_points(points,i)
		var u := float(i)/float(points.size()-1)
		var top_vertex := center+vertical
		var bottom_vertex := center-vertical
		var top_normal := curve_normal
		var bottom_normal := curve_normal
		if _is_attached_u(u):
			top_vertex = _frustum_edge_point(u,label_y+label_height*0.5)
			bottom_vertex = _frustum_edge_point(u,label_y-label_height*0.5)
			top_normal = _frustum_edge_normal(top_vertex)
			bottom_normal = _frustum_edge_normal(bottom_vertex)
		_mesh.surface_set_normal(top_normal)
		_mesh.surface_set_uv(Vector2(u,0.0))
		_mesh.surface_add_vertex(top_vertex)
		_mesh.surface_set_normal(bottom_normal)
		_mesh.surface_set_uv(Vector2(u,1.0))
		_mesh.surface_add_vertex(bottom_vertex)
	_mesh.surface_end()

func _sync_from_runtime_cup() -> void:
	if not is_inside_tree():
		return
	var parent := get_parent()
	if parent == null:
		return
	var cup := parent.get_node_or_null("Cup") as MeshInstance3D
	if cup == null or not (cup.mesh is CylinderMesh):
		return
	var cup_mesh := cup.mesh as CylinderMesh
	var bottom := maxf(cup_mesh.bottom_radius,0.001)
	var top := maxf(cup_mesh.top_radius,0.001)
	var height := maxf(absf(cup_mesh.height),0.001)
	var center_y := to_local(cup.global_position).y
	if _uses_frustum_profile and is_equal_approx(bottom,_cup_bottom_radius) and is_equal_approx(top,_cup_top_radius) and is_equal_approx(height,_cup_height) and is_equal_approx(center_y,_cup_center_y):
		return
	_cup_bottom_radius = bottom
	_cup_top_radius = top
	_cup_height = height
	_cup_center_y = center_y
	_uses_frustum_profile = true
	cup_radius = CupSurface.frustum_radius_at_y(label_y,_cup_bottom_radius,_cup_top_radius,_cup_height,_cup_center_y)

func _try_configure_from_runtime_cup() -> void:
	_sync_from_runtime_cup()

func _is_attached_u(u: float) -> bool:
	if not _uses_frustum_profile:
		return false
	if not (_phase_name in ["ATTACHED","PEELING"]):
		return false
	return u+0.000001>=_last_progress

func _frustum_edge_point(u: float, y: float) -> Vector3:
	return CupSurface.attached_point_on_frustum(u,label_width,y,_cup_bottom_radius,_cup_top_radius,_cup_height,_cup_center_y,surface_offset)

func _frustum_edge_normal(point: Vector3) -> Vector3:
	return CupSurface.frustum_surface_normal(point,_cup_bottom_radius,_cup_top_radius,_cup_height)

func _normal_from_points(points: PackedVector3Array, index: int) -> Vector3:
	var left_index := maxi(index-1,0)
	var right_index := mini(index+1,points.size()-1)
	var tangent := points[right_index]-points[left_index]
	if tangent.length_squared()<=0.000001:
		return Vector3.FORWARD
	var normal := tangent.normalized().cross(Vector3.UP).normalized()
	if normal.length_squared()<=0.000001:
		return Vector3.FORWARD
	return normal
