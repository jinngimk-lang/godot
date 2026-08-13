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

	var right_hand := scene.get_node_or_null("RightHand") as Node3D
	var label := scene.get_node_or_null("PeelLabel") as LabelVisual
	if right_hand == null or label == null:
		push_error("RESET_SMOKE: RightHand or PeelLabel missing")
		quit(1)
		return
	if not right_hand.has_method("get_pinch_world_position") or not right_hand.has_method("snap_to"):
		push_error("RESET_SMOKE: RightHand missing pinch/reset contract")
		quit(1)
		return

	var expected_grip_local := label.get_front_position(0.0)
	var expected_grip_world := label.to_global(expected_grip_local)
	var displaced := right_hand.position + Vector3(0.82, 0.31, 0.47)
	right_hand.call("snap_to", displaced)
	if right_hand.position.distance_to(displaced) > 0.001:
		push_error("RESET_SMOKE: fixture failed to displace RightHand")
		quit(1)
		return

	scene.call("_reset_session")
	var pinch_world := right_hand.call("get_pinch_world_position") as Vector3
	if pinch_world.distance_to(expected_grip_world) > 0.035:
		push_error("RESET_SMOKE: reset must return visible pinch to fresh label edge; expected=%s actual=%s" % [str(expected_grip_world), str(pinch_world)])
		quit(1)
		return

	# The next idle frame must not immediately undo the reset alignment.
	await process_frame
	var pinch_after_idle := right_hand.call("get_pinch_world_position") as Vector3
	if pinch_after_idle.distance_to(expected_grip_world) > 0.065:
		push_error("RESET_SMOKE: fresh-session pinch drifts away from label edge on the first idle frame; expected=%s actual=%s" % [str(expected_grip_world), str(pinch_after_idle)])
		quit(1)
		return

	print("PASS: repeated session reset restores visible pinch to the fresh label edge")
	scene.queue_free()
	await process_frame
	quit(0)
