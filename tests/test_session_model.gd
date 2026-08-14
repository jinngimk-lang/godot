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
		failures.append("current V5 baseline should expose future contents through explicit none profile")

	if not model.has_method("record_ritual_complete"):
		failures.append("RED: session progression must expose score-independent record_ritual_complete")
		return failures

	var first_result: Dictionary = model.record_ritual_complete()
	if model.get_clean_peels() != 1:
		failures.append("one completed ritual should advance progression exactly once")
	if model.get_total_score() != 0:
		failures.append("ritual progression must not require public score accumulation")
	if bool(first_result.get("unlocked_new", true)):
		failures.append("second tactile profile should not unlock after only one ritual")

	var unlock_two: Dictionary = model.record_ritual_complete()
	if model.get_unlocked_count() != 2 or not bool(unlock_two.get("unlocked_new", false)):
		failures.append("second tactile profile should unlock on second completed ritual")
	model.advance_item()
	var second: Dictionary = model.current_variant()
	if String(second.get("id", "")) == String(first.get("id", "")):
		failures.append("advance_item should rotate to a meaningfully different unlocked tactile profile")
	if float(second.get("base_adhesion", 0.0)) == float(first.get("base_adhesion", 0.0)):
		failures.append("variant rotation must change actual peel feel, not only text")
	var second_crumple: Dictionary = second.get("crumple_profile", {})
	if is_equal_approx(float(second_crumple.get("rigidity", 0.0)), float(first_crumple.get("rigidity", 0.0))) and is_equal_approx(float(second_crumple.get("max_compression", 0.0)), float(first_crumple.get("max_compression", 0.0))):
		failures.append("unlocked cup variants should change crumple feel, not only label feel")

	model.record_ritual_complete()
	model.record_ritual_complete()
	var unlock_three: Dictionary = model.record_ritual_complete()
	if model.get_unlocked_count() != 3 or not bool(unlock_three.get("unlocked_new", false)):
		failures.append("third tactile profile should unlock on fifth completed ritual")

	# Legacy score API stays compatible for old callers, but score is no longer required for progression.
	model.restart_run()
	var legacy_result: Dictionary = model.record_clean_peel(75)
	if model.get_clean_peels() != 1 or model.get_total_score() != 75:
		failures.append("legacy clean-peel API should remain compatible while delegating ritual progression")
	if bool(legacy_result.get("unlocked_new", true)):
		failures.append("legacy compatibility wrapper must keep the same unlock cadence")

	model.restart_run()
	if model.get_clean_peels() != 0 or model.get_total_score() != 0 or model.get_unlocked_count() != 1:
		failures.append("full run restart should clear progression deterministically")
	if String(model.current_variant().get("id", "")) != "warm_paper":
		failures.append("full run restart should restore first tactile profile")

	return failures
