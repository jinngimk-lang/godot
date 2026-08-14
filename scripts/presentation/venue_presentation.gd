extends Node3D
class_name VenuePresentation

var _active_profile_id: String = "cafe_window"
var _built: bool = false
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
	var requested: String = String(profile.get("id","cafe_window"))
	if requested not in ["cafe_window","night_bar","market_coldcase"]:
		requested = "cafe_window"
	_active_profile_id = requested
	_cafe.visible = requested == "cafe_window"
	_bar.visible = requested == "night_bar"
	_market.visible = requested == "market_coldcase"
	_apply_environment()
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

func _apply_environment() -> void:
	var env: Environment = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	if _active_profile_id == "night_bar":
		env.background_color = Color(0.016,0.009,0.007)
		env.ambient_light_color = Color(0.30,0.13,0.065)
		env.ambient_light_energy = 0.48
	elif _active_profile_id == "market_coldcase":
		env.background_color = Color(0.62,0.67,0.70)
		env.ambient_light_color = Color(0.78,0.87,0.94)
		env.ambient_light_energy = 0.68
	else:
		env.background_color = Color(0.13,0.09,0.055)
		env.ambient_light_color = Color(0.64,0.43,0.25)
		env.ambient_light_energy = 0.54
	_world.environment = env

func _apply_parent_stage(profile: Dictionary) -> void:
	var parent: Node = get_parent()
	if parent == null:
		return
	var table: MeshInstance3D = parent.get_node_or_null("Table") as MeshInstance3D
	if table != null:
		var table_mat: StandardMaterial3D = StandardMaterial3D.new()
		table_mat.albedo_color = Color(profile.get("table_color",Color(0.22,0.115,0.055)))
		table_mat.roughness = clampf(float(profile.get("table_roughness",0.54)),0.05,1.0)
		table_mat.metallic = 0.02 if _active_profile_id != "market_coldcase" else 0.0
		table.material_override = table_mat
	var key: DirectionalLight3D = parent.get_node_or_null("KeyLight") as DirectionalLight3D
	var fill: OmniLight3D = parent.get_node_or_null("FillLight") as OmniLight3D
	var rim: OmniLight3D = parent.get_node_or_null("RimLight") as OmniLight3D
	if key != null:
		if _active_profile_id == "night_bar":
			key.light_color = Color(1.0,0.46,0.19)
			key.light_energy = 0.98
		elif _active_profile_id == "market_coldcase":
			key.light_color = Color(0.82,0.92,1.0)
			key.light_energy = 0.94
		else:
			key.light_color = Color(1.0,0.73,0.45)
			key.light_energy = 0.96
	if fill != null:
		if _active_profile_id == "night_bar":
			fill.light_color = Color(1.0,0.52,0.28)
			fill.light_energy = 1.20
		elif _active_profile_id == "market_coldcase":
			fill.light_color = Color(0.80,0.90,1.0)
			fill.light_energy = 0.98
		else:
			fill.light_color = Color(1.0,0.83,0.64)
			fill.light_energy = 0.92
	if rim != null:
		rim.light_color = Color(1.0,0.30,0.08) if _active_profile_id == "night_bar" else (Color(0.66,0.86,1.0) if _active_profile_id == "market_coldcase" else Color(0.72,0.84,1.0))
		rim.light_energy = 0.70

func _build_cafe(root: Node3D) -> void:
	_add_box(root,"CafeBackWall",Vector3(0,1.15,-2.72),Vector3(7.9,3.8,0.16),Color(0.105,0.060,0.035),0.92)
	for x: float in [-2.8,-1.4,0.0,1.4,2.8]:
		_add_box(root,"WindowMullion",Vector3(x,1.32,-2.49),Vector3(0.065,3.10,0.10),Color(0.035,0.030,0.028),0.42)
	_add_box(root,"WindowTop",Vector3(0,2.82,-2.49),Vector3(5.75,0.07,0.10),Color(0.035,0.030,0.028),0.42)
	_add_box(root,"WindowSill",Vector3(0,-0.14,-2.49),Vector3(5.75,0.09,0.13),Color(0.055,0.038,0.028),0.58)
	for i: int in range(4):
		var window_color: Color = Color(0.53+float(i)*0.035,0.65,0.54)
		_add_box(root,"SunlitExterior",Vector3(-2.15+float(i)*1.42,1.33,-2.59),Vector3(1.23,2.72,0.035),window_color,0.95,true,Color(0.42,0.34,0.19),0.18)
	for i: int in range(7):
		_add_cylinder(root,"ExteriorGreenery",Vector3(-2.45+float(i)*0.78,0.34+float(i%2)*0.17,-2.40),0.18+float(i%3)*0.04,0.72+float(i%2)*0.26,Color(0.14,0.23+float(i%3)*0.025,0.12),0.88)
	_add_box(root,"CafeCounter",Vector3(2.42,0.48,-1.70),Vector3(2.18,0.82,0.64),Color(0.19,0.088,0.036),0.48)
	for y: float in [1.18,1.68]:
		_add_box(root,"CafeShelf",Vector3(2.45,y,-2.09),Vector3(2.08,0.07,0.30),Color(0.10,0.050,0.027),0.48)
	for i: int in range(7):
		_add_cylinder(root,"CafeJar",Vector3(1.65+float(i)*0.27,1.83,-1.97),0.07,0.26,Color(0.27+float(i%2)*0.05,0.19,0.12),0.30)
	for x: float in [-2.0,-0.72,0.70]:
		_add_box(root,"CafeSideTable",Vector3(x,0.18,-1.32),Vector3(0.68,0.08,0.48),Color(0.19,0.090,0.042),0.52)
		_add_box(root,"CafeChairBack",Vector3(x,0.54,-1.53),Vector3(0.50,0.60,0.10),Color(0.11,0.071,0.052),0.76)
	for x: float in [-1.62,0.24,2.02]:
		_add_pendant(root,Vector3(x,2.43,-1.61),Color(1.0,0.58,0.25))

func _build_bar(root: Node3D) -> void:
	_add_box(root,"BarWall",Vector3(0,1.15,-2.72),Vector3(7.9,3.8,0.16),Color(0.024,0.012,0.009),0.96)
	for row: int in range(6):
		for col: int in range(10):
			var x_offset: float = 0.28 if row%2 == 1 else 0.0
			_add_box(root,"Brick",Vector3(-3.05+float(col)*0.68+x_offset,0.02+float(row)*0.43,-2.57),Vector3(0.60,0.31,0.055),Color(0.088+float(row%2)*0.01,0.037,0.024),0.92)
	for y: float in [0.62,1.26,1.90]:
		_add_box(root,"BackBarShelf",Vector3(1.0,y,-2.14),Vector3(4.65,0.09,0.40),Color(0.075,0.033,0.017),0.33)
		for i: int in range(10):
			var tint: float = float(i%4)
			_add_cylinder(root,"BarBottle",Vector3(-0.95+float(i)*0.43,y+0.27,-1.99),0.073,0.42,Color(0.10+0.032*tint,0.032+0.009*tint,0.013),0.16)
	_add_box(root,"BarGlowStrip",Vector3(1.0,0.42,-2.03),Vector3(4.65,0.055,0.08),Color(0.92,0.20,0.02),0.28,true,Color(1.0,0.16,0.018),1.9)
	_add_box(root,"NeonPlate",Vector3(-2.30,1.55,-2.30),Vector3(1.05,0.52,0.055),Color(0.11,0.020,0.014),0.36,true,Color(1.0,0.08,0.025),1.35)
	for x: float in [-1.42,0.26,2.10]:
		_add_pendant(root,Vector3(x,2.44,-1.55),Color(1.0,0.31,0.08))

func _build_market(root: Node3D) -> void:
	_add_box(root,"MarketBackWall",Vector3(0,1.15,-2.75),Vector3(7.9,3.8,0.16),Color(0.70,0.74,0.75),0.78)
	for x: float in [-2.55,-1.28,0.0,1.28,2.55]:
		_add_box(root,"CoolerFrame",Vector3(x,1.31,-2.43),Vector3(0.075,2.94,0.12),Color(0.22,0.27,0.29),0.24)
	for y: float in [0.08,0.64,1.20,1.76,2.32]:
		_add_box(root,"CoolerShelf",Vector3(0,y,-2.34),Vector3(5.35,0.055,0.34),Color(0.62,0.67,0.68),0.40)
	var product_colors: Array[Color] = [Color(0.76,0.88,0.82),Color(0.92,0.82,0.46),Color(0.66,0.80,0.92),Color(0.90,0.64,0.58)]
	for row: int in range(4):
		for col: int in range(12):
			var product_color: Color = product_colors[col%product_colors.size()]
			_add_box(root,"MarketProduct",Vector3(-2.35+float(col)*0.43,0.33+float(row)*0.56,-2.10),Vector3(0.26,0.34,0.18),product_color,0.62)
	_add_box(root,"PriceRail",Vector3(0,0.45,-1.99),Vector3(5.2,0.12,0.05),Color(0.93,0.94,0.90),0.66)
	for x: float in [-2.2,0.0,2.2]:
		_add_box(root,"CeilingPanel",Vector3(x,2.77,-1.08),Vector3(1.15,0.055,0.36),Color(0.94,0.98,1.0),0.32,true,Color(0.72,0.88,1.0),1.25)

func _add_pendant(root: Node3D, at: Vector3, color: Color) -> void:
	_add_cylinder(root,"PendantStem",at+Vector3(0,0.22,0),0.025,0.44,Color(0.035,0.025,0.020),0.34)
	var bulb: MeshInstance3D = _add_sphere(root,"PendantBulb",at,0.105,Color(1.0,0.55,0.22),0.20,true,color,2.2)
	bulb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var light: OmniLight3D = OmniLight3D.new()
	light.name = "PendantLight"
	light.position = at
	light.light_color = color
	light.light_energy = 0.58
	light.omni_range = 2.0
	root.add_child(light)

func _add_box(root: Node3D, node_name: String, at: Vector3, size: Vector3, color: Color, roughness: float, emissive: bool = false, emission: Color = Color.BLACK, emission_energy: float = 0.0) -> MeshInstance3D:
	var node: MeshInstance3D = MeshInstance3D.new()
	node.name = node_name
	var shape: BoxMesh = BoxMesh.new()
	shape.size = size
	node.mesh = shape
	node.position = at
	node.material_override = _material(color,roughness,emissive,emission,emission_energy)
	root.add_child(node)
	return node

func _add_cylinder(root: Node3D, node_name: String, at: Vector3, radius: float, height: float, color: Color, roughness: float) -> MeshInstance3D:
	var node: MeshInstance3D = MeshInstance3D.new()
	node.name = node_name
	var shape: CylinderMesh = CylinderMesh.new()
	shape.top_radius = radius
	shape.bottom_radius = radius
	shape.height = height
	shape.radial_segments = 16
	node.mesh = shape
	node.position = at
	node.material_override = _material(color,roughness)
	root.add_child(node)
	return node

func _add_sphere(root: Node3D, node_name: String, at: Vector3, radius: float, color: Color, roughness: float, emissive: bool = false, emission: Color = Color.BLACK, emission_energy: float = 0.0) -> MeshInstance3D:
	var node: MeshInstance3D = MeshInstance3D.new()
	node.name = node_name
	var shape: SphereMesh = SphereMesh.new()
	shape.radius = radius
	shape.height = radius*2.0
	shape.radial_segments = 16
	shape.rings = 8
	node.mesh = shape
	node.position = at
	node.material_override = _material(color,roughness,emissive,emission,emission_energy)
	root.add_child(node)
	return node

func _material(color: Color, roughness: float, emissive: bool = false, emission: Color = Color.BLACK, emission_energy: float = 0.0) -> StandardMaterial3D:
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = clampf(roughness,0.02,1.0)
	if emissive:
		mat.emission_enabled = true
		mat.emission = emission
		mat.emission_energy_multiplier = maxf(emission_energy,0.0)
	return mat
