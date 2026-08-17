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
			if product.get_node_or_null("BottleLip") != null:
				failures.append("RED: %s must not render the old solid BottleLip disk that reads as a plastic cap" % kind)
			var mouth := product.get_node_or_null("BottleMouthRim") as MeshInstance3D
			if mouth == null:
				failures.append("RED: %s must expose a hollow BottleMouthRim" % kind)
			elif not (mouth.mesh is CylinderMesh):
				failures.append("%s BottleMouthRim must use a cylindrical glass rim" % kind)
			else:
				var mouth_mesh := mouth.mesh as CylinderMesh
				if mouth_mesh.cap_top or mouth_mesh.cap_bottom:
					failures.append("RED: %s BottleMouthRim must stay open instead of drawing a cyan/opaque cap disk" % kind)
			var edge := product.get_node_or_null("BottleEdgeFresnel") as MeshInstance3D
			if edge == null:
				failures.append("RED: %s must expose a continuous BottleEdgeFresnel shell" % kind)
			else:
				if not (edge.mesh is ArrayMesh):
					failures.append("RED: %s edge response must follow the continuous lathed bottle profile" % kind)
				if not (edge.material_override is ShaderMaterial):
					failures.append("RED: %s edge response must use a view-dependent ShaderMaterial" % kind)
				else:
					var shader_mat := edge.material_override as ShaderMaterial
					if shader_mat.shader == null:
						failures.append("%s BottleEdgeFresnel shader is missing" % kind)
					else:
						var code := shader_mat.shader.code
						if "dot(NORMAL, VIEW)" not in code:
							failures.append("RED: %s edge shader must react to view angle with NORMAL·VIEW" % kind)
						if "ALPHA" not in code or "ROUGHNESS" not in code:
							failures.append("RED: %s edge shader must control transparent optical edge response" % kind)
	product.set_inspection_yaw(0.7)
	if not is_equal_approx(product.rotation.y,0.7):
		failures.append("product decoration should follow inspection yaw")
	product.free()
	return failures
