extends SceneTree

const SURFACE_TOLERANCE := 0.004
const FRONT_TOLERANCE := 0.002
const MAX_COLUMN_GAP := 0.09

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load("res://scenes/peel_lab/peel_lab.tscn") as PackedScene
	if packed == null:
		push_error("PEEL_SEAM_SMOKE: peel_lab scene failed to load")
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
		push_error("PEEL_SEAM_SMOKE: runtime Cup/PeelLabel contract missing")
		quit(1)
		return

	# Put the peel front exactly on a sampled strip column. This attacks the
	# renderer boundary where LabelGeometry switches free/attached ownership.
	var boundary_index := 7
	var progress := float(boundary_index) / float(label.segments)
	var front := label.get_front_position(progress)
	var desired_grip := front + Vector3(-0.25, 0.12, 0.28)
	label.set_phase("PEELING")
	label.set_peel(progress, desired_grip)

	var arrays := label.mesh.surface_get_arrays(0)
	if arrays.size() <= Mesh.ARRAY_VERTEX or not (arrays[Mesh.ARRAY_VERTEX] is PackedVector3Array):
		push_error("PEEL_SEAM_SMOKE: partial peel mesh has no vertices")
		quit(1)
		return
	var vertices := arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
	var expected_columns := label.segments + 1
	if vertices.size() != expected_columns * 2:
		push_error("PEEL_SEAM_SMOKE: unexpected strip vertex count %d for %d columns" % [vertices.size(), expected_columns])
		quit(1)
		return

	var boundary_mid := _column_midpoint(vertices, boundary_index)
	var before_mid := _column_midpoint(vertices, boundary_index - 1)
	var after_mid := _column_midpoint(vertices, boundary_index + 1)
	var front_error := boundary_mid.distance_to(front)
	if front_error > FRONT_TOLERANCE:
		push_error("RED: sampled peel-front column is discontinuous from logical front; error=%.6f progress=%.6f" % [front_error, progress])
		quit(1)
		return

	var cup_mesh := cup.mesh as CylinderMesh
	for column_index in [boundary_index, boundary_index + 1]:
		for row in [0, 1]:
			var vertex := vertices[column_index * 2 + row]
			var cup_local := cup.to_local(label.to_global(vertex))
			var t := clampf((cup_local.y + cup_mesh.height * 0.5) / cup_mesh.height, 0.0, 1.0)
			var expected_radius := lerpf(cup_mesh.bottom_radius, cup_mesh.top_radius, t) + label.surface_offset
			var actual_radius := Vector2(cup_local.x, cup_local.z).length()
			var radial_error := absf(actual_radius - expected_radius)
			if radial_error > SURFACE_TOLERANCE:
				push_error("RED: attached peel-front vertex left tapered surface; column=%d row=%d error=%.6f" % [column_index, row, radial_error])
				quit(1)
				return

	var before_gap := before_mid.distance_to(boundary_mid)
	var after_gap := boundary_mid.distance_to(after_mid)
	if before_gap > MAX_COLUMN_GAP or after_gap > MAX_COLUMN_GAP:
		push_error("RED: peel-front seam has an abnormal strip jump; before=%.6f after=%.6f" % [before_gap, after_gap])
		quit(1)
		return
	var smaller_gap := maxf(minf(before_gap, after_gap), 0.000001)
	var gap_ratio := maxf(before_gap, after_gap) / smaller_gap
	if gap_ratio > 2.0:
		push_error("RED: peel-front seam spacing is discontinuous; before=%.6f after=%.6f ratio=%.3f" % [before_gap, after_gap, gap_ratio])
		quit(1)
		return

	print("PASS: sampled partial-peel seam stays continuous; progress=%.6f front_error=%.6f gaps=%.6f/%.6f" % [progress, front_error, before_gap, after_gap])
	scene.queue_free()
	await process_frame
	quit(0)

func _column_midpoint(vertices: PackedVector3Array, column_index: int) -> Vector3:
	return (vertices[column_index * 2] + vertices[column_index * 2 + 1]) * 0.5
