extends MeshInstance3D
class_name ResidueVisual

var _immediate: ImmediateMesh = ImmediateMesh.new()
var _adhesive_material: StandardMaterial3D = StandardMaterial3D.new()
var _fiber_material: StandardMaterial3D = StandardMaterial3D.new()
var _bottom_radius: float = 0.45
var _top_radius: float = 0.54
var _body_height: float = 1.45
var _body_center_y: float = 0.05
var _label_width: float = 1.15
var _label_height: float = 0.40
var _label_y: float = 0.68
var _residue_amount: float = 0.0
var _integrity: float = 1.0
var _progress: float = 0.0
var _fiber_strength: float = 0.0

func _ready() -> void:
	mesh = _immediate
	_ensure_materials()

func configure(bottom_radius: float, top_radius: float, body_height: float, body_center_y: float, label_width: float, label_height: float, label_y: float = 0.68) -> void:
	_bottom_radius = maxf(bottom_radius,0.02)
	_top_radius = maxf(top_radius,0.02)
	_body_height = maxf(absf(body_height),0.05)
	_body_center_y = body_center_y
	_label_width = maxf(label_width,0.05)
	_label_height = maxf(label_height,0.03)
	_label_y = label_y
	_rebuild()

func set_residue(progress: float, residue: float, integrity: float) -> void:
	_progress = clampf(progress if is_finite(progress) else 0.0,0.0,1.0)
	_residue_amount = clampf(residue if is_finite(residue) else 0.0,0.0,1.0)
	_integrity = clampf(integrity if is_finite(integrity) else 1.0,0.0,1.0)
	_fiber_strength = clampf(_residue_amount*0.45+(1.0-_integrity)*0.75,0.0,1.0)
	_rebuild()

func get_residue_amount() -> float:
	return _residue_amount

func get_fiber_strength() -> float:
	return _fiber_strength

func has_layered_residue() -> bool:
	return _residue_amount > 0.002 and _progress > 0.002 and _immediate.get_surface_count() >= 2

func set_inspection_yaw(yaw: float) -> void:
	rotation.y = yaw if is_finite(yaw) else 0.0

func _ensure_materials() -> void:
	_adhesive_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_adhesive_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_adhesive_material.roughness = 0.36
	_adhesive_material.metallic = 0.0
	_adhesive_material.metallic_specular = 0.46
	_adhesive_material.render_priority = 2

	_fiber_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_fiber_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_fiber_material.roughness = 0.98
	_fiber_material.metallic = 0.0
	_fiber_material.metallic_specular = 0.12
	_fiber_material.render_priority = 3

func _rebuild() -> void:
	if mesh != _immediate:
		mesh = _immediate
	_immediate.clear_surfaces()
	if _residue_amount <= 0.002 or _progress <= 0.002:
		return
	_ensure_materials()

	var adhesive_alpha := clampf(0.14+_residue_amount*0.42,0.14,0.50)
	_adhesive_material.albedo_color = Color(0.76,0.70,0.56,adhesive_alpha)
	var fiber_alpha := clampf(0.64+_fiber_strength*0.28,0.64,0.90)
	_fiber_material.albedo_color = Color(0.92,0.87,0.78,fiber_alpha)

	_draw_adhesive_layer()
	_draw_fiber_layer()

func _draw_adhesive_layer() -> void:
	var segments := 40
	var peeled_u := clampf(_progress,0.0,1.0)
	var density := clampf(0.32+_residue_amount*1.15,0.32,0.96)
	var started := false
	for i in range(segments):
		var u0 := float(i)/float(segments)
		if u0 >= peeled_u:
			break
		var u1 := minf(float(i+1)/float(segments),peeled_u)
		var signal_value := _signal(i,5)
		if signal_value > density:
			continue
		if not started:
			_immediate.surface_begin(Mesh.PRIMITIVE_TRIANGLES,_adhesive_material)
			started = true
		var center_offset := sin(float(i)*1.43+0.25)*_label_height*0.16
		var half_height := _label_height*(0.08+0.09*(1.0-signal_value)+0.04*_residue_amount)
		var y0_top := _label_y+center_offset+half_height
		var y0_bottom := _label_y+center_offset-half_height
		var next_offset := sin(float(i+1)*1.43+0.25)*_label_height*0.16
		var next_half := half_height*(0.82+0.22*_signal(i+1,9))
		var y1_top := _label_y+next_offset+next_half
		var y1_bottom := _label_y+next_offset-next_half
		_emit_patch(u0,u1,y0_top,y0_bottom,y1_top,y1_bottom,0.0122)
	if started:
		_immediate.surface_end()

func _draw_fiber_layer() -> void:
	# Torn backing should read as a handful of broad paper islands, not a picket
	# fence of narrow vertical shards. Fourteen broad cells preserve deterministic
	# variation while keeping each surviving fragment wider than it is tall.
	var segments := 14
	var peeled_u := clampf(_progress,0.0,1.0)
	var density := clampf(0.22+_fiber_strength*0.62,0.22,0.82)
	var started := false
	for i in range(segments):
		var u0 := float(i)/float(segments)
		if u0 >= peeled_u:
			break
		var u1 := minf(float(i+1)/float(segments),peeled_u)
		var signal_value := _signal(i,17)
		if signal_value > density:
			continue
		if not started:
			_immediate.surface_begin(Mesh.PRIMITIVE_TRIANGLES,_fiber_material)
			started = true
		var center_offset := (0.5-_signal(i,31))*_label_height*0.34
		var next_offset := center_offset+(0.5-_signal(i+1,37))*_label_height*0.08
		var half_height := _label_height*(0.035+0.075*_fiber_strength+0.020*(1.0-signal_value))
		var rag0 := (0.5-_signal(i,23))*_label_height*0.025
		var rag1 := (0.5-_signal(i+1,29))*_label_height*0.025
		var y0_top := _label_y+center_offset+half_height+rag0
		var y0_bottom := _label_y+center_offset-half_height-rag0*0.35
		var y1_top := _label_y+next_offset+half_height*0.90+rag1
		var y1_bottom := _label_y+next_offset-half_height*0.88-rag1*0.35
		_emit_patch(u0,u1,y0_top,y0_bottom,y1_top,y1_bottom,0.0153)
	if started:
		_immediate.surface_end()

func _emit_patch(u0: float, u1: float, y0_top: float, y0_bottom: float, y1_top: float, y1_bottom: float, offset: float) -> void:
	var a := _point(u0,y0_top,offset)
	var b := _point(u0,y0_bottom,offset)
	var c := _point(u1,y1_top,offset)
	var d := _point(u1,y1_bottom,offset)
	var na := _normal(a)
	var nb := _normal(b)
	var nc := _normal(c)
	var nd := _normal(d)
	_vertex(a,na,Vector2(u0,0)); _vertex(b,nb,Vector2(u0,1)); _vertex(c,nc,Vector2(u1,0))
	_vertex(c,nc,Vector2(u1,0)); _vertex(b,nb,Vector2(u0,1)); _vertex(d,nd,Vector2(u1,1))

func _signal(index: int, salt: int) -> float:
	var hashed := posmod((index+1)*37+salt*53+(index+salt)*(index+3)*11,97)
	return float(hashed)/96.0

func _point(u: float, y: float, offset: float) -> Vector3:
	return CupSurface.attached_point_on_frustum(u,_label_width,y,_bottom_radius,_top_radius,_body_height,_body_center_y,offset)

func _normal(point: Vector3) -> Vector3:
	return CupSurface.frustum_surface_normal(point,_bottom_radius,_top_radius,_body_height)

func _vertex(position: Vector3, normal: Vector3, uv: Vector2) -> void:
	_immediate.surface_set_normal(normal)
	_immediate.surface_set_uv(uv)
	_immediate.surface_add_vertex(position)
