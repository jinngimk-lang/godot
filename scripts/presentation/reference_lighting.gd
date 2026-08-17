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
	# VenuePresentation owns semantic scene switching and can be reapplied by the
	# gameplay parent after child _ready(). Lighting is the final presentation
	# authority, so reassert the small three-light profile instead of allowing
	# that later venue write to leave the hero product permanently orange.
	_apply(root,next_id)

func _apply(root: Node, venue_id: String) -> void:
	var key := root.get_node_or_null("KeyLight") as DirectionalLight3D
	var fill := root.get_node_or_null("FillLight") as OmniLight3D
	var rim := root.get_node_or_null("RimLight") as OmniLight3D
	var venue := root.get_node_or_null("VenuePresentation") as Node3D
	var world := venue.get_node_or_null("ReferenceEnvironment") as WorldEnvironment if venue != null else null

	if venue_id == "night_bar":
		if key != null:
			key.light_color = Color(1.0,0.76,0.58)
			key.light_energy = 0.70
		if fill != null:
			fill.light_color = Color(0.92,0.60,0.42)
			fill.light_energy = 0.58
		if rim != null:
			rim.light_color = Color(1.0,0.46,0.20)
			rim.light_energy = 0.62
		_set_ambient(world,Color(0.23,0.12,0.075),0.34)
	elif venue_id == "market_coldcase":
		if key != null:
			key.light_color = Color(0.90,0.96,1.0)
			key.light_energy = 0.84
		if fill != null:
			fill.light_color = Color(0.82,0.91,1.0)
			fill.light_energy = 0.72
		if rim != null:
			rim.light_color = Color(0.68,0.88,1.0)
			rim.light_energy = 0.48
		_set_ambient(world,Color(0.75,0.84,0.90),0.60)
	else:
		# cafe_v1 is warm because of the room and table, but the hero cup sits
		# beside a large daylight window. Keep the foreground key/fill close to
		# neutral so white paper and skin do not turn prototype orange.
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
