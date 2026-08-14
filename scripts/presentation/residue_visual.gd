extends MeshInstance3D
class_name ResidueVisual

var _immediate: ImmediateMesh = ImmediateMesh.new()
var _material: StandardMaterial3D = StandardMaterial3D.new()
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

func _ready() -> void:
	mesh = _immediate
	_material.albedo_color = Color(0.83,0.80,0.72,0.92)
	_material.roughness = 0.98
	_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

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
	_rebuild()

func get_residue_amount() -> float:
	return _residue_amount

func set_inspection_yaw(yaw: float) -> void:
	rotation.y = yaw if is_finite(yaw) else 0.0

func _rebuild() -> void:
	if mesh != _immediate:
		mesh = _immediate
	_immediate.clear_surfaces()
	if _residue_amount <= 0.002 or _progress <= 0.002:
		return
	_material.albedo_color = Color(0.80,0.77,0.69,clampf(0.58 + _residue_amount*0.38,0.58,0.96))
	_immediate.surface_begin(Mesh.PRIMITIVE_TRIANGLES,_material)
	var segments: int = 34
	var peeled_u: float = clampf(_progress,0.0,1.0)
	var density: float = clampf(_residue_amount*1.55 + (1.0-_integrity)*0.72,0.08,1.0)
	for i: int in range(segments):
		var u0: float = float(i)/float(segments)
		var u1: float = float(i+1)/float(segments)
		if u0 >= peeled_u:
			break
		var signal_value: float = 0.5 + 0.5*sin(float(i)*2.71 + 0.43)
		if signal_value > density:
			continue
		u1 = minf(u1,peeled_u)
		var rag_a: float = sin(float(i)*1.91)*0.11*_label_height*(0.4+_residue_amount)
		var rag_b: float = sin(float(i+1)*2.17+0.8)*0.11*_label_height*(0.4+_residue_amount)
		var y_top_a: float = _label_y + _label_height*0.5 - absf(rag_a)*0.35
		var y_bot_a: float = _label_y - _label_height*0.5 + absf(rag_a)
		var y_top_b: float = _label_y + _label_height*0.5 - absf(rag_b)*0.70
		var y_bot_b: float = _label_y - _label_height*0.5 + absf(rag_b)*0.45
		var a: Vector3 = _point(u0,y_top_a)
		var b: Vector3 = _point(u0,y_bot_a)
		var c: Vector3 = _point(u1,y_top_b)
		var d: Vector3 = _point(u1,y_bot_b)
		var na: Vector3 = _normal(a)
		var nb: Vector3 = _normal(b)
		var nc: Vector3 = _normal(c)
		var nd: Vector3 = _normal(d)
		_vertex(a,na,Vector2(u0,0))
		_vertex(b,nb,Vector2(u0,1))
		_vertex(c,nc,Vector2(u1,0))
		_vertex(c,nc,Vector2(u1,0))
		_vertex(b,nb,Vector2(u0,1))
		_vertex(d,nd,Vector2(u1,1))
	_immediate.surface_end()

func _point(u: float, y: float) -> Vector3:
	return CupSurface.attached_point_on_frustum(u,_label_width,y,_bottom_radius,_top_radius,_body_height,_body_center_y,0.0125)

func _normal(point: Vector3) -> Vector3:
	return CupSurface.frustum_surface_normal(point,_bottom_radius,_top_radius,_body_height)

func _vertex(position: Vector3, normal: Vector3, uv: Vector2) -> void:
	_immediate.surface_set_normal(normal)
	_immediate.surface_set_uv(uv)
	_immediate.surface_add_vertex(position)
