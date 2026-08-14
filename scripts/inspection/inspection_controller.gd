extends RefCounted
class_name InspectionController

var _active := false
var _yaw := 0.0
var _target_yaw := 0.0
var _sensitivity: float
var _follow_rate: float

func _init(config: Dictionary = {}) -> void:
	_sensitivity = clampf(float(config.get("sensitivity", 0.006)), 0.0001, 0.05)
	_follow_rate = clampf(float(config.get("follow_rate", 18.0)), 1.0, 60.0)

func begin() -> void:
	_active = true

func end() -> void:
	_active = false

func is_active() -> bool:
	return _active

func drag(delta_x: float, _delta: float = 0.0) -> void:
	if not _active:
		return
	var safe_delta := delta_x if is_finite(delta_x) else 0.0
	_target_yaw = wrapf(_target_yaw + safe_delta * _sensitivity, -PI, PI)

func tick(delta: float) -> float:
	var safe_delta := clampf(delta if is_finite(delta) else 0.0, 0.0, 0.1)
	var shortest := wrapf(_target_yaw - _yaw, -PI, PI)
	var weight := 1.0 - exp(-_follow_rate * safe_delta)
	_yaw = wrapf(_yaw + shortest * weight, -PI, PI)
	return _yaw

func reset() -> void:
	_active = false
	_yaw = 0.0
	_target_yaw = 0.0

func get_yaw() -> float:
	return _yaw

func get_target_yaw() -> float:
	return _target_yaw
