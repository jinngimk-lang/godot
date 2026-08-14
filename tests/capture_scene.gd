extends SceneTree

const OUTPUT_NAME := "peel_scene.png"

func _init() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var packed := load("res://scenes/peel_lab/peel_lab.tscn") as PackedScene
	if packed == null:
		push_error("CAPTURE: peel_lab scene failed to load")
		quit(1)
		return
	var scene := packed.instantiate()
	root.add_child(scene)
	for _frame in range(24):
		await process_frame
	var left := scene.get_node_or_null("LeftHand")
	var right := scene.get_node_or_null("RightHand")
	if left == null or right == null:
		push_error("CAPTURE: hand missing")
		quit(1)
		return
	print("HAND_POSE_GREEN left=%s right=%s" % [String(left.get("_last_authored_pose")), String(right.get("_last_authored_pose"))])
	var texture := root.get_texture()
	if texture == null:
		push_error("CAPTURE: root viewport has no texture")
		quit(1)
		return
	var image := texture.get_image()
	if image == null or image.is_empty():
		push_error("CAPTURE: viewport image is empty")
		quit(1)
		return
	var workspace := OS.get_environment("GITHUB_WORKSPACE")
	var output_dir := workspace.path_join("artifacts") if not workspace.is_empty() else ProjectSettings.globalize_path("user://visual-artifacts")
	var mkdir_error := DirAccess.make_dir_recursive_absolute(output_dir)
	if mkdir_error != OK:
		push_error("CAPTURE: cannot create output directory: %s" % error_string(mkdir_error))
		quit(1)
		return
	var output_path := output_dir.path_join(OUTPUT_NAME)
	var save_error := image.save_png(output_path)
	if save_error != OK:
		push_error("CAPTURE: failed to save PNG: %s" % error_string(save_error))
		quit(1)
		return
	print("CAPTURE_OK: %s %dx%d" % [output_path, image.get_width(), image.get_height()])
	quit(0)
