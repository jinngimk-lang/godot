extends RefCounted

func run() -> Array[String]:
	var failures: Array[String] = []
	var required := "res://scripts/session/session_model.gd"
	if not ResourceLoader.exists(required):
		failures.append("RED: missing complete-session progression contract")
		return failures

	var model = load(required).new()
	var first: Dictionary = model.current_variant()
	if String(first.get("id", "")) != "warm_paper":
		failures.append("session should start on warm_paper")
	if model.get_unlocked_count() != 1:
		failures.append("session should start with one unlocked tactile profile")

	for key in ["cup_shell", "cup_dimensions", "crumple_profile", "contents_profile", "reward_theme"]:
		if not first.has(key):
			failures.append("RED: tactile profile missing V5 sensory field %s" % key)
	if failures.size() > 0:
		return failures

	var first_dims: Dictionary = first.get("cup_dimensions", {})
	var first_crumple: Dictionary = first.get("crumple_profile", {})
	var first_contents: Dictionary = first.get("contents_profile", {})
	if float(first_dims.get("top_radius", 0.0)) <= 0.0 or float(first_dims.get("bottom_radius", 0.0)) <= 0.0 or float(first_dims.get("height", 0.0)) <= 0.0:
		failures.append("cup profile dimensions must be positive")
	if float(first_crumple.get("max_compression", 0.0)) <= 0.0 or float(first_crumple.get("max_compression", 0.0)) >= 0.5:
		failures.append("crumple profile should define a bounded physical compression range")
	if String(first_contents.get("type", "")) != "none":
		failures.append("fresh warm_paper baseline should remain visually quiet with no contents")

	if not model.has_method("record_ritual_complete"):
		failures.append("RED: session progression must expose score-independent record_ritual_complete")
		return failures

	var first_result: Dictionary = model.record_ritual_complete()
	if model.get_clean_peels() != 1:
		failures.append("one completed ritual should advance progression exactly once")
	if model.get_total_score() != 0:
		failures.append("ritual progression must not require public score accumulation")
	if model.get_unlocked_count() != 2 or not bool(first_result.get("unlocked_new", false)):
		failures.append("POST_PEEL_RED: first completed café ritual should unlock amber bar immediately")
	model.advance_item()
	var second: Dictionary = model.current_variant()
	if String(second.get("id", "")) != "silky_long":
		failures.append("POST_PEEL_RED: first Continue must rotate café to amber bar")
	if float(second.get("base_adhesion", 0.0)) == float(first.get("base_adhesion", 0.0)):
		failures.append("variant rotation must change actual peel feel, not only text")
	var second_crumple: Dictionary = second.get("crumple_profile", {})
	if is_equal_approx(float(second_crumple.get("rigidity", 0.0)), float(first_crumple.get("rigidity", 0.0))) and is_equal_approx(float(second_crumple.get("max_compression", 0.0)), float(first_crumple.get("max_compression", 0.0))):
		failures.append("unlocked cup variants should change crumple feel, not only label feel")

	var second_result: Dictionary = model.record_ritual_complete()
	if model.get_unlocked_count() != 3 or not bool(second_result.get("unlocked_new", false)):
		failures.append("POST_PEEL_RED: completed bar ritual should unlock market immediately")
	model.advance_item()
	if String(model.current_variant().get("id", "")) != "crisp_seal":
		failures.append("POST_PEEL_RED: second Continue must rotate amber bar to market")

	# V6 sensory profile contract: each tactile cup must read as a distinct silhouette,
	# and only the final profile may introduce a small contained ice layer.
	var silhouette_signatures: Array[String] = []
	for i in range(model.VARIANTS.size()):
		var variant: Dictionary = model.VARIANTS[i]
		var dims: Dictionary = variant.get("cup_dimensions", {})
		var signature := "%.3f/%.3f/%.3f" % [
			float(dims.get("top_radius", 0.0)),
			float(dims.get("bottom_radius", 0.0)),
			float(dims.get("height", 0.0))
		]
		if signature in silhouette_signatures:
			failures.append("RED: tactile cup silhouettes must be materially distinct, duplicate=%s" % signature)
		silhouette_signatures.append(signature)

		var contents: Dictionary = variant.get("contents_profile", {})
		if i < model.VARIANTS.size() - 1:
			if String(contents.get("type", "")) != "none":
				failures.append("only the final tactile cup should introduce contents")
		else:
			if String(contents.get("type", "")) != "ice":
				failures.append("RED: final tactile cup should introduce bounded contained ice")
			var count := int(contents.get("count", 0))
			var cube_size := float(contents.get("cube_size", 0.0))
			var motion_gain := float(contents.get("motion_gain", -1.0))
			if count < 2 or count > 5:
				failures.append("ice count should stay deliberately small (2..5), got %d" % count)
			if cube_size < 0.07 or cube_size > 0.16:
				failures.append("ice cube size should stay visually legible but contained, got %.3f" % cube_size)
			if motion_gain < 0.0 or motion_gain > 1.0:
				failures.append("ice motion gain must be bounded 0..1, got %.3f" % motion_gain)

	# Every current tactile cup should take a short sequence of deliberate squeezes,
	# not jump from fresh to complete on one representative 50 px inward drag.
	var crumple_script := load("res://scripts/cup/cup_crumple_model.gd")
	for variant in model.VARIANTS:
		var profile: Dictionary = variant.get("crumple_profile", {})
		var crumple = crumple_script.new(profile)
		crumple.begin_gesture(-100.0, 0.0)
		crumple.apply_drag(50.0)
		var first_squeeze: float = float(crumple.get_progress())
		if first_squeeze <= 0.05 or first_squeeze >= 0.45:
			failures.append("RED: %s should need several intentional squeezes; first 50px progress=%.3f" % [String(variant.get("id", "unknown")), first_squeeze])
		for _i in range(5):
			crumple.apply_drag(50.0)
		if not crumple.is_complete():
			failures.append("%s should still reach completion within a short six-squeeze ritual" % String(variant.get("id", "unknown")))

	# Legacy score API stays compatible for old callers, but score is no longer required for progression.
	model.restart_run()
	var legacy_result: Dictionary = model.record_clean_peel(75)
	if model.get_clean_peels() != 1 or model.get_total_score() != 75:
		failures.append("legacy clean-peel API should remain compatible while delegating ritual progression")
	if model.get_unlocked_count() != 2 or not bool(legacy_result.get("unlocked_new", false)):
		failures.append("legacy compatibility wrapper must keep the same immediate next-scene unlock cadence")

	model.restart_run()
	if model.get_clean_peels() != 0 or model.get_total_score() != 0 or model.get_unlocked_count() != 1:
		failures.append("full run restart should clear progression deterministically")
	if String(model.current_variant().get("id", "")) != "warm_paper":
		failures.append("full run restart should restore first tactile profile")

	return failures
