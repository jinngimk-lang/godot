extends RefCounted
class_name RitualFlow

enum Phase {
	PEEL,
	PEEL_SETTLE,
	CRUMPLE_READY,
	CRUMPLING,
	RITUAL_COMPLETE
}

var settle_duration := 0.45

var _phase := Phase.PEEL
var _settle_elapsed := 0.0
var _reward_pending := false
var _next_pending := false

func reset() -> void:
	_phase = Phase.PEEL
	_settle_elapsed = 0.0
	_reward_pending = false
	_next_pending = false

func on_label_detached() -> bool:
	if _phase != Phase.PEEL:
		return false
	_phase = Phase.PEEL_SETTLE
	_settle_elapsed = 0.0
	return true

func update(delta: float) -> void:
	if _phase != Phase.PEEL_SETTLE:
		return
	var safe_delta := delta if is_finite(delta) and delta > 0.0 else 0.0
	_settle_elapsed += safe_delta
	if _settle_elapsed >= settle_duration:
		_phase = Phase.CRUMPLE_READY

func begin_crumple() -> bool:
	if _phase != Phase.CRUMPLE_READY or _next_pending:
		return false
	_phase = Phase.CRUMPLING
	return true

func mark_crumple_complete() -> bool:
	if _phase != Phase.CRUMPLING or _next_pending:
		return false
	_phase = Phase.RITUAL_COMPLETE
	_reward_pending = true
	return true

func request_next() -> bool:
	if _phase not in [Phase.CRUMPLE_READY, Phase.CRUMPLING, Phase.RITUAL_COMPLETE]:
		return false
	if _next_pending:
		return false
	_next_pending = true
	return true

func consume_reward_event() -> bool:
	if not _reward_pending:
		return false
	_reward_pending = false
	return true

func consume_next_request() -> bool:
	if not _next_pending:
		return false
	_next_pending = false
	return true

func get_phase_name() -> String:
	match _phase:
		Phase.PEEL:
			return "PEEL"
		Phase.PEEL_SETTLE:
			return "PEEL_SETTLE"
		Phase.CRUMPLE_READY:
			return "CRUMPLE_READY"
		Phase.CRUMPLING:
			return "CRUMPLING"
		Phase.RITUAL_COMPLETE:
			return "RITUAL_COMPLETE"
	return "PEEL"
