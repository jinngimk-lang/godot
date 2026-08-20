extends Node
class_name TableSurfacePresentation

var _active_id := ""
var _shader: Shader
var _table: MeshInstance3D
var _active_material: ShaderMaterial

func _ready() -> void:
	_shader = load("res://art/shaders/reference_table.gdshader") as Shader

func _exit_tree() -> void:
	release_table_resources()

func release_table_resources() -> void:
	# Runtime venue switching creates per-profile ShaderMaterials. Detach the
	# renderer-owned resource explicitly before scene shutdown so the final table
	# material cannot survive the five-scene capture process exit.
	if is_instance_valid(_table):
		_table.material_override = null
	_active_material = null
	_shader = null
	_table = null
	_active_id = ""

func profile_parameters(profile_id: String) -> Dictionary:
	match profile_id:
		"pantry_jar":
			return {
				"base_color": Vector3(0.74,0.69,0.61),
				"roughness_value": 0.43,
				"grain_strength": 0.030,
				"grain_scale": 25.0,
				"stone_mode": 1.0,
				"grain_bump_strength": 0.018,
				"surface_alpha": 1.0,
				"plank_count": 1.0,
				"plank_contrast": 0.0,
				"specular_variation": 0.025
			}
		"pantry_tin":
			return {
				"base_color": Vector3(0.43,0.45,0.44),
				"roughness_value": 0.31,
				"grain_strength": 0.020,
				"grain_scale": 34.0,
				"stone_mode": 1.0,
				"grain_bump_strength": 0.018,
				"surface_alpha": 1.0,
				"plank_count": 1.0,
				"plank_contrast": 0.0,
				"specular_variation": 0.030
			}
		"market_coldcase":
			return {
				"base_color": Vector3(0.79,0.80,0.77),
				"roughness_value": 0.30,
				"grain_strength": 0.016,
				"grain_scale": 18.0,
				"stone_mode": 1.0,
				"grain_bump_strength": 0.018,
				"surface_alpha": 1.0,
				"plank_count": 1.0,
				"plank_contrast": 0.0,
				"specular_variation": 0.028
			}
		"market_can":
			# Direct Can target uses a warm, slightly polished stone/concrete service
			# counter under the cold silver can. Keep it distinct from both Coffee
			# walnut and Supermarket's pale refrigerated counter.
			return {
				"base_color": Vector3(0.43,0.35,0.27),
				"roughness_value": 0.32,
				"grain_strength": 0.030,
				"grain_scale": 24.0,
				"stone_mode": 1.0,
				"grain_bump_strength": 0.026,
				"surface_alpha": 1.0,
				"plank_count": 1.0,
				"plank_contrast": 0.0,
				"specular_variation": 0.055
			}
		_:
			return {
				"base_color": Vector3(0.31,0.128,0.041),
				"roughness_value": 0.29,
				"grain_strength": 0.29,
				"grain_scale": 72.0,
				"stone_mode": 0.0,
				"grain_bump_strength": 0.055,
				"surface_alpha": 1.0,
				"plank_count": 6.0,
				"plank_contrast": 0.13,
				"specular_variation": 0.11
			}

func _process(_delta: float) -> void:
	var root := get_parent()
	if root == null:
		return
	var venue := root.get_node_or_null("VenuePresentation")
	var table := root.get_node_or_null("Table") as MeshInstance3D
	if venue == null or table == null or not venue.has_method("get_active_profile_id"):
		return
	_table = table
	var next_id := String(venue.call("get_active_profile_id"))
	table.visible = true
	if table.mesh is BoxMesh:
		var box := table.mesh as BoxMesh
		box.size = Vector3(5.8,0.12,3.5)
	table.position = Vector3(0.0,-0.73,0.18)
	if _shader == null:
		return
	var material_is_current := _active_material != null and table.material_override == _active_material
	if next_id == _active_id and material_is_current:
		return
	_active_id = next_id
	table.material_override = null
	_active_material = null
	var mat := ShaderMaterial.new()
	mat.shader = _shader
	var parameters := profile_parameters(next_id)
	for parameter_name in parameters:
		mat.set_shader_parameter(StringName(parameter_name),parameters[parameter_name])
	_active_material = mat
	table.material_override = _active_material
