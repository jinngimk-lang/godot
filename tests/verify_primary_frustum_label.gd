extends SceneTree

const SURFACE_TOLERANCE := 0.004
const FRONT_SEGMENT_TOLERANCE := 0.018
const MAX_COLUMN_GAP := 0.11

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load("res://scenes/peel_lab/peel_lab.tscn") as PackedScene
	if packed == null:
		push_error("PRIMARY_FRUSTUM_VERIFY: peel_lab scene failed to load")
		quit(1)
		return

	var scene := packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	await process_frame

	var cup := scene.get_node_or_null("Cup") as MeshInstance3D
	var label := scene.get_node_or_null("PeelLabel") as LabelVisual
	if cup == null or label == null or not (cup.mesh is CylinderMesh):
		push_error("PRIMARY_FRUSTUM_VERIFY: runtime Cup/PeelLabel contract missing")
		quit(1)
		return

	var cup_mesh := cup.mesh as CylinderMesh
	var progress_values: Array[float] = [0.07, 0.233, 0.517, 0.881]
	for progress in progress_values:
		var front := label.get_front_position(progress)
		var desired_grip := front + Vector3(-0.24 - progress * 0.06, 0.10, 0.26)
		label.set_phase("PEELING")
		label.set_peel(progress, desired_grip)

		var arrays := label.mesh.surface_get_arrays(0)
		if arrays.size() <= Mesh.ARRAY_VERTEX or not (arrays[Mesh.ARRAY_VERTEX] is PackedVector3Array):
			push_error("PRIMARY_FRUSTUM_VERIFY: partial peel mesh has no vertices at progress %.3f" % progress)
			quit(1)
			return
		var vertices := arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
		var expected_columns := label.segments + 1
		if vertices.size() != expected_columns * 2:
			push_error("PRIMARY_FRUSTUM_VERIFY: unexpected strip vertex count %d at progress %.3f" % [vertices.size(), progress])
			quit(1)
			return

		var first_attached := clampi(int(ceil(progress * float(label.segments))), 1, label.segments)
		var last_free := first_attached - 1
		var next_attached := mini(first_attached + 1, label.segments)
		var before_mid := _column_midpoint(vertices, last_free)
		var attached_mid := _column_midpoint(vertices, first_attached)
		var after_mid := _column_midpoint(vertices, next_attached)

		var front_segment_error := _distance_to_segment(front, before_mid, attached_mid)
		if front_segment_error > FRONT_SEGMENT_TOLERANCE:
			push_error("RED: non-sampled logical peel front escaped the local free/attached seam; progress=%.3f error=%.6f" % [progress, front_segment_error])
			quit(1)
			return

		for column_index in [first_attached, next_attached]:
			for row in [0, 1]:
				var vertex := vertices[column_index * 2 + row]
				var cup_local := cup.to_local(label.to_global(vertex))
				var t := clampf((cup_local.y + cup_mesh.height * 0.5) / maxf(cup_mesh.height, 0.001), 0.0, 1.0)
				var expected_radius := lerpf(cup_mesh.bottom_radius, cup_mesh.top_radius, t) + label.surface_offset
				var actual_radius := Vector2(cup_local.x, cup_local.z).length()
				var radial_error := absf(actual_radius - expected_radius)
				if radial_error > SURFACE_TOLERANCE:
					push_error("RED: non-sampled attached vertex left tapered surface; progress=%.3f column=%d row=%d error=%.6f" % [progress, column_index, row, radial_error])
					quit(1)
					return

		var before_gap := before_mid.distance_to(attached_mid)
		var after_gap := attached_mid.distance_to(after_mid)
		if before_gap > MAX_COLUMN_GAP or after_gap > MAX_COLUMN_GAP:
			push_error("RED: non-sampled peel seam has abnormal strip jump; progress=%.3f before=%.6f after=%.6f" % [progress, before_gap, after_gap])
			quit(1)
			return

		print("PRIMARY_FRUSTUM_SAMPLE progress=%.3f front_segment_error=%.6f gaps=%.6f/%.6f" % [progress, front_segment_error, before_gap, after_gap])

	scene.queue_free()
	await process_frame

	# Alternate construction/fallback contract: LabelVisual must still work when
	# instantiated without a sibling Cup, using its configured cylindrical radius.
	var standalone_parent := Node3D.new()
	standalone_parent.name = "StandaloneLabelParent"
	root.add_child(standalone_parent)
	var standalone := LabelVisual.new()
	standalone.name = "StandaloneLabel"
	standalone.cup_radius = 0.61
	standalone_parent.add_child(standalone)
	await process_frame
	if absf(standalone.get_center_cup_radius() - 0.61) > 0.000001:
		push_error("RED: standalone LabelVisual lost cylindrical fallback radius")
		quit(1)
		return
	standalone.set_phase("PEELING")
	var standalone_front := standalone.get_front_position(0.37)
	standalone.set_peel(0.37, standalone_front + Vector3(-0.18, 0.08, 0.20))
	if standalone.mesh == null or standalone.mesh.get_surface_count() == 0:
		push_error("RED: standalone LabelVisual failed to render without runtime Cup discovery")
		quit(1)
		return

	print("PASS: PRIMARY independent frustum review covers non-sampled peel seams and standalone fallback")
	standalone_parent.queue_free()
	await process_frame
	quit(0)

func _column_midpoint(vertices: PackedVector3Array, column_index: int) -> Vector3:
	return (vertices[column_index * 2] + vertices[column_index * 2 + 1]) * 0.5

func _distance_to_segment(point: Vector3, a: Vector3, b: Vector3) -> float:
	var ab := b - a
	var length_sq := ab.length_squared()
	if length_sq <= 0.0000001:
		return point.distance_to(a)
	var t := clampf((point - a).dot(ab) / length_sq, 0.0, 1.0)
	return point.distance_to(a + ab * t)
