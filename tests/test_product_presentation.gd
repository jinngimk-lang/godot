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
		[{"kind":"clear_bottle","body_color":Color(0.94,0.985,0.98),"glass_alpha":0.16,"liquid_color":Color(0.91,0.93,0.70)},"BottleOuterGlass"]
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
					if kind == "clear_bottle":
						var edge_alpha := float(shader_mat.get_shader_parameter("edge_alpha"))
						if edge_alpha < 0.21 or edge_alpha > 0.30:
							failures.append("RED: clear bottle needs bounded grazing-edge contrast on the bright market backdrop; alpha=%.3f" % edge_alpha)
						var edge_color: Color = shader_mat.get_shader_parameter("edge_color")
						var body_color: Color = pair[0].get("body_color",Color.WHITE)
						var edge_luma := (edge_color.r+edge_color.g+edge_color.b)/3.0
						var body_luma := (body_color.r+body_color.g+body_color.b)/3.0
						if edge_luma > body_luma-0.05 or edge_luma < 0.68:
							failures.append("RED: clear bottle edge cue must be cool-smoked rather than near-white/neon; luma=%.3f body=%.3f" % [edge_luma,body_luma])
			if kind == "clear_bottle" and outer != null and outer.material_override is StandardMaterial3D:
				var outer_mat := outer.material_override as StandardMaterial3D
				if outer_mat.albedo_color.a < 0.09 or outer_mat.albedo_color.a > 0.13:
					failures.append("RED: clear bottle outer shell needs enough bounded density to survive the bright cold-case background; alpha=%.3f" % outer_mat.albedo_color.a)
	product.set_inspection_yaw(0.7)
	if not is_equal_approx(product.rotation.y,0.7):
		failures.append("product decoration should follow inspection yaw")
	product.free()
	return failures
