extends RefCounted

func run() -> Array[String]:
	var failures: Array[String] = []
	var session = SessionModel.new()
	for variant in session.VARIANTS:
		var model := PeelModel.new({
			"base_adhesion": float(variant.get("base_adhesion", 12.0)),
			"release_increment": float(variant.get("release_increment", 0.045)),
			"speed_gain": float(variant.get("speed_gain", 0.02)),
			"angle_gain": float(variant.get("angle_gain", 0.25)),
			"bond_response": float(variant.get("bond_response", 10.0)),
			"bond_relaxation": float(variant.get("bond_relaxation", 4.0)),
			"safe_pull_speed": float(variant.get("safe_pull_speed", 5.0)),
			"tear_pull_speed": float(variant.get("tear_pull_speed", 12.0)),
			"residue_gain": float(variant.get("residue_gain", 0.18))
		})
		var variant_id := String(variant.get("id", "unknown"))
		for _frame in range(30):
			model.step(30.0, 4.0, PI * 0.5, 1.0 / 60.0)
		if model.is_complete():
			failures.append("PEEL_PACING_RED: %s completes within 0.5 s of sustained clean pull" % variant_id)
		if model.get_progress() > 0.55:
			failures.append("PEEL_PACING_RED: %s releases too much by 0.5 s; progress=%.3f" % [variant_id, model.get_progress()])
		if model.get_progress() < 0.08:
			failures.append("%s should still visibly respond during the first 0.5 s; progress=%.3f" % [variant_id, model.get_progress()])
		for _frame in range(120):
			if model.is_complete():
				break
			model.step(30.0, 4.0, PI * 0.5, 1.0 / 60.0)
		if not model.is_complete():
			failures.append("%s should complete within a short 2.5 s sustained clean peel" % variant_id)
	return failures
