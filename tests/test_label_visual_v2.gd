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

	return failures
