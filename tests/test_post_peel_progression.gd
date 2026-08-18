extends RefCounted

func run() -> Array[String]:
	var failures: Array[String] = []
	var model = SessionModel.new()
	var expected_ids := ["coffee_shop","sauce_jar","tin_can","yuzu_bottle","lemon_can"]
	if model.get_unlocked_count() != 5:
		failures.append("POST_PEEL_RED: all five scenes must be available immediately")
	for i in range(5):
		if String(model.current_variant().get("id","")) != expected_ids[i]:
			failures.append("POST_PEEL_RED: expected %s at scene index %d" % [expected_ids[i],i])
		var result: Dictionary = model.record_ritual_complete()
		if bool(result.get("unlocked_new",true)):
			failures.append("POST_PEEL_RED: completion must not gate scenes behind unlocks")
		model.advance_item()
	if String(model.current_variant().get("id","")) != "coffee_shop":
		failures.append("POST_PEEL_RED: fifth Continue must wrap back to Coffee Shop")
	if model.get_clean_peels() != 5:
		failures.append("POST_PEEL_RED: five completed labels should record exactly five completions")
	return failures
