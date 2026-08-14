extends RefCounted

var _completion_count := 0

func run() -> Array[String]:
	var failures: Array[String] = []
	var controller_script = load("res://scripts/peel/peel_controller.gd")
	var pointer_script = load("res://scripts/input/pointer_state.gd")
	if controller_script == null or pointer_script == null:
		failures.append("controller dependencies did not load")
		return failures

	_completion_count = 0
	var controller = controller_script.new({"base_adhesion":8.0,"release_increment":0.2,"bond_response":12.0})
	controller.completed.connect(_on_completed)
	controller.set_edge_position(Vector2(100,100))
	if not controller.has_method("set_grab_region"):
		failures.append("RED: controller must accept projected label grab region")
		return failures
	controller.set_grab_region(Rect2(Vector2(70,70), Vector2(130,70)))
	var pointer = pointer_script.new()

	pointer.set_frame(true, Vector2(170,100), Vector2.ZERO, Vector2.ZERO, false)
	var anywhere: Dictionary = controller.process_pointer(pointer, 0.016)
	if controller.get_state_name() != "EDGE_LIFT":
		failures.append("RED: press anywhere on label surface should immediately begin lift")

	pointer.set_frame(true, Vector2(205,78), Vector2(35,-22), Vector2(900,-500), false)
	for _i in range(5):
		anywhere = controller.process_pointer(pointer, 0.016)
	if controller.get_progress() <= 0.0:
		failures.append("sustained drag after arbitrary label grab should begin progressive peel")
	for key in ["bond_load","integrity","residue"]:
		if not anywhere.has(key):
			failures.append("RED: controller output missing physical quality field %s" % key)

	var before_release: float = float(controller.get_progress())
	pointer.set_frame(false, pointer.position, Vector2.ZERO, Vector2.ZERO, true)
	controller.process_pointer(pointer, 0.016)
	if controller.get_progress() < before_release:
		failures.append("releasing grip must not reverse peel progress")

	pointer.set_frame(true, Vector2(135,92), Vector2.ZERO, Vector2.ZERO, false)
	controller.process_pointer(pointer, 0.016)
	for i in range(70):
		var pos := Vector2(170 + i * 3, 42)
		pointer.set_frame(true, pos, Vector2(3,0), Vector2(1200,-400), false)
		controller.process_pointer(pointer, 0.016)
	if not controller.is_complete() or controller.get_state_name() != "COMPLETE":
		failures.append("sustained high pull should complete exactly one peel session")
	if _completion_count != 1:
		failures.append("controller completion signal expected once, got %d" % _completion_count)

	controller.reset()
	if not is_equal_approx(controller.get_progress(), 0.0) or controller.get_state_name() != "IDLE":
		failures.append("controller reset must restore progress and IDLE state")
	return failures

func _on_completed() -> void:
	_completion_count += 1
