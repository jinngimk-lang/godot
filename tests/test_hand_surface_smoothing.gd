extends RefCounted

const SCRIPT_PATH := "res://scripts/presentation/hand_surface_smoothing.gd"

func run() -> Array[String]:
	var failures: Array[String] = []
	if not ResourceLoader.exists(SCRIPT_PATH):
		return ["HAND_SMOOTH_RED: missing authored-hand smoothing presentation"]
	var script = load(SCRIPT_PATH)
	if script == null:
		return ["HAND_SMOOTH_RED: smoothing script failed to load"]
	var instance = script.new()
	for method_name in ["smooth_mesh","get_smoothed_mesh_count"]:
		if not instance.has_method(method_name):
			failures.append("HAND_SMOOTH_RED: smoothing presentation missing %s" % method_name)
	instance.free()
	return failures
