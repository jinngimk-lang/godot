extends SceneTree

const OUTPUT_DIR := "artifacts/hand-pose-candidates"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load("res://scenes/peel_lab/peel_lab.tscn") as PackedScene
	if packed == null:
		push_error("HAND_POSE_CAPTURE: scene failed to load")
		quit(1)
		return
	var scene := packed.instantiate()
	root.add_child(scene)
	for _i in range(24):
		await process_frame

	var left := scene.get_node_or_null("LeftHand")
	var right := scene.get_node_or_null("RightHand")
	if left == null or right == null:
		push_error("HAND_POSE_CAPTURE: hands missing")
		quit(1)
		return
	var left_player := _find_animation_player(left)
	var right_player := _find_animation_player(right)
	if left_player == null or right_player == null:
		push_error("HAND_POSE_CAPTURE: animation player missing")
		quit(1)
		return

	var workspace := OS.get_environment("GITHUB_WORKSPACE")
	var output_dir := workspace.path_join(OUTPUT_DIR) if not workspace.is_empty() else ProjectSettings.globalize_path("user://hand-pose-candidates")
	var err := DirAccess.make_dir_recursive_absolute(output_dir)
	if err != OK:
		push_error("HAND_POSE_CAPTURE: cannot create output dir")
		quit(1)
		return

	await _capture(scene, left_player, right_player, "01_current_cup_default.png", "Cup", "Default pose")
	await _capture(scene, left_player, right_player, "02_cup_pinch_up.png", "Cup", "Pinch Up")
	await _capture(scene, left_player, right_player, "03_cup_pinch_tight.png", "Cup", "Pinch Tight")
	await _capture(scene, left_player, right_player, "04_hold_pinch_up.png", "Hold", "Pinch Up")
	await _capture(scene, left_player, right_player, "05_default_pinch_up.png", "Default pose", "Pinch Up")

	print("HAND_POSE_CAPTURE_OK dir=%s" % output_dir)
	quit(0)

func _capture(scene: Node, left_player: AnimationPlayer, right_player: AnimationPlayer, filename: String, left_pose: String, right_pose: String) -> void:
	_apply_pose(left_player, left_pose)
	_apply_pose(right_player, right_pose)
	for _i in range(3):
		await process_frame
	var image := root.get_texture().get_image()
	if image == null or image.is_empty():
		push_error("HAND_POSE_CAPTURE: empty image for %s" % filename)
		return
	var workspace := OS.get_environment("GITHUB_WORKSPACE")
	var output_dir := workspace.path_join(OUTPUT_DIR) if not workspace.is_empty() else ProjectSettings.globalize_path("user://hand-pose-candidates")
	var path := output_dir.path_join(filename)
	var save_error := image.save_png(path)
	if save_error != OK:
		push_error("HAND_POSE_CAPTURE: save failed %s" % filename)
		return
	print("HAND_POSE_FRAME file=%s left=%s right=%s" % [filename, left_pose, right_pose])

func _apply_pose(player: AnimationPlayer, pose: String) -> void:
	if not player.has_animation(pose):
		push_error("HAND_POSE_CAPTURE: missing pose %s" % pose)
		return
	player.play(pose)
	player.seek(0.0, true)
	player.pause()

func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var found := _find_animation_player(child)
		if found != null:
			return found
	return null
