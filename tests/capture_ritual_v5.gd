extends SceneTree

const OUT_DIR := "artifacts/ritual-v5"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://%s" % OUT_DIR))
	var packed := load("res://scenes/peel_lab/peel_lab.tscn") as PackedScene
	if packed == null:
		push_error("CAPTURE_V5: failed to load peel lab")
		quit(1)
		return
	var scene := packed.instantiate()
	root.add_child(scene)
	await _settle_frames(8)
	await _capture("01_fresh_peel.png")

	var label := scene.get_node("PeelLabel") as LabelVisual
	var right_hand := scene.get_node("RightHand") as HandVisual
	var marker := scene.get_node("PeelEdge") as MeshInstance3D
	label.set_phase("HELD")
	label.set_detach_alpha(1.0)
	label.set_peel(1.0, right_hand.get_pinch_world_position())
	marker.visible = false
	scene.call("_handle_detached_label")
	var ritual = scene.get("_ritual")
	var crumple = scene.get("_crumple")
	ritual.update(0.46)
	scene.call("_update_hud", "", "HELD", 1.0)
	await _settle_frames(5)
	await _capture("02_crumple_ready.png")

	# Enter production CRUMPLING through its normal pointer route. Between capture
	# waits the real scene may end the synthetic gesture because there is no
	# physical pointer, so later stages explicitly re-begin only the model gesture
	# on this verifier-only fixture before feeding more production drag frames.
	var press := PointerState.new()
	press.set_frame(true, Vector2(420, 360), Vector2.ZERO, Vector2.ZERO, false)
	scene.call("_process_crumple_pointer", press)
	var drag := PointerState.new()
	drag.set_frame(true, Vector2(470, 360), Vector2(50, 0), Vector2(120, 0), false)
	scene.call("_process_crumple_pointer", drag)
	scene.call("_process_crumple_pointer", drag)
	scene.call("_update_hud", "", "HELD", 1.0)
	await _settle_frames(5)
	await _capture("03_mid_crumple.png")

	# Capture-only re-arm: production requires fresh gesture ownership; the model
	# was ended by idle SceneTree frames above, so begin a new left-side squeeze.
	crumple.begin_gesture(420.0, 640.0)
	for _i in range(4):
		scene.call("_process_crumple_pointer", drag)
	scene.call("_update_hud", "", "HELD", 1.0)
	await _settle_frames(2)
	await _capture("04_complete_crumple.png")

	if float(crumple.get_progress()) < 0.72 or ritual.get_phase_name() != "RITUAL_COMPLETE":
		push_error("CAPTURE_V5: final frame failed to reach real crumple completion; progress=%.3f phase=%s" % [float(crumple.get_progress()), ritual.get_phase_name()])
		quit(1)
		return
	print("CAPTURE_V5: phase=%s crumple=%.3f lid_y=%.4f" % [ritual.get_phase_name(), float(crumple.get_progress()), scene.get_node("Lid").position.y])
	scene.queue_free()
	await process_frame
	quit(0)

func _settle_frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func _capture(filename: String) -> void:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var path := "res://%s/%s" % [OUT_DIR, filename]
	var err := image.save_png(path)
	if err != OK:
		push_error("CAPTURE_V5: failed to save %s: %s" % [path, err])
		quit(1)
		return
	print("CAPTURE_V5: saved %s" % ProjectSettings.globalize_path(path))
