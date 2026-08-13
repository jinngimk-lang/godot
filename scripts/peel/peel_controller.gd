extends RefCounted
class_name PeelController

signal completed
signal state_changed(name: String)

enum State { IDLE, EDGE_HOVER, EDGE_LIFT, PINCHED, PEELING, RELEASED, COMPLETE }

var _state: State = State.IDLE
var _model: PeelModel
var _edge_position := Vector2.ZERO
var _grab_origin := Vector2.ZERO
var _hand_position := Vector2.ZERO
var _edge_radius := 34.0
var _lift_distance := 4.0
var _tension_per_pixel := 0.65
var _hand_follow_rate := 14.0

func _init(model_config: Dictionary = {}) -> void:
	_model = PeelModel.new(model_config)

func reset() -> void:
	_model.reset()
	_state = State.IDLE
	_grab_origin = Vector2.ZERO
	_hand_position = _edge_position

func set_edge_position(screen_position: Vector2) -> void:
	_edge_position = screen_position
	if _state in [State.IDLE, State.EDGE_HOVER, State.RELEASED]:
		_hand_position = screen_position

func process_pointer(pointer: PointerState, delta: float) -> Dictionary:
	var distance_to_edge := pointer.position.distance_to(_edge_position)
	match _state:
		State.IDLE:
			if distance_to_edge <= _edge_radius:
				_set_state(State.EDGE_HOVER)
		State.EDGE_HOVER:
			if distance_to_edge > _edge_radius * 1.35:
				_set_state(State.IDLE)
			elif pointer.pressed:
				_grab_origin = pointer.position
				_hand_position = pointer.position
				_set_state(State.EDGE_LIFT)
		State.EDGE_LIFT:
			_update_hand(pointer.position, delta)
			if not pointer.pressed:
				_set_state(State.EDGE_HOVER)
			elif pointer.position.distance_to(_grab_origin) >= _lift_distance:
				_set_state(State.PINCHED)
		State.PINCHED:
			_update_hand(pointer.position, delta)
			if pointer.released_this_frame or not pointer.pressed:
				_set_state(State.RELEASED)
			else:
				_set_state(State.PEELING)
		State.PEELING:
			_update_hand(pointer.position, delta)
			if pointer.released_this_frame or not pointer.pressed:
				_set_state(State.RELEASED)
			else:
				var pull_vec := _hand_position - _edge_position
				var tension := pull_vec.length() * _tension_per_pixel
				var speed := pointer.velocity.length() / 100.0
				var peel_angle := absf(atan2(pull_vec.y, pull_vec.x))
				var result := _model.step(tension, speed, peel_angle, delta)
				if result.completed_now:
					_set_state(State.COMPLETE)
					completed.emit()
		State.RELEASED:
			_update_hand(_edge_position, delta)
			if pointer.pressed and distance_to_edge <= _edge_radius * 1.5:
				_grab_origin = pointer.position
				_set_state(State.PINCHED)
			elif distance_to_edge <= _edge_radius:
				_set_state(State.EDGE_HOVER)
		State.COMPLETE:
			_update_hand(pointer.position, delta)

	return {
		"state": get_state_name(),
		"progress": _model.get_progress(),
		"hand_position": _hand_position
	}

func get_progress() -> float:
	return _model.get_progress()

func is_complete() -> bool:
	return _model.is_complete()

func get_hand_position() -> Vector2:
	return _hand_position

func get_state_name() -> String:
	return State.keys()[_state]

func _update_hand(target: Vector2, delta: float) -> void:
	var safe_delta := clampf(delta, 0.0, 0.1)
	var weight := 1.0 - exp(-_hand_follow_rate * safe_delta)
	_hand_position = _hand_position.lerp(target, weight)

func _set_state(next: State) -> void:
	if _state == next:
		return
	_state = next
	state_changed.emit(get_state_name())
