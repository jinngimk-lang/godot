extends RefCounted
class_name ResidueScrubModel

var _required_travel := 340.0
var _reversal_bonus := 0.45
var _progress := 0.0
var _last_direction := Vector2.ZERO
var _rub_intensity := 0.0
var _completed_event_pending := false

func _init(config: Dictionary = {}) -> void:
	_required_travel = clampf(float(config.get("required_travel",340.0)),120.0,900.0)
	_reversal_bonus = clampf(float(config.get("reversal_bonus",0.45)),0.0,1.0)

func reset() -> void:
	_progress = 0.0
	_last_direction = Vector2.ZERO
	_rub_intensity = 0.0
	_completed_event_pending = false

func update(pressed: bool, position: Vector2, relative: Vector2, region: Rect2, delta: float) -> Dictionary:
	var safe_delta := clampf(delta if is_finite(delta) else 0.0,0.0,0.10)
	_rub_intensity = move_toward(_rub_intensity,0.0,safe_delta*7.0)
	if _progress >= 1.0 or not pressed or not region.has_point(position):
		if not pressed:
			_last_direction = Vector2.ZERO
		return _snapshot(false,0.0)
	var travel := minf(relative.length(),24.0)
	if travel < 2.0:
		return _snapshot(false,0.0)
	var direction := relative.normalized()
	var reversed := _last_direction.length_squared() > 0.5 and direction.dot(_last_direction) < -0.30
	var stroke_weight := 1.0+_reversal_bonus if reversed else 0.62
	var gained := minf(travel/_required_travel*stroke_weight,0.085)
	_progress = minf(_progress+gained,1.0)
	_last_direction = direction
	_rub_intensity = clampf(travel/18.0,0.25,1.0)
	if _progress >= 1.0 and not _completed_event_pending:
		_completed_event_pending = true
	return _snapshot(true,gained)

func get_progress() -> float:
	return _progress

func get_rub_intensity() -> float:
	return _rub_intensity

func is_complete() -> bool:
	return _progress >= 0.999

func consume_completed_event() -> bool:
	if not _completed_event_pending:
		return false
	_completed_event_pending = false
	return true

func _snapshot(active: bool, gained: float) -> Dictionary:
	return {
		"active":active,
		"gained":gained,
		"progress":_progress,
		"intensity":_rub_intensity,
		"complete":is_complete()
	}
