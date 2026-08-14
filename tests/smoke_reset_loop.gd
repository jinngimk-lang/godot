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
	var contents: Node = scene.get_node_or_null("CupContentsPresentation")
	var session = scene.get("_session")
	var ritual = scene.get("_ritual")
	var crumple = scene.get("_crumple")
	if right_hand == null or label == null or hud == null or contents == null or session == null or ritual == null or crumple == null:
		push_error("RESET_SMOKE: runtime hand/label/HUD/contents/session/ritual/crumple contract missing")
		quit(1)
		return
	if scene.get("_contents_presentation") != contents:
		push_error("RED: runtime must keep the production CupContentsPresentation reference")
		quit(1)
		return
	if not contents.has_method("get_content_count") or int(contents.call("get_content_count")) != 0:
		push_error("RED: fresh warm_paper reset must start with zero cup contents")
		quit(1)
		return
	if not right_hand.has_method("get_pinch_world_position") or not right_hand.has_method("snap_to"):
		push_error("RESET_SMOKE: RightHand missing pinch/reset contract")
		quit(1)
		return

	var onboarding := hud.text.to_lower()
	if onboarding.contains("hold left mouse"):
		push_error("RED: touch-ready onboarding must not make left mouse sound mandatory: %s" % hud.text)
		quit(1)
		return
	if not onboarding.contains("mouse") or not onboarding.contains("touch"):
		push_error("RED: onboarding must explicitly cover both mouse and touch input: %s" % hud.text)
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
	await process_frame
	var pinch_after_idle := right_hand.call("get_pinch_world_position") as Vector3
	if pinch_after_idle.distance_to(expected_grip_world) > 0.065:
		push_error("RESET_SMOKE: fresh-session pinch drifts away from label edge on first idle frame")
		quit(1)
		return

	if not scene.has_method("_handle_detached_label"):
		push_error("RESET_SMOKE: scene missing repeatable detached-label completion handler")
		quit(1)
		return

	var reset_key := InputEventKey.new()
	reset_key.pressed = true
	reset_key.keycode = KEY_R
	var escape := InputEventKey.new()
	escape.pressed = true
	escape.keycode = KEY_ESCAPE

	scene.set("_pending_score", 100)
	scene.call("_handle_detached_label")
	scene.call("_handle_detached_label")
	if session.get_clean_peels() != 1 or session.get_total_score() != 0:
		push_error("RED: duplicate detach callback must record one score-independent ritual exactly once")
		quit(1)
		return
	if float(scene.get("_reset_timer")) >= 0.0 or bool(scene.get("_advance_after_reset")):
		push_error("RED: V5 detach must not schedule the old automatic next-item timer")
		quit(1)
		return
	if ritual.get_phase_name() != "PEEL_SETTLE":
		push_error("RESET_SMOKE: first detach should enter PEEL_SETTLE")
		quit(1)
		return

	scene.call("_unhandled_key_input", escape)
	if not bool(scene.get("_paused")) or not hud.text.contains("PAUSED"):
		push_error("RESET_SMOKE: Esc must enter visible pause state")
		quit(1)
		return
	scene.call("_process", 1.0)
	if ritual.get_phase_name() != "PEEL_SETTLE":
		push_error("RED: pause must freeze the post-peel settle phase")
		quit(1)
		return
	scene.call("_unhandled_key_input", escape)
	if bool(scene.get("_paused")):
		push_error("RESET_SMOKE: second Esc must resume play")
		quit(1)
		return

	scene.call("_unhandled_key_input", reset_key)
	if session.get_clean_peels() != 1 or session.get_total_score() != 0:
		push_error("RESET_SMOKE: immediate post-peel R must preserve earned progression")
		quit(1)
		return
	if ritual.get_phase_name() != "PEEL" or crumple.get_progress() != 0.0:
		push_error("RED: post-peel R must reset ritual/crumple state for the next item")
		quit(1)
		return

	var before_active_reset := String(session.current_variant().get("id", ""))
	scene.call("_unhandled_key_input", reset_key)
	if session.get_clean_peels() != 1 or String(session.current_variant().get("id", "")) != before_active_reset:
		push_error("RESET_SMOKE: ordinary active-label R must preserve progression/current tactile profile")
		quit(1)
		return

	for ritual_number in range(2, 6):
		scene.set("_pending_score", 100 - ritual_number)
		scene.call("_handle_detached_label")
		scene.call("_handle_detached_label")
		if session.get_clean_peels() != ritual_number:
			push_error("RESET_SMOKE: ritual %d must record exactly once" % ritual_number)
			quit(1)
			return
		if session.get_total_score() != 0:
			push_error("RESET_SMOKE: ritual progression must stay score-independent")
			quit(1)
			return
		ritual.update(0.46)
		if ritual.get_phase_name() != "CRUMPLE_READY":
			push_error("RESET_SMOKE: ritual %d should reach pressure-free CRUMPLE_READY" % ritual_number)
			quit(1)
			return
		for _i in range(30):
			ritual.update(0.1)
		if ritual.get_phase_name() != "CRUMPLE_READY":
			push_error("RED: elapsed time must not auto-advance ritual %d" % ritual_number)
			quit(1)
			return
		scene.call("_unhandled_key_input", reset_key)
		if ritual.get_phase_name() != "PEEL":
			push_error("RESET_SMOKE: deliberate next should return ritual %d to PEEL" % ritual_number)
			quit(1)
			return

	if session.get_clean_peels() != 5 or session.get_unlocked_count() != 3:
		push_error("RESET_SMOKE: five completed rituals must unlock all three tactile profiles")
		quit(1)
		return
	if String(session.current_variant().get("id", "")) != "crisp_seal":
		push_error("RESET_SMOKE: fifth deliberate next should rotate to newly unlocked crisp_seal")
		quit(1)
		return
	if int(contents.call("get_content_count")) != 3:
		push_error("RED: unlocked crisp_seal must materialize exactly three contained ice cubes")
		quit(1)
		return

	var ice_container: Node = contents.get_node_or_null("IceContents")
	if ice_container == null or ice_container.get_child_count() != 3:
		push_error("RED: crisp_seal contents must expose deterministic IceContents children")
		quit(1)
		return
	var first_ice := ice_container.get_child(0) as MeshInstance3D
	if first_ice == null:
		push_error("RESET_SMOKE: first crisp ice child must be renderable")
		quit(1)
		return
	var ice_before_crumple := first_ice.transform

	# Sixth ritual uses the newly unlocked iced cup. A real inward squeeze must
	# forward the same crumple pulse/progress into the contents presentation.
	scene.call("_handle_detached_label")
	if session.get_clean_peels() != 6 or ritual.get_phase_name() != "PEEL_SETTLE":
		push_error("RESET_SMOKE: sixth ritual fixture must enter post-peel settle")
		quit(1)
		return
	ritual.update(0.46)
	if ritual.get_phase_name() != "CRUMPLE_READY":
		push_error("RESET_SMOKE: iced sixth ritual must reach CRUMPLE_READY")
		quit(1)
		return
	var press := PointerState.new()
	press.set_frame(true, Vector2(420, 360), Vector2.ZERO, Vector2.ZERO, false)
	scene.call("_process_crumple_pointer", press)
	var drag := PointerState.new()
	drag.set_frame(true, Vector2(470, 360), Vector2(50, 0), Vector2(120, 0), false)
	scene.call("_process_crumple_pointer", drag)
	if crumple.get_progress() <= 0.0:
		push_error("RESET_SMOKE: iced cup squeeze fixture must create crumple progress")
		quit(1)
		return
	if first_ice.transform.is_equal_approx(ice_before_crumple):
		push_error("RED: production crumple pointer route must forward bounded motion into contained ice")
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
	if ritual.get_phase_name() != "PEEL" or crumple.get_progress() != 0.0:
		push_error("RED: Shift+R must clear ritual/crumple transient state")
		quit(1)
		return
	if int(contents.call("get_content_count")) != 0:
		push_error("RED: full restart must remove unlocked ice and restore quiet warm_paper contents")
		quit(1)
		return
	if float(scene.get("_reset_timer")) >= 0.0 or bool(scene.get("_advance_after_reset")):
		push_error("RED: V5 restart must leave no stale automatic next transition")
		quit(1)
		return
	scene.call("_process", 3.0)
	if String(session.current_variant().get("id", "")) != "warm_paper" or session.get_clean_peels() != 0 or ritual.get_phase_name() != "PEEL":
		push_error("RED: idle time after full restart must not cause stale next-item behavior")
		quit(1)
		return

	print("PASS: exact-once ritual -> deliberate unlock -> iced crumple motion -> full quiet restart")
	scene.queue_free()
	await process_frame
	quit(0)
