extends Node3D
class_name BottleHeroPolish

const HIGHLIGHT_ALPHA := 0.125
const OUTER_GLASS_ALPHA := 0.0
const LIQUID_ALPHA := 0.74
const TARGET_FOCUS_Y := 0.42

var _active_kind := ""
var _product: ProductPresentation

func _ready() -> void:
	call_deferred("_bind")

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
		"liquid_alpha":LIQUID_ALPHA,
		"target_focus_y":TARGET_FOCUS_Y,
		"highlight_count":2,
		"neck_ring":true
	}

func build_preview_for_kind(kind: String) -> void:
	_active_kind = kind
	for child in get_children():
		child.free()
	if kind != "clear_bottle":
		return
	_build_metal_cap()
	_build_neck_ring()
	_build_highlight("BottleHighlightLeft",-0.222,0.27,0.92,HIGHLIGHT_ALPHA)
	_build_highlight("BottleHighlightRight",0.235,0.20,0.70,HIGHLIGHT_ALPHA*0.52)
	_tune_base_bottle()

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
	# The direct target reads the vessel through its liquid, bright contour and
	# specular streaks. Alpha-blended full glass shells stack into a milky blue
	# bottle in GL compatibility, so keep those shells out of the color pass and
	# let the dedicated Fresnel/highlight geometry describe the transparent glass.
	var outer := _product.get_node_or_null("BottleOuterGlass") as MeshInstance3D
	if outer != null:
		outer.visible = false
	var inner := _product.get_node_or_null("BottleInnerGlass") as MeshInstance3D
	if inner != null:
		inner.visible = false
	var liquid := _product.get_node_or_null("BottleLiquid") as MeshInstance3D
	if liquid != null and liquid.material_override is StandardMaterial3D:
		liquid.visible = true
		var liquid_material := liquid.material_override as StandardMaterial3D
		liquid_material.albedo_color = Color(0.945,0.925,0.685,LIQUID_ALPHA)
		liquid_material.roughness = 0.11
		liquid_material.metallic_specular = 0.24
	var edge := _product.get_node_or_null("BottleEdgeFresnel") as MeshInstance3D
	if edge != null and edge.material_override is ShaderMaterial:
		edge.visible = true
		edge.scale = Vector3.ONE*1.002
		var edge_material := edge.material_override as ShaderMaterial
		edge_material.set_shader_parameter("edge_color",Color(0.965,0.995,1.0,1.0))
		edge_material.set_shader_parameter("edge_alpha",0.38)
		edge_material.set_shader_parameter("fresnel_power",2.35)
	var base_ring := _product.get_node_or_null("BottleBaseRing") as MeshInstance3D
	if base_ring != null:
		base_ring.visible = true
		if base_ring.material_override is StandardMaterial3D:
			var ring_material := base_ring.material_override as StandardMaterial3D
			ring_material.albedo_color = Color(0.96,0.99,1.0,0.22)
			ring_material.roughness = 0.04

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
	material.albedo_color = Color(0.99,1.0,1.0,0.13)
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
