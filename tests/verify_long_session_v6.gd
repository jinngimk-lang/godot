extends SceneTree

const RITUAL_COUNT := 30

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var failures: Array[String] = []
	var packed := load("res://scenes/peel_lab/peel_lab.tscn") as PackedScene
	if packed == null:
		push_error("LONG_SESSION_RED: production scene failed to load")
		quit(1)
		return

	var scene := packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	var session = scene.get("_session")
	var ritual = scene.get("_ritual")
	var crumple = scene.get("_crumple")
	var pointer := scene.get_node_or_null("PointerAdapter") as PointerAdapter
	var camera := scene.get_node_or_null("Camera") as Camera3D
	var cup := scene.get_node_or_null("Cup") as MeshInstance3D
	var lid := scene.get_node_or_null("Lid") as MeshInstance3D
	var contents = scene.get("_contents_presentation")
	var reward := scene.get_node_or_null("HUD/Reward") as Label
	if session == null or ritual == null or crumple == null or pointer == null or camera == null or cup == null or lid == null or contents == null or reward == null:
		failures.append("LONG_SESSION_RED: runtime ritual/session/crumple/pointer/cup/contents contract missing")
		_finish(scene, failures)
		return

	var baseline_structural_nodes := _recursive_count(scene) - int(contents.get_content_count())
	var seen_profiles: Dictionary = {}

	for cycle in range(RITUAL_COUNT):
		var current_profile: Dictionary = session.current_variant()
		var current_id := String(current_profile.get("id", ""))
		seen_profiles[current_id] = true
		_check_profile_presentation(scene, current_id, failures, "cycle %d start" % cycle)

		var before_rituals := int(session.get_clean_peels())
		scene.call("_handle_detached_label")
		scene.call("_handle_detached_label")
		if int(session.get_clean_peels()) != before_rituals + 1:
			failures.append("LONG_SESSION_RED: detach must advance exactly once at cycle %d" % cycle)
			break
		if int(session.get_total_score()) != 0:
			failures.append("LONG_SESSION_RED: long-session ritual progression must not revive public score accumulation")
			break
		if ritual.get_phase_name() != "PEEL_SETTLE":
			failures.append("LONG_SESSION_RED: detach should enter PEEL_SETTLE at cycle %d" % cycle)
			break
		if reward.text.is_empty():
			failures.append("LONG_SESSION_RED: detach should expose calm reward copy at cycle %d" % cycle)
			break

		ritual.update(0.50)
		if ritual.get_phase_name() != "CRUMPLE_READY":
			failures.append("LONG_SESSION_RED: settle should reach pressure-free CRUMPLE_READY at cycle %d" % cycle)
			break

		# Mix three realistic owner paths: full multi-grab crumple, partial
		# crumple then skip, and immediate post-peel skip. This stresses the same
		# scene for many minutes without requiring a single preferred play style.
		match cycle % 3:
			0:
				_full_crumple_with_regrab(scene, camera, cup, ritual, crumple, failures, cycle)
			1:
				_partial_crumple_with_regrab(scene, camera, cup, ritual, crumple, failures, cycle)
			2:
				if not is_equal_approx(float(crumple.get_progress()), 0.0):
					failures.append("LONG_SESSION_RED: fresh skip path inherited old crumple progress at cycle %d" % cycle)
		if not failures.is_empty():
			break

		var next_key := InputEventKey.new()
		next_key.pressed = true
		next_key.keycode = KEY_R
		scene.call("_unhandled_key_input", next_key)
		await process_frame

		if ritual.get_phase_name() != "PEEL":
			failures.append("LONG_SESSION_RED: R Next must return authority to PEEL at cycle %d" % cycle)
			break
		if not is_equal_approx(float(crumple.get_progress()), 0.0) or crumple.get_gesture_side() != 0:
			failures.append("LONG_SESSION_RED: next cup must clear crumple model/gesture at cycle %d" % cycle)
			break
		if not reward.text.is_empty():
			failures.append("LONG_SESSION_RED: next cup must clear prior reward presentation at cycle %d" % cycle)
			break
		if pointer.state.pressed:
			failures.append("LONG_SESSION_RED: next cup must not inherit a pressed pointer at cycle %d" % cycle)
			break
		var next_id := String(session.current_variant().get("id", ""))
		_check_profile_presentation(scene, next_id, failures, "cycle %d next" % cycle)
		if not failures.is_empty():
			break
		var structural_nodes := _recursive_count(scene) - int(contents.get_content_count())
		if structural_nodes != baseline_structural_nodes:
			failures.append("LONG_SESSION_RED: structural scene node count drifted at cycle %d: baseline=%d now=%d" % [cycle, baseline_structural_nodes, structural_nodes])
			break

	if failures.is_empty():
		if int(session.get_clean_peels()) != RITUAL_COUNT:
			failures.append("LONG_SESSION_RED: 30 cycles should record exactly 30 rituals")
		if seen_profiles.size() != 3 or not seen_profiles.has("warm_paper") or not seen_profiles.has("silky_long") or not seen_profiles.has("crisp_seal"):
			failures.append("LONG_SESSION_RED: sustained play must actually rotate through all three tactile profiles after unlock")

	_finish(scene, failures)

func _full_crumple_with_regrab(scene: Node, camera: Camera3D, cup: MeshInstance3D, ritual, crumple, failures: Array[String], cycle: int) -> void:
	var center_x := camera.unproject_position(cup.global_position).x
	var left_press := PointerState.new()
	left_press.set_frame(true, Vector2(center_x - 100.0, 360.0), Vector2.ZERO, Vector2.ZERO, false)
	scene.call("_process_crumple_pointer", left_press)
	var left_drag := PointerState.new()
	left_drag.set_frame(true, Vector2(center_x - 80.0, 360.0), Vector2(20.0, 0.0), Vector2(100.0, 0.0), false)
	scene.call("_process_crumple_pointer", left_drag)
	var first_progress := float(crumple.get_progress())
	if first_progress <= 0.0:
		failures.append("LONG_SESSION_RED: full path first squeeze made no progress at cycle %d" % cycle)
		return
	var release := PointerState.new()
	release.set_frame(false, Vector2(center_x - 80.0, 360.0), Vector2.ZERO, Vector2.ZERO, true)
	scene.call("_process_crumple_pointer", release)
	var right_press := PointerState.new()
	right_press.set_frame(true, Vector2(center_x + 100.0, 360.0), Vector2.ZERO, Vector2.ZERO, false)
	scene.call("_process_crumple_pointer", right_press)
	var right_drag := PointerState.new()
	right_drag.set_frame(true, Vector2(center_x + 55.0, 360.0), Vector2(-45.0, 0.0), Vector2(-140.0, 0.0), false)
	for _i in range(20):
		scene.call("_process_crumple_pointer", right_drag)
		if ritual.get_phase_name() == "RITUAL_COMPLETE":
			break
	if float(crumple.get_progress()) <= first_progress:
		failures.append("LONG_SESSION_RED: opposite-side re-grab did not add progress at cycle %d" % cycle)
		return
	if not crumple.is_complete() or ritual.get_phase_name() != "RITUAL_COMPLETE":
		failures.append("LONG_SESSION_RED: full path failed to reach RITUAL_COMPLETE at cycle %d" % cycle)

func _partial_crumple_with_regrab(scene: Node, camera: Camera3D, cup: MeshInstance3D, ritual, crumple, failures: Array[String], cycle: int) -> void:
	var center_x := camera.unproject_position(cup.global_position).x
	var press := PointerState.new()
	press.set_frame(true, Vector2(center_x - 100.0, 360.0), Vector2.ZERO, Vector2.ZERO, false)
	scene.call("_process_crumple_pointer", press)
	var drag := PointerState.new()
	drag.set_frame(true, Vector2(center_x - 85.0, 360.0), Vector2(15.0, 0.0), Vector2(80.0, 0.0), false)
	scene.call("_process_crumple_pointer", drag)
	var first := float(crumple.get_progress())
	var release := PointerState.new()
	release.set_frame(false, Vector2(center_x - 85.0, 360.0), Vector2.ZERO, Vector2.ZERO, true)
	scene.call("_process_crumple_pointer", release)
	var press_again := PointerState.new()
	press_again.set_frame(true, Vector2(center_x - 100.0, 360.0), Vector2.ZERO, Vector2.ZERO, false)
	scene.call("_process_crumple_pointer", press_again)
	scene.call("_process_crumple_pointer", drag)
	if float(crumple.get_progress()) <= first + 0.001:
		failures.append("LONG_SESSION_RED: partial re-grab failed to add progress at cycle %d" % cycle)
		return
	if crumple.is_complete() or ritual.get_phase_name() != "CRUMPLING":
		failures.append("LONG_SESSION_RED: partial path should remain optional/incomplete before skip at cycle %d" % cycle)

func _check_profile_presentation(scene: Node, profile_id: String, failures: Array[String], context: String) -> void:
	var contents = scene.get("_contents_presentation")
	var cup := scene.get_node_or_null("Cup") as MeshInstance3D
	var lid := scene.get_node_or_null("Lid") as MeshInstance3D
	if contents == null or cup == null or lid == null or not (cup.mesh is CylinderMesh):
		failures.append("LONG_SESSION_RED: profile presentation contract missing at %s" % context)
		return
	var count := int(contents.get_content_count())
	var cup_mesh := cup.mesh as CylinderMesh
	if profile_id == "crisp_seal":
		if count != 3 or cup_mesh.cap_top or lid.visible:
			failures.append("LONG_SESSION_RED: crisp profile must remain exactly 3 ice/open-top at %s" % context)
	else:
		if count != 0 or not cup_mesh.cap_top or not lid.visible:
			failures.append("LONG_SESSION_RED: non-ice profile must remain empty/capped/lidded at %s" % context)

func _recursive_count(node: Node) -> int:
	var total := 1
	for child in node.get_children():
		total += _recursive_count(child)
	return total

func _finish(scene: Node, failures: Array[String]) -> void:
	if failures.is_empty():
		print("PASS: 30 mixed rituals remain bounded, pressure-free and profile-consistent")
		scene.queue_free()
		await process_frame
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
