extends RefCounted

func run() -> Array[String]:
	var failures: Array[String] = []
	var controller_script = load("res://scripts/peel/peel_controller.gd")
	var pointer_script = load("res://scripts/input/pointer_state.gd")
	if controller_script == null or pointer_script == null:
		failures.append("controller dependencies did not load")
		return failures

	var controller = controller_script.new({"base_adhesion": 8.0, "release_increment": 0.2})
	controller.set_edge_position(Vector2(100, 100))
	var pointer = pointer_script.new()
	pointer.set_frame(false, Vector2(100, 100), Vector2.ZERO, Vector2.ZERO, false)
	controller.process_pointer(pointer, 0.016)
	if controller.get_state_name() != "EDGE_HOVER":
		failures.append("pointer near edge should enter EDGE_HOVER")

	pointer.set_frame(true, Vector2(100, 100), Vector2.ZERO, Vector2.ZERO, false)
	controller.process_pointer(pointer, 0.016)
	if controller.get_state_name() != "EDGE_LIFT":
		failures.append("press on edge should enter EDGE_LIFT")

	pointer.set_frame(true, Vector2(128, 82), Vector2(28, -18), Vector2(900, -500), false)
	controller.process_pointer(pointer, 0.016)
	controller.process_pointer(pointer, 0.016)
	if controller.get_progress() <= 0.0:
		failures.append("drag after edge lift should begin progressive peel")

	var before_release: float = controller.get_progress()
	pointer.set_frame(false, pointer.position, Vector2.ZERO, Vector2.ZERO, true)
	controller.process_pointer(pointer, 0.016)
	if controller.get_progress() < before_release:
		failures.append("releasing grip must not reverse peel progress")

	controller.set_edge_position(pointer.position)
	pointer.set_frame(true, pointer.position, Vector2(1, 0), Vector2(100, 0), false)
	controller.process_pointer(pointer, 0.016)
	for i in range(32):
		var pos := Vector2(220 + i * 3, 40)
		pointer.set_frame(true, pos, Vector2(3, 0), Vector2(1200, -400), false)
		controller.process_pointer(pointer, 0.016)
	if not controller.is_complete() or controller.get_state_name() != "COMPLETE":
		failures.append("sustained high pull should complete exactly one peel session")
	return failures
