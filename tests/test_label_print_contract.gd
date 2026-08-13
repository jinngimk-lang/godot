extends RefCounted

func run() -> Array[String]:
	var failures: Array[String] = []
	var print_path := "res://scripts/peel/label_print.gd"
	if not ResourceLoader.exists(print_path):
		failures.append("RED: missing deforming label print provider")
		return failures

	var print_script = load(print_path)
	if print_script == null:
		failures.append("LabelPrint script did not load")
		return failures

	var print_methods := _method_names(print_script)
	if not print_methods.has("set_order"):
		failures.append("LabelPrint must expose set_order")

	var visual_script = load("res://scripts/peel/label_visual.gd")
	if visual_script == null:
		failures.append("LabelVisual script did not load")
	else:
		var visual_methods := _method_names(visual_script)
		if not visual_methods.has("set_print_texture"):
			failures.append("LabelVisual must accept a print texture")

	var lab_source := FileAccess.get_file_as_string("res://scripts/peel_lab.gd")
	if lab_source.contains("OrderPrint") or lab_source.contains("Label3D.new()"):
		failures.append("world-space OrderPrint Label3D must be removed from the peel scene")

	return failures

func _method_names(script: Script) -> Array[String]:
	var names: Array[String] = []
	for method in script.get_script_method_list():
		names.append(String(method.get("name", "")))
	return names
