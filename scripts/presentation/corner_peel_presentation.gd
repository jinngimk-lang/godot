extends Node3D
class_name CornerPeelPresentation

const U_SEGMENTS := 40
const V_SEGMENTS := 28
const SURFACE_OFFSET := 0.025
const VISUAL_AREA_SCALE := 0.62
const COMPLETE_RAMP_START := 0.84
const DEFAULT_BEND_BAND_RATIO := 0.14
const DEFAULT_BACKING_THICKNESS := 0.0036
const PAPER_BACKING_ROUGHNESS := 0.96
const PAPER_SHADER_PATH := "res://art/shaders/peeled_paper.gdshader"

var _label: LabelVisual
var _cup: MeshInstance3D
var _print: LabelPrint
var _lifecycle
var _visual: MeshInstance3D
var _front_material: ShaderMaterial
var _back_material: ShaderMaterial
var _adhesive_material: StandardMaterial3D
var _last_progress := -1.0
var _last_drag := Vector3(INF,INF,INF)
var _last_size := Vector2.ZERO
var _last_release_settle_alpha := -1.0
var _visual_grip_local := Vector3.ZERO
var _bend_band_ratio := DEFAULT_BEND_BAND_RATIO
var _backing_thickness := DEFAULT_BACKING_THICKNESS

func _ready() -> void:
	call_deferred("_bind")

func _process(_delta: float) -> void:
	if _label == null or _cup == null or _print == null or _lifecycle == null:
		_bind()
	if _label == null or _cup == null or _print == null or not (_cup.mesh is CylinderMesh):
		return
	_label.visible = false
	transform = _label.transform
	_sync_texture()
	var should_render := true
	var settle_alpha := 0.0
	if _lifecycle != null:
		should_render = bool(_lifecycle.call("should_render_label"))
		settle_alpha = clampf(float(_lifecycle.call("get_release_settle_alpha")),0.0,1.0)
	if _visual != null:
		_visual.visible = should_render
	if not should_render:
		return
	var progress := clampf(float(_label.get("_last_progress")),0.0,1.0)
	var hidden_grip := Vector3(_label.get("_last_grip"))
	var hidden_front := _label.get_front_position(progress)
	var drag := hidden_grip-hidden_front
	var size := Vector2(_label.label_width,_label.label_height)
	if absf(progress-_last_progress)<0.001 and drag.distance_to(_last_drag)<0.002 and size.distance_to(_last_size)<0.001 and absf(settle_alpha-_last_release_settle_alpha)<0.002:
		return
	_last_progress = progress
	_last_drag = drag
	_last_size = size
	_last_release_settle_alpha = settle_alpha
	_rebuild(progress,drag,settle_alpha)

func set_paper_profile(profile: Dictionary) -> void:
	_bend_band_ratio = clampf(float(profile.get("bend_band_ratio",DEFAULT_BEND_BAND_RATIO)),0.06,0.22)
	_backing_thickness = clampf(float(profile.get("backing_thickness",DEFAULT_BACKING_THICKNESS)),0.0015,0.010)
	_last_progress = -1.0
	_last_drag = Vector3(INF,INF,INF)
	_last_release_settle_alpha = -1.0

func get_paper_surface_shader_path() -> String:
	return PAPER_SHADER_PATH

func get_visual_grip_world_position() -> Vector3:
	return to_global(_visual_grip_local)

func get_start_edge_world_position() -> Vector3:
	if _label == null or _cup == null or not (_cup.mesh is CylinderMesh):
		return global_position
	var mesh := _cup.mesh as CylinderMesh
	var y := _label.label_y+_label.label_height*0.5
	var point := CupSurface.attached_point_on_frustum(1.0,_label.label_width,y,mesh.bottom_radius,mesh.top_radius,mesh.height,_cup.position.y,SURFACE_OFFSET)
	return to_global(point)

func visual_progress_for_gameplay(progress: float) -> float:
	var p := clampf(progress if is_finite(progress) else 0.0,0.0,1.0)
	if p >= 0.999:
		return 1.0
	if p <= COMPLETE_RAMP_START:
		return p*VISUAL_AREA_SCALE
	var start_visible := COMPLETE_RAMP_START*VISUAL_AREA_SCALE
	var t := clampf((p-COMPLETE_RAMP_START)/(1.0-COMPLETE_RAMP_START),0.0,1.0)
	var eased := t*t*(3.0-2.0*t)
	return lerpf(start_visible,1.0,eased)

func paper_bend_band_ratio() -> float:
	return _bend_band_ratio

func paper_backing_thickness() -> float:
	return _backing_thickness

func paper_backing_roughness() -> float:
	return PAPER_BACKING_ROUGHNESS

func _bind() -> void:
	var parent := get_parent()
	if parent == null:
		return
	_label = parent.get_node_or_null("PeelLabel") as LabelVisual
	_cup = parent.get_node_or_null("Cup") as MeshInstance3D
	_print = parent.get_node_or_null("LabelPrint") as LabelPrint
	_lifecycle = parent.get("_lifecycle")
	if _label == null or _cup == null or _print == null:
		return
	if _visual == null:
		_visual = MeshInstance3D.new()
		_visual.name = "CornerPeelLabel"
		_visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(_visual)
		var paper_shader := load(PAPER_SHADER_PATH) as Shader
		if paper_shader == null:
			return
		_front_material = ShaderMaterial.new()
		_front_material.resource_name = "CornerPeelPrintedPaper"
		_front_material.shader = paper_shader
		_front_material.set_shader_parameter("use_print",true)
		_front_material.set_shader_parameter("paper_tint",Color.WHITE)
		_front_material.set_shader_parameter("base_roughness",0.91)
		_front_material.set_shader_parameter("fiber_strength",0.036)
		_front_material.set_shader_parameter("fiber_scale",220.0)
		_back_material = ShaderMaterial.new()
		_back_material.resource_name = "CornerPeelFibrousBacking"
		_back_material.shader = paper_shader
		_back_material.set_shader_parameter("use_print",false)
		_back_material.set_shader_parameter("paper_tint",Color(0.86,0.82,0.72,1.0))
		_back_material.set_shader_parameter("base_roughness",PAPER_BACKING_ROUGHNESS)
		_back_material.set_shader_parameter("fiber_strength",0.058)
		_back_material.set_shader_parameter("fiber_scale",270.0)
		_adhesive_material = StandardMaterial3D.new()
		_adhesive_material.resource_name = "CornerPeelAdhesiveTrace"
		_adhesive_material.albedo_color = Color(0.80,0.72,0.58,0.30)
		_adhesive_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_adhesive_material.roughness = 0.58
		_adhesive_material.metallic_specular = 0.24
		_adhesive_material.cull_mode = BaseMaterial3D.CULL_DISABLED
		_adhesive_material.render_priority = 2
	_sync_texture()
	_rebuild(0.0,Vector3.ZERO,0.0)

func _sync_texture() -> void:
	if _front_material != null and _print != null:
		_front_material.set_shader_parameter("print_texture",_print.get_texture())

func _rebuild(progress: float, drag_delta: Vector3, release_settle_alpha: float = 0.0) -> void:
	if _visual == null or _label == null or _cup == null or not (_cup.mesh is CylinderMesh):
		return
	var cup_mesh := _cup.mesh as CylinderMesh
	var visual_progress := maxf(visual_progress_for_gameplay(progress),0.012)
	var threshold := _area_threshold(visual_progress)
	var full_release := progress >= 0.999
	var safe_drag := drag_delta
	var max_drag := maxf(_label.label_width*0.24,0.10)
	if safe_drag.length()>max_drag:
		safe_drag = safe_drag.normalized()*max_drag
	if progress<=0.001 and safe_drag.length_squared()<0.000001:
		safe_drag = Vector3(0.014,0.006,0.022)
	elif full_release and safe_drag.length()<0.075:
		safe_drag = Vector3(0.10,0.025,0.085)

	var settle_t := clampf(release_settle_alpha,0.0,1.0)
	var settle_eased := settle_t*settle_t*(3.0-2.0*settle_t)
	# Once fully released, acknowledge the clean peel briefly, then move the
	# physical sheet into a lower-left discard/collection direction instead of
	# leaving it floating forever in front of the hero product.
	var settle_offset := Vector3(-0.34*settle_eased,-0.56*settle_eased,0.12*settle_eased)

	var corner_y := _label.label_y+_label.label_height*0.5
	var corner_attached := CupSurface.attached_point_on_frustum(1.0,_label.label_width,corner_y,cup_mesh.bottom_radius,cup_mesh.top_radius,cup_mesh.height,_cup.position.y,SURFACE_OFFSET)
	var corner_normal := CupSurface.frustum_surface_normal(corner_attached,cup_mesh.bottom_radius,cup_mesh.top_radius,cup_mesh.height)
	var tangent_axis := Vector3(corner_normal.z,0.0,-corner_normal.x).normalized()
	if tangent_axis.length_squared()<0.000001:
		tangent_axis = Vector3.RIGHT
	var free_normal := corner_normal
	var lift_distance := 0.020+progress*0.070

	var base_positions := PackedVector3Array()
	var flap_positions := PackedVector3Array()
	var back_positions := PackedVector3Array()
	var adhesive_positions := PackedVector3Array()
	var base_normals := PackedVector3Array()
	var flap_normals := PackedVector3Array()
	var back_normals := PackedVector3Array()
	var adhesive_normals := PackedVector3Array()
	var uvs := PackedVector2Array()

	for v_index in range(V_SEGMENTS+1):
		var v := float(v_index)/float(V_SEGMENTS)
		var y := _label.label_y-_label.label_height*0.5+_label.label_height*v
		for u_index in range(U_SEGMENTS+1):
			var u := float(u_index)/float(U_SEGMENTS)
			var attached := CupSurface.attached_point_on_frustum(u,_label.label_width,y,cup_mesh.bottom_radius,cup_mesh.top_radius,cup_mesh.height,_cup.position.y,SURFACE_OFFSET)
			var outward := CupSurface.frustum_surface_normal(attached,cup_mesh.bottom_radius,cup_mesh.top_radius,cup_mesh.height)
			var edge_variation := 0.018*sin(v*17.0+u*5.0)+0.009*sin(v*41.0)
			var d := (1.0-u)+(1.0-v)+edge_variation
			var depth := clampf((threshold-d)/maxf(threshold,0.001),0.0,1.0)
			var band_t := clampf(depth/_bend_band_ratio,0.0,1.0)
			var rigid_weight := band_t*band_t*(3.0-2.0*band_t)
			if full_release:
				rigid_weight = 1.0
			var flat_reference := corner_attached+tangent_axis*((u-1.0)*_label.label_width)+Vector3.UP*((v-1.0)*_label.label_height)
			var free_target := flat_reference+safe_drag+free_normal*lift_distance+Vector3.UP*(progress*0.010)
			if full_release:
				free_target += settle_offset
			var moved := attached.lerp(free_target,rigid_weight)
			var flap_normal := outward.lerp(free_normal,rigid_weight).normalized()
			base_positions.append(attached)
			flap_positions.append(moved)
			back_positions.append(moved-flap_normal*_backing_thickness)
			adhesive_positions.append(attached+outward*0.0015)
			base_normals.append(outward)
			flap_normals.append(flap_normal)
			back_normals.append(-flap_normal)
			adhesive_normals.append(outward)
			uvs.append(Vector2(u,1.0-v))

	var base_indices := PackedInt32Array()
	var flap_indices := PackedInt32Array()
	var row := U_SEGMENTS+1
	for v_index in range(V_SEGMENTS):
		var center_v := (float(v_index)+0.5)/float(V_SEGMENTS)
		for u_index in range(U_SEGMENTS):
			var center_u := (float(u_index)+0.5)/float(U_SEGMENTS)
			var edge_variation := 0.018*sin(center_v*17.0+center_u*5.0)+0.009*sin(center_v*41.0)
			var center_d := (1.0-center_u)+(1.0-center_v)+edge_variation
			var target := flap_indices if full_release or center_d<threshold else base_indices
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
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,_arrays(back_positions,back_normals,uvs,_reversed_indices(flap_indices)))
		mesh.surface_set_material(mesh.get_surface_count()-1,_back_material)
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,_arrays(adhesive_positions,adhesive_normals,uvs,flap_indices))
		mesh.surface_set_material(mesh.get_surface_count()-1,_adhesive_material)
	_visual.mesh = mesh
	var corner_index := V_SEGMENTS*(U_SEGMENTS+1)+U_SEGMENTS
	_visual_grip_local = flap_positions[corner_index]

func _reversed_indices(source: PackedInt32Array) -> PackedInt32Array:
	var reversed := PackedInt32Array()
	for i in range(0,source.size(),3):
		if i+2 >= source.size(): break
		reversed.append(source[i]); reversed.append(source[i+2]); reversed.append(source[i+1])
	return reversed

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
	if p<=0.5: return sqrt(2.0*p)
	return 2.0-sqrt(2.0*(1.0-p))
