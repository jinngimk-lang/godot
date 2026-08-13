extends RefCounted

func run() -> Array[String]:
	var failures: Array[String] = []
	var script = load("res://scripts/input/pointer_state.gd")
	if script == null:
		failures.append("PointerState script did not load")
		return failures
	var state = script.new()
	if state.pressed or state.released_this_frame:
		failures.append("pointer defaults must be inactive")
	state.set_frame(true, Vector2(10, 20), Vector2(2, 3), Vector2(100, 150), false)
	if not state.pressed or state.position != Vector2(10, 20) or state.relative != Vector2(2, 3):
		failures.append("pointer frame values were not preserved")
	state.set_frame(false, state.position, Vector2.ZERO, Vector2.ZERO, true)
	if not state.released_this_frame:
		failures.append("pointer release transient was not preserved")
	state.clear_transients()
	if state.released_this_frame or state.relative != Vector2.ZERO:
		failures.append("pointer transients did not clear")
	return failures
