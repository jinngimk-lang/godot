extends RefCounted

func run() -> Array[String]:
	var failures: Array[String] = []
	var geometry_path := "res://scripts/peel/label_geometry.gd"
	if not ResourceLoader.exists(geometry_path):
		failures.append("FLAP_ARC_RED: missing LabelGeometry")
		return failures
	var geometry = load(geometry_path)
	if geometry == null:
		failures.append("FLAP_ARC_RED: LabelGeometry did not load")
		return failures

	# Mirror the product evidence range rather than inventing an extreme pull.
	# The free flap should visibly bow away from the straight grip->peel-front
	# chord so the 38-48% captures read as flexible paper, not a rigid triangle.
	var width := 1.25
	var radius := 0.53
	var label_y := 0.22
	var offset := 0.018
	var segments := 28
	var progress := 0.45
	var front: Vector3 = CupSurface.attached_point(progress,width,radius,label_y,offset)
	var desired_grip := front + Vector3(-0.95,0.11,0.56)
	var grip: Vector3 = geometry.resolve_grip(progress,desired_grip,width,radius,label_y,offset)
	var points: PackedVector3Array = geometry.peeling_points(progress,desired_grip,width,radius,label_y,offset,segments)
	if points.size() != segments + 1:
		failures.append("FLAP_ARC_RED: peeling centerline must return segments + 1 points")
		return failures

	var free_length := width * progress
	var max_deviation := 0.0
	for i in range(points.size()):
		var u := float(i) / float(segments)
		if u > progress:
			break
		var t := clampf(u / progress,0.0,1.0)
		var chord_point := grip.lerp(front,t)
		max_deviation = maxf(max_deviation,points[i].distance_to(chord_point))
	var arc_ratio := max_deviation / maxf(free_length,0.0001)
	if arc_ratio < 0.12:
		failures.append("FLAP_ARC_RED: lifted flap is too chord-flat for a readable flexible-paper arc; ratio=%.4f" % arc_ratio)

	# Preserve the existing no-rubber-sheet constraint while adding curvature.
	var nominal := width / float(segments)
	for i in range(points.size()-1):
		var spacing := points[i].distance_to(points[i+1])
		if spacing > nominal * 1.8:
			failures.append("FLAP_ARC_RED: added curvature stretched segment %d to %.5f" % [i,spacing])
			break
	return failures
