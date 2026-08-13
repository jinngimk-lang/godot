extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load("res://scenes/peel_lab/peel_lab.tscn") as PackedScene
	if packed == null:
		push_error("RESET_INPUT_RED: peel lab scene failed to load")
		quit(1)
		return
	var scene := packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	var pointer := scene.get_node_or_null("PointerAdapter") as PointerAdapter
	var label := scene.get_node_or_null("PeelLabel") as LabelVisual
	var camera := scene.get_node_or_null("Camera") as Camera3D
	if pointer == null or label == null or camera == null:
		push_error("RESET_INPUT_RED: missing pointer/label/camera contract")
		quit(1)
		return

	var controller = scene.get("_controller")
	if controller == null:
		push_error("RESET_INPUT_RED: missing controller")
		quit(1)
		return
	controller.reset()
	var edge_world := label.get_front_position(controller.get_progress())
	var edge_screen := camera.unproject_position(edge_world)

	# Deterministically arm a real held interaction through the production scene path:
	# IDLE -> EDGE_HOVER on an unpressed edge frame, then EDGE_HOVER -> EDGE_LIFT on press.
	pointer.state.set_frame(false, edge_screen, Vector2.ZERO, Vector2.ZERO, false)
	scene.call("_process", 1.0 / 60.0)
	pointer.state.set_frame(true, edge_screen, Vector2.ZERO, Vector2.ZERO, false)
	scene.call("_process", 1.0 / 60.0)
	if String(controller.get_state_name()) != "EDGE_LIFT":
		push_error("RESET_INPUT_RED: fixture failed to arm EDGE_LIFT; actual=%s" % String(controller.get_state_name()))
		quit(1)
		return

	# Ordinary R must create a fresh label, not let the old held press immediately
	# grab that new label without a release/new press boundary.
	var reset_key := InputEventKey.new()
	reset_key.pressed = true
	reset_key.keycode = KEY_R
	scene.call("_unhandled_key_input", reset_key)
	if String(controller.get_state_name()) != "IDLE":
		push_error("RESET_INPUT_RED: R fixture expected controller reset to IDLE")
		quit(1)
		return

	# No new pointer event occurs here. The pre-reset held bit is still present if
	# reset failed to quarantine pointer state. Two frames are enough for
	# IDLE -> EDGE_HOVER -> EDGE_LIFT.
	scene.call("_process", 1.0 / 60.0)
	scene.call("_process", 1.0 / 60.0)
	var after_reset := String(controller.get_state_name())
	if after_reset in ["EDGE_LIFT", "PINCHED", "PEELING", "COMPLETE"]:
		push_error("RESET_INPUT_RED: held pointer leaked across R reset and re-grabbed fresh label: %s" % after_reset)
		quit(1)
		return

	# Re-arm, then check Shift+R. This path rebuilds the controller, so reacquire it.
	pointer.state.set_frame(false, edge_screen, Vector2.ZERO, Vector2.ZERO, false)
	scene.call("_process", 1.0 / 60.0)
	pointer.state.set_frame(true, edge_screen, Vector2.ZERO, Vector2.ZERO, false)
	scene.call("_process", 1.0 / 60.0)
	var restart := InputEventKey.new()
	restart.pressed = true
	restart.keycode = KEY_R
	restart.shift_pressed = true
	scene.call("_unhandled_key_input", restart)
	controller = scene.get("_controller")
	if controller == null or String(controller.get_state_name()) != "IDLE":
		push_error("RESET_INPUT_RED: Shift+R fixture expected a fresh IDLE controller")
		quit(1)
		return
	scene.call("_process", 1.0 / 60.0)
	scene.call("_process", 1.0 / 60.0)
	var after_restart := String(controller.get_state_name())
	if after_restart in ["EDGE_LIFT", "PINCHED", "PEELING", "COMPLETE"]:
		push_error("RESET_INPUT_RED: held pointer leaked across Shift+R restart and re-grabbed fresh label: %s" % after_restart)
		quit(1)
		return

	print("PASS: reset/restart quarantine held pointer state until a fresh interaction")
	scene.queue_free()
	await process_frame
	quit(0)
