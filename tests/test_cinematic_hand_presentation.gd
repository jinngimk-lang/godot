extends RefCounted

const SCRIPT_PATH := "res://scripts/presentation/cinematic_hand_presentation.gd"

func run() -> Array[String]:
	var failures: Array[String] = []
	if not ResourceLoader.exists(SCRIPT_PATH):
		failures.append("RED: missing cinematic hand presentation layer")
		return failures
	var script = load(SCRIPT_PATH)
	if script == null:
		failures.append("RED: cinematic hand presentation script did not load")
		return failures
	var methods: Array[String] = []
	for method in script.get_script_method_list():
		methods.append(String(method.get("name", "")))
	for required_method in [
		"get_shell_ready_count",
		"get_visible_legacy_hand_mesh_count",
		"get_shell_piece_count",
		"get_cinematic_forearm_span"
	]:
		if not methods.has(required_method):
			failures.append("RED: cinematic hand presentation missing runtime contract %s" % required_method)
	return failures
