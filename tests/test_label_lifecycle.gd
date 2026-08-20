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
	for method_name in ["get_detach_alpha", "get_settle_alpha", "is_resolved", "is_next_ready"]:
		if not method_names.has(method_name):
			failures.append("RED: label lifecycle missing %s" % method_name)
	if not failures.is_empty():
		return failures

	var lifecycle = lifecycle_script.new(0.16, 0.40, 0.60)
	lifecycle.reset()
	if lifecycle.get_phase_name() != "ATTACHED":
		failures.append("reset lifecycle should be ATTACHED")
	if lifecycle.is_detached():
		failures.append("reset lifecycle must not be detached")
	if lifecycle.get_detach_alpha() != 0.0:
		failures.append("reset lifecycle detach alpha should be zero")
	if lifecycle.get_settle_alpha() != 0.0:
		failures.append("reset lifecycle settle alpha should be zero")

	lifecycle.update(0.45, false, 0.016)
	if lifecycle.get_phase_name() != "PEELING":
		failures.append("partial progress should be PEELING")
	if lifecycle.is_detached():
		failures.append("partial progress must remain cup-attached")

	lifecycle.update(1.0, true, 0.016)
	if lifecycle.get_phase_name() != "DETACHING":
		failures.append("completion should enter DETACHING")
	if lifecycle.get_detach_alpha() != 0.0:
		failures.append("DETACHING should begin at zero blend")
	if lifecycle.consume_detach_event():
		failures.append("detach event should not fire before detach duration elapses")

	lifecycle.update(1.0, false, 0.08)
	var half_alpha: float = lifecycle.get_detach_alpha()
	if half_alpha < 0.45 or half_alpha > 0.55:
		failures.append("half detach duration should produce about half blend")

	lifecycle.update(1.0, false, 0.10)
	if lifecycle.get_phase_name() != "HELD":
		failures.append("elapsed detach duration should enter HELD")
	if lifecycle.get_detach_alpha() != 1.0:
		failures.append("HELD lifecycle detach alpha should be one")
	if not lifecycle.is_detached():
		failures.append("HELD lifecycle must report detached")
	if not lifecycle.consume_detach_event():
		failures.append("entering HELD should emit one detach event")
	if lifecycle.consume_detach_event():
		failures.append("detach event must be consumable exactly once")

	lifecycle.update(1.0, false, 0.20)
	if lifecycle.get_phase_name() != "HELD":
		failures.append("released label should remain held during the completion beat")
	if not lifecycle.is_detached():
		failures.append("completed label must stay detached before reset")

	lifecycle.update(1.0, false, 0.21)
	if lifecycle.get_phase_name() != "SETTLING":
		failures.append("released label should enter SETTLING after the completion hold")
	if lifecycle.get_settle_alpha() != 0.0:
		failures.append("SETTLING should begin at zero blend")

	lifecycle.update(1.0, false, 0.30)
	var settle_midpoint: float = lifecycle.get_settle_alpha()
	if settle_midpoint < 0.45 or settle_midpoint > 0.55:
		failures.append("half settle duration should produce about half blend")

	lifecycle.update(1.0, false, 0.31)
	if lifecycle.get_phase_name() != "RESOLVED":
		failures.append("released label should resolve after the settle duration")
	if not lifecycle.is_resolved():
		failures.append("resolved lifecycle should report resolved")
	if not lifecycle.is_next_ready():
		failures.append("resolved lifecycle should make the next interaction ready")
	if lifecycle.get_settle_alpha() != 1.0:
		failures.append("resolved lifecycle settle alpha should be one")
	if not lifecycle.is_detached():
		failures.append("resolved label must remain detached")

	lifecycle.reset()
	if lifecycle.get_phase_name() != "ATTACHED" or lifecycle.is_detached():
		failures.append("reset should restore ATTACHED and clear detached state")
	if lifecycle.get_settle_alpha() != 0.0:
		failures.append("reset should clear released-label settle progress")

	return failures
