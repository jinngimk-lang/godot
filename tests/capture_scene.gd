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
	for hand_name in ["LeftHand", "RightHand"]:
		var hand := scene.get_node_or_null(hand_name) as Node3D
		var camera := scene.get_node_or_null("Camera") as Camera3D
		if hand != null and camera != null:
			var pinch := hand.call("get_pinch_world_position") as Vector3
			var forearm := hand.get_node_or_null("ForearmSleeve") as MeshInstance3D
			var exit_marker := hand.get_node_or_null("ForearmExit") as Node3D
			var vertex_count := 0
			var mesh_extent := Vector3.ZERO
			if forearm != null and forearm.mesh is ArrayMesh:
				var mesh := forearm.mesh as ArrayMesh
				var arrays := mesh.surface_get_arrays(0)
				vertex_count = (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
				mesh_extent = mesh.get_aabb().size
			print("COMPACT_CURVE_DIAG %s pinch=%s exit=%s exit_len=%.6f extent=%s vertices=%d" % [hand_name, str(camera.unproject_position(pinch)), str(exit_marker.position if exit_marker != null else Vector3.ZERO), (exit_marker.position.length() if exit_marker != null else 0.0), str(mesh_extent), vertex_count])
	var label := scene.get_node_or_null("PeelLabel") as LabelVisual
	if label != null:
		print("COMPACT_CURVE_LABEL center_radius=%.6f" % label.get_center_cup_radius())
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
