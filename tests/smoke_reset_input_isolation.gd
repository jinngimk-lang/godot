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
	var label := scene.get_node_or_null("PeelLabel") as LabelVisual
	var camera := scene.get_node_or_null("Camera") as Camera3D
	var controller = scene.get("_controller")
	if pointer == null or label == null or camera == null or controller == null:
		push_error("RESET_INPUT_RED: missing pointer/label/camera/controller contract")
		quit(1)
		return

	var edge_screen := _edge_screen(label,camera,controller)
	_arm_edge_lift(scene,pointer,controller,edge_screen)
	if String(controller.get_state_name()) != "EDGE_LIFT":
		push_error("RESET_INPUT_RED: fixture failed to arm EDGE_LIFT; actual=%s" % String(controller.get_state_name()))
		quit(1)
		return

	# R is the approved reset key. A held primary button from before reset must be
	# quarantined rather than instantly re-grabbing the fresh label.
	var reset_key := InputEventKey.new()
	reset_key.pressed = true
	reset_key.keycode = KEY_R
	scene.call("_unhandled_key_input",reset_key)
	controller = scene.get("_controller")
	if controller == null or String(controller.get_state_name()) != "IDLE":
		push_error("RESET_INPUT_RED: R must leave a fresh IDLE controller")
		quit(1)
		return
	edge_screen = _edge_screen(label,camera,controller)
	scene.call("_process",1.0/60.0)
	scene.call("_process",1.0/60.0)
	var after_reset := String(controller.get_state_name())
	if after_reset in ["EDGE_LIFT","PINCHED","PEELING","COMPLETE"]:
		push_error("RESET_INPUT_RED: held pointer leaked across R reset and re-grabbed label: %s" % after_reset)
		quit(1)
		return

	# Release then a genuinely fresh press must re-arm the same live label.
	_send_mouse(pointer,false,edge_screen)
	scene.call("_process",1.0/60.0)
	_send_mouse(pointer,true,edge_screen)
	scene.call("_process",1.0/60.0)
	if String(controller.get_state_name()) != "EDGE_LIFT":
		push_error("RESET_INPUT_RED: fresh post-reset press did not re-arm EDGE_LIFT; actual=%s" % String(controller.get_state_name()))
		quit(1)
		return

	print("PASS: R reset quarantines held pointer state until release and a fresh press")
	scene.queue_free()
	await process_frame
	quit(0)

func _edge_screen(label: LabelVisual, camera: Camera3D, controller) -> Vector2:
	controller.reset()
	var edge_world := label.to_global(label.get_front_position(controller.get_progress()))
	return camera.unproject_position(edge_world)

func _arm_edge_lift(scene: Node, pointer: PointerAdapter, _controller, edge_screen: Vector2) -> void:
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
