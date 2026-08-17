extends RefCounted

func run() -> Array[String]:
	var failures: Array[String] = []
	var required := "res://scripts/session/session_model.gd"
	if not ResourceLoader.exists(required):
		failures.append("POST_PEEL_RED: missing session progression model")
		return failures

	var model = load(required).new()
	if String(model.current_variant().get("id", "")) != "warm_paper":
		failures.append("POST_PEEL_RED: run must start in café/warm_paper")
		return failures

	var first_result: Dictionary = model.record_ritual_complete()
	if model.get_unlocked_count() != 2 or not bool(first_result.get("unlocked_new", false)):
		failures.append("POST_PEEL_RED: completing café once must unlock the bar immediately")
	model.advance_item()
	if String(model.current_variant().get("id", "")) != "silky_long":
		failures.append("POST_PEEL_RED: Continue after café must advance to amber bar, not loop café")

	var second_result: Dictionary = model.record_ritual_complete()
	if model.get_unlocked_count() != 3 or not bool(second_result.get("unlocked_new", false)):
		failures.append("POST_PEEL_RED: completing bar once must unlock the market immediately")
	model.advance_item()
	if String(model.current_variant().get("id", "")) != "crisp_seal":
		failures.append("POST_PEEL_RED: Continue after bar must advance to market")

	var third_result: Dictionary = model.record_ritual_complete()
	if model.get_unlocked_count() != 3 or bool(third_result.get("unlocked_new", false)):
		failures.append("POST_PEEL_RED: completing market must keep all three scenes unlocked without duplicate unlock")
	model.advance_item()
	if String(model.current_variant().get("id", "")) != "warm_paper":
		failures.append("POST_PEEL_RED: Continue after market must wrap to café")

	return failures
