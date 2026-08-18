extends SceneTree

const OUTPUT_DIR := "res://artifacts/reference_frames"
const CASES := [
	{"index":0,"base":"coffee","peel":"coffee_peel38","done":"coffee_done","progress":0.38,"residue":0.08,"integrity":0.94},
	{"index":1,"base":"jar","peel":"jar_peel49","done":"jar_done","progress":0.49,"residue":0.14,"integrity":0.88},
	{"index":2,"base":"tin","peel":"tin_peel41","done":"tin_done","progress":0.41,"residue":0.18,"integrity":0.82},
	{"index":3,"base":"market","peel":"market_peel45","done":"market_done","progress":0.45,"residue":0.05,"integrity":0.98},
	{"index":4,"base":"can","peel":"can_peel33","done":"can_done","progress":0.33,"residue":0.07,"integrity":0.96}
]
const FORBIDDEN_NODES := ["LeftHand","RightHand","ForearmPresentation","CrumpleHandStaging","HandChoreographyPresentation","CinematicHandPresentation","HandSurfaceSmoothing","ReferencePeelPlayback"]

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load("res://scenes/peel_lab/peel_lab.tscn") as PackedScene
	if packed == null:
		push_error("CAPTURE_RED: peel lab scene did not load")
		quit(1)
		return
	var scene := packed.instantiate()
	root.add_child(scene)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	await _settle_frames(12)
	if not _assert_object_only_scene(scene): return
	for capture_case in CASES:
		scene.call("debug_select_variant",int(capture_case["index"]))
		await _settle_frames(8)
		_align_cursor_to_corner(scene,false)
		if not await _capture(String(capture_case["base"])): return
		if not _stage_direct_peel(scene,capture_case): return
		await _settle_frames(4)
		_align_cursor_to_corner(scene,true)
		await _settle_frames(1)
		if not _assert_direct_peel(scene,capture_case): return
		if not await _capture(String(capture_case["peel"])): return
		if not _stage_full_release(scene,capture_case): return
		await _settle_frames(4)
		if not _assert_full_release(scene,capture_case): return
		if not await _capture(String(capture_case["done"])): return
		_resume_scene(scene)
		await _settle_frames(2)
	Input.set_custom_mouse_cursor(null,Input.CURSOR_POINTING_HAND)
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	scene.queue_free()
	await process_frame
	await RenderingServer.frame_post_draw
	print("PASS: captured five paper-release triplets")
	quit(0)

func _assert_object_only_scene(scene: Node) -> bool:
	for node_name in FORBIDDEN_NODES:
		if scene.get_node_or_null(node_name) != null:
			push_error("CAPTURE_RED: obsolete presentation node still exists: %s" % node_name)
			quit(1); return false
	var contract: Dictionary = scene.call("get_visual_interaction_contract")
	if bool(contract.get("visible_hands",true)) or String(contract.get("pointer_grip","")) != "mouse_direct":
		push_error("CAPTURE_RED: runtime is not using object-only mouse-direct interaction")
		quit(1); return false
	var cursor := scene.get_node_or_null("CursorPresentation") as CursorPresentation
	var corner := scene.get_node_or_null("CornerPeelPresentation") as CornerPeelPresentation
	if cursor == null or cursor.get_cursor_node() == null:
		push_error("CAPTURE_RED: software hand cursor is missing from the gameplay viewport")
		quit(1); return false
	if corner == null or corner.get_node_or_null("CornerPeelLabel") == null:
		push_error("CAPTURE_RED: localized corner-peel renderer is missing")
		quit(1); return false
	return true

func _stage_direct_peel(scene: Node, capture_case: Dictionary) -> bool:
	var label := scene.get_node_or_null("PeelLabel") as LabelVisual
	var residue := scene.get_node_or_null("ResidueVisual") as ResidueVisual
	var guide := scene.get_node_or_null("GuidedJourneyPresentation") as GuidedJourneyPresentation
	var session = scene.get("_session")
	if label == null or residue == null or session == null:
		push_error("CAPTURE_RED: direct peel staging is missing label/residue/session")
		quit(1); return false
	var progress := float(capture_case["progress"])
	var front := label.get_front_position(progress)
	var desired_grip_local := front+Vector3(0.36,0.04,0.22)
	var grip_local := label.get_effective_grip(progress,desired_grip_local)
	label.set_phase("PEELING")
	label.set_detach_alpha(0.0)
	label.set_peel(progress,grip_local)
	residue.set_residue(progress,float(capture_case["residue"]),float(capture_case["integrity"]))
	scene.set_process(false)
	if guide != null:
		guide.set_process(false)
		guide.set_state(int(capture_case["index"]),"PEELING","inspect",progress,false)
	scene.call("_update_hud","PEELING","PEELING",progress)
	return true

func _stage_full_release(scene: Node, capture_case: Dictionary) -> bool:
	var label := scene.get_node_or_null("PeelLabel") as LabelVisual
	var residue := scene.get_node_or_null("ResidueVisual") as ResidueVisual
	var guide := scene.get_node_or_null("GuidedJourneyPresentation") as GuidedJourneyPresentation
	var lifecycle = scene.get("_lifecycle")
	if label == null or residue == null or lifecycle == null:
		push_error("CAPTURE_RED: full release staging is missing label/residue/lifecycle")
		quit(1); return false
	var front := label.get_front_position(1.0)
	var desired_grip_local := front+Vector3(0.50,0.10,0.34)
	var grip_local := label.get_effective_grip(1.0,desired_grip_local)
	label.set_peel(1.0,grip_local)
	residue.set_residue(1.0,float(capture_case["residue"]),float(capture_case["integrity"]))
	# Stage the actual post-peel lifecycle rather than freezing the old HELD state.
	# LabelLifecycle intentionally clamps any single delta to 0.5 s, so advance the
	# 0.72 s settle window in two bounded updates to prove true RESOLVED state.
	lifecycle.reset()
	lifecycle.update(1.0,true,0.016)
	lifecycle.update(1.0,false,0.18)
	lifecycle.update(1.0,false,0.50)
	lifecycle.update(1.0,false,0.30)
	label.set_phase(String(lifecycle.get_phase_name()))
	label.set_detach_alpha(float(lifecycle.get_detach_alpha()))
	scene.set_process(false)
	if guide != null:
		guide.set_process(false)
		guide.set_state(int(capture_case["index"]),"COMPLETE","inspect",1.0,true)
	scene.call("_update_hud","COMPLETE",String(lifecycle.get_phase_name()),1.0)
	return true

func _align_cursor_to_corner(scene: Node, peeled: bool) -> void:
	var camera := scene.get_node_or_null("Camera") as Camera3D
	var cursor := scene.get_node_or_null("CursorPresentation") as CursorPresentation
	var corner := scene.get_node_or_null("CornerPeelPresentation") as CornerPeelPresentation
	if camera == null or cursor == null or corner == null:
		return
	var target := corner.get_visual_grip_world_position() if peeled else corner.get_start_edge_world_position()
	cursor.set_debug_position(camera.unproject_position(target))

func _assert_direct_peel(scene: Node, capture_case: Dictionary) -> bool:
	var label := scene.get_node_or_null("PeelLabel") as LabelVisual
	var corner := scene.get_node_or_null("CornerPeelPresentation") as CornerPeelPresentation
	var residue := scene.get_node_or_null("ResidueVisual") as ResidueVisual
	var guide := scene.get_node_or_null("GuidedJourneyPresentation") as GuidedJourneyPresentation
	var expected_percent := int(round(float(capture_case["progress"])*100.0))
	if label == null or corner == null:
		push_error("CAPTURE_RED: hidden simulation label or corner renderer disappeared"); quit(1); return false
	var visual := corner.get_node_or_null("CornerPeelLabel") as MeshInstance3D
	if visual == null or not visual.visible or visual.mesh == null:
		push_error("CAPTURE_RED: %s lost localized visible corner peel" % String(capture_case["peel"])); quit(1); return false
	if label.visible:
		push_error("CAPTURE_RED: hand-era ribbon LabelVisual must remain hidden behind CornerPeelPresentation"); quit(1); return false
	if residue == null or not residue.has_adhesive_trace():
		push_error("CAPTURE_RED: %s lost the real residue trace" % String(capture_case["peel"])); quit(1); return false
	var hud := scene.get_node_or_null("HUD/Instructions") as Label
	if hud == null or not hud.text.contains("Peel %d%%" % expected_percent):
		push_error("CAPTURE_RED: %s HUD does not match staged progress" % String(capture_case["peel"])); quit(1); return false
	if guide != null and not guide.get_action_text().contains("%d%%" % expected_percent):
		push_error("CAPTURE_RED: %s rail guidance does not match staged progress" % String(capture_case["peel"])); quit(1); return false
	return true

func _assert_full_release(scene: Node, capture_case: Dictionary) -> bool:
	var corner := scene.get_node_or_null("CornerPeelPresentation") as CornerPeelPresentation
	var label := scene.get_node_or_null("PeelLabel") as LabelVisual
	var residue := scene.get_node_or_null("ResidueVisual") as ResidueVisual
	var lifecycle = scene.get("_lifecycle")
	if corner == null or label == null or lifecycle == null:
		push_error("CAPTURE_RED: full release lost label presentation/lifecycle")
		quit(1); return false
	if float(corner.visual_progress_for_gameplay(1.0)) < 0.999:
		push_error("CAPTURE_RED: %s leaves visually attached paper at 100%%" % String(capture_case["done"]))
		quit(1); return false
	if not bool(lifecycle.call("is_resolved")):
		push_error("CAPTURE_RED: %s never resolves the released-label lifecycle" % String(capture_case["done"]))
		quit(1); return false
	var visual := corner.get_node_or_null("CornerPeelLabel") as MeshInstance3D
	if visual == null or visual.mesh == null:
		push_error("CAPTURE_RED: %s lost the paper presentation node" % String(capture_case["done"]))
		quit(1); return false
	if visual.visible:
		push_error("CAPTURE_RED: %s still leaves the fully released sheet floating over the hero product" % String(capture_case["done"]))
		quit(1); return false
	if residue == null or not residue.has_adhesive_trace():
		push_error("CAPTURE_RED: %s should keep residue evidence after paper disposal" % String(capture_case["done"]))
		quit(1); return false
	var hud := scene.get_node_or_null("HUD/Instructions") as Label
	if hud == null or not hud.text.contains("Peel 100%"):
		push_error("CAPTURE_RED: %s does not expose 100%% completion in HUD" % String(capture_case["done"]))
		quit(1); return false
	return true

func _resume_scene(scene: Node) -> void:
	var guide := scene.get_node_or_null("GuidedJourneyPresentation") as GuidedJourneyPresentation
	if guide != null: guide.set_process(true)
	scene.set_process(true)

func _capture(name: String) -> bool:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null or image.is_empty():
		push_error("CAPTURE_RED: viewport image empty for %s" % name); quit(1); return false
	var path := "%s/%s.png" % [OUTPUT_DIR,name]
	var error := image.save_png(path)
	if error != OK:
		push_error("CAPTURE_RED: failed to save %s (%d)" % [path,error]); quit(1); return false
	print("CAPTURE: %s" % path)
	return true

func _settle_frames(count: int) -> void:
	for _i in range(count): await process_frame