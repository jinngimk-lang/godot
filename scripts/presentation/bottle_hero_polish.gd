extends Node3D
class_name BottleHeroPolish

const HIGHLIGHT_ALPHA := 0.145
const OUTER_GLASS_ALPHA := 0.0
const EDGE_ALPHA := 0.19
const FRESNEL_POWER := 4.25
const LIQUID_ALPHA := 1.0
const LIQUID_TOP_Y := 0.72
const TARGET_FOCUS_Y := 0.42
const LATHE_SEGMENTS := 96
const CLEAR_EDGE_SHADER := """shader_type spatial;
render_mode blend_mix, cull_disabled, depth_draw_never;
uniform vec4 edge_color : source_color = vec4(0.985, 1.0, 1.0, 1.0);
uniform float edge_alpha = 0.19;
uniform float fresnel_power = 4.25;
void fragment() {
	float facing = abs(dot(normalize(NORMAL), normalize(VIEW)));
	float grazing = clamp(1.0 - facing, 0.0, 1.0);
	float fresnel = pow(grazing, fresnel_power);
	ALBEDO = edge_color.rgb;
	ALPHA = edge_alpha * fresnel;
	ROUGHNESS = mix(0.065, 0.018, fresnel);
	SPECULAR = 0.96;
	CLEARCOAT = 0.96;
	CLEARCOAT_ROUGHNESS = 0.035;
}
"""

var _active_kind := ""
var _product: ProductPresentation
var _clear_edge_material: ShaderMaterial

func _ready() -> void:
	call_deferred("_bind")

func _exit_tree() -> void:
	release_preview_resources()

func _process(_delta: float) -> void:
	if _product == null:
		_bind()
	if _product == null:
		return
	var kind := _product.get_active_kind()
	if kind != _active_kind:
		build_preview_for_kind(kind)
	rotation.y = _product.rotation.y
	var old_cap := _product.get_node_or_null("MarketGreenCap") as Node3D
	if old_cap != null:
		old_cap.visible = kind != "clear_bottle"
	if kind == "clear_bottle":
		_tune_base_bottle()

func get_visual_contract() -> Dictionary:
	return {
		"cap":"silver_crimp",
		"glass_highlight_alpha":HIGHLIGHT_ALPHA,
		"outer_glass_alpha":OUTER_GLASS_ALPHA,
		"edge_alpha":EDGE_ALPHA,
		"fresnel_power":FRESNEL_POWER,
		"orientation_safe_fresnel":true,
		"liquid_alpha":LIQUID_ALPHA,
		"liquid_top_y":LIQUID_TOP_Y,
		"liquid_shape":"shouldered",
		"target_focus_y":TARGET_FOCUS_Y,
		"highlight_count":2,
		"neck_ring":true
	}

func build_preview_for_kind(kind: String) -> void:
	_active_kind = kind
	release_preview_resources()
	if kind != "clear_bottle":
		return
	_build_liquid_hero()
	_build_metal_cap()
	_build_neck_ring()
	_build_highlight("BottleHighlightLeft",-0.222,0.27,0.92,HIGHLIGHT_ALPHA)
	_build_highlight("BottleHighlightRight",0.235,0.20,0.70,HIGHLIGHT_ALPHA*0.52)
	_tune_base_bottle()

func release_preview_resources() -> void:
	# The Yuzu hero uses runtime-created meshes/materials. Clear those resource
	# references before freeing their nodes so GL compatibility cannot keep the
	# final ArrayMesh/material alive through process shutdown or a scene switch.
	if is_instance_valid(_product) and _clear_edge_material != null:
		var edge := _product.get_node_or_null("BottleEdgeFresnel") as MeshInstance3D
		if edge != null and edge.material_override == _clear_edge_material:
			edge.material_override = null
	_clear_edge_material = null
	for child in get_children():
		if child is MeshInstance3D:
			var visual := child as MeshInstance3D
			visual.material_override = null
			visual.mesh = null
		child.free()

func _bind() -> void:
	var root := get_parent()
	if root == null:
		return
	_product = root.get_node_or_null("ProductPresentation") as ProductPresentation
	if _product != null:
		build_preview_for_kind(_product.get_active_kind())

func _tune_base_bottle() -> void:
	if _product == null:
		return
	var outer := _product.get_node_or_null("BottleOuterGlass") as MeshInstance3D
	if outer != null:
		outer.visible = false
	var inner := _product.get_node_or_null("BottleInnerGlass") as MeshInstance3D
	if inner != null:
		inner.visible = false
	var old_liquid := _product.get_node_or_null("BottleLiquid") as MeshInstance3D
	if old_liquid != null:
		old_liquid.visible = false
	var edge := _product.get_node_or_null("BottleEdgeFresnel") as MeshInstance3D
	if edge != null:
		edge.visible = true
		edge.scale = Vector3.ONE*1.0015
		_ensure_clear_edge_material(edge)
	var base_ring := _product.get_node_or_null("BottleBaseRing") as MeshInstance3D
	if base_ring != null:
		base_ring.visible = true
		if base_ring.material_override is StandardMaterial3D:
			var ring_material := base_ring.material_override as StandardMaterial3D
			ring_material.albedo_color = Color(0.96,0.99,1.0,0.18)
			ring_material.roughness = 0.04

func _ensure_clear_edge_material(edge: MeshInstance3D) -> void:
	if _clear_edge_material == null:
		var shader := Shader.new()
		shader.code = CLEAR_EDGE_SHADER
		_clear_edge_material = ShaderMaterial.new()
		_clear_edge_material.resource_name = "YuzuOrientationSafeGlassEdge"
		_clear_edge_material.shader = shader
		_clear_edge_material.render_priority = 1
		_clear_edge_material.set_shader_parameter("edge_color",Color(0.985,1.0,1.0,1.0))
		_clear_edge_material.set_shader_parameter("edge_alpha",EDGE_ALPHA)
		_clear_edge_material.set_shader_parameter("fresnel_power",FRESNEL_POWER)
	if edge.material_override != _clear_edge_material:
		edge.material_override = _clear_edge_material

func _build_liquid_hero() -> void:
	var liquid := MeshInstance3D.new()
	liquid.name = "BottleLiquidHero"
	# Inset bottle-following profile: broad body, then a visible shoulder taper.
	# The top cap sits well inside the shoulder rather than reading as a floating
	# cylindrical puck in the middle of the vessel.
	var profile: Array[Vector2] = [
		Vector2(-0.60,0.260),Vector2(-0.565,0.286),Vector2(-0.515,0.292),
		Vector2(0.46,0.292),Vector2(0.535,0.289),Vector2(0.600,0.278),
		Vector2(0.655,0.257),Vector2(LIQUID_TOP_Y,0.220)
	]
	liquid.mesh = _lathe_mesh(profile,true,true)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.925,0.89,0.665,1.0)
	material.roughness = 0.27
	material.metallic_specular = 0.10
	material.clearcoat_enabled = true
	material.clearcoat = 0.10
	material.clearcoat_roughness = 0.23
	liquid.material_override = material
	liquid.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(liquid)

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
	vertices.append(Vector3(0,sample.x,0)); normals.append(normal); uvs.append(Vector2(0.5,0.5))
	var start := vertices.size()
	for side_index in range(LATHE_SEGMENTS+1):
		var u := float(side_index)/float(LATHE_SEGMENTS)
		var angle := u*TAU
		vertices.append(Vector3(cos(angle)*sample.y,sample.x,sin(angle)*sample.y))
		normals.append(normal); uvs.append(Vector2(0.5+cos(angle)*0.5,0.5+sin(angle)*0.5))
	for side_index in range(LATHE_SEGMENTS):
		if top:
			indices.append(center); indices.append(start+side_index); indices.append(start+side_index+1)
		else:
			indices.append(center); indices.append(start+side_index+1); indices.append(start+side_index)

func _build_metal_cap() -> void:
	var cap := MeshInstance3D.new()
	cap.name = "BottleMetalCap"
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.208
	mesh.bottom_radius = 0.212
	mesh.height = 0.108
	mesh.radial_segments = 96
	cap.mesh = mesh
	cap.position.y = 1.425
	cap.material_override = _metal(Color(0.80,0.82,0.82),0.20)
	add_child(cap)
	for i in range(3):
		var ridge := MeshInstance3D.new()
		ridge.name = "BottleCapCrimp%d" % i
		var ridge_mesh := CylinderMesh.new()
		ridge_mesh.top_radius = 0.217
		ridge_mesh.bottom_radius = 0.217
		ridge_mesh.height = 0.010
		ridge_mesh.radial_segments = 96
		ridge.mesh = ridge_mesh
		ridge.position.y = 1.390+float(i)*0.034
		ridge.material_override = _metal(Color(0.88,0.89,0.88),0.16)
		add_child(ridge)

func _build_neck_ring() -> void:
	var ring := MeshInstance3D.new()
	ring.name = "BottleNeckRing"
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.195
	mesh.bottom_radius = 0.194
	mesh.height = 0.036
	mesh.radial_segments = 96
	mesh.cap_top = false
	mesh.cap_bottom = false
	ring.mesh = mesh
	ring.position.y = 1.337
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.99,1.0,1.0,0.095)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.roughness = 0.024
	material.metallic_specular = 0.96
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	ring.material_override = material
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ring)

func _build_highlight(node_name: String, x: float, y: float, height: float, alpha: float) -> void:
	var highlight := MeshInstance3D.new()
	highlight.name = node_name
	var quad := QuadMesh.new()
	quad.size = Vector2(0.016,height)
	highlight.mesh = quad
	highlight.position = Vector3(x,y,0.336)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(1.0,1.0,0.99,alpha)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.roughness = 0.025
	material.metallic_specular = 0.98
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.render_priority = 3
	highlight.material_override = material
	highlight.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(highlight)

func _metal(color: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = 0.93
	material.metallic_specular = 0.82
	return material
