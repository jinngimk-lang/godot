extends Node3D
class_name ForearmPresentation

const CURVE_RINGS := 24
const RING_SIDES := 24

var _applied := false
var _forearms: Dictionary = {}
var _cloth_materials: Dictionary = {}
var _skin_materials: Dictionary = {}
var _last_venue := ""

func _ready() -> void:
	call_deferred("_apply")

func _process(_delta: float) -> void:
	if not _applied:
		return
	var venue_id := _active_venue_id()
	if venue_id == _last_venue:
		return
	_last_venue = venue_id
	_apply_venue_materials(venue_id)

func _apply() -> void:
	if _applied:
		return
	_build_for_hand("RightHand",true)
	_build_for_hand("LeftHand",false)
	_applied = true
	_last_venue = ""

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
	if legacy_sleeve == null or legacy_sleeve.material_override == null:
		return
	var cloth: Material = legacy_sleeve.material_override
	cloth.resource_name = "SleeveFabric"
	var skin: Material = _find_material(authored,"HandSkin") as Material
	if skin == null:
		var fallback_skin := StandardMaterial3D.new()
		fallback_skin.resource_name = "HandSkin"
		fallback_skin.albedo_color = Color(0.72,0.46,0.32,1.0)
		fallback_skin.roughness = 0.70
		skin = fallback_skin
	legacy_sleeve.visible = false

	var side := -1.0 if dynamic_hand else 1.0
	# Keep the extension close to the actual wrist. Previous values pushed a
	# dark tapered cone across half the screen; the reference hands instead have
	# a short anatomical forearm that exits the frame without becoming the hero.
	var start_authored := Vector3(0.0,0.0,0.022)
	var control_authored := Vector3(0.018*side,-0.003,0.105)
	var end_authored := Vector3(0.070*side,-0.010,0.270)
	var start: Vector3 = _descendant_point_to_ancestor(authored,hand,start_authored)
	var control: Vector3 = _descendant_point_to_ancestor(authored,hand,control_authored)
	var end: Vector3 = _descendant_point_to_ancestor(authored,hand,end_authored)
	if not _finite_vector(start) or not _finite_vector(control) or not _finite_vector(end):
		return

	var forearm := MeshInstance3D.new()
	forearm.name = "ForearmNatural"
	forearm.mesh = _build_curve_mesh(start,control,end)
	forearm.material_override = cloth
	forearm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	hand.add_child(forearm)
	_forearms[hand_name] = forearm
	_cloth_materials[hand_name] = cloth
	_skin_materials[hand_name] = skin

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
		var oval_height := lerpf(0.72,0.82,t)
		for side_index in range(RING_SIDES):
			var angle := TAU*float(side_index)/float(RING_SIDES)
			var cos_a := cos(angle)
			var sin_a := sin(angle)
			var radial := ring_x*cos_a*radius + ring_y*sin_a*radius*oval_height
			vertices.append(point+radial)
			normals.append((ring_x*cos_a + ring_y*sin_a/oval_height).normalized())
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
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	return mesh

func _radius_profile(t: float) -> float:
	return lerpf(0.050,0.074,smoothstep(0.0,1.0,clampf(t,0.0,1.0)))

func _active_venue_id() -> String:
	var parent := get_parent()
	if parent == null:
		return "cafe_window"
	var venue := parent.get_node_or_null("VenuePresentation")
	if venue != null and venue.has_method("get_active_profile_id"):
		return String(venue.call("get_active_profile_id"))
	return "cafe_window"

func _apply_venue_materials(venue_id: String) -> void:
	var use_cloth := venue_id == "cafe_window"
	for hand_name in _forearms.keys():
		var forearm := _forearms[hand_name] as MeshInstance3D
		if forearm == null:
			continue
		forearm.material_override = (_cloth_materials.get(hand_name) as Material) if use_cloth else (_skin_materials.get(hand_name) as Material)

func _find_material(node: Node, wanted_name: String):
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		if mesh_instance.material_override != null and mesh_instance.material_override.resource_name == wanted_name:
			return mesh_instance.material_override
		var mesh := mesh_instance.mesh
		if mesh != null:
			for surface_index in range(mesh.get_surface_count()):
				var material := mesh.surface_get_material(surface_index)
				if material != null and material.resource_name == wanted_name:
					return material
	for child in node.get_children():
		var found = _find_material(child,wanted_name)
		if found != null:
			return found
	return null

func _quadratic_point(start: Vector3, control: Vector3, end: Vector3, t: float) -> Vector3:
	var one_minus := 1.0-t
	return start*one_minus*one_minus + control*2.0*one_minus*t + end*t*t

func _quadratic_tangent(start: Vector3, control: Vector3, end: Vector3, t: float) -> Vector3:
	return (control-start)*(2.0*(1.0-t)) + (end-control)*(2.0*t)

func _descendant_point_to_ancestor(descendant: Node3D, ancestor: Node3D, point: Vector3) -> Vector3:
	var current := descendant
	var converted := point
	while current != ancestor:
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
