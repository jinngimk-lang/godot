extends Node3D
class_name ProductPresentation

const BOTTLE_SEGMENTS := 80
const PAPER_BODY_SHADER := """shader_type spatial;
render_mode cull_back;
uniform vec4 paper_color : source_color = vec4(0.95, 0.935, 0.895, 1.0);
uniform float paper_roughness = 0.95;
uniform float fiber_strength = 0.022;
float paper_hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
void fragment() {
	vec2 fiber_cell = floor(UV * vec2(420.0, 860.0));
	float fleck = (paper_hash(fiber_cell) - 0.5) * 2.0;
	float coarse = (paper_hash(floor(UV * vec2(52.0, 118.0))) - 0.5) * 2.0;
	float pore = (paper_hash(floor(UV * vec2(180.0, 360.0))) - 0.5) * 2.0;
	float strand = sin((UV.y + sin(UV.x * 31.0) * 0.004) * 920.0) * 0.5;
	float fiber = (fleck * 0.50 + strand * 0.28 + pore * 0.22) * fiber_strength + coarse * 0.018;
	ALBEDO = clamp(paper_color.rgb + vec3(fiber), vec3(0.0), vec3(1.0));
	ROUGHNESS = clamp(paper_roughness + abs(fiber) * 0.55, 0.90, 1.0);
	SPECULAR = 0.18;
	NORMAL_MAP = vec3(0.5 + fleck * 0.016, 0.5 + pore * 0.012, 1.0);
	NORMAL_MAP_DEPTH = 0.14;
}
"""
const GLASS_EDGE_SHADER := """shader_type spatial;
render_mode blend_mix, cull_disabled, depth_draw_never;
uniform vec4 edge_color : source_color = vec4(0.80, 0.92, 0.96, 1.0);
uniform float edge_alpha = 0.22;
uniform float fresnel_power = 3.1;
void fragment() {
	float grazing = clamp(1.0 - dot(NORMAL, VIEW), 0.0, 1.0);
	float fresnel = pow(grazing, fresnel_power);
	ALBEDO = edge_color.rgb;
	ALPHA = edge_alpha * fresnel;
	ROUGHNESS = mix(0.075, 0.022, fresnel);
	SPECULAR = 0.92;
	CLEARCOAT = 0.94;
	CLEARCOAT_ROUGHNESS = 0.05;
}
"""
const CONTACT_SHADOW_SHADER := """shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never;
uniform vec4 shadow_color : source_color = vec4(0.035, 0.020, 0.012, 0.24);
void fragment() {
	vec2 p = (UV - vec2(0.5)) * 2.0;
	float radial = dot(p, p);
	float feather = 1.0 - smoothstep(0.10, 1.0, radial);
	ALBEDO = shadow_color.rgb;
	ALPHA = shadow_color.a * feather;
}
"""

var _active_kind := "paper_cup"

func get_active_kind() -> String:
	return _active_kind

func apply_profile(profile: Dictionary) -> void:
	var requested := String(profile.get("kind","paper_cup"))
	if requested not in ["paper_cup","sauce_jar","tin_can","clear_bottle","soda_can"]:
		requested = "paper_cup"
	_active_kind = requested
	for child in get_children():
		child.free()
	match requested:
		"sauce_jar": _build_jar(profile)
		"tin_can": _build_tin_can(profile)
		"clear_bottle": _build_bottle(profile)
		"soda_can": _build_soda_can(profile)
		_: _build_paper(profile)
	_build_contact_shadow(requested)

func apply_to_base(body: MeshInstance3D, lid: MeshInstance3D, profile: Dictionary) -> void:
	if body == null:
		return
	var paper := String(profile.get("kind","paper_cup")) == "paper_cup"
	body.visible = paper
	if paper:
		body.material_override = _paper_material(profile)
	if lid != null:
		lid.visible = paper
		if paper:
			lid.material_override = _molded_lid_material(Color(profile.get("lid_color",Color(0.025,0.024,0.022))))

func set_inspection_yaw(yaw: float) -> void:
	rotation.y = yaw if is_finite(yaw) else 0.0

func _build_contact_shadow(kind: String) -> void:
	var shadow := MeshInstance3D.new()
	shadow.name = "ProductContactShadow"
	var quad := QuadMesh.new()
	var sizes := {
		"paper_cup":Vector2(1.16,0.54),
		"sauce_jar":Vector2(1.02,0.48),
		"tin_can":Vector2(0.98,0.46),
		"clear_bottle":Vector2(0.88,0.43),
		"soda_can":Vector2(0.96,0.45)
	}
	quad.size = sizes.get(kind,Vector2(0.86,0.40))
	shadow.mesh = quad
	shadow.position = Vector3(0.0,-0.632,0.015)
	shadow.rotation_degrees = Vector3(-90.0,0.0,0.0)
	shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var shader := Shader.new()
	shader.code = CONTACT_SHADOW_SHADER
	var material := ShaderMaterial.new()
	material.shader = shader
	var tone := Color(0.035,0.024,0.018,0.34)
	if kind in ["tin_can","soda_can","clear_bottle"]:
		tone = Color(0.035,0.045,0.050,0.28)
	material.set_shader_parameter("shadow_color",tone)
	material.render_priority = -2
	shadow.material_override = material
	add_child(shadow)

func _build_paper(profile: Dictionary) -> void:
	var root := Node3D.new()
	root.name = "CupPaperDetails"
	add_child(root)
	var body_color := Color(profile.get("body_color",Color(0.95,0.935,0.895)))
	var top_radius := float(profile.get("top_radius",0.49))
	var bottom_radius := float(profile.get("bottom_radius",0.415))
	var height := float(profile.get("height",1.40))
	var top_y := 0.05+height*0.5
	var bottom_y := 0.05-height*0.5
	_add_ring(root,"PaperBaseFold",Vector3(0,bottom_y-0.004,0),bottom_radius+0.004,0.018,body_color.darkened(0.045),0.97)
	_add_ring(root,"PaperLip",Vector3(0,top_y+0.006,0),top_radius+0.007,0.018,body_color.lightened(0.018),0.82)
	var seam := MeshInstance3D.new()
	seam.name = "PaperSeam"
	var seam_mesh := BoxMesh.new()
	seam_mesh.size = Vector3(0.007,height*0.80,0.004)
	seam.mesh = seam_mesh
	seam.position = Vector3(0.0,0.03,-top_radius+0.006)
	seam.material_override = _mat(body_color.darkened(0.035),0.98)
	root.add_child(seam)
	var lid_color := Color(profile.get("lid_color",Color(0.022,0.021,0.020)))
	var lid_mat := _molded_lid_material(lid_color)
	_add_lid_layer("CupLidSnapRing",top_y+0.038,top_radius+0.032,top_radius+0.030,0.030,lid_mat)
	_add_lid_layer("CupLidCrown",top_y+0.086,top_radius-0.005,top_radius+0.015,0.090,lid_mat)
	_add_lid_layer("CupLidTopBead",top_y+0.134,top_radius-0.003,top_radius-0.003,0.014,lid_mat)

func _build_jar(profile: Dictionary) -> void:
	var glass_color := Color(profile.get("body_color",Color(0.92,0.97,0.98)))
	var glass := MeshInstance3D.new()
	glass.name = "JarGlass"
	var glass_mesh := CylinderMesh.new()
	glass_mesh.top_radius = 0.385
	glass_mesh.bottom_radius = 0.405
	glass_mesh.height = 1.28
	glass_mesh.radial_segments = 96
	glass.mesh = glass_mesh
	glass.material_override = _glass_mat(glass_color,float(profile.get("glass_alpha",0.16)),0.045)
	glass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(glass)

	var contents := MeshInstance3D.new()
	contents.name = "JarContents"
	var contents_mesh := CylinderMesh.new()
	contents_mesh.top_radius = 0.342
	contents_mesh.bottom_radius = 0.365
	contents_mesh.height = 1.10
	contents_mesh.radial_segments = 80
	contents.mesh = contents_mesh
	contents.position.y = -0.035
	var sauce := _mat(Color(profile.get("liquid_color",Color(0.56,0.075,0.035))),0.62)
	sauce.metallic_specular = 0.18
	contents.material_override = sauce
	add_child(contents)

	var lid := MeshInstance3D.new()
	lid.name = "JarLid"
	var lid_mesh := CylinderMesh.new()
	lid_mesh.top_radius = 0.414
	lid_mesh.bottom_radius = 0.420
	lid_mesh.height = 0.12
	lid_mesh.radial_segments = 96
	lid.mesh = lid_mesh
	lid.position.y = 0.70
	lid.material_override = _metal_mat(Color(profile.get("lid_color",Color(0.29,0.20,0.13))),0.36,0.62)
	add_child(lid)
	_add_ring(self,"JarBaseGlass",Vector3(0,-0.635,0),0.408,0.025,glass_color,0.08,0.18)

func _build_tin_can(profile: Dictionary) -> void:
	var color := Color(profile.get("body_color",Color(0.64,0.67,0.70)))
	var body := MeshInstance3D.new()
	body.name = "TinCanBody"
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.398
	mesh.bottom_radius = 0.398
	mesh.height = 1.31
	mesh.radial_segments = 96
	body.mesh = mesh
	body.material_override = _metal_mat(color,float(profile.get("roughness",0.31)),float(profile.get("metallic",0.86)))
	add_child(body)
	_add_metal_rim("TinCanTopRim",0.664,0.414,0.030,color.lightened(0.10),0.24)
	_add_metal_rim("TinCanBottomRim",-0.664,0.414,0.030,color.darkened(0.06),0.30)
	var top := MeshInstance3D.new()
	top.name = "TinCanTop"
	var top_mesh := CylinderMesh.new()
	top_mesh.top_radius = 0.382
	top_mesh.bottom_radius = 0.382
	top_mesh.height = 0.010
	top_mesh.radial_segments = 96
	top.mesh = top_mesh
	top.position.y = 0.674
	top.material_override = _metal_mat(Color(0.72,0.74,0.75),0.32,0.92)
	add_child(top)

func _build_soda_can(profile: Dictionary) -> void:
	var color := Color(profile.get("body_color",Color(0.74,0.77,0.80)))
	var body := MeshInstance3D.new()
	body.name = "SodaCanBody"
	var profile_points: Array[Vector2] = [
		Vector2(-0.69,0.365),Vector2(-0.66,0.395),Vector2(-0.58,0.402),
		Vector2(0.56,0.402),Vector2(0.62,0.395),Vector2(0.67,0.365)
	]
	body.mesh = _build_lathe_mesh(profile_points,true,true)
	body.material_override = _metal_mat(color,float(profile.get("roughness",0.25)),float(profile.get("metallic",0.92)))
	add_child(body)
	_add_metal_rim("SodaCanTopRim",0.688,0.383,0.028,Color(0.82,0.84,0.85),0.20)
	_add_metal_rim("SodaCanBottomRim",-0.700,0.382,0.030,Color(0.68,0.70,0.72),0.26)
	var top := MeshInstance3D.new()
	top.name = "SodaCanTop"
	var top_mesh := CylinderMesh.new()
	top_mesh.top_radius = 0.350
	top_mesh.bottom_radius = 0.350
	top_mesh.height = 0.010
	top_mesh.radial_segments = 96
	top.mesh = top_mesh
	top.position.y = 0.700
	top.material_override = _metal_mat(Color(0.76,0.78,0.80),0.25,0.94)
	add_child(top)
	_add_condensation_for_radius(0.404,-0.50,0.56)

func _build_bottle(profile: Dictionary) -> void:
	var body_color := Color(profile.get("body_color",Color(0.94,0.985,0.98)))
	var neck_radius := float(profile.get("neck_radius",0.17))
	var source_alpha := float(profile.get("glass_alpha",0.18))
	var roughness := float(profile.get("roughness",0.045))
	var outer_profile := _bottle_profile(neck_radius)
	var outer_mesh := _build_lathe_mesh(outer_profile,false,false)
	var outer := MeshInstance3D.new()
	outer.name = "BottleOuterGlass"
	outer.mesh = outer_mesh
	outer.material_override = _glass_mat(body_color,source_alpha*0.55,roughness)
	outer.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(outer)
	var edge := MeshInstance3D.new()
	edge.name = "BottleEdgeFresnel"
	edge.mesh = outer_mesh
	edge.scale = Vector3.ONE*1.006
	edge.material_override = _glass_edge_material(body_color,source_alpha)
	edge.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(edge)
	var inner_profile: Array[Vector2] = []
	for sample in outer_profile:
		inner_profile.append(Vector2(sample.x,maxf(sample.y-0.021,0.035)))
	var inner := MeshInstance3D.new()
	inner.name = "BottleInnerGlass"
	inner.mesh = _build_lathe_mesh(inner_profile,false,false)
	inner.material_override = _glass_mat(body_color.lightened(0.16),source_alpha*0.06,0.020)
	inner.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(inner)
	var liquid := MeshInstance3D.new()
	liquid.name = "BottleLiquid"
	liquid.mesh = _build_lathe_mesh(_liquid_profile(),true,true)
	var liquid_mat := StandardMaterial3D.new()
	liquid_mat.albedo_color = Color(profile.get("liquid_color",Color(0.91,0.93,0.70,0.28)))
	liquid_mat.albedo_color.a = 0.30
	liquid_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	liquid_mat.roughness = 0.055
	liquid_mat.metallic_specular = 0.60
	liquid.material_override = liquid_mat
	liquid.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(liquid)
	_add_ring(self,"BottleLiquidMeniscus",Vector3(0,0.584,0),0.277,0.010,Color(0.93,0.95,0.68),0.045,0.40)
	_add_ring(self,"BottleBaseRing",Vector3(0,-0.655,0),0.322,0.020,body_color,0.040,0.18)
	var punt := MeshInstance3D.new()
	punt.name = "BottleBottomPunt"
	var punt_mesh := SphereMesh.new()
	punt_mesh.radius = 0.105
	punt_mesh.height = 0.062
	punt_mesh.radial_segments = 48
	punt_mesh.rings = 12
	punt.mesh = punt_mesh
	punt.position = Vector3(0,-0.610,0)
	punt.material_override = _glass_mat(body_color.lightened(0.10),0.20,0.025)
	punt.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(punt)
	_add_bottle_mouth_rim(body_color,neck_radius,source_alpha,roughness)
	_add_market_green_cap(neck_radius)
	_add_condensation_for_radius(0.334,-0.44,0.72)

func _paper_material(profile: Dictionary) -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = PAPER_BODY_SHADER
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("paper_color",Color(profile.get("body_color",Color(0.95,0.935,0.895))))
	material.set_shader_parameter("paper_roughness",clampf(float(profile.get("roughness",0.95)),0.90,1.0))
	material.set_shader_parameter("fiber_strength",clampf(float(profile.get("paper_fiber_strength",0.022)),0.008,0.035))
	return material

func _molded_lid_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.30
	material.metallic_specular = 0.56
	material.rim_enabled = true
	material.rim = 0.34
	material.rim_tint = 0.72
	material.clearcoat_enabled = true
	material.clearcoat = 0.48
	material.clearcoat_roughness = 0.12
	return material

func _add_lid_layer(node_name: String, y: float, top_radius: float, bottom_radius: float, height: float, material: Material) -> void:
	var layer := MeshInstance3D.new()
	layer.name = node_name
	var mesh := CylinderMesh.new()
	mesh.top_radius = top_radius
	mesh.bottom_radius = bottom_radius
	mesh.height = height
	mesh.radial_segments = 96
	layer.mesh = mesh
	layer.position = Vector3(0.0,y,0.0)
	layer.material_override = material
	add_child(layer)

func _add_metal_rim(node_name: String, y: float, radius: float, height: float, color: Color, roughness: float) -> void:
	var rim := MeshInstance3D.new()
	rim.name = node_name
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 96
	rim.mesh = mesh
	rim.position.y = y
	rim.material_override = _metal_mat(color,roughness,0.92)
	add_child(rim)

func _bottle_profile(neck_radius: float) -> Array[Vector2]:
	return [Vector2(-0.67,0.292),Vector2(-0.64,0.320),Vector2(-0.57,0.330),Vector2(0.52,0.330),Vector2(0.61,0.328),Vector2(0.69,0.317),Vector2(0.77,0.290),Vector2(0.84,0.251),Vector2(0.91,0.198),Vector2(0.98,neck_radius*1.16),Vector2(1.04,neck_radius),Vector2(1.25,neck_radius),Vector2(1.30,neck_radius*1.06),Vector2(1.34,neck_radius*1.13),Vector2(1.37,neck_radius*1.08)]

func _liquid_profile() -> Array[Vector2]:
	return [Vector2(-0.60,0.253),Vector2(-0.57,0.276),Vector2(-0.52,0.281),Vector2(0.555,0.281),Vector2(0.58,0.280)]

func _build_lathe_mesh(profile: Array[Vector2], cap_bottom: bool, cap_top: bool) -> ArrayMesh:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	if profile.size()<2:
		return ArrayMesh.new()
	for ring_index in range(profile.size()):
		var sample := profile[ring_index]
		var prev := profile[maxi(ring_index-1,0)]
		var next := profile[mini(ring_index+1,profile.size()-1)]
		var dy := next.x-prev.x
		var dr := next.y-prev.y
		var slope := dr/dy if absf(dy)>0.00001 else 0.0
		for side_index in range(BOTTLE_SEGMENTS+1):
			var u := float(side_index)/float(BOTTLE_SEGMENTS)
			var angle := u*TAU
			var radial := Vector3(cos(angle),0.0,sin(angle))
			vertices.append(Vector3(radial.x*sample.y,sample.x,radial.z*sample.y))
			normals.append(Vector3(radial.x,-slope,radial.z).normalized())
			uvs.append(Vector2(u,1.0-float(ring_index)/float(profile.size()-1)))
	for ring_index in range(profile.size()-1):
		var row := BOTTLE_SEGMENTS+1
		for side_index in range(BOTTLE_SEGMENTS):
			var a := ring_index*row+side_index
			var b := a+1
			var c := (ring_index+1)*row+side_index+1
			var d := (ring_index+1)*row+side_index
			indices.append(a); indices.append(d); indices.append(c)
			indices.append(a); indices.append(c); indices.append(b)
	if cap_bottom:
		_add_lathe_cap(vertices,normals,uvs,indices,profile[0],false)
	if cap_top:
		_add_lathe_cap(vertices,normals,uvs,indices,profile[profile.size()-1],true)
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	return mesh

func _add_lathe_cap(vertices: PackedVector3Array, normals: PackedVector3Array, uvs: PackedVector2Array, indices: PackedInt32Array, sample: Vector2, top: bool) -> void:
	var center_index := vertices.size()
	var normal := Vector3.UP if top else Vector3.DOWN
	vertices.append(Vector3(0,sample.x,0)); normals.append(normal); uvs.append(Vector2(0.5,0.5))
	var start := vertices.size()
	for side_index in range(BOTTLE_SEGMENTS+1):
		var u := float(side_index)/float(BOTTLE_SEGMENTS)
		var angle := u*TAU
		vertices.append(Vector3(cos(angle)*sample.y,sample.x,sin(angle)*sample.y)); normals.append(normal); uvs.append(Vector2(0.5+cos(angle)*0.5,0.5+sin(angle)*0.5))
	for side_index in range(BOTTLE_SEGMENTS):
		if top:
			indices.append(center_index); indices.append(start+side_index); indices.append(start+side_index+1)
		else:
			indices.append(center_index); indices.append(start+side_index+1); indices.append(start+side_index)

func _add_bottle_mouth_rim(body_color: Color, neck_radius: float, source_alpha: float, roughness: float) -> void:
	var rim := MeshInstance3D.new()
	rim.name = "BottleMouthRim"
	var mesh := CylinderMesh.new()
	mesh.top_radius = neck_radius+0.020
	mesh.bottom_radius = neck_radius+0.012
	mesh.height = 0.050
	mesh.radial_segments = 72
	mesh.cap_top = false
	mesh.cap_bottom = false
	rim.mesh = mesh
	rim.position.y = 1.345
	rim.material_override = _glass_mat(body_color.lightened(0.18),minf(source_alpha*0.36+0.035,0.22),maxf(roughness*0.75,0.020))
	rim.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(rim)

func _add_market_green_cap(neck_radius: float) -> void:
	var cap := MeshInstance3D.new()
	cap.name = "MarketGreenCap"
	var mesh := CylinderMesh.new()
	mesh.top_radius = neck_radius+0.036
	mesh.bottom_radius = neck_radius+0.032
	mesh.height = 0.105
	mesh.radial_segments = 72
	cap.mesh = mesh
	cap.position.y = 1.425
	cap.material_override = _mat(Color(0.12,0.38,0.15),0.46)
	add_child(cap)

func _add_condensation_for_radius(radius: float, y_min: float, y_max: float) -> void:
	for i in range(24):
		var angle := TAU*float((i*7)%24)/24.0
		var y := lerpf(y_min,y_max,float((i*11)%24)/23.0)
		var bead := MeshInstance3D.new()
		bead.name = "Condensation"
		var sm := SphereMesh.new()
		sm.radius = 0.006+0.002*float(i%3)
		sm.height = sm.radius*2.0
		sm.radial_segments = 10
		sm.rings = 5
		bead.mesh = sm
		bead.position = Vector3(sin(angle)*(radius+0.003),y,cos(angle)*(radius+0.003))
		bead.material_override = _glass_mat(Color(0.96,1.0,1.0),0.16,0.018)
		add_child(bead)

func _add_ring(root: Node3D, node_name: String, at: Vector3, radius: float, height: float, color: Color, roughness: float, alpha := 1.0) -> void:
	var ring := MeshInstance3D.new()
	ring.name = node_name
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 72
	ring.mesh = mesh
	ring.position = at
	var mat := _mat(color,roughness)
	if alpha<0.999:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color.a = clampf(alpha,0.05,0.96)
	ring.material_override = mat
	root.add_child(ring)

func _mat(color: Color, roughness: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	return mat

func _metal_mat(color: Color, roughness: float, metallic: float) -> StandardMaterial3D:
	var mat := _mat(color,clampf(roughness,0.08,0.75))
	mat.metallic = clampf(metallic,0.0,1.0)
	mat.metallic_specular = 0.72
	return mat

func _glass_mat(color: Color, alpha: float, roughness: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.albedo_color.a = clampf(alpha,0.02,0.48)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = clampf(roughness,0.014,0.18)
	mat.metallic_specular = 0.92
	mat.rim_enabled = true
	mat.rim = 0.88
	mat.rim_tint = 0.54
	mat.clearcoat_enabled = true
	mat.clearcoat = 0.94
	mat.clearcoat_roughness = 0.035
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	return mat

func _glass_edge_material(body_color: Color, source_alpha: float) -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = GLASS_EDGE_SHADER
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("edge_color",Color(0.74,0.86,0.90,1.0))
	material.set_shader_parameter("edge_alpha",clampf(source_alpha*1.30,0.21,0.28))
	material.set_shader_parameter("fresnel_power",3.2)
	material.render_priority = 1
	return material
