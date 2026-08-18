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

func peel_side() -> String:
	return "left"

func peel_front_u_for_progress(progress: float) -> float:
	return visual_progress_for_gameplay(progress)

func get_visual_grip_world_position() -> Vector3:
	return to_global(_visual_grip_local)

func get_start_edge_world_position() -> Vector3:
	if _label == null or _cup == null or not (_cup.mesh is CylinderMesh):
		return global_position
	var mesh := _cup.mesh as CylinderMesh
	var point := CupSurface.attached_point_on_frustum(0.0,_label.label_width,_label.label_y,mesh.bottom_radius,mesh.top_radius,mesh.height,_cup.position.y,SURFACE_OFFSET)
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
		_adhesive_material.albedo_color = Color(0.80,0.72,0.58,0.24)
		_adhesive_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_adhesive_material.roughness = 0.66
		_adhesive_material.metallic_specular = 0.14
		_adhesive_material.cull_mode = BaseMaterial3D.CULL_DISABLED
		_adhesive_material.render_priority = 2
	_sync_texture()
	_rebuild(0.0,Vector3.ZERO,0.0)

func _sync_texture() -> void:
	if _front_material != null and _print != null:
		_front_material.set_shader_parameter("print_texture",_print.get_texture())

func _row_front_u(base_front: float, v: float) -> float:
	if base_front <= 0.001 or base_front >= 0.999:
		return base_front
	# Subtle torn/bond-front irregularity, not the old diagonal staircase.
	var variation := (sin(v*13.0+0.7)+0.45*sin(v*31.0+1.9))*0.006
	return clampf(base_front+variation,0.0,1.0)

func _smooth01(value: float) -> float:
	var t := clampf(value,0.0,1.0)
	return t*t*(3.0-2.0*t)

func _rebuild(progress: float, drag_delta: Vector3, release_settle_alpha: float = 0.0) -> void:
	if _visual == null or _label == null or _cup == null or not (_cup.mesh is CylinderMesh):
		return
	var cup_mesh := _cup.mesh as CylinderMesh
	var full_release := progress >= 0.999
	var front_base := peel_front_u_for_progress(progress)
	# Keep a barely lifted discoverable lip at rest while preserving the pure
	# progress contract u=0. This is visual affordance only, not gameplay progress.
	var geometry_front_base := 1.0 if full_release else maxf(front_base,0.012)

	var safe_drag := drag_delta
	var max_drag := minf(maxf(_label.label_width*0.10,0.055),0.12)
	if safe_drag.length()>max_drag:
		safe_drag = safe_drag.normalized()*max_drag
	if progress<=0.001 and safe_drag.length_squared()<0.000001:
		safe_drag = Vector3(-0.010,-0.004,0.026)

	var settle_t := clampf(release_settle_alpha,0.0,1.0)
	var settle_eased := _smooth01(settle_t)
	var settle_offset := Vector3(-0.30*settle_eased,-0.52*settle_eased,0.12*settle_eased)

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
		var front_u := _row_front_u(geometry_front_base,v)
		var front_attached := CupSurface.attached_point_on_frustum(front_u,_label.label_width,y,cup_mesh.bottom_radius,cup_mesh.top_radius,cup_mesh.height,_cup.position.y,SURFACE_OFFSET)
		var front_normal := CupSurface.frustum_surface_normal(front_attached,cup_mesh.bottom_radius,cup_mesh.top_radius,cup_mesh.height)
		var tangent := Vector3(front_normal.z,0.0,-front_normal.x).normalized()
		if tangent.length_squared()<0.000001:
			tangent = Vector3.RIGHT
		var drag_outward := clampf(safe_drag.dot(front_normal),-0.008,0.080)
		var drag_tangent := clampf(safe_drag.dot(tangent),-0.035,0.035)
		var drag_vertical := clampf(safe_drag.y,-0.035,0.035)
		var lift_max := 0.050+progress*0.075+maxf(drag_outward,0.0)*0.55
		if full_release:
			front_attached += front_normal*0.095-tangent*0.030+Vector3.UP*0.015+settle_offset

		for u_index in range(U_SEGMENTS+1):
			var u := float(u_index)/float(U_SEGMENTS)
			var attached := CupSurface.attached_point_on_frustum(u,_label.label_width,y,cup_mesh.bottom_radius,cup_mesh.top_radius,cup_mesh.height,_cup.position.y,SURFACE_OFFSET)
			var outward := CupSurface.frustum_surface_normal(attached,cup_mesh.bottom_radius,cup_mesh.top_radius,cup_mesh.height)
			var is_free := full_release or u < front_u
			var moved := attached
			var flap_normal := outward
			if is_free:
				var free_span := maxf(front_u,0.001)
				var free_ratio := clampf((front_u-u)/free_span,0.0,1.0)
				var distance_from_front := maxf(front_u-u,0.0)*_label.label_width
				var bend_width := maxf(_bend_band_ratio*_label.label_width,0.025)
				var bend_weight := _smooth01(distance_from_front/bend_width)
				# Preserve paper width in the tangent plane. Cursor movement changes the
				# lift/pose only within a small bounded range; it cannot stretch the sheet.
				var flat_sheet := front_attached-tangent*distance_from_front
				var cursor_pose := tangent*drag_tangent*free_ratio+Vector3.UP*drag_vertical*free_ratio
				var free_edge_curl := pow(free_ratio,2.2)
				var curl_lift := front_normal*(lift_max*bend_weight+0.055*free_edge_curl)
				var curl_drop := Vector3.DOWN*(_label.label_height*0.16*free_edge_curl)
				moved = flat_sheet+cursor_pose+curl_lift+curl_drop
				flap_normal = front_normal
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
		var front_u := _row_front_u(geometry_front_base,center_v)
		for u_index in range(U_SEGMENTS):
			var center_u := (float(u_index)+0.5)/float(U_SEGMENTS)
			var target := flap_indices if full_release or center_u<front_u else base_indices
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
	# The pointer/hand cursor follows the free LEFT edge around mid-height, matching
	# the approved practical target instead of jumping to the old top-right corner.
	var grip_row := clampi(int(round(float(V_SEGMENTS)*0.42)),0,V_SEGMENTS)
	var grip_index := grip_row*(U_SEGMENTS+1)
	_visual_grip_local = flap_positions[grip_index]

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
