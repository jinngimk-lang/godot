extends RefCounted

func run() -> Array[String]:
	var failures: Array[String] = []
	var model = SessionModel.new()
	if not model.has_method("select_variant"):
		return ["PROFILE_RED: showcase needs deterministic direct variant navigation"]
	if model.VARIANTS.size() != 5:
		failures.append("PROFILE_RED: object-only north star requires exactly five variants")
		return failures

	var expected_scenes := ["cafe_window","pantry_jar","pantry_tin","market_coldcase","market_can"]
	var expected_kinds := ["paper_cup","sauce_jar","tin_can","clear_bottle","soda_can"]
	var expected_names := ["Coffee Shop","Jar","Tin Can","Supermarket","Can"]
	var composition_path := "res://scripts/presentation/reference_composition.gd"
	var composition = load(composition_path) if ResourceLoader.exists(composition_path) else null
	if composition == null:
		failures.append("PROFILE_RED: live ReferenceComposition is required")

	for i in range(5):
		var variant: Dictionary = model.VARIANTS[i]
		for key in ["scene_profile","container_profile","post_peel_action","label_width","label_height"]:
			if not variant.has(key):
				failures.append("PROFILE_RED: variant %d missing %s" % [i,key])
		if String(variant.get("name","")) != expected_names[i]:
			failures.append("PROFILE_RED: variant %d must be named %s" % [i,expected_names[i]])
		if String((variant.get("scene_profile",{}) as Dictionary).get("id","")) != expected_scenes[i]:
			failures.append("PROFILE_RED: variant %d has wrong scene id" % i)
		if String((variant.get("container_profile",{}) as Dictionary).get("kind","")) != expected_kinds[i]:
			failures.append("PROFILE_RED: variant %d has wrong product kind" % i)
		if String(variant.get("post_peel_action","")) != "inspect":
			failures.append("PROFILE_RED: object-only variant %d must finish in inspect, not crumple" % i)
		if float(variant.get("label_width",0.0)) < 0.68 or float(variant.get("label_height",0.0)) < 0.50:
			failures.append("PROFILE_RED: variant %d label must remain a large tactile hero patch" % i)
		if composition != null:
			var fov := float(composition.target_fov_for_kind(expected_kinds[i]))
			if fov < 34.0 or fov > 42.0:
				failures.append("PROFILE_RED: %s hero framing must stay within close 34-42 degree reference range, got %.2f" % [expected_kinds[i],fov])

	for i in range(5):
		model.select_variant(i)
		if String(model.current_variant().container_profile.get("kind","")) != expected_kinds[i]:
			failures.append("PROFILE_RED: direct navigation must select %s at index %d" % [expected_kinds[i],i])
	return failures
