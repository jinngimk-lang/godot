extends Node3D
class_name CafePresentation

var _applied := false
var _cup: MeshInstance3D
var _cup_seam: MeshInstance3D
var _cup_base_fold: MeshInstance3D
var _cup_lip_shadow: MeshInstance3D
var _cup_seam_material: StandardMaterial3D
var _cup_base_material: StandardMaterial3D
var _cup_lip_material: StandardMaterial3D
var _cup_base_local := Transform3D.IDENTITY
var _cup_lip_local := Transform3D.IDENTITY
var _last_cup_color := Color(-1.0, -1.0, -1.0, -1.0)

func _ready() -> void:
	# This child becomes ready before PeelLab builds its procedural world.
	# Defer one turn so the parent-created lights/table/lid exist first.
	call_deferred("_apply")

func _process(_delta: float) -> void:
	if not _applied or _cup == null:
		return
	_sync_cup_detail_transform()
	_sync_cup_detail_palette()

func _apply() -> void:
	if _applied:
		return
	_applied = true
	_build_world_environment()
	_build_backdrop()
	_build_cafe_depth_layer()
	_build_lid_detail()
	_build_ground_shadow()
	_build_cup_structure()
	_tune_parent_lighting()
	_tune_parent_surfaces()
	_sync_cup_detail_transform()
	_sync_cup_detail_palette()

func _build_world_environment() -> void:
	var world := WorldEnvironment.new()
	world.name = "WorldEnvironment"
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.25, 0.175, 0.13, 1.0)
	environment.background_energy_multiplier = 0.82
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.58, 0.43, 0.33, 1.0)
	environment.ambient_light_energy = 0.44
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.adjustment_enabled = true
	environment.adjustment_brightness = 1.035
	environment.adjustment_contrast = 1.025
	environment.adjustment_saturation = 0.92
	world.environment = environment
	add_child(world)

func _build_backdrop() -> void:
	# Keep the compatibility renderer, but replace the old flat dark wall with a
	# warm low-frequency café wall. Distant props add depth without competing
	# with the tactile cup/hand foreground.
	var backdrop := MeshInstance3D.new()
	backdrop.name = "Backdrop"
	var wall_mesh := BoxMesh.new()
	wall_mesh.size = Vector3(8.6, 4.2, 0.10)
	backdrop.mesh = wall_mesh
	backdrop.position = Vector3(0.0, 0.72, -1.78)
	backdrop.material_override = _material(Color(0.38, 0.25, 0.19, 1.0), 1.0)
	add_child(backdrop)

	var backsplash := MeshInstance3D.new()
	backsplash.name = "Backsplash"
	var backsplash_mesh := BoxMesh.new()
	backsplash_mesh.size = Vector3(8.62, 0.56, 0.055)
	backsplash.mesh = backsplash_mesh
	backsplash.position = Vector3(0.0, -0.28, -1.705)
	backsplash.material_override = _material(Color(0.46, 0.31, 0.225, 1.0), 0.94)
	add_child(backsplash)

func _build_cafe_depth_layer() -> void:
	var window := MeshInstance3D.new()
	window.name = "WindowGlow"
	var window_mesh := BoxMesh.new()
	window_mesh.size = Vector3(2.05, 1.42, 0.035)
	window.mesh = window_mesh
	window.position = Vector3(-2.25, 0.92, -1.69)
	window.material_override = _unshaded_material(Color(0.78, 0.61, 0.42, 1.0))
	add_child(window)

	for x_offset in [-0.53, 0.53]:
		var mullion := MeshInstance3D.new()
		mullion.name = "WindowMullion"
		var mullion_mesh := BoxMesh.new()
		mullion_mesh.size = Vector3(0.035, 1.40, 0.028)
		mullion.mesh = mullion_mesh
		mullion.position = window.position + Vector3(x_offset, 0.0, 0.025)
		mullion.material_override = _material(Color(0.37, 0.24, 0.18, 1.0), 0.92)
		add_child(mullion)

	var counter := MeshInstance3D.new()
	counter.name = "CafeCounter"
	var counter_mesh := BoxMesh.new()
	counter_mesh.size = Vector3(7.7, 0.48, 0.30)
	counter.mesh = counter_mesh
	counter.position = Vector3(0.0, -0.24, -1.47)
	counter.material_override = _material(Color(0.36, 0.235, 0.17, 1.0), 0.86)
	add_child(counter)

	var shelf := MeshInstance3D.new()
	shelf.name = "BackShelf"
	var shelf_mesh := BoxMesh.new()
	shelf_mesh.size = Vector3(4.7, 0.075, 0.18)
	shelf.mesh = shelf_mesh
	shelf.position = Vector3(0.70, 0.88, -1.51)
	shelf.material_override = _material(Color(0.23, 0.145, 0.105, 1.0), 0.90)
	add_child(shelf)

	var mug := MeshInstance3D.new()
	mug.name = "PropMug"
	var mug_mesh := CylinderMesh.new()
	mug_mesh.top_radius = 0.22
	mug_mesh.bottom_radius = 0.21
	mug_mesh.height = 0.42
	mug.mesh = mug_mesh
	mug.position = Vector3(-1.70, 0.18, -1.29)
	mug.material_override = _material(Color(0.73, 0.61, 0.50, 1.0), 0.88)
	add_child(mug)

	var jar := MeshInstance3D.new()
	jar.name = "PropJar"
	var jar_mesh := CylinderMesh.new()
	jar_mesh.top_radius = 0.19
	jar_mesh.bottom_radius = 0.21
	jar_mesh.height = 0.54
	jar.mesh = jar_mesh
	jar.position = Vector3(1.66, 0.24, -1.31)
	jar.material_override = _material(Color(0.49, 0.35, 0.24, 1.0), 0.78)
	add_child(jar)

	var bokeh_left := Sprite3D.new()
	bokeh_left.name = "BokehWarmLeft"
	bokeh_left.texture = _radial_bokeh_texture(Color(1.0, 0.78, 0.48, 0.30))
	bokeh_left.position = Vector3(-1.15, 1.31, -1.42)
	bokeh_left.pixel_size = 0.012
	bokeh_left.scale = Vector3(1.35, 1.35, 1.0)
	add_child(bokeh_left)

	var bokeh_right := Sprite3D.new()
	bokeh_right.name = "BokehWarmRight"
	bokeh_right.texture = _radial_bokeh_texture(Color(0.86, 0.68, 0.48, 0.22))
	bokeh_right.position = Vector3(2.05, 0.92, -1.43)
	bokeh_right.pixel_size = 0.010
	bokeh_right.scale = Vector3(1.05, 1.05, 1.0)
	add_child(bokeh_right)

func _build_lid_detail() -> void:
	var inset := MeshInstance3D.new()
	inset.name = "LidInset"
	var inset_mesh := CylinderMesh.new()
	inset_mesh.top_radius = 0.445
	inset_mesh.bottom_radius = 0.455
	inset_mesh.height = 0.022
	inset.mesh = inset_mesh
	inset.position = Vector3(0.0, 0.881, 0.0)
	inset.material_override = _material(Color(0.12, 0.105, 0.092, 1.0), 0.52)
	add_child(inset)

	var lid_center := MeshInstance3D.new()
	lid_center.name = "LidCenter"
	var center_mesh := CylinderMesh.new()
	center_mesh.top_radius = 0.315
	center_mesh.bottom_radius = 0.325
	center_mesh.height = 0.012
	lid_center.mesh = center_mesh
	lid_center.position = Vector3(0.0, 0.895, 0.0)
	lid_center.material_override = _material(Color(0.16, 0.14, 0.125, 1.0), 0.48)
	add_child(lid_center)

func _build_ground_shadow() -> void:
	var shadow := MeshInstance3D.new()
	shadow.name = "GroundShadow"
	var shadow_mesh := CylinderMesh.new()
	shadow_mesh.top_radius = 0.66
	shadow_mesh.bottom_radius = 0.66
	shadow_mesh.height = 0.004
	shadow.mesh = shadow_mesh
	shadow.position = Vector3(0.07, -0.635, 0.05)
	shadow.scale = Vector3(1.0, 1.0, 0.60)
	var material := StandardMaterial3D.new()
	material.resource_name = "SoftGroundShadow"
	material.albedo_color = Color(0.08, 0.045, 0.032, 0.24)
	material.roughness = 1.0
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	shadow.material_override = material
	add_child(shadow)

func _build_cup_structure() -> void:
	var parent := get_parent()
	if parent == null:
		return
	_cup = parent.get_node_or_null("Cup") as MeshInstance3D
	if _cup == null or not (_cup.mesh is CylinderMesh):
		_cup = null
		return
	var cup_mesh := _cup.mesh as CylinderMesh
	var height := maxf(cup_mesh.height, 0.001)

	_cup_seam = MeshInstance3D.new()
	_cup_seam.name = "CupPaperSeam"
	_cup_seam.mesh = _build_paper_seam_mesh(cup_mesh)
	_cup_seam_material = _semantic_material("CupPaperSeam", 0.98)
	_cup_seam_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_cup_seam.material_override = _cup_seam_material
	add_child(_cup_seam)

	_cup_base_fold = MeshInstance3D.new()
	_cup_base_fold.name = "CupBaseFold"
	var fold_mesh := CylinderMesh.new()
	var fold_y := -height * 0.5 + 0.045
	var fold_t := clampf((fold_y + height * 0.5) / height, 0.0, 1.0)
	var fold_radius := lerpf(cup_mesh.bottom_radius, cup_mesh.top_radius, fold_t)
	fold_mesh.bottom_radius = fold_radius + 0.003
	fold_mesh.top_radius = fold_radius + 0.004
	fold_mesh.height = 0.024
	_cup_base_fold.mesh = fold_mesh
	_cup_base_material = _semantic_material("CupBaseFold", 1.0)
	_cup_base_fold.material_override = _cup_base_material
	_cup_base_local = Transform3D(Basis.IDENTITY, Vector3(0.0, fold_y, 0.0))
	add_child(_cup_base_fold)

	_cup_lip_shadow = MeshInstance3D.new()
	_cup_lip_shadow.name = "CupLipShadow"
	var lip_mesh := CylinderMesh.new()
	lip_mesh.bottom_radius = cup_mesh.top_radius + 0.008
	lip_mesh.top_radius = cup_mesh.top_radius + 0.010
	lip_mesh.height = 0.018
	_cup_lip_shadow.mesh = lip_mesh
	_cup_lip_material = _semantic_material("CupLipShadow", 1.0)
	_cup_lip_shadow.material_override = _cup_lip_material
	_cup_lip_local = Transform3D(Basis.IDENTITY, Vector3(0.0, height * 0.5 - 0.009, 0.0))
	add_child(_cup_lip_shadow)

func _build_paper_seam_mesh(cup_mesh: CylinderMesh) -> ArrayMesh:
	var height := maxf(cup_mesh.height, 0.001)
	var lower_y := -height * 0.42
	var upper_y := height * 0.42
	var seam_angle := 1.28
	var half_width_angle := 0.011
	var lower_t := clampf((lower_y + height * 0.5) / height, 0.0, 1.0)
	var upper_t := clampf((upper_y + height * 0.5) / height, 0.0, 1.0)
	var lower_radius := lerpf(cup_mesh.bottom_radius, cup_mesh.top_radius, lower_t) + 0.0035
	var upper_radius := lerpf(cup_mesh.bottom_radius, cup_mesh.top_radius, upper_t) + 0.0035
	var left_angle := seam_angle - half_width_angle
	var right_angle := seam_angle + half_width_angle
	var vertices := PackedVector3Array([
		Vector3(sin(left_angle) * lower_radius, lower_y, cos(left_angle) * lower_radius),
		Vector3(sin(right_angle) * lower_radius, lower_y, cos(right_angle) * lower_radius),
		Vector3(sin(left_angle) * upper_radius, upper_y, cos(left_angle) * upper_radius),
		Vector3(sin(right_angle) * upper_radius, upper_y, cos(right_angle) * upper_radius),
	])
	var slope := (cup_mesh.top_radius - cup_mesh.bottom_radius) / height
	var outward := Vector3(sin(seam_angle), -slope, cos(seam_angle)).normalized()
	var normals := PackedVector3Array([outward, outward, outward, outward])
	var indices := PackedInt32Array([0, 1, 2, 1, 3, 2])
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

func _sync_cup_detail_transform() -> void:
	if _cup == null:
		return
	var cup_in_presentation := global_transform.affine_inverse() * _cup.global_transform
	if _cup_seam != null:
		_cup_seam.transform = cup_in_presentation
	if _cup_base_fold != null:
		_cup_base_fold.transform = cup_in_presentation * _cup_base_local
	if _cup_lip_shadow != null:
		_cup_lip_shadow.transform = cup_in_presentation * _cup_lip_local

func _sync_cup_detail_palette() -> void:
	if _cup == null or not (_cup.material_override is StandardMaterial3D):
		return
	var cup_material := _cup.material_override as StandardMaterial3D
	var cup_color := cup_material.albedo_color
	if cup_color.is_equal_approx(_last_cup_color):
		return
	_last_cup_color = cup_color
	if _cup_seam_material != null:
		_cup_seam_material.albedo_color = _scaled_color(cup_color, 0.78)
	if _cup_base_material != null:
		_cup_base_material.albedo_color = _scaled_color(cup_color, 0.74)
	if _cup_lip_material != null:
		_cup_lip_material.albedo_color = _scaled_color(cup_color, 0.55)

func _scaled_color(color: Color, scale: float) -> Color:
	return Color(
		clampf(color.r * scale, 0.0, 1.0),
		clampf(color.g * scale, 0.0, 1.0),
		clampf(color.b * scale, 0.0, 1.0),
		color.a
	)

func _tune_parent_lighting() -> void:
	var parent := get_parent()
	if parent == null:
		return
	var key := parent.get_node_or_null("KeyLight") as DirectionalLight3D
	if key != null:
		key.light_energy = 0.84
		key.light_color = Color(1.0, 0.88, 0.78, 1.0)
		key.shadow_enabled = false
	var fill := parent.get_node_or_null("FillLight") as OmniLight3D
	if fill != null:
		fill.light_energy = 0.78
		fill.light_color = Color(1.0, 0.85, 0.74, 1.0)
		fill.omni_range = 5.4
	var rim := parent.get_node_or_null("RimLight") as OmniLight3D
	if rim != null:
		rim.light_energy = 0.30
		rim.light_color = Color(0.82, 0.86, 1.0, 1.0)
		rim.omni_range = 4.2

func _tune_parent_surfaces() -> void:
	var parent := get_parent()
	if parent == null:
		return
	var table := parent.get_node_or_null("Table") as MeshInstance3D
	if table != null:
		table.material_override = _material(Color(0.50, 0.36, 0.255, 1.0), 0.86)
	var lid := parent.get_node_or_null("Lid") as MeshInstance3D
	if lid != null:
		lid.material_override = _material(Color(0.085, 0.075, 0.067, 1.0), 0.60)

func _radial_bokeh_texture(color: Color) -> Texture2D:
	var size := 64
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(float(size - 1) * 0.5, float(size - 1) * 0.5)
	var radius := float(size) * 0.5
	for y in range(size):
		for x in range(size):
			var distance := Vector2(float(x), float(y)).distance_to(center) / radius
			var falloff := pow(clampf(1.0 - distance, 0.0, 1.0), 2.35)
			image.set_pixel(x, y, Color(color.r, color.g, color.b, color.a * falloff))
	return ImageTexture.create_from_image(image)

func _semantic_material(resource_name: String, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.resource_name = resource_name
	material.roughness = roughness
	return material

func _material(color: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material

func _unshaded_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return material
