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
		[{"kind":"amber_bottle","body_color":Color(0.38,0.11,0.024),"glass_alpha":0.36},"BottleOuterGlass"],
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
			if kind == "amber_bottle" and outer != null:
				var outer_mat := outer.material_override as StandardMaterial3D
				var liquid := product.get_node_or_null("BottleLiquid") as MeshInstance3D
				var liquid_mat := liquid.material_override as StandardMaterial3D if liquid != null else null
				if outer_mat == null or outer_mat.albedo_color.a > 0.15:
					failures.append("RED: amber outer glass must stay translucent enough for shoulder/neck separation")
				if liquid_mat == null or liquid_mat.albedo_color.a > 0.16:
					failures.append("RED: amber liquid must not turn the bottle body into an opaque brown mass")
	product.set_inspection_yaw(0.7)
	if not is_equal_approx(product.rotation.y,0.7):
		failures.append("product decoration should follow inspection yaw")
	product.free()
	return failures
