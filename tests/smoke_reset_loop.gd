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

	# PC remains primary, but the same production PointerAdapter accepts direct
	# touch. The first player-facing instruction must therefore not tell a touch
	# player that a left mouse button is mandatory.
	var onboarding := hud.text.to_lower()
	if onboarding.contains("hold left mouse"):
		push_error("RED: touch-ready onboarding must not make left mouse sound mandatory: %s" % hud.text)
		quit(1)
		return
	if not onboarding.contains("mouse") or not onboarding.contains("touch"):
		push_error("RED: onboarding must explicitly cover both mouse and touch input: %s" % hud.text)
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

	if not scene.has_method("_handle_detached_label"):
		push_error("RESET_SMOKE: scene missing repeatable detached-label completion handler")
		quit(1)
		return

	# First detach: even a duplicated detach callback must never double-count.
	scene.set("_pending_score", 100)
	scene.call("_handle_detached_label")
	scene.call("_handle_detached_label")
	if session.get_clean_peels() != 1 or session.get_total_score() != 100:
		push_error("RED: duplicate detach callback must record progression exactly once")
		quit(1)
		return
	scene.set("_reset_timer", 0.0)
	await process_frame

	# Second detach unlocks Silky Long. Pause must freeze the pending next-item timer.
	scene.set("_pending_score", 90)
	scene.call("_handle_detached_label")
	if session.get_clean_peels() != 2 or session.get_unlocked_count() != 2:
		push_error("RESET_SMOKE: second clean peel must unlock the second tactile feel")
		quit(1)
		return
	var timer_before_pause := float(scene.get("_reset_timer"))
	var escape := InputEventKey.new()
	escape.pressed = true
	escape.keycode = KEY_ESCAPE
	scene.call("_unhandled_key_input", escape)
	if not bool(scene.get("_paused")) or not hud.text.contains("PAUSED"):
		push_error("RESET_SMOKE: Esc must enter a visible pause state")
		quit(1)
		return
	scene.call("_process", 0.75)
	if absf(float(scene.get("_reset_timer")) - timer_before_pause) > 0.001:
		push_error("RED: pause during the next-item delay must freeze the timer")
		quit(1)
		return
	scene.call("_unhandled_key_input", escape)
	if bool(scene.get("_paused")):
		push_error("RESET_SMOKE: second Esc must resume play")
		quit(1)
		return

	# R after a completed peel means 'next now', not replaying the already-counted item.
	var before_skip_id := String(session.current_variant().get("id", ""))
	var reset_key := InputEventKey.new()
	reset_key.pressed = true
	reset_key.keycode = KEY_R
	scene.call("_unhandled_key_input", reset_key)
	if session.get_clean_peels() != 2 or session.get_total_score() != 190:
		push_error("RESET_SMOKE: skipping the completion delay must not change earned progression")
		quit(1)
		return
	if float(scene.get("_reset_timer")) >= 0.0 or bool(scene.get("_advance_after_reset")):
		push_error("RED: R during completion delay must consume the pending next-item transition")
		quit(1)
		return
	var after_skip_id := String(session.current_variant().get("id", ""))
	if before_skip_id == after_skip_id or after_skip_id != "silky_long":
		push_error("RED: R during completion delay must advance immediately to the next unlocked tactile feel")
		quit(1)
		return

	# Ordinary R on an active fresh label resets only that label and preserves the run.
	scene.call("_unhandled_key_input", reset_key)
	if session.get_clean_peels() != 2 or session.get_total_score() != 190 or String(session.current_variant().get("id", "")) != "silky_long":
		push_error("RESET_SMOKE: ordinary R must preserve progression and the current tactile feel")
		quit(1)
		return

	# Three more completions exercise repeated next-item rotation and unlock the third feel.
	for score in [80, 70, 60]:
		scene.set("_pending_score", score)
		scene.call("_handle_detached_label")
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

	# A completed sixth label creates another pending transition; Shift+R must cancel it
	# while clearing the whole run, so no stale auto-advance can fire afterwards.
	scene.set("_pending_score", 50)
	scene.call("_handle_detached_label")
	if session.get_clean_peels() != 6 or float(scene.get("_reset_timer")) <= 0.0:
		push_error("RESET_SMOKE: fixture must enter a pending next-item transition")
		quit(1)
		return
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
	if float(scene.get("_reset_timer")) >= 0.0 or bool(scene.get("_advance_after_reset")):
		push_error("RED: Shift+R during completion delay must cancel stale pending auto-advance")
		quit(1)
		return
	scene.call("_process", 3.0)
	if String(session.current_variant().get("id", "")) != "warm_paper" or session.get_clean_peels() != 0:
		push_error("RED: stale next-item transition must not fire after full-run restart")
		quit(1)
		return

	print("PASS: exact-once detach -> frozen pause -> next-now R -> repeated unlock -> full restart")
	scene.queue_free()
	await process_frame
	quit(0)
