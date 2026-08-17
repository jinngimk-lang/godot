extends RefCounted

func run() -> Array[String]:
	var failures: Array[String] = []
	var session := SessionModel.new()
	var variant := session.current_variant()
	var dims: Dictionary = variant.get("cup_dimensions",{}) as Dictionary
	var top_radius := float(dims.get("top_radius",0.0))
	var bottom_radius := float(dims.get("bottom_radius",0.0))
	var height := float(dims.get("height",0.0))
	if top_radius > 0.50:
		failures.append("RED: cafe_v1 hero cup must stay slimmer than the prototype at the top; radius=%.3f" % top_radius)
	if bottom_radius > 0.42:
		failures.append("RED: cafe_v1 hero cup base must stay visually narrow; radius=%.3f" % bottom_radius)
	if height < 1.34 or height > 1.44:
		failures.append("RED: cafe_v1 cup height must remain a bounded mid-foreground hero object; height=%.3f" % height)
	if bottom_radius > 0.0 and top_radius / bottom_radius < 1.16:
		failures.append("RED: cafe_v1 paper cup needs a readable tapered wall rather than a straight cylinder")

	var profile: Dictionary = variant.get("container_profile",{}) as Dictionary
	var body_color: Color = profile.get("body_color",Color.BLACK)
	var body_luma := (body_color.r+body_color.g+body_color.b)/3.0
	if body_luma < 0.90:
		failures.append("RED: cafe_v1 cup stock must be warm off-white rather than orange/tan; luma=%.3f" % body_luma)
	if float(profile.get("roughness",0.0)) < 0.93:
		failures.append("RED: cafe_v1 cup stock needs strongly matte paper roughness")

	var product := ProductPresentation.new()
	product.apply_profile(profile)
	for node_name in ["CupLidCrown","CupLidSnapRing","CupLidTopBead"]:
		if product.get_node_or_null(node_name) == null:
			failures.append("RED: cafe_v1 black takeaway lid needs semantic molded layer %s" % node_name)

	var crown := product.get_node_or_null("CupLidCrown") as MeshInstance3D
	if crown != null:
		if not (crown.mesh is CylinderMesh):
			failures.append("RED: CupLidCrown must use a bounded round molded shell")
		else:
			var crown_mesh := crown.mesh as CylinderMesh
			if crown_mesh.height < 0.075:
				failures.append("RED: CupLidCrown is too thin to read from the product camera")
			if crown_mesh.top_radius < 0.48 or crown_mesh.top_radius > 0.54:
				failures.append("RED: CupLidCrown radius must track the slimmer cafe cup")
		if crown.position.y < 0.77:
			failures.append("RED: molded lid crown must sit visibly above the paper rim")

	var body := MeshInstance3D.new()
	body.mesh = CylinderMesh.new()
	var lid := MeshInstance3D.new()
	lid.mesh = CylinderMesh.new()
	product.apply_to_base(body,lid,profile)
	if not (body.material_override is ShaderMaterial):
		failures.append("RED: cafe_v1 cup body needs a procedural paper-fiber ShaderMaterial instead of flat prototype color")
	else:
		var paper := body.material_override as ShaderMaterial
		if paper.shader == null or "fiber" not in paper.shader.code.to_lower() or "ROUGHNESS" not in paper.shader.code:
			failures.append("RED: cafe_v1 paper shader must encode visible bounded fiber/roughness response")
	if not (lid.material_override is StandardMaterial3D):
		failures.append("RED: base cafe lid needs a dark molded-plastic material")
	else:
		var lid_mat := lid.material_override as StandardMaterial3D
		var lid_luma := (lid_mat.albedo_color.r+lid_mat.albedo_color.g+lid_mat.albedo_color.b)/3.0
		if lid_luma > 0.08:
			failures.append("RED: cafe_v1 lid must remain near-black molded plastic; luma=%.3f" % lid_luma)
		if lid_mat.roughness < 0.22 or lid_mat.roughness > 0.46:
			failures.append("RED: cafe_v1 lid needs controlled molded-plastic roughness, got %.3f" % lid_mat.roughness)

	body.free()
	lid.free()
	product.free()
	return failures
