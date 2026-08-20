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
				"surface_alpha": 1.0,
				"plank_count": 1.0,
				"plank_contrast": 0.0,
				"specular_variation": 0.025
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
			return {
				"base_color": Vector3(0.20,0.25,0.24),
				"roughness_value": 0.28,
				"grain_strength": 0.075,
				"grain_scale": 54.0,
				"stone_mode": 0.0,
				"grain_bump_strength": 0.028,
				"surface_alpha": 1.0,
				"plank_count": 5.0,
				"plank_contrast": 0.070,
				"specular_variation": 0.085
			}
		_:
			# Coffee target: rich walnut with broad plank separation, long grain and
			# highlight breakup. This must read as real foreground wood rather than
			# a flat brown mask over the photographic café plate.
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
