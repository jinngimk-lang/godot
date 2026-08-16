extends RefCounted

func run() -> Array[String]:
	var failures: Array[String] = []
	var script = load("res://scripts/presentation/hand_choreography_presentation.gd")
	if script == null:
		failures.append("HandChoreographyPresentation script did not load")
		return failures
	var presentation = script.new()
	var rest_bar: Dictionary = presentation.call("_peel_rest_profile","night_bar")
	var active_bar: Vector3 = presentation.call("_active_peel_rotation","night_bar",0.50)
	var active_market: Vector3 = presentation.call("_active_peel_rotation","market_coldcase",0.50)
	var active_cafe_start: Vector3 = presentation.call("_active_peel_rotation","cafe_window",0.0)
	var active_cafe_pull: Vector3 = presentation.call("_active_peel_rotation","cafe_window",1.0)
	var rest_rotation: Vector3 = rest_bar.get("rotation",Vector3.ZERO)
	if active_bar.distance_to(rest_rotation) < deg_to_rad(15.0):
		failures.append("active peel orientation must materially depart from idle palm rotation")
	if absf(active_bar.z) < deg_to_rad(35.0):
		failures.append("active bar pinch must roll the palm toward the lifted flap")
	if absf(active_market.z) < deg_to_rad(35.0):
		failures.append("active market pinch must roll the palm toward the lifted flap")
	if active_cafe_pull.distance_to(active_cafe_start) > deg_to_rad(12.0):
		failures.append("active peel progress must stay a bounded choreography adjustment, not a pose sweep")
	presentation.free()
	return failures
