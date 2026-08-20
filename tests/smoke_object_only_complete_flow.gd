extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load("res://scenes/peel_lab/peel_lab.tscn") as PackedScene
	if packed == null:
		_fail("peel lab scene failed to load")
		return
	var scene := packed.instantiate()
	root.add_child(scene)
	for _frame in range(4):
		await process_frame
	scene.process_mode = Node.PROCESS_MODE_DISABLED

	var controller = scene.get("_controller")
	var lifecycle = scene.get("_lifecycle")
	var pointer := scene.get_node_or_null("PointerAdapter") as PointerAdapter
	var corner := scene.get_node_or_null("CornerPeelPresentation") as CornerPeelPresentation
	var residue := scene.get_node_or_null("ResidueVisual") as ResidueVisual
	var cursor := scene.get_node_or_null("CursorPresentation") as CursorPresentation
	var session = scene.get("_session")
	var continue_button := scene.get_node_or_null("HUD/Continue") as Button
	var rail := scene.get_node_or_null("HUD/JourneyRail") as Control
	if controller == null or lifecycle == null or pointer == null or corner == null or residue == null or cursor == null or session == null or continue_button == null or rail == null:
		_fail("runtime interaction contract is incomplete",scene)
		return

	controller.reset()
	pointer.state.set_frame(false,Vector2.ZERO,Vector2.ZERO,Vector2.ZERO,false)
	scene.call("_process",1.0/60.0)
	var edge: Vector2 = controller.get_edge_position()

	pointer.state.set_frame(true,edge,Vector2.ZERO,Vector2.ZERO,false)
	scene.call("_process",1.0/60.0)
	if String(controller.get_state_name()) != "EDGE_LIFT":
		_fail("fresh visible-corner press did not enter EDGE_LIFT",scene)
		return

	for _frame in range(7):
		pointer.state.set_frame(true,edge+Vector2(16,-6),Vector2(2,-1),Vector2(140,-80),false)
		scene.call("_process",1.0/60.0)
	if String(controller.get_state_name()) not in ["PINCHED","PEELING"]:
		_fail("deliberate edge load did not arm the peel",scene)
		return

	var last_position := edge+Vector2(16,-6)
	for pull_index in range(420):
		last_position = edge+Vector2(28+pull_index*3,-18-pull_index*0.08)
		pointer.state.set_frame(true,last_position,Vector2(3,-0.08),Vector2(980,-220),false)
		scene.call("_process",1.0/60.0)
		if controller.is_complete():
			break
	if not controller.is_complete() or float(controller.get_progress()) < 0.999:
		_fail("continuous outward pointer work did not complete the label",scene)
		return

	var clean_before_resolution := int(session.get_clean_peels())
	pointer.state.set_frame(false,last_position,Vector2.ZERO,Vector2.ZERO,true)
	for _frame in range(92):
		scene.call("_process",1.0/60.0)
		pointer.clear_transients()
	if String(lifecycle.get_phase_name()) != "RESOLVED" or not lifecycle.is_next_ready():
		_fail("completed label did not settle into RESOLVED/NEXT_READY",scene)
		return
	var released_visual := corner.get_node_or_null("CornerPeelLabel") as MeshInstance3D
	if released_visual == null or released_visual.visible:
		_fail("resolved paper still blocks the hero object",scene)
		return
	if int(session.get_clean_peels()) != clean_before_resolution:
		_fail("label release must wait for residue rubbing before recording a clean result",scene)
		return
	if continue_button.visible or not rail.visible:
		_fail("resolved flow must keep Continue gated while exposing the persistent scene rail",scene)
		return
	cursor.call("_process",1.0/60.0)
	if not cursor.is_scrub_feedback_visible():
		_fail("resolved residue stage must turn the small hand cursor into visible RUB feedback",scene)
		return
	var scrub = scene.get("_scrub_model")
	if scrub == null:
		_fail("resolved flow is missing the mouse-driven residue scrub stage",scene)
		return
	var scrub_region: Rect2 = scene.call("_project_label_region")
	var scrub_position := scrub_region.get_center()
	for stroke_index in range(90):
		var relative := Vector2(18 if stroke_index % 2 == 0 else -18,2 if stroke_index % 4 < 2 else -2)
		scrub_position += relative
		pointer.state.set_frame(true,scrub_position,relative,relative*38.0,false)
		scene.call("_process",1.0/60.0)
		pointer.clear_transients()
		if scrub.is_complete():
			break
	pointer.state.set_frame(false,scrub_position,Vector2.ZERO,Vector2.ZERO,true)
	scene.call("_process",1.0/60.0)
	if not scrub.is_complete() or residue.get_cleanup_progress() < 0.999:
		_fail("pressed back-and-forth hand motion did not rub the residue clean",scene)
		return
	if int(session.get_clean_peels()) != clean_before_resolution+1:
		_fail("scrub completion must record exactly one clean result",scene)
		return
	if not continue_button.visible:
		_fail("Continue must appear after residue cleanup completes",scene)
		return
	cursor.call("_process",1.0/60.0)
	if cursor.is_scrub_feedback_visible():
		_fail("RUB cursor feedback must retire after the residue is clean",scene)
		return

	scene.call("debug_select_variant",1)
	scene.call("_process",1.0/60.0)
	if session.get_variant_index() != 1 or float(scene.get("_controller").get_progress()) != 0.0:
		_fail("next scene did not begin with a clean neutral controller",scene)
		return
	if String(scene.get("_lifecycle").get_phase_name()) != "ATTACHED" or not released_visual.visible:
		_fail("scene boundary did not restore the attached paper presentation",scene)
		return

	print("PASS: object-only grab -> load -> peel -> settle -> next-scene flow")
	Input.set_custom_mouse_cursor(null,Input.CURSOR_POINTING_HAND)
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	scene.queue_free()
	for _frame in range(5):
		await process_frame
	controller = null
	lifecycle = null
	session = null
	pointer = null
	corner = null
	residue = null
	cursor = null
	scrub = null
	continue_button = null
	rail = null
	released_visual = null
	packed = null
	scene = null
	await process_frame
	await create_timer(0.05).timeout
	await process_frame
	quit(0)

func _fail(message: String, scene: Node = null) -> void:
	push_error("COMPLETE_FLOW_RED: %s" % message)
	if scene != null:
		scene.queue_free()
	quit(1)
