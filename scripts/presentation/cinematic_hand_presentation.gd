extends Node3D
class_name CinematicHandPresentation

const HAND_NAMES := ["RightHand", "LeftHand"]
const FINGER_NAMES := ["Thumb", "Index", "Middle", "Ring", "Little"]
const FOREARM_RINGS := 28
const FOREARM_SIDES := 28
const AUTHORED_SCALE_READY := 3.80

var _hands: Dictionary = {}
var _camera: Camera3D
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
		_refresh_hand(String(hand_name))
	_update_venue_materials()

func get_shell_ready_count() -> int:
	return _hands.size()

func get_visible_legacy_hand_mesh_count() -> int:
	var count := 0
	for hand_name in _hands.keys():
		var data: Dictionary = _hands[hand_name]
		var authored := data.get("authored") as Node
		if authored != null:
			count += _count_visible_meshes(authored)
	return count

func get_shell_piece_count(hand_name: String = "RightHand") -> int:
	if not _hands.has(hand_name):
		return 0
	var data: Dictionary = _hands[hand_name]
	var shell := data.get("shell") as Node
	if shell == null:
		return 0
	return _count_meshes(shell)

func get_cinematic_forearm_span(hand_name: String = "RightHand") -> float:
	if not _hands.has(hand_name):
		return 0.0
	var data: Dictionary = _hands[hand_name]
	var forearm := data.get("forearm") as MeshInstance3D
	if forearm == null or forearm.mesh == null:
		return 0.0
	return forearm.mesh.get_aabb().size.length()

func _bind() -> void:
	var parent := get_parent() as Node3D
	if parent == null:
		return
	_camera = parent.get_node_or_null("Camera") as Camera3D
	_cup = parent.get_node_or_null("Cup") as MeshInstance3D
	_venue = parent.get_node_or_null("VenuePresentation") as VenuePresentation
	for hand_name in HAND_NAMES:
		if _hands.has(hand_name):
			continue
		_bind_hand(parent, hand_name)

func _bind_hand(parent: Node3D, hand_name: String) -> void:
	var hand := parent.get_node_or_null(hand_name) as HandVisual
	if hand == null:
		return
	var authored := hand.get_node_or_null("AuthoredHand") as Node3D
	if authored == null or authored.scale.x < AUTHORED_SCALE_READY:
		return
	var skeleton := _find_skeleton(authored)
	if skeleton == null:
		return

	# Keep the repository-local authored rig and authored poses as animation
	# authority, but retire its low-poly render surface. The new shell below is
	# reconstructed every frame from the live bone pose, so interaction anchors,
	# Cup/Pinch animations and gameplay ownership stay untouched.
	_set_mesh_visibility_recursive(authored, false)
	var legacy_forearm := hand.get_node_or_null("ForearmNatural") as MeshInstance3D
	if legacy_forearm != null:
		legacy_forearm.visible = false
	var legacy_cuff := hand.get_node_or_null("SleeveCuffNatural") as MeshInstance3D
	if legacy_cuff != null:
		legacy_cuff.visible = false

	var shell := Node3D.new()
	shell.name = "CinematicShell"
	hand.add_child(shell)
	var pieces := _build_shell_pieces(shell)
	var suffix := "R" if hand_name == "RightHand" else "L"
	var data := {
		"hand": hand,
		"authored": authored,
		"skeleton": skeleton,
		"shell": shell,
		"pieces": pieces,
		"suffix": suffix,
		"forearm": null,
		"cuff": null,
		"forearm_built": false,
	}
	_hands[hand_name] = data
	_refresh_hand(hand_name)

func _build_shell_pieces(shell: Node3D) -> Dictionary:
	var pieces: Dictionary = {}
	pieces["PalmCore"] = _new_sphere("PalmCore", _skin_material)
	pieces["PalmHeel"] = _new_sphere("PalmHeel", _skin_material)
	pieces["Thenar"] = _new_sphere("Thenar", _skin_material)
	pieces["WristBlend"] = _new_capsule("WristBlend", _skin_material)
	for key in ["PalmCore", "PalmHeel", "Thenar", "WristBlend"]:
		shell.add_child(pieces[key] as MeshInstance3D)

	for finger_name in FINGER_NAMES:
		var segments: Array[MeshInstance3D] = []
		for segment_index in range(3):
			var segment := _new_capsule("%sSegment%d" % [finger_name, segment_index], _skin_material)
			shell.add_child(segment)
			segments.append(segment)
		pieces["%sSegments" % finger_name] = segments
		var tip := _new_sphere("%sTip" % finger_name, _skin_material)
		shell.add_child(tip)
		pieces["%sTip" % finger_name] = tip
		var nail := _new_sphere("%sNail" % finger_name, _nail_material)
		shell.add_child(nail)
		pieces["%sNail" % finger_name] = nail
	return pieces

func _refresh_hand(hand_name: String) -> void:
	if not _hands.has(hand_name):
		return
	var data: Dictionary = _hands[hand_name]
	var hand := data.get("hand") as HandVisual
	var skeleton := data.get("skeleton") as Skeleton3D
	if hand == null or skeleton == null:
		return
	var suffix := String(data.get("suffix", "R"))
	var wrist_value = _bone_point(hand, skeleton, "Wrist_%s" % suffix)
	if wrist_value == null:
		return
	var wrist: Vector3 = wrist_value
	var chains: Dictionary = {}
	for finger_name in FINGER_NAMES:
		var chain := _finger_chain(hand, skeleton, suffix, finger_name, wrist)
		if chain.size() == 4:
			chains[finger_name] = chain
		else:
			_set_finger_visible(data, finger_name, false)

	if not chains.has("Index") or not chains.has("Middle") or not chains.has("Ring") or not chains.has("Little"):
		return
	var index_root: Vector3 = (chains["Index"] as Array)[0]
	var middle_root: Vector3 = (chains["Middle"] as Array)[0]
	var ring_root: Vector3 = (chains["Ring"] as Array)[0]
	var little_root: Vector3 = (chains["Little"] as Array)[0]
	var knuckle_center := (index_root + middle_root + ring_root + little_root) * 0.25
	var across := little_root - index_root
	var forward := knuckle_center - wrist
	if across.length_squared() <= 0.000001 or forward.length_squared() <= 0.000001:
		return
	var x_axis := across.normalized()
	var y_axis := forward.normalized()
	var z_axis := x_axis.cross(y_axis).normalized()
	if z_axis.length_squared() <= 0.000001:
		z_axis = Vector3.FORWARD
	if _camera != null:
		var palm_world := hand.to_global(wrist.lerp(knuckle_center, 0.58))
		var camera_dir_world := (_camera.global_position - palm_world).normalized()
		var camera_dir_local := hand.global_transform.basis.inverse() * camera_dir_world
		if z_axis.dot(camera_dir_local) < 0.0:
			z_axis = -z_axis
	var width := clampf(across.length() * 1.36, 0.30, 0.52)
	var length := clampf(forward.length() * 1.38, 0.30, 0.54)
	var thickness := clampf(width * 0.28, 0.075, 0.135)
	var pieces: Dictionary = data["pieces"]

	_place_ellipsoid(pieces["PalmCore"] as MeshInstance3D,
		wrist.lerp(knuckle_center, 0.61) + z_axis * thickness * 0.05,
		x_axis, y_axis, z_axis,
		Vector3(width * 0.52, length * 0.52, thickness))
	_place_ellipsoid(pieces["PalmHeel"] as MeshInstance3D,
		wrist.lerp(knuckle_center, 0.34),
		x_axis, y_axis, z_axis,
		Vector3(width * 0.43, length * 0.31, thickness * 1.03))

	var thumb_chain: Array = chains.get("Thumb", [])
	if thumb_chain.size() == 4:
		var thumb_root: Vector3 = thumb_chain[0]
		_place_ellipsoid(pieces["Thenar"] as MeshInstance3D,
			wrist.lerp(thumb_root, 0.70) + z_axis * thickness * 0.03,
			x_axis, y_axis, z_axis,
			Vector3(width * 0.30, length * 0.30, thickness * 1.12))
		(pieces["Thenar"] as MeshInstance3D).visible = true
	else:
		(pieces["Thenar"] as MeshInstance3D).visible = false

	var wrist_end := wrist - y_axis * maxf(length * 0.46, 0.16)
	_place_capsule(pieces["WristBlend"] as MeshInstance3D, wrist_end, wrist + y_axis * 0.025, width * 0.235)

	for finger_name in FINGER_NAMES:
		if not chains.has(finger_name):
			continue
		_set_finger_visible(data, finger_name, true)
		var chain: Array = chains[finger_name]
		var radius := _finger_radius(width, finger_name)
		var segments: Array = pieces["%sSegments" % finger_name]
		for segment_index in range(3):
			_place_capsule(segments[segment_index] as MeshInstance3D, chain[segment_index], chain[segment_index + 1], radius * (1.0 - 0.08 * segment_index))
		var tip := pieces["%sTip" % finger_name] as MeshInstance3D
		var direction: Vector3 = (chain[3] - chain[2]).normalized()
		var side := direction.cross(z_axis).normalized()
		if side.length_squared() <= 0.000001:
			side = x_axis
		_place_ellipsoid(tip, chain[3] - direction * radius * 0.10, side, direction, z_axis, Vector3(radius * 1.03, radius * 1.18, radius * 0.96))
		var nail := pieces["%sNail" % finger_name] as MeshInstance3D
		_place_ellipsoid(nail,
			chain[3] - direction * radius * 0.30 + z_axis * radius * 0.87,
			side, direction, z_axis,
			Vector3(radius * 0.66, radius * 0.75, maxf(radius * 0.13, 0.004)))

	if not bool(data.get("forearm_built", false)):
		_build_cinematic_forearm(hand_name, wrist, y_axis, width)

func _finger_chain(hand: Node3D, skeleton: Skeleton3D, suffix: String, finger_name: String, wrist: Vector3) -> Array:
	var names: Array[String] = []
	if finger_name == "Thumb":
		names = ["Thumb_Metacarpal_%s" % suffix, "Thumb_Proximal_%s" % suffix, "Thumb_Distal_%s" % suffix]
	else:
		names = ["%s_Proximal_%s" % [finger_name, suffix], "%s_Intermediate_%s" % [finger_name, suffix], "%s_Distal_%s" % [finger_name, suffix]]
	var points: Array = []
	for bone_name in names:
		var value = _bone_point(hand, skeleton, bone_name)
		if value != null:
			points.append(value)
		elif finger_name != "Thumb":
			return []
	if finger_name == "Thumb" and points.size() == 2:
		points.insert(0, wrist.lerp(points[0] as Vector3, 0.52))
	if points.size() != 3:
		return []
	var previous: Vector3 = points[1]
	var distal: Vector3 = points[2]
	var direction := distal - previous
	if direction.length_squared() <= 0.000001:
		return []
	var extension := clampf(direction.length() * 0.74, 0.045, 0.105)
	points.append(distal + direction.normalized() * extension)
	return points

func _bone_point(hand: Node3D, skeleton: Skeleton3D, bone_name: String):
	var bone_id := skeleton.find_bone(bone_name)
	if bone_id < 0:
		return null
	var pose := skeleton.get_bone_global_pose(bone_id)
	return _descendant_point_to_ancestor(skeleton, hand, pose.origin)

func _build_cinematic_forearm(hand_name: String, wrist: Vector3, palm_forward: Vector3, palm_width: float) -> void:
	if not _hands.has(hand_name):
		return
	var data: Dictionary = _hands[hand_name]
	var hand := data.get("hand") as HandVisual
	if hand == null:
		return
	var start := wrist - palm_forward * maxf(palm_width * 0.16, 0.05)
	var start_world := hand.to_global(start)
	var cup_world := _cup.global_position if _cup != null else Vector3.ZERO
	var outward_sign := -1.0 if start_world.x < cup_world.x else 1.0
	if absf(start_world.x - cup_world.x) < 0.04:
		outward_sign = -1.0 if hand_name == "RightHand" else 1.0
	var control_a_world := start_world + Vector3(outward_sign * 0.44, -0.38, 0.10)
	var control_b_world := start_world + Vector3(outward_sign * 1.55, -1.08, 0.28)
	var end_world := start_world + Vector3(outward_sign * 3.25, -2.10, 0.50)
	var control_a := hand.to_local(control_a_world)
	var control_b := hand.to_local(control_b_world)
	var end := hand.to_local(end_world)
	var start_radius := clampf(palm_width * 0.255, 0.085, 0.125)
	var end_radius := clampf(palm_width * 0.405, 0.145, 0.205)

	var forearm := MeshInstance3D.new()
	forearm.name = "CinematicForearm"
	forearm.mesh = _build_curve_mesh(start, control_a, control_b, end, start_radius, end_radius)
	forearm.material_override = _cloth_material
	forearm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	hand.add_child(forearm)
	data["forearm"] = forearm

	var cuff := MeshInstance3D.new()
	cuff.name = "CinematicCuff"
	var cuff_mesh := CylinderMesh.new()
	cuff_mesh.top_radius = start_radius * 1.07
	cuff_mesh.bottom_radius = start_radius * 1.09
	cuff_mesh.height = 0.16
	cuff_mesh.radial_segments = 32
	cuff.mesh = cuff_mesh
	cuff.material_override = _cuff_material
	var cuff_end := start + (control_a - start).normalized() * 0.16
	_place_cylinder(cuff, start - (control_a - start).normalized() * 0.02, cuff_end)
	hand.add_child(cuff)
	data["cuff"] = cuff
	data["forearm_built"] = true
	_hands[hand_name] = data

func _build_curve_mesh(start: Vector3, control_a: Vector3, control_b: Vector3, end: Vector3, start_radius: float, end_radius: float) -> ArrayMesh:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	for ring_index in range(FOREARM_RINGS):
		var t := float(ring_index) / float(FOREARM_RINGS - 1)
		var point := _cubic_point(start, control_a, control_b, end, t)
		var tangent := _cubic_tangent(start, control_a, control_b, end, t).normalized()
		if tangent.length_squared() <= 0.000001:
			tangent = Vector3.FORWARD
		var helper := Vector3.UP
		if absf(tangent.dot(helper)) > 0.94:
			helper = Vector3.RIGHT
		var ring_x := helper.cross(tangent).normalized()
		var ring_y := tangent.cross(ring_x).normalized()
		var radius := lerpf(start_radius, end_radius, smoothstep(0.0, 1.0, t))
		var flatten := lerpf(0.61, 0.72, t)
		for side_index in range(FOREARM_SIDES):
			var u := float(side_index) / float(FOREARM_SIDES)
			var angle := TAU * u
			var fold := 1.0 + 0.018 * sin(angle * 3.0 + t * 2.1) + 0.010 * cos(angle * 5.0 - t * 1.4)
			var radial := ring_x * (cos(angle) * radius * fold) + ring_y * (sin(angle) * radius * flatten * fold)
			vertices.append(point + radial)
			normals.append(radial.normalized())
			uvs.append(Vector2(u, t))
	for ring_index in range(FOREARM_RINGS - 1):
		var current := ring_index * FOREARM_SIDES
		var next := (ring_index + 1) * FOREARM_SIDES
		for side_index in range(FOREARM_SIDES):
			var side_next := (side_index + 1) % FOREARM_SIDES
			var a := current + side_index
			var b := next + side_index
			var c := next + side_next
			var d := current + side_next
			indices.append(a); indices.append(b); indices.append(c)
			indices.append(a); indices.append(c); indices.append(d)
	var end_center := vertices.size()
	vertices.append(end)
	normals.append(_cubic_tangent(start, control_a, control_b, end, 1.0).normalized())
	uvs.append(Vector2(0.5, 1.0))
	var end_ring := (FOREARM_RINGS - 1) * FOREARM_SIDES
	for side_index in range(FOREARM_SIDES):
		var side_next := (side_index + 1) % FOREARM_SIDES
		indices.append(end_center); indices.append(end_ring + side_index); indices.append(end_ring + side_next)
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

func _place_capsule(instance: MeshInstance3D, a: Vector3, b: Vector3, radius: float) -> void:
	var delta := b - a
	var length := maxf(delta.length(), radius * 2.05)
	var y_axis := delta.normalized()
	if y_axis.length_squared() <= 0.000001:
		y_axis = Vector3.DOWN
	var helper := Vector3.FORWARD
	if absf(y_axis.dot(helper)) > 0.96:
		helper = Vector3.RIGHT
	var x_axis := helper.cross(y_axis).normalized()
	var z_axis := x_axis.cross(y_axis).normalized()
	var capsule := instance.mesh as CapsuleMesh
	if capsule != null:
		capsule.radius = radius
		capsule.height = length
	instance.transform = Transform3D(Basis(x_axis, y_axis, z_axis), (a + b) * 0.5)

func _place_cylinder(instance: MeshInstance3D, a: Vector3, b: Vector3) -> void:
	var delta := b - a
	var y_axis := delta.normalized()
	if y_axis.length_squared() <= 0.000001:
		y_axis = Vector3.DOWN
	var helper := Vector3.FORWARD
	if absf(y_axis.dot(helper)) > 0.96:
		helper = Vector3.RIGHT
	var x_axis := helper.cross(y_axis).normalized()
	var z_axis := x_axis.cross(y_axis).normalized()
	var cylinder := instance.mesh as CylinderMesh
	if cylinder != null:
		cylinder.height = maxf(delta.length(), 0.02)
	instance.transform = Transform3D(Basis(x_axis, y_axis, z_axis), (a + b) * 0.5)

func _place_ellipsoid(instance: MeshInstance3D, center: Vector3, x_axis: Vector3, y_axis: Vector3, z_axis: Vector3, radii: Vector3) -> void:
	var x := x_axis.normalized()
	var y := y_axis.normalized()
	var z := z_axis.normalized()
	instance.transform = Transform3D(Basis(x * radii.x, y * radii.y, z * radii.z), center)

func _finger_radius(palm_width: float, finger_name: String) -> float:
	var factor := 0.105
	match finger_name:
		"Thumb":
			factor = 0.122
		"Middle":
			factor = 0.108
		"Ring":
			factor = 0.101
		"Little":
			factor = 0.084
	return clampf(palm_width * factor, 0.025, 0.058)

func _set_finger_visible(data: Dictionary, finger_name: String, visible: bool) -> void:
	var pieces: Dictionary = data.get("pieces", {})
	var segments: Array = pieces.get("%sSegments" % finger_name, [])
	for segment in segments:
		(segment as MeshInstance3D).visible = visible
	var tip := pieces.get("%sTip" % finger_name) as MeshInstance3D
	if tip != null:
		tip.visible = visible
	var nail := pieces.get("%sNail" % finger_name) as MeshInstance3D
	if nail != null:
		nail.visible = visible

func _build_materials() -> void:
	_skin_material = StandardMaterial3D.new()
	_skin_material.resource_name = "CinematicHandSkin"
	_skin_material.albedo_color = Color(0.57, 0.34, 0.235, 1.0)
	_skin_material.roughness = 0.70
	_skin_material.metallic = 0.0
	_skin_material.metallic_specular = 0.34

	_nail_material = StandardMaterial3D.new()
	_nail_material.resource_name = "CinematicHandNail"
	_nail_material.albedo_color = Color(0.78, 0.55, 0.46, 1.0)
	_nail_material.roughness = 0.52
	_nail_material.metallic = 0.0
	_nail_material.metallic_specular = 0.42

	_cloth_material = StandardMaterial3D.new()
	_cloth_material.resource_name = "CinematicSleeveFabric"
	_cloth_material.albedo_color = Color(0.055, 0.062, 0.058, 1.0)
	_cloth_material.roughness = 0.97
	_cloth_material.metallic = 0.0
	_cloth_material.metallic_specular = 0.10

	_cuff_material = StandardMaterial3D.new()
	_cuff_material.resource_name = "CinematicSleeveCuff"
	_cuff_material.albedo_color = Color(0.075, 0.080, 0.075, 1.0)
	_cuff_material.roughness = 0.95
	_cuff_material.metallic = 0.0
	_cuff_material.metallic_specular = 0.10

func _new_sphere(node_name: String, material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	var mesh := SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 2.0
	mesh.radial_segments = 32
	mesh.rings = 16
	instance.mesh = mesh
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	return instance

func _new_capsule(node_name: String, material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	var mesh := CapsuleMesh.new()
	mesh.radius = 0.05
	mesh.height = 0.12
	mesh.radial_segments = 28
	mesh.rings = 10
	instance.mesh = mesh
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	return instance

func _update_venue_materials() -> void:
	var venue_id := "cafe_window"
	if _venue != null:
		venue_id = _venue.get_active_profile_id()
	if venue_id == _last_venue_id:
		return
	_last_venue_id = venue_id
	var cafe := venue_id == "cafe_window"
	for hand_name in _hands.keys():
		var data: Dictionary = _hands[hand_name]
		var forearm := data.get("forearm") as MeshInstance3D
		var cuff := data.get("cuff") as MeshInstance3D
		if forearm != null:
			forearm.material_override = _cloth_material if cafe else _skin_material
		if cuff != null:
			cuff.visible = cafe

func _set_mesh_visibility_recursive(node: Node, visible: bool) -> void:
	if node is MeshInstance3D:
		(node as MeshInstance3D).visible = visible
	for child in node.get_children():
		_set_mesh_visibility_recursive(child, visible)

func _count_visible_meshes(node: Node) -> int:
	var count := 1 if node is MeshInstance3D and (node as MeshInstance3D).visible else 0
	for child in node.get_children():
		count += _count_visible_meshes(child)
	return count

func _count_meshes(node: Node) -> int:
	var count := 1 if node is MeshInstance3D else 0
	for child in node.get_children():
		count += _count_meshes(child)
	return count

func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node as Skeleton3D
	for child in node.get_children():
		var found := _find_skeleton(child)
		if found != null:
			return found
	return null

func _descendant_point_to_ancestor(descendant: Node3D, ancestor: Node3D, point: Vector3):
	var current := descendant
	var converted := point
	while current != ancestor:
		if current.is_set_as_top_level():
			return null
		converted = current.transform * converted
		var parent := current.get_parent()
		if not (parent is Node3D):
			return null
		current = parent as Node3D
	return converted

func _cubic_point(start: Vector3, control_a: Vector3, control_b: Vector3, end: Vector3, t: float) -> Vector3:
	var one_minus := 1.0 - t
	return start * one_minus * one_minus * one_minus + control_a * 3.0 * one_minus * one_minus * t + control_b * 3.0 * one_minus * t * t + end * t * t * t

func _cubic_tangent(start: Vector3, control_a: Vector3, control_b: Vector3, end: Vector3, t: float) -> Vector3:
	var one_minus := 1.0 - t
	return (control_a - start) * (3.0 * one_minus * one_minus) + (control_b - control_a) * (6.0 * one_minus * t) + (end - control_b) * (3.0 * t * t)
