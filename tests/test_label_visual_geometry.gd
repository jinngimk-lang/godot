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

	# Preserve the original cylindrical fallback contract for standalone callers.
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

	# Production cup is a frustum: radius must interpolate with vertical height,
	# attached strip edges must use the radius at their own y coordinate, and
	# their shading normals must include the taper slope instead of staying flat in y.
	var bottom_radius := 0.45
	var top_radius := 0.54
	var cup_height := 1.48
	var cup_center_y := 0.05
	var bottom_y := cup_center_y - cup_height * 0.5
	var top_y := cup_center_y + cup_height * 0.5
	var midpoint_radius: float = script.frustum_radius_at_y(
		cup_center_y, bottom_radius, top_radius, cup_height, cup_center_y
	)
	if absf(midpoint_radius - 0.495) > 0.00001:
		failures.append("frustum midpoint radius should interpolate between bottom and top")
	if absf(script.frustum_radius_at_y(bottom_y, bottom_radius, top_radius, cup_height, cup_center_y) - bottom_radius) > 0.00001:
		failures.append("frustum bottom y must use bottom radius")
	if absf(script.frustum_radius_at_y(top_y, bottom_radius, top_radius, cup_height, cup_center_y) - top_radius) > 0.00001:
		failures.append("frustum top y must use top radius")

	var expected_slope := (top_radius - bottom_radius) / cup_height
	var expected_normal_y := -expected_slope / sqrt(1.0 + expected_slope * expected_slope)
	for sample_y in [label_y - 0.21, label_y, label_y + 0.21]:
		var expected_frustum_radius: float = script.frustum_radius_at_y(
			sample_y, bottom_radius, top_radius, cup_height, cup_center_y
		) + surface_offset
		for u in [0.0, 0.5, 1.0]:
			var point: Vector3 = script.attached_point_on_frustum(
				u,
				label_width,
				sample_y,
				bottom_radius,
				top_radius,
				cup_height,
				cup_center_y,
				surface_offset
			)
			var actual_frustum_radius := Vector2(point.x, point.z).length()
			if absf(actual_frustum_radius - expected_frustum_radius) > 0.00001:
				failures.append("frustum attached point at y=%.3f u=%.2f missed radius: %.5f vs %.5f" % [sample_y, u, actual_frustum_radius, expected_frustum_radius])
				break
			var normal: Vector3 = script.frustum_surface_normal(point, bottom_radius, top_radius, cup_height)
			if absf(normal.length() - 1.0) > 0.00001:
				failures.append("frustum surface normal must be unit length")
				break
			var radial := Vector3(point.x, 0.0, point.z).normalized()
			if normal.dot(radial) <= 0.99:
				failures.append("frustum surface normal must face outward at y=%.3f u=%.2f" % [sample_y, u])
				break
			if absf(normal.y - expected_normal_y) > 0.00001:
				failures.append("frustum surface normal must include taper slope: %.6f vs %.6f" % [normal.y, expected_normal_y])
				break

	return failures
