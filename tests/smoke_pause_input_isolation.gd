extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load("res://scenes/peel_lab/peel_lab.tscn") as PackedScene
	if packed == null:
		push_error("PAUSE_INPUT_RED: peel lab scene failed to load")
		quit(1)
		return
	var scene := packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	scene.process_mode = Node.PROCESS_MODE_DISABLED

	var controller = scene.get("_controller")
	var pointer := scene.get_node_or_null("PointerAdapter") as PointerAdapter
	var label := scene.get_node_or_null("PeelLabel") as LabelVisual
	var camera := scene.get_node_or_null("Camera") as Camera3D
	if controller == null or pointer == null or label == null or camera == null:
		push_error("PAUSE_INPUT_RED: missing controller/pointer/label/camera contract")
		quit(1)
		return

	controller.reset()
	var edge_world := label.get_front_position(controller.get_progress())
	var edge_screen := camera.unproject_position(edge_world)

	var escape := InputEventKey.new()
	escape.pressed = true
	escape.keycode = KEY_ESCAPE
	scene.call("_unhandled_key_input", escape)
	if not bool(scene.get("_paused")):
		push_error("PAUSE_INPUT_RED: fixture failed to enter pause")
		quit(1)
		return

	# A primary-button press received while paused must never arm gameplay.
	_send_mouse(pointer, true, edge_screen)
	scene.call("_process", 1.0 / 60.0)
	scene.call("_process", 1.0 / 60.0)

	scene.call("_unhandled_key_input", escape)
	if bool(scene.get("_paused")):
		push_error("PAUSE_INPUT_RED: fixture failed to resume")
		quit(1)
		return

	# No release or new press occurs here. A held pause-time press must remain
	# quarantined after resume instead of becoming a fresh edge grab.
	scene.call("_process", 1.0 / 60.0)
	scene.call("_process", 1.0 / 60.0)
	var after_resume := String(controller.get_state_name())
	if after_resume in ["EDGE_LIFT", "PINCHED", "PEELING", "COMPLETE"]:
		push_error("PAUSE_INPUT_RED: paused pointer press leaked across resume and entered gameplay state: %s" % after_resume)
		quit(1)
		return

	# Release re-arms input; a genuinely fresh post-resume press must still work.
	_send_mouse(pointer, false, edge_screen)
	scene.call("_process", 1.0 / 60.0)
	_send_mouse(pointer, true, edge_screen)
	scene.call("_process", 1.0 / 60.0)
	if String(controller.get_state_name()) != "EDGE_LIFT":
		push_error("PAUSE_INPUT_RED: fresh post-resume press did not re-arm edge lift; actual=%s" % String(controller.get_state_name()))
		quit(1)
		return

	print("PASS: pause quarantines pointer input until release and a fresh post-resume press")
	scene.queue_free()
	await process_frame
	quit(0)

func _send_mouse(pointer: PointerAdapter, pressed: bool, position: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = position
	pointer._unhandled_input(event)
