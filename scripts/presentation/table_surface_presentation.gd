extends Node
class_name TableSurfacePresentation

var _active_id := ""
var _shader: Shader

func _ready() -> void:
	_shader = load("res://art/shaders/reference_table.gdshader") as Shader

func profile_parameters(profile_id: String) -> Dictionary:
	if profile_id in ["market_coldcase","market_can"]:
		return {
			"base_color": Vector3(0.76,0.75,0.71) if profile_id == "market_coldcase" else Vector3(0.42,0.36,0.29),
			"roughness_value": 0.34 if profile_id == "market_coldcase" else 0.32,
			"grain_strength": 0.018 if profile_id == "market_coldcase" else 0.10,
			"grain_scale": 18.0 if profile_id == "market_coldcase" else 55.0,
			"stone_mode": 1.0 if profile_id == "market_coldcase" else 0.0,
			"grain_bump_strength": 0.022 if profile_id == "market_coldcase" else 0.030,
			"surface_alpha": 0.42
		}
	if profile_id in ["pantry_jar","pantry_tin"]:
		return {
			"base_color": Vector3(0.30,0.19,0.10),
			"roughness_value": 0.36,
			"grain_strength": 0.16,
			"grain_scale": 64.0,
			"stone_mode": 0.0,
			"grain_bump_strength": 0.038,
			"surface_alpha": 0.46
		}
	return {
		"base_color": Vector3(0.34,0.15,0.050),
		"roughness_value": 0.30,
		"grain_strength": 0.21,
		"grain_scale": 70.0,
		"stone_mode": 0.0,
		"grain_bump_strength": 0.040,
		"surface_alpha": 0.46
	}

func _process(_delta: float) -> void:
	var root := get_parent()
	if root == null:
		return
	var venue := root.get_node_or_null("VenuePresentation")
	var table := root.get_node_or_null("Table") as MeshInstance3D
	if venue == null or table == null or _shader == null or not venue.has_method("get_active_profile_id"):
		return
	var next_id := String(venue.call("get_active_profile_id"))
	if next_id == _active_id:
		return
	_active_id = next_id
	var mat := ShaderMaterial.new()
	mat.shader = _shader
	var parameters := profile_parameters(next_id)
	for parameter_name in parameters:
		mat.set_shader_parameter(StringName(parameter_name),parameters[parameter_name])
	table.material_override = mat
