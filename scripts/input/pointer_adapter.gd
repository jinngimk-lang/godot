extends Node
class_name PointerAdapter

signal pointer_changed(state: PointerState)

enum PointerSource { NONE, MOUSE, TOUCH }

var state := PointerState.new()
var _gameplay_suspended := false
var _awaiting_release := false
var _physical_pressed := false
var _active_source := PointerSource.NONE
var _active_touch_index := -1

func suspend_gameplay_input() -> void:
	_gameplay_suspended = true
	_neutralize_state(state.position)

func resume_gameplay_input() -> void:
	_gameplay_suspended = false
	_awaiting_release = _physical_pressed
	_neutralize_state(state.position)

func quarantine_current_press() -> void:
	_awaiting_release = _physical_pressed or state.pressed
	_neutralize_state(state.position)

func _unhandled_input(event: InputEvent) -> void:
	# Godot can synthesize mouse events from touch. Real touch is already handled
	# directly below, so the emulated duplicate must never become a second source.
	if event is InputEventMouseButton and event.device == InputEvent.DEVICE_ID_EMULATION:
		return
	if event is InputEventMouseMotion and event.device == InputEvent.DEVICE_ID_EMULATION:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			# A fresh button press is the only way mouse ownership can begin.
			if _active_source == PointerSource.TOUCH:
				return
			_active_source = PointerSource.MOUSE
			_physical_pressed = true
			if _consume_boundary_event(true, event.position):
				return
			state.set_frame(true, event.position, Vector2.ZERO, Vector2.ZERO, false)
			pointer_changed.emit(state)
			return

		# A release may only end an already-owned mouse gesture. A neutral mouse-up
		# with no owner may still update hover position, but it must not manufacture
		# a gameplay release. While touch owns, even its position is ignored.
		if _active_source == PointerSource.TOUCH:
			return
		if _active_source == PointerSource.NONE:
			_physical_pressed = false
			if _consume_boundary_event(false, event.position):
				return
			state.set_frame(false, event.position, Vector2.ZERO, Vector2.ZERO, false)
			pointer_changed.emit(state)
			return
		_physical_pressed = false
		_active_source = PointerSource.NONE
		if _consume_boundary_event(false, event.position):
			return
		state.set_frame(false, event.position, Vector2.ZERO, Vector2.ZERO, true)
		pointer_changed.emit(state)
		return

	if event is InputEventMouseMotion:
		if _active_source == PointerSource.TOUCH:
			return
		if _active_source == PointerSource.MOUSE:
			_physical_pressed = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
			if _consume_boundary_event(_physical_pressed, event.position):
				return
			state.set_frame(
				_physical_pressed,
				event.position,
				event.relative,
				event.velocity,
				false
			)
			pointer_changed.emit(state)
			return

		# Motion alone never creates ownership. It still updates hover position,
		# but remains neutral even if another physical button is lingering down.
		_physical_pressed = false
		if _consume_boundary_event(false, event.position):
			return
		state.set_frame(false, event.position, event.relative, event.velocity, false)
		pointer_changed.emit(state)
		return

	if event is InputEventScreenTouch:
		if event.pressed:
			# A fresh touch press is the only way touch ownership can begin.
			if _active_source == PointerSource.MOUSE:
				return
			if _active_source == PointerSource.NONE:
				_active_source = PointerSource.TOUCH
				_active_touch_index = event.index
			elif event.index != _active_touch_index:
				return
			_physical_pressed = true
			if _consume_boundary_event(true, event.position):
				return
			state.set_frame(true, event.position, Vector2.ZERO, Vector2.ZERO, false)
			pointer_changed.emit(state)
			return

		# Secondary/lingering releases are ignored. Only the current owner can
		# release the gameplay pointer.
		if _active_source != PointerSource.TOUCH or event.index != _active_touch_index:
			return
		_physical_pressed = false
		_active_touch_index = -1
		_active_source = PointerSource.NONE
		if _consume_boundary_event(false, event.position):
			return
		state.set_frame(false, event.position, Vector2.ZERO, Vector2.ZERO, true)
		pointer_changed.emit(state)
		return

	if event is InputEventScreenDrag:
		# Crucial ownership invariant: drag can update an existing touch owner but
		# can never create ownership. This prevents a secondary finger that stayed
		# held through the primary release from silently inheriting the gesture.
		if _active_source != PointerSource.TOUCH or event.index != _active_touch_index:
			return
		_physical_pressed = true
		if _consume_boundary_event(true, event.position):
			return
		state.set_frame(true, event.position, event.screen_relative, event.screen_velocity, false)
		pointer_changed.emit(state)

func consume_frame() -> PointerState:
	return state

func clear_transients() -> void:
	state.clear_transients()

func _consume_boundary_event(is_pressed: bool, position: Vector2) -> bool:
	if _gameplay_suspended:
		_neutralize_state(position)
		pointer_changed.emit(state)
		return true
	if _awaiting_release:
		if not is_pressed:
			_awaiting_release = false
		_neutralize_state(position)
		pointer_changed.emit(state)
		return true
	return false

func _neutralize_state(position: Vector2) -> void:
	state.set_frame(false, position, Vector2.ZERO, Vector2.ZERO, false)
