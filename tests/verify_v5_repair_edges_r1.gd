extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var failures: Array[String] = []
	var model_script = load("res://scripts/cup/cup_crumple_model.gd")
	if model_script == null:
		push_error("VERIFY_RED: CupCrumpleModel failed to load")
		quit(1)
		return

	var crisp := {"rigidity": 0.055, "dent_gain": 0.0035, "max_compression": 0.18}

	# Equal all-inward displacement should remain packetization-invariant.
	var coarse = model_script.new(crisp)
	var mixed = model_script.new(crisp)
	coarse.begin_gesture(-100.0, 0.0)
	mixed.begin_gesture(-100.0, 0.0)
	coarse.apply_drag(20.0)
	for packet in [2.0, 3.0, 1.0, 4.0, 10.0]:
		mixed.apply_drag(packet)
	if absf(float(coarse.get_progress()) - float(mixed.get_progress())) > 0.0001:
		failures.append("PACKET_RED: mixed packetization changed equal inward displacement; coarse=%.6f mixed=%.6f" % [coarse.get_progress(), mixed.get_progress()])

	# The rigidity threshold exists to reject tiny pointer jitter. Oscillating
	# around the exact starting point has zero net inward displacement and must
	# not eventually synthesize a dent merely by accumulating only positive half-cycles.
	var jitter = model_script.new(crisp)
	jitter.begin_gesture(-100.0, 0.0)
	for _i in range(12):
		jitter.apply_drag(0.2)
		jitter.apply_drag(-0.2)
	if float(jitter.get_progress()) > 0.000001:
		failures.append("JITTER_RED: zero-net subpixel oscillation bypassed rigidity deadzone; progress=%.6f" % jitter.get_progress())

	# Scene-level regression: release a partial left squeeze, then re-grab on the
	# opposite side. Fresh ownership must follow the new side and add deformation.
	var packed := load("res://scenes/peel_lab/peel_lab.tscn") as PackedScene
	if packed == null:
		failures.append("SCENE_RED: peel lab failed to load")
	else:
		var scene := packed.instantiate()
		root.add_child(scene)
		await process_frame
		await process_frame
		var ritual = scene.get("_ritual")
		var crumple = scene.get("_crumple")
		var camera := scene.get_node_or_null("Camera") as Camera3D
		var cup := scene.get_node_or_null("Cup") as Node3D
		var audio := scene.get_node_or_null("PeelAudio")
		if ritual == null or crumple == null or camera == null or cup == null or audio == null:
			failures.append("SCENE_RED: ritual/crumple/camera/cup/audio contract missing")
		else:
			scene.call("_handle_detached_label")
			ritual.update(0.46)
			var center_x := camera.unproject_position(cup.global_position).x
			var audio_count := [0]
			if audio.has_signal("crumple_pulse_played"):
				audio.connect("crumple_pulse_played", func(_strength): audio_count[0] += 1)

			var left_press := PointerState.new()
			left_press.set_frame(true, Vector2(center_x - 100.0, 360.0), Vector2.ZERO, Vector2.ZERO, false)
			scene.call("_process_crumple_pointer", left_press)
			var audio_after_press := int(audio_count[0])
			if float(crumple.get_progress()) != 0.0 or int(audio_count[0]) != audio_after_press:
				failures.append("SCENE_RED: press-only crumple ownership must not create deformation/Foley")
			var left_drag := PointerState.new()
			left_drag.set_frame(true, Vector2(center_x - 85.0, 360.0), Vector2(15.0, 0.0), Vector2(80.0, 0.0), false)
			scene.call("_process_crumple_pointer", left_drag)
			var after_left := float(crumple.get_progress())

			var release := PointerState.new()
			release.set_frame(false, Vector2(center_x - 85.0, 360.0), Vector2.ZERO, Vector2.ZERO, true)
			scene.call("_process_crumple_pointer", release)

			var right_press := PointerState.new()
			right_press.set_frame(true, Vector2(center_x + 100.0, 360.0), Vector2.ZERO, Vector2.ZERO, false)
			scene.call("_process_crumple_pointer", right_press)
			if int(crumple.get_gesture_side()) != 1:
				failures.append("SCENE_RED: opposite-side re-grab must reacquire right-side gesture ownership")
			var right_drag := PointerState.new()
			right_drag.set_frame(true, Vector2(center_x + 85.0, 360.0), Vector2(-15.0, 0.0), Vector2(-80.0, 0.0), false)
			scene.call("_process_crumple_pointer", right_drag)
			if float(crumple.get_progress()) <= after_left + 0.01:
				failures.append("SCENE_RED: opposite-side fresh re-grab failed to add a second squeeze; left=%.6f right=%.6f" % [after_left, crumple.get_progress()])
		scene.queue_free()
		await process_frame

	if failures.is_empty():
		print("PASS: integrated V5 repair edges — packetization, jitter deadzone, opposite-side re-grab")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
