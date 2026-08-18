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
		"get_ready_hand_count",
		"get_visible_authored_hand_mesh_count",
		"get_visible_realtime_shell_count",
		"get_visible_primitive_shell_mesh_count",
		"get_cinematic_forearm_span",
		"is_skin_physically_lit"
	]:
		if not methods.has(required_method):
			failures.append("RED: cinematic hand presentation missing realtime authority contract %s" % required_method)
	if methods.has("is_skin_physically_lit"):
		var player = script.new()
		if not bool(player.call("is_skin_physically_lit")):
			failures.append("RED: final hand skin must use normal scene lighting rather than an unshaded flat-color pass")
		player.free()
	return failures
