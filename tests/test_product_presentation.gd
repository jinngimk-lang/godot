extends RefCounted

func run() -> Array[String]:
	var failures: Array[String] = []
	var path := "res://scripts/presentation/product_presentation.gd"
	if not ResourceLoader.exists(path):
		failures.append("RED: missing ProductPresentation")
		return failures
	var product = load(path).new()
	var cases := [
		[{"kind":"paper_cup","body_color":Color(0.88,0.82,0.70)},"CupPaperDetails"],
		[{"kind":"amber_bottle","body_color":Color(0.32,0.10,0.025),"glass_alpha":0.48},"BottleOuterGlass"],
		[{"kind":"clear_bottle","body_color":Color(0.88,0.96,0.94),"glass_alpha":0.19,"liquid_color":Color(0.92,0.91,0.68)},"BottleOuterGlass"]
	]
	for pair in cases:
		product.apply_profile(pair[0])
		var kind := String(pair[0].kind)
		if product.get_active_kind() != kind:
			failures.append("product should activate %s" % kind)
		if product.get_node_or_null(String(pair[1])) == null:
			failures.append("%s missing semantic presentation node %s" % [kind,String(pair[1])])
		if kind in ["amber_bottle","clear_bottle"]:
			var outer := product.get_node_or_null("BottleOuterGlass") as MeshInstance3D
			if outer == null or not (outer.mesh is ArrayMesh):
				failures.append("RED: %s must use one continuous lathed ArrayMesh outer glass shell" % kind)
			if product.get_node_or_null("BottleInnerGlass") == null or product.get_node_or_null("BottleLiquid") == null:
				failures.append("%s must use layered outer glass + inner glass + liquid" % kind)
			if product.get_node_or_null("BottleShoulder") != null:
				failures.append("RED: %s must not fall back to stacked BottleShoulder cylinder primitives" % kind)
			if product.get_node_or_null("BottleHighlight") != null:
				failures.append("RED: %s must not use rectangular BottleHighlight guide strips" % kind)
	product.set_inspection_yaw(0.7)
	if not is_equal_approx(product.rotation.y,0.7):
		failures.append("product decoration should follow inspection yaw")
	product.free()
	return failures
