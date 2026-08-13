extends SceneTree

const MAX_SURFACE_ERROR := 0.004

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load("res://scenes/peel_lab/peel_lab.tscn") as PackedScene
	if packed == null:
		push_error("ALL_VARIANT_SURFACE: peel_lab scene failed to load")
		quit(1)
		return
	var scene := packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	await process_frame

	var session = scene.get("_session")
	var cup := scene.get_node_or_null("Cup") as MeshInstance3D
	var label := scene.get_node_or_null("PeelLabel") as LabelVisual
	if session == null or cup == null or label == null or not (cup.mesh is CylinderMesh):
		push_error("ALL_VARIANT_SURFACE: runtime session/cup/label contract missing")
		quit(1)
		return

	var observed_ids: Array[String] = []
	var observed_sizes: Array[Vector2] = []
	if not _check_current_variant(scene, session, cup, label, observed_ids, observed_sizes):
		quit(1)
		return

	# Unlock the second feel through the real progression model, then use the
	# production next-item path so dimensions/controller/reset are applied exactly
	# as they are during normal play.
	session.record_clean_peel(100)
	session.record_clean_peel(100)
	scene.call("_advance_to_next_item")
	await process_frame
	if not _check_current_variant(scene, session, cup, label, observed_ids, observed_sizes):
		quit(1)
		return

	# Reach five total clean peels while Silky Long is active; the production
	# next-item path must then rotate to the third unlocked Crisp Seal profile.
	session.record_clean_peel(100)
	session.record_clean_peel(100)
	session.record_clean_peel(100)
	scene.call("_advance_to_next_item")
	await process_frame
	if not _check_current_variant(scene, session, cup, label, observed_ids, observed_sizes):
		quit(1)
		return

	var expected_ids := ["warm_paper", "silky_long", "crisp_seal"]
	if observed_ids != expected_ids:
		push_error("RED: production next-item flow did not exercise all tactile variants in order: %s" % str(observed_ids))
		quit(1)
		return
	if observed_sizes[0] == observed_sizes[1] or observed_sizes[1] == observed_sizes[2] or observed_sizes[0] == observed_sizes[2]:
		push_error("RED: all-variant surface test did not exercise distinct label dimensions: %s" % str(observed_sizes))
		quit(1)
		return

	print("PASS: all production tactile variants follow tapered cup surface: ids=%s sizes=%s" % [str(observed_ids), str(observed_sizes)])
	scene.queue_free()
	await process_frame
	quit(0)

func _check_current_variant(scene: Node, session: Variant, cup: MeshInstance3D, label: LabelVisual, observed_ids: Array[String], observed_sizes: Array[Vector2]) -> bool:
	var variant: Dictionary = session.current_variant()
	var variant_id := String(variant.get("id", ""))
	var expected_width := float(variant.get("label_width", -1.0))
	var expected_height := float(variant.get("label_height", -1.0))
	if absf(label.label_width - expected_width) > 0.001 or absf(label.label_height - expected_height) > 0.001:
		push_error("RED: production variant %s dimensions were not applied to LabelVisual: actual=%.3fx%.3f expected=%.3fx%.3f" % [variant_id, label.label_width, label.label_height, expected_width, expected_height])
		return false

	# Assert the label is actually reset to its fresh attached representation.
	if label.is_detached():
		push_error("RED: production variant %s did not start as fresh attached label" % variant_id)
		return false
	label.set_peel(0.0, label.get_front_position(0.0))
	var max_error := _max_surface_error(cup, label)
	if max_error > MAX_SURFACE_ERROR:
		push_error("RED: production variant %s missed tapered cup surface; max radial error=%.6f width=%.3f height=%.3f" % [variant_id, max_error, label.label_width, label.label_height])
		return false

	observed_ids.append(variant_id)
	observed_sizes.append(Vector2(label.label_width, label.label_height))
	print("VARIANT_SURFACE_DIAG id=%s width=%.3f height=%.3f max_error=%.6f" % [variant_id, label.label_width, label.label_height, max_error])
	return true

func _max_surface_error(cup: MeshInstance3D, label: LabelVisual) -> float:
	if label.mesh == null or label.mesh.get_surface_count() == 0:
		return INF
	var arrays := label.mesh.surface_get_arrays(0)
	if arrays.size() <= Mesh.ARRAY_VERTEX or not (arrays[Mesh.ARRAY_VERTEX] is PackedVector3Array):
		return INF
	var vertices := arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
	if vertices.is_empty():
		return INF
	var cup_mesh := cup.mesh as CylinderMesh
	var max_error := 0.0
	for vertex in vertices:
		var cup_local := cup.to_local(label.to_global(vertex))
		var t := clampf((cup_local.y + cup_mesh.height * 0.5) / cup_mesh.height, 0.0, 1.0)
		var expected_radius := lerpf(cup_mesh.bottom_radius, cup_mesh.top_radius, t) + label.surface_offset
		var actual_radius := Vector2(cup_local.x, cup_local.z).length()
		max_error = maxf(max_error, absf(actual_radius - expected_radius))
	return max_error
