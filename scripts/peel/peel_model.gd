extends RefCounted
class_name PeelModel

var _progress: float = 0.0
var _completion_emitted := false
var _base_adhesion: float
var _release_increment: float
var _speed_gain: float
var _angle_gain: float

func _init(config: Dictionary = {}) -> void:
	_base_adhesion = max(_finite_or(float(config.get("base_adhesion", 12.0)), 12.0), 0.001)
	_release_increment = clampf(_finite_or(float(config.get("release_increment", 0.045)), 0.045), 0.001, 1.0)
	_speed_gain = clampf(_finite_or(float(config.get("speed_gain", 0.02)), 0.02), 0.0, 1.0)
	_angle_gain = clampf(_finite_or(float(config.get("angle_gain", 0.25)), 0.25), 0.0, 1.0)

func reset() -> void:
	_progress = 0.0
	_completion_emitted = false

func step(tension: float, pull_speed: float, peel_angle: float, delta: float) -> Dictionary:
	var safe_tension := absf(_finite_or(tension, 0.0))
	var safe_speed := minf(absf(_finite_or(pull_speed, 0.0)), 100.0)
	var safe_angle := clampf(absf(_finite_or(peel_angle, 0.0)), 0.0, PI)
	var safe_delta := clampf(absf(_finite_or(delta, 0.0)), 0.0, 1.0 / 15.0)
	var previous := _progress

	if not _completion_emitted and _progress < 1.0 and safe_delta > 0.0:
		var speed_factor := 1.0 + (_speed_gain * safe_speed)
		var angle_factor := 1.0 + (_angle_gain * (safe_angle / PI))
		var effective_pull := safe_tension * speed_factor * angle_factor
		if effective_pull > _base_adhesion:
			var overdrive := clampf((effective_pull - _base_adhesion) / _base_adhesion, 0.0, 1.0)
			var frame_scale := clampf(safe_delta * 60.0, 0.25, 4.0)
			var release := _release_increment * lerpf(0.35, 1.0, overdrive) * frame_scale
			_progress = clampf(_progress + release, 0.0, 1.0)

	var completed_now := false
	if _progress >= 1.0 and not _completion_emitted:
		_completion_emitted = true
		completed_now = true

	return {
		"progress": _progress,
		"released": maxf(_progress - previous, 0.0),
		"completed_now": completed_now
	}

func get_progress() -> float:
	return _progress

func is_complete() -> bool:
	return _progress >= 1.0

func get_config() -> Dictionary:
	return {
		"base_adhesion": _base_adhesion,
		"release_increment": _release_increment,
		"speed_gain": _speed_gain,
		"angle_gain": _angle_gain
	}

func _finite_or(value: float, fallback: float) -> float:
	if is_nan(value) or is_inf(value):
		return fallback
	return value
