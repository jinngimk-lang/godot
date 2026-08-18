extends RefCounted
class_name LabelLifecycle

enum Phase { ATTACHED, PEELING, DETACHING, SETTLING, RESOLVED, RESETTING }

var _phase: Phase = Phase.ATTACHED
var _detach_duration := 0.16
var _detach_elapsed := 0.0
var _settle_duration := 0.72
var _settle_elapsed := 0.0
var _detach_event_pending := false

func _init(detach_duration: float = 0.16, settle_duration: float = 0.72) -> void:
	_detach_duration = clampf(detach_duration, 0.01, 2.0)
	_settle_duration = clampf(settle_duration, 0.20, 2.0)

func reset() -> void:
	_phase = Phase.ATTACHED
	_detach_elapsed = 0.0
	_settle_elapsed = 0.0
	_detach_event_pending = false

func update(progress: float, completed_now: bool, delta: float) -> void:
	var safe_progress := clampf(progress if is_finite(progress) else 0.0, 0.0, 1.0)
	var safe_delta := clampf(delta if is_finite(delta) else 0.0, 0.0, 0.5)

	match _phase:
		Phase.ATTACHED:
			if completed_now or safe_progress >= 1.0:
				_begin_detach()
			elif safe_progress > 0.0001:
				_phase = Phase.PEELING
		Phase.PEELING:
			if completed_now or safe_progress >= 1.0:
				_begin_detach()
			elif safe_progress <= 0.0001:
				_phase = Phase.ATTACHED
		Phase.DETACHING:
			_detach_elapsed += safe_delta
			if _detach_elapsed >= _detach_duration:
				_detach_elapsed = _detach_duration
				_phase = Phase.SETTLING
				_settle_elapsed = 0.0
				_detach_event_pending = true
		Phase.SETTLING:
			_settle_elapsed += safe_delta
			if _settle_elapsed >= _settle_duration:
				_settle_elapsed = _settle_duration
				_phase = Phase.RESOLVED
		Phase.RESOLVED:
			pass
		Phase.RESETTING:
			pass

func get_phase_name() -> String:
	return Phase.keys()[_phase]

func get_detach_alpha() -> float:
	if _phase in [Phase.SETTLING, Phase.RESOLVED]:
		return 1.0
	if _phase != Phase.DETACHING:
		return 0.0
	return clampf(_detach_elapsed / _detach_duration, 0.0, 1.0)

func get_release_settle_alpha() -> float:
	if _phase == Phase.RESOLVED:
		return 1.0
	if _phase != Phase.SETTLING:
		return 0.0
	return clampf(_settle_elapsed / _settle_duration, 0.0, 1.0)

func should_render_label() -> bool:
	return _phase != Phase.RESOLVED

func is_detached() -> bool:
	return _phase in [Phase.SETTLING, Phase.RESOLVED]

func is_resolved() -> bool:
	return _phase == Phase.RESOLVED

func consume_detach_event() -> bool:
	if not _detach_event_pending:
		return false
	_detach_event_pending = false
	return true

func _begin_detach() -> void:
	if _phase in [Phase.DETACHING, Phase.SETTLING, Phase.RESOLVED]:
		return
	_phase = Phase.DETACHING
	_detach_elapsed = 0.0
	_settle_elapsed = 0.0
	_detach_event_pending = false
