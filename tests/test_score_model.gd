extends RefCounted

func run() -> Array[String]:
	var failures: Array[String] = []
	var script = load("res://scripts/scoring/score_model.gd")
	if script == null:
		failures.append("ScoreModel script did not load")
		return failures
	if script.score(100.0, 1.0, 0.8) != 80:
		failures.append("score should multiply base area by completion and continuity")
	if script.score(100.0, 0.0, 1.0) != 0:
		failures.append("incomplete peel should not receive completion reward")
	if script.score(-100.0, 2.0, -1.0) != 0:
		failures.append("score inputs should clamp to safe non-negative ranges")
	return failures
