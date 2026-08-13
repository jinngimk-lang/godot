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
	if event is InputEventMouseButton and event.device == InputEvent.DEVICE_ID_EMULATION:
		return

	if event is InputEventMouseMotion and event.device == InputEvent.DEVICE_ID_EMULATION:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if _active_source == PointerSource.TOUCH:
				return
			_active_source = PointerSource.MOUSE
			_physical_pressed = true
			if _consume_boundary_event(true, event.position):
				return
			state.set_frame(true, event.position, Vector2.ZERO, Vector2.ZERO, false)
			pointer_changed.emit(state)
			return

		if _active_source == PointerSource.TOUCH:
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
		# Motion may continue an already-owned mouse gesture, but it must never
		# establish ownership after a competing source's press was ignored.
		_physical_pressed = _active_source == PointerSource.MOUSE
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

	if event is InputEventScreenTouch:
		if event.pressed:
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
		# A drag is continuation evidence, never a fresh ownership event. This
		# prevents an ignored still-held secondary finger from inheriting the
		# gesture after the previous owner releases.
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
