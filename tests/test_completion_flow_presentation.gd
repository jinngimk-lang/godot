extends RefCounted

func run() -> Array[String]:
	var failures: Array[String] = []
	var path := "res://scripts/presentation/completion_flow_presentation.gd"
	if not ResourceLoader.exists(path):
		return ["COMPLETION_FLOW_RED: missing post-peel completion presentation"]
	var flow = load(path).new()
	if not flow.has_method("state_for_phase"):
		failures.append("COMPLETION_FLOW_RED: completion presentation needs deterministic lifecycle mapping")
		flow.free()
		return failures
	var attached: Dictionary = flow.call("state_for_phase","ATTACHED",0.0)
	var settling: Dictionary = flow.call("state_for_phase","SETTLING",1.0)
	var resolved: Dictionary = flow.call("state_for_phase","RESOLVED",1.0)
	if bool(attached.get("visible",true)):
		failures.append("COMPLETION_FLOW_RED: tray/status must stay out of the way before release")
	if String(settling.get("stage","")) != "RELEASED" or not bool(settling.get("visible",false)):
		failures.append("COMPLETION_FLOW_RED: fully released paper needs a brief visible acknowledgement")
	if String(resolved.get("stage","")) != "COLLECTED" or not bool(resolved.get("visible",false)):
		failures.append("COMPLETION_FLOW_RED: resolved paper needs an authored collected/disposed state")
	if not bool(resolved.get("allow_inspect",false)) or not bool(resolved.get("allow_continue",false)):
		failures.append("COMPLETION_FLOW_RED: after disposal the player must be able to inspect residue or continue")
	if float(resolved.get("hero_occlusion",1.0)) > 0.05:
		failures.append("COMPLETION_FLOW_RED: collected label UI must not block the hero product")
	flow.free()
	return failures
