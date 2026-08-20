extends Node3D
class_name HeroProductDetailPresentation

const LATHE_SEGMENTS := 96

var _product: ProductPresentation
var _active_kind := ""
var _detail_root: Node3D

func _ready() -> void:
	call_deferred("_bind")

func _process(_delta: float) -> void:
	if _product == null:
		_bind()
	if _product == null:
		return
	rotation.y = _product.rotation.y
	var kind := _product.get_active_kind()
	if kind != _active_kind:
		_rebuild(kind)

func _bind() -> void:
	var parent := get_parent()
	if parent == null:
		return
	_product = parent.get_node_or_null("ProductPresentation") as ProductPresentation
	if _detail_root == null:
		_detail_root = Node3D.new()
		_detail_root.name = "HeroProductDetails"
		add_child(_detail_root)
	if _product != null:
		_rebuild(_product.get_active_kind())

func material_contract_for_kind(kind: String) -> Dictionary:
	match kind:
		"sauce_jar":
			return {"glass_alpha":0.055,"fill_height_ratio":0.86,"sauce_color":Color(0.46,0.055,0.018)}
		"tin_can":
			return {"body_value":0.90,"metallic":0.16,"roughness":0.24}
		"soda_can":
			return {"finish":"bare_aluminum","body_color":Color(0.89,0.90,0.91),"metallic":0.18,"roughness":0.20,"condensation":true}
		_:
			return {}

func _rebuild(kind: String) -> void:
	_active_kind = kind
	if _detail_root == null:
		return
	for child in _detail_root.get_children():
		child.free()
	_restore_base_visibility()
	match kind:
		"sauce_jar":
			_hide_product_nodes(["JarGlass","JarContents","JarLid","JarBaseGlass"])
			_build_jar()
		"tin_can":
			_hide_product_nodes(["TinCanBody","TinCanTop","TinCanTopRim","TinCanBottomRim"])
			_build_tin_can()
		"soda_can":
			_hide_product_nodes(["SodaCanBody","SodaCanTop","SodaCanTopRim","SodaCanBottomRim"])
			_build_soda_can()

func _restore_base_visibility() -> void:
	if _product == null:
		return
	for child in _product.get_children():
		if child is VisualInstance3D:
			(child as VisualInstance3D).visible = true

func _hide_product_nodes(names: Array[String]) -> void:
	if _product == null:
		return
	for node_name in names:
		var node := _product.get_node_or_null(node_name)
		if node is VisualInstance3D:
			(node as VisualInstance3D).visible = false

func _build_jar() -> void:
	var contract := material_contract_for_kind("sauce_jar")
	var glass_profile: Array[Vector2] = [
		Vector2(-0.65,0.365),Vector2(-0.625,0.398),Vector2(-0.58,0.408),
		Vector2(0.43,0.408),Vector2(0.48,0.402),Vector2(0.54,0.382),
		Vector2(0.59,0.345),Vector2(0.62,0.315),Vector2(0.70,0.315)
	]
	_add_lathe("JarHeroShell",glass_profile,_glass_material(Color(0.96,0.985,0.985),float(contract["glass_alpha"]),0.022),false,false)

	# Fill most of the real jar volume. The target reads as a glass vessel around
	# dense tomato sauce, not an empty jar with a red puck floating near the lid.
	var sauce_profile: Array[Vector2] = [
		Vector2(-0.59,0.320),Vector2(-0.55,0.342),Vector2(-0.48,0.348),
		Vector2(0.35,0.348),Vector2(0.405,0.338),Vector2(0.455,0.312)
	]
	var sauce := _mat(Color(0.46,0.055,0.018),0.44)
	sauce.metallic_specular = 0.12
	_add_lathe("JarSauceVolume",sauce_profile,sauce,true,true)

	_add_cylinder("JarHeroLid",Vector3(0,0.735,0),0.338,0.338,0.125,_metal_material(Color(0.47,0.31,0.18),0.28,0.18),112)
	_add_ring("JarThreadBand0",0.680,0.345,0.014,Color(0.56,0.38,0.22),0.28,false,0.16)
	_add_ring("JarThreadBand1",0.713,0.347,0.012,Color(0.63,0.43,0.25),0.25,false,0.16)
	_add_ring("JarThreadBand2",0.746,0.345,0.011,Color(0.50,0.33,0.20),0.29,false,0.16)
	_add_ring("JarGlassBase",-0.647,0.407,0.022,Color(0.94,0.98,0.99,0.20),0.06,true,0.0)
	_add_glass_highlight("JarHighlightLeft",Vector3(-0.252,0.02,0.321),Vector2(0.020,0.92),0.12)
	_add_glass_highlight("JarHighlightRight",Vector3(0.272,-0.03,0.303),Vector2(0.013,0.68),0.07)

func _build_tin_can() -> void:
	var contract := material_contract_for_kind("tin_can")
	var body_profile: Array[Vector2] = [
		Vector2(-0.655,0.385),Vector2(-0.628,0.398),Vector2(-0.585,0.402),
		Vector2(0.585,0.402),Vector2(0.628,0.398),Vector2(0.655,0.385)
	]
	_add_lathe("TinHeroBody",body_profile,_metal_material(Color(0.90,0.91,0.92),float(contract["roughness"]),float(contract["metallic"])),true,true)
	_add_ring("TinHeroTopRoll",0.665,0.418,0.030,Color(0.96,0.965,0.97),0.18,false,0.18)
	_add_ring("TinHeroBottomRoll",-0.665,0.418,0.030,Color(0.88,0.89,0.90),0.22,false,0.16)
	_add_cylinder("TinHeroTopDisk",Vector3(0,0.681,0),0.382,0.382,0.010,_metal_material(Color(0.94,0.945,0.95),0.26,0.16),112)
	_add_cylinder("TinHeroTopInset",Vector3(0,0.688,0),0.315,0.315,0.006,_metal_material(Color(0.80,0.82,0.83),0.34,0.12),96)
	_add_vertical_specular("TinSpecularLeft",-0.285,0.02,0.88,0.050,0.10)

func _build_soda_can() -> void:
	var contract := material_contract_for_kind("soda_can")
	var body_profile: Array[Vector2] = [
		Vector2(-0.70,0.360),Vector2(-0.675,0.390),Vector2(-0.625,0.402),
		Vector2(0.54,0.402),Vector2(0.585,0.396),Vector2(0.625,0.378),
		Vector2(0.660,0.344),Vector2(0.682,0.332)
	]
	_add_lathe("SodaHeroBody",body_profile,_metal_material(contract["body_color"],float(contract["roughness"]),float(contract["metallic"])),true,true)
	_add_ring("SodaHeroTopRoll",0.690,0.365,0.026,Color(0.97,0.975,0.98),0.16,false,0.20)
	_add_ring("SodaHeroBottomRoll",-0.705,0.378,0.030,Color(0.86,0.88,0.89),0.22,false,0.16)
	_add_cylinder("SodaHeroTopDisk",Vector3(0,0.699,0),0.332,0.332,0.008,_metal_material(Color(0.93,0.94,0.95),0.20,0.20),112)
	_add_pull_tab()
	_add_condensation(0.405,-0.50,0.54,34)
	_add_vertical_specular("SodaMetalHighlightLeft",-0.280,0.01,0.92,0.042,0.12)
	_add_vertical_specular("SodaMetalHighlightRight",0.265,-0.02,0.74,0.025,0.055)

func _add_pull_tab() -> void:
	var tab := MeshInstance3D.new()
	tab.name = "SodaPullTab"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.11,0.008,0.23)
	tab.mesh = mesh
	tab.position = Vector3(0.0,0.710,0.035)
	tab.rotation_degrees.y = 8.0
	tab.material_override = _metal_material(Color(0.84,0.86,0.87),0.23,0.20)
	_detail_root.add_child(tab)
	var opening := MeshInstance3D.new()
	opening.name = "SodaOpening"
	var opening_mesh := CylinderMesh.new()
	opening_mesh.top_radius = 0.052
	opening_mesh.bottom_radius = 0.052
	opening_mesh.height = 0.006
	opening_mesh.radial_segments = 40
	opening.mesh = opening_mesh
	opening.position = Vector3(0.0,0.708,-0.125)
	opening.material_override = _mat(Color(0.055,0.058,0.060),0.50)
	_detail_root.add_child(opening)

func _add_condensation(radius: float, y_min: float, y_max: float, count: int) -> void:
	for i in range(count):
		var angle := TAU*float((i*11)%count)/float(count)
		var y := lerpf(y_min,y_max,float((i*17)%count)/float(maxi(count-1,1)))
		var bead := MeshInstance3D.new()
		bead.name = "HeroCondensation"
		var sm := SphereMesh.new()
		sm.radius = 0.006+0.002*float(i%4)
		sm.height = sm.radius*2.0
		sm.radial_segments = 10
		sm.rings = 6
		bead.mesh = sm
		bead.position = Vector3(cos(angle)*(radius+0.004),y,sin(angle)*(radius+0.004))
		bead.material_override = _glass_material(Color(0.96,0.99,1.0),0.20,0.012)
		_detail_root.add_child(bead)

func _add_glass_highlight(node_name: String, at: Vector3, size: Vector2, alpha: float) -> void:
	var highlight := MeshInstance3D.new()
	highlight.name = node_name
	var mesh := QuadMesh.new()
	mesh.size = size
	highlight.mesh = mesh
	highlight.position = at
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(1.0,1.0,0.98,alpha)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.roughness = 0.03
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.render_priority = 3
	highlight.material_override = material
	highlight.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_detail_root.add_child(highlight)

func _add_vertical_specular(node_name: String, x: float, y: float, height: float, width: float, alpha: float) -> void:
	_add_glass_highlight(node_name,Vector3(x,y,0.404),Vector2(width,height),alpha)

func _add_lathe(node_name: String, profile: Array[Vector2], material: Material, cap_bottom: bool, cap_top: bool) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = _lathe_mesh(profile,cap_bottom,cap_top)
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_detail_root.add_child(instance)
	return instance

func _lathe_mesh(profile: Array[Vector2], cap_bottom: bool, cap_top: bool) -> ArrayMesh:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	for ring_index in range(profile.size()):
		var sample := profile[ring_index]
		var prev := profile[maxi(ring_index-1,0)]
		var next := profile[mini(ring_index+1,profile.size()-1)]
		var dy := next.x-prev.x
		var dr := next.y-prev.y
		var slope := dr/dy if absf(dy)>0.00001 else 0.0
		for side_index in range(LATHE_SEGMENTS+1):
			var u := float(side_index)/float(LATHE_SEGMENTS)
			var angle := u*TAU
			var radial := Vector3(cos(angle),0.0,sin(angle))
			vertices.append(Vector3(radial.x*sample.y,sample.x,radial.z*sample.y))
			normals.append(Vector3(radial.x,-slope,radial.z).normalized())
			uvs.append(Vector2(u,1.0-float(ring_index)/float(maxi(profile.size()-1,1))))
	var row := LATHE_SEGMENTS+1
	for ring_index in range(profile.size()-1):
		for side_index in range(LATHE_SEGMENTS):
			var a := ring_index*row+side_index
			var b := a+1
			var d := (ring_index+1)*row+side_index
			var c := d+1
			indices.append(a); indices.append(d); indices.append(c)
			indices.append(a); indices.append(c); indices.append(b)
	if cap_bottom:
		_add_cap(vertices,normals,uvs,indices,profile[0],false)
	if cap_top:
		_add_cap(vertices,normals,uvs,indices,profile[profile.size()-1],true)
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=vertices
	arrays[Mesh.ARRAY_NORMAL]=normals
	arrays[Mesh.ARRAY_TEX_UV]=uvs
	arrays[Mesh.ARRAY_INDEX]=indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	return mesh

func _add_cap(vertices: PackedVector3Array, normals: PackedVector3Array, uvs: PackedVector2Array, indices: PackedInt32Array, sample: Vector2, top: bool) -> void:
	var center := vertices.size()
	var normal := Vector3.UP if top else Vector3.DOWN
	vertices.append(Vector3(0,sample.x,0))
	normals.append(normal)
	uvs.append(Vector2(0.5,0.5))
	var start := vertices.size()
	for side_index in range(LATHE_SEGMENTS+1):
		var u := float(side_index)/float(LATHE_SEGMENTS)
		var angle := u*TAU
		vertices.append(Vector3(cos(angle)*sample.y,sample.x,sin(angle)*sample.y))
		normals.append(normal)
		uvs.append(Vector2(0.5+cos(angle)*0.5,0.5+sin(angle)*0.5))
	for side_index in range(LATHE_SEGMENTS):
		if top:
			indices.append(center); indices.append(start+side_index); indices.append(start+side_index+1)
		else:
			indices.append(center); indices.append(start+side_index+1); indices.append(start+side_index)

func _add_cylinder(node_name: String, at: Vector3, top_radius: float, bottom_radius: float, height: float, material: Material, segments: int) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	var mesh := CylinderMesh.new()
	mesh.top_radius = top_radius
	mesh.bottom_radius = bottom_radius
	mesh.height = height
	mesh.radial_segments = segments
	instance.mesh = mesh
	instance.position = at
	instance.material_override = material
	_detail_root.add_child(instance)
	return instance

func _add_ring(node_name: String, y: float, radius: float, height: float, color: Color, roughness: float, transparent: bool = false, metallic: float = 0.35) -> void:
	var mat := _metal_material(Color(color.r,color.g,color.b,1.0),roughness,metallic)
	if transparent:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color.a = color.a
	_add_cylinder(node_name,Vector3(0,y,0),radius,radius,height,mat,112)

func _mat(color: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material

func _metal_material(color: Color, roughness: float, metallic: float) -> StandardMaterial3D:
	var material := _mat(color,roughness)
	material.metallic = metallic
	material.metallic_specular = 0.82
	return material

func _glass_material(color: Color, alpha: float, roughness: float) -> StandardMaterial3D:
	var material := _mat(color,roughness)
	material.albedo_color.a = alpha
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.metallic_specular = 0.90
	material.rim_enabled = true
	material.rim = 0.86
	material.rim_tint = 0.50
	material.clearcoat_enabled = true
	material.clearcoat = 0.92
	material.clearcoat_roughness = 0.035
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material
