extends RefCounted

func run() -> Array[String]:
	var failures: Array[String] = []
	var model = SessionModel.new()
	var cafe: Dictionary = model.current_variant()
	var hint := String(cafe.get("hint", "")).to_lower()
	if "peel anywhere" in hint:
		failures.append("PEEL_GUIDANCE_RED: café hint must not teach obsolete peel-anywhere behavior")
	if not ("edge" in hint and "lift" in hint):
		failures.append("PEEL_GUIDANCE_RED: café hint must teach grab-edge then lift before peeling")
	return failures
