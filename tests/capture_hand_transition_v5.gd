extends SceneTree

const OUT_DIR := "artifacts/hand-transition-v5"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://%s" % OUT_DIR))
	var packed := load("res://scenes/peel_lab/peel_lab.tscn") as PackedScene
	if packed == null:
		push_error("HAND_PRIMARY: failed to load peel lab")
		quit(1)
		return
	var scene := packed.instantiate()
	root.add_child(scene)
	for _i in range(8):
		await process_frame
	var hand := scene.get_node("RightHand") as HandVisual
	var label := scene.get_node("PeelLabel") as LabelVisual
	if hand == null or label == null or not hand.is_using_authored_asset():
		push_error("HAND_PRIMARY: authored dynamic hand/label missing")
		quit(1)
		return
	var relaxed_pose := String(hand.get("_last_authored_pose"))
	await _capture("01_relaxed.png")

	# Freeze PeelLab coordinator so this verifier can hold one controlled active
	# pose instead of the normal idle loop immediately restoring relaxed pinch.
	scene.set_process(false)
	var target := label.to_global(label.get_front_position(0.0))
	hand.set_pinch_amount(1.0)
	hand.set_grip_target(target)
	for _i in range(10):
		hand.tick(0.1)
	var active_pose := String(hand.get("_last_authored_pose"))
	var pinch := hand.get_pinch_world_position()
	var error := pinch.distance_to(target)
	await _capture("02_active_pinch.png")

	if relaxed_pose != "Pinch Up":
		push_error("HAND_PRIMARY: relaxed pose=%s" % relaxed_pose)
		quit(1)
		return
	if active_pose != "Pinch Tight":
		push_error("HAND_PRIMARY: active pose=%s" % active_pose)
		quit(1)
		return
	if error > 0.025:
		push_error("HAND_PRIMARY: active pose pinch anchor drifted %.6f m from same label-edge target" % error)
		quit(1)
		return
	print("HAND_PRIMARY: relaxed=%s active=%s target=%s pinch=%s error=%.6f" % [relaxed_pose, active_pose, str(target), str(pinch), error])
	scene.queue_free()
	await process_frame
	quit(0)

func _capture(filename: String) -> void:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var path := "res://%s/%s" % [OUT_DIR, filename]
	var err := image.save_png(path)
	if err != OK:
		push_error("HAND_PRIMARY: failed to save %s" % path)
		quit(1)
		return
