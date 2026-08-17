extends Node
class_name TableSurfacePresentation

var _active_id := ""
var _shader: Shader

func _ready() -> void:
	_shader = load("res://art/shaders/reference_table.gdshader") as Shader

func profile_parameters(profile_id: String) -> Dictionary:
	if profile_id == "night_bar":
		return {
			"base_color": Vector3(0.105,0.045,0.018),
			"roughness_value": 0.23,
			"grain_strength": 0.16,
			"grain_scale": 72.0,
			"stone_mode": 0.0,
			"grain_bump_strength": 0.034
		}
	if profile_id == "market_coldcase":
		return {
			"base_color": Vector3(0.72,0.71,0.67),
			"roughness_value": 0.38,
			"grain_strength": 0.018,
			"grain_scale": 18.0,
			"stone_mode": 1.0,
			"grain_bump_strength": 0.024
		}
	return {
		"base_color": Vector3(0.26,0.105,0.035),
		"roughness_value": 0.40,
		"grain_strength": 0.12,
		"grain_scale": 58.0,
		"stone_mode": 0.0,
		"grain_bump_strength": 0.044
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
