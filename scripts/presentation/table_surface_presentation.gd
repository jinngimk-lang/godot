extends Node
class_name TableSurfacePresentation

var _active_id := ""
var _shader: Shader

func _ready() -> void:
	_shader = load("res://art/shaders/reference_table.gdshader") as Shader

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
	if next_id == "night_bar":
		mat.set_shader_parameter("base_color",Vector3(0.105,0.045,0.018))
		mat.set_shader_parameter("roughness_value",0.23)
		mat.set_shader_parameter("grain_strength",0.20)
		mat.set_shader_parameter("grain_scale",92.0)
		mat.set_shader_parameter("stone_mode",0.0)
	elif next_id == "market_coldcase":
		mat.set_shader_parameter("base_color",Vector3(0.72,0.71,0.67))
		mat.set_shader_parameter("roughness_value",0.36)
		mat.set_shader_parameter("grain_strength",0.03)
		mat.set_shader_parameter("grain_scale",42.0)
		mat.set_shader_parameter("stone_mode",1.0)
	else:
		mat.set_shader_parameter("base_color",Vector3(0.26,0.105,0.035))
		mat.set_shader_parameter("roughness_value",0.40)
		mat.set_shader_parameter("grain_strength",0.16)
		mat.set_shader_parameter("grain_scale",76.0)
		mat.set_shader_parameter("stone_mode",0.0)
	table.material_override = mat
