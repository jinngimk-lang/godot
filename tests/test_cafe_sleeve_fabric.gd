extends RefCounted

func run() -> Array[String]:
	var failures: Array[String] = []
	var presentation := ForearmPresentation.new()
	var methods: Array[String] = []
	for method in presentation.get_method_list():
		methods.append(String(method.get("name","")))

	if not methods.has("_sleeve_cross_section"):
		failures.append("RED: cafe_v1 sleeve needs an explicit non-circular cloth cross-section contract")
	else:
		var wrist_side: Vector2 = presentation.call("_sleeve_cross_section",0.18,0.0)
		var wrist_vertical: Vector2 = presentation.call("_sleeve_cross_section",0.18,PI*0.5)
		if absf(wrist_side.x) <= absf(wrist_vertical.y)*1.12:
			failures.append("RED: cafe sleeve wrist must read as a flattened cloth oval rather than a round hose")
		var fold_a: Vector2 = presentation.call("_sleeve_cross_section",0.72,PI*0.25)
		var fold_b: Vector2 = presentation.call("_sleeve_cross_section",0.72,PI*0.75)
		if absf(fold_a.length()-fold_b.length()) < 0.004:
			failures.append("RED: cafe sleeve silhouette needs bounded asymmetric cloth folds instead of a perfect extrusion")
		var far_side: Vector2 = presentation.call("_sleeve_cross_section",0.90,0.0)
		if far_side.length() <= wrist_side.length()*1.25:
			failures.append("RED: cafe sleeve should broaden naturally toward the off-frame forearm")

	var cloth = presentation.call("_make_cafe_cloth")
	if not (cloth is ShaderMaterial):
		failures.append("RED: cafe sleeve needs a procedural cloth ShaderMaterial rather than flat prototype color")
	else:
		var cloth_shader := (cloth as ShaderMaterial).shader
		var code := cloth_shader.code.to_lower() if cloth_shader != null else ""
		if "weave" not in code or "roughness" not in code:
			failures.append("RED: cafe sleeve shader must encode bounded weave and roughness response")
		if (cloth as ShaderMaterial).resource_name != "SleeveFabric":
			failures.append("cafe cloth shader must preserve SleeveFabric semantic identity")

	var mesh: ArrayMesh = presentation.call("_build_curve_mesh",Vector3.ZERO,Vector3(-0.5,-0.4,0.2),Vector3(-2.0,-1.0,0.4),Vector3(-4.5,-1.2,0.6))
	if mesh == null or mesh.get_surface_count() != 1:
		failures.append("cafe sleeve curve mesh did not build one surface")
	else:
		var arrays: Array = mesh.surface_get_arrays(0)
		var uv_value = arrays[Mesh.ARRAY_TEX_UV]
		if uv_value == null:
			failures.append("RED: cafe sleeve mesh needs stable UVs so cloth weave follows the arm instead of screen space")
		elif uv_value is PackedVector2Array:
			var uvs := uv_value as PackedVector2Array
			if uvs.is_empty():
				failures.append("RED: cafe sleeve mesh needs stable UVs so cloth weave follows the arm instead of screen space")
			else:
				var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
				if uvs.size() != vertices.size():
					failures.append("cafe sleeve UV count must match generated vertex count")
		else:
			failures.append("RED: cafe sleeve UV channel has an unexpected runtime type")

	presentation.free()
	return failures
