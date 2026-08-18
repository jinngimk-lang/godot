extends RefCounted

func run() -> Array[String]:
	var failures: Array[String] = []
	var shader_path := "res://art/shaders/peeled_paper.gdshader"
	if not ResourceLoader.exists(shader_path):
		failures.append("PAPER_SURFACE_RED: missing real-time peeled paper shader")
		return failures
	var shader := load(shader_path) as Shader
	if shader == null:
		failures.append("PAPER_SURFACE_RED: peeled paper shader did not load")
		return failures
	var code := shader.code
	for token in ["fiber_strength","fiber_scale","NORMAL_MAP","NORMAL_MAP_DEPTH","ROUGHNESS","use_print"]:
		if token not in code:
			failures.append("PAPER_SURFACE_RED: peeled paper shader missing %s" % token)
	var corner_script = load("res://scripts/presentation/corner_peel_presentation.gd")
	if corner_script == null:
		failures.append("corner peel presentation did not load")
	else:
		var corner = corner_script.new()
		if not corner.has_method("get_paper_surface_shader_path"):
			failures.append("PAPER_SURFACE_RED: corner peel renderer must own the fibrous shader contract")
		elif String(corner.call("get_paper_surface_shader_path")) != shader_path:
			failures.append("corner peel renderer points at wrong paper shader")
		corner.free()
	return failures
