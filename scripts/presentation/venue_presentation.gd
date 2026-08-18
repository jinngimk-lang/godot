extends Node3D
class_name VenuePresentation

const VALID_IDS := ["cafe_window","pantry_jar","pantry_tin","market_coldcase","market_can"]

var _active_profile_id := "cafe_window"
var _built := false
var _world: WorldEnvironment
var _cafe: Node3D
var _pantry: Node3D
var _market: Node3D

func _ready() -> void:
	_ensure_built()
	apply_profile({"id":"cafe_window"})

func get_active_profile_id() -> String:
	return _active_profile_id

func apply_profile(profile: Dictionary) -> void:
	_ensure_built()
	var requested := String(profile.get("id","cafe_window"))
	if requested not in VALID_IDS:
		requested = "cafe_window"
	_active_profile_id = requested
	_cafe.visible = requested == "cafe_window"
	_pantry.visible = requested in ["pantry_jar","pantry_tin"]
	_market.visible = requested in ["market_coldcase","market_can"]
	_apply_environment()
	_apply_parent_stage(profile)

func _ensure_built() -> void:
	if _built:
		return
	_built = true
	_world = WorldEnvironment.new()
	_world.name = "ReferenceEnvironment"
	add_child(_world)
	_cafe = Node3D.new(); _cafe.name = "CafeWindows"; add_child(_cafe)
	_pantry = Node3D.new(); _pantry.name = "BarBackShelf"; add_child(_pantry)
	_market = Node3D.new(); _market.name = "MarketCooler"; add_child(_market)

func _apply_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	match _active_profile_id:
		"pantry_jar":
			env.background_color = Color(0.34,0.27,0.20)
			env.ambient_light_color = Color(0.93,0.78,0.61)
			env.ambient_light_energy = 0.62
		"pantry_tin":
			env.background_color = Color(0.20,0.20,0.19)
			env.ambient_light_color = Color(0.73,0.73,0.69)
			env.ambient_light_energy = 0.52
		"market_coldcase":
			env.background_color = Color(0.63,0.69,0.72)
			env.ambient_light_color = Color(0.83,0.91,0.98)
			env.ambient_light_energy = 0.76
		"market_can":
			env.background_color = Color(0.24,0.34,0.34)
			env.ambient_light_color = Color(0.69,0.88,0.86)
			env.ambient_light_energy = 0.66
		_:
			env.background_color = Color(0.13,0.085,0.045)
			env.ambient_light_color = Color(0.70,0.47,0.25)
			env.ambient_light_energy = 0.58
	_world.environment = env

func _apply_parent_stage(profile: Dictionary) -> void:
	var parent := get_parent()
	if parent == null:
		return
	var table := parent.get_node_or_null("Table") as MeshInstance3D
	if table != null:
		var table_mat := StandardMaterial3D.new()
		table_mat.albedo_color = Color(profile.get("table_color",Color(0.22,0.115,0.055)))
		table_mat.roughness = clampf(float(profile.get("table_roughness",0.54)),0.05,1.0)
		table.material_override = table_mat

	if _active_profile_id == "cafe_window":
		var cup := parent.get_node_or_null("Cup") as MeshInstance3D
		if cup != null and cup.material_override is ShaderMaterial:
			(cup.material_override as ShaderMaterial).set_shader_parameter("paper_color",Color(0.70,0.58,0.46,1.0))

	var key := parent.get_node_or_null("KeyLight") as DirectionalLight3D
	var fill := parent.get_node_or_null("FillLight") as OmniLight3D
	var rim := parent.get_node_or_null("RimLight") as OmniLight3D
	var base_energy := float(profile.get("light_energy",1.0))
	if key != null:
		key.shadow_enabled = false
	if key == null or fill == null or rim == null:
		return
	match _active_profile_id:
		"pantry_jar":
			key.rotation_degrees = Vector3(-48,-28,0)
			key.light_color = Color(1.0,0.82,0.64)
			key.light_energy = base_energy*0.83
			fill.position = Vector3(-1.65,1.45,2.1)
			fill.light_color = Color(1.0,0.91,0.78)
			fill.light_energy = base_energy*0.72
			rim.position = Vector3(1.40,1.25,-0.70)
			rim.light_color = Color(0.86,0.72,0.54)
			rim.light_energy = base_energy*0.38
		"pantry_tin":
			key.rotation_degrees = Vector3(-52,-18,0)
			key.light_color = Color(0.92,0.92,0.88)
			key.light_energy = base_energy*0.78
			fill.position = Vector3(-1.3,1.55,1.85)
			fill.light_color = Color(0.78,0.82,0.84)
			fill.light_energy = base_energy*0.60
			rim.position = Vector3(1.55,1.15,-0.55)
			rim.light_color = Color(1.0,0.78,0.52)
			rim.light_energy = base_energy*0.52
		"market_coldcase":
			key.rotation_degrees = Vector3(-44,-30,0)
			key.light_color = Color(0.90,0.96,1.0)
			key.light_energy = base_energy*0.92
			fill.position = Vector3(-1.65,1.80,2.25)
			fill.light_color = Color(0.82,0.94,1.0)
			fill.light_energy = base_energy*0.82
			rim.position = Vector3(1.55,1.45,-0.65)
			rim.light_color = Color(0.72,0.91,1.0)
			rim.light_energy = base_energy*0.58
		"market_can":
			key.rotation_degrees = Vector3(-40,-40,0)
			key.light_color = Color(0.86,1.0,0.95)
			key.light_energy = base_energy*0.88
			fill.position = Vector3(-1.8,1.65,2.0)
			fill.light_color = Color(0.65,0.91,0.90)
			fill.light_energy = base_energy*0.72
			rim.position = Vector3(1.7,1.30,-0.7)
			rim.light_color = Color(0.42,0.90,0.90)
			rim.light_energy = base_energy*0.66
		_:
			key.rotation_degrees = Vector3(-47,-34,0)
			key.light_color = Color(1.0,0.76,0.47)
			key.light_energy = base_energy*0.82
			fill.position = Vector3(-1.8,1.7,2.2)
			fill.light_color = Color(1.0,0.87,0.66)
			fill.light_energy = base_energy*0.68
			rim.position = Vector3(1.65,1.40,-0.85)
			rim.light_color = Color(1.0,0.58,0.26)
			rim.light_energy = base_energy*0.48
