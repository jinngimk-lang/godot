extends SceneTree

func _init() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var packed := load("res://scenes/peel_lab/peel_lab.tscn") as PackedScene
	if packed == null:
		push_error("CAPTURE: scene load failed")
		quit(1)
		return
	var scene := packed.instantiate()
	root.add_child(scene)
	for _frame in range(24):
		await process_frame
	var presentation := scene.get_node_or_null("CafePresentation") as Node3D
	if presentation == null:
		push_error("CAPTURE: CafePresentation missing")
		quit(1)
		return
	for detail_name in ["CupPaperSeam", "CupBaseFold", "CupLipShadow"]:
		var detail := presentation.get_node_or_null(detail_name) as MeshInstance3D
		if detail == null:
			push_error("CAPTURE: missing %s" % detail_name)
			quit(1)
			return
		var color := Color.BLACK
		if detail.material_override is StandardMaterial3D:
			color = (detail.material_override as StandardMaterial3D).albedo_color
		print("PAPER_CUP_DIAG %s global_pos=%s aabb=%s color=%s" % [detail_name, str(detail.global_position), str(detail.mesh.get_aabb().size if detail.mesh != null else Vector3.ZERO), str(color)])
	var camera := scene.get_node_or_null("Camera") as Camera3D
	var right_hand := scene.get_node_or_null("RightHand") as Node3D
	if camera != null and right_hand != null:
		var pinch := right_hand.call("get_pinch_world_position") as Vector3
		print("PAPER_CUP_PINCH screen=%s" % str(camera.unproject_position(pinch)))
	var label := scene.get_node_or_null("PeelLabel") as LabelVisual
	if label != null:
		print("PAPER_CUP_LABEL center_radius=%.6f" % label.get_center_cup_radius())
	var image := root.get_texture().get_image()
	var output_dir := OS.get_environment("GITHUB_WORKSPACE").path_join("artifacts")
	DirAccess.make_dir_recursive_absolute(output_dir)
	var path := output_dir.path_join("peel_scene.png")
	var err := image.save_png(path)
	if err != OK:
		push_error("CAPTURE: save failed")
		quit(1)
		return
	print("CAPTURE_OK: %s" % path)
	scene.queue_free()
	await process_frame
	quit(0)
