extends RefCounted
class_name ScoreModel

static func score(base_area: float, completion: float, continuity: float) -> int:
	var safe_base := maxf(base_area, 0.0)
	var safe_completion := clampf(completion, 0.0, 1.0)
	var safe_continuity := clampf(continuity, 0.0, 1.0)
	return maxi(int(round(safe_base * safe_completion * safe_continuity)), 0)
