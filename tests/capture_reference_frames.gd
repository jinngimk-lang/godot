extends SceneTree

const OUTPUT_DIR := "res://artifacts/reference_frames"
const CASES := [
	{"index":0,"base":"coffee","peel":"coffee_peel38","progress":0.38,"residue":0.08,"integrity":0.94},
	{"index":1,"base":"jar","peel":"jar_peel49","progress":0.49,"residue":0.14,"integrity":0.88},
	{"index":2,"base":"tin","peel":"tin_peel41","progress":0.41,"residue":0.18,"integrity":0.82},
	{"index":3,"base":"market","peel":"market_peel45","progress":0.45,"residue":0.05,"integrity":0.98},
	{"index":4,"base":"can","peel":"can_peel33","progress":0.33,"residue":0.07,"integrity":0.96}
]
const FORBIDDEN_NODES := [
	"LeftHand","RightHand","ForearmPresentation","CrumpleHandStaging",
	"HandChoreographyPresentation","CinematicHandPresentation","HandSurfaceSmoothing",
	"ReferencePeelPlayback"
]

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
	if not _assert_object_only_scene(scene):
		return

	for capture_case in CASES:
		var index := int(capture_case["index"])
		scene.call("debug_select_variant",index)
		await _settle_frames(8)
		if not await _capture(String(capture_case["base"])):
			return
		if not _stage_direct_peel(scene,capture_case):
			return
		await _settle_frames(4)
		if not _assert_direct_peel(scene,capture_case):
			return
		if not await _capture(String(capture_case["peel"])):
			return
		_resume_scene(scene)
		await _settle_frames(2)

	scene.queue_free()
	await process_frame
	print("PASS: captured five object-only base + direct mouse-peel evidence pairs")
	quit(0)

func _assert_object_only_scene(scene: Node) -> bool:
	for node_name in FORBIDDEN_NODES:
		if scene.get_node_or_null(node_name) != null:
			push_error("CAPTURE_RED: obsolete presentation node still exists: %s" % node_name)
			quit(1)
			return false
	var contract: Dictionary = scene.call("get_visual_interaction_contract")
	if bool(contract.get("visible_hands",true)) or String(contract.get("pointer_grip","")) != "mouse_direct":
		push_error("CAPTURE_RED: runtime is not using object-only mouse-direct interaction")
		quit(1)
		return false
	return true

func _stage_direct_peel(scene: Node, capture_case: Dictionary) -> bool:
	var label := scene.get_node_or_null("PeelLabel") as LabelVisual
	var residue := scene.get_node_or_null("ResidueVisual") as ResidueVisual
	var guide := scene.get_node_or_null("GuidedJourneyPresentation") as GuidedJourneyPresentation
	var session = scene.get("_session")
	if label == null or residue == null or session == null:
		push_error("CAPTURE_RED: direct peel staging is missing label/residue/session")
		quit(1)
		return false

	var progress := float(capture_case["progress"])
	var front := label.get_front_position(progress)
	# The pointer is staged to the camera-left of the live peel edge, matching the
	# approved mockup: a readable lifted flap, not an extreme ribbon or hand pose.
	var desired_grip_local := front+Vector3(-0.62,0.08,0.34)
	var grip_local := label.get_effective_grip(progress,desired_grip_local)
	label.visible = true
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

func _assert_direct_peel(scene: Node, capture_case: Dictionary) -> bool:
	var label := scene.get_node_or_null("PeelLabel") as LabelVisual
	var residue := scene.get_node_or_null("ResidueVisual") as ResidueVisual
	var guide := scene.get_node_or_null("GuidedJourneyPresentation") as GuidedJourneyPresentation
	var expected_percent := int(round(float(capture_case["progress"])*100.0))
	if label == null or not label.visible:
		push_error("CAPTURE_RED: %s lost the live label during settle" % String(capture_case["peel"]))
		quit(1)
		return false
	if residue == null or not residue.has_adhesive_trace():
		push_error("CAPTURE_RED: %s lost the real residue trace" % String(capture_case["peel"]))
		quit(1)
		return false
	var hud := scene.get_node_or_null("HUD/Instructions") as Label
	if hud == null or not hud.text.contains("Peel %d%%" % expected_percent):
		push_error("CAPTURE_RED: %s HUD does not match staged progress" % String(capture_case["peel"]))
		quit(1)
		return false
	if guide != null and not guide.get_action_text().contains("%d%%" % expected_percent):
		push_error("CAPTURE_RED: %s rail guidance does not match staged progress" % String(capture_case["peel"]))
		quit(1)
		return false
	return true

func _resume_scene(scene: Node) -> void:
	var guide := scene.get_node_or_null("GuidedJourneyPresentation") as GuidedJourneyPresentation
	if guide != null:
		guide.set_process(true)
	scene.set_process(true)

func _capture(name: String) -> bool:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null or image.is_empty():
		push_error("CAPTURE_RED: viewport image empty for %s" % name)
		quit(1)
		return false
	var path := "%s/%s.png" % [OUTPUT_DIR,name]
	var error := image.save_png(path)
	if error != OK:
		push_error("CAPTURE_RED: failed to save %s (%d)" % [path,error])
		quit(1)
		return false
	print("CAPTURE: %s" % path)
	return true

func _settle_frames(count: int) -> void:
	for _i in range(count):
		await process_frame
