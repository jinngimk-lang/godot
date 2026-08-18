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
	var composition_path := "res://scripts/presentation/reference_composition.gd"
	var composition = load(composition_path) if ResourceLoader.exists(composition_path) else null
	if composition == null:
		failures.append("BOTTLE_FRAMING_RED: live ReferenceComposition is required")
	for i in range(3):
		var variant: Dictionary = model.VARIANTS[i]
		for key in ["scene_profile","container_profile","post_peel_action"]:
			if not variant.has(key): failures.append("RED: variant %d missing %s" % [i,key])
		if not failures.is_empty(): continue
		if String(variant.scene_profile.get("id","")) != expected_scenes[i]: failures.append("variant %d wrong scene" % i)
		if String(variant.container_profile.get("kind","")) != expected_kinds[i]: failures.append("variant %d wrong container kind" % i)
		if String(variant.post_peel_action) != expected_post[i]: failures.append("variant %d wrong post-peel action" % i)
		if composition != null:
			var camera_fov := float(composition.target_fov_for_kind(expected_kinds[i]))
			if expected_kinds[i] == "paper_cup":
				if camera_fov < 38.0 or camera_fov > 40.0:
					failures.append("BOTTLE_FRAMING_RED: café lens must remain a close 38-40 degrees, got %.2f" % camera_fov)
			else:
				if camera_fov < 41.0 or camera_fov > 45.0:
					failures.append("BOTTLE_FRAMING_RED: bottle lens must stay close enough for the target hero scale, got %.2f" % camera_fov)

	var cafe: Dictionary = model.VARIANTS[0]
	if float(cafe.get("label_width",0.0)) < 0.72:
		failures.append("RED: café receipt is too narrow for the supplied target")
	if float(cafe.get("label_height",0.0)) < 0.56:
		failures.append("RED: café receipt is too short for the supplied target")

	var bar: Dictionary = model.VARIANTS[1]
	if float(bar.get("label_width",0.0)) < 0.74:
		failures.append("RED: bar label must be a large vertical fibrous patch")
	if float(bar.get("label_height",0.0)) < 0.62:
		failures.append("RED: bar label is too short versus the supplied beer-bottle target")

	var market: Dictionary = model.VARIANTS[2]
	if float(market.get("label_width",0.0)) < 0.84:
		failures.append("RED: market label must span the clear-bottle body")
	if float(market.get("label_height",0.0)) < 0.58:
		failures.append("RED: market label is too short versus the supplied Yuzu target")

	model.select_variant(2)
	if String(model.current_variant().container_profile.get("kind","")) != "clear_bottle":
		failures.append("direct navigation should select market bottle even before progression unlock")
	model.select_variant(1)
	if String(model.current_variant().scene_profile.get("id","")) != "night_bar":
		failures.append("direct navigation should select bar profile")
	return failures
