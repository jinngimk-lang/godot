extends Node3D
class_name VenuePresentation

var _active_profile_id := "cafe_window"
var _built := false
var _world: WorldEnvironment
var _cafe: Node3D
var _bar: Node3D
var _market: Node3D

func _ready() -> void:
	_ensure_built()
	apply_profile({"id":"cafe_window"})

func get_active_profile_id() -> String:
	return _active_profile_id

func apply_profile(profile: Dictionary) -> void:
	_ensure_built()
	var requested := String(profile.get("id", "cafe_window"))
	if requested not in ["cafe_window", "night_bar", "market_coldcase"]:
		requested = "cafe_window"
	_active_profile_id = requested
	_cafe.visible = requested == "cafe_window"
	_bar.visible = requested == "night_bar"
	_market.visible = requested == "market_coldcase"
	_apply_environment(profile)
	_apply_parent_stage(profile)

func _ensure_built() -> void:
	if _built:
		return
	_built = true
	_world = WorldEnvironment.new()
	_world.name = "ReferenceEnvironment"
	add_child(_world)
	_cafe = Node3D.new()
	_cafe.name = "CafeWindows"
	add_child(_cafe)
	_bar = Node3D.new()
	_bar.name = "BarBackShelf"
	add_child(_bar)
	_market = Node3D.new()
	_market.name = "MarketCooler"
	add_child(_market)
	_build_cafe(_cafe)
	_build_bar(_bar)
	_build_market(_market)

func _apply_environment(profile: Dictionary) -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	var id := _active_profile_id
	if id == "night_bar":
		env.background_color = Color(0.018,0.010,0.008)
		env.ambient_light_color = Color(0.24,0.105,0.055)
		env.ambient_light_energy = 0.50
	elif id == "market_coldcase":
		env.background_color = Color(0.62,0.67,0.70)
		env.ambient_light_color = Color(0.78,0.86,0.92)
		env.ambient_light_energy = 0.68
	else:
		env.background_color = Color(0.13,0.095,0.065)
		env.ambient_light_color = Color(0.62,0.42,0.25)
		env.ambient_light_energy = 0.52
	_world.environment = env

func _apply_parent_stage(profile: Dictionary) -> void:
	var parent := get_parent()
	if parent == null:
		return
	var table := parent.get_node_or_null("Table") as MeshInstance3D
	if table != null:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(profile.get("table_color", Color(0.22,0.115,0.055)))
		mat.roughness = clampf(float(profile.get("table_roughness", 0.54)), 0.05, 1.0)
		mat.metallic = 0.03 if _active_profile_id != "market_coldcase" else 0.0
		table.material_override = mat
	var key := parent.get_node_or_null("KeyLight") as DirectionalLight3D
	var fill := parent.get_node_or_null("FillLight") as OmniLight3D
	var rim := parent.get_node_or_null("RimLight") as DirectionalLight3D
	if key != null:
		if _active_profile_id == "night_bar":
			key.light_color = Color(1.0,0.46,0.19)
			key.light_energy = 1.45
		elif _active_profile_id == "market_coldcase":
			key.light_color = Color(0.82,0.92,1.0)
			key.light_energy = 1.10
		else:
			key.light_color = Color(1.0,0.73,0.45)
			key.light_energy = 1.28
	if fill != null:
		fill.light_color = Color(1.0,0.52,0.28) if _active_profile_id == "night_bar" else (Color(0.80,0.90,1.0) if _active_profile_id == "market_coldcase" else Color(1.0,0.83,0.64))
		fill.light_energy = 1.25 if _active_profile_id == "night_bar" else 0.95
	if rim != null:
		rim.light_color = Color(1.0,0.30,0.08) if _active_profile_id == "night_bar" else (Color(0.66,0.86,1.0) if _active_profile_id == "market_coldcase" else Color(0.72,0.84,1.0))
		rim.light_energy = 0.72

func _build_cafe(root: Node3D) -> void:
	_add_box(root,"CafeBackWall",Vector3(0,1.20,-2.65),Vector3(7.8,3.7,0.16),Color(0.105,0.065,0.040),0.92)
	# Large floor-to-ceiling windows and mullions give the scene a readable silhouette.
	for x in [-2.8,-1.4,0.0,1.4,2.8]:
		_add_box(root,"WindowMullion",Vector3(x,1.32,-2.46),Vector3(0.07,3.05,0.10),Color(0.045,0.035,0.030),0.48)
	_add_box(root,"WindowTop",Vector3(0,2.80,-2.46),Vector3(5.8,0.08,0.10),Color(0.045,0.035,0.030),0.48)
	_add_box(root,"WindowSill",Vector3(0,-0.12,-2.46),Vector3(5.8,0.10,0.12),Color(0.055,0.038,0.028),0.60)
	for i in range(4):
		var x := -2.15 + float(i) * 1.42
		_add_box(root,"SunlitExterior",Vector3(x,1.33,-2.57),Vector3(1.24,2.72,0.035),Color(0.58 + i*0.035,0.68,0.55),0.95,true,Color(0.40,0.34,0.20),0.16)
	# Exterior greenery/building silhouettes.
	for i in range(7):
		_add_cylinder(root,"ExteriorGreenery",Vector3(-2.45 + i*0.78,0.36 + float(i%2)*0.18,-2.39),0.18 + float(i%3)*0.045,0.72 + float(i%2)*0.28,Color(0.15,0.25 + float(i%3)*0.025,0.13),0.88)
	_add_box(root,"CafeCounter",Vector3(2.45,0.48,-1.66),Vector3(2.15,0.82,0.62),Color(0.20,0.095,0.040),0.50)
	_add_box(root,"CafeShelf",Vector3(2.45,1.55,-2.10),Vector3(2.10,0.08,0.32),Color(0.12,0.065,0.035),0.58)
	for i in range(6):
		_add_cylinder(root,"CafeJar",Vector3(1.70 + float(i)*0.28,1.72,-1.96),0.075,0.28,Color(0.30+0.04*(i%2),0.22,0.15),0.32)
	for x in [-2.0,-0.75,0.72]:
		_add_box(root,"CafeSideTable",Vector3(x,0.18,-1.30),Vector3(0.70,0.09,0.48),Color(0.20,0.105,0.052),0.54)
		_add_box(root,"CafeChairBack",Vector3(x,0.55,-1.52),Vector3(0.52,0.62,0.10),Color(0.115,0.075,0.055),0.78)
	for x in [-1.65,0.25,2.05]:
		_add_pendant(root,Vector3(x,2.45,-1.62),Color(1.0,0.58,0.25))

func _build_bar(root: Node3D) -> void:
	_add_box(root,"BarWall",Vector3(0,1.18,-2.62),Vector3(7.8,3.75,0.18),Color(0.028,0.014,0.011),0.94)
	# Repeating brick courses are cheap but break the prototype-box look.
	for row in range(7):
		for col in range(10):
			var offset := 0.28 if row % 2 == 1 else 0.0
			_add_box(root,"Brick",Vector3(-3.05 + col*0.68 + offset,-0.05 + row*0.43,-2.49),Vector3(0.60,0.31,0.055),Color(0.095+0.008*(row%2),0.040,0.026),0.90)
	for y in [0.65,1.30,1.95]:
		_add_box(root,"BackBarShelf",Vector3(1.05,y,-2.12),Vector3(4.55,0.10,0.42),Color(0.085,0.040,0.022),0.36)
		for i in range(10):
			var x := -0.92 + float(i)*0.43
			var hue := float(i%4)
			_add_cylinder(root,"BarBottle",Vector3(x,y+0.27,-1.98),0.075,0.43,Color(0.11+0.035*hue,0.035+0.012*hue,0.015),0.18)
	_add_box(root,"BarGlowStrip",Vector3(1.05,0.47,-2.02),Vector3(4.6,0.055,0.08),Color(0.95,0.23,0.025),0.35,true,Color(1.0,0.18,0.02),1.8)
	_add_box(root,"NeonPlate",Vector3(-2.25,1.55,-2.24),Vector3(1.05,0.52,0.06),Color(0.13,0.025,0.015),0.40,true,Color(1.0,0.11,0.035),1.25)
	for x in [-1.45,0.25,2.15]:
		_add_pendant(root,Vector3(x,2.48,-1.52),Color(1.0,0.31,0.08))

func _build_market(root: Node3D) -> void:
	_add_box(root,"MarketBackWall",Vector3(0,1.18,-2.72),Vector3(7.8,3.75,0.18),Color(0.72,0.76,0.76),0.76)
	# Cooler doors/frames.
	for x in [-2.55,-1.28,0.0,1.28,2.55]:
		_add_box(root,"CoolerFrame",Vector3(x,1.30,-2.42),Vector3(0.075,2.92,0.12),Color(0.24,0.29,0.31),0.28)
	for y in [0.08,0.65,1.22,1.79,2.36]:
		_add_box(root,"CoolerShelf",Vector3(0,y,-2.34),Vector3(5.35,0.055,0.34),Color(0.62,0.67,0.68),0.42)
	for row in range(4):
		for col in range(12):
			var group := col % 4
			var c := [Color(0.76,0.88,0.82),Color(0.92,0.82,0.46),Color(0.66,0.80,0.92),Color(0.90,0.64,0.58)][group]
			_add_box(root,"MarketProduct",Vector3(-2.35+col*0.43,0.34+row*0.57,-2.10),Vector3(0.26,0.34,0.18),c,0.62)
	_add_box(root,"PriceRail",Vector3(0,0.47,-1.99),Vector3(5.2,0.12,0.05),Color(0.93,0.94,0.90),0.66)
	# Ceiling panels establish the cool commercial light rhythm.
	for x in [-2.2,0.0,2.2]:
		_add_box(root,"CeilingPanel",Vector3(x,2.77,-1.10),Vector3(1.15,0.055,0.36),Color(0.94,0.98,1.0),0.35,true,Color(0.72,0.88,1.0),1.2)

func _add_pendant(root: Node3D, at: Vector3, color: Color) -> void:
	_add_cylinder(root,"PendantStem",at+Vector3(0,0.22,0),0.025,0.44,Color(0.035,0.025,0.020),0.34)
	var bulb := _add_sphere(root,"PendantBulb",at,0.105,Color(1.0,0.55,0.22),0.20,true,color,2.2)
	var light := OmniLight3D.new()
	light.name = "PendantLight"
	light.position = at
	light.light_color = color
	light.light_energy = 0.62
	light.omni_range = 2.0
	root.add_child(light)
	bulb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func _add_box(root: Node3D, node_name: String, at: Vector3, size: Vector3, color: Color, roughness: float, emissive := false, emission := Color.BLACK, emission_energy := 0.0) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.position = at
	node.material_override = _material(color, roughness, emissive, emission, emission_energy)
	root.add_child(node)
	return node

func _add_cylinder(root: Node3D, node_name: String, at: Vector3, radius: float, height: float, color: Color, roughness: float) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = node_name
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 16
	node.mesh = mesh
	node.position = at
	node.material_override = _material(color, roughness)
	root.add_child(node)
	return node

func _add_sphere(root: Node3D, node_name: String, at: Vector3, radius: float, color: Color, roughness: float, emissive := false, emission := Color.BLACK, emission_energy := 0.0) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = node_name
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 16
	mesh.rings = 8
	node.mesh = mesh
	node.position = at
	node.material_override = _material(color, roughness, emissive, emission, emission_energy)
	root.add_child(node)
	return node

func _material(color: Color, roughness: float, emissive := false, emission := Color.BLACK, emission_energy := 0.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = clampf(roughness,0.02,1.0)
	if emissive:
		mat.emission_enabled = true
		mat.emission = emission
		mat.emission_energy_multiplier = maxf(emission_energy,0.0)
	return mat
