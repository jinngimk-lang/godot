extends RefCounted
class_name PeelController

signal completed
signal state_changed(name: String)

enum State { IDLE, EDGE_HOVER, EDGE_LIFT, PINCHED, PEELING, RELEASED, COMPLETE }

var _state: State = State.IDLE
var _model: PeelModel
var _edge_position := Vector2.ZERO
var _grab_region := Rect2()
var _grab_origin := Vector2.ZERO
var _hand_position := Vector2.ZERO
var _edge_radius := 30.0
var _regrab_edge_radius := 34.0
var _lift_distance := 10.0
var _minimum_lift_hold := 0.08
var _lift_elapsed := 0.0
var _tension_per_pixel := 0.65
var _hand_follow_rate := 14.0
var _motion_pixels_per_release := 2.4

func _init(model_config: Dictionary = {}) -> void:
	_motion_pixels_per_release = clampf(float(model_config.get("motion_pixels_per_release",2.4)),1.2,8.0)
	_model = PeelModel.new(model_config)

func reset() -> void:
	_model.reset()
	_state = State.IDLE
	_grab_origin = Vector2.ZERO
	_hand_position = _edge_position
	_lift_elapsed = 0.0

func set_edge_position(screen_position: Vector2) -> void:
	_edge_position = screen_position
	if _state in [State.IDLE, State.EDGE_HOVER, State.RELEASED]:
		_hand_position = screen_position

func set_grab_region(screen_region: Rect2) -> void:
	_grab_region = screen_region.abs()
	if _model.get_progress() <= 0.001 and _grab_region.size.x > 0.0 and _grab_region.size.y > 0.0 and _state in [State.IDLE,State.EDGE_HOVER,State.RELEASED]:
		_edge_position = _grab_region.position+Vector2(_grab_region.size.x,0.0)
		_hand_position = _edge_position

func process_pointer(pointer: PointerState, delta: float) -> Dictionary:
	var can_grab := _can_grab(pointer.position)
	match _state:
		State.IDLE:
			if pointer.pressed and can_grab: _begin_lift(pointer.position)
			elif can_grab: _set_state(State.EDGE_HOVER)
		State.EDGE_HOVER:
			if pointer.pressed and can_grab: _begin_lift(pointer.position)
			elif not can_grab: _set_state(State.IDLE)
		State.EDGE_LIFT:
			_update_hand(pointer.position, delta)
			_lift_elapsed += clampf(delta if is_finite(delta) else 0.0, 0.0, 0.1)
			if not pointer.pressed:
				_set_state(State.RELEASED)
			elif pointer.position.distance_to(_grab_origin) >= _lift_distance and _lift_elapsed >= _minimum_lift_hold:
				_set_state(State.PINCHED)
		State.PINCHED:
			_update_hand(pointer.position, delta)
			if pointer.released_this_frame or not pointer.pressed:
				_set_state(State.RELEASED)
			else:
				_set_state(State.PEELING)
				_advance_peel(pointer, delta)
		State.PEELING:
			_update_hand(pointer.position, delta)
			if pointer.released_this_frame or not pointer.pressed:
				_set_state(State.RELEASED)
			else:
				_advance_peel(pointer, delta)
		State.RELEASED:
			_update_hand(_edge_position, delta)
			if pointer.pressed and can_grab: _begin_lift(pointer.position)
			elif can_grab: _set_state(State.EDGE_HOVER)
		State.COMPLETE:
			_update_hand(pointer.position, delta)

	return {
		"state": get_state_name(),
		"progress": _model.get_progress(),
		"hand_position": _hand_position,
		"bond_load": _model.get_bond_load(),
		"integrity": _model.get_integrity(),
		"residue": _model.get_residue()
	}

func get_progress() -> float: return _model.get_progress()
func get_bond_load() -> float: return _model.get_bond_load()
func get_integrity() -> float: return _model.get_integrity()
func get_residue() -> float: return _model.get_residue()
func is_complete() -> bool: return _model.is_complete()
func get_hand_position() -> Vector2: return _hand_position
func get_edge_position() -> Vector2: return _edge_position
func get_state_name() -> String: return State.keys()[_state]
func get_model_config() -> Dictionary: return _model.get_config()
func get_motion_pixels_per_release() -> float: return _motion_pixels_per_release

func _can_grab(position: Vector2) -> bool:
	if _model.get_progress() > 0.001:
		if _grab_region.size.x > 0.0 and _grab_region.size.y > 0.0 and _grab_region.grow(7.0).has_point(position): return true
		return position.distance_to(_edge_position) <= _regrab_edge_radius
	return position.distance_to(_edge_position) <= _edge_radius

func _begin_lift(position: Vector2) -> void:
	_grab_origin = position
	_hand_position = position
	_lift_elapsed = 0.0
	_set_state(State.EDGE_LIFT)

func _advance_peel(pointer: PointerState, delta: float) -> void:
	var pull_vec: Vector2 = _hand_position - _grab_origin
	var tension := pull_vec.length() * _tension_per_pixel
	var speed := pointer.velocity.length() / 100.0
	var peel_angle := absf(atan2(pull_vec.y, pull_vec.x))
	var pull_direction := pull_vec.normalized() if pull_vec.length_squared() > 0.000001 else Vector2.ZERO
	var outward_pixels := maxf(pointer.relative.dot(pull_direction), 0.0)
	var motion_gate := clampf(outward_pixels / _motion_pixels_per_release, 0.0, 1.0)
	var result: Dictionary = _model.step(tension, speed, peel_angle, delta, motion_gate)
	if bool(result["completed_now"]):
		_set_state(State.COMPLETE)
		completed.emit()

func _update_hand(target: Vector2, delta: float) -> void:
	var safe_delta := clampf(delta, 0.0, 0.1)
	var weight := 1.0 - exp(-_hand_follow_rate * safe_delta)
	_hand_position = _hand_position.lerp(target, weight)

func _set_state(next: State) -> void:
	if _state == next: return
	_state = next
	state_changed.emit(get_state_name())
