extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load("res://scenes/peel_lab/peel_lab.tscn") as PackedScene
	if packed == null:
		push_error("REGRAB_RED: peel lab scene failed to load")
		quit(1)
		return
	var scene := packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	var ritual = scene.get("_ritual")
	var crumple = scene.get("_crumple")
	var camera := scene.get_node_or_null("Camera") as Camera3D
	var cup := scene.get_node_or_null("Cup") as Node3D
	if ritual == null or crumple == null or camera == null or cup == null:
		push_error("REGRAB_RED: production ritual/crumple/camera/cup contract missing")
		quit(1)
		return
	scene.call("_handle_detached_label")
	ritual.update(0.46)
	if ritual.get_phase_name() != "CRUMPLE_READY":
		push_error("REGRAB_RED: fixture failed to reach CRUMPLE_READY")
		quit(1)
		return
	var center_x := camera.unproject_position(cup.global_position).x
	var press_one := PointerState.new()
	press_one.set_frame(true, Vector2(center_x - 100.0, 360.0), Vector2.ZERO, Vector2.ZERO, false)
	scene.call("_process_crumple_pointer", press_one)
	var drag_one := PointerState.new()
	drag_one.set_frame(true, Vector2(center_x - 85.0, 360.0), Vector2(15.0, 0.0), Vector2(80.0, 0.0), false)
	scene.call("_process_crumple_pointer", drag_one)
	var after_first: float = float(crumple.get_progress())
	if after_first <= 0.0 or crumple.is_complete():
		push_error("REGRAB_RED: first squeeze fixture should create partial crumple progress")
		quit(1)
		return
	var release := PointerState.new()
	release.set_frame(false, Vector2(center_x - 85.0, 360.0), Vector2.ZERO, Vector2.ZERO, true)
	scene.call("_process_crumple_pointer", release)
	var press_two := PointerState.new()
	press_two.set_frame(true, Vector2(center_x - 100.0, 360.0), Vector2.ZERO, Vector2.ZERO, false)
	scene.call("_process_crumple_pointer", press_two)
	var drag_two := PointerState.new()
	drag_two.set_frame(true, Vector2(center_x - 85.0, 360.0), Vector2(15.0, 0.0), Vector2(80.0, 0.0), false)
	scene.call("_process_crumple_pointer", drag_two)
	var after_second: float = float(crumple.get_progress())
	if after_second <= after_first + 0.01:
		push_error("REGRAB_RED: fresh press after release must allow a second independent squeeze; first=%.6f second=%.6f phase=%s side=%d" % [after_first, after_second, ritual.get_phase_name(), int(crumple.get_gesture_side())])
		quit(1)
		return
	print("PASS: repeated release/re-grab squeezes accumulate crumple progress")
	scene.queue_free()
	await process_frame
	quit(0)
