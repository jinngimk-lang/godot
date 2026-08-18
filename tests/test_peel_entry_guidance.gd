extends RefCounted

func run() -> Array[String]:
	var failures: Array[String] = []
	var model = SessionModel.new()
	var cafe: Dictionary = model.current_variant()
	var hint := String(cafe.get("hint", "")).to_lower()
	if "peel anywhere" in hint:
		failures.append("PEEL_GUIDANCE_RED: café hint must not teach obsolete peel-anywhere behavior")
	if not ("grab" in hint and ("corner" in hint or "edge" in hint)):
		failures.append("PEEL_GUIDANCE_RED: café hint must teach the small hand cursor to grab a label corner/edge before dragging")
	return failures
