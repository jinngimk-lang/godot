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

	model.record_clean_peel(100)
	if model.get_clean_peels() != 1 or model.get_total_score() != 100:
		failures.append("clean peel should accumulate stamps and score")
	if model.get_unlocked_count() != 1:
		failures.append("second tactile profile should not unlock after only one peel")

	var unlock_two: Dictionary = model.record_clean_peel(90)
	if model.get_unlocked_count() != 2 or not bool(unlock_two.get("unlocked_new", false)):
		failures.append("second tactile profile should unlock on second clean peel")
	model.advance_item()
	var second: Dictionary = model.current_variant()
	if String(second.get("id", "")) == String(first.get("id", "")):
		failures.append("advance_item should rotate to a meaningfully different unlocked tactile profile")
	if float(second.get("base_adhesion", 0.0)) == float(first.get("base_adhesion", 0.0)):
		failures.append("variant rotation must change actual peel feel, not only text")

	model.record_clean_peel(80)
	model.record_clean_peel(70)
	var unlock_three: Dictionary = model.record_clean_peel(60)
	if model.get_unlocked_count() != 3 or not bool(unlock_three.get("unlocked_new", false)):
		failures.append("third tactile profile should unlock on fifth clean peel")

	model.restart_run()
	if model.get_clean_peels() != 0 or model.get_total_score() != 0 or model.get_unlocked_count() != 1:
		failures.append("full run restart should clear progression deterministically")
	if String(model.current_variant().get("id", "")) != "warm_paper":
		failures.append("full run restart should restore first tactile profile")

	return failures
