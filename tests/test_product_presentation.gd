extends RefCounted

func run() -> Array[String]:
	var failures: Array[String] = []
	var path := "res://scripts/presentation/product_presentation.gd"
	if not ResourceLoader.exists(path):
		return ["PRODUCT_RED: missing ProductPresentation"]
	var product = load(path).new()
	# The glass edge pass must be symmetric to normal orientation. Using raw
	# dot(NORMAL, VIEW) lets a front-facing surface with the opposite winding
	# become full Fresnel in GL compatibility and turns a clear bottle milky.
	var edge_shader := String(product.GLASS_EDGE_SHADER)
	if "abs(dot" not in edge_shader:
		failures.append("BOTTLE_GLASS_RED: edge Fresnel must use absolute view/normal alignment so the bottle center stays clear")
	var cases := [
		[{"kind":"paper_cup","body_color":Color(0.88,0.82,0.70)},"CupPaperDetails"],
		[{"kind":"sauce_jar","body_color":Color(0.92,0.97,0.98),"liquid_color":Color(0.55,0.08,0.035)},"JarGlass"],
		[{"kind":"tin_can","body_color":Color(0.62,0.65,0.68)},"TinCanBody"],
		[{"kind":"clear_bottle","body_color":Color(0.94,0.985,0.98),"glass_alpha":0.16,"liquid_color":Color(0.91,0.93,0.70)},"BottleOuterGlass"],
		[{"kind":"soda_can","body_color":Color(0.74,0.76,0.78)},"SodaCanBody"]
	]
	for pair in cases:
		var profile: Dictionary = pair[0]
		var semantic_node := String(pair[1])
		product.apply_profile(profile)
		var kind := String(profile.get("kind",""))
		if product.get_active_kind() != kind:
			failures.append("PRODUCT_RED: product should activate %s" % kind)
		if product.get_node_or_null(semantic_node) == null:
			failures.append("PRODUCT_RED: %s missing semantic node %s" % [kind,semantic_node])
		var contact_shadow := product.get_node_or_null("ProductContactShadow") as MeshInstance3D
		if contact_shadow == null or not (contact_shadow.mesh is QuadMesh):
			failures.append("PRODUCT_RED: %s needs one bounded soft contact shadow quad" % kind)

		if kind == "sauce_jar":
			if product.get_node_or_null("JarContents") == null or product.get_node_or_null("JarLid") == null:
				failures.append("PRODUCT_RED: sauce jar needs visible sauce contents and metal lid")
		if kind == "tin_can":
			if product.get_node_or_null("TinCanTopRim") == null or product.get_node_or_null("TinCanBottomRim") == null:
				failures.append("PRODUCT_RED: tin can needs rolled metal rims")
		if kind == "clear_bottle":
			if product.get_node_or_null("BottleInnerGlass") == null or product.get_node_or_null("BottleLiquid") == null:
				failures.append("PRODUCT_RED: market bottle needs layered glass and liquid")
		if kind == "soda_can":
			if product.get_node_or_null("SodaCanTopRim") == null or product.get_node_or_null("SodaCanBottomRim") == null:
				failures.append("PRODUCT_RED: soda can needs rolled aluminum rims")
			if product.get_node_or_null("Condensation") == null:
				failures.append("PRODUCT_RED: soda can needs visible condensation")

	product.set_inspection_yaw(0.7)
	if not is_equal_approx(product.rotation.y,0.7):
		failures.append("PRODUCT_RED: product decoration should follow inspection yaw")
	product.free()
	return failures
