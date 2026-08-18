extends Node3D
class_name CinematicHandPresentation

const HAND_NAMES := ["RightHand", "LeftHand"]
const FOREARM_RINGS := 18
const FOREARM_SIDES := 28
const VISIBLE_WRIST_LOCAL := Vector3(0.0,0.094,0.004)

var _hands: Dictionary = {}
var _cup: MeshInstance3D
var _venue: VenuePresentation
var _skin_material: StandardMaterial3D
var _nail_material: StandardMaterial3D
var _cloth_material: StandardMaterial3D
var _cuff_material: StandardMaterial3D
var _last_venue_id := ""

func _ready() -> void:
	_build_materials()
	call_deferred("_bind")

func _process(_delta: float) -> void:
	if _hands.size() < HAND_NAMES.size():
		_bind()
	for hand_name in _hands.keys():
		_enforce_render_authority(String(hand_name))
	_update_venue_materials()

func is_skin_physically_lit() -> bool:
	return _skin_material == null or _skin_material is StandardMaterial3D

func get_ready_hand_count() -> int:
	return _hands.size()

func get_visible_authored_hand_mesh_count() -> int:
	var count := 0
	for hand_name in _hands.keys():
		var hand := (_hands[hand_name] as Dictionary).get("hand") as HandVisual
		if hand != null:
			count += _count_visible_meshes(hand.get_node_or_null("AuthoredHand"))
	return count

func get_polished_authored_mesh_count() -> int:
	return 0

func get_visible_realtime_shell_count() -> int:
	var count := 0
	for hand_name in _hands.keys():
		var hand := (_hands[hand_name] as Dictionary).get("hand") as HandVisual
		if hand != null:
			var shell := hand.get_node_or_null("RealtimeHandShell") as Node3D
			if shell != null and shell.visible:
				count += 1
	return count

func get_visible_primitive_shell_mesh_count() -> int:
	var count := 0
	for hand_name in _hands.keys():
		var hand := (_hands[hand_name] as Dictionary).get("hand") as HandVisual
		if hand == null:
			continue
		var shell := hand.get_node_or_null("CinematicShell") as Node
		if shell != null:
			count += _count_visible_meshes(shell)
	return count

func get_cinematic_forearm_span(hand_name: String = "RightHand") -> float:
	if not _hands.has(hand_name):
		return 0.0
	var forearm := (_hands[hand_name] as Dictionary).get("forearm") as MeshInstance3D
	if forearm == null or forearm.mesh == null:
		return 0.0
	return forearm.mesh.get_aabb().size.length()

func _build_materials() -> void:
	_skin_material = StandardMaterial3D.new()
	_skin_material.resource_name = "CinematicHandSkin"
	_skin_material.albedo_color = Color(0.72,0.50,0.38,1.0)
	_skin_material.roughness = 0.53
	_skin_material.metallic = 0.0
	_skin_material.metallic_specular = 0.34
	_nail_material = StandardMaterial3D.new()
	_nail_material.resource_name = "CinematicHandNail"
	_nail_material.albedo_color = Color(0.87,0.68,0.60,1.0)
	_nail_material.roughness = 0.40
	_nail_material.metallic = 0.0
	_nail_material.metallic_specular = 0.42
	_cloth_material = StandardMaterial3D.new()
	_cloth_material.resource_name = "CinematicSleeve"
	_cloth_material.albedo_color = Color(0.055,0.052,0.049,1.0)
	_cloth_material.roughness = 0.92
	_cloth_material.metallic = 0.0
	_cloth_material.metallic_specular = 0.08
	_cuff_material = StandardMaterial3D.new()
	_cuff_material.resource_name = "CinematicSleeveCuff"
	_cuff_material.albedo_color = Color(0.085,0.080,0.074,1.0)
	_cuff_material.roughness = 0.95
	_cuff_material.metallic = 0.0
	_cuff_material.metallic_specular = 0.07

func _bind() -> void:
	var parent := get_parent() as Node3D
	if parent == null:
		return
	_cup = parent.get_node_or_null("Cup") as MeshInstance3D
	_venue = parent.get_node_or_null("VenuePresentation") as VenuePresentation
	for hand_name in HAND_NAMES:
		if not _hands.has(hand_name):
			_bind_hand(parent,hand_name)

func _bind_hand(parent: Node3D, hand_name: String) -> void:
	var hand := parent.get_node_or_null(hand_name) as HandVisual
	if hand == null or not hand.is_using_realtime_shell():
		return
	var authored := hand.get_node_or_null("AuthoredHand") as Node3D
	if authored == null:
		return
	var legacy_forearm := hand.get_node_or_null("ForearmNatural") as MeshInstance3D
	if legacy_forearm == null:
		return
	var shell := hand.get_node_or_null("RealtimeHandShell") as Node3D
	if shell == null:
		return
	_hide_render_meshes(authored)
	_apply_realtime_shell_materials(hand,shell)
	_hands[hand_name] = {
		"hand":hand,
		"authored":authored,
		"shell":shell,
		"forearm":null,
		"cuff":null,
	}
	_build_cinematic_forearm(hand_name)
	_enforce_render_authority(hand_name)

func _enforce_render_authority(hand_name: String) -> void:
	if not _hands.has(hand_name):
		return
	var hand := (_hands[hand_name] as Dictionary).get("hand") as HandVisual
	if hand == null:
		return
	_hide_render_meshes(hand.get_node_or_null("AuthoredHand"))
	for path in ["ForearmNatural","SleeveCuffNatural","AuthoredHand/WristSleeve","AuthoredHand/WristCuff"]:
		var node := hand.get_node_or_null(path) as Node3D
		if node != null:
			node.visible = false
	var shell := hand.get_node_or_null("RealtimeHandShell") as Node3D
	if shell != null:
		shell.visible = true

func _hide_render_meshes(node: Node) -> void:
	if node == null:
		return
	if node is MeshInstance3D:
		(node as MeshInstance3D).visible = false
	for child in node.get_children():
		_hide_render_meshes(child)

func _apply_realtime_shell_materials(hand: HandVisual, shell: Node) -> void:
	if shell is MeshInstance3D:
		(shell as MeshInstance3D).material_override = _skin_material
	for child in shell.get_children():
		_apply_realtime_shell_materials(hand,child)
	for nail_name in ["IndexNail","ThumbNail"]:
		var nail := hand.get_node_or_null(nail_name) as MeshInstance3D
		if nail != null:
			nail.material_override = _nail_material

func _build_cinematic_forearm(hand_name: String) -> void:
	if not _hands.has(hand_name):
		return
	var data: Dictionary = _hands[hand_name]
	var hand := data.get("hand") as HandVisual
	if hand == null:
		return
	var start := VISIBLE_WRIST_LOCAL
	var start_world := hand.to_global(start)
	var cup_world := _cup.global_position if _cup != null else Vector3.ZERO
	var outward_sign := -1.0 if start_world.x < cup_world.x else 1.0
	if absf(start_world.x-cup_world.x) < 0.04:
		outward_sign = -1.0 if hand_name == "RightHand" else 1.0
	var control_a_world := start_world+Vector3(outward_sign*0.16,-0.17,0.045)
	var control_b_world := start_world+Vector3(outward_sign*0.42,-0.36,0.090)
	var end_world := start_world+Vector3(outward_sign*0.76,-0.59,0.135)
	var control_a := hand.to_local(control_a_world)
	var control_b := hand.to_local(control_b_world)
	var end := hand.to_local(end_world)
	var forearm := MeshInstance3D.new()
	forearm.name = "CinematicForearm"
	forearm.mesh = _build_curve_mesh(start,control_a,control_b,end,0.058,0.088)
	forearm.material_override = _cloth_material
	forearm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	hand.add_child(forearm)
	data["forearm"] = forearm
	var cuff := MeshInstance3D.new()
	cuff.name = "CinematicCuff"
	var cuff_mesh := CylinderMesh.new()
	cuff_mesh.top_radius = 0.065
	cuff_mesh.bottom_radius = 0.070
	cuff_mesh.height = 0.072
	cuff_mesh.radial_segments = 32
	cuff.mesh = cuff_mesh
	cuff.material_override = _cuff_material
	var tangent := (control_a-start).normalized()
	_place_cylinder(cuff,start-tangent*0.010,start+tangent*0.062)
	hand.add_child(cuff)
	data["cuff"] = cuff
	_hands[hand_name] = data

func _build_curve_mesh(start: Vector3, control_a: Vector3, control_b: Vector3, end: Vector3, start_radius: float, end_radius: float) -> ArrayMesh:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	for ring_index in range(FOREARM_RINGS):
		var t := float(ring_index)/float(FOREARM_RINGS-1)
		var point := _cubic_point(start,control_a,control_b,end,t)
		var tangent := _cubic_tangent(start,control_a,control_b,end,t).normalized()
		if tangent.length_squared() <= 0.000001:
			tangent = Vector3.FORWARD
		var helper := Vector3.UP
		if absf(tangent.dot(helper)) > 0.94:
			helper = Vector3.RIGHT
		var ring_x := helper.cross(tangent).normalized()
		var ring_y := tangent.cross(ring_x).normalized()
		var radius := lerpf(start_radius,end_radius,smoothstep(0.0,1.0,t))
		var flatten := lerpf(0.70,0.76,t)
		for side_index in range(FOREARM_SIDES):
			var u := float(side_index)/float(FOREARM_SIDES)
			var angle := TAU*u
			var fold := 1.0+0.012*sin(angle*3.0+t*4.0)
			var radial := ring_x*(cos(angle)*radius*fold)+ring_y*(sin(angle)*radius*flatten*fold)
			vertices.append(point+radial)
			normals.append(radial.normalized())
			uvs.append(Vector2(u,t))
	for ring_index in range(FOREARM_RINGS-1):
		var current := ring_index*FOREARM_SIDES
		var next := (ring_index+1)*FOREARM_SIDES
		for side_index in range(FOREARM_SIDES):
			var side_next := (side_index+1)%FOREARM_SIDES
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
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	return mesh

func _place_cylinder(instance: MeshInstance3D, a: Vector3, b: Vector3) -> void:
	var delta := b-a
	var y_axis := delta.normalized()
	if y_axis.length_squared() <= 0.000001:
		y_axis = Vector3.DOWN
	var helper := Vector3.FORWARD
	if absf(y_axis.dot(helper)) > 0.95:
		helper = Vector3.RIGHT
	var x_axis := helper.cross(y_axis).normalized()
	var z_axis := y_axis.cross(x_axis).normalized()
	instance.transform = Transform3D(Basis(x_axis,y_axis,z_axis),(a+b)*0.5)

func _update_venue_materials() -> void:
	if _venue == null:
		return
	var venue_id := _venue.get_active_profile_id()
	if venue_id == _last_venue_id:
		return
	_last_venue_id = venue_id
	var cafe := venue_id == "cafe_window"
	for hand_name in _hands.keys():
		var data: Dictionary = _hands[hand_name]
		var hand := data.get("hand") as HandVisual
		var shell := data.get("shell") as Node
		if hand != null and shell != null:
			_apply_realtime_shell_materials(hand,shell)
		var forearm := data.get("forearm") as MeshInstance3D
		var cuff := data.get("cuff") as MeshInstance3D
		if forearm != null:
			forearm.material_override = _cloth_material if cafe else _skin_material
		if cuff != null:
			cuff.visible = cafe
			cuff.material_override = _cuff_material

func _count_visible_meshes(node: Node) -> int:
	if node == null:
		return 0
	var count := 0
	if node is MeshInstance3D and (node as MeshInstance3D).visible:
		count += 1
	for child in node.get_children():
		count += _count_visible_meshes(child)
	return count

func _cubic_point(a: Vector3,b: Vector3,c: Vector3,d: Vector3,t: float) -> Vector3:
	var inv := 1.0-t
	return a*inv*inv*inv+b*3.0*inv*inv*t+c*3.0*inv*t*t+d*t*t*t

func _cubic_tangent(a: Vector3,b: Vector3,c: Vector3,d: Vector3,t: float) -> Vector3:
	var inv := 1.0-t
	return (b-a)*3.0*inv*inv+(c-b)*6.0*inv*t+(d-c)*3.0*t*t
