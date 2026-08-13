extends SceneTree

const VARIANTS := [
	{
		"name": "baseline",
		"left_pos": Vector3(-0.60, 0.30, 0.34),
		"left_rot": Vector3(18, -28, -48),
		"right_rot": Vector3(-8, 8, 15)
	},
	{
		"name": "spread_a",
		"left_pos": Vector3(0.68, 0.22, 0.62),
		"left_rot": Vector3(12, 28, 48),
		"right_rot": Vector3(-18, -18, 32)
	},
	{
		"name": "spread_b",
		"left_pos": Vector3(0.74, 0.10, 0.72),
		"left_rot": Vector3(4, 38, 58),
		"right_rot": Vector3(-28, -12, 36)
	},
	{
		"name": "spread_c",
		"left_pos": Vector3(0.66, 0.34, 0.72),
		"left_rot": Vector3(18, 18, 58),
		"right_rot": Vector3(8, -28, 40)
	},
	{
		"name": "right_open_a",
		"left_pos": Vector3(0.72, 0.22, 0.70),
		"left_rot": Vector3(10, 30, 52),
		"right_rot": Vector3(-18, -38, 58)
	},
	{
		"name": "right_open_b",
		"left_pos": Vector3(0.70, 0.18, 0.66),
		"left_rot": Vector3(8, 34, 54),
		"right_rot": Vector3(18, -22, -8)
	}
]

func _init() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var packed := load("res://scenes/peel_lab/peel_lab.tscn") as PackedScene
	if packed == null:
		push_error("CAPTURE_VARIANTS: peel_lab scene failed to load")
		quit(1)
		return

	var workspace := OS.get_environment("GITHUB_WORKSPACE")
	var output_dir := workspace.path_join("artifacts") if not workspace.is_empty() else ProjectSettings.globalize_path("user://visual-artifacts")
	var mkdir_error := DirAccess.make_dir_recursive_absolute(output_dir)
	if mkdir_error != OK:
		push_error("CAPTURE_VARIANTS: cannot create output directory: %s" % error_string(mkdir_error))
		quit(1)
		return

	for variant in VARIANTS:
		var scene := packed.instantiate()
		root.add_child(scene)
		for _frame in range(18):
			await process_frame

		var left := scene.get_node_or_null("LeftHand") as HandVisual
		var right := scene.get_node_or_null("RightHand") as HandVisual
		if left == null or right == null:
			push_error("CAPTURE_VARIANTS: runtime hands missing")
			quit(1)
			return

		# Freeze the main scene so the candidate is stable while we adjust only hand presentation.
		scene.process_mode = Node.PROCESS_MODE_DISABLED
		var grip_target := right.get_pinch_world_position()
		left.position = variant["left_pos"] as Vector3
		left.rotation_degrees = variant["left_rot"] as Vector3
		right.rotation_degrees = variant["right_rot"] as Vector3
		right.set_grip_target(grip_target)
		for _step in range(8):
			right.tick(0.1)

		for _frame in range(3):
			await process_frame

		var texture := root.get_texture()
		var image := texture.get_image() if texture != null else null
		if image == null or image.is_empty():
			push_error("CAPTURE_VARIANTS: viewport image is empty")
			quit(1)
			return
		var output_path := output_dir.path_join("hand_%s.png" % String(variant["name"]))
		var save_error := image.save_png(output_path)
		if save_error != OK:
			push_error("CAPTURE_VARIANTS: failed to save %s" % output_path)
			quit(1)
			return
		print("HAND_VARIANT %s left_pos=%s left_rot=%s right_root=%s right_rot=%s pinch=%s" % [
			String(variant["name"]),
			str(left.position),
			str(left.rotation_degrees),
			str(right.position),
			str(right.rotation_degrees),
			str(right.get_pinch_world_position())
		])
		scene.queue_free()
		await process_frame

	print("CAPTURE_VARIANTS_OK: %d candidates" % VARIANTS.size())
	quit(0)
