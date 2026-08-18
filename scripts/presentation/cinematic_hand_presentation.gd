extends Node3D
class_name CinematicHandPresentation

const HAND_NAMES := ["RightHand", "LeftHand"]
const FOREARM_RINGS := 28
const FOREARM_SIDES := 28
const AUTHORED_SCALE_READY := 3.80
const LEGACY_WRIST_NAMES := ["WristSleeve", "WristCuff"]

const SKIN_SHADER := """shader_type spatial;
render_mode unshaded, cull_back;
uniform vec4 skin_color : source_color = vec4(0.64, 0.39, 0.27, 1.0);

void fragment() {
	float uv_soft = mix(0.965, 1.025, clamp(UV.y, 0.0, 1.0));
	ALBEDO = clamp(skin_color.rgb * uv_soft, vec3(0.0), vec3(1.0));
	ALPHA = skin_color.a;
}
"""

const NAIL_SHADER := """shader_type spatial;
render_mode unshaded, cull_back;
uniform vec4 nail_color : source_color = vec4(0.82, 0.58, 0.49, 1.0);

void fragment() {
	ALBEDO = nail_color.rgb;
	ALPHA = nail_color.a;
}
"""

var _hands: Dictionary = {}
var _cup: MeshInstance3D
var _venue: VenuePresentation
var _skin_material: ShaderMaterial
var _nail_material: ShaderMaterial
var _cloth_material: StandardMaterial3D
var _cuff_material: StandardMaterial3D
var _last_venue_id := ""

func _ready() -> void:
	_build_materials()
	call_deferred("_bind")

func _process(_delta: float) -> void:
	if _hands.size() < HAND_NAMES.size():
		_bind()
	_update_venue_materials()

func get_ready_hand_count() -> int:
	return _hands.size()

func get_visible_authored_hand_mesh_count() -> int:
	var count := 0
	for hand_name in _hands.keys():
		var data: Dictionary = _hands[hand_name]
		var meshes: Array = data.get("authored_meshes", [])
		for value in meshes:
			var mesh_instance := value as MeshInstance3D
			if mesh_instance != null and mesh_instance.visible:
				count += 1
	return count

func get_polished_authored_mesh_count() -> int:
	var count := 0
	for hand_name in _hands.keys():
		var data: Dictionary = _hands[hand_name]
		var meshes: Array = data.get("authored_meshes", [])
		for value in meshes:
			var mesh_instance := value as MeshInstance3D
			if mesh_instance != null and mesh_instance.visible and _mesh_has_cinematic_override(mesh_instance):
				count += 1
	return count

func get_visible_primitive_shell_mesh_count() -> int:
	var count := 0
	for hand_name in _hands.keys():
		var data: Dictionary = _hands[hand_name]
		var hand := data.get("hand") as Node3D
		if hand == null:
			continue
		var shell := hand.get_node_or_null("CinematicShell") as Node
		if shell != null:
			count += _count_visible_meshes(shell)
	return count

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
	var legacy_forearm := hand.get_node_or_null("ForearmNatural") as MeshInstance3D
	if legacy_forearm == null:
		# ForearmPresentation runs first and supplies compatibility geometry. Waiting
		# for it avoids two presentation layers racing over the wrist in startup.
		return
	var legacy_cuff := hand.get_node_or_null("SleeveCuffNatural") as MeshInstance3D
	legacy_forearm.visible = false
	if legacy_cuff != null:
		legacy_cuff.visible = false

	# Explicitly retire the failed primitive approximation if this node is hot-
	# reloaded in an editor session. Fresh scene instances never create it now.
	var primitive_shell := hand.get_node_or_null("CinematicShell") as Node3D
	if primitive_shell != null:
		primitive_shell.visible = false

	# The authored XR GLB remains the only continuous anatomical topology in the
	# repository. Preserve its skinning and animations, and change presentation
	# only: continuous geometry stays visible while surface overrides suppress the
	# distracting triangle-by-triangle lighting that made the baseline look cut up.
	var authored_meshes: Array[MeshInstance3D] = []
	_polish_authored_meshes(authored, authored_meshes)
	if authored_meshes.is_empty():
		return

	var suffix := "R" if hand_name == "RightHand" else "L"
	var wrist_value = _bone_point(hand, skeleton, "Wrist_%s" % suffix)
	if wrist_value == null:
		return
	var wrist: Vector3 = wrist_value
	var palm_value = _bone_point(hand, skeleton, "Palm_%s" % suffix)
	var palm_forward := Vector3(0.0, -1.0, 0.0)
	if palm_value != null:
		var delta: Vector3 = (palm_value as Vector3) - wrist
		if delta.length_squared() > 0.000001:
			palm_forward = delta.normalized()

	var data := {
		"hand": hand,
		"authored": authored,
		"skeleton": skeleton,
		"authored_meshes": authored_meshes,
		"forearm": null,
		"cuff": null,
	}
	_hands[hand_name] = data
	_build_cinematic_forearm(hand_name, wrist, palm_forward)

func _polish_authored_meshes(node: Node, output: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		if mesh_instance.name in LEGACY_WRIST_NAMES:
			mesh_instance.visible = false
		else:
			mesh_instance.visible = true
			mesh_instance.material_override = null
			var mesh := mesh_instance.mesh
			if mesh != null:
				for surface_index in range(mesh.get_surface_count()):
					var source_material := mesh.surface_get_material(surface_index)
					var source_name := source_material.resource_name if source_material != null else ""
					var replacement: Material = _nail_material if source_name == "HandNail" else _skin_material
					mesh_instance.set_surface_override_material(surface_index, replacement)
				output.append(mesh_instance)
	for child in node.get_children():
		_polish_authored_meshes(child, output)

func _mesh_has_cinematic_override(mesh_instance: MeshInstance3D) -> bool:
	if mesh_instance.mesh == null:
		return false
	for surface_index in range(mesh_instance.mesh.get_surface_count()):
		var material := mesh_instance.get_surface_override_material(surface_index)
		if material == _skin_material or material == _nail_material:
			return true
	return false

func _build_cinematic_forearm(hand_name: String, wrist: Vector3, palm_forward: Vector3) -> void:
	if not _hands.has(hand_name):
		return
	var data: Dictionary = _hands[hand_name]
	var hand := data.get("hand") as HandVisual
	if hand == null:
		return
	var start := wrist - palm_forward * 0.055
	var start_world := hand.to_global(start)
	var cup_world := _cup.global_position if _cup != null else Vector3.ZERO
	var outward_sign := -1.0 if start_world.x < cup_world.x else 1.0
	if absf(start_world.x - cup_world.x) < 0.04:
		outward_sign = -1.0 if hand_name == "RightHand" else 1.0

	# The target frame reads as two short, diagonal arm exits from the lower
	# corners, not pipes running across the entire screen. Keep the wrist tangent
	# gentle, widen toward the frame edge, and terminate comfortably off-camera.
	var control_a_world := start_world + Vector3(outward_sign * 0.44, -0.38, 0.10)
	var control_b_world := start_world + Vector3(outward_sign * 1.55, -1.08, 0.28)
	var end_world := start_world + Vector3(outward_sign * 3.25, -2.10, 0.50)
	var control_a := hand.to_local(control_a_world)
	var control_b := hand.to_local(control_b_world)
	var end := hand.to_local(end_world)
	var start_radius := 0.105
	var end_radius := 0.185

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
	cuff_mesh.top_radius = start_radius * 1.08
	cuff_mesh.bottom_radius = start_radius * 1.11
	cuff_mesh.height = 0.15
	cuff_mesh.radial_segments = 32
	cuff.mesh = cuff_mesh
	cuff.material_override = _cuff_material
	var tangent := (control_a - start).normalized()
	_place_cylinder(cuff, start - tangent * 0.035, start + tangent * 0.115)
	hand.add_child(cuff)
	data["cuff"] = cuff
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
		var flatten := lerpf(0.62, 0.72, t)
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

func _build_materials() -> void:
	var skin_shader := Shader.new()
	skin_shader.code = SKIN_SHADER
	_skin_material = ShaderMaterial.new()
	_skin_material.resource_name = "CinematicHandSkin"
	_skin_material.shader = skin_shader
	_skin_material.set_shader_parameter("skin_color", Color(0.64, 0.39, 0.27, 1.0))

	var nail_shader := Shader.new()
	nail_shader.code = NAIL_SHADER
	_nail_material = ShaderMaterial.new()
	_nail_material.resource_name = "CinematicHandNail"
	_nail_material.shader = nail_shader
	_nail_material.set_shader_parameter("nail_color", Color(0.82, 0.58, 0.49, 1.0))

	_cloth_material = StandardMaterial3D.new()
	_cloth_material.resource_name = "CinematicSleeveFabric"
	_cloth_material.albedo_color = Color(0.045, 0.052, 0.049, 1.0)
	_cloth_material.roughness = 0.98
	_cloth_material.metallic = 0.0
	_cloth_material.metallic_specular = 0.08

	_cuff_material = StandardMaterial3D.new()
	_cuff_material.resource_name = "CinematicSleeveCuff"
	_cuff_material.albedo_color = Color(0.062, 0.068, 0.063, 1.0)
	_cuff_material.roughness = 0.97
	_cuff_material.metallic = 0.0
	_cuff_material.metallic_specular = 0.08

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

func _bone_point(hand: Node3D, skeleton: Skeleton3D, bone_name: String):
	var bone_id := skeleton.find_bone(bone_name)
	if bone_id < 0:
		return null
	var pose := skeleton.get_bone_global_pose(bone_id)
	return _descendant_point_to_ancestor(skeleton, hand, pose.origin)

func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node as Skeleton3D
	for child in node.get_children():
		var found := _find_skeleton(child)
		if found != null:
			return found
	return null

func _count_visible_meshes(node: Node) -> int:
	var count := 1 if node is MeshInstance3D and (node as MeshInstance3D).visible else 0
	for child in node.get_children():
		count += _count_visible_meshes(child)
	return count

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
