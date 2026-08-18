extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load("res://scenes/peel_lab/peel_lab.tscn") as PackedScene
	if packed == null:
		push_error("RITUAL_RED: peel lab scene failed to load")
		quit(1)
		return
	var scene := packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	var failures: Array[String] = []
	var ritual = scene.get("_ritual")
	var crumple = scene.get("_crumple")
	var session = scene.get("_session")
	var pointer := scene.get_node_or_null("PointerAdapter") as PointerAdapter
	var audio := scene.get_node_or_null("PeelAudio")
	var support_hand := scene.get_node_or_null("LeftHand") as Node3D
	var hud := scene.get_node_or_null("HUD/Instructions") as Label
	var reward := scene.get_node_or_null("HUD/Reward") as Label
	var continue_button := scene.get_node_or_null("HUD/Continue") as Button
	var presentation := scene.get_node_or_null("CupCrumplePresentation")
	if ritual == null:
		failures.append("RITUAL_RED: PeelLab must own RitualFlow")
	if crumple == null:
		failures.append("RITUAL_RED: PeelLab must own CupCrumpleModel")
	if session == null or pointer == null or audio == null or support_hand == null or hud == null or reward == null or presentation == null:
		failures.append("RITUAL_RED: real scene missing ritual/session/pointer/audio/support-hand/HUD/presentation contract")
	if continue_button == null:
		failures.append("POST_PEEL_RED: HUD must expose a pointer/touch Continue control after a completed peel")
	if not failures.is_empty():
		_finish(scene, failures)
		return
	if not scene.has_method("_process_crumple_pointer"):
		failures.append("RITUAL_RED: PeelLab missing production crumple pointer router")
		_finish(scene, failures)
		return
	if not audio.has_signal("crumple_pulse_played"):
		failures.append("RITUAL_RED: real crumple needs a machine-observable Foley pulse signal")
		_finish(scene, failures)
		return
	if continue_button.visible:
		failures.append("POST_PEEL_RED: Continue must stay hidden before label completion")
	var crumple_audio_events := [0]
	audio.connect("crumple_pulse_played", func(_strength): crumple_audio_events[0] += 1)
	var support_home := support_hand.position

	pointer.set("_physical_pressed", true)
	pointer.state.set_frame(true, Vector2(520, 360), Vector2.ZERO, Vector2.ZERO, false)
	scene.set("_pending_score", 100)
	scene.call("_handle_detached_label")
	scene.call("_handle_detached_label")
	if session.get_clean_peels() != 1:
		failures.append("RITUAL_RED: duplicate detach must record base ritual progression exactly once")
	if session.get_total_score() != 0:
		failures.append("RITUAL_RED: base progression must not depend on public score accumulation")
	if session.get_unlocked_count() != 2:
		failures.append("POST_PEEL_RED: first café completion must unlock amber bar immediately")
	if float(scene.get("_reset_timer")) >= 0.0:
		failures.append("RITUAL_RED: detached label must not start the old automatic next-cup timer")
	if ritual.get_phase_name() != "PEEL_SETTLE":
		failures.append("RITUAL_RED: detached label should enter PEEL_SETTLE")
	if pointer.state.pressed or not bool(pointer.get("_awaiting_release")):
		failures.append("RITUAL_RED: detach-to-crumple boundary must quarantine a held peel press")
	if not continue_button.visible:
		failures.append("POST_PEEL_RED: Continue must become visible as soon as the label is detached")
	var continue_text := continue_button.text.to_lower()
	if not (continue_text.contains("continue") or continue_text.contains("next")):
		failures.append("POST_PEEL_RED: post-peel button must clearly say Continue/Next")

	ritual.update(0.46)
	if ritual.get_phase_name() != "CRUMPLE_READY":
		failures.append("RITUAL_RED: calm settle should reach CRUMPLE_READY")
	for _i in range(50):
		ritual.update(0.1)
	if ritual.get_phase_name() != "CRUMPLE_READY":
		failures.append("RITUAL_RED: CRUMPLE_READY must never auto-advance on elapsed time")

	var press := PointerState.new()
	press.set_frame(true, Vector2(420, 360), Vector2.ZERO, Vector2.ZERO, false)
	scene.call("_process_crumple_pointer", press)
	var partial_drag := PointerState.new()
	partial_drag.set_frame(true, Vector2(435, 360), Vector2(15, 0), Vector2(80, 0), false)
	scene.call("_process_crumple_pointer", partial_drag)
	var before_regrab: float = float(crumple.get_progress())
	if before_regrab <= 0.0 or crumple.is_complete() or ritual.get_phase_name() != "CRUMPLING":
		failures.append("RITUAL_RED: re-grab fixture must create a partial, still-active crumple")

	var release := PointerState.new()
	release.set_frame(false, Vector2(435, 360), Vector2.ZERO, Vector2.ZERO, true)
	scene.call("_process_crumple_pointer", release)
	if not is_equal_approx(float(crumple.get_progress()), before_regrab):
		failures.append("RITUAL_RED: releasing a squeeze must preserve accumulated cup deformation")
	var press_again := PointerState.new()
	press_again.set_frame(true, Vector2(420, 360), Vector2.ZERO, Vector2.ZERO, false)
	scene.call("_process_crumple_pointer", press_again)
	scene.call("_process_crumple_pointer", partial_drag)
	if float(crumple.get_progress()) <= before_regrab + 0.01:
		failures.append("RITUAL_RED: fresh press after release must reacquire crumple ownership and add another squeeze")

	var drag := PointerState.new()
	drag.set_frame(true, Vector2(470, 360), Vector2(50, 0), Vector2(120, 0), false)
	for _i in range(4):
		scene.call("_process_crumple_pointer", drag)
	if float(crumple.get_progress()) <= 0.0:
		failures.append("RITUAL_RED: real inward squeeze must accumulate cup crumple progress")
	if session.get_clean_peels() != 1:
		failures.append("RITUAL_RED: optional cup squeezing must not duplicate base progression")
	if presentation.has_method("get_progress") and float(presentation.call("get_progress")) <= 0.0:
		failures.append("RITUAL_RED: crumple pointer route must drive visible presentation progress")
	if crumple_audio_events[0] <= 0:
		failures.append("RITUAL_RED: real inward squeeze must route a crumple Foley pulse")
	var support_after_squeeze := support_hand.position
	if support_after_squeeze.x >= support_home.x - 0.02:
		failures.append("RITUAL_RED: support hand must visibly press inward with cup crumple progress")
	if support_after_squeeze.distance_to(support_home) > 0.13:
		failures.append("RITUAL_RED: support-hand staging must remain a restrained presentation offset")
	var audio_before_stationary: int = int(crumple_audio_events[0])
	var stationary := PointerState.new()
	stationary.set_frame(true, Vector2(470, 360), Vector2.ZERO, Vector2.ZERO, false)
	scene.call("_process_crumple_pointer", stationary)
	if int(crumple_audio_events[0]) != audio_before_stationary:
		failures.append("RITUAL_RED: stationary crumple hold must not retrigger Foley")

	for _i in range(20):
		scene.call("_process_crumple_pointer", drag)
	if not crumple.is_complete():
		failures.append("RITUAL_RED: fixture should reach bounded crumple completion")
	if ritual.get_phase_name() != "RITUAL_COMPLETE":
		failures.append("RITUAL_RED: completed squeeze should enter RITUAL_COMPLETE")
	if session.get_clean_peels() != 1:
		failures.append("RITUAL_RED: crumple completion must remain a sensory bonus, not a second ritual")

	scene.call("_update_hud", "", "HELD", 1.0)
	var hud_lower := hud.text.to_lower()
	if hud_lower.contains("score") or hud_lower.contains("feels"):
		failures.append("RITUAL_RED: primary HUD must de-emphasize Score/Feels counters")
	if not hud_lower.contains("squeeze") or not hud_lower.contains("continue"):
		failures.append("POST_PEEL_RED: post-peel HUD should communicate optional squeeze plus explicit Continue")

	continue_button.emit_signal("pressed")
	await process_frame
	if session.get_clean_peels() != 1:
		failures.append("POST_PEEL_RED: Continue must not double-count progression")
	if String(session.current_variant().get("id", "")) != "silky_long":
		failures.append("POST_PEEL_RED: Continue after café must enter amber bar")
	if ritual.get_phase_name() != "PEEL":
		failures.append("POST_PEEL_RED: next scene must reset ritual authority to PEEL")
	if continue_button.visible:
		failures.append("POST_PEEL_RED: Continue must hide again on the fresh next scene")
	if float(crumple.get_progress()) != 0.0:
		failures.append("POST_PEEL_RED: next scene must reset accumulated cup deformation")

	var reset_variant := String(session.current_variant().get("id", ""))
	var reset_key := InputEventKey.new()
	reset_key.pressed = true
	reset_key.keycode = KEY_T
	scene.call("_unhandled_key_input", reset_key)
	if String(session.current_variant().get("id", "")) != reset_variant:
		failures.append("POST_PEEL_RED: T must only reset the current item; it must never act as Next")
	var controller = scene.get("_controller")
	if controller == null or not is_zero_approx(float(controller.get_progress())):
		failures.append("POST_PEEL_RED: T reset must restore fresh peel progress")

	_finish(scene, failures)

func _finish(scene: Node, failures: Array[String]) -> void:
	if failures.is_empty():
		print("PASS: detach -> optional tactile ritual -> explicit Continue -> café/bar progression -> T reset")
		scene.queue_free()
		await process_frame
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	scene.queue_free()
	await process_frame
	quit(1)