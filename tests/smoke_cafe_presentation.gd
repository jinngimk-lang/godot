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
			if not (backdrop.material_override is StandardMaterial3D):
				failures.append("CAFE_RED: backdrop needs controllable warm material")
			else:
				var wall_color := (backdrop.material_override as StandardMaterial3D).albedo_color
				if _perceived_value(wall_color) < 0.24:
					failures.append("REFERENCE_RED: cafe wall is still too dark/technical-demo; value=%.3f" % _perceived_value(wall_color))

		var world := presentation.get_node_or_null("WorldEnvironment") as WorldEnvironment
		if world == null or world.environment == null:
			failures.append("CAFE_RED: missing WorldEnvironment")
		else:
			if _perceived_value(world.environment.background_color) < 0.16:
				failures.append("REFERENCE_RED: environment background is too crushed for the warm reference look")
			if world.environment.ambient_light_energy < 0.34:
				failures.append("REFERENCE_RED: foreground fill is too low to preserve hand/cup material detail")

		for node_name in ["WindowGlow", "CafeCounter", "BackShelf", "PropMug", "PropJar"]:
			var prop := presentation.get_node_or_null(node_name) as Node3D
			if prop == null:
				failures.append("REFERENCE_RED: missing layered cafe background cue %s" % node_name)
			elif prop.position.z > -1.0:
				failures.append("CAFE_RED: background cue %s is too close to gameplay space" % node_name)

		# The first real V7 frame still read as hard primitive geometry. In the
		# Compatibility renderer the owner-reference depth look is approximated
		# with soft alpha sprites, not sharp boxes/cylinders crossing the action.
		for node_name in ["WindowGlow", "BackShelf", "PropMug", "PropJar"]:
			var soft_cue := presentation.get_node_or_null(node_name) as Sprite3D
			if soft_cue == null or soft_cue.texture == null:
				failures.append("REFERENCE_RED: %s must be a soft textured depth cue, not a hard primitive silhouette" % node_name)
		var shelf := presentation.get_node_or_null("BackShelf") as Node3D
		if shelf != null and absf(shelf.position.x) < 0.85:
			failures.append("REFERENCE_RED: background shelf must stay out of the central cup action column")
		var haze := presentation.get_node_or_null("CafeHaze") as Sprite3D
		if haze == null or haze.texture == null:
			failures.append("REFERENCE_RED: missing broad CafeHaze layer for low-frequency compatibility depth")

		for node_name in ["BokehWarmLeft", "BokehWarmRight"]:
			var bokeh := presentation.get_node_or_null(node_name) as Sprite3D
			if bokeh == null or bokeh.texture == null:
				failures.append("REFERENCE_RED: missing soft bokeh/depth cue %s" % node_name)

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

	var table := scene.get_node_or_null("Table") as MeshInstance3D
	if table == null or not (table.material_override is StandardMaterial3D):
		failures.append("REFERENCE_RED: missing controllable tabletop material")
	else:
		var table_color := (table.material_override as StandardMaterial3D).albedo_color
		if _perceived_value(table_color) < 0.30:
			failures.append("REFERENCE_RED: tabletop is too dark; target is warm light wood/stone, value=%.3f" % _perceived_value(table_color))

	var key := scene.get_node_or_null("KeyLight") as DirectionalLight3D
	var fill := scene.get_node_or_null("FillLight") as OmniLight3D
	if key == null:
		failures.append("CAFE_RED: missing KeyLight")
	else:
		if key.shadow_enabled:
			failures.append("CAFE_RED: hard directional shadows should be disabled in calm close-up presentation")
		if key.light_energy < 0.68 or key.light_energy > 1.15:
			failures.append("REFERENCE_RED: warm key should preserve readable close-up material range; energy=%.3f" % key.light_energy)
	if fill == null or fill.light_energy < 0.65:
		failures.append("REFERENCE_RED: soft fill must keep hand/cup shadows open")

	if failures.is_empty():
		print("PASS: warm layered cafe reference presentation with soft compatibility depth cues")
		scene.queue_free()
		await process_frame
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _perceived_value(color: Color) -> float:
	return color.r * 0.2126 + color.g * 0.7152 + color.b * 0.0722
