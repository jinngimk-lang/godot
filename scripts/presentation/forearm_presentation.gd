extends Node3D
class_name ForearmPresentation

var _applied := false

func _ready() -> void:
	# PeelLab builds authored hands in its own _ready(). Defer once so their
	# imported meshes, wrist sleeve and semantic fabric materials exist first.
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
	var fabric := legacy_sleeve.material_override
	# Keep the existing thin WristCuff at the skin/fabric seam, but replace the
	# long straight cone with a measured two-segment silhouette.
	legacy_sleeve.visible = false

	var side := -1.0 if dynamic_hand else 1.0
	# Axis diagnostics from a real 1280x720 render show authored +Z heading
	# down/out from each wrist and authored ±X moving toward the correct side
	# of the frame. The first segment stays close to +Z, the second introduces
	# the lateral bend so it exits the interaction instead of crossing it.
	var start_authored := Vector3(0.0, 0.0, 0.020)
	var bend_authored := Vector3(0.035 * side, 0.0, 0.245 if dynamic_hand else 0.265)
	var end_authored := Vector3(0.205 * side, 0.0, 0.700 if dynamic_hand else 0.735)

	var start: Vector3 = _descendant_point_to_ancestor(authored, hand, start_authored)
	var bend: Vector3 = _descendant_point_to_ancestor(authored, hand, bend_authored)
	var end: Vector3 = _descendant_point_to_ancestor(authored, hand, end_authored)
	if not _finite_vector(start) or not _finite_vector(bend) or not _finite_vector(end):
		legacy_sleeve.visible = true
		return

	var near := MeshInstance3D.new()
	near.name = "ForearmNear"
	near.material_override = fabric
	hand.add_child(near)
	_place_tapered_segment(near, start, bend, 0.064, 0.078, 0.86, 0.70)

	var elbow := MeshInstance3D.new()
	elbow.name = "SleeveElbow"
	var elbow_mesh := SphereMesh.new()
	elbow_mesh.radius = 0.082
	elbow_mesh.height = 0.164
	elbow.mesh = elbow_mesh
	elbow.material_override = fabric
	elbow.position = bend
	elbow.scale = Vector3(0.88, 0.80, 0.72)
	hand.add_child(elbow)

	var far := MeshInstance3D.new()
	far.name = "ForearmSleeve"
	far.material_override = fabric
	hand.add_child(far)
	_place_tapered_segment(far, bend, end, 0.076, 0.105, 0.90, 0.74)

func _place_tapered_segment(instance: MeshInstance3D, a: Vector3, b: Vector3, radius_a: float, radius_b: float, oval_x: float, oval_z: float) -> void:
	var delta := b - a
	var length := delta.length()
	if length <= 0.0001:
		return
	var y_axis := delta / length
	var helper := Vector3.FORWARD
	if absf(y_axis.dot(helper)) > 0.96:
		helper = Vector3.RIGHT
	var x_axis := helper.cross(y_axis).normalized()
	var z_axis := x_axis.cross(y_axis).normalized()
	var mesh := CylinderMesh.new()
	mesh.bottom_radius = radius_a
	mesh.top_radius = radius_b
	mesh.height = length
	instance.mesh = mesh
	instance.transform = Transform3D(
		Basis(x_axis * oval_x, y_axis, z_axis * oval_z),
		(a + b) * 0.5
	)

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
