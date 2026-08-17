extends RefCounted

func run() -> Array[String]:
	var failures: Array[String] = []
	var geometry_path := "res://scripts/peel/label_geometry.gd"
	if not ResourceLoader.exists(geometry_path):
		failures.append("RED: missing bounded label geometry contract")
		return failures

	var geometry = load(geometry_path)
	if geometry == null:
		failures.append("LabelGeometry script did not load")
		return failures

	var width := 1.25
	var radius := 0.53
	var label_y := 0.22
	var offset := 0.018
	var segments := 28
	var progress := 0.55
	var far_grip := Vector3(-6.0, 2.0, 4.0)
	var effective: Vector3 = geometry.resolve_grip(progress, far_grip, width, radius, label_y, offset)
	var front: Vector3 = CupSurface.attached_point(progress, width, radius, label_y, offset)
	var available := width * progress
	if effective.distance_to(front) > available + 0.0001:
		failures.append("effective grip exceeds physically peeled label length")

	var peel_points: PackedVector3Array = geometry.peeling_points(
		progress, far_grip, width, radius, label_y, offset, segments
	)
	if peel_points.size() != segments + 1:
		failures.append("peeling centerline should return segments + 1 points")
	else:
		var nominal := width / float(segments)
		for i in range(peel_points.size() - 1):
			var spacing := peel_points[i].distance_to(peel_points[i + 1])
			if spacing > nominal * 1.8:
				failures.append("label segment stretch exceeded bounded tolerance at segment %d: %.5f" % [i, spacing])
				break

	var held_grip := Vector3(1.8, 0.6, 1.2)
	var held_direction := Vector3(-1.0, 0.1, -0.15)
	var held_a: PackedVector3Array = geometry.held_points(held_grip, held_direction, width, segments)
	var move_delta := Vector3(0.7, -0.2, 0.35)
	var held_b: PackedVector3Array = geometry.held_points(held_grip + move_delta, held_direction, width, segments)
	if held_a.size() != segments + 1 or held_b.size() != segments + 1:
		failures.append("held centerline should return segments + 1 points")
	else:
		for i in range(held_a.size()):
			var actual_delta := held_b[i] - held_a[i]
			if actual_delta.distance_to(move_delta) > 0.0001:
				failures.append("held label must translate with grip without a cup anchor")
				break

	var old_cup_front := CupSurface.attached_point(1.0, width, radius, label_y, offset)
	var retains_cup_anchor := false
	for point in held_a:
		if point.distance_to(old_cup_front) < 0.00001:
			retains_cup_anchor = true
			break
	if retains_cup_anchor:
		failures.append("held label geometry must not retain the cup-side endpoint")

	var visual_path := "res://scripts/peel/label_visual.gd"
	if not ResourceLoader.exists(visual_path):
		failures.append("RED: missing LabelVisual paper presentation")
		return failures
	var visual = load(visual_path).new()
	visual.segments = segments
	visual.label_height = 0.36
	var attached_edges: PackedVector2Array = visual.get_edge_offsets(0.0)
	var peeled_edges: PackedVector2Array = visual.get_edge_offsets(progress)
	var repeated_edges: PackedVector2Array = visual.get_edge_offsets(progress)
	if attached_edges.size() != segments + 1 or peeled_edges.size() != segments + 1:
		failures.append("RED: paper edge profile must cover every label segment")
	elif peeled_edges != repeated_edges:
		failures.append("RED: paper edge profile must be deterministic across identical frames")
	else:
		var attached_max := 0.0
		var peeled_min := INF
		var peeled_max := -INF
		for i in range(attached_edges.size()):
			attached_max = maxf(attached_max, maxf(absf(attached_edges[i].x), absf(attached_edges[i].y)))
			peeled_min = minf(peeled_min, minf(peeled_edges[i].x, peeled_edges[i].y))
			peeled_max = maxf(peeled_max, maxf(peeled_edges[i].x, peeled_edges[i].y))
		if attached_max > 0.0030:
			failures.append("attached label deckle must remain subtle; max=%.4f" % attached_max)
		if peeled_max - peeled_min < 0.010:
			failures.append("RED: partially peeled label needs visible deterministic edge irregularity")
		var boundary_index := clampi(int(round(progress * float(segments))),0,segments)
		var boundary := peeled_edges[boundary_index]
		if boundary.x > -0.001 and boundary.y < 0.001:
			failures.append("RED: peel front should narrow/notch the paper edge instead of staying rectangular")
	var thickness := float(visual.get_paper_thickness())
	if thickness < 0.003 or thickness > 0.007:
		failures.append("RED: label needs a thin but visible paper sidewall; got %.4f" % thickness)

	if not visual.has_method("get_torn_front_fringe"):
		failures.append("RED: partially peeled label needs a deterministic torn-front fiber fringe")
	else:
		var attached_fringe: PackedVector2Array = visual.get_torn_front_fringe(0.0)
		var torn_fringe: PackedVector2Array = visual.get_torn_front_fringe(progress)
		var repeated_fringe: PackedVector2Array = visual.get_torn_front_fringe(progress)
		if not attached_fringe.is_empty():
			failures.append("RED: fully attached label must not expose torn-front fibers")
		if torn_fringe.size() < 5 or torn_fringe.size() > 11:
			failures.append("RED: torn front should use a small readable cluster of fibers; got %d" % torn_fringe.size())
		elif torn_fringe != repeated_fringe:
			failures.append("RED: torn-front fringe must be deterministic across identical frames")
		else:
			var longest := 0.0
			var shortest := INF
			for fiber in torn_fringe:
				longest = maxf(longest, fiber.y)
				shortest = minf(shortest, fiber.y)
			if longest < 0.010:
				failures.append("RED: torn-front fibers must protrude enough to break the rectangular silhouette")
			if longest - shortest < 0.004:
				failures.append("RED: torn-front fibers need varied lengths instead of a uniform comb")

	visual._ready()
	var attached_surface_count: int = visual.mesh.get_surface_count() if visual.mesh != null else 0
	visual.set_peel(progress,far_grip)
	var peeled_surface_count: int = visual.mesh.get_surface_count() if visual.mesh != null else 0
	if attached_surface_count > 3:
		failures.append("RED: fully attached label should not generate a separate exposed backing surface")
	if peeled_surface_count < attached_surface_count + 2:
		failures.append("RED: peeled label needs both torn-front fibers and a distinct exposed backing surface")
	visual.free()

	return failures