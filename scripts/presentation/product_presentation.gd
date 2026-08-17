extends Node3D
class_name ProductPresentation

const BOTTLE_SEGMENTS := 80
const GLASS_EDGE_SHADER := """shader_type spatial;
render_mode blend_mix, cull_disabled, depth_draw_never;
uniform vec4 edge_color : source_color = vec4(1.0, 0.78, 0.52, 1.0);
uniform float edge_alpha = 0.24;
uniform float fresnel_power = 3.2;
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
	if requested not in ["paper_cup","amber_bottle","clear_bottle"]:
		requested = "paper_cup"
	_active_kind = requested
	for child in get_children():
		child.free()
	if requested == "amber_bottle":
		_build_bottle(profile,true)
	elif requested == "clear_bottle":
		_build_bottle(profile,false)
	else:
		_build_paper(profile)
	_build_contact_shadow(requested)

func apply_to_base(body: MeshInstance3D, lid: MeshInstance3D, profile: Dictionary) -> void:
	if body == null:
		return
	var kind := String(profile.get("kind","paper_cup"))
	var paper := kind == "paper_cup"
	body.visible = paper
	if paper:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(profile.get("body_color",Color(0.89,0.84,0.74)))
		mat.roughness = float(profile.get("roughness",0.90))
		mat.metallic = 0.0
		body.material_override = mat
	if lid != null:
		lid.visible = paper
		if paper:
			var lid_mat := StandardMaterial3D.new()
			lid_mat.albedo_color = Color(profile.get("lid_color",Color(0.025,0.024,0.022)))
			lid_mat.roughness = 0.16
			lid_mat.metallic = 0.02
			lid.material_override = lid_mat

func set_inspection_yaw(yaw: float) -> void:
	rotation.y = yaw if is_finite(yaw) else 0.0

func _build_contact_shadow(kind: String) -> void:
	var shadow := MeshInstance3D.new()
	shadow.name = "ProductContactShadow"
	var quad := QuadMesh.new()
	quad.size = Vector2(0.98,0.50) if kind == "paper_cup" else Vector2(0.76,0.41)
	shadow.mesh = quad
	shadow.position = Vector3(0.0,-0.632,0.015)
	shadow.rotation_degrees = Vector3(-90.0,0.0,0.0)
	shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var shader := Shader.new()
	shader.code = CONTACT_SHADOW_SHADER
	var material := ShaderMaterial.new()
	material.shader = shader
	var tone := Color(0.045,0.024,0.012,0.26)
	if kind == "amber_bottle":
		tone = Color(0.030,0.012,0.006,0.29)
	elif kind == "clear_bottle":
		tone = Color(0.060,0.075,0.080,0.20)
	material.set_shader_parameter("shadow_color",tone)
	material.render_priority = -2
	shadow.material_override = material
	add_child(shadow)

func _build_paper(profile: Dictionary) -> void:
	var root := Node3D.new()
	root.name = "CupPaperDetails"
	add_child(root)
	var body_color := Color(profile.get("body_color",Color(0.89,0.84,0.74)))
	_add_ring(root,"PaperBaseFold",Vector3(0,-0.655,0),0.445,0.020,body_color.darkened(0.055),0.93)
	_add_ring(root,"PaperLip",Vector3(0,0.735,0),0.535,0.025,body_color.lightened(0.025),0.74)
	var seam := MeshInstance3D.new()
	seam.name = "PaperSeam"
	var seam_mesh := BoxMesh.new()
	seam_mesh.size = Vector3(0.010,1.12,0.007)
	seam.mesh = seam_mesh
	seam.position = Vector3(0.0,0.02,-0.526)
	seam.material_override = _mat(body_color.darkened(0.055),0.96)
	root.add_child(seam)

func _build_bottle(profile: Dictionary, amber: bool) -> void:
	var body_color := Color(profile.get("body_color",Color(0.38,0.11,0.024) if amber else Color(0.94,0.985,0.98)))
	var neck_radius := float(profile.get("neck_radius",0.175 if amber else 0.17))
	var source_alpha := float(profile.get("glass_alpha",0.36 if amber else 0.16))
	var roughness := float(profile.get("roughness",0.048 if amber else 0.040))
	var outer_profile := _bottle_profile(neck_radius,amber)
	var outer_mesh := _build_lathe_mesh(outer_profile,false,false)

	var outer := MeshInstance3D.new()
	outer.name = "BottleOuterGlass"
	outer.mesh = outer_mesh
	var outer_color := body_color.lightened(0.10) if amber else body_color
	outer.material_override = _glass_mat(outer_color,source_alpha*(0.30 if amber else 0.62),roughness)
	outer.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(outer)

	var edge := MeshInstance3D.new()
	edge.name = "BottleEdgeFresnel"
	edge.mesh = outer_mesh
	edge.scale = Vector3.ONE * 1.006
	edge.material_override = _glass_edge_material(body_color, source_alpha, amber)
	edge.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(edge)

	var inner_profile: Array[Vector2] = []
	for sample in outer_profile:
		inner_profile.append(Vector2(sample.x,maxf(sample.y-0.021,0.035)))
	var inner := MeshInstance3D.new()
	inner.name = "BottleInnerGlass"
	inner.mesh = _build_lathe_mesh(inner_profile,false,false)
	inner.material_override = _glass_mat(body_color.lightened(0.26 if amber else 0.16),source_alpha*0.10,0.023)
	inner.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(inner)

	var liquid := MeshInstance3D.new()
	liquid.name = "BottleLiquid"
	liquid.mesh = _build_lathe_mesh(_liquid_profile(amber),true,true)
	var liquid_mat := StandardMaterial3D.new()
	liquid_mat.albedo_color = Color(0.60,0.22,0.035,0.14) if amber else Color(profile.get("liquid_color",Color(0.91,0.93,0.70,0.40)))
	liquid_mat.albedo_color.a = 0.14 if amber else 0.40
	liquid_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	liquid_mat.roughness = 0.08
	liquid_mat.metallic_specular = 0.56
	liquid.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	liquid.material_override = liquid_mat
	add_child(liquid)

	_add_ring(self,"BottleBaseRing",Vector3(0,-0.655,0),0.334 if amber else 0.322,0.020,body_color.lightened(0.08),0.050,minf(source_alpha*0.58+0.10,0.45))
	_add_bottle_mouth_rim(body_color,neck_radius,source_alpha,roughness)

	if not amber:
		_add_condensation()

func _bottle_profile(neck_radius: float, amber: bool) -> Array[Vector2]:
	var body := 0.342 if amber else 0.330
	return [
		Vector2(-0.67,body*0.88),
		Vector2(-0.64,body*0.97),
		Vector2(-0.57,body),
		Vector2(0.52,body),
		Vector2(0.61,body*0.995),
		Vector2(0.69,body*0.96),
		Vector2(0.77,body*0.88),
		Vector2(0.84,body*0.76),
		Vector2(0.91,body*0.60),
		Vector2(0.98,neck_radius*1.16),
		Vector2(1.05,neck_radius),
		Vector2(1.38,neck_radius),
		Vector2(1.43,neck_radius*1.06),
		Vector2(1.47,neck_radius*1.13),
		Vector2(1.50,neck_radius*1.08)
	]

func _liquid_profile(amber: bool) -> Array[Vector2]:
	var radius := 0.291 if amber else 0.281
	var top_y := 0.19 if amber else 0.46
	return [
		Vector2(-0.60,radius*0.90),
		Vector2(-0.57,radius*0.98),
		Vector2(-0.52,radius),
		Vector2(top_y-0.025,radius),
		Vector2(top_y,radius*0.995)
	]

func _build_lathe_mesh(profile: Array[Vector2], cap_bottom: bool, cap_top: bool) -> ArrayMesh:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	if profile.size() < 2:
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
	vertices.append(Vector3(0,sample.x,0))
	normals.append(normal)
	uvs.append(Vector2(0.5,0.5))
	var start := vertices.size()
	for side_index in range(BOTTLE_SEGMENTS+1):
		var u := float(side_index)/float(BOTTLE_SEGMENTS)
		var angle := u*TAU
		vertices.append(Vector3(cos(angle)*sample.y,sample.x,sin(angle)*sample.y))
		normals.append(normal)
		uvs.append(Vector2(0.5+cos(angle)*0.5,0.5+sin(angle)*0.5))
	for side_index in range(BOTTLE_SEGMENTS):
		if top:
			indices.append(center_index); indices.append(start+side_index); indices.append(start+side_index+1)
		else:
			indices.append(center_index); indices.append(start+side_index+1); indices.append(start+side_index)

func _add_bottle_mouth_rim(body_color: Color, neck_radius: float, source_alpha: float, roughness: float) -> void:
	var rim := MeshInstance3D.new()
	rim.name = "BottleMouthRim"
	var rim_mesh := CylinderMesh.new()
	rim_mesh.top_radius = neck_radius + 0.020
	rim_mesh.bottom_radius = neck_radius + 0.012
	rim_mesh.height = 0.055
	rim_mesh.radial_segments = 72
	rim_mesh.cap_top = false
	rim_mesh.cap_bottom = false
	rim.mesh = rim_mesh
	rim.position = Vector3(0,1.475,0)
	rim.material_override = _glass_mat(body_color.lightened(0.12),minf(source_alpha*0.52+0.055,0.34),maxf(roughness*0.82,0.024))
	rim.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(rim)

func _add_condensation() -> void:
	for i in range(20):
		var angle := TAU*float((i*7)%20)/20.0
		var y := -0.44+float((i*11)%20)/20.0*1.20
		var bead := MeshInstance3D.new()
		bead.name = "Condensation"
		var sm := SphereMesh.new()
		sm.radius = 0.007+0.002*float(i%3)
		sm.height = sm.radius*2.0
		sm.radial_segments = 10
		sm.rings = 5
		bead.mesh = sm
		bead.position = Vector3(sin(angle)*0.334,y,cos(angle)*0.334)
		bead.material_override = _glass_mat(Color(0.96,1.0,1.0),0.20,0.020)
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
	if alpha < 0.999:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color.a = clampf(alpha,0.08,0.96)
		mat.rim_enabled = true
		mat.rim = 0.55
		mat.rim_tint = 0.38
	ring.material_override = mat
	root.add_child(ring)

func _mat(color: Color, roughness: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	return mat

func _glass_mat(color: Color, alpha: float, roughness: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.albedo_color.a = clampf(alpha,0.04,0.60)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = clampf(roughness,0.018,0.22)
	mat.metallic = 0.0
	mat.metallic_specular = 0.86
	mat.rim_enabled = true
	mat.rim = 0.80
	mat.rim_tint = 0.46
	mat.clearcoat_enabled = true
	mat.clearcoat = 0.82
	mat.clearcoat_roughness = 0.055
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	return mat

func _glass_edge_material(body_color: Color, source_alpha: float, amber: bool) -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = GLASS_EDGE_SHADER
	var material := ShaderMaterial.new()
	material.shader = shader
	var edge_color := body_color.lightened(0.48 if amber else 0.03)
	if not amber:
		edge_color = Color(0.74,0.86,0.90,1.0)
	material.set_shader_parameter("edge_color", edge_color)
	material.set_shader_parameter("edge_alpha", clampf(source_alpha * (0.82 if amber else 1.46), 0.13, 0.34))
	material.set_shader_parameter("fresnel_power", 3.15 if amber else 3.25)
	material.render_priority = 1
	return material
