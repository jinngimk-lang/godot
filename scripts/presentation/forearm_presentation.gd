extends Node3D
class_name ForearmPresentation

const CURVE_RINGS := 16
const RING_SIDES := 12

var _applied := false

func _ready() -> void:
	# PeelLab constructs authored hands in its own _ready(). Defer once so the
	# imported hand mesh, wrist cover and shared SleeveFabric material exist.
	call_deferred("_apply")

func _apply() -> void:
	if _applied:
		return
	_applied = true
	_build_for_hand("RightHand", true)
	_build_for_hand("LeftHand", false)

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

	var legacy_sleeve := authored.find_child("WristSleeve", true, false) as MeshInstance3D
	if legacy_sleeve == null or legacy_sleeve.material_override == null:
		return
	# Do not recolor HandVisual's shared wrist material in place. The long visible
	# forearm gets its own low-contrast cloth copy so hand/wrist fallback semantics
	# remain untouched while the frame no longer contains two near-black hoses.
	var fabric := legacy_sleeve.material_override.duplicate()
	if fabric is StandardMaterial3D:
		var cloth := fabric as StandardMaterial3D
		cloth.resource_name = "SleeveFabric"
		cloth.albedo_color = Color(0.68, 0.57, 0.49, 1.0)
		cloth.roughness = 0.96
	legacy_sleeve.visible = false

	var side := -1.0 if dynamic_hand else 1.0
	# Real-render axis diagnostics established that authored +Z heads down/out
	# from each wrist and authored +/-X heads toward the correct side of frame.
	# Keep the visible curve deliberately compact: the hand and cup are the
	# subject, while the forearm should leave the frame quickly instead of
	# becoming a long hose-like graphic element.
	var start_authored := Vector3(0.0, 0.0, 0.020)
	var control_authored := Vector3(0.045 * side, 0.0, 0.205 if dynamic_hand else 0.220)
	var end_authored := Vector3(0.165 * side, 0.0, 0.515 if dynamic_hand else 0.545)

	var start: Vector3 = _descendant_point_to_ancestor(authored, hand, start_authored)
	var control: Vector3 = _descendant_point_to_ancestor(authored, hand, control_authored)
	var end: Vector3 = _descendant_point_to_ancestor(authored, hand, end_authored)
	if not _finite_vector(start) or not _finite_vector(control) or not _finite_vector(end):
		legacy_sleeve.visible = true
		return

	var forearm := MeshInstance3D.new()
	forearm.name = "ForearmSleeve"
	forearm.mesh = _build_curve_mesh(start, control, end)
	forearm.material_override = fabric
	hand.add_child(forearm)

	var exit_marker := Node3D.new()
	exit_marker.name = "ForearmExit"
	exit_marker.position = end
	hand.add_child(exit_marker)

func _build_curve_mesh(start: Vector3, control: Vector3, end: Vector3) -> ArrayMesh:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()

	for ring_index in range(CURVE_RINGS):
		var t := float(ring_index) / float(CURVE_RINGS - 1)
		var point := _quadratic_point(start, control, end, t)
		var tangent := _quadratic_tangent(start, control, end, t).normalized()
		if tangent.length_squared() <= 0.000001:
			tangent = Vector3.FORWARD

		var helper := Vector3.UP
		if absf(tangent.dot(helper)) > 0.94:
			helper = Vector3.RIGHT
		var ring_x := helper.cross(tangent).normalized()
		var ring_y := tangent.cross(ring_x).normalized()

		# A slender oval cloth section preserves wrist continuity without reading
		# as a uniform pipe. The forearm is fuller through its middle but remains
		# secondary to the cup and hands in the fixed close-up camera.
		var radius := _radius_profile(t)
		var oval_height := lerpf(0.60, 0.70, smoothstep(0.0, 1.0, t))
		for side_index in range(RING_SIDES):
			var angle := TAU * float(side_index) / float(RING_SIDES)
			var cos_a := cos(angle)
			var sin_a := sin(angle)
			var radial := ring_x * cos_a * radius + ring_y * sin_a * radius * oval_height
			vertices.append(point + radial)
			normals.append((ring_x * cos_a + ring_y * sin_a / oval_height).normalized())

	for ring_index in range(CURVE_RINGS - 1):
		var current := ring_index * RING_SIDES
		var next := (ring_index + 1) * RING_SIDES
		for side_index in range(RING_SIDES):
			var side_next := (side_index + 1) % RING_SIDES
			var a := current + side_index
			var b := next + side_index
			var c := next + side_next
			var d := current + side_next
			indices.append(a)
			indices.append(b)
			indices.append(c)
			indices.append(a)
			indices.append(c)
			indices.append(d)

	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

func _radius_profile(t: float) -> float:
	var clamped := clampf(t, 0.0, 1.0)
	if clamped <= 0.60:
		return lerpf(0.046, 0.074, smoothstep(0.0, 0.60, clamped))
	return lerpf(0.074, 0.062, smoothstep(0.60, 1.0, clamped))

func _quadratic_point(start: Vector3, control: Vector3, end: Vector3, t: float) -> Vector3:
	var one_minus := 1.0 - t
	return start * one_minus * one_minus + control * 2.0 * one_minus * t + end * t * t

func _quadratic_tangent(start: Vector3, control: Vector3, end: Vector3, t: float) -> Vector3:
	return (control - start) * (2.0 * (1.0 - t)) + (end - control) * (2.0 * t)

func _descendant_point_to_ancestor(descendant: Node3D, ancestor: Node3D, point: Vector3) -> Vector3:
	var current := descendant
	var converted := point
	while current != ancestor:
		if current.is_set_as_top_level():
			return Vector3(INF, INF, INF)
		converted = current.transform * converted
		var parent := current.get_parent()
		if not (parent is Node3D):
			return Vector3(INF, INF, INF)
		current = parent as Node3D
	return converted

func _finite_vector(value: Vector3) -> bool:
	return is_finite(value.x) and is_finite(value.y) and is_finite(value.z)
