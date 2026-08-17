extends Node3D
class_name CupCrumplePresentation

signal crumple_changed(progress: float)

const RINGS := 7
const SEGMENTS := 16
const VISUAL_COMPRESSION_GAIN := 2.20
const HEIGHT_SHORTENING_GAIN := 0.24

var _cup: MeshInstance3D
var _lid: MeshInstance3D
var _shell: MeshInstance3D
var _profile: Dictionary = {}
var _enabled := true
var _progress := 0.0
var _side := -1
var _pulse := 0.0
var _last_signature := Vector4(-1.0,0.0,0.0,0.0)
var _baseline_lid_transform := Transform3D.IDENTITY
var _has_lid_baseline := false

func _ready() -> void:
	call_deferred("_bind_cup")

func _process(_delta: float) -> void:
	if _cup == null:
		_bind_cup()
	if _cup != null and _shell != null:
		_shell.transform = global_transform.affine_inverse()*_cup.global_transform
		if _enabled:
			_sync_material()

func set_profile(profile: Dictionary) -> void:
	_profile = profile.duplicate(true)
	_enabled = String(_profile.get("post_peel_action","crumple")) == "crumple" and String(_profile.get("cup_shell","paper")) == "paper"
	if _cup == null:
		_bind_cup()
	_capture_lid_baseline()
	_progress = 0.0
	_pulse = 0.0
	_last_signature.x = -1.0
	if _enabled:
		_rebuild_shell()
		_apply_lid_follow()
	elif _shell != null:
		_shell.visible = false
	# Important: disabled glass profiles deliberately do not touch _cup.visible.
	# ProductPresentation owns whether the hidden interaction cylinder is shown.

func set_crumple(progress: float, side: int, pulse: float) -> void:
	if not _enabled:
		return
	_progress = clampf(progress if is_finite(progress) else 0.0,0.0,1.0)
	_side = -1 if side<0 else 1
	_pulse = clampf(pulse if is_finite(pulse) else 0.0,0.0,1.0)
	_rebuild_shell()
	_apply_visibility()
	_apply_lid_follow()
	crumple_changed.emit(_progress)

func reset_visual() -> void:
	_progress = 0.0
	_pulse = 0.0
	_last_signature.x = -1.0
	if _enabled:
		_rebuild_shell()
		_apply_visibility()
		_restore_lid_baseline()
	else:
		if _shell != null:
			_shell.visible = false
	crumple_changed.emit(0.0)

func get_progress() -> float:
	return _progress

func is_enabled_for_profile() -> bool:
	return _enabled

func _bind_cup() -> void:
	if _cup != null:
		return
	var parent := get_parent()
	if parent == null:
		return
	_cup = parent.get_node_or_null("Cup") as MeshInstance3D
	if _cup == null or not (_cup.mesh is CylinderMesh):
		_cup = null
		return
	_lid = parent.get_node_or_null("Lid") as MeshInstance3D
	if _shell == null:
		_shell = MeshInstance3D.new()
		_shell.name = "CrumpledCup"
		_shell.visible = false
		add_child(_shell)
	_shell.transform = global_transform.affine_inverse()*_cup.global_transform
	_sync_material()
	_capture_lid_baseline()
	if _enabled:
		_rebuild_shell()
		_apply_visibility()

func _capture_lid_baseline() -> void:
	if _lid == null:
		var parent := get_parent()
		if parent != null:
			_lid = parent.get_node_or_null("Lid") as MeshInstance3D
	if _lid == null:
		_has_lid_baseline = false
		return
	_baseline_lid_transform = _lid.transform
	_has_lid_baseline = true

func _apply_lid_follow() -> void:
	if not _enabled or _lid == null or not _has_lid_baseline:
		return
	var dims := _dimensions()
	var total_shortening := dims.z*_progress*HEIGHT_SHORTENING_GAIN
	var target := _baseline_lid_transform
	target.origin.y -= total_shortening*0.5
	_lid.transform = target

func _restore_lid_baseline() -> void:
	if _enabled and _lid != null and _has_lid_baseline:
		_lid.transform = _baseline_lid_transform

func _apply_visibility() -> void:
	if not _enabled or _cup == null or _shell == null:
		return
	var crumpled := _progress>0.001
	_shell.visible = crumpled
	_cup.visible = not crumpled
	_set_cafe_details_visible(not crumpled)

func _set_cafe_details_visible(value: bool) -> void:
	if not _enabled:
		return
	var parent := get_parent()
	if parent == null:
		return
	var cafe := parent.get_node_or_null("CafePresentation")
	if cafe == null:
		return
	for node_name in ["CupPaperSeam","CupBaseFold","CupLipShadow"]:
		var detail := cafe.get_node_or_null(node_name) as Node3D
		if detail != null:
			detail.visible = value

func _sync_material() -> void:
	if _cup == null or _shell == null:
		return
	if _cup.material_override != null:
		_shell.material_override = _cup.material_override
	elif _shell.material_override == null:
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(0.89,0.84,0.74,1.0)
		material.roughness = 0.94
		_shell.material_override = material

func _rebuild_shell() -> void:
	if not _enabled:
		return
	if _cup == null:
		_bind_cup()
	if _cup == null or _shell == null:
		return
	var dims := _dimensions()
	var max_compression := _max_compression()
	var signature := Vector4(_progress,float(_side),max_compression,dims.z)
	if absf(signature.x-_last_signature.x)<0.002 and signature.y==_last_signature.y and is_equal_approx(signature.z,_last_signature.z) and is_equal_approx(signature.w,_last_signature.w):
		return
	_last_signature = signature
	_shell.mesh = _build_mesh(dims.x,dims.y,dims.z,_progress,_side,max_compression,_pulse)

func _dimensions() -> Vector3:
	var cup_mesh := _cup.mesh as CylinderMesh
	var bottom := maxf(cup_mesh.bottom_radius,0.05)
	var top := maxf(cup_mesh.top_radius,bottom)
	var height := maxf(cup_mesh.height,0.20)
	var configured: Dictionary = _profile.get("cup_dimensions",{})
	if not configured.is_empty():
		bottom = maxf(float(configured.get("bottom_radius",bottom)),0.05)
		top = maxf(float(configured.get("top_radius",top)),bottom)
		height = maxf(float(configured.get("height",height)),0.20)
	return Vector3(bottom,top,height)

func _max_compression() -> float:
	var crumple: Dictionary = _profile.get("crumple_profile",{})
	return clampf(float(crumple.get("max_compression",0.22)),0.02,0.45)

func _build_mesh(bottom_radius: float, top_radius: float, height: float, progress: float, side: int, max_compression: float, pulse: float) -> ArrayMesh:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	var compression := clampf(progress*max_compression*VISUAL_COMPRESSION_GAIN,0.0,0.50)
	var shown_height := height*(1.0-progress*HEIGHT_SHORTENING_GAIN)
	var slope := (top_radius-bottom_radius)/maxf(shown_height,0.001)
	for ring in range(RINGS):
		var t := float(ring)/float(RINGS-1)
		var y := lerpf(-shown_height*0.5,shown_height*0.5,t)
		var radius := lerpf(bottom_radius,top_radius,t)
		var vertical_envelope := pow(sin(PI*t),1.20)
		for segment in range(SEGMENTS):
			var u := float(segment)/float(SEGMENTS)
			var angle := u*TAU
			var radial_x := sin(angle)
			var radial_z := cos(angle)
			var side_weight := maxf(float(side)*radial_x,0.0)
			var dent := compression*vertical_envelope*(0.26+0.74*side_weight)
			var x_scale := 1.0-dent
			var z_scale := 1.0-compression*vertical_envelope*0.18
			var inward_shift := -float(side)*compression*vertical_envelope*radius*0.13
			var crease := float(side)*pulse*progress*vertical_envelope*sin(angle*3.0+float(ring)*0.55)*0.028
			var wrinkle_y := pulse*progress*vertical_envelope*sin(angle*2.0+float(ring))*0.010
			vertices.append(Vector3(radial_x*radius*x_scale+inward_shift+crease,y+wrinkle_y,radial_z*radius*z_scale))
			var normal := Vector3(radial_x/maxf(x_scale,0.2),-slope,radial_z/maxf(z_scale,0.2)).normalized()
			normals.append(normal)
			uvs.append(Vector2(u,1.0-t))
	for ring in range(RINGS-1):
		for segment in range(SEGMENTS):
			var next_segment := (segment+1)%SEGMENTS
			var a := ring*SEGMENTS+segment
			var b := ring*SEGMENTS+next_segment
			var c := (ring+1)*SEGMENTS+segment
			var d := (ring+1)*SEGMENTS+next_segment
			indices.append_array(PackedInt32Array([a,c,b,b,c,d]))
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	return mesh
