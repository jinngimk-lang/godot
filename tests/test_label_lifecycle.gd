extends RefCounted

func run() -> Array[String]:
	var failures: Array[String] = []
	var lifecycle_path := "res://scripts/peel/label_lifecycle.gd"
	if not ResourceLoader.exists(lifecycle_path):
		failures.append("RED: missing label detach lifecycle contract")
		return failures

	var lifecycle_script = load(lifecycle_path)
	if lifecycle_script == null:
		failures.append("label lifecycle script did not load")
		return failures
	var method_names: Array[String] = []
	for method in lifecycle_script.get_script_method_list():
		method_names.append(String(method.get("name", "")))
	for required_method in ["get_detach_alpha", "get_release_settle_alpha", "should_render_label", "is_resolved"]:
		if not method_names.has(required_method):
			failures.append("POST_RELEASE_RED: label lifecycle missing %s" % required_method)
	if not failures.is_empty():
		return failures

	var lifecycle = lifecycle_script.new(0.16, 0.72)
	lifecycle.reset()
	if lifecycle.get_phase_name() != "ATTACHED":
		failures.append("reset lifecycle should be ATTACHED")
	if lifecycle.is_detached():
		failures.append("reset lifecycle must not be detached")
	if lifecycle.get_detach_alpha() != 0.0:
		failures.append("reset lifecycle detach alpha should be zero")
	if not lifecycle.should_render_label():
		failures.append("attached label must render")

	lifecycle.update(0.45, false, 0.016)
	if lifecycle.get_phase_name() != "PEELING":
		failures.append("partial progress should be PEELING")

	lifecycle.update(1.0, true, 0.016)
	if lifecycle.get_phase_name() != "DETACHING":
		failures.append("completion should enter DETACHING")
	if lifecycle.consume_detach_event():
		failures.append("detach event should not fire before detach duration elapses")

	lifecycle.update(1.0, false, 0.08)
	var half_alpha: float = lifecycle.get_detach_alpha()
	if half_alpha < 0.45 or half_alpha > 0.55:
		failures.append("half detach duration should produce about half detach blend")

	lifecycle.update(1.0, false, 0.10)
	if lifecycle.get_phase_name() != "SETTLING":
		failures.append("elapsed detach duration should enter SETTLING")
	if not lifecycle.is_detached():
		failures.append("SETTLING label must report detached")
	if not lifecycle.consume_detach_event():
		failures.append("entering SETTLING should emit one detach event")
	if lifecycle.get_release_settle_alpha() > 0.05:
		failures.append("SETTLING should start visible before disposal")
	if not lifecycle.should_render_label():
		failures.append("newly detached label should remain briefly visible")

	lifecycle.update(1.0, false, 0.36)
	var mid_settle := lifecycle.get_release_settle_alpha()
	if mid_settle < 0.40 or mid_settle > 0.60:
		failures.append("half settle duration should be about half resolved")
	if not lifecycle.should_render_label():
		failures.append("label should still render during settle motion")

	lifecycle.update(1.0, false, 0.40)
	if lifecycle.get_phase_name() != "RESOLVED":
		failures.append("released label should leave SETTLING and become RESOLVED")
	if not lifecycle.is_resolved():
		failures.append("RESOLVED lifecycle must report resolved")
	if lifecycle.should_render_label():
		failures.append("resolved label must no longer block the hero product")
	if lifecycle.consume_detach_event():
		failures.append("detach event must remain one-shot")

	lifecycle.update(0.20, false, 0.016)
	if lifecycle.get_phase_name() != "RESOLVED":
		failures.append("completed label must not reattach before reset")

	lifecycle.reset()
	if lifecycle.get_phase_name() != "ATTACHED" or lifecycle.is_detached() or lifecycle.is_resolved():
		failures.append("reset should restore ATTACHED and clear detached/resolved state")

	return failures
