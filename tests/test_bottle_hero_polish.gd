extends RefCounted

func run() -> Array[String]:
	var failures: Array[String] = []
	var path := "res://scripts/presentation/bottle_hero_polish.gd"
	if not ResourceLoader.exists(path):
		return ["BOTTLE_HERO_RED: missing bottle hero polish layer"]
	var polish = load(path).new()
	if not polish.has_method("build_preview_for_kind"):
		failures.append("BOTTLE_HERO_RED: polish layer needs deterministic preview builder")
		polish.free()
		return failures
	polish.call("build_preview_for_kind","clear_bottle")
	for detail_name in [
		"BottleGlassHeroShell",
		"BottleMetalCap",
		"BottleCapTop",
		"BottleCapFlute0",
		"BottleNeckRing",
		"BottleHighlightLeft",
		"BottleHighlightRight",
		"BottleLiquidHero",
		"BottleLiquidMeniscus",
		"BottleLiquidSurface"
	]:
		if polish.get_node_or_null(detail_name) == null:
			failures.append("BOTTLE_HERO_RED: clear bottle missing target cue %s" % detail_name)
	if not polish.has_method("set_liquid_inertia"):
		failures.append("BOTTLE_LIQUID_RED: visible Yuzu liquid needs a dedicated surface-inertia presenter")
	if not polish.has_method("get_visual_contract"):
		failures.append("BOTTLE_HERO_RED: missing bottle visual contract")
	else:
		var contract: Dictionary = polish.call("get_visual_contract")
		if String(contract.get("cap","")) != "silver_crimp":
			failures.append("BOTTLE_HERO_RED: direct Yuzu target requires silver crimp cap")
		if String(contract.get("cap_detail","")) != "vertical_flutes":
			failures.append("BOTTLE_CAP_RED: cap must use vertical crimp flutes, not screw-thread rings")
		if float(contract.get("cap_radius",1.0)) > 0.19:
			failures.append("BOTTLE_CAP_RED: target cap is compact; radius must stay <= 0.19")
		if float(contract.get("cap_height",1.0)) > 0.085:
			failures.append("BOTTLE_CAP_RED: target cap is shallow; height must stay <= 0.085")
		if float(contract.get("glass_highlight_alpha",0.0)) < 0.10:
			failures.append("BOTTLE_HERO_RED: glass needs readable edge/highlight breakup")
		if float(contract.get("outer_glass_alpha",1.0)) > 0.04:
			failures.append("BOTTLE_HERO_RED: Yuzu glass center must stay optically clear, not milky")
		if float(contract.get("edge_alpha",1.0)) > 0.14:
			failures.append("BOTTLE_GLASS_RED: Yuzu contour must be thin; broad Fresnel shell reads as frosted plastic")
		if float(contract.get("fresnel_power",0.0)) < 5.0:
			failures.append("BOTTLE_GLASS_RED: glass contour should be confined tightly to grazing edges")
		if not bool(contract.get("orientation_safe_fresnel",false)):
			failures.append("BOTTLE_GLASS_RED: Yuzu edge shader must treat reversed front normals symmetrically in GL")
		if String(contract.get("liquid_rendering","")) != "stable_volume_translucent_surface":
			failures.append("BOTTLE_LIQUID_RED: closed transparent liquid volume caused GL sort breakup; use stable body plus translucent surface cues")
		if String(contract.get("liquid_inertia","")) != "surface_countertilt":
			failures.append("BOTTLE_LIQUID_RED: shake inertia must tilt the free surface, not rotate the whole liquid volume through the bottle")
		if String(contract.get("liquid_tone","")) != "warm_yuzu_yellow":
			failures.append("BOTTLE_LIQUID_RED: target liquid must be warm yellow rather than grey-green")
		if float(contract.get("liquid_top_y",0.0)) < 0.68:
			failures.append("BOTTLE_HERO_RED: Yuzu liquid should rise into the shoulder like the target bottle")
		if String(contract.get("liquid_shape","")) != "shouldered":
			failures.append("BOTTLE_HERO_RED: Yuzu liquid needs a shouldered bottle-following volume, not a floating cylinder")
		if not bool(contract.get("liquid_meniscus",false)):
			failures.append("BOTTLE_LIQUID_RED: liquid surface needs a restrained visible meniscus cue")
		if float(contract.get("target_focus_y",0.0)) < 0.24:
			failures.append("BOTTLE_HERO_RED: bottle framing should keep the crown cap inside the viewport")
	if polish.has_method("set_liquid_inertia"):
		polish.call("set_liquid_inertia",0.08)
		var body := polish.get_node_or_null("BottleLiquidHero") as Node3D
		var surface := polish.get_node_or_null("BottleLiquidSurface") as Node3D
		if body != null and absf(body.rotation.z) > 0.005:
			failures.append("BOTTLE_LIQUID_RED: main liquid volume must stay stable during shake")
		if surface != null and absf(surface.rotation.z) < 0.02:
			failures.append("BOTTLE_LIQUID_RED: free surface must visibly counter-tilt during shake")
	if not polish.has_method("release_preview_resources"):
		failures.append("BOTTLE_RESOURCE_RED: bottle hero needs explicit preview resource teardown")
	else:
		polish.call("release_preview_resources")
		if polish.get_child_count() != 0:
			failures.append("BOTTLE_RESOURCE_RED: resource teardown must remove all preview children")
	polish.free()
	return failures
