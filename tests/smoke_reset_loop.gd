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
	var hud := scene.get_node_or_null("HUD/Instructions") as Label
	var session = scene.get("_session")
	if right_hand == null or label == null or hud == null or session == null:
		push_error("RESET_SMOKE: runtime hand/label/HUD/session contract missing")
		quit(1)
		return
	if not right_hand.has_method("get_pinch_world_position") or not right_hand.has_method("snap_to"):
		push_error("RESET_SMOKE: RightHand missing pinch/reset contract")
		quit(1)
		return

	# Current-label reset keeps the visible pinch aligned to the fresh edge.
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

	await process_frame
	var pinch_after_idle := right_hand.call("get_pinch_world_position") as Vector3
	if pinch_after_idle.distance_to(expected_grip_world) > 0.065:
		push_error("RESET_SMOKE: fresh-session pinch drifts away from label edge on the first idle frame; expected=%s actual=%s" % [str(expected_grip_world), str(pinch_after_idle)])
		quit(1)
		return

	# Completion handling must be factored so the actual detach path can be
	# exercised repeatedly without fabricating pointer events in this smoke.
	if not scene.has_method("_handle_detached_label"):
		push_error("RED: scene missing repeatable detached-label completion handler")
		quit(1)
		return

	var first_id := String(session.current_variant().get("id", ""))
	var scores := [100, 90, 80, 70, 60]
	for i in range(scores.size()):
		scene.set("_pending_score", scores[i])
		scene.call("_handle_detached_label")
		if session.get_clean_peels() != i + 1:
			push_error("RESET_SMOKE: each detach must record exactly one clean peel")
			quit(1)
			return
		# Collapse the presentation delay while keeping the same production next-item path.
		scene.set("_reset_timer", 0.0)
		await process_frame

	if session.get_clean_peels() != 5 or session.get_unlocked_count() != 3:
		push_error("RESET_SMOKE: five completed labels must unlock all three tactile feels")
		quit(1)
		return
	if session.get_total_score() != 400:
		push_error("RESET_SMOKE: repeated completion score should accumulate exactly once per label")
		quit(1)
		return
	if String(session.current_variant().get("id", "")) == first_id:
		push_error("RESET_SMOKE: repeated next-item flow must rotate away from the initial tactile feel")
		quit(1)
		return

	# Pause is player-facing and reversible without destroying progression.
	var escape := InputEventKey.new()
	escape.pressed = true
	escape.keycode = KEY_ESCAPE
	scene.call("_unhandled_key_input", escape)
	if not bool(scene.get("_paused")) or not hud.text.contains("PAUSED"):
		push_error("RESET_SMOKE: Esc must enter a visible pause state")
		quit(1)
		return
	scene.call("_unhandled_key_input", escape)
	if bool(scene.get("_paused")):
		push_error("RESET_SMOKE: second Esc must resume play")
		quit(1)
		return

	# Shift+R is a deterministic full-run restart, separate from ordinary label reset.
	var restart := InputEventKey.new()
	restart.pressed = true
	restart.keycode = KEY_R
	restart.shift_pressed = true
	scene.call("_unhandled_key_input", restart)
	if session.get_clean_peels() != 0 or session.get_total_score() != 0 or session.get_unlocked_count() != 1:
		push_error("RESET_SMOKE: Shift+R must restart progression cleanly")
		quit(1)
		return
	if String(session.current_variant().get("id", "")) != "warm_paper":
		push_error("RESET_SMOKE: full restart must restore warm_paper")
		quit(1)
		return

	print("PASS: repeated complete -> next -> unlock -> pause -> restart flow")
	scene.queue_free()
	await process_frame
	quit(0)
