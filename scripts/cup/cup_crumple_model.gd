extends RefCounted
class_name CupCrumpleModel

const COMPLETE_PROGRESS := 0.72

var _rigidity := 0.04
var _dent_gain := 0.018
var _max_compression := 0.22

var _progress := 0.0
var _gesture_active := false
var _gesture_side := 0
var _gesture_inward_position := 0.0
var _gesture_peak_inward := 0.0
var _gesture_effective_total := 0.0
var _pending_event := 0.0

func _init(profile: Dictionary = {}) -> void:
	configure(profile)

func configure(profile: Dictionary) -> void:
	_rigidity = clampf(_finite_or(float(profile.get("rigidity", 0.04)), 0.04), 0.0, 1.0)
	_dent_gain = clampf(_finite_or(float(profile.get("dent_gain", 0.018)), 0.018), 0.0001, 0.25)
	_max_compression = clampf(_finite_or(float(profile.get("max_compression", 0.22)), 0.22), 0.02, 0.45)

func reset() -> void:
	_progress = 0.0
	_gesture_active = false
	_gesture_side = 0
	_gesture_inward_position = 0.0
	_gesture_peak_inward = 0.0
	_gesture_effective_total = 0.0
	_pending_event = 0.0

func begin_gesture(pointer_x: float, cup_center_x: float) -> void:
	_gesture_inward_position = 0.0
	_gesture_peak_inward = 0.0
	_gesture_effective_total = 0.0
	if not is_finite(pointer_x) or not is_finite(cup_center_x):
		_gesture_active = false
		_gesture_side = 0
		return
	_gesture_side = -1 if pointer_x < cup_center_x else 1
	_gesture_active = true

func apply_drag(relative_x: float) -> Dictionary:
	var result := {
		"changed": false,
		"delta": 0.0,
		"progress": _progress,
		"event_strength": 0.0
	}
	if not _gesture_active or not is_finite(relative_x):
		return result

	# Track signed gesture-local displacement, not only positive input packets.
	# Returning outward reduces the current inward position, so zero-net pointer
	# jitter cannot accumulate enough positive half-cycles to defeat rigidity.
	# Existing cup deformation remains permanent; only this gesture-local cursor
	# depth moves back outward.
	var inward_delta := relative_x if _gesture_side < 0 else -relative_x
	_gesture_inward_position = maxf(_gesture_inward_position + inward_delta, 0.0)
	_gesture_peak_inward = maxf(_gesture_peak_inward, _gesture_inward_position)

	# Rigidity is charged once against the deepest inward point reached during
	# this physical press. Only a new peak beyond the prior effective depth can
	# add deformation, preserving packetization invariance without jitter creep.
	var deadzone_px := _rigidity * 20.0
	var effective_total := maxf(_gesture_peak_inward - deadzone_px, 0.0)
	var effective_px := maxf(effective_total - _gesture_effective_total, 0.0)
	_gesture_effective_total = effective_total
	if effective_px <= 0.0:
		return result

	var before := _progress
	_progress = clampf(_progress + effective_px * _dent_gain, 0.0, 1.0)
	var delta := _progress - before
	if delta <= 0.0:
		return result

	var strength := clampf(delta / 0.18, 0.08, 1.0)
	_pending_event = maxf(_pending_event, strength)
	result["changed"] = true
	result["delta"] = delta
	result["progress"] = _progress
	result["event_strength"] = strength
	return result

func end_gesture() -> void:
	_gesture_active = false
	_gesture_side = 0
	_gesture_inward_position = 0.0
	_gesture_peak_inward = 0.0
	_gesture_effective_total = 0.0

func get_progress() -> float:
	return _progress

func is_complete() -> bool:
	return _progress >= COMPLETE_PROGRESS

func get_compression() -> float:
	return clampf(_progress * _max_compression, 0.0, _max_compression)

func consume_crumple_event() -> float:
	var value := _pending_event
	_pending_event = 0.0
	return value

func get_gesture_side() -> int:
	return _gesture_side if _gesture_active else 0

func _finite_or(value: float, fallback: float) -> float:
	return value if is_finite(value) else fallback