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
	_print_hand(scene, "LeftHand")
	_print_hand(scene, "RightHand")
	var image := root.get_texture().get_image()
	if image == null or image.is_empty():
		push_error("CAPTURE: viewport image is empty")
		quit(1)
		return
	var workspace := OS.get_environment("GITHUB_WORKSPACE")
	var output_dir := workspace.path_join("artifacts")
	DirAccess.make_dir_recursive_absolute(output_dir)
	var output_path := output_dir.path_join(OUTPUT_NAME)
	var save_error := image.save_png(output_path)
	if save_error != OK:
		push_error("CAPTURE: failed to save PNG")
		quit(1)
		return
	print("CAPTURE_OK: %s %dx%d" % [output_path, image.get_width(), image.get_height()])
	scene.queue_free()
	await process_frame
	quit(0)

func _print_hand(scene: Node, hand_name: String) -> void:
	var hand := scene.get_node_or_null(hand_name) as Node3D
	var camera := scene.get_node_or_null("Camera") as Camera3D
	if hand == null or camera == null:
		return
	var pinch := hand.call("get_pinch_world_position") as Vector3
	var near := hand.get_node_or_null("ForearmNear") as MeshInstance3D
	var elbow := hand.get_node_or_null("SleeveElbow") as MeshInstance3D
	var far := hand.get_node_or_null("ForearmSleeve") as MeshInstance3D
	print("FOREARM_DIAG %s pinch_screen=%s near=%s elbow=%s far=%s" % [
		hand_name,
		str(camera.unproject_position(pinch)),
		str(near.position if near != null else Vector3.ZERO),
		str(elbow.position if elbow != null else Vector3.ZERO),
		str(far.position if far != null else Vector3.ZERO)
	])
