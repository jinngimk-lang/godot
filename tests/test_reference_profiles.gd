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

	var cafe_label_profile: Dictionary = cafe.get("label_profile",{}) as Dictionary
	var cafe_fill := float(cafe_label_profile.get("front_fill",0.0))
	if cafe_fill < 0.20 or cafe_fill > 0.65:
		failures.append("RED: café thermal-paper receipt needs bounded front_fill 0.20..0.65 after measured dark-face mismatch, got %.3f" % cafe_fill)
	for i in [1,2]:
		var other_profile: Dictionary = (model.VARIANTS[i] as Dictionary).get("label_profile",{}) as Dictionary
		var other_fill := float(other_profile.get("front_fill",0.0))
		if absf(other_fill) > 0.001:
			failures.append("RED: front paper bounce is Café-only; variant %d front_fill must stay 0, got %.3f" % [i,other_fill])

	model.select_variant(2)
	if String(model.current_variant().container_profile.get("kind","")) != "clear_bottle":
		failures.append("direct navigation should select market bottle even before progression unlock")
	model.select_variant(1)
	if String(model.current_variant().scene_profile.get("id","")) != "night_bar":
		failures.append("direct navigation should select bar profile")
	return failures
