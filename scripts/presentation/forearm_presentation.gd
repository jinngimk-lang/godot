extends Node3D
class_name ForearmPresentation

const CURVE_RINGS := 30
const RING_SIDES := 28
const AUTHORED_HAND_SCALE := 3.60
const SUPPORT_FOLLOW_RATE := 8.5

var _applied := false
var _forearms: Dictionary = {}
var _cloth_materials: Dictionary = {}
var _skin_materials: Dictionary = {}
var _last_venue := ""
var _support_hand: HandVisual
var _cup: MeshInstance3D

func _ready() -> void:
	call_deferred("_apply")

func _process(delta: float) -> void:
	if not _applied:
		return
	var venue_id := _active_venue_id()
	if venue_id != _last_venue:
		_last_venue = venue_id
		_apply_venue_materials(venue_id)
	_update_support_hand(delta)

func _apply() -> void:
	if _applied:
		return
	var parent := get_parent()
	if parent == null:
		return
	_support_hand = parent.get_node_or_null("LeftHand") as HandVisual
	_cup = parent.get_node_or_null("Cup") as MeshInstance3D
	_scale_hand_preserve_pinch(parent.get_node_or_null("RightHand") as HandVisual)
	_scale_hand_preserve_pinch(_support_hand)
	_build_for_hand("RightHand",true)
	_build_for_hand("LeftHand",false)
	_applied = true
	_last_venue = ""

func _scale_hand_preserve_pinch(hand: HandVisual) -> void:
	if hand == null:
		return
	var authored := hand.get_node_or_null("AuthoredHand") as Node3D
	if authored == null:
		return
	var old_pinch := hand.get_pinch_world_position()
	authored.scale = Vector3.ONE*AUTHORED_HAND_SCALE
	hand.snap_to(hand.position)
	var new_pinch := hand.get_pinch_world_position()
	hand.position += old_pinch-new_pinch
	hand.set_grip_target(old_pinch)

func _update_support_hand(delta: float) -> void:
	if _support_hand == null or _cup == null:
		return
	if _active_venue_id() == "cafe_window":
		return
	var yaw := _cup.rotation.y
	var target := Vector3(0.76+sin(yaw)*0.10,0.18,0.48+cos(yaw)*0.045)
	var safe_delta := clampf(delta if is_finite(delta) else 0.0,0.0,0.1)
	var weight := 1.0-exp(-SUPPORT_FOLLOW_RATE*safe_delta)
	_support_hand.position = _support_hand.position.lerp(target,weight)
	_support_hand.rotation.y = lerp_angle(_support_hand.rotation.y,deg_to_rad(40.0)+yaw*0.32,weight)

func _build_for_hand(hand_name: String, dynamic_hand: bool) -> void:
	var parent := get_parent()
	if parent == null:
		return
	var hand := parent.get_node_or_null(hand_name) as Node3D
	if hand == null:
		return
	var authored := hand.get_node_or_null("AuthoredHand") as Node3D
	if authored == null:
		return
	var legacy_sleeve := authored.find_child("WristSleeve",true,false) as MeshInstance3D
	var legacy_cuff := authored.find_child("WristCuff",true,false) as MeshInstance3D
	if legacy_sleeve == null:
		return
	legacy_sleeve.visible = false
	if legacy_cuff != null:
		legacy_cuff.visible = false

	var cloth := _make_cafe_cloth()
	var skin: Material = _find_material(authored,"HandSkin") as Material
	if skin == null:
		var fallback_skin := StandardMaterial3D.new()
		fallback_skin.resource_name = "HandSkin"
		fallback_skin.albedo_color = Color(0.72,0.46,0.32,1.0)
		fallback_skin.roughness = 0.72
		skin = fallback_skin

	var start: Vector3 = _descendant_point_to_ancestor(authored,hand,Vector3(0.0,0.0,0.023))
	if not _finite_vector(start):
		return
	var start_world := hand.to_global(start)
	var cup_world := _cup.global_position if _cup != null else Vector3.ZERO
	var outward_sign := -1.0 if start_world.x < cup_world.x else 1.0
	if absf(start_world.x-cup_world.x) < 0.05:
		outward_sign = -1.0 if dynamic_hand else 1.0
	# Explicit world-space routing makes the arms leave through the side edges
	# like the reference photography instead of ending as visible tubes near the cup.
	var control_world := start_world+Vector3(outward_sign*0.82,-0.12,0.22)
	var end_world := start_world+Vector3(outward_sign*2.30,-0.30,0.58)
	var control := hand.to_local(control_world)
	var end := hand.to_local(end_world)

	var forearm := MeshInstance3D.new()
	forearm.name = "ForearmNatural"
	forearm.mesh = _build_curve_mesh(start,control,end)
	forearm.material_override = cloth
	forearm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	hand.add_child(forearm)
	_forearms[hand_name] = forearm
	_cloth_materials[hand_name] = cloth
	_skin_materials[hand_name] = skin

func _make_cafe_cloth() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.resource_name = "SleeveFabric"
	material.albedo_color = Color(0.68,0.62,0.54,1.0)
	material.roughness = 0.94
	return material

func _build_curve_mesh(start: Vector3, control: Vector3, end: Vector3) -> ArrayMesh:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()
	for ring_index in range(CURVE_RINGS):
		var t := float(ring_index)/float(CURVE_RINGS-1)
		var point := _quadratic_point(start,control,end,t)
		var tangent := _quadratic_tangent(start,control,end,t).normalized()
		if tangent.length_squared() <= 0.000001:
			tangent = Vector3.FORWARD
		var helper := Vector3.UP
		if absf(tangent.dot(helper)) > 0.94:
			helper = Vector3.RIGHT
		var ring_x := helper.cross(tangent).normalized()
		var ring_y := tangent.cross(ring_x).normalized()
		var radius := _radius_profile(t)
		var oval_height := lerpf(0.72,0.80,t)
		for side_index in range(RING_SIDES):
			var angle := TAU*float(side_index)/float(RING_SIDES)
			var cos_a := cos(angle)
			var sin_a := sin(angle)
			var radial := ring_x*cos_a*radius+ring_y*sin_a*radius*oval_height
			vertices.append(point+radial)
			normals.append((ring_x*cos_a+ring_y*sin_a/oval_height).normalized())
	for ring_index in range(CURVE_RINGS-1):
		var current := ring_index*RING_SIDES
		var next := (ring_index+1)*RING_SIDES
		for side_index in range(RING_SIDES):
			var side_next := (side_index+1)%RING_SIDES
			var a := current+side_index
			var b := next+side_index
			var c := next+side_next
			var d := current+side_next
			indices.append(a); indices.append(b); indices.append(c)
			indices.append(a); indices.append(c); indices.append(d)
	# Seal both ends so even a transitional camera angle never exposes a hollow tube.
	var start_center := vertices.size()
	vertices.append(start)
	normals.append(-_quadratic_tangent(start,control,end,0.0).normalized())
	var end_center := vertices.size()
	vertices.append(end)
	normals.append(_quadratic_tangent(start,control,end,1.0).normalized())
	for side_index in range(RING_SIDES):
		var side_next := (side_index+1)%RING_SIDES
		indices.append(start_center); indices.append(side_next); indices.append(side_index)
		var end_ring := (CURVE_RINGS-1)*RING_SIDES
		indices.append(end_center); indices.append(end_ring+side_index); indices.append(end_ring+side_next)
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	return mesh

func _radius_profile(t: float) -> float:
	var p := smoothstep(0.0,1.0,clampf(t,0.0,1.0))
	return lerpf(0.115,0.165,p)

func _active_venue_id() -> String:
	var parent := get_parent()
	if parent == null:
		return "cafe_window"
	var venue := parent.get_node_or_null("VenuePresentation")
	if venue != null and venue.has_method("get_active_profile_id"):
		return String(venue.call("get_active_profile_id"))
	return "cafe_window"

func _apply_venue_materials(venue_id: String) -> void:
	var use_cloth := venue_id=="cafe_window"
	for hand_name in _forearms.keys():
		var forearm := _forearms[hand_name] as MeshInstance3D
		if forearm == null:
			continue
		forearm.material_override = (_cloth_materials.get(hand_name) as Material) if use_cloth else (_skin_materials.get(hand_name) as Material)

func _find_material(node: Node, wanted_name: String):
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		if mesh_instance.material_override != null and mesh_instance.material_override.resource_name==wanted_name:
			return mesh_instance.material_override
		var mesh := mesh_instance.mesh
		if mesh != null:
			for surface_index in range(mesh.get_surface_count()):
				var material := mesh.surface_get_material(surface_index)
				if material != null and material.resource_name==wanted_name:
					return material
	for child in node.get_children():
		var found = _find_material(child,wanted_name)
		if found != null:
			return found
	return null

func _quadratic_point(start: Vector3, control: Vector3, end: Vector3, t: float) -> Vector3:
	var one_minus := 1.0-t
	return start*one_minus*one_minus+control*2.0*one_minus*t+end*t*t

func _quadratic_tangent(start: Vector3, control: Vector3, end: Vector3, t: float) -> Vector3:
	return (control-start)*(2.0*(1.0-t))+(end-control)*(2.0*t)

func _descendant_point_to_ancestor(descendant: Node3D, ancestor: Node3D, point: Vector3) -> Vector3:
	var current := descendant
	var converted := point
	while current!=ancestor:
		if current.is_set_as_top_level():
			return Vector3(INF,INF,INF)
		converted = current.transform*converted
		var parent := current.get_parent()
		if not (parent is Node3D):
			return Vector3(INF,INF,INF)
		current = parent as Node3D
	return converted

func _finite_vector(value: Vector3) -> bool:
	return is_finite(value.x) and is_finite(value.y) and is_finite(value.z)
