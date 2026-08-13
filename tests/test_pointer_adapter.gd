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

	var required_methods := ["suspend_gameplay_input", "resume_gameplay_input", "quarantine_current_press"]
	var missing_contract := false
	for method_name in required_methods:
		if not adapter.has_method(method_name):
			failures.append("RED: PointerAdapter missing boundary quarantine method %s" % method_name)
			missing_contract = true
	if missing_contract:
		adapter.free()
		return failures

	# Reset-style quarantine: a touch that was already held must stay neutral
	# through drags until release, then a fresh press must work normally.
	touch.position = Vector2(400, 260)
	touch.pressed = true
	adapter._unhandled_input(touch)
	adapter.quarantine_current_press()
	state = adapter.consume_frame()
	if state.pressed:
		failures.append("quarantine_current_press should neutralize an already-held touch")
	drag.position = Vector2(430, 250)
	adapter._unhandled_input(drag)
	state = adapter.consume_frame()
	if state.pressed:
		failures.append("held touch drag must stay quarantined until release")
	touch.position = drag.position
	touch.pressed = false
	adapter._unhandled_input(touch)
	state = adapter.consume_frame()
	if state.pressed or state.released_this_frame:
		failures.append("quarantine release should re-arm without leaking a gameplay release transient")
	touch.pressed = true
	adapter._unhandled_input(touch)
	if not adapter.consume_frame().pressed:
		failures.append("fresh touch after quarantine release should re-arm normally")

	# Pause-style suspension: input received while suspended is tracked physically
	# but never exposed to gameplay; resuming while held waits for a release.
	adapter.suspend_gameplay_input()
	drag.position = Vector2(455, 245)
	adapter._unhandled_input(drag)
	if adapter.consume_frame().pressed:
		failures.append("suspended touch drag must not expose pressed gameplay state")
	adapter.resume_gameplay_input()
	if adapter.consume_frame().pressed:
		failures.append("resume while touch is still held must remain quarantined")
	touch.position = drag.position
	touch.pressed = false
	adapter._unhandled_input(touch)
	if adapter.consume_frame().released_this_frame:
		failures.append("resume quarantine release must not leak a gameplay release transient")
	touch.pressed = true
	adapter._unhandled_input(touch)
	if not adapter.consume_frame().pressed:
		failures.append("fresh post-resume touch should re-arm normally")

	# Multi-touch ownership: the first active touch owns the gameplay pointer
	# until it releases. A second finger must not teleport or release that pointer.
	touch.index = 0
	touch.pressed = false
	adapter._unhandled_input(touch)
	adapter.clear_transients()
	var primary_position := Vector2(510, 260)
	touch.position = primary_position
	touch.pressed = true
	adapter._unhandled_input(touch)
	state = adapter.consume_frame()
	if not state.pressed or state.position != primary_position:
		failures.append("primary touch should acquire gameplay pointer ownership")

	var secondary := InputEventScreenTouch.new()
	secondary.index = 1
	secondary.position = Vector2(810, 470)
	secondary.pressed = true
	adapter._unhandled_input(secondary)
	state = adapter.consume_frame()
	if not state.pressed or state.position != primary_position:
		failures.append("RED: secondary touch press must not steal gameplay pointer ownership")

	secondary.pressed = false
	adapter._unhandled_input(secondary)
	state = adapter.consume_frame()
	if not state.pressed or state.position != primary_position or state.released_this_frame:
		failures.append("RED: secondary touch release must not release the active primary touch")

	drag.index = 0
	drag.position = Vector2(540, 245)
	drag.screen_relative = Vector2(30, -15)
	drag.screen_velocity = Vector2(620, -280)
	adapter._unhandled_input(drag)
	state = adapter.consume_frame()
	if not state.pressed or state.position != drag.position:
		failures.append("primary drag should retain ownership after secondary-touch noise")

	touch.position = drag.position
	touch.pressed = false
	adapter._unhandled_input(touch)
	state = adapter.consume_frame()
	if state.pressed or not state.released_this_frame:
		failures.append("primary owner release should end the gameplay pointer")

	adapter.free()
	return failures
