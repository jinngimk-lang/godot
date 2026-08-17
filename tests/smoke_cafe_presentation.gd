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

		# Locked cafe_v1 reads as a slim tapered paper cup with a clearly molded
		# black plastic lid. Keep these as low-frequency presentation contracts,
		# not camera-dependent pixel heuristics.
		var cup := scene.get_node_or_null("Cup") as MeshInstance3D
		var lid := scene.get_node_or_null("Lid") as MeshInstance3D
		if cup == null or not (cup.mesh is CylinderMesh):
			failures.append("CAFE_RED: missing production tapered Cup")
		else:
			var cup_mesh := cup.mesh as CylinderMesh
			var taper_ratio := cup_mesh.bottom_radius / maxf(cup_mesh.top_radius,0.001)
			var width_height_ratio := (cup_mesh.top_radius * 2.0) / maxf(cup_mesh.height,0.001)
			if cup_mesh.top_radius > 0.495:
				failures.append("CAFE_RED: cafe hero cup is too wide at the mouth for the locked reference silhouette")
			if taper_ratio > 0.80:
				failures.append("CAFE_RED: cafe hero cup is too cylindrical; bottom/top ratio=%.4f" % taper_ratio)
			if width_height_ratio > 0.71:
				failures.append("CAFE_RED: cafe hero cup is too squat/wide; diameter/height ratio=%.4f" % width_height_ratio)
		if lid == null or not (lid.mesh is CylinderMesh):
			failures.append("CAFE_RED: missing production black Lid")
		else:
			var outer_ridge := presentation.get_node_or_null("LidOuterRidge") as MeshInstance3D
			if outer_ridge == null or not (outer_ridge.mesh is CylinderMesh):
				failures.append("CAFE_RED: molded cafe lid needs a distinct outer ridge silhouette")
			else:
				var lid_mesh := lid.mesh as CylinderMesh
				var ridge_mesh := outer_ridge.mesh as CylinderMesh
				if ridge_mesh.top_radius <= lid_mesh.top_radius + 0.008:
					failures.append("CAFE_RED: lid outer ridge must visibly flare beyond the base lid")
				var expected_y := lid.position.y + lid_mesh.height * 0.5
				if absf(outer_ridge.position.y - expected_y) > 0.045:
					failures.append("CAFE_RED: molded lid ridge must sit on the actual production lid, not float above it")
				var product := scene.get_node_or_null("ProductPresentation") as Node3D
				var paper_lip := product.get_node_or_null("CupPaperDetails/PaperLip") as MeshInstance3D if product != null else null
				if paper_lip == null or not (paper_lip.mesh is CylinderMesh):
					failures.append("CAFE_RED: missing product PaperLip structural cue")
				else:
					var paper_lip_mesh := paper_lip.mesh as CylinderMesh
					if paper_lip_mesh.top_radius > (cup.mesh as CylinderMesh).top_radius + 0.020:
						failures.append("CAFE_RED: paper lip overhang is too wide and masks the black molded lid")
					if ridge_mesh.top_radius < paper_lip_mesh.top_radius + 0.020:
						failures.append("CAFE_RED: black lid outer ridge must remain visibly outside the paper lip silhouette")

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

		# Presentation colors must follow the current tactile cup palette instead of
		# remaining hard-coded to the first warm-paper variant.
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

	var key := scene.get_node_or_null("KeyLight") as DirectionalLight3D
	if key == null:
		failures.append("CAFE_RED: missing KeyLight")
	elif key.shadow_enabled:
		failures.append("CAFE_RED: hard directional shadows should be disabled in calm close-up presentation")

	if failures.is_empty():
		print("PASS: cafe backdrop, slim tapered cup, molded lid, soft grounding, paper structure and palette sync")
		scene.queue_free()
		await process_frame
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
