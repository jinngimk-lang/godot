extends Node
class_name TableSurfacePresentation

var _active_id := ""
var _shader: Shader

func _ready() -> void:
	_shader = load("res://art/shaders/reference_table.gdshader") as Shader

func profile_parameters(profile_id: String) -> Dictionary:
	match profile_id:
		"pantry_jar":
			# Target: bright food-prep / pantry counter, not the café/bar wood.
			return {
				"base_color": Vector3(0.74,0.69,0.61),
				"roughness_value": 0.43,
				"grain_strength": 0.030,
				"grain_scale": 25.0,
				"stone_mode": 1.0,
				"grain_bump_strength": 0.018,
				"surface_alpha": 1.0
			}
		"pantry_tin":
			# Neutral brushed/stone grocery worktop gives the tin a manufactured,
			# industrial silhouette instead of another warm café surface.
			return {
				"base_color": Vector3(0.43,0.45,0.44),
				"roughness_value": 0.31,
				"grain_strength": 0.020,
				"grain_scale": 34.0,
				"stone_mode": 1.0,
				"grain_bump_strength": 0.018,
				"surface_alpha": 1.0
			}
		"market_coldcase":
			return {
				"base_color": Vector3(0.79,0.80,0.77),
				"roughness_value": 0.30,
				"grain_strength": 0.016,
				"grain_scale": 18.0,
				"stone_mode": 1.0,
				"grain_bump_strength": 0.018,
				"surface_alpha": 1.0
			}
		"market_can":
			return {
				"base_color": Vector3(0.20,0.25,0.24),
				"roughness_value": 0.28,
				"grain_strength": 0.060,
				"grain_scale": 51.0,
				"stone_mode": 0.0,
				"grain_bump_strength": 0.024,
				"surface_alpha": 1.0
			}
		_:
			# Coffee target: continuous rich walnut plane across the lower frame.
			return {
				"base_color": Vector3(0.30,0.125,0.040),
				"roughness_value": 0.31,
				"grain_strength": 0.24,
				"grain_scale": 66.0,
				"stone_mode": 0.0,
				"grain_bump_strength": 0.046,
				"surface_alpha": 1.0
			}

func _process(_delta: float) -> void:
	var root := get_parent()
	if root == null:
		return
	var venue := root.get_node_or_null("VenuePresentation")
	var table := root.get_node_or_null("Table") as MeshInstance3D
	if venue == null or table == null or not venue.has_method("get_active_profile_id"):
		return
	var next_id := String(venue.call("get_active_profile_id"))
	# The target boards consistently use a real counter/table beneath the hero.
	# Keeping the photographed backdrop all the way to the bottom exposed source-
	# image hands/foreground blobs and made every venue feel like the same plate.
	# Restore the realtime contact surface and tune it per venue instead.
	table.visible = true
	if table.mesh is BoxMesh:
		var box := table.mesh as BoxMesh
		box.size = Vector3(5.8,0.12,3.5)
	table.position = Vector3(0.0,-0.73,0.18)
	if next_id == _active_id or _shader == null:
		return
	_active_id = next_id
	var mat := ShaderMaterial.new()
	mat.shader = _shader
	var parameters := profile_parameters(next_id)
	for parameter_name in parameters:
		mat.set_shader_parameter(StringName(parameter_name),parameters[parameter_name])
	table.material_override = mat
