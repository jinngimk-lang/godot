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
	for detail_name in ["BottleMetalCap","BottleNeckRing","BottleHighlightLeft","BottleHighlightRight"]:
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
	polish.free()
	return failures
