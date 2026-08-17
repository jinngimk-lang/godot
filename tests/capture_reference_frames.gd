extends SceneTree

const OUTPUT_DIR := "res://artifacts/reference_frames"
const THUMB_SIZE := Vector2i(48,27)
const CAPTURE_GRIP_META := &"capture_expected_grip_world"
const CAPTURE_GUIDE_WAS_PROCESSING := &"capture_guide_was_processing"

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
	# Clean café peel: prove the pressure-sensitive contact film without
	# fabricating torn backing fibers.
	_stage_peel(scene,0.38,0.0,1.0,"clean")
	await _settle_frames(5)
	if not _assert_staged_peel_survived_settle(scene,"cafe_peel38","clean"): return
	if not await _capture("cafe_peel38"): return
	_resume_staged_capture(scene)
	scene.call("debug_select_variant",0)
	await _settle_frames(4)
	_stage_crumple(scene,0.55)
	await _settle_frames(8)
	if not _assert_staged_crumple_survived_settle(scene,"cafe_crumple55"): return
	if not await _capture("cafe_crumple55"): return

	scene.call("debug_select_variant",1)
	await _settle_frames(8)
	if not await _capture("bar"): return
	# Bar is intentionally the damaged/fibrous fixture: it must show the clean
	# glue film plus a separate dry backing layer.
	_stage_peel(scene,0.48,0.18,0.78,"damaged")
	await _settle_frames(5)
	if not _assert_staged_peel_survived_settle(scene,"bar_peel48","damaged"): return
	if not await _capture("bar_peel48"): return
	_resume_staged_capture(scene)
	scene.call("debug_select_variant",1)
	await _settle_frames(4)
	_stage_inspect(scene,0.58,0.22,0.78)
	await _settle_frames(8)
	if not _assert_staged_inspect_survived_settle(scene,"bar_inspect"): return
	if not await _capture("bar_inspect"): return
	_resume_staged_capture(scene)

	scene.call("debug_select_variant",2)
	await _settle_frames(8)
	if not await _capture("market"): return
	# Clean coated-market peel: lower-tack contact film, no torn paper layer.
	_stage_peel(scene,0.45,0.0,1.0,"clean")
	await _settle_frames(5)
	if not _assert_staged_peel_survived_settle(scene,"market_peel45","clean"): return
	if not await _capture("market_peel45"): return
	_resume_staged_capture(scene)
	scene.call("debug_select_variant",2)
	await _settle_frames(4)
	_stage_inspect(scene,-0.62,0.10,0.90)
	await _settle_frames(8)
	if not _assert_staged_inspect_survived_settle(scene,"market_inspect"): return
	if not await _capture("market_inspect"): return
	_resume_staged_capture(scene)

	scene.queue_free()
	await process_frame
	print("PASS: captured base + explicit clean-glue/damaged-fiber peel + crumple/inspect evidence")
	quit(0)

func _stage_peel(scene: Node, progress: float, residue_amount: float, integrity: float, evidence_kind: String) -> void:
	var label := scene.get_node("PeelLabel") as LabelVisual
	var hand := scene.get_node("RightHand") as HandVisual
	var residue := scene.get_node("ResidueVisual") as ResidueVisual
	var choreography := scene.get_node_or_null("HandChoreographyPresentation") as HandChoreographyPresentation
	var guide := scene.get_node_or_null("GuidedJourneyPresentation") as GuidedJourneyPresentation
	var session = scene.get("_session")
	label.visible = true
	label.set_phase("PEELING")
	label.set_detach_alpha(0.0)
	var front := label.get_front_position(progress)
	var desired_grip_local := front+Vector3(-0.95,0.11,0.56)
	var grip_local := label.get_effective_grip(progress,desired_grip_local)
	var grip_world := label.to_global(grip_local)
	var flap_points := label.get_sample_points(progress,desired_grip_local)
	if flap_points.is_empty():
		push_error("CAPTURE_RED: staged peel produced no label points")
		quit(1)
		return
	var rendered_flap_tip_world := label.to_global(flap_points[0])
	var hand_to_flap_error := grip_world.distance_to(rendered_flap_tip_world)
	if hand_to_flap_error > 0.0005:
		push_error("CAPTURE_RED: effective hand target misses rendered flap tip by %.6f m" % hand_to_flap_error)
		quit(1)
		return

	scene.set_process(false)
	if choreography != null:
		choreography.set_process(false)
	if guide != null:
		guide.set_meta(CAPTURE_GUIDE_WAS_PROCESSING,guide.is_processing())
		guide.set_process(false)

	hand.set_pinch_amount(1.0)
	hand.set("_pinch_amount",1.0)
	hand.call("_apply_pose")
	hand.call("_refresh_pinch_anchors")
	var current_pinch := hand.get_pinch_world_position()
	hand.position += grip_world-current_pinch
	hand.set_grip_target(grip_world)
	hand.set_meta(CAPTURE_GRIP_META,grip_world)
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
	residue.set_residue(progress,residue_amount,integrity)

	# Staged visual evidence must tell the same state story as the image. Keep
	# the capture-only pose isolated from gameplay authority, but update the
	# player-facing status to the exact staged progress instead of showing 0%.
	scene.call("_update_hud","PEELING","PEELING",progress)
	if guide != null and session != null:
		var variant: Dictionary = session.current_variant()
		guide.set_state(int(session.get_variant_index()),"PEELING",String(variant.get("post_peel_action","inspect")),progress,false)

	if not residue.has_adhesive_trace():
		push_error("CAPTURE_RED: staged %s peel did not produce an adhesive trace" % evidence_kind)
		quit(1)
		return
	var surfaces := residue.mesh.get_surface_count() if residue.mesh != null else 0
	if evidence_kind == "clean":
		if surfaces != 1 or residue.get_fiber_strength() > 0.02:
			push_error("CAPTURE_RED: clean peel must show exactly one glue-film surface and no torn fibers (surfaces=%d fiber=%.3f)" % [surfaces,residue.get_fiber_strength()])
			quit(1)
			return
	elif evidence_kind == "damaged":
		if surfaces < 2 or not residue.has_layered_residue():
			push_error("CAPTURE_RED: damaged peel must show separate glue + fibrous backing surfaces (surfaces=%d)" % surfaces)
			quit(1)
			return

func _assert_staged_peel_survived_settle(scene: Node, capture_name: String, evidence_kind: String) -> bool:
	var hand := scene.get_node("RightHand") as HandVisual
	var residue := scene.get_node("ResidueVisual") as ResidueVisual
	var hud := scene.get_node_or_null("HUD/Instructions") as Label
	var guide := scene.get_node_or_null("GuidedJourneyPresentation") as GuidedJourneyPresentation
	if not hand.has_meta(CAPTURE_GRIP_META):
		push_error("CAPTURE_RED: %s missing staged grip contract" % capture_name)
		quit(1)
		return false
	var active_pose := String(hand.get("_last_authored_pose"))
	if active_pose != "Pinch Tight":
		push_error("CAPTURE_RED: %s lost Pinch Tight during settle (got %s)" % [capture_name,active_pose])
		quit(1)
		return false
	var expected_grip: Vector3 = hand.get_meta(CAPTURE_GRIP_META)
	var alignment_error := hand.get_pinch_world_position().distance_to(expected_grip)
	if alignment_error > 0.0005:
		push_error("CAPTURE_RED: %s pinch drifted %.6f m during settle" % [capture_name,alignment_error])
		quit(1)
		return false
	if residue == null or not residue.has_adhesive_trace():
		push_error("CAPTURE_RED: %s lost adhesive trace during settle" % capture_name)
		quit(1)
		return false
	var surfaces := residue.mesh.get_surface_count() if residue.mesh != null else 0
	if evidence_kind == "clean" and surfaces != 1:
		push_error("CAPTURE_RED: %s clean evidence drifted to %d residue surfaces" % [capture_name,surfaces])
		quit(1)
		return false
	if evidence_kind == "damaged" and surfaces < 2:
		push_error("CAPTURE_RED: %s damaged evidence lost layered residue" % capture_name)
		quit(1)
		return false
	var expected_percent := capture_name.trim_prefix("cafe_peel").trim_prefix("bar_peel").trim_prefix("market_peel")
	if hud == null or not hud.text.contains("Peel %s%%" % expected_percent):
		push_error("CAPTURE_RED: %s HUD does not match staged peel progress" % capture_name)
		quit(1)
		return false
	if guide != null and not guide.get_action_text().contains("%s%%" % expected_percent):
		push_error("CAPTURE_RED: %s JourneyGuide does not match staged peel progress" % capture_name)
		quit(1)
		return false
	return true

func _assert_staged_crumple_survived_settle(scene: Node, capture_name: String) -> bool:
	var label := scene.get_node("PeelLabel") as LabelVisual
	var lifecycle = scene.get("_lifecycle")
	if label == null or lifecycle == null:
		push_error("CAPTURE_RED: %s missing label/lifecycle evidence contract" % capture_name)
		quit(1)
		return false
	if label.visible:
		push_error("CAPTURE_RED: %s regrew the detached receipt during crumple settle" % capture_name)
		quit(1)
		return false
	if String(lifecycle.get_phase_name()) != "HELD":
		push_error("CAPTURE_RED: %s must stage the post-detach lifecycle as HELD before crumpling" % capture_name)
		quit(1)
		return false
	return true

func _assert_staged_inspect_survived_settle(scene: Node, capture_name: String) -> bool:
	var label := scene.get_node("PeelLabel") as LabelVisual
	var residue := scene.get_node("ResidueVisual") as ResidueVisual
	if label.visible:
		push_error("CAPTURE_RED: %s inspection evidence regrew the label during settle" % capture_name)
		quit(1)
		return false
	if residue == null or residue.mesh == null or residue.mesh.get_surface_count() <= 0:
		push_error("CAPTURE_RED: %s inspection evidence lost residue geometry during settle" % capture_name)
		quit(1)
		return false
	return true

func _resume_staged_capture(scene: Node) -> void:
	var hand := scene.get_node("RightHand") as HandVisual
	if hand.has_meta(CAPTURE_GRIP_META):
		hand.remove_meta(CAPTURE_GRIP_META)
	var choreography := scene.get_node_or_null("HandChoreographyPresentation") as HandChoreographyPresentation
	if choreography != null:
		choreography.set_process(true)
	var guide := scene.get_node_or_null("GuidedJourneyPresentation") as GuidedJourneyPresentation
	if guide != null:
		var should_process := bool(guide.get_meta(CAPTURE_GUIDE_WAS_PROCESSING,true))
		guide.set_process(should_process)
		if guide.has_meta(CAPTURE_GUIDE_WAS_PROCESSING):
			guide.remove_meta(CAPTURE_GUIDE_WAS_PROCESSING)
	scene.set_process(true)

func _stage_inspect(scene: Node, yaw: float, residue_amount: float, integrity: float) -> void:
	var label := scene.get_node("PeelLabel") as LabelVisual
	var residue := scene.get_node("ResidueVisual") as ResidueVisual
	var choreography := scene.get_node_or_null("HandChoreographyPresentation") as HandChoreographyPresentation
	var guide := scene.get_node_or_null("GuidedJourneyPresentation") as GuidedJourneyPresentation
	var session = scene.get("_session")
	scene.set_process(false)
	if choreography != null:
		choreography.set_process(false)
	if guide != null:
		guide.set_meta(CAPTURE_GUIDE_WAS_PROCESSING,guide.is_processing())
		guide.set_process(false)
	label.visible = false
	residue.set_residue(0.88,residue_amount,integrity)
	scene.call("_apply_inspection_yaw",yaw)
	scene.call("_update_hud","HELD","HELD",1.0)
	if guide != null and session != null:
		var variant: Dictionary = session.current_variant()
		guide.set_state(int(session.get_variant_index()),"HELD",String(variant.get("post_peel_action","inspect")),1.0,true)

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
