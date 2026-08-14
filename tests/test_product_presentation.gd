extends RefCounted

func run() -> Array[String]:
	var failures: Array[String] = []
	var path := "res://scripts/presentation/product_presentation.gd"
	if not ResourceLoader.exists(path):
		failures.append("RED: missing ProductPresentation")
		return failures
	var product = load(path).new()
	var cases := [
		[{"kind":"paper_cup", "body_color":Color(0.88,0.82,0.70)}, "CupPaperDetails"],
		[{"kind":"amber_bottle", "body_color":Color(0.20,0.075,0.025)}, "BottleShoulder"],
		[{"kind":"clear_bottle", "body_color":Color(0.88,0.96,0.94), "liquid_color":Color(0.92,0.91,0.68)}, "BottleLiquid"]
	]
	for pair in cases:
		product.apply_profile(pair[0])
		if product.get_active_kind() != String(pair[0].kind):
			failures.append("product should activate %s" % String(pair[0].kind))
		if product.get_node_or_null(String(pair[1])) == null:
			failures.append("%s missing semantic presentation node %s" % [String(pair[0].kind), String(pair[1])])
	product.set_inspection_yaw(0.7)
	if not is_equal_approx(product.rotation.y, 0.7):
		failures.append("product decoration should follow inspection yaw")
	return failures
