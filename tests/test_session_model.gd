extends RefCounted

func run() -> Array[String]:
	var failures: Array[String] = []
	var required := "res://scripts/session/session_model.gd"
	if not ResourceLoader.exists(required):
		return ["SESSION_RED: missing session model"]
	var model = load(required).new()
	if model.VARIANTS.size() != 5:
		return ["SESSION_RED: object-only showcase requires five variants"]
	if model.get_unlocked_count() != 5:
		failures.append("SESSION_RED: all five object scenes must be directly available from the persistent rail")
	if model.get_variant_index() != 0:
		failures.append("SESSION_RED: session must start on Coffee Shop")

	var expected_ids := ["coffee_shop","sauce_jar","tin_can","yuzu_bottle","lemon_can"]
	var silhouette_signatures: Array[String] = []
	var label_signatures: Array[String] = []
	for i in range(model.VARIANTS.size()):
		var variant: Dictionary = model.VARIANTS[i]
		if String(variant.get("id","")) != expected_ids[i]:
			failures.append("SESSION_RED: variant %d must use id %s" % [i,expected_ids[i]])
		for key in ["cup_dimensions","container_profile","scene_profile","label_profile","label_width","label_height","post_peel_action"]:
			if not variant.has(key):
				failures.append("SESSION_RED: variant %d missing %s" % [i,key])
		if String(variant.get("post_peel_action","")) != "inspect":
			failures.append("SESSION_RED: object-only variant %d must finish in inspect" % i)
		var dims: Dictionary = variant.get("cup_dimensions",{})
		var signature := "%.3f/%.3f/%.3f" % [float(dims.get("top_radius",0.0)),float(dims.get("bottom_radius",0.0)),float(dims.get("height",0.0))]
		if signature in silhouette_signatures:
			failures.append("SESSION_RED: hero silhouettes must remain materially distinct, duplicate=%s" % signature)
		silhouette_signatures.append(signature)
		var label_profile: Dictionary = variant.get("label_profile",{})
		for key in ["substrate","roughness","thickness_scale","fiber_scale","adhesive_trace","adhesive_tint","fiber_tint","fiber_gain"]:
			if not label_profile.has(key):
				failures.append("SESSION_RED: %s label profile missing %s" % [String(variant.get("id","unknown")),key])
		var label_signature := "%s/%.2f/%.2f/%.2f/%.2f" % [String(label_profile.get("substrate","")),float(label_profile.get("roughness",0.0)),float(label_profile.get("thickness_scale",0.0)),float(label_profile.get("fiber_scale",0.0)),float(label_profile.get("adhesive_trace",0.0))]
		if label_signature in label_signatures:
			failures.append("SESSION_RED: five labels need distinct tactile signatures")
		label_signatures.append(label_signature)

	for i in range(5):
		model.select_variant(i)
		if model.get_variant_index() != i:
			failures.append("SESSION_RED: direct scene selection must accept index %d" % i)
	model.select_variant(4)
	model.advance_item()
	if model.get_variant_index() != 0:
		failures.append("SESSION_RED: Continue after Can must wrap to Coffee Shop")

	var before_clean := model.get_clean_peels()
	var result: Dictionary = model.record_ritual_complete()
	if model.get_clean_peels() != before_clean+1:
		failures.append("SESSION_RED: completed peel should increment completion count once")
	if bool(result.get("unlocked_new",true)):
		failures.append("SESSION_RED: no unlock event should fire because all five scenes start available")

	model.restart_run()
	if model.get_variant_index() != 0 or model.get_clean_peels() != 0 or model.get_total_score() != 0 or model.get_unlocked_count() != 5:
		failures.append("SESSION_RED: restart must restore Coffee Shop while keeping all five scene buttons available")
	return failures
