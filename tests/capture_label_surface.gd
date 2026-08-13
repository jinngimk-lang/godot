extends SceneTree

func _init() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var packed := load("res://scenes/peel_lab/peel_lab.tscn") as PackedScene
	if packed == null:
		push_error("CAPTURE_LABEL: peel_lab failed to load")
		quit(1)
		return
	var scene := packed.instantiate()
	root.add_child(scene)
	for _frame in range(24):
		await process_frame

	var cup := scene.get_node_or_null("Cup") as MeshInstance3D
	var label := scene.get_node_or_null("PeelLabel") as LabelVisual
	if cup == null or label == null or not (cup.mesh is CylinderMesh) or label.mesh == null:
		push_error("CAPTURE_LABEL: runtime cup/label geometry missing")
		quit(1)
		return
	var cup_mesh := cup.mesh as CylinderMesh
	var arrays := label.mesh.surface_get_arrays(0)
	var vertices := arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
	var max_error := 0.0
	for vertex in vertices:
		var cup_local := cup.to_local(label.to_global(vertex))
		var t := clampf((cup_local.y + cup_mesh.height * 0.5) / cup_mesh.height, 0.0, 1.0)
		var expected := lerpf(cup_mesh.bottom_radius, cup_mesh.top_radius, t) + label.surface_offset
		var actual := Vector2(cup_local.x, cup_local.z).length()
		max_error = maxf(max_error, absf(actual - expected))
	print("LABEL_SURFACE_DIAG max_radial_error=%.6f vertices=%d center_radius=%.6f" % [max_error, vertices.size(), label.get_center_cup_radius()])

	var image := root.get_texture().get_image()
	if image == null or image.is_empty():
		push_error("CAPTURE_LABEL: viewport image is empty")
		quit(1)
		return
	var workspace := OS.get_environment("GITHUB_WORKSPACE")
	var output_dir := workspace.path_join("artifacts")
	DirAccess.make_dir_recursive_absolute(output_dir)
	var output_path := output_dir.path_join("frustum_label.png")
	var error := image.save_png(output_path)
	if error != OK:
		push_error("CAPTURE_LABEL: failed to save PNG: %s" % error_string(error))
		quit(1)
		return
	print("CAPTURE_LABEL_OK: %s %dx%d" % [output_path, image.get_width(), image.get_height()])
	scene.queue_free()
	await process_frame
	quit(0)
