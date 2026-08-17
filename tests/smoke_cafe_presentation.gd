extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load("res://scenes/peel_lab/peel_lab.tscn") as PackedScene
	if packed == null:
		push_error("CAFE_RED: peel lab scene failed to load")
		quit(1)
		return
	var scene := packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	await process_frame

	var failures: Array[String] = []
	var presentation := scene.get_node_or_null("CafePresentation") as Node3D
	if presentation == null:
		failures.append("CAFE_RED: missing CafePresentation")
	else:
		var backdrop := presentation.get_node_or_null("Backdrop") as MeshInstance3D
		if backdrop == null or not (backdrop.mesh is BoxMesh):
			failures.append("CAFE_RED: missing BoxMesh backdrop")
		else:
			var wall := backdrop.mesh as BoxMesh
			if wall.size.x < 7.5:
				failures.append("CAFE_RED: backdrop must cover wide viewport without black side gutters")
		var ground_shadow := presentation.get_node_or_null("GroundShadow") as MeshInstance3D
		if ground_shadow == null or ground_shadow.mesh == null or ground_shadow.material_override == null:
			failures.append("CAFE_RED: missing soft cup GroundShadow")

		var seam := presentation.get_node_or_null("CupPaperSeam") as MeshInstance3D
		if seam == null or not (seam.mesh is ArrayMesh) or seam.material_override == null:
			failures.append("CAFE_RED: missing tapered CupPaperSeam presentation geometry")
		else:
			var seam_mesh := seam.mesh as ArrayMesh
			if seam_mesh.get_surface_count() != 1:
				failures.append("CAFE_RED: CupPaperSeam should be one simple presentation surface")
			elif seam_mesh.get_aabb().size.y < 0.75:
				failures.append("CAFE_RED: CupPaperSeam must read as a real vertical paper seam, not a tiny decal")

		var base_fold := presentation.get_node_or_null("CupBaseFold") as MeshInstance3D
		if base_fold == null or not (base_fold.mesh is CylinderMesh) or base_fold.material_override == null:
			failures.append("CAFE_RED: missing CupBaseFold paper compression detail")
		else:
			var fold_mesh := base_fold.mesh as CylinderMesh
			if fold_mesh.height > 0.08 or fold_mesh.height < 0.015:
				failures.append("CAFE_RED: CupBaseFold must stay a subtle structural band")

		var lip_shadow := presentation.get_node_or_null("CupLipShadow") as MeshInstance3D
		if lip_shadow == null or not (lip_shadow.mesh is CylinderMesh) or lip_shadow.material_override == null:
			failures.append("CAFE_RED: missing CupLipShadow under-lid paper depth cue")
		elif not (lip_shadow.material_override is StandardMaterial3D):
			failures.append("CAFE_RED: CupLipShadow must use a controllable semantic material")

		var cup := scene.get_node_or_null("Cup") as MeshInstance3D
		if cup == null:
			failures.append("CAFE_RED: missing production Cup for palette-sync contract")
		elif seam != null and base_fold != null and lip_shadow != null:
			var before_seam := (seam.material_override as StandardMaterial3D).albedo_color if seam.material_override is StandardMaterial3D else Color.BLACK
			var probe_material := StandardMaterial3D.new()
			probe_material.albedo_color = Color(0.62, 0.79, 0.76, 1.0)
			probe_material.roughness = 0.94
			cup.material_override = probe_material
			await process_frame
			var after_seam := (seam.material_override as StandardMaterial3D).albedo_color if seam.material_override is StandardMaterial3D else Color.BLACK
			var after_fold := (base_fold.material_override as StandardMaterial3D).albedo_color if base_fold.material_override is StandardMaterial3D else Color.BLACK
			if before_seam.is_equal_approx(after_seam):
				failures.append("CAFE_RED: cup paper detail palette must react when production Cup color changes")
			if after_seam.r >= probe_material.albedo_color.r or after_fold.r >= probe_material.albedo_color.r:
				failures.append("CAFE_RED: seam/base paper details should remain a subtle darker structural variation of the Cup palette")

	var label_print := scene.get_node_or_null("LabelPrint") as SubViewport
	if label_print == null:
		failures.append("CAFE_RED: missing LabelPrint")
	else:
		var print_aspect := float(label_print.size.x)/maxf(float(label_print.size.y),1.0)
		if print_aspect > 1.35:
			failures.append("CAFE_RED: Café LabelPrint must use a near-square receipt layout, aspect %.2f" % print_aspect)
		var print_root := label_print.get_node_or_null("PrintRoot") as Control
		if print_root == null:
			failures.append("CAFE_RED: missing receipt PrintRoot")
		else:
			var order_label := print_root.get_node_or_null("OrderLabel") as Label
			var drink_label := print_root.get_node_or_null("DrinkLabel") as Label
			var note := print_root.get_node_or_null("Note") as Label
			if order_label == null or not order_label.text.contains("COCOA CLOUD"):
				failures.append("CAFE_RED: Café receipt needs COCOA CLOUD as the hero printed identity")
			if drink_label == null or not drink_label.text.contains("MOCHA LATTE"):
				failures.append("CAFE_RED: Café receipt needs a smaller drink-detail line beneath the hero name")
			if note == null or not note.text.contains("OAT"):
				failures.append("CAFE_RED: Café receipt needs tactile order-detail copy rather than generic PICKUP")

	var peel_label := scene.get_node_or_null("PeelLabel") as LabelVisual
	if peel_label == null:
		failures.append("CAFE_RED: missing PeelLabel for receipt readability contract")
	elif not peel_label.has_method("get_front_fill") or not peel_label.has_method("get_front_material"):
		failures.append("CAFE_READABILITY_RED: LabelVisual must expose bounded front-fill material state")
	else:
		var front_fill := float(peel_label.call("get_front_fill"))
		if front_fill < 0.20 or front_fill > 0.65:
			failures.append("CAFE_READABILITY_RED: Café receipt front_fill must stay in 0.20..0.65, got %.3f" % front_fill)
		var front_material = peel_label.call("get_front_material")
		if not (front_material is StandardMaterial3D):
			failures.append("CAFE_READABILITY_RED: Café receipt front material must remain StandardMaterial3D")
		else:
			var paper := front_material as StandardMaterial3D
			if not paper.emission_enabled:
				failures.append("CAFE_READABILITY_RED: pale thermal paper needs bounded emission bounce")
			if paper.emission_texture == null or paper.albedo_texture == null or paper.emission_texture != paper.albedo_texture:
				failures.append("CAFE_READABILITY_RED: receipt print texture must mask both albedo and emission so dark ink stays dark")
			if paper.emission_energy_multiplier < 0.20 or paper.emission_energy_multiplier > 0.65:
				failures.append("CAFE_READABILITY_RED: receipt emission energy must remain bounded, got %.3f" % paper.emission_energy_multiplier)

	var key := scene.get_node_or_null("KeyLight") as DirectionalLight3D
	if key == null:
		failures.append("CAFE_RED: missing KeyLight")
	elif key.shadow_enabled:
		failures.append("CAFE_RED: hard directional shadows should be disabled in calm close-up presentation")

	if failures.is_empty():
		print("PASS: cafe backdrop, soft grounding, paper-cup structure, receipt layout and bounded paper readability")
		scene.queue_free()
		await process_frame
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
