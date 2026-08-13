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
	if not method_names.has("get_detach_alpha"):
		failures.append("RED: label lifecycle missing progressive detach alpha")
		return failures

	var lifecycle = lifecycle_script.new(0.16)
	lifecycle.reset()
	if lifecycle.get_phase_name() != "ATTACHED":
		failures.append("reset lifecycle should be ATTACHED")
	if lifecycle.is_detached():
		failures.append("reset lifecycle must not be detached")
	if lifecycle.get_detach_alpha() != 0.0:
		failures.append("reset lifecycle detach alpha should be zero")

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

	lifecycle.update(0.20, false, 0.016)
	if lifecycle.get_phase_name() != "HELD":
		failures.append("completed label must not reattach before reset")
	if not lifecycle.is_detached():
		failures.append("completed label must stay detached before reset")

	lifecycle.reset()
	if lifecycle.get_phase_name() != "ATTACHED" or lifecycle.is_detached():
		failures.append("reset should restore ATTACHED and clear detached state")

	return failures
