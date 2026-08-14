extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load("res://scenes/peel_lab/peel_lab.tscn") as PackedScene
	if packed == null:
		_fail("RESET_SMOKE: peel lab scene failed to load")
		return
	var scene := packed.instantiate()
	root.add_child(scene)
	await process_frame

	var right_hand := scene.get_node_or_null("RightHand") as Node3D
	var label := scene.get_node_or_null("PeelLabel") as LabelVisual
	var hud := scene.get_node_or_null("HUD/Instructions") as Label
	var session = scene.get("_session")
	var ritual = scene.get("_ritual")
	var crumple = scene.get("_crumple")
	if right_hand == null or label == null or hud == null or session == null or ritual == null or crumple == null:
		_fail("RESET_SMOKE: runtime hand/label/HUD/session/ritual/crumple contract missing", scene)
		return

	# The reference HUD uses compact desktop notation; touch ownership is covered
	# independently by PointerAdapter deterministic tests rather than bloating HUD copy.
	var onboarding := hud.text.to_lower()
	if not (onboarding.contains("lmb") or onboarding.contains("mouse")) or not onboarding.contains("peel anywhere"):
		_fail("RESET_SMOKE: reference onboarding must expose mouse peel-anywhere input: %s" % hud.text, scene)
		return

	# Current-label reset keeps the visible pinch aligned to the fresh label.
	var expected_grip_local := label.get_front_position(0.0)
	var expected_grip_world := label.to_global(expected_grip_local)
	var displaced := right_hand.position + Vector3(0.82,0.31,0.47)
	right_hand.call("snap_to", displaced)
	scene.call("_reset_session")
	var pinch_world := right_hand.call("get_pinch_world_position") as Vector3
	if pinch_world.distance_to(expected_grip_world) > 0.035:
		_fail("RESET_SMOKE: reset must return visible pinch to fresh label edge", scene)
		return
	await process_frame
	var pinch_after_idle := right_hand.call("get_pinch_world_position") as Vector3
	if pinch_after_idle.distance_to(expected_grip_world) > 0.065:
		_fail("RESET_SMOKE: fresh-session pinch drifts away on first idle frame", scene)
		return

	var reset_key := InputEventKey.new()
	reset_key.pressed = true
	reset_key.keycode = KEY_R
	var escape := InputEventKey.new()
	escape.pressed = true
	escape.keycode = KEY_ESCAPE

	# Paper detach remains exact-once and enters the optional tactile settle.
	scene.set("_pending_score",100)
	scene.call("_handle_detached_label")
	scene.call("_handle_detached_label")
	if session.get_clean_peels() != 1 or session.get_total_score() != 0:
		_fail("RESET_SMOKE: duplicate paper detach must record exactly one ritual", scene)
		return
	if ritual.get_phase_name() != "PEEL_SETTLE":
		_fail("RESET_SMOKE: paper detach should enter PEEL_SETTLE", scene)
		return

	# Pause freezes the calm paper settle.
	scene.call("_unhandled_key_input",escape)
	if not bool(scene.get("_paused")) or not hud.text.contains("PAUSED"):
		_fail("RESET_SMOKE: Esc must enter visible pause state", scene)
		return
	scene.call("_process",1.0)
	if ritual.get_phase_name() != "PEEL_SETTLE":
		_fail("RESET_SMOKE: pause must freeze paper settle", scene)
		return
	scene.call("_unhandled_key_input",escape)

	# Deliberate R may skip the optional paper squeeze and return a fresh item.
	scene.call("_unhandled_key_input",reset_key)
	if session.get_clean_peels() != 1 or ritual.get_phase_name() != "PEEL" or crumple.get_progress() != 0.0:
		_fail("RESET_SMOKE: paper R-next must preserve progression and clear transient ritual state", scene)
		return

	# Complete a second café peel so progression unlocks the bar, then deliberately
	# advance through the paper ritual boundary.
	scene.call("_handle_detached_label")
	if session.get_clean_peels() != 2 or session.get_unlocked_count() < 2:
		_fail("RESET_SMOKE: second paper ritual should unlock bar profile", scene)
		return
	ritual.update(0.46)
	if ritual.get_phase_name() != "CRUMPLE_READY":
		_fail("RESET_SMOKE: paper settle should expose optional CRUMPLE_READY", scene)
		return
	scene.call("_unhandled_key_input",reset_key)
	if String(session.current_variant().get("id","")) != "silky_long":
		_fail("RESET_SMOKE: deliberate next after paper should advance to unlocked bar bottle", scene)
		return
	if ritual.get_phase_name() != "PEEL":
		_fail("RESET_SMOKE: bar entry must start with fresh PEEL authority", scene)
		return

	# Glass products never borrow the paper crumple ritual. Detach is counted once,
	# stays inspectable, and R resets the current bottle rather than deforming it.
	scene.call("_handle_detached_label")
	scene.call("_handle_detached_label")
	if session.get_clean_peels() != 3:
		_fail("RESET_SMOKE: duplicate bar detach must count once", scene)
		return
	if ritual.get_phase_name() != "PEEL" or crumple.get_progress() != 0.0:
		_fail("RESET_SMOKE: glass detach must not enter paper crumple ritual", scene)
		return
	var bar_id := String(session.current_variant().get("id",""))
	scene.call("_unhandled_key_input",reset_key)
	if String(session.current_variant().get("id","")) != bar_id or session.get_clean_peels() != 3:
		_fail("RESET_SMOKE: R on glass should reset that item without erasing progression", scene)
		return

	# Full restart from a glass scene clears progression and all transient state.
	var restart := InputEventKey.new()
	restart.pressed = true
	restart.keycode = KEY_R
	restart.shift_pressed = true
	scene.call("_unhandled_key_input",restart)
	if session.get_clean_peels() != 0 or session.get_total_score() != 0 or session.get_unlocked_count() != 1:
		_fail("RESET_SMOKE: Shift+R must restart progression cleanly", scene)
		return
	if String(session.current_variant().get("id","")) != "warm_paper":
		_fail("RESET_SMOKE: full restart must restore café paper cup", scene)
		return
	if ritual.get_phase_name() != "PEEL" or crumple.get_progress() != 0.0:
		_fail("RESET_SMOKE: full restart must clear ritual/crumple state", scene)
		return
	scene.call("_process",3.0)
	if String(session.current_variant().get("id","")) != "warm_paper" or session.get_clean_peels() != 0:
		_fail("RESET_SMOKE: idle time after restart must not cause stale transition", scene)
		return

	print("PASS: paper ritual reset -> bar glass reset -> exact-once progression -> full restart")
	scene.queue_free()
	await process_frame
	quit(0)

func _fail(message: String, scene: Node = null) -> void:
	push_error(message)
	if scene != null:
		scene.queue_free()
	await process_frame
	quit(1)
