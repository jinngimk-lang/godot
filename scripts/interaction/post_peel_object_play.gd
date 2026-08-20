extends Node
class_name PostPeelObjectPlay

const PROFILES := {
	"paper_cup": {"squeeze_gain":0.0038,"max_squeeze":0.095,"shake_gain":0.0015,"shake_limit":0.085,"liquid_gain":0.18},
	"sauce_jar": {"squeeze_gain":0.00010,"max_squeeze":0.006,"shake_gain":0.0012,"shake_limit":0.070,"liquid_gain":0.80},
	"tin_can": {"squeeze_gain":0.00055,"max_squeeze":0.020,"shake_gain":0.0014,"shake_limit":0.080,"liquid_gain":0.36},
	"clear_bottle": {"squeeze_gain":0.00008,"max_squeeze":0.004,"shake_gain":0.0018,"shake_limit":0.095,"liquid_gain":1.00},
	"soda_can": {"squeeze_gain":0.0025,"max_squeeze":0.070,"shake_gain":0.0017,"shake_limit":0.090,"liquid_gain":0.62}
}

var _kind := "paper_cup"
var _profile: Dictionary = PROFILES["paper_cup"].duplicate(true)
var _active := false
var _squeeze := 0.0
var _squeeze_target := 0.0
var _shake_angle := 0.0
var _shake_velocity := 0.0
var _liquid_tilt := 0.0
var _last_drag_sign := 0.0

func profile_for_kind(kind: String) -> Dictionary:
	return (PROFILES.get(kind,PROFILES["paper_cup"]) as Dictionary).duplicate(true)

func configure_kind(kind: String) -> void:
	_kind = kind if PROFILES.has(kind) else "paper_cup"
	_profile = profile_for_kind(_kind)
	reset()

func set_active(active: bool) -> void:
	_active = active
	if not active:
		_squeeze_target = 0.0

func is_active() -> bool:
	return _active

func feed_drag(relative: Vector2, delta: float) -> void:
	if not _active:
		return
	var safe_delta := maxf(delta,0.001)
	var horizontal_speed := relative.x/safe_delta
	var sign_now := signf(relative.x)
	var reversal_boost := 1.35 if _last_drag_sign != 0.0 and sign_now != 0.0 and sign_now != _last_drag_sign else 1.0
	_last_drag_sign = sign_now if sign_now != 0.0 else _last_drag_sign
	var shake_gain := float(_profile.get("shake_gain",0.0015))
	_shake_velocity += horizontal_speed*shake_gain*0.0012*reversal_boost
	_shake_velocity = clampf(_shake_velocity,-1.8,1.8)

	var squeeze_gain := float(_profile.get("squeeze_gain",0.0))
	var max_squeeze := float(_profile.get("max_squeeze",0.0))
	var compress_work := (absf(relative.x)*0.72+absf(relative.y)*0.42)*squeeze_gain
	_squeeze_target = clampf(maxf(_squeeze_target,compress_work),0.0,max_squeeze)

func tick(delta: float) -> void:
	var dt := clampf(delta,0.0,0.05)
	var squeeze_follow := 1.0-exp(-18.0*dt)
	_squeeze = lerpf(_squeeze,_squeeze_target,squeeze_follow)
	if _active:
		_squeeze_target *= exp(-3.2*dt)
	else:
		_squeeze_target = 0.0

	_shake_angle += _shake_velocity*dt
	var limit := float(_profile.get("shake_limit",0.08))
	_shake_angle = clampf(_shake_angle,-limit,limit)
	# Damped spring: responsive during drag, calm recovery after release.
	_shake_velocity += (-_shake_angle*42.0)*dt
	_shake_velocity *= exp(-7.0*dt)
	if not _active:
		_shake_angle *= exp(-4.6*dt)
	var liquid_gain := float(_profile.get("liquid_gain",0.0))
	_liquid_tilt = clampf(-_shake_angle*liquid_gain-_shake_velocity*0.018*liquid_gain,-0.16,0.16)

func get_squeeze_scale() -> Vector3:
	var amount := clampf(_squeeze,0.0,float(_profile.get("max_squeeze",0.0)))
	return Vector3(1.0-amount,1.0+amount*0.34,1.0+amount*0.16)

func get_shake_angle() -> float:
	return _shake_angle

func get_liquid_tilt() -> float:
	return _liquid_tilt

func get_feedback_text() -> String:
	if not _active:
		return "LMB drag to squeeze / shake"
	if absf(_shake_angle) > 0.025:
		return "SHAKING • release gently"
	if _squeeze > 0.012:
		return "SQUEEZE • feel the container flex"
	return "MOVE • slow drag squeezes, quick swipes shake"

func reset() -> void:
	_active = false
	_squeeze = 0.0
	_squeeze_target = 0.0
	_shake_angle = 0.0
	_shake_velocity = 0.0
	_liquid_tilt = 0.0
	_last_drag_sign = 0.0
