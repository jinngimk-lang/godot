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
	for detail_name in ["BottleMetalCap","BottleNeckRing","BottleHighlightLeft","BottleHighlightRight","BottleLiquidHero"]:
		if polish.get_node_or_null(detail_name) == null:
			failures.append("BOTTLE_HERO_RED: clear bottle missing target cue %s" % detail_name)
	if not polish.has_method("get_visual_contract"):
		failures.append("BOTTLE_HERO_RED: missing bottle visual contract")
	else:
		var contract: Dictionary = polish.call("get_visual_contract")
		if String(contract.get("cap","")) != "silver_crimp":
			failures.append("BOTTLE_HERO_RED: direct Yuzu target requires silver crimp cap")
		if float(contract.get("glass_highlight_alpha",0.0)) < 0.10:
			failures.append("BOTTLE_HERO_RED: glass needs readable edge/highlight breakup")
		if float(contract.get("outer_glass_alpha",1.0)) > 0.055:
			failures.append("BOTTLE_HERO_RED: target glass center must stay optically clear, not milky")
		if float(contract.get("edge_alpha",1.0)) > 0.24:
			failures.append("BOTTLE_GLASS_RED: Yuzu center must not be filled by a broad blue Fresnel shell")
		if float(contract.get("fresnel_power",0.0)) < 3.5:
			failures.append("BOTTLE_GLASS_RED: glass contour should be confined to grazing edges")
		if float(contract.get("liquid_alpha",0.0)) < 0.42:
			failures.append("BOTTLE_HERO_RED: pale Yuzu liquid must read separately through clear glass")
		if float(contract.get("liquid_top_y",0.0)) < 0.68:
			failures.append("BOTTLE_HERO_RED: Yuzu liquid should rise into the shoulder like the target bottle")
		if String(contract.get("liquid_shape","")) != "shouldered":
			failures.append("BOTTLE_HERO_RED: Yuzu liquid needs a shouldered bottle-following volume, not a floating cylinder")
		if float(contract.get("target_focus_y",0.0)) < 0.24:
			failures.append("BOTTLE_HERO_RED: bottle framing should keep the crown cap inside the viewport")
	if not polish.has_method("release_preview_resources"):
		failures.append("BOTTLE_RESOURCE_RED: bottle hero needs explicit preview resource teardown")
	else:
		polish.call("release_preview_resources")
		if polish.get_child_count() != 0:
			failures.append("BOTTLE_RESOURCE_RED: resource teardown must remove all preview children")
	polish.free()
	return failures
