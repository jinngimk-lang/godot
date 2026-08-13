extends RefCounted

func run() -> Array[String]:
	var failures: Array[String] = []
	var script = load("res://scripts/peel/label_visual.gd")
	if script == null:
		failures.append("LabelVisual script did not load")
		return failures

	var label = script.new()
	label.cup_radius = 0.53
	label.label_width = 1.25
	var expected_radius := label.cup_radius + 0.018

	for progress in [0.0, 0.5, 1.0]:
		var point: Vector3 = label.get_front_position(progress)
		var radial_distance := Vector2(point.x, point.z).length()
		if not is_equal_approx(radial_distance, expected_radius):
			failures.append("attached label front at %.2f is not on cup cylinder: %.5f vs %.5f" % [progress, radial_distance, expected_radius])

	var left: Vector3 = label.get_front_position(0.0)
	var right: Vector3 = label.get_front_position(1.0)
	if left.x >= 0.0 or right.x <= 0.0:
		failures.append("label endpoints should span both sides of the cup front")
	return failures
