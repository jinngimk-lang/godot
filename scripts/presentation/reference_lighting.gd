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

	if venue_id in ["market_coldcase","market_can"]:
		if key != null:
			key.light_color = Color(0.91,0.96,1.0)
			key.light_energy = 0.86 if venue_id == "market_coldcase" else 0.82
		if fill != null:
			fill.light_color = Color(0.84,0.92,1.0)
			fill.light_energy = 0.74
		if rim != null:
			rim.light_color = Color(0.72,0.89,1.0)
			rim.light_energy = 0.50
		_set_ambient(world,Color(0.76,0.84,0.90),0.60)
	elif venue_id in ["pantry_jar","pantry_tin"]:
		if key != null:
			key.light_color = Color(1.0,0.90,0.78)
			key.light_energy = 0.78
		if fill != null:
			fill.light_color = Color(0.94,0.86,0.76)
			fill.light_energy = 0.62
		if rim != null:
			rim.light_color = Color(1.0,0.68,0.42)
			rim.light_energy = 0.36
		_set_ambient(world,Color(0.48,0.39,0.31),0.44)
	else:
		if key != null:
			key.light_color = Color(1.0,0.965,0.91)
			key.light_energy = 0.80
		if fill != null:
			fill.light_color = Color(0.92,0.965,1.0)
			fill.light_energy = 0.68
		if rim != null:
			rim.light_color = Color(1.0,0.80,0.61)
			rim.light_energy = 0.34
		_set_ambient(world,Color(0.54,0.48,0.41),0.42)

func _set_ambient(world: WorldEnvironment, color: Color, energy: float) -> void:
	if world == null or world.environment == null:
		return
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = color
	world.environment.ambient_light_energy = energy
