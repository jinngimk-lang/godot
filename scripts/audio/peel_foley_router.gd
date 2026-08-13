extends RefCounted
class_name PeelFoleyRouter

var _micro_cooldown := 0.0
var _paper_cooldown := 0.0
var _final_emitted := false

func reset() -> void:
	_micro_cooldown = 0.0
	_paper_cooldown = 0.0
	_final_emitted = false

func update(
	active: bool,
	speed: float,
	tension: float,
	released: float,
	detached_now: bool,
	delta: float
) -> Array[String]:
	var events: Array[String] = []
	var safe_delta := clampf(delta if is_finite(delta) else 0.0, 0.0, 0.5)
	var safe_speed := clampf(speed if is_finite(speed) else 0.0, 0.0, 40.0)
	var safe_tension := clampf(tension if is_finite(tension) else 0.0, 0.0, 120.0)
	var safe_released := clampf(released if is_finite(released) else 0.0, 0.0, 1.0)

	_micro_cooldown = maxf(_micro_cooldown - safe_delta, 0.0)
	_paper_cooldown = maxf(_paper_cooldown - safe_delta, 0.0)

	if detached_now and not _final_emitted:
		_final_emitted = true
		events.append("final_release")

	if not active:
		return events

	if safe_speed < 5.0:
		events.append("slow")
	else:
		events.append("fast")

	if safe_tension >= 10.0 and _paper_cooldown <= 0.0:
		events.append("paper_flex")
		_paper_cooldown = 0.16

	if safe_released >= 0.02 and _micro_cooldown <= 0.0:
		events.append("micro_release")
		_micro_cooldown = 0.075

	return events
