extends SceneTree

const MAX_SURFACE_ERROR := 0.004

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
	await process_frame
	await process_frame
	await process_frame

	var cup := scene.get_node_or_null("Cup") as MeshInstance3D
	var label := scene.get_node_or_null("PeelLabel") as LabelVisual
	if cup == null or label == null:
		push_error("LABEL_SURFACE_SMOKE: Cup or PeelLabel missing")
		quit(1)
		return
	if not (cup.mesh is CylinderMesh):
		push_error("LABEL_SURFACE_SMOKE: Cup must expose CylinderMesh taper contract")
		quit(1)
		return
	if label.mesh == null or label.mesh.get_surface_count() == 0:
		push_error("LABEL_SURFACE_SMOKE: fresh PeelLabel has no renderable surface")
		quit(1)
		return

	var cup_mesh := cup.mesh as CylinderMesh
	var arrays := label.mesh.surface_get_arrays(0)
	if arrays.size() <= Mesh.ARRAY_VERTEX or not (arrays[Mesh.ARRAY_VERTEX] is PackedVector3Array):
		push_error("LABEL_SURFACE_SMOKE: fresh PeelLabel surface has no vertex array")
		quit(1)
		return
	var vertices := arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
	if vertices.is_empty():
		push_error("LABEL_SURFACE_SMOKE: fresh PeelLabel vertex array is empty")
		quit(1)
		return

	var max_error := 0.0
	var worst_local := Vector3.ZERO
	var worst_actual := 0.0
	var worst_expected := 0.0
	for vertex in vertices:
		var cup_local := cup.to_local(label.to_global(vertex))
		var height := maxf(cup_mesh.height, 0.001)
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

	if max_error > MAX_SURFACE_ERROR:
		push_error("RED: fresh attached label does not follow tapered cup surface; max radial error=%.5f at cup-local %s, actual=%.5f expected=%.5f" % [max_error, str(worst_local), worst_actual, worst_expected])
		quit(1)
		return

	print("PASS: fresh attached label follows tapered cup surface within %.3f m" % MAX_SURFACE_ERROR)
	scene.queue_free()
	await process_frame
	quit(0)
