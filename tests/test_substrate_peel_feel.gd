extends RefCounted

func run() -> Array[String]:
	var failures: Array[String] = []
	var session_script = load("res://scripts/session/session_model.gd")
	if session_script == null:
		return ["SUBSTRATE_FEEL_RED: session model did not load"]
	var session = session_script.new()
	var feel_profiles: Array[Dictionary] = []
	for index in range(session.VARIANTS.size()):
		session.select_variant(index)
		var variant: Dictionary = session.current_variant()
		var feel_value = variant.get("peel_feel",{})
		if not (feel_value is Dictionary) or (feel_value as Dictionary).is_empty():
			failures.append("SUBSTRATE_FEEL_RED: variant %s needs a peel_feel profile" % String(variant.get("id",index)))
			continue
		var feel: Dictionary = feel_value
		for key in ["motion_pixels_per_release","breakaway_multiplier","bend_band_ratio","backing_thickness"]:
			if not feel.has(key):
				failures.append("SUBSTRATE_FEEL_RED: %s missing %s" % [String(variant.get("id",index)),key])
		feel_profiles.append(feel)
	if feel_profiles.size() == 5:
		var coffee: Dictionary = feel_profiles[0]
		var jar: Dictionary = feel_profiles[1]
		var tin: Dictionary = feel_profiles[2]
		var market: Dictionary = feel_profiles[3]
		var can: Dictionary = feel_profiles[4]
		if float(jar.get("motion_pixels_per_release",0.0)) <= float(market.get("motion_pixels_per_release",999.0)):
			failures.append("SUBSTRATE_FEEL_RED: rustic jar paper should require more pointer work than coated Yuzu paper")
		if float(jar.get("backing_thickness",0.0)) <= float(can.get("backing_thickness",999.0)):
			failures.append("SUBSTRATE_FEEL_RED: jar paper should be visibly thicker than thin soda wrap")
		if float(jar.get("bend_band_ratio",1.0)) >= float(can.get("bend_band_ratio",0.0)):
			failures.append("SUBSTRATE_FEEL_RED: thick jar paper should concentrate bending more tightly than thin can wrap")
		if float(coffee.get("breakaway_multiplier",0.0)) <= 1.0:
			failures.append("SUBSTRATE_FEEL_RED: coffee sticker needs a real initial breakaway peak")
		if float(tin.get("breakaway_multiplier",0.0)) <= 1.0:
			failures.append("SUBSTRATE_FEEL_RED: tin wrap needs a real initial breakaway peak")

	var controller_script = load("res://scripts/peel/peel_controller.gd")
	if controller_script == null:
		failures.append("peel controller did not load")
	else:
		var controller = controller_script.new({"motion_pixels_per_release":4.2})
		if not controller.has_method("get_motion_pixels_per_release"):
			failures.append("SUBSTRATE_FEEL_RED: controller must expose configured pointer-work scale")
		elif absf(float(controller.call("get_motion_pixels_per_release"))-4.2) > 0.01:
			failures.append("controller ignored substrate motion_pixels_per_release")

	var corner_script = load("res://scripts/presentation/corner_peel_presentation.gd")
	if corner_script == null:
		failures.append("corner peel presentation did not load")
	else:
		var corner = corner_script.new()
		if not corner.has_method("set_paper_profile"):
			failures.append("SUBSTRATE_FEEL_RED: corner renderer must accept substrate paper profile")
		else:
			corner.call("set_paper_profile",{"bend_band_ratio":0.09,"backing_thickness":0.0052})
			if absf(float(corner.call("paper_bend_band_ratio"))-0.09) > 0.002:
				failures.append("corner renderer ignored substrate bend band")
			if absf(float(corner.call("paper_backing_thickness"))-0.0052) > 0.0002:
				failures.append("corner renderer ignored substrate paper thickness")
		corner.free()
	return failures
