extends Node
class_name PointerAdapter

signal pointer_changed(state: PointerState)

var state := PointerState.new()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		state.set_frame(event.pressed, event.position, Vector2.ZERO, Vector2.ZERO, not event.pressed)
		pointer_changed.emit(state)
		return

	if event is InputEventMouseMotion:
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
		state.set_frame(event.pressed, event.position, Vector2.ZERO, Vector2.ZERO, not event.pressed)
		pointer_changed.emit(state)
		return

	if event is InputEventScreenDrag:
		state.set_frame(true, event.position, event.screen_relative, event.screen_velocity, false)
		pointer_changed.emit(state)

func consume_frame() -> PointerState:
	return state

func clear_transients() -> void:
	state.clear_transients()
