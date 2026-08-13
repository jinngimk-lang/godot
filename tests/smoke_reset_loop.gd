extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load("res://scenes/peel_lab/peel_lab.tscn") as PackedScene
	if packed == null:
		push_error("RESET_SMOKE: peel lab scene failed to load")
		quit(1)
		return
	var scene := packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	var right_hand := scene.get_node_or_null("RightHand") as Node3D
	if right_hand == null:
		push_error("RESET_SMOKE: RightHand missing")
		quit(1)
		return
	var home := right_hand.position
	var displaced := home + Vector3(0.82, 0.31, 0.47)
	if right_hand.has_method("snap_to"):
		right_hand.call("snap_to", displaced)
	else:
		right_hand.position = displaced
	if right_hand.position.distance_to(home) < 0.5:
		push_error("RESET_SMOKE: fixture failed to move RightHand away from home")
		quit(1)
		return

	scene.call("_reset_session")
	var after_reset := right_hand.position
	if after_reset.distance_to(home) > 0.01:
		push_error("RESET_SMOKE: RightHand did not return home after session reset; home=%s after=%s" % [str(home), str(after_reset)])
		quit(1)
		return

	print("PASS: repeated session reset restores RightHand home position")
	scene.queue_free()
	await process_frame
	quit(0)
