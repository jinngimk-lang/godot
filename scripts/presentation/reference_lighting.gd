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

func lighting_contract_for_venue(venue_id: String) -> Dictionary:
	match venue_id:
		"market_coldcase":
			return {
				"key_color":Color(0.91,0.96,1.0),"key_energy":0.88,
				"fill_color":Color(0.84,0.92,1.0),"fill_energy":0.76,
				"rim_color":Color(0.72,0.89,1.0),"rim_energy":0.52,
				"ambient_color":Color(0.76,0.84,0.90),"ambient_energy":0.60
			}
		"market_can":
			# Warm convenience-counter practicals. The former cold blue lighting
			# overrode VenuePresentation and repainted neutral aluminum cyan.
			return {
				"key_color":Color(1.0,0.91,0.79),"key_energy":0.84,
				"fill_color":Color(0.95,0.86,0.74),"fill_energy":0.58,
				"rim_color":Color(1.0,0.68,0.38),"rim_energy":0.58,
				"ambient_color":Color(0.48,0.36,0.26),"ambient_energy":0.46
			}
		"pantry_jar":
			return {
				"key_color":Color(1.0,0.88,0.72),"key_energy":0.77,
				"fill_color":Color(0.94,0.80,0.68),"fill_energy":0.60,
				"rim_color":Color(1.0,0.58,0.32),"rim_energy":0.35,
				"ambient_color":Color(0.48,0.36,0.27),"ambient_energy":0.43
			}
		"pantry_tin":
			return {
				"key_color":Color(0.96,0.91,0.82),"key_energy":0.86,
				"fill_color":Color(0.82,0.84,0.83),"fill_energy":0.68,
				"rim_color":Color(0.93,0.72,0.48),"rim_energy":0.40,
				"ambient_color":Color(0.49,0.47,0.43),"ambient_energy":0.50
			}
		_:
			return {
				"key_color":Color(1.0,0.965,0.91),"key_energy":0.80,
				"fill_color":Color(0.92,0.965,1.0),"fill_energy":0.68,
				"rim_color":Color(1.0,0.80,0.61),"rim_energy":0.34,
				"ambient_color":Color(0.54,0.48,0.41),"ambient_energy":0.42
			}

func _apply(root: Node, venue_id: String) -> void:
	var key := root.get_node_or_null("KeyLight") as DirectionalLight3D
	var fill := root.get_node_or_null("FillLight") as OmniLight3D
	var rim := root.get_node_or_null("RimLight") as OmniLight3D
	var venue := root.get_node_or_null("VenuePresentation") as Node3D
	var world := venue.get_node_or_null("ReferenceEnvironment") as WorldEnvironment if venue != null else null
	var contract := lighting_contract_for_venue(venue_id)
	_set_light(key,contract.get("key_color",Color.WHITE),float(contract.get("key_energy",0.8)))
	_set_light(fill,contract.get("fill_color",Color.WHITE),float(contract.get("fill_energy",0.6)))
	_set_light(rim,contract.get("rim_color",Color.WHITE),float(contract.get("rim_energy",0.4)))
	_set_ambient(world,contract.get("ambient_color",Color(0.5,0.5,0.5)),float(contract.get("ambient_energy",0.5)))

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
