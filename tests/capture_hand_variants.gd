extends SceneTree

const VARIANTS := [
	{
		"name": "support_a",
		"left_pos": Vector3(0.52, 0.20, 0.28),
		"left_rot": Vector3(8, 34, 54)
	},
	{
		"name": "support_b",
		"left_pos": Vector3(0.58, 0.10, 0.22),
		"left_rot": Vector3(0, 45, 65)
	},
	{
		"name": "support_c",
		"left_pos": Vector3(0.48, 0.28, 0.38),
		"left_rot": Vector3(18, 22, 60)
	},
	{
		"name": "support_d",
		"left_pos": Vector3(0.58, 0.24, 0.38),
		"left_rot": Vector3(14, 42, 45)
	},
	{
		"name": "support_e",
		"left_pos": Vector3(0.50, 0.08, 0.36),
		"left_rot": Vector3(-4, 35, 70)
	},
	{
		"name": "support_f",
		"left_pos": Vector3(0.62, 0.28, 0.24),
		"left_rot": Vector3(20, 50, 55)
	}
]

const RIGHT_ROT := Vector3(18, -22, -8)

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

		# Freeze the scene and vary presentation only. Keep the right-hand pinch target exact.
		scene.process_mode = Node.PROCESS_MODE_DISABLED
		var grip_target := right.get_pinch_world_position()
		left.position = variant["left_pos"] as Vector3
		left.rotation_degrees = variant["left_rot"] as Vector3
		right.rotation_degrees = RIGHT_ROT
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
