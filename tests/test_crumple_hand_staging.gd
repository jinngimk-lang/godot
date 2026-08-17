extends RefCounted

func run() -> Array[String]:
	var failures: Array[String] = []
	var root := Node3D.new()
	var source := CupCrumplePresentation.new()
	source.name = "CupCrumplePresentation"
	root.add_child(source)

	var left := Node3D.new()
	left.name = "LeftHand"
	left.position = Vector3(0.40, 0.10, 0.0)
	root.add_child(left)

	var right := Node3D.new()
	right.name = "RightHand"
	right.position = Vector3(-0.40, 0.12, 0.0)
	root.add_child(right)

	var staging := CrumpleHandStaging.new()
	staging.name = "CrumpleHandStaging"
	root.add_child(staging)
	staging._bind()

	var left_home := left.position
	var right_home := right.position
	staging._on_crumple_changed(0.60)

	if left.position.x >= left_home.x - 0.001:
		failures.append("crumple support hand must move inward toward the cup")
	if right.position.x <= right_home.x + 0.001:
		failures.append("RED: released peel hand must also move inward during cafe crumple")
	if left.position.y > left_home.y + 0.001 or right.position.y > right_home.y + 0.001:
		failures.append("crumple hands must not drift upward while applying pressure")
	if left.position.distance_to(left_home) > 0.11 or right.position.distance_to(right_home) > 0.11:
		failures.append("crumple staging must remain a bounded presentation offset")

	staging.reset_staging()
	if not left.position.is_equal_approx(left_home):
		failures.append("crumple reset must restore support-hand root exactly")
	if not right.position.is_equal_approx(right_home):
		failures.append("RED: crumple reset must restore released peel-hand root exactly")

	root.free()
	return failures
