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
	controller.set_edge_position(edge_screen)

	var escape := InputEventKey.new()
	escape.pressed = true
	escape.keycode = KEY_ESCAPE
	scene.call("_unhandled_key_input", escape)
	if not bool(scene.get("_paused")):
		push_error("PAUSE_INPUT_RED: fixture failed to enter pause")
		quit(1)
		return

	# Simulate a mouse press arriving while paused at the current peel edge.
	# PointerAdapter accepts this event shape while the scene is paused; paused
	# frames clear only transients, so the persistent `pressed` bit survives.
	pointer.state.set_frame(true, edge_screen, Vector2.ZERO, Vector2.ZERO, false)
	await process_frame
	await process_frame
	if not pointer.state.pressed:
		push_error("PAUSE_INPUT_RED: fixture expected paused press to remain latched")
		quit(1)
		return

	# Resume without a fresh mouse event. A real pause boundary must not turn the
	# paused press into a gameplay grab after resuming.
	scene.call("_unhandled_key_input", escape)
	if bool(scene.get("_paused")):
		push_error("PAUSE_INPUT_RED: fixture failed to resume")
		quit(1)
		return

	await process_frame
	await process_frame
	await process_frame
	var state_name := String(controller.get_state_name())
	if state_name in ["EDGE_LIFT", "PINCHED", "PEELING", "COMPLETE"]:
		push_error("PAUSE_INPUT_RED: paused pointer press leaked across resume and entered gameplay state: %s" % state_name)
		quit(1)
		return

	print("PASS: pause isolates pointer input until a fresh post-resume interaction")
	scene.queue_free()
	await process_frame
	quit(0)
