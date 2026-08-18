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
	if controller == null or pointer == null:
		push_error("PAUSE_INPUT_RED: missing controller/pointer contract")
		quit(1)
		return

	controller.reset()
	# One dry frame lets PeelLab project the real label region; PeelController then
	# publishes the approved top-right visible corner as its first-grab edge.
	scene.call("_process",1.0/60.0)
	var edge_screen: Vector2 = controller.get_edge_position()

	var escape := InputEventKey.new()
	escape.pressed = true
	escape.keycode = KEY_ESCAPE
	scene.call("_unhandled_key_input",escape)
	if not bool(scene.get("_paused")):
		push_error("PAUSE_INPUT_RED: fixture failed to enter pause")
		quit(1)
		return

	_send_mouse(pointer,true,edge_screen)
	scene.call("_process",1.0/60.0)
	scene.call("_process",1.0/60.0)

	scene.call("_unhandled_key_input",escape)
	if bool(scene.get("_paused")):
		push_error("PAUSE_INPUT_RED: fixture failed to resume")
		quit(1)
		return

	scene.call("_process",1.0/60.0)
	scene.call("_process",1.0/60.0)
	var after_resume := String(controller.get_state_name())
	if after_resume in ["EDGE_LIFT","PINCHED","PEELING","COMPLETE"]:
		push_error("PAUSE_INPUT_RED: paused pointer press leaked across resume: %s" % after_resume)
		quit(1)
		return

	_send_mouse(pointer,false,edge_screen)
	scene.call("_process",1.0/60.0)
	_send_mouse(pointer,true,edge_screen)
	scene.call("_process",1.0/60.0)
	if String(controller.get_state_name()) != "EDGE_LIFT":
		push_error("PAUSE_INPUT_RED: fresh post-resume corner press did not re-arm edge lift; actual=%s" % String(controller.get_state_name()))
		quit(1)
		return

	print("PASS: pause quarantines visible-corner pointer input until a fresh post-resume press")
	scene.queue_free()
	await process_frame
	quit(0)

func _send_mouse(pointer: PointerAdapter, pressed: bool, position: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = position
	pointer._unhandled_input(event)
