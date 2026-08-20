extends RefCounted

func run() -> Array[String]:
	var failures: Array[String] = []
	var path := "res://scripts/interaction/post_peel_object_play.gd"
	if not ResourceLoader.exists(path):
		return ["POST_PEEL_PLAY_RED: missing resolved-object interaction model"]
	var model = load(path).new()
	for kind in ["paper_cup","sauce_jar","tin_can","clear_bottle","soda_can"]:
		var profile: Dictionary = model.call("profile_for_kind",kind)
		if profile.is_empty():
			failures.append("POST_PEEL_PLAY_RED: missing profile for %s" % kind)
		if not profile.has("shake_gain") or not profile.has("squeeze_gain"):
			failures.append("POST_PEEL_PLAY_RED: %s needs shake and squeeze response" % kind)
	var cup: Dictionary = model.call("profile_for_kind","paper_cup")
	var bottle: Dictionary = model.call("profile_for_kind","clear_bottle")
	var can: Dictionary = model.call("profile_for_kind","soda_can")
	if float(cup.get("squeeze_gain",0.0)) <= float(bottle.get("squeeze_gain",1.0)):
		failures.append("POST_PEEL_PLAY_RED: paper cup must squeeze more than glass bottle")
	if float(can.get("squeeze_gain",0.0)) <= float(bottle.get("squeeze_gain",1.0)):
		failures.append("POST_PEEL_PLAY_RED: aluminum can must squeeze more than glass bottle")

	model.call("configure_kind","clear_bottle")
	model.call("set_active",true)
	model.call("feed_drag",Vector2(38.0,2.0),0.016)
	model.call("feed_drag",Vector2(-42.0,-1.0),0.016)
	model.call("feed_drag",Vector2(44.0,1.0),0.016)
	model.call("tick",0.016)
	if absf(float(model.call("get_shake_angle"))) < 0.003:
		failures.append("POST_PEEL_PLAY_RED: fast alternating drag should create visible bottle shake")
	if absf(float(model.call("get_liquid_tilt"))) < 0.003:
		failures.append("POST_PEEL_PLAY_RED: bottle shake needs liquid inertia cue")

	model.call("reset")
	model.call("configure_kind","paper_cup")
	model.call("set_active",true)
	model.call("feed_drag",Vector2(18.0,12.0),0.10)
	model.call("tick",0.016)
	var scale: Vector3 = model.call("get_squeeze_scale")
	if scale.x >= 0.998 or scale.y <= 1.001:
		failures.append("POST_PEEL_PLAY_RED: cup drag should create bounded pinch deformation")
	model.call("set_active",false)
	for _i in range(90): model.call("tick",0.016)
	var recovered: Vector3 = model.call("get_squeeze_scale")
	if recovered.distance_to(Vector3.ONE) > 0.035:
		failures.append("POST_PEEL_PLAY_RED: released object should calmly recover toward rest")
	model.free()
	return failures
