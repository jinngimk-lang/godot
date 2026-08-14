extends SceneTree

const MAX_SURFACE_ERROR := 0.004
const MIN_SURFACE_NORMAL_DOT := 0.999

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load("res://scenes/peel_lab/peel_lab.tscn") as PackedScene
	if packed == null:
		push_error("LABEL_SURFACE_SMOKE: peel_lab scene failed to load")
		quit(1)
		return

	var scene := packed.instantiate()
	root.add_child(scene)
	await _settle_frames(3)

	var cup := scene.get_node_or_null("Cup") as MeshInstance3D
	var label := scene.get_node_or_null("PeelLabel") as LabelVisual
	var session = scene.get("_session")
	if cup == null or label == null or session == null:
		push_error("LABEL_SURFACE_SMOKE: Cup, PeelLabel or SessionModel missing")
		quit(1)
		return

	var failure := _surface_failure(cup, label, "warm_paper")
	if not failure.is_empty():
		push_error(failure)
		quit(1)
		return

	# Switch through the real tactile silhouettes. LabelVisual must rebind its
	# frustum whenever the live Cup dimensions change; keeping warm_paper's
	# cached taper makes silky labels float and crisp labels sink inside the cup.
	session.record_ritual_complete()
	session.record_ritual_complete()
	session.advance_item()
	scene.call("_apply_current_variant")
	scene.call("_reset_session")
	await _settle_frames(2)
	failure = _surface_failure(cup, label, "silky_long")
	if not failure.is_empty():
		push_error(failure)
		quit(1)
		return

	session.record_ritual_complete()
	session.record_ritual_complete()
	session.record_ritual_complete()
	session.advance_item()
	scene.call("_apply_current_variant")
	scene.call("_reset_session")
	await _settle_frames(2)
	failure = _surface_failure(cup, label, "crisp_seal")
	if not failure.is_empty():
		push_error(failure)
		quit(1)
		return

	print("PASS: attached label follows all tactile cup silhouettes within %.3f m with taper-aware normals" % MAX_SURFACE_ERROR)
	scene.queue_free()
	await process_frame
	quit(0)

func _surface_failure(cup: MeshInstance3D, label: LabelVisual, profile_name: String) -> String:
	if not (cup.mesh is CylinderMesh):
		return "LABEL_SURFACE_SMOKE: Cup must expose CylinderMesh taper contract"
	if label.mesh == null or label.mesh.get_surface_count() == 0:
		return "LABEL_SURFACE_SMOKE: %s PeelLabel has no renderable surface" % profile_name

	var cup_mesh := cup.mesh as CylinderMesh
	var arrays := label.mesh.surface_get_arrays(0)
	if arrays.size() <= Mesh.ARRAY_VERTEX or not (arrays[Mesh.ARRAY_VERTEX] is PackedVector3Array):
		return "LABEL_SURFACE_SMOKE: %s PeelLabel surface has no vertex array" % profile_name
	if arrays.size() <= Mesh.ARRAY_NORMAL or not (arrays[Mesh.ARRAY_NORMAL] is PackedVector3Array):
		return "LABEL_SURFACE_SMOKE: %s PeelLabel surface has no normal array" % profile_name
	var vertices := arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
	var normals := arrays[Mesh.ARRAY_NORMAL] as PackedVector3Array
	if vertices.is_empty():
		return "LABEL_SURFACE_SMOKE: %s PeelLabel vertex array is empty" % profile_name
	if normals.size() != vertices.size():
		return "LABEL_SURFACE_SMOKE: %s vertex/normal array sizes must match" % profile_name

	var max_error := 0.0
	var worst_local := Vector3.ZERO
	var worst_actual := 0.0
	var worst_expected := 0.0
	var min_normal_dot := 1.0
	var worst_normal_local := Vector3.ZERO
	var worst_mesh_normal := Vector3.ZERO
	var worst_expected_normal := Vector3.ZERO
	var height := maxf(cup_mesh.height, 0.001)
	var taper_slope := (cup_mesh.top_radius - cup_mesh.bottom_radius) / height

	for i in range(vertices.size()):
		var vertex := vertices[i]
		var cup_local := cup.to_local(label.to_global(vertex))
		var t := clampf((cup_local.y + height * 0.5) / height, 0.0, 1.0)
		var cup_radius := lerpf(cup_mesh.bottom_radius, cup_mesh.top_radius, t)
		var expected_radius := cup_radius + label.surface_offset
		var actual_radius := Vector2(cup_local.x, cup_local.z).length()
		var error := absf(actual_radius - expected_radius)
		if error > max_error:
			max_error = error
			worst_local = cup_local
			worst_actual = actual_radius
			worst_expected = expected_radius

		var radial := Vector3(cup_local.x, 0.0, cup_local.z).normalized()
		if radial.length_squared() <= 0.000001:
			return "LABEL_SURFACE_SMOKE: %s label vertex cannot define a cup radial normal" % profile_name
		var expected_normal := Vector3(radial.x, -taper_slope, radial.z).normalized()
		var world_normal := (label.global_transform.basis * normals[i]).normalized()
		var cup_local_normal := (cup.global_transform.basis.inverse() * world_normal).normalized()
		var normal_dot := clampf(cup_local_normal.dot(expected_normal), -1.0, 1.0)
		if normal_dot < min_normal_dot:
			min_normal_dot = normal_dot
			worst_normal_local = cup_local
			worst_mesh_normal = cup_local_normal
			worst_expected_normal = expected_normal

	if max_error > MAX_SURFACE_ERROR:
		return "RED: %s attached label does not follow its live tapered cup; max radial error=%.5f at cup-local %s, actual=%.5f expected=%.5f" % [profile_name, max_error, str(worst_local), worst_actual, worst_expected]
	if min_normal_dot < MIN_SURFACE_NORMAL_DOT:
		var angle_deg := rad_to_deg(acos(clampf(min_normal_dot, -1.0, 1.0)))
		return "RED: %s attached label normals ignore live cup taper; min dot=%.6f angle=%.3fdeg at cup-local %s, mesh=%s expected=%s" % [profile_name, min_normal_dot, angle_deg, str(worst_normal_local), str(worst_mesh_normal), str(worst_expected_normal)]
	return ""

func _settle_frames(count: int) -> void:
	for _i in range(count):
		await process_frame
