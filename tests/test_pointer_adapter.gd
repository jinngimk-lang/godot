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

	# Reset-style quarantine.
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

	# Pause-style suspension.
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

	# Multi-touch ownership.
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
		failures.append("secondary touch press must not steal gameplay pointer ownership")
	secondary.pressed = false
	adapter._unhandled_input(secondary)
	state = adapter.consume_frame()
	if not state.pressed or state.position != primary_position or state.released_this_frame:
		failures.append("secondary touch release must not release the active primary touch")

	drag.index = 0
	drag.position = Vector2(540, 245)
	drag.screen_relative = Vector2(30, -15)
	drag.screen_velocity = Vector2(620, -280)
	adapter._unhandled_input(drag)
	state = adapter.consume_frame()
	if not state.pressed or state.position != drag.position:
		failures.append("primary drag should retain ownership after secondary-touch noise")

	# Emulated mouse duplicate from touch.
	var emulated_mouse := InputEventMouseButton.new()
	emulated_mouse.device = InputEvent.DEVICE_ID_EMULATION
	emulated_mouse.button_index = MOUSE_BUTTON_LEFT
	emulated_mouse.position = Vector2(930, 510)
	emulated_mouse.pressed = true
	adapter._unhandled_input(emulated_mouse)
	state = adapter.consume_frame()
	if not state.pressed or state.position != drag.position:
		failures.append("emulated mouse press from touch must not steal active touch ownership")
	emulated_mouse.pressed = false
	adapter._unhandled_input(emulated_mouse)
	state = adapter.consume_frame()
	if not state.pressed or state.position != drag.position or state.released_this_frame:
		failures.append("emulated mouse release from touch must not release active touch ownership")

	# Hybrid-device ownership: a real mouse must not steal a real touch that
	# already owns the gameplay gesture.
	var real_mouse := InputEventMouseButton.new()
	real_mouse.device = 0
	real_mouse.button_index = MOUSE_BUTTON_LEFT
	real_mouse.position = Vector2(1010, 560)
	real_mouse.pressed = true
	adapter._unhandled_input(real_mouse)
	state = adapter.consume_frame()
	if not state.pressed or state.position != drag.position:
		failures.append("real mouse press must not steal an already-active touch gesture")
	real_mouse.pressed = false
	adapter._unhandled_input(real_mouse)
	state = adapter.consume_frame()
	if not state.pressed or state.position != drag.position or state.released_this_frame:
		failures.append("real mouse release must not release an already-active touch gesture")

	touch.position = drag.position
	touch.pressed = false
	adapter._unhandled_input(touch)
	state = adapter.consume_frame()
	if state.pressed or not state.released_this_frame:
		failures.append("primary owner release should end the gameplay pointer")
	adapter.clear_transients()

	# The inverse must also hold: once a real mouse press owns the gesture, a
	# real touch cannot teleport or release it until the mouse releases.
	real_mouse.position = Vector2(620, 320)
	real_mouse.pressed = true
	adapter._unhandled_input(real_mouse)
	state = adapter.consume_frame()
	if not state.pressed or state.position != real_mouse.position:
		failures.append("real mouse press should acquire gameplay pointer ownership")

	touch.index = 0
	touch.position = Vector2(880, 430)
	touch.pressed = true
	adapter._unhandled_input(touch)
	state = adapter.consume_frame()
	if not state.pressed or state.position != real_mouse.position:
		failures.append("touch press must not steal an already-active real mouse gesture")
	touch.pressed = false
	adapter._unhandled_input(touch)
	state = adapter.consume_frame()
	if not state.pressed or state.position != real_mouse.position or state.released_this_frame:
		failures.append("touch release must not release an already-active real mouse gesture")

	real_mouse.pressed = false
	adapter._unhandled_input(real_mouse)
	state = adapter.consume_frame()
	if state.pressed or not state.released_this_frame:
		failures.append("real mouse owner release should end the gameplay pointer")

	adapter.free()
	return failures
