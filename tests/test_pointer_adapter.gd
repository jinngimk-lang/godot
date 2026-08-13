extends RefCounted

func run() -> Array[String]:
	var failures: Array[String] = []
	var adapter_script = load("res://scripts/input/pointer_adapter.gd")
	if adapter_script == null:
		failures.append("PointerAdapter script did not load")
		return failures

	var adapter = adapter_script.new()

	var touch := InputEventScreenTouch.new()
	touch.index = 0
	touch.position = Vector2(320, 240)
	touch.pressed = true
	adapter._unhandled_input(touch)
	var state: PointerState = adapter.consume_frame()
	if not state.pressed:
		failures.append("screen touch press should set pointer pressed")
	if state.position != Vector2(320, 240):
		failures.append("screen touch press should preserve viewport position")
	if state.released_this_frame:
		failures.append("screen touch press must not mark release transient")

	var drag := InputEventScreenDrag.new()
	drag.index = 0
	drag.position = Vector2(348, 222)
	drag.screen_relative = Vector2(28, -18)
	drag.screen_velocity = Vector2(900, -500)
	adapter._unhandled_input(drag)
	state = adapter.consume_frame()
	if not state.pressed:
		failures.append("screen drag should keep pointer pressed")
	if state.position != drag.position:
		failures.append("screen drag should preserve viewport position")
	if state.relative != drag.screen_relative:
		failures.append("screen drag should use unscaled screen_relative")
	if state.velocity != drag.screen_velocity:
		failures.append("screen drag should use unscaled screen_velocity")

	touch.position = drag.position
	touch.pressed = false
	adapter._unhandled_input(touch)
	state = adapter.consume_frame()
	if state.pressed:
		failures.append("screen touch release should clear pointer pressed")
	if not state.released_this_frame:
		failures.append("screen touch release should set release transient")

	adapter.clear_transients()
	state = adapter.consume_frame()
	if state.released_this_frame or state.relative != Vector2.ZERO or state.velocity != Vector2.ZERO:
		failures.append("clear_transients should clear release, relative and velocity only")

	# Pause/suspend must ignore pointer activity and require a release only when
	# the boundary ends while a pointer is still held.
	adapter.suspend_input()
	touch.position = Vector2(400, 260)
	touch.pressed = true
	adapter._unhandled_input(touch)
	state = adapter.consume_frame()
	if state.pressed:
		failures.append("suspended input must not latch a touch press")

	drag.position = Vector2(430, 250)
	drag.screen_relative = Vector2(30, -10)
	drag.screen_velocity = Vector2(700, -300)
	adapter._unhandled_input(drag)
	state = adapter.consume_frame()
	if state.pressed or state.relative != Vector2.ZERO or state.velocity != Vector2.ZERO:
		failures.append("suspended input must quarantine touch drag motion")

	adapter.resume_input()
	adapter._unhandled_input(drag)
	state = adapter.consume_frame()
	if state.pressed:
		failures.append("resume while touch is held must stay quarantined until release")

	touch.position = drag.position
	touch.pressed = false
	adapter._unhandled_input(touch)
	state = adapter.consume_frame()
	if state.pressed or state.released_this_frame:
		failures.append("boundary-clearing release must not leak as gameplay release")

	touch.position = Vector2(460, 245)
	touch.pressed = true
	adapter._unhandled_input(touch)
	state = adapter.consume_frame()
	if not state.pressed:
		failures.append("fresh press after boundary release should re-arm pointer input")

	# Reset quarantine must clear a held pointer immediately, ignore drag while
	# still held, and re-arm after the physical release.
	adapter.quarantine_until_release()
	state = adapter.consume_frame()
	if state.pressed:
		failures.append("quarantine_until_release must neutralize a held pointer")
	adapter._unhandled_input(drag)
	state = adapter.consume_frame()
	if state.pressed:
		failures.append("quarantined drag must not re-latch pointer press")
	touch.position = drag.position
	touch.pressed = false
	adapter._unhandled_input(touch)
	touch.position = Vector2(480, 240)
	touch.pressed = true
	adapter._unhandled_input(touch)
	state = adapter.consume_frame()
	if not state.pressed:
		failures.append("pointer should accept a fresh press after quarantine release")

	adapter.free()
	return failures
