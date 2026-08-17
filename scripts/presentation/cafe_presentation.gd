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
	_build_lid_detail()
	_sync_product_paper_details()
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
	var parent := get_parent()
	if parent == null:
		return
	var lid := parent.get_node_or_null("Lid") as MeshInstance3D
	if lid == null or not (lid.mesh is CylinderMesh):
		return
	var lid_mesh := lid.mesh as CylinderMesh
	var base_radius := maxf(lid_mesh.top_radius, 0.10)
	var lid_top_y := lid.position.y + lid_mesh.height * 0.5

	# Build the silhouette from the actual production lid rather than the old
	# fixed world-space dimensions. The outer flare is deliberately shallow:
	# enough to read as molded black plastic at thumbnail scale without turning
	# into a decorative halo.
	var ridge := MeshInstance3D.new()
	ridge.name = "LidOuterRidge"
	var ridge_mesh := CylinderMesh.new()
	ridge_mesh.top_radius = base_radius + 0.016
	ridge_mesh.bottom_radius = base_radius + 0.012
	ridge_mesh.height = 0.026
	ridge_mesh.radial_segments = 64
	ridge.mesh = ridge_mesh
	ridge.position = Vector3(lid.position.x, lid_top_y + 0.004, lid.position.z)
	ridge.material_override = _material(Color(0.050, 0.046, 0.043, 1.0), 0.44)
	add_child(ridge)

	var inset := MeshInstance3D.new()
	inset.name = "LidInset"
	var inset_mesh := CylinderMesh.new()
	inset_mesh.top_radius = base_radius * 0.82
	inset_mesh.bottom_radius = base_radius * 0.84
	inset_mesh.height = 0.022
	inset_mesh.radial_segments = 64
	inset.mesh = inset_mesh
	inset.position = Vector3(lid.position.x, lid_top_y + 0.018, lid.position.z)
	inset.material_override = _material(Color(0.086, 0.078, 0.072, 1.0), 0.50)
	add_child(inset)

	var lid_center := MeshInstance3D.new()
	lid_center.name = "LidCenter"
	var center_mesh := CylinderMesh.new()
	center_mesh.top_radius = base_radius * 0.58
	center_mesh.bottom_radius = base_radius * 0.60
	center_mesh.height = 0.014
	center_mesh.radial_segments = 64
	lid_center.mesh = center_mesh
	lid_center.position = Vector3(lid.position.x, lid_top_y + 0.033, lid.position.z)
	lid_center.material_override = _material(Color(0.115, 0.103, 0.094, 1.0), 0.48)
	add_child(lid_center)

func _sync_product_paper_details() -> void:
	# ProductPresentation owns generic paper construction cues. Once the café
	# cup changes proportion, keep those cues fitted to the real production mesh
	# so a stale wide PaperLip cannot visually mask the black molded lid.
	var parent := get_parent()
	if parent == null:
		return
	var cup := parent.get_node_or_null("Cup") as MeshInstance3D
	var product := parent.get_node_or_null("ProductPresentation") as Node3D
	if cup == null or product == null or not (cup.mesh is CylinderMesh):
		return
	var cup_mesh := cup.mesh as CylinderMesh
	var paper_lip := product.get_node_or_null("CupPaperDetails/PaperLip") as MeshInstance3D
	if paper_lip != null and paper_lip.mesh is CylinderMesh:
		var lip_mesh := paper_lip.mesh as CylinderMesh
		lip_mesh.top_radius = cup_mesh.top_radius + 0.015
		lip_mesh.bottom_radius = cup_mesh.top_radius + 0.012
		paper_lip.position.y = cup.position.y + cup_mesh.height * 0.5 - lip_mesh.height * 0.5
	var paper_base := product.get_node_or_null("CupPaperDetails/PaperBaseFold") as MeshInstance3D
	if paper_base != null and paper_base.mesh is CylinderMesh:
		var base_mesh := paper_base.mesh as CylinderMesh
		base_mesh.top_radius = cup_mesh.bottom_radius + 0.008
		base_mesh.bottom_radius = cup_mesh.bottom_radius + 0.006
		paper_base.position.y = cup.position.y - cup_mesh.height * 0.5 + base_mesh.height * 0.5

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
	# Keep the compressed paper base nearly flush with the cup. A larger lip
	# catches the key light like a plastic/metal trim ring in the close-up.
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
