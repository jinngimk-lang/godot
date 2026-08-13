extends Node
class_name PointerAdapter

signal pointer_changed(state: PointerState)

var state := PointerState.new()
var _suspended := false
var _require_release := false
var _suspended_pressed := false

func suspend_input() -> void:
	_suspended = true
	_suspended_pressed = state.pressed
	_neutralize(state.position)

func resume_input() -> void:
	var held_across_boundary := _suspended_pressed or state.pressed
	_suspended = false
	_suspended_pressed = false
	_require_release = _require_release or held_across_boundary
	_neutralize(state.position)

func quarantine_until_release() -> void:
	_require_release = _require_release or state.pressed
	_neutralize(state.position)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_button(event.pressed, event.position)
		return

	if event is InputEventMouseMotion:
		if _suspended:
			_neutralize(event.position)
			pointer_changed.emit(state)
			return
		if _require_release:
			if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
				_require_release = false
			_neutralize(event.position)
			pointer_changed.emit(state)
			return
		state.set_frame(
			Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT),
			event.position,
			event.relative,
			event.velocity,
			false
		)
		pointer_changed.emit(state)
		return

	if event is InputEventScreenTouch:
		_handle_button(event.pressed, event.position)
		return

	if event is InputEventScreenDrag:
		if _suspended or _require_release:
			_neutralize(event.position)
			pointer_changed.emit(state)
			return
		state.set_frame(true, event.position, event.screen_relative, event.screen_velocity, false)
		pointer_changed.emit(state)

func consume_frame() -> PointerState:
	return state

func clear_transients() -> void:
	state.clear_transients()

func _handle_button(is_pressed: bool, position: Vector2) -> void:
	if _suspended:
		_suspended_pressed = is_pressed
		_neutralize(position)
		pointer_changed.emit(state)
		return
	if _require_release:
		if not is_pressed:
			_require_release = false
		_neutralize(position)
		pointer_changed.emit(state)
		return
	state.set_frame(is_pressed, position, Vector2.ZERO, Vector2.ZERO, not is_pressed)
	pointer_changed.emit(state)

func _neutralize(position: Vector2) -> void:
	state.set_frame(false, position, Vector2.ZERO, Vector2.ZERO, false)
