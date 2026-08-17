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

		# ReferenceComposition promises a hand-and-object closeup where the hero
		# vessel occupies roughly one-half to two-thirds of frame height. The
		# taller bottle meshes need a slightly wider vertical lens than the café
		# cup so their mouth remains inside the 720p acceptance capture instead
		# of being cropped by the top edge.
		var camera_fov := float((variant.scene_profile as Dictionary).get("camera_fov",39.0))
		if expected_kinds[i] == "paper_cup":
			if absf(camera_fov-39.0) > 0.1:
				failures.append("BOTTLE_FRAMING_RED: café closeup lens must remain 39 degrees, got %.2f" % camera_fov)
		else:
			if camera_fov < 47.0:
				failures.append("BOTTLE_FRAMING_RED: %s needs a wider bottle lens so the full slender vessel stays in frame, got %.2f" % [expected_scenes[i],camera_fov])
			if camera_fov > 50.0:
				failures.append("BOTTLE_FRAMING_RED: %s lens became too wide for the reference closeup, got %.2f" % [expected_scenes[i],camera_fov])

	var cafe: Dictionary = model.VARIANTS[0]
	var cafe_width := float(cafe.get("label_width",0.0))
	var cafe_height := float(cafe.get("label_height",0.0))
	if cafe_width <= 0.0 or cafe_height <= 0.0:
		failures.append("RED: café label dimensions must be positive")
	else:
		var aspect := cafe_width/cafe_height
		if cafe_width > 0.72:
			failures.append("RED: approved café receipt needs a narrower silhouette, got %.3f m" % cafe_width)
		if cafe_height < 0.54:
			failures.append("RED: approved café receipt needs stronger vertical presence, got %.3f m" % cafe_height)
		if aspect > 1.35:
			failures.append("RED: café receipt should read near-square rather than landscape, aspect %.2f" % aspect)

	model.select_variant(2)
	if String(model.current_variant().container_profile.get("kind","")) != "clear_bottle":
		failures.append("direct navigation should select market bottle even before progression unlock")
	model.select_variant(1)
	if String(model.current_variant().scene_profile.get("id","")) != "night_bar":
		failures.append("direct navigation should select bar profile")
	return failures
