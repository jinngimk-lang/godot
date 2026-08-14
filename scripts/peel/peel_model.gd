extends RefCounted
class_name PeelModel

var _progress: float = 0.0
var _completion_emitted := false
var _base_adhesion: float
var _release_increment: float
var _speed_gain: float
var _angle_gain: float
var _bond_response: float
var _bond_relaxation: float
var _safe_pull_speed: float
var _tear_pull_speed: float
var _residue_gain: float
var _bond_load := 0.0
var _integrity := 1.0
var _residue := 0.0

func _init(config: Dictionary = {}) -> void:
	_base_adhesion = max(_finite_or(float(config.get("base_adhesion", 12.0)), 12.0), 0.001)
	_release_increment = clampf(_finite_or(float(config.get("release_increment", 0.045)), 0.045), 0.001, 1.0)
	_speed_gain = clampf(_finite_or(float(config.get("speed_gain", 0.02)), 0.02), 0.0, 1.0)
	_angle_gain = clampf(_finite_or(float(config.get("angle_gain", 0.25)), 0.25), 0.0, 1.0)
	_bond_response = clampf(_finite_or(float(config.get("bond_response", 7.0)), 7.0), 0.1, 30.0)
	_bond_relaxation = clampf(_finite_or(float(config.get("bond_relaxation", 4.0)), 4.0), 0.1, 30.0)
	_safe_pull_speed = clampf(_finite_or(float(config.get("safe_pull_speed", 5.0)), 5.0), 0.1, 100.0)
	_tear_pull_speed = maxf(_finite_or(float(config.get("tear_pull_speed", 12.0)), 12.0), _safe_pull_speed + 0.1)
	_residue_gain = clampf(_finite_or(float(config.get("residue_gain", 0.12)), 0.12), 0.0, 2.0)

func reset() -> void:
	_progress = 0.0
	_completion_emitted = false
	_bond_load = 0.0
	_integrity = 1.0
	_residue = 0.0

func step(tension: float, pull_speed: float, peel_angle: float, delta: float) -> Dictionary:
	var safe_tension := minf(absf(_finite_or(tension, 0.0)), 1000000.0)
	var safe_speed := minf(absf(_finite_or(pull_speed, 0.0)), 100.0)
	var safe_angle := clampf(absf(_finite_or(peel_angle, 0.0)), 0.0, PI)
	var safe_delta := clampf(absf(_finite_or(delta, 0.0)), 0.0, 1.0 / 15.0)
	var previous := _progress

	if safe_delta > 0.0:
		var speed_factor := 1.0 + (_speed_gain * safe_speed)
		var angle_factor := 1.0 + (_angle_gain * (safe_angle / PI))
		var effective_pull := safe_tension * speed_factor * angle_factor
		var target_load := clampf(effective_pull / _base_adhesion, 0.0, 12.0)
		var rate := _bond_response if target_load > _bond_load else _bond_relaxation
		var weight := 1.0 - exp(-rate * safe_delta)
		_bond_load = clampf(lerpf(_bond_load, target_load, weight), 0.0, 12.0)

		if not _completion_emitted and _progress < 1.0 and _bond_load > 1.0:
			var overdrive := clampf((_bond_load - 1.0) / 2.0, 0.0, 1.0)
			var frame_scale := clampf(safe_delta * 60.0, 0.0, 4.0)
			var release := _release_increment * lerpf(0.30, 1.0, overdrive) * frame_scale
			_progress = clampf(_progress + release, 0.0, 1.0)

			var speed_abuse := clampf((safe_speed - _safe_pull_speed) / (_tear_pull_speed - _safe_pull_speed), 0.0, 1.0)
			var force_abuse := clampf((target_load - 2.0) / 4.0, 0.0, 1.0)
			var abuse := maxf(speed_abuse, force_abuse)
			if abuse > 0.0:
				var damage := abuse * _residue_gain * safe_delta
				_integrity = clampf(_integrity - damage, 0.0, 1.0)
				_residue = clampf(_residue + damage * 1.25, 0.0, 1.0)

	var completed_now := false
	if _progress >= 1.0 and not _completion_emitted:
		_completion_emitted = true
		completed_now = true

	return {
		"progress": _progress,
		"released": maxf(_progress - previous, 0.0),
		"completed_now": completed_now,
		"bond_load": _bond_load,
		"integrity": _integrity,
		"residue": _residue
	}

func get_progress() -> float:
	return _progress

func get_bond_load() -> float:
	return _bond_load

func get_integrity() -> float:
	return _integrity

func get_residue() -> float:
	return _residue

func is_complete() -> bool:
	return _progress >= 1.0

func get_config() -> Dictionary:
	return {
		"base_adhesion": _base_adhesion,
		"release_increment": _release_increment,
		"speed_gain": _speed_gain,
		"angle_gain": _angle_gain,
		"bond_response": _bond_response,
		"bond_relaxation": _bond_relaxation,
		"safe_pull_speed": _safe_pull_speed,
		"tear_pull_speed": _tear_pull_speed,
		"residue_gain": _residue_gain
	}

func _finite_or(value: float, fallback: float) -> float:
	if is_nan(value) or is_inf(value):
		return fallback
	return value
