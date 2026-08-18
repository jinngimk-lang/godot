extends RefCounted

var _completion_count := 0

func run() -> Array[String]:
	var failures: Array[String] = []
	var controller_script = load("res://scripts/peel/peel_controller.gd")
	var pointer_script = load("res://scripts/input/pointer_state.gd")
	if controller_script == null or pointer_script == null:
		failures.append("controller dependencies did not load")
		return failures

	var grab_region := Rect2(Vector2(70,70),Vector2(130,70))

	# Object-only reference contract: a casual press in the middle of a fresh
	# label must not start a peel. set_grab_region() advertises the visible
	# top-right corner as the first-grab edge, matching CornerPeelPresentation.
	var gate_controller = controller_script.new({"base_adhesion":8.0,"release_increment":0.04,"bond_response":12.0})
	gate_controller.set_edge_position(Vector2(100,100))
	gate_controller.set_grab_region(grab_region)
	var gate_pointer = pointer_script.new()
	gate_pointer.set_frame(true, grab_region.get_center(), Vector2.ZERO, Vector2.ZERO, false)
	gate_controller.process_pointer(gate_pointer,0.016)
	if gate_controller.get_state_name() != "IDLE":
		failures.append("PEEL_ENTRY_RED: fresh label center press must stay IDLE; first grab belongs to the visible top-right corner")
	if gate_controller.get_progress() > 0.0:
		failures.append("PEEL_ENTRY_RED: fresh label center press must not release adhesive")

	_completion_count = 0
	var controller = controller_script.new({"base_adhesion":8.0,"release_increment":0.04,"bond_response":12.0})
	controller.completed.connect(_on_completed)
	controller.set_edge_position(Vector2(100,100))
	if not controller.has_method("set_grab_region") or not controller.has_method("get_edge_position"):
		failures.append("controller must expose projected label region and visible corner edge")
		return failures
	controller.set_grab_region(grab_region)
	var edge: Vector2 = controller.get_edge_position()
	var pointer = pointer_script.new()

	# A true top-right corner press starts lift authoring, but a tiny 6 px twitch
	# must remain an edge lift instead of immediately arming PINCHED/PEELING.
	pointer.set_frame(true,edge,Vector2.ZERO,Vector2.ZERO,false)
	controller.process_pointer(pointer,0.016)
	if controller.get_state_name() != "EDGE_LIFT":
		failures.append("visible corner press should enter EDGE_LIFT")
	pointer.set_frame(true,edge+Vector2(6,0),Vector2(6,0),Vector2(375,0),false)
	controller.process_pointer(pointer,0.016)
	if controller.get_state_name() != "EDGE_LIFT":
		failures.append("PEEL_ENTRY_RED: tiny first motion must stay EDGE_LIFT instead of arming peel")
	if controller.get_progress() > 0.0:
		failures.append("PEEL_ENTRY_RED: adhesive progress must stay zero during first-lift arming")

	# Deliberate hold + lift arms the pinch. Feed a modest diagonal pull away from
	# the visible corner long enough to make the interaction intentional.
	for _i in range(6):
		pointer.set_frame(true,edge+Vector2(14,-4),Vector2(1,-1),Vector2(90,-90),false)
		controller.process_pointer(pointer,0.016)
	if controller.get_state_name() not in ["PINCHED","PEELING"]:
		failures.append("deliberate corner lift should arm PINCHED/PEELING after a short tactile dwell")

	var peel_result: Dictionary = {}
	for i in range(10):
		var pos := edge+Vector2(22+i*4,-18-i)
		pointer.set_frame(true,pos,Vector2(4,-1),Vector2(650,-180),false)
		peel_result = controller.process_pointer(pointer,0.016)
	if controller.get_progress() <= 0.0:
		failures.append("sustained drag after deliberate corner lift should begin progressive peel")
	if controller.is_complete():
		failures.append("test precondition: short deliberate pull must remain partial before re-grab")
	for key in ["bond_load","integrity","residue"]:
		if not peel_result.has(key):
			failures.append("controller output missing physical quality field %s" % key)

	# Once some material is already lifted, re-grabbing the visible label surface
	# remains forgiving; the strict corner gate only applies to the first peel.
	var before_release: float = float(controller.get_progress())
	pointer.set_frame(false,pointer.position,Vector2.ZERO,Vector2.ZERO,true)
	controller.process_pointer(pointer,0.016)
	if controller.get_progress() < before_release:
		failures.append("releasing grip must not reverse peel progress")
	pointer.set_frame(true,grab_region.get_center(),Vector2.ZERO,Vector2.ZERO,false)
	controller.process_pointer(pointer,0.016)
	if controller.get_state_name() != "EDGE_LIFT":
		failures.append("partially peeled label should remain easy to re-grab on its visible surface")

	for _i in range(6):
		pointer.set_frame(true,Vector2(184,90),Vector2(1,-1),Vector2(100,-100),false)
		controller.process_pointer(pointer,0.016)
	for i in range(110):
		var pos := Vector2(190+i*3,42)
		pointer.set_frame(true,pos,Vector2(3,0),Vector2(1200,-400),false)
		controller.process_pointer(pointer,0.016)
		if controller.is_complete():
			break
	if not controller.is_complete() or controller.get_state_name() != "COMPLETE":
		failures.append("sustained high pull should complete exactly one peel session")
	if _completion_count != 1:
		failures.append("controller completion signal expected once, got %d" % _completion_count)

	controller.reset()
	if not is_equal_approx(controller.get_progress(),0.0) or controller.get_state_name() != "IDLE":
		failures.append("controller reset must restore progress and IDLE state")
	return failures

func _on_completed() -> void:
	_completion_count += 1
