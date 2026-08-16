extends SceneTree

const OUTPUT_DIR := "res://artifacts/reference_frames"
const THUMB_SIZE := Vector2i(48,27)

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed: PackedScene = load("res://scenes/peel_lab/peel_lab.tscn") as PackedScene
	if packed == null:
		push_error("CAPTURE_RED: peel lab scene did not load")
		quit(1)
		return
	var scene: Node = packed.instantiate()
	root.add_child(scene)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	await _settle_frames(10)

	scene.call("debug_select_variant",0)
	await _settle_frames(8)
	if not await _capture("cafe"): return
	_stage_peel(scene,0.38,0.05,0.94)
	await _settle_frames(5)
	if not await _capture("cafe_peel38"): return
	_resume_hand_choreography(scene)
	scene.call("debug_select_variant",0)
	await _settle_frames(4)
	_stage_crumple(scene,0.55)
	await _settle_frames(8)
	if not await _capture("cafe_crumple55"): return

	scene.call("debug_select_variant",1)
	await _settle_frames(8)
	if not await _capture("bar"): return
	_stage_peel(scene,0.48,0.18,0.78)
	await _settle_frames(5)
	if not await _capture("bar_peel48"): return
	_resume_hand_choreography(scene)
	scene.call("debug_select_variant",1)
	await _settle_frames(4)
	_stage_inspect(scene,0.58,0.22,0.78)
	await _settle_frames(8)
	if not await _capture("bar_inspect"): return

	scene.call("debug_select_variant",2)
	await _settle_frames(8)
	if not await _capture("market"): return
	_stage_peel(scene,0.45,0.07,0.93)
	await _settle_frames(5)
	if not await _capture("market_peel45"): return
	_resume_hand_choreography(scene)
	scene.call("debug_select_variant",2)
	await _settle_frames(4)
	_stage_inspect(scene,-0.62,0.10,0.90)
	await _settle_frames(8)
	if not await _capture("market_inspect"): return

	scene.queue_free()
	await process_frame
	print("PASS: captured base + peel + crumple/inspect visual-convergence frames")
	quit(0)

func _stage_peel(scene: Node, progress: float, residue_amount: float, integrity: float) -> void:
	var label := scene.get_node("PeelLabel") as LabelVisual
	var hand := scene.get_node("RightHand") as HandVisual
	var residue := scene.get_node("ResidueVisual")
	var choreography := scene.get_node_or_null("HandChoreographyPresentation") as HandChoreographyPresentation
	label.visible = true
	label.set_phase("PEELING")
	label.set_detach_alpha(0.0)
	var front := label.get_front_position(progress)
	# Exaggerate the staging pull enough to make the lifted flap and adhesive
	# bend readable in a single screenshot; gameplay still uses live pointer input.
	var grip_local := front+Vector3(-0.95,0.11,0.56)
	var grip_world := label.to_global(grip_local)
	# This test stages peel state directly rather than driving PeelController. Keep
	# hand choreography paused until the screenshot is written; otherwise the idle
	# controller state overwrites the staged hand during settle frames and publishes
	# a frame that is neither the requested Pinch Tight pose nor exact flap contact.
	if choreography != null:
		choreography.set_process(false)
	hand.set_pinch_amount(1.0)
	hand.set("_pinch_amount",1.0)
	hand.call("_apply_pose")
	hand.call("_refresh_pinch_anchors")
	var current_pinch := hand.get_pinch_world_position()
	hand.position += grip_world-current_pinch
	hand.set_grip_target(grip_world)
	var active_pose := String(hand.get("_last_authored_pose"))
	if active_pose != "Pinch Tight":
		push_error("CAPTURE_RED: staged peel did not activate Pinch Tight (got %s)" % active_pose)
		quit(1)
		return
	var aligned_pinch := hand.get_pinch_world_position()
	var alignment_error := aligned_pinch.distance_to(grip_world)
	if alignment_error > 0.0005:
		push_error("CAPTURE_RED: staged pinch/root alignment error %.6f m" % alignment_error)
		quit(1)
		return
	label.set_peel(progress,label.to_local(aligned_pinch))
	residue.call("set_residue",progress,residue_amount,integrity)

func _resume_hand_choreography(scene: Node) -> void:
	var choreography := scene.get_node_or_null("HandChoreographyPresentation") as HandChoreographyPresentation
	if choreography != null:
		choreography.set_process(true)

func _stage_inspect(scene: Node, yaw: float, residue_amount: float, integrity: float) -> void:
	var label := scene.get_node("PeelLabel") as LabelVisual
	var residue := scene.get_node("ResidueVisual")
	label.visible = false
	residue.call("set_residue",0.88,residue_amount,integrity)
	scene.call("_apply_inspection_yaw",yaw)

func _stage_crumple(scene: Node, amount: float) -> void:
	var label := scene.get_node("PeelLabel") as LabelVisual
	var ritual = scene.get("_ritual")
	var crumple_visual := scene.get_node_or_null("CupCrumplePresentation")
	label.visible = false
	scene.call("_handle_detached_label")
	ritual.update(0.22)
	ritual.begin_crumple()
	if crumple_visual != null:
		crumple_visual.call("set_crumple",amount,-1,0.72)

func _capture(name: String) -> bool:
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	if image == null or image.is_empty():
		push_error("CAPTURE_RED: viewport image empty for %s" % name)
		quit(1)
		return false
	var path := "%s/%s.png" % [OUTPUT_DIR,name]
	var error := image.save_png(path)
	if error != OK:
		push_error("CAPTURE_RED: failed to save %s (%s)" % [path,error_string(error)])
		quit(1)
		return false
	print("CAPTURE: %s" % path)
	if name.contains("peel"):
		_emit_thumb_rgbhex(name,image)
	return true

func _emit_thumb_rgbhex(name: String, image: Image) -> void:
	var thumb := image.duplicate()
	thumb.resize(THUMB_SIZE.x,THUMB_SIZE.y,Image.INTERPOLATE_BILINEAR)
	var rgb := PackedStringArray()
	rgb.resize(THUMB_SIZE.x*THUMB_SIZE.y)
	var i := 0
	for y in range(THUMB_SIZE.y):
		for x in range(THUMB_SIZE.x):
			rgb[i] = thumb.get_pixel(x,y).to_html(false)
			i += 1
	print("THUMB_RGBHEX:%s:%dx%d:%s" % [name,THUMB_SIZE.x,THUMB_SIZE.y,"".join(rgb)])

func _settle_frames(count: int) -> void:
	for _i: int in range(count):
		await process_frame
