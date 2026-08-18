extends Node3D
class_name CornerPeelPresentation

const U_SEGMENTS := 40
const V_SEGMENTS := 28
const SURFACE_OFFSET := 0.025

var _label: LabelVisual
var _cup: MeshInstance3D
var _print: LabelPrint
var _visual: MeshInstance3D
var _front_material: StandardMaterial3D
var _adhesive_material: StandardMaterial3D
var _last_progress := -1.0
var _last_drag := Vector3(INF,INF,INF)
var _last_size := Vector2.ZERO
var _visual_grip_local := Vector3.ZERO

func _ready() -> void:
	call_deferred("_bind")

func _process(_delta: float) -> void:
	if _label == null or _cup == null or _print == null:
		_bind()
	if _label == null or _cup == null or _print == null or not (_cup.mesh is CylinderMesh):
		return
	_label.visible = false
	transform = _label.transform
	_sync_texture()
	var progress := clampf(float(_label.get("_last_progress")),0.0,1.0)
	var hidden_grip := Vector3(_label.get("_last_grip"))
	var hidden_front := _label.get_front_position(progress)
	var drag := hidden_grip-hidden_front
	var size := Vector2(_label.label_width,_label.label_height)
	if absf(progress-_last_progress)<0.001 and drag.distance_to(_last_drag)<0.002 and size.distance_to(_last_size)<0.001:
		return
	_last_progress = progress
	_last_drag = drag
	_last_size = size
	_rebuild(progress,drag)

func get_visual_grip_world_position() -> Vector3:
	return to_global(_visual_grip_local)

func get_start_edge_world_position() -> Vector3:
	if _label == null or _cup == null or not (_cup.mesh is CylinderMesh):
		return global_position
	var mesh := _cup.mesh as CylinderMesh
	var y := _label.label_y+_label.label_height*0.5
	var point := CupSurface.attached_point_on_frustum(1.0,_label.label_width,y,mesh.bottom_radius,mesh.top_radius,mesh.height,_cup.position.y,SURFACE_OFFSET)
	return to_global(point)

func _bind() -> void:
	var parent := get_parent()
	if parent == null:
		return
	_label = parent.get_node_or_null("PeelLabel") as LabelVisual
	_cup = parent.get_node_or_null("Cup") as MeshInstance3D
	_print = parent.get_node_or_null("LabelPrint") as LabelPrint
	if _label == null or _cup == null or _print == null:
		return
	if _visual == null:
		_visual = MeshInstance3D.new()
		_visual.name = "CornerPeelLabel"
		_visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(_visual)
		_front_material = StandardMaterial3D.new()
		_front_material.resource_name = "CornerPeelPrintedPaper"
		_front_material.cull_mode = BaseMaterial3D.CULL_DISABLED
		_front_material.roughness = 0.87
		_front_material.metallic_specular = 0.18
		_adhesive_material = StandardMaterial3D.new()
		_adhesive_material.resource_name = "CornerPeelAdhesiveTrace"
		_adhesive_material.albedo_color = Color(0.80,0.72,0.58,0.38)
		_adhesive_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_adhesive_material.roughness = 0.48
		_adhesive_material.metallic_specular = 0.42
		_adhesive_material.cull_mode = BaseMaterial3D.CULL_DISABLED
		_adhesive_material.render_priority = 2
	_sync_texture()
	_rebuild(0.0,Vector3.ZERO)

func _sync_texture() -> void:
	if _front_material != null and _print != null:
		_front_material.albedo_texture = _print.get_texture()
		_front_material.albedo_color = Color.WHITE

func _rebuild(progress: float, drag_delta: Vector3) -> void:
	if _visual == null or _label == null or _cup == null or not (_cup.mesh is CylinderMesh):
		return
	var cup_mesh := _cup.mesh as CylinderMesh
	# Show a tiny pre-lifted top-right corner at rest so the hand cursor has a clear
	# affordance. Gameplay progress itself remains exactly zero.
	var visual_progress := maxf(progress,0.012)
	var threshold := _area_threshold(visual_progress)
	var safe_drag := drag_delta
	var max_drag := maxf(_label.label_width*0.20,0.090)
	if safe_drag.length()>max_drag:
		safe_drag = safe_drag.normalized()*max_drag
	if progress<=0.001 and safe_drag.length_squared()<0.000001:
		safe_drag = Vector3(0.014,0.006,0.022)

	var base_positions := PackedVector3Array()
	var flap_positions := PackedVector3Array()
	var adhesive_positions := PackedVector3Array()
	var base_normals := PackedVector3Array()
	var flap_normals := PackedVector3Array()
	var adhesive_normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var flap_normal := Vector3(0.28,0.02,0.96).normalized()

	for v_index in range(V_SEGMENTS+1):
		var v := float(v_index)/float(V_SEGMENTS)
		var y := _label.label_y-_label.label_height*0.5+_label.label_height*v
		for u_index in range(U_SEGMENTS+1):
			var u := float(u_index)/float(U_SEGMENTS)
			var attached := CupSurface.attached_point_on_frustum(u,_label.label_width,y,cup_mesh.bottom_radius,cup_mesh.top_radius,cup_mesh.height,_cup.position.y,SURFACE_OFFSET)
			var outward := CupSurface.frustum_surface_normal(attached,cup_mesh.bottom_radius,cup_mesh.top_radius,cup_mesh.height)
			var d := (1.0-u)+(1.0-v)
			var t := clampf((threshold-d)/maxf(threshold,0.001),0.0,1.0)
			var eased := t*t*(3.0-2.0*t)
			# A detached triangular paper patch: the hinge edge stays on the vessel while
			# the free corner follows the pointer. Because the attached and lifted cells
			# are separate surfaces, printed copy outside the peeled area never stretches.
			var moved := attached+safe_drag*eased
			moved += outward*(0.012+progress*0.030)*sin(eased*PI*0.5)
			moved += Vector3.UP*(0.004+progress*0.012)*sin(eased*PI)
			base_positions.append(attached)
			flap_positions.append(moved)
			adhesive_positions.append(attached+outward*0.0015)
			base_normals.append(outward)
			flap_normals.append(outward.lerp(flap_normal,eased*0.78).normalized())
			adhesive_normals.append(outward)
			uvs.append(Vector2(u,1.0-v))

	var base_indices := PackedInt32Array()
	var flap_indices := PackedInt32Array()
	var row := U_SEGMENTS+1
	for v_index in range(V_SEGMENTS):
		var center_v := (float(v_index)+0.5)/float(V_SEGMENTS)
		for u_index in range(U_SEGMENTS):
			var center_u := (float(u_index)+0.5)/float(U_SEGMENTS)
			var center_d := (1.0-center_u)+(1.0-center_v)
			var target := flap_indices if center_d<threshold else base_indices
			var a := v_index*row+u_index
			var b := a+1
			var d := (v_index+1)*row+u_index
			var c := d+1
			target.append(a); target.append(d); target.append(c)
			target.append(a); target.append(c); target.append(b)

	var mesh := ArrayMesh.new()
	if not base_indices.is_empty():
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,_arrays(base_positions,base_normals,uvs,base_indices))
		mesh.surface_set_material(mesh.get_surface_count()-1,_front_material)
	if not flap_indices.is_empty():
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,_arrays(flap_positions,flap_normals,uvs,flap_indices))
		mesh.surface_set_material(mesh.get_surface_count()-1,_front_material)
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,_arrays(adhesive_positions,adhesive_normals,uvs,flap_indices))
		mesh.surface_set_material(mesh.get_surface_count()-1,_adhesive_material)
	_visual.mesh = mesh

	var corner_index := V_SEGMENTS*(U_SEGMENTS+1)+U_SEGMENTS
	_visual_grip_local = flap_positions[corner_index]

func _arrays(vertices: PackedVector3Array, normals: PackedVector3Array, tex_uv: PackedVector2Array, indices: PackedInt32Array) -> Array:
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = tex_uv
	arrays[Mesh.ARRAY_INDEX] = indices
	return arrays

func _area_threshold(progress: float) -> float:
	var p := clampf(progress,0.0,1.0)
	if p<=0.5:
		return sqrt(2.0*p)
	return 2.0-sqrt(2.0*(1.0-p))
