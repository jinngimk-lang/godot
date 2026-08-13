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

	var controller = scene.get("_controller")
	var pointer := scene.get_node_or_null("PointerAdapter") as PointerAdapter
	var label := scene.get_node_or_null("PeelLabel") as LabelVisual
	var camera := scene.get_node_or_null("Camera") as Camera3D
	if controller == null or pointer == null or label == null or camera == null:
		push_error("RESET_INPUT_RED: missing controller/pointer/label/camera contract")
		quit(1)
		return

	controller.reset()
	var edge_world := label.get_front_position(controller.get_progress())
	var edge_screen := camera.unproject_position(edge_world)
	controller.set_edge_position(edge_screen)

	# Simulate the player still holding the primary pointer over the fresh edge.
	pointer.state.set_frame(true, edge_screen, Vector2.ZERO, Vector2.ZERO, false)
	await process_frame
	if String(controller.get_state_name()) not in ["EDGE_LIFT", "PINCHED", "PEELING"]:
		push_error("RESET_INPUT_RED: fixture failed to arm a held peel interaction")
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

	await process_frame
	await process_frame
	await process_frame
	var after_reset := String(controller.get_state_name())
	if after_reset in ["EDGE_LIFT", "PINCHED", "PEELING", "COMPLETE"]:
		push_error("RESET_INPUT_RED: held pointer leaked across R reset and re-grabbed fresh label: %s" % after_reset)
		quit(1)
		return

	# Shift+R should provide the same input isolation while also restarting run state.
	pointer.state.set_frame(true, edge_screen, Vector2.ZERO, Vector2.ZERO, false)
	await process_frame
	var restart := InputEventKey.new()
	restart.pressed = true
	restart.keycode = KEY_R
	restart.shift_pressed = true
	scene.call("_unhandled_key_input", restart)
	await process_frame
	await process_frame
	var after_restart := String(controller.get_state_name())
	if after_restart in ["EDGE_LIFT", "PINCHED", "PEELING", "COMPLETE"]:
		push_error("RESET_INPUT_RED: held pointer leaked across Shift+R restart and re-grabbed fresh label: %s" % after_restart)
		quit(1)
		return

	print("PASS: reset/restart quarantine held pointer state until a fresh interaction")
	scene.queue_free()
	await process_frame
	quit(0)
