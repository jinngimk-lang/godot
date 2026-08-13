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
	_tune_parent_lighting()
	_tune_parent_surfaces()

func _build_world_environment() -> void:
	var world := WorldEnvironment.new()
	world.name = "WorldEnvironment"
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.032, 0.023, 0.020, 1.0)
	environment.background_energy_multiplier = 0.72
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.42, 0.31, 0.24, 1.0)
	environment.ambient_light_energy = 0.32
	world.environment = environment
	add_child(world)

func _build_backdrop() -> void:
	var backdrop := MeshInstance3D.new()
	backdrop.name = "Backdrop"
	var wall_mesh := BoxMesh.new()
	wall_mesh.size = Vector3(5.8, 3.4, 0.10)
	backdrop.mesh = wall_mesh
	backdrop.position = Vector3(0.0, 0.72, -1.52)
	backdrop.material_override = _material(Color(0.105, 0.074, 0.060, 1.0), 1.0)
	add_child(backdrop)

	# A low horizontal value change gives the backdrop a cafe-counter read
	# without introducing branded signage or distracting decoration.
	var backsplash := MeshInstance3D.new()
	backsplash.name = "Backsplash"
	var backsplash_mesh := BoxMesh.new()
	backsplash_mesh.size = Vector3(5.82, 0.48, 0.055)
	backsplash.mesh = backsplash_mesh
	backsplash.position = Vector3(0.0, -0.32, -1.455)
	backsplash.material_override = _material(Color(0.155, 0.108, 0.086, 1.0), 0.94)
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
	inset.material_override = _material(Color(0.105, 0.095, 0.088, 1.0), 0.48)
	add_child(inset)

	var lid_center := MeshInstance3D.new()
	lid_center.name = "LidCenter"
	var center_mesh := CylinderMesh.new()
	center_mesh.top_radius = 0.315
	center_mesh.bottom_radius = 0.325
	center_mesh.height = 0.012
	lid_center.mesh = center_mesh
	lid_center.position = Vector3(0.0, 0.895, 0.0)
	lid_center.material_override = _material(Color(0.135, 0.122, 0.112, 1.0), 0.44)
	add_child(lid_center)

func _tune_parent_lighting() -> void:
	var parent := get_parent()
	if parent == null:
		return
	var key := parent.get_node_or_null("KeyLight") as DirectionalLight3D
	if key != null:
		key.light_energy = 0.72
		key.light_color = Color(1.0, 0.84, 0.70, 1.0)
	var fill := parent.get_node_or_null("FillLight") as OmniLight3D
	if fill != null:
		fill.light_energy = 0.72
		fill.light_color = Color(1.0, 0.78, 0.65, 1.0)
		fill.omni_range = 5.0
	var rim := parent.get_node_or_null("RimLight") as OmniLight3D
	if rim != null:
		rim.light_energy = 0.55
		rim.light_color = Color(0.78, 0.84, 1.0, 1.0)
		rim.omni_range = 4.2

func _tune_parent_surfaces() -> void:
	var parent := get_parent()
	if parent == null:
		return
	var table := parent.get_node_or_null("Table") as MeshInstance3D
	if table != null:
		table.material_override = _material(Color(0.205, 0.145, 0.115, 1.0), 0.90)
	var lid := parent.get_node_or_null("Lid") as MeshInstance3D
	if lid != null:
		lid.material_override = _material(Color(0.075, 0.068, 0.064, 1.0), 0.55)

func _material(color: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material
