extends Node3D
class_name CafePresentation

var _applied := false

func _ready() -> void:
	# This child becomes ready before PeelLab builds its procedural world.
	# Defer one turn so the parent-created lights/table/lid exist first.
	call_deferred("_apply")

func _apply() -> void:
	if _applied:
		return
	_applied = true
	_build_world_environment()
	_build_backdrop()
	_build_lid_detail()
	_build_ground_shadow()
	_tune_parent_lighting()
	_tune_parent_surfaces()

func _build_world_environment() -> void:
	var world := WorldEnvironment.new()
	world.name = "WorldEnvironment"
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.026, 0.019, 0.017, 1.0)
	environment.background_energy_multiplier = 0.68
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.39, 0.29, 0.23, 1.0)
	environment.ambient_light_energy = 0.30
	world.environment = environment
	add_child(world)

func _build_backdrop() -> void:
	# Oversize the wall beyond the 1280x720 camera frustum so no black side
	# gutters appear when the close-up camera shifts or aspect ratios vary.
	var backdrop := MeshInstance3D.new()
	backdrop.name = "Backdrop"
	var wall_mesh := BoxMesh.new()
	wall_mesh.size = Vector3(8.6, 4.2, 0.10)
	backdrop.mesh = wall_mesh
	backdrop.position = Vector3(0.0, 0.72, -1.72)
	backdrop.material_override = _material(Color(0.086, 0.060, 0.050, 1.0), 1.0)
	add_child(backdrop)

	# A quiet lower-value band suggests a café wall/counter transition without
	# signage, branding, props, or high-contrast decoration.
	var backsplash := MeshInstance3D.new()
	backsplash.name = "Backsplash"
	var backsplash_mesh := BoxMesh.new()
	backsplash_mesh.size = Vector3(8.62, 0.42, 0.055)
	backsplash.mesh = backsplash_mesh
	backsplash.position = Vector3(0.0, -0.34, -1.655)
	backsplash.material_override = _material(Color(0.125, 0.087, 0.071, 1.0), 0.96)
	add_child(backsplash)

func _build_lid_detail() -> void:
	var inset := MeshInstance3D.new()
	inset.name = "LidInset"
	var inset_mesh := CylinderMesh.new()
	inset_mesh.top_radius = 0.445
	inset_mesh.bottom_radius = 0.455
	inset_mesh.height = 0.022
	inset.mesh = inset_mesh
	inset.position = Vector3(0.0, 0.881, 0.0)
	inset.material_override = _material(Color(0.105, 0.095, 0.088, 1.0), 0.50)
	add_child(inset)

	var lid_center := MeshInstance3D.new()
	lid_center.name = "LidCenter"
	var center_mesh := CylinderMesh.new()
	center_mesh.top_radius = 0.315
	center_mesh.bottom_radius = 0.325
	center_mesh.height = 0.012
	lid_center.mesh = center_mesh
	lid_center.position = Vector3(0.0, 0.895, 0.0)
	lid_center.material_override = _material(Color(0.145, 0.130, 0.118, 1.0), 0.46)
	add_child(lid_center)

func _build_ground_shadow() -> void:
	# With the hard directional shadow removed, use one controlled translucent
	# ellipse to ground the cup without casting giant hand/forearm diagonals.
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
	material.albedo_color = Color(0.018, 0.012, 0.011, 0.34)
	material.roughness = 1.0
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	shadow.material_override = material
	add_child(shadow)

func _tune_parent_lighting() -> void:
	var parent := get_parent()
	if parent == null:
		return
	var key := parent.get_node_or_null("KeyLight") as DirectionalLight3D
	if key != null:
		key.light_energy = 0.62
		key.light_color = Color(1.0, 0.84, 0.72, 1.0)
		# GL compatibility hard directional shadows looked theatrical and made the
		# long close-up sleeves dominate. Soft grounding is handled explicitly.
		key.shadow_enabled = false
	var fill := parent.get_node_or_null("FillLight") as OmniLight3D
	if fill != null:
		fill.light_energy = 0.62
		fill.light_color = Color(1.0, 0.80, 0.69, 1.0)
		fill.omni_range = 5.0
	var rim := parent.get_node_or_null("RimLight") as OmniLight3D
	if rim != null:
		rim.light_energy = 0.44
		rim.light_color = Color(0.76, 0.82, 1.0, 1.0)
		rim.omni_range = 4.2

func _tune_parent_surfaces() -> void:
	var parent := get_parent()
	if parent == null:
		return
	var table := parent.get_node_or_null("Table") as MeshInstance3D
	if table != null:
		table.material_override = _material(Color(0.185, 0.128, 0.102, 1.0), 0.92)
	var lid := parent.get_node_or_null("Lid") as MeshInstance3D
	if lid != null:
		lid.material_override = _material(Color(0.070, 0.063, 0.059, 1.0), 0.58)

func _material(color: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material
