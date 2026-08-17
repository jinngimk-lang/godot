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
var _leaving_current := false

func reset() -> void:
	_phase = Phase.PEEL
	_settle_elapsed = 0.0
	_reward_pending = false
	_next_pending = false
	_leaving_current = false

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
	# The calm settle is a visual invitation, not a mandatory input lockout.
	# Explicit squeeze intent may enter the optional ritual immediately after
	# detach, just as an explicit next request may already leave PEEL_SETTLE.
	# With no input, update() still preserves the full 0.45 s calm beat before
	# exposing CRUMPLE_READY.
	if _phase not in [Phase.PEEL_SETTLE, Phase.CRUMPLE_READY] or _leaving_current:
		return false
	_phase = Phase.CRUMPLING
	return true

func mark_crumple_complete() -> bool:
	# Once next is accepted, this outgoing cup remains reward-ineligible even
	# after the one-shot next event is consumed. Reset/new item clears the latch.
	if _phase != Phase.CRUMPLING or _leaving_current:
		return false
	_phase = Phase.RITUAL_COMPLETE
	_reward_pending = true
	return true

func request_next() -> bool:
	# The short settle is an invitation, never a mandatory lockout. Once the
	# label is detached the player may continue immediately or linger into the
	# optional crumple phase at their own pace.
	if _phase not in [Phase.PEEL_SETTLE, Phase.CRUMPLE_READY, Phase.CRUMPLING, Phase.RITUAL_COMPLETE]:
		return false
	if _leaving_current:
		return false
	_leaving_current = true
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
