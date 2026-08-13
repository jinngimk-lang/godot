extends SceneTree

const MIN_ATTACHED_DOT := 0.999
const MIN_SEAM_DOT := 0.0
const CURVE_Y_EPS := 0.01

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load("res://scenes/peel_lab/peel_lab.tscn") as PackedScene
	if packed == null:
		push_error("PRIMARY_NORMAL_VERIFY: peel_lab failed to load")
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
		push_error("PRIMARY_NORMAL_VERIFY: runtime Cup/PeelLabel contract missing")
		quit(1)
		return
	var cup_mesh := cup.mesh as CylinderMesh
	var slope: float = (cup_mesh.top_radius - cup_mesh.bottom_radius) / maxf(cup_mesh.height, 0.001)

	var progress := 0.233
	var front := label.get_front_position(progress)
	label.set_phase("PEELING")
	label.set_peel(progress, front + Vector3(-0.34, 0.13, 0.31))
	var partial: Array = _mesh_arrays(label)
	if partial.is_empty():
		quit(1)
		return
	var vertices := partial[0] as PackedVector3Array
	var normals := partial[1] as PackedVector3Array
	var first_attached: int = clampi(int(ceil(progress * float(label.segments))), 1, label.segments)
	var last_free: int = first_attached - 1

	print("PRIMARY_NORMAL_DIAG progress=%.6f segments=%d first_attached=%d last_free=%d vertices=%d normals=%d" % [progress, label.segments, first_attached, last_free, vertices.size(), normals.size()])
	for column in range(maxi(last_free - 2, 0), mini(first_attached + 3, label.segments + 1)):
		var u: float = float(column) / float(label.segments)
		for row in [0, 1]:
			var idx: int = column * 2 + int(row)
			print("PRIMARY_NORMAL_DIAG column=%d u=%.6f row=%d vertex=%s normal=%s" % [column, u, int(row), str(vertices[idx]), str(normals[idx].normalized())])

	var min_attached_dot := 1.0
	var min_seam_dot := 1.0
	for row_value in [0, 1]:
		var row: int = int(row_value)
		var free_normal: Vector3 = normals[last_free * 2 + row].normalized()
		var attached_index: int = first_attached * 2 + row
		var vertex: Vector3 = vertices[attached_index]
		var mesh_normal: Vector3 = normals[attached_index].normalized()
		var cup_local: Vector3 = cup.to_local(label.to_global(vertex))
		var radial: Vector3 = Vector3(cup_local.x, 0.0, cup_local.z).normalized()
		var expected: Vector3 = Vector3(radial.x, -slope, radial.z).normalized()
		var world_normal: Vector3 = (label.global_transform.basis * mesh_normal).normalized()
		var cup_normal: Vector3 = (cup.global_transform.basis.inverse() * world_normal).normalized()
		min_attached_dot = minf(min_attached_dot, cup_normal.dot(expected))
		min_seam_dot = minf(min_seam_dot, free_normal.dot(mesh_normal))
		if absf(free_normal.y) > CURVE_Y_EPS:
			push_error("RED: first free partial-peel column was incorrectly snapped to cup taper normal; row=%d normal=%s" % [row, str(free_normal)])
			quit(1)
			return
		if mesh_normal.y >= -0.03:
			push_error("RED: first attached partial-peel column lost the widening-upward taper normal")
			quit(1)
			return
	if min_attached_dot < MIN_ATTACHED_DOT:
		push_error("RED: partial-peel attached normal disagrees with real frustum; min dot %.6f" % min_attached_dot)
		quit(1)
		return
	if min_seam_dot <= MIN_SEAM_DOT:
		push_error("RED: partial-peel free/attached normal seam inverted beyond 90 degrees; min dot %.6f" % min_seam_dot)
		quit(1)
		return
	print("PRIMARY_NORMAL_PARTIAL attached_dot=%.6f seam_dot=%.6f" % [min_attached_dot, min_seam_dot])

	label.set_phase("DETACHING")
	label.set_detach_alpha(0.55)
	var detach_grip: Vector3 = label.get_front_position(1.0) + Vector3(-0.30, 0.16, 0.26)
	label.set_peel(1.0, detach_grip)
	if not _all_normals_curve_like(label, "DETACHING"):
		quit(1)
		return
	label.set_phase("HELD")
	label.set_peel(1.0, detach_grip + Vector3(-0.12, 0.05, 0.08))
	if not _all_normals_curve_like(label, "HELD"):
		quit(1)
		return

	var narrowing_point := Vector3(0.5, 0.0, 0.2)
	var narrowing_normal := CupSurface.frustum_surface_normal(narrowing_point, 0.54, 0.45, 1.48)
	if narrowing_normal.y <= 0.0:
		push_error("RED: frustum normal slope sign is hard-coded for widening cups")
		quit(1)
		return

	scene.queue_free()
	await process_frame

	var standalone_parent := Node3D.new()
	root.add_child(standalone_parent)
	var standalone := LabelVisual.new()
	standalone.cup_radius = 0.61
	standalone_parent.add_child(standalone)
	await process_frame
	standalone.set_phase("PEELING")
	var standalone_front := standalone.get_front_position(0.37)
	standalone.set_peel(0.37, standalone_front + Vector3(-0.24, 0.08, 0.20))
	if absf(standalone.get_center_cup_radius() - 0.61) > 0.000001:
		push_error("RED: standalone cylindrical fallback radius changed")
		quit(1)
		return
	if not _all_normals_curve_like(standalone, "standalone fallback"):
		quit(1)
		return

	print("PASS: PRIMARY independent frustum-normal review covers partial seam, detach/held, slope sign and cylindrical fallback")
	standalone_parent.queue_free()
	await process_frame
	quit(0)

func _mesh_arrays(label: LabelVisual) -> Array:
	if label.mesh == null or label.mesh.get_surface_count() == 0:
		push_error("PRIMARY_NORMAL_VERIFY: label has no render surface")
		return []
	var arrays: Array = label.mesh.surface_get_arrays(0)
	if arrays.size() <= Mesh.ARRAY_NORMAL:
		push_error("PRIMARY_NORMAL_VERIFY: label surface arrays incomplete")
		return []
	if not (arrays[Mesh.ARRAY_VERTEX] is PackedVector3Array) or not (arrays[Mesh.ARRAY_NORMAL] is PackedVector3Array):
		push_error("PRIMARY_NORMAL_VERIFY: label vertex/normal arrays missing")
		return []
	return [arrays[Mesh.ARRAY_VERTEX], arrays[Mesh.ARRAY_NORMAL]]

func _all_normals_curve_like(label: LabelVisual, context: String) -> bool:
	var arrays: Array = _mesh_arrays(label)
	if arrays.is_empty():
		return false
	var normals := arrays[1] as PackedVector3Array
	if normals.is_empty():
		push_error("PRIMARY_NORMAL_VERIFY: %s normals empty" % context)
		return false
	var max_abs_y := 0.0
	for normal in normals:
		max_abs_y = maxf(max_abs_y, absf(normal.normalized().y))
	if max_abs_y > CURVE_Y_EPS:
		push_error("RED: %s retained cup-taper normal component after leaving attached surface; max |y| %.6f" % [context, max_abs_y])
		return false
	print("PRIMARY_NORMAL_CURVE %s max_abs_y=%.6f" % [context, max_abs_y])
	return true
