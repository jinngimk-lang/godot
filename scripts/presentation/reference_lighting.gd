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
				"key_color":Color(0.91,0.96,1.0),"key_energy":0.88,"key_rotation":Vector3(-34,-18,0),
				"fill_color":Color(0.84,0.92,1.0),"fill_energy":0.76,"fill_position":Vector3(-1.65,1.80,2.25),
				"rim_color":Color(0.72,0.89,1.0),"rim_energy":0.52,"rim_position":Vector3(1.55,1.45,-0.65),
				"ambient_color":Color(0.76,0.84,0.90),"ambient_energy":0.60
			}
		"market_can":
			return {
				"key_color":Color(1.0,0.995,0.985),"key_energy":1.15,"key_rotation":Vector3(-22,8,0),
				"fill_color":Color(0.975,0.980,0.995),"fill_energy":1.05,"fill_position":Vector3(-1.05,1.40,1.85),
				"rim_color":Color(1.0,0.72,0.43),"rim_energy":0.44,"rim_position":Vector3(1.60,1.30,-0.62),
				"ambient_color":Color(0.34,0.31,0.28),"ambient_energy":0.22
			}
		"pantry_jar":
			return {
				"key_color":Color(1.0,0.88,0.72),"key_energy":0.77,"key_rotation":Vector3(-40,-22,0),
				"fill_color":Color(0.94,0.80,0.68),"fill_energy":0.60,"fill_position":Vector3(-1.65,1.45,2.1),
				"rim_color":Color(1.0,0.58,0.32),"rim_energy":0.35,"rim_position":Vector3(1.40,1.25,-0.70),
				"ambient_color":Color(0.48,0.36,0.27),"ambient_energy":0.43
			}
		"pantry_tin":
			return {
				"key_color":Color(1.0,0.985,0.955),"key_energy":1.16,"key_rotation":Vector3(-26,-12,0),
				"fill_color":Color(0.965,0.965,0.950),"fill_energy":1.10,"fill_position":Vector3(-1.00,1.45,1.80),
				"rim_color":Color(0.98,0.83,0.62),"rim_energy":0.36,"rim_position":Vector3(1.50,1.20,-0.55),
				"ambient_color":Color(0.38,0.36,0.33),"ambient_energy":0.28
			}
		_:
			return {
				"key_color":Color(1.0,0.965,0.91),"key_energy":0.80,"key_rotation":Vector3(-38,-24,0),
				"fill_color":Color(0.92,0.965,1.0),"fill_energy":0.68,"fill_position":Vector3(-1.8,1.7,2.2),
				"rim_color":Color(1.0,0.80,0.61),"rim_energy":0.34,"rim_position":Vector3(1.65,1.40,-0.85),
				"ambient_color":Color(0.54,0.48,0.41),"ambient_energy":0.42
			}

func _apply(root: Node, venue_id: String) -> void:
	var key := root.get_node_or_null("KeyLight") as DirectionalLight3D
	var fill := root.get_node_or_null("FillLight") as OmniLight3D
	var rim := root.get_node_or_null("RimLight") as OmniLight3D
	var venue := root.get_node_or_null("VenuePresentation") as Node3D
	var world := venue.get_node_or_null("ReferenceEnvironment") as WorldEnvironment if venue != null else null
	var contract := lighting_contract_for_venue(venue_id)
	if key != null:
		key.rotation_degrees = contract.get("key_rotation",key.rotation_degrees) as Vector3
	if fill != null:
		fill.position = contract.get("fill_position",fill.position) as Vector3
	if rim != null:
		rim.position = contract.get("rim_position",rim.position) as Vector3
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
