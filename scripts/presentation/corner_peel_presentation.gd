extends Node3D
class_name CornerPeelPresentation

const U_SEGMENTS := 30
const V_SEGMENTS := 20
const SURFACE_OFFSET := 0.025

var _label: LabelVisual
var _cup: MeshInstance3D
var _print: LabelPrint
var _visual: MeshInstance3D
var _front_material: StandardMaterial3D
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
		_front_material.resource_name = "CornerPeelFront"
		# One continuous two-sided printed sheet avoids the previous coplanar
		# front/back z-fight. A dedicated underside can be added later only on the
		# actually lifted polygon if the reference comparison still needs it.
		_front_material.cull_mode = BaseMaterial3D.CULL_DISABLED
		_front_material.roughness = 0.87
		_front_material.metallic = 0.0
		_front_material.metallic_specular = 0.20
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
	var positions := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var threshold := _area_threshold(progress)
	var feather := 0.070
	var safe_drag := drag_delta
	var max_drag := maxf(_label.label_width*0.27,0.105)
	if safe_drag.length()>max_drag:
		safe_drag = safe_drag.normalized()*max_drag
	if progress<=0.001 and safe_drag.length_squared()<0.000001:
		safe_drag = Vector3(0.018,0.008,0.025)

	var flap_normal := Vector3(0.30,0.02,0.954).normalized()
	for v_index in range(V_SEGMENTS+1):
		var v := float(v_index)/float(V_SEGMENTS)
		var y := _label.label_y-_label.label_height*0.5+_label.label_height*v
		for u_index in range(U_SEGMENTS+1):
			var u := float(u_index)/float(U_SEGMENTS)
			var attached := CupSurface.attached_point_on_frustum(u,_label.label_width,y,cup_mesh.bottom_radius,cup_mesh.top_radius,cup_mesh.height,_cup.position.y,SURFACE_OFFSET)
			var d := (1.0-u)+(1.0-v)
			var influence := 1.0-smoothstep(maxf(threshold-feather,0.0),threshold+feather,d)
			if progress<=0.001:
				influence *= smoothstep(1.82,2.0,u+v)
			var hinge_weight := 1.0-smoothstep(maxf(threshold-feather*2.2,0.0),threshold,d)
			var local_drag := safe_drag*pow(influence,1.05)
			var outward := CupSurface.frustum_surface_normal(attached,cup_mesh.bottom_radius,cup_mesh.top_radius,cup_mesh.height)
			var curl := outward*(0.010+progress*0.024)*hinge_weight
			curl += Vector3.UP*(0.006+progress*0.016)*hinge_weight
			positions.append(attached+local_drag+curl)
			normals.append(outward.lerp(flap_normal,influence*0.82).normalized())
			uvs.append(Vector2(u,1.0-v))

	var indices := PackedInt32Array()
	var row := U_SEGMENTS+1
	for v_index in range(V_SEGMENTS):
		for u_index in range(U_SEGMENTS):
			var a := v_index*row+u_index
			var b := a+1
			var d := (v_index+1)*row+u_index
			var c := d+1
			indices.append(a); indices.append(d); indices.append(c)
			indices.append(a); indices.append(c); indices.append(b)

	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = positions
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	mesh.surface_set_material(0,_front_material)
	_visual.mesh = mesh

	var corner_index := V_SEGMENTS*(U_SEGMENTS+1)+U_SEGMENTS
	_visual_grip_local = positions[corner_index]

func _area_threshold(progress: float) -> float:
	var p := clampf(progress,0.0,1.0)
	if p<=0.5:
		return sqrt(2.0*p)
	return 2.0-sqrt(2.0*(1.0-p))
