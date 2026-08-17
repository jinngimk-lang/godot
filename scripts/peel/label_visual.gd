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
var _edge_material := StandardMaterial3D.new()
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
	_edge_material.albedo_color = Color(0.76,0.72,0.63,1.0)
	_edge_material.roughness = 0.98
	_edge_material.cull_mode = BaseMaterial3D.CULL_DISABLED
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

func get_paper_thickness() -> float:
	return clampf(label_height * 0.014, 0.0032, 0.0060)

func get_torn_front_fringe(progress: float) -> PackedVector2Array:
	var fringe := PackedVector2Array()
	var p := clampf(progress if is_finite(progress) else 0.0,0.0,1.0)
	if p <= 0.025:
		return fringe
	var fiber_count := 7
	for i in range(fiber_count):
		var t := float(i+1)/float(fiber_count+1)
		var y_jitter := _edge_noise(i,41)*label_height*0.026
		var y_offset := lerpf(-label_height*0.42,label_height*0.42,t)+y_jitter
		var length_noise := (_edge_noise(i,47)+1.0)*0.5
		var length := 0.0085+length_noise*0.0115
		fringe.append(Vector2(y_offset,length))
	return fringe

func get_edge_offsets(progress: float) -> PackedVector2Array:
	var result := PackedVector2Array()
	var p := clampf(progress if is_finite(progress) else 0.0,0.0,1.0)
	var count := maxi(segments,1)
	for i in range(count+1):
		var u := float(i)/float(count)
		var peeled_weight := clampf((p + 0.08 - u) / 0.08,0.0,1.0) * p
		var distance := (u-p)/0.065
		var boundary := exp(-(distance*distance)) * p
		var top_noise := _edge_noise(i,3)
		var bottom_noise := _edge_noise(i,11)
		var amplitude := 0.0012 + 0.0058*peeled_weight + 0.0075*boundary
		var notch_top := boundary * (0.0022 + 0.0034*absf(bottom_noise))
		var notch_bottom := boundary * (0.0020 + 0.0032*absf(top_noise))
		var top_offset := clampf(top_noise*amplitude-notch_top,-0.016,0.012)
		var bottom_offset := clampf(bottom_noise*amplitude+notch_bottom,-0.012,0.016)
		result.append(Vector2(top_offset,bottom_offset))
	return result

func set_peel(progress: float, grip_local: Vector3) -> void:
	_last_progress = clampf(progress,0.0,1.0)
	_last_grip = grip_local
	var points := get_sample_points(_last_progress,grip_local)
	if points.size()<2:
		return
	var edge_offsets := get_edge_offsets(_last_progress)
	var top_vertices := PackedVector3Array()
	var bottom_vertices := PackedVector3Array()
	var top_normals := PackedVector3Array()
	var bottom_normals := PackedVector3Array()

	_mesh.clear_surfaces()
	_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP,_material)
	for i in range(points.size()):
		var center := points[i]
		var curve_normal := _normal_from_points(points,i)
		var u := float(i)/float(points.size()-1)
		var offsets := edge_offsets[mini(i,edge_offsets.size()-1)]
		var top_y_offset := label_height*0.5+offsets.x
		var bottom_y_offset := -label_height*0.5+offsets.y
		var top_vertex := center+Vector3.UP*top_y_offset
		var bottom_vertex := center+Vector3.UP*bottom_y_offset
		var top_normal := curve_normal
		var bottom_normal := curve_normal
		if _is_attached_u(u):
			top_vertex = _frustum_edge_point(u,label_y+top_y_offset)
			bottom_vertex = _frustum_edge_point(u,label_y+bottom_y_offset)
			top_normal = _frustum_edge_normal(top_vertex)
			bottom_normal = _frustum_edge_normal(bottom_vertex)
		top_vertices.append(top_vertex)
		bottom_vertices.append(bottom_vertex)
		top_normals.append(top_normal)
		bottom_normals.append(bottom_normal)
		_mesh.surface_set_normal(top_normal)
		_mesh.surface_set_uv(Vector2(u,0.0))
		_mesh.surface_add_vertex(top_vertex)
		_mesh.surface_set_normal(bottom_normal)
		_mesh.surface_set_uv(Vector2(u,1.0))
		_mesh.surface_add_vertex(bottom_vertex)
	_mesh.surface_end()

	_draw_paper_edge(top_vertices,top_normals,true)
	_draw_paper_edge(bottom_vertices,bottom_normals,false)
	_draw_torn_front_fringe(points,_last_progress)

func _draw_paper_edge(vertices: PackedVector3Array, normals: PackedVector3Array, top_edge: bool) -> void:
	if vertices.size()<2 or normals.size()!=vertices.size():
		return
	var thickness := get_paper_thickness()
	_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP,_edge_material)
	for i in range(vertices.size()):
		var u := float(i)/float(vertices.size()-1)
		var front := vertices[i]
		var back := front-normals[i]*thickness
		var side_normal := Vector3.UP if top_edge else Vector3.DOWN
		_mesh.surface_set_normal(side_normal)
		_mesh.surface_set_uv(Vector2(u,0.0))
		_mesh.surface_add_vertex(front)
		_mesh.surface_set_normal(side_normal)
		_mesh.surface_set_uv(Vector2(u,1.0))
		_mesh.surface_add_vertex(back)
	_mesh.surface_end()

func _draw_torn_front_fringe(points: PackedVector3Array, progress: float) -> void:
	var fringe := get_torn_front_fringe(progress)
	if fringe.is_empty() or points.size()<3:
		return
	var boundary_index := clampi(int(round(progress*float(points.size()-1))),1,points.size()-1)
	var boundary_center := points[boundary_index]
	var peel_direction := points[boundary_index-1]-boundary_center
	if peel_direction.length_squared()<=0.000001:
		return
	peel_direction = peel_direction.normalized()
	var normal := _normal_from_points(points,boundary_index)
	_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES,_edge_material)
	for i in range(fringe.size()):
		var fiber := fringe[i]
		var half_width := 0.0018+0.0010*float(i%3)
		var base_center := boundary_center+Vector3.UP*fiber.x+normal*0.0015
		var tip := base_center+peel_direction*fiber.y+Vector3.UP*_edge_noise(i,59)*0.0028
		_mesh.surface_set_normal(normal)
		_mesh.surface_set_uv(Vector2(0.0,0.0))
		_mesh.surface_add_vertex(base_center+Vector3.UP*half_width)
		_mesh.surface_set_normal(normal)
		_mesh.surface_set_uv(Vector2(0.0,1.0))
		_mesh.surface_add_vertex(base_center-Vector3.UP*half_width)
		_mesh.surface_set_normal(normal)
		_mesh.surface_set_uv(Vector2(1.0,0.5))
		_mesh.surface_add_vertex(tip)
	_mesh.surface_end()

func _edge_noise(index: int, salt: int) -> float:
	var hashed := posmod((index+1)*37 + salt*53 + (index+salt)*(index+3)*11,97)
	return float(hashed)/48.0-1.0

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