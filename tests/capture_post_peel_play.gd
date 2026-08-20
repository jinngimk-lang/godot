extends SceneTree

const OUTPUT_DIR := "res://artifacts/reference_frames"
const CASES := [
	{"index":0,"name":"coffee_play","kind":"paper_cup","mode":"squeeze"},
	{"index":3,"name":"market_play","kind":"clear_bottle","mode":"shake"},
	{"index":4,"name":"can_play","kind":"soda_can","mode":"squeeze_shake"}
]

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load("res://scenes/peel_lab/peel_lab.tscn") as PackedScene
	if packed == null:
		push_error("POST_PLAY_CAPTURE_RED: peel lab scene did not load")
		quit(1); return
	var scene := packed.instantiate()
	root.add_child(scene)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	await _settle_frames(10)

	for capture_case in CASES:
		scene.set_process(true)
		scene.call("debug_select_variant",int(capture_case["index"]))
		await _settle_frames(7)
		if not _stage_resolved(scene): return
		var play := scene.get_node_or_null("PostPeelObjectPlayPresentation") as PostPeelObjectPlayPresentation
		if play == null:
			push_error("POST_PLAY_CAPTURE_RED: runtime play presentation missing")
			quit(1); return
		play.debug_stage_resolved(String(capture_case["kind"]))
		var mode := String(capture_case["mode"])
		if mode == "squeeze":
			play.debug_feed_drag(Vector2(26,15),0.085)
			play.debug_feed_drag(Vector2(16,9),0.060)
		elif mode == "shake":
			play.debug_feed_drag(Vector2(42,2),0.016)
			play.debug_feed_drag(Vector2(-48,-1),0.016)
			play.debug_feed_drag(Vector2(45,1),0.016)
		else:
			play.debug_feed_drag(Vector2(27,11),0.060)
			play.debug_feed_drag(Vector2(-36,-2),0.018)
			play.debug_feed_drag(Vector2(40,1),0.018)
		await _settle_frames(1)
		if not _assert_play_state(scene,play,capture_case): return
		if not await _capture(String(capture_case["name"])): return
		play.debug_release_play(0.016)
		scene.set_process(true)
		await _settle_frames(3)

	Input.set_custom_mouse_cursor(null,Input.CURSOR_POINTING_HAND)
	Input.set_custom_mouse_cursor(null,Input.CURSOR_ARROW)
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	root.remove_child(scene)
	scene.free()
	scene = null
	packed = null
	await _settle_frames(6)
	print("PASS: captured resolved object-play states")
	quit(0)

func _stage_resolved(scene: Node) -> bool:
	var label := scene.get_node_or_null("PeelLabel") as LabelVisual
	var residue := scene.get_node_or_null("ResidueVisual") as ResidueVisual
	var lifecycle = scene.get("_lifecycle")
	if label == null or residue == null or lifecycle == null:
		push_error("POST_PLAY_CAPTURE_RED: release staging dependencies missing")
		quit(1); return false
	var front := label.get_front_position(1.0)
	label.set_peel(1.0,label.get_effective_grip(1.0,front+Vector3(0.38,0.08,0.28)))
	residue.set_residue(1.0,0.08,0.94)
	lifecycle.reset()
	lifecycle.update(1.0,true,0.016)
	lifecycle.update(1.0,false,0.22)
	lifecycle.update(1.0,false,0.52)
	lifecycle.update(1.0,false,0.34)
	label.set_phase(String(lifecycle.get_phase_name()))
	label.set_detach_alpha(float(lifecycle.get_detach_alpha()))
	if not bool(lifecycle.call("is_resolved")):
		push_error("POST_PLAY_CAPTURE_RED: lifecycle did not reach RESOLVED")
		quit(1); return false
	scene.call("_update_hud","COMPLETE",String(lifecycle.get_phase_name()),1.0)
	scene.set_process(false)
	await process_frame
	return true

func _assert_play_state(scene: Node, play: PostPeelObjectPlayPresentation, capture_case: Dictionary) -> bool:
	var corner := scene.get_node_or_null("CornerPeelPresentation") as CornerPeelPresentation
	if corner == null:
		push_error("POST_PLAY_CAPTURE_RED: corner presentation missing")
		quit(1); return false
	var sheet := corner.get_node_or_null("CornerPeelLabel") as MeshInstance3D
	if sheet != null and sheet.visible:
		push_error("POST_PLAY_CAPTURE_RED: removed label returned during object play")
		quit(1); return false
	var model := play.get_model()
	if model == null:
		push_error("POST_PLAY_CAPTURE_RED: interaction model missing")
		quit(1); return false
	var mode := String(capture_case["mode"])
	if mode.contains("squeeze") and model.get_squeeze_scale().x >= 0.995:
		push_error("POST_PLAY_CAPTURE_RED: %s has no visible squeeze" % String(capture_case["name"]))
		quit(1); return false
	if mode.contains("shake") and absf(model.get_shake_angle()) < 0.004:
		push_error("POST_PLAY_CAPTURE_RED: %s has no visible shake" % String(capture_case["name"]))
		quit(1); return false
	if String(capture_case["kind"]) == "clear_bottle" and absf(model.get_liquid_tilt()) < 0.004:
		push_error("POST_PLAY_CAPTURE_RED: Yuzu shake lost liquid inertia")
		quit(1); return false
	var prompt := scene.get_node_or_null("HUD/PostPeelObjectPlayHint") as Label
	if prompt == null or not prompt.visible or not prompt.text.contains("LMB drag"):
		push_error("POST_PLAY_CAPTURE_RED: resolved object play guidance missing")
		quit(1); return false
	return true

func _capture(name: String) -> bool:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null or image.is_empty():
		push_error("POST_PLAY_CAPTURE_RED: empty viewport for %s" % name)
		quit(1); return false
	var path := "%s/%s.png" % [OUTPUT_DIR,name]
	var error := image.save_png(path)
	image = null
	if error != OK:
		push_error("POST_PLAY_CAPTURE_RED: failed to save %s" % path)
		quit(1); return false
	print("CAPTURE: %s" % path)
	return true

func _settle_frames(count: int) -> void:
	for _i in range(count):
		await process_frame
