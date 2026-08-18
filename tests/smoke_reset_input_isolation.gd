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
	scene.process_mode = Node.PROCESS_MODE_DISABLED

	var pointer := scene.get_node_or_null("PointerAdapter") as PointerAdapter
	var controller = scene.get("_controller")
	if pointer == null or controller == null:
		push_error("RESET_INPUT_RED: missing pointer/controller contract")
		quit(1)
		return

	controller.reset()
	scene.call("_process",1.0/60.0)
	var edge_screen: Vector2 = controller.get_edge_position()
	_arm_edge_lift(scene,pointer,edge_screen)
	if String(controller.get_state_name()) != "EDGE_LIFT":
		push_error("RESET_INPUT_RED: fixture failed to arm visible corner; actual=%s" % String(controller.get_state_name()))
		quit(1)
		return

	var reset_key := InputEventKey.new()
	reset_key.pressed = true
	reset_key.keycode = KEY_R
	scene.call("_unhandled_key_input",reset_key)
	controller = scene.get("_controller")
	if controller == null or String(controller.get_state_name()) != "IDLE":
		push_error("RESET_INPUT_RED: R must leave a fresh IDLE controller")
		quit(1)
		return
	scene.call("_process",1.0/60.0)
	edge_screen = controller.get_edge_position()
	scene.call("_process",1.0/60.0)
	var after_reset := String(controller.get_state_name())
	if after_reset in ["EDGE_LIFT","PINCHED","PEELING","COMPLETE"]:
		push_error("RESET_INPUT_RED: held pointer leaked across R reset and re-grabbed corner: %s" % after_reset)
		quit(1)
		return

	_send_mouse(pointer,false,edge_screen)
	scene.call("_process",1.0/60.0)
	_send_mouse(pointer,true,edge_screen)
	scene.call("_process",1.0/60.0)
	if String(controller.get_state_name()) != "EDGE_LIFT":
		push_error("RESET_INPUT_RED: fresh post-reset corner press did not re-arm EDGE_LIFT; actual=%s" % String(controller.get_state_name()))
		quit(1)
		return

	print("PASS: R reset quarantines visible-corner pointer state until a fresh press")
	scene.queue_free()
	await process_frame
	quit(0)

func _arm_edge_lift(scene: Node, pointer: PointerAdapter, edge_screen: Vector2) -> void:
	_send_mouse(pointer,false,edge_screen)
	scene.call("_process",1.0/60.0)
	_send_mouse(pointer,true,edge_screen)
	scene.call("_process",1.0/60.0)

func _send_mouse(pointer: PointerAdapter, pressed: bool, position: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = position
	pointer._unhandled_input(event)
