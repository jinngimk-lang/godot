extends Node
class_name ReferenceLighting

var _active_id := ""

func _process(_delta: float) -> void:
	var root := get_parent()
	if root == null:
		return
	var venue := root.get_node_or_null("VenuePresentation")
	if venue == null or not venue.has_method("get_active_profile_id"):
		return
	var next_id := String(venue.call("get_active_profile_id"))
	_active_id = next_id
	_apply(root,next_id)

func _apply(root: Node, venue_id: String) -> void:
	var key := root.get_node_or_null("KeyLight") as DirectionalLight3D
	var fill := root.get_node_or_null("FillLight") as OmniLight3D
	var rim := root.get_node_or_null("RimLight") as OmniLight3D
	var venue := root.get_node_or_null("VenuePresentation") as Node3D
	var world := venue.get_node_or_null("ReferenceEnvironment") as WorldEnvironment if venue != null else null

	match venue_id:
		"market_coldcase":
			_set_light(key,Color(0.91,0.96,1.0),0.88)
			_set_light(fill,Color(0.84,0.92,1.0),0.76)
			_set_light(rim,Color(0.72,0.89,1.0),0.52)
			_set_ambient(world,Color(0.76,0.84,0.90),0.60)
		"market_can":
			_set_light(key,Color(0.86,0.95,1.0),0.84)
			_set_light(fill,Color(0.72,0.88,0.96),0.58)
			_set_light(rim,Color(0.54,0.86,1.0),0.64)
			_set_ambient(world,Color(0.60,0.76,0.84),0.50)
		"pantry_jar":
			_set_light(key,Color(1.0,0.88,0.72),0.77)
			_set_light(fill,Color(0.94,0.80,0.68),0.60)
			_set_light(rim,Color(1.0,0.58,0.32),0.35)
			_set_ambient(world,Color(0.48,0.36,0.27),0.43)
		"pantry_tin":
			_set_light(key,Color(0.96,0.91,0.82),0.86)
			_set_light(fill,Color(0.82,0.84,0.83),0.68)
			_set_light(rim,Color(0.93,0.72,0.48),0.40)
			_set_ambient(world,Color(0.49,0.47,0.43),0.50)
		_:
			_set_light(key,Color(1.0,0.965,0.91),0.80)
			_set_light(fill,Color(0.92,0.965,1.0),0.68)
			_set_light(rim,Color(1.0,0.80,0.61),0.34)
			_set_ambient(world,Color(0.54,0.48,0.41),0.42)

func _set_light(light: Light3D, color: Color, energy: float) -> void:
	if light == null:
		return
	light.light_color = color
	light.light_energy = energy

func _set_ambient(world: WorldEnvironment, color: Color, energy: float) -> void:
	if world == null or world.environment == null:
		return
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = color
	world.environment.ambient_light_energy = energy
