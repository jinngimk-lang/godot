extends RefCounted
class_name PointerState

var pressed := false
var position := Vector2.ZERO
var relative := Vector2.ZERO
var velocity := Vector2.ZERO
var released_this_frame := false

func set_frame(is_pressed: bool, new_position: Vector2, new_relative: Vector2, new_velocity: Vector2, released: bool) -> void:
	pressed = is_pressed
	position = new_position
	relative = new_relative
	velocity = new_velocity
	released_this_frame = released

func clear_transients() -> void:
	relative = Vector2.ZERO
	velocity = Vector2.ZERO
	released_this_frame = false
