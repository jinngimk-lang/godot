extends RefCounted

func run() -> Array[String]:
	var failures: Array[String] = []
	var adapter := PointerAdapter.new()

	var primary := InputEventScreenTouch.new()
	primary.index = 0
	primary.position = Vector2(410, 260)
	primary.pressed = true
	adapter._unhandled_input(primary)
	if not adapter.consume_frame().pressed:
		failures.append("fixture: primary touch failed to acquire ownership")
		adapter.free()
		return failures

	# Finger 1 becomes a known secondary while finger 0 owns the gesture, then
	# remains physically held when finger 0 releases.
	var secondary := InputEventScreenTouch.new()
	secondary.index = 1
	secondary.position = Vector2(770, 470)
	secondary.pressed = true
	adapter._unhandled_input(secondary)

	primary.pressed = false
	adapter._unhandled_input(primary)
	var state := adapter.consume_frame()
	if state.pressed or not state.released_this_frame:
		failures.append("fixture: primary owner release must end gameplay gesture")
		adapter.free()
		return failures
	adapter.clear_transients()

	# The still-held secondary finger has never produced a new press. Its drag
	# must stay ignored; otherwise it silently inherits the just-ended gesture.
	var lingering_drag := InputEventScreenDrag.new()
	lingering_drag.index = 1
	lingering_drag.position = Vector2(790, 455)
	lingering_drag.screen_relative = Vector2(20, -15)
	lingering_drag.screen_velocity = Vector2(300, -200)
	adapter._unhandled_input(lingering_drag)
	state = adapter.consume_frame()
	if state.pressed:
		failures.append("RED: still-held secondary touch must not inherit ownership through drag after primary release")

	# Once the ignored finger actually releases, a genuinely fresh press from
	# that index may become the next owner.
	secondary.position = lingering_drag.position
	secondary.pressed = false
	adapter._unhandled_input(secondary)
	adapter.clear_transients()
	secondary.pressed = true
	adapter._unhandled_input(secondary)
	state = adapter.consume_frame()
	if not state.pressed or state.position != secondary.position:
		failures.append("fresh press after ignored-secondary release should acquire ownership")

	adapter.free()
	return failures
