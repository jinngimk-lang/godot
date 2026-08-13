extends RefCounted

func run() -> Array[String]:
	var failures: Array[String] = []
	var path := "res://scripts/peel/cup_surface.gd"
	if not ResourceLoader.exists(path):
		failures.append("RED: missing pure cup-surface geometry contract")
		return failures
	var script = load(path)
	if script == null:
		failures.append("CupSurface script did not load")
		return failures

	var cup_radius := 0.53
	var label_width := 1.25
	var label_y := 0.22
	var surface_offset := 0.018
	var expected_radius := cup_radius + surface_offset

	for u in [0.0, 0.5, 1.0]:
		var point: Vector3 = script.attached_point(u, label_width, cup_radius, label_y, surface_offset)
		var radial_distance := Vector2(point.x, point.z).length()
		if not is_equal_approx(radial_distance, expected_radius):
			failures.append("attached label point at %.2f is not on cup cylinder: %.5f vs %.5f" % [u, radial_distance, expected_radius])

	var left: Vector3 = script.attached_point(0.0, label_width, cup_radius, label_y, surface_offset)
	var right: Vector3 = script.attached_point(1.0, label_width, cup_radius, label_y, surface_offset)
	if left.x >= 0.0 or right.x <= 0.0:
		failures.append("label endpoints should span both sides of the cup front")
	if left.z <= 0.0 or right.z <= 0.0:
		failures.append("attached label should remain on the visible front hemisphere")
	return failures
