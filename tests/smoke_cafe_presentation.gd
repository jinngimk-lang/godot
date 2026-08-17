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

		var lid_sip_tab := presentation.get_node_or_null("LidSipTab") as MeshInstance3D
		if lid_sip_tab == null or not (lid_sip_tab.mesh is CylinderMesh) or lid_sip_tab.material_override == null:
			failures.append("CAFE_RED: black café lid needs a molded LidSipTab instead of reading as stacked flat discs")
		else:
			var sip_mesh := lid_sip_tab.mesh as CylinderMesh
			if sip_mesh.top_radius < 0.055 or sip_mesh.top_radius > 0.095 or sip_mesh.height < 0.008 or sip_mesh.height > 0.028:
				failures.append("CAFE_RED: LidSipTab must stay a subtle molded drinking feature")
			if lid_sip_tab.position.z < 0.12:
				failures.append("CAFE_RED: LidSipTab must sit toward the camera-facing drinking edge")

		var lid_vent := presentation.get_node_or_null("LidVentDimple") as MeshInstance3D
		if lid_vent == null or not (lid_vent.mesh is CylinderMesh) or lid_vent.material_override == null:
			failures.append("CAFE_RED: black café lid needs a small LidVentDimple for molded depth")
		else:
			var vent_mesh := lid_vent.mesh as CylinderMesh
			if vent_mesh.top_radius > 0.035 or vent_mesh.height > 0.018:
				failures.append("CAFE_RED: LidVentDimple must remain quiet secondary lid detail")

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

	var key := scene.get_node_or_null("KeyLight") as DirectionalLight3D
	if key == null:
		failures.append("CAFE_RED: missing KeyLight")
	elif key.shadow_enabled:
		failures.append("CAFE_RED: hard directional shadows should be disabled in calm close-up presentation")

	if failures.is_empty():
		print("PASS: cafe backdrop, molded lid, soft grounding, paper-cup structure and receipt print layout")
		scene.queue_free()
		await process_frame
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)