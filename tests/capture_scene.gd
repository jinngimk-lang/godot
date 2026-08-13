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
			if forearm != null and forearm.mesh is ArrayMesh:
				var arrays := (forearm.mesh as ArrayMesh).surface_get_arrays(0)
				vertex_count = (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
			print("CURVE_DIAG %s pinch=%s exit=%s vertices=%d" % [hand_name, str(camera.unproject_position(pinch)), str(exit_marker.position if exit_marker != null else Vector3.ZERO), vertex_count])
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
