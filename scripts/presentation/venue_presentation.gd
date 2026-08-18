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
	if _active_profile_id in ["market_coldcase","market_can"]:
		env.background_color = Color(0.62,0.67,0.70)
		env.ambient_light_color = Color(0.78,0.87,0.94)
		env.ambient_light_energy = 0.68
	elif _active_profile_id in ["pantry_jar","pantry_tin"]:
		env.background_color = Color(0.16,0.11,0.075)
		env.ambient_light_color = Color(0.58,0.43,0.31)
		env.ambient_light_energy = 0.50
	else:
		env.background_color = Color(0.13,0.09,0.055)
		env.ambient_light_color = Color(0.64,0.43,0.25)
		env.ambient_light_energy = 0.54
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

	# The approved Coffee Shop mockup uses warm kraft paper, not a nearly white
	# takeaway cup. Apply this after ProductPresentation has created the live paper
	# shader so the order sticker remains the lighter focal surface.
	if _active_profile_id == "cafe_window":
		var cup := parent.get_node_or_null("Cup") as MeshInstance3D
		if cup != null and cup.material_override is ShaderMaterial:
			(cup.material_override as ShaderMaterial).set_shader_parameter("paper_color",Color(0.70,0.58,0.46,1.0))

	var key := parent.get_node_or_null("KeyLight") as DirectionalLight3D
	var fill := parent.get_node_or_null("FillLight") as OmniLight3D
	var rim := parent.get_node_or_null("RimLight") as OmniLight3D
	if key != null:
		key.shadow_enabled = false
		key.light_energy = float(profile.get("light_energy",1.0))*0.72
	if fill != null:
		fill.light_energy = float(profile.get("light_energy",1.0))*0.62
	if rim != null:
		rim.light_energy = float(profile.get("light_energy",1.0))*0.42
