extends RefCounted

func run() -> Array[String]:
	var failures: Array[String] = []
	var model = SessionModel.new()
	if not model.has_method("select_variant"):
		failures.append("RED: showcase needs deterministic direct variant navigation")
		return failures
	if model.VARIANTS.size() < 3:
		failures.append("reference vertical slice requires three variants")
		return failures
	var expected_scenes := ["cafe_window","night_bar","market_coldcase"]
	var expected_kinds := ["paper_cup","amber_bottle","clear_bottle"]
	var expected_post := ["crumple","inspect","inspect"]
	for i in range(3):
		var variant: Dictionary = model.VARIANTS[i]
		for key in ["scene_profile","container_profile","post_peel_action"]:
			if not variant.has(key): failures.append("RED: variant %d missing %s" % [i,key])
		if not failures.is_empty(): continue
		if String(variant.scene_profile.get("id","")) != expected_scenes[i]: failures.append("variant %d wrong scene" % i)
		if String(variant.container_profile.get("kind","")) != expected_kinds[i]: failures.append("variant %d wrong container kind" % i)
		if String(variant.post_peel_action) != expected_post[i]: failures.append("variant %d wrong post-peel action" % i)
	model.select_variant(2)
	if String(model.current_variant().container_profile.get("kind","")) != "clear_bottle":
		failures.append("direct navigation should select market bottle even before progression unlock")
	model.select_variant(1)
	if String(model.current_variant().scene_profile.get("id","")) != "night_bar":
		failures.append("direct navigation should select bar profile")
	return failures
