extends SceneTree

const POSITION_TOLERANCE := 0.0002

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load("res://scenes/peel_lab/peel_lab.tscn") as PackedScene
	if packed == null:
		push_error("HELD_INDEPENDENCE_SMOKE: peel_lab scene failed to load")
		quit(1)
		return
	var scene := packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	await process_frame

	var label := scene.get_node_or_null("PeelLabel") as LabelVisual
	if label == null:
		push_error("HELD_INDEPENDENCE_SMOKE: PeelLabel missing")
		quit(1)
		return

	var front := label.get_front_position(1.0)
	var grip_a := front + Vector3(-0.34, 0.16, 0.31)
	label.set_phase("PEELING")
	label.set_peel(1.0, grip_a)
	label.set_phase("DETACHING")
	label.set_detach_alpha(1.0)
	label.set_peel(1.0, grip_a)
	var detaching_vertices := _vertices(label)
	if detaching_vertices.is_empty():
		push_error("HELD_INDEPENDENCE_SMOKE: DETACHING mesh missing")
		quit(1)
		return

	label.set_phase("HELD")
	label.set_peel(1.0, grip_a)
	var held_a := _vertices(label)
	if held_a.size() != detaching_vertices.size():
		push_error("RED: DETACHING alpha=1 and HELD mesh sizes diverge")
		quit(1)
		return
	for i in range(held_a.size()):
		if held_a[i].distance_to(detaching_vertices[i]) > POSITION_TOLERANCE:
			push_error("RED: DETACHING alpha=1 must converge to HELD geometry; vertex=%d error=%.6f" % [i, held_a[i].distance_to(detaching_vertices[i])])
			quit(1)
			return

	var move_delta := Vector3(0.62, -0.18, 0.27)
	label.set_peel(1.0, grip_a + move_delta)
	var held_b := _vertices(label)
	if held_b.size() != held_a.size():
		push_error("RED: HELD mesh topology changed after grip translation")
		quit(1)
		return
	var max_translation_error := 0.0
	for i in range(held_a.size()):
		var actual_delta := held_b[i] - held_a[i]
		max_translation_error = maxf(max_translation_error, actual_delta.distance_to(move_delta))
	if max_translation_error > POSITION_TOLERANCE:
		push_error("RED: runtime HELD mesh retained a non-translating cup anchor; max translation error=%.6f" % max_translation_error)
		quit(1)
		return

	var aabb := label.mesh.get_aabb()
	var max_extent := maxf(aabb.size.x, maxf(aabb.size.y, aabb.size.z))
	if max_extent > label.label_width * 1.25:
		push_error("RED: HELD runtime mesh became physically unbounded; extent=%.6f width=%.6f" % [max_extent, label.label_width])
		quit(1)
		return

	print("PASS: runtime DETACHING->HELD stays cup-independent; max_translation_error=%.6f extent=%.6f" % [max_translation_error, max_extent])
	scene.queue_free()
	await process_frame
	quit(0)

func _vertices(label: LabelVisual) -> PackedVector3Array:
	if label.mesh == null or label.mesh.get_surface_count() == 0:
		return PackedVector3Array()
	var arrays := label.mesh.surface_get_arrays(0)
	if arrays.size() <= Mesh.ARRAY_VERTEX or not (arrays[Mesh.ARRAY_VERTEX] is PackedVector3Array):
		return PackedVector3Array()
	return arrays[Mesh.ARRAY_VERTEX]
