extends RefCounted

func run() -> Array[String]:
	var failures: Array[String] = []
	var script = load("res://scripts/presentation/hud_chrome_presentation.gd")
	if script == null:
		return ["HUD_RED: HudChromePresentation script did not load"]

	var root := Node.new()
	var layer := CanvasLayer.new()
	layer.name = "HUD"
	root.add_child(layer)
	var label := Label.new()
	label.name = "Instructions"
	label.text = "COFFEE SHOP  •  Coffee Shop\nPeel 38%  •  Quality A  •  residue 4%\nsteady pull\nlegacy controls"
	layer.add_child(label)

	var chrome = script.new()
	root.add_child(chrome)
	chrome._process(0.0)

	for node_name in ["ProgressPanel","ControlsPanel","HowToPanel"]:
		if layer.get_node_or_null(node_name) == null:
			failures.append("HUD_RED: object-only HUD missing %s" % node_name)
	if layer.get_node_or_null("ProgressPanel/ProgressBar") == null:
		failures.append("HUD_RED: upper-left reference HUD needs a visible horizontal progress bar")

	var progress_panel := layer.get_node_or_null("ProgressPanel") as Control
	if progress_panel != null:
		var copy := _collect_text(progress_panel).to_upper()
		if not copy.contains("SCENE") or not copy.contains("PEEL PROGRESS"):
			failures.append("HUD_RED: upper-left HUD must expose scene title and Peel Progress copy")

	var how_to := layer.get_node_or_null("HowToPanel") as Control
	if how_to != null:
		var copy := _collect_text(how_to).to_upper()
		for required in ["HOW TO PLAY","GRAB EDGE","PEEL GENTLY","INSPECT","CLEAN PEEL"]:
			if not copy.contains(required):
				failures.append("HUD_RED: how-to panel missing %s" % required)
		if copy.contains("YOUR HAND") or copy.contains("HAND MODEL"):
			failures.append("HUD_RED: tutorial must describe mouse/object interaction, never a visible hand model")

	var controls := layer.get_node_or_null("ControlsPanel") as Control
	if controls != null:
		var control_copy := _collect_text(controls)
		for required in ["LMB", "RMB", "Wheel", "R", "1 2 3 4 5", "Esc"]:
			if not control_copy.contains(required):
				failures.append("HUD_RED: control legend missing %s" % required)
		if control_copy.contains("T Reset") or control_copy.contains("R Inspect"):
			failures.append("HUD_RED: obsolete hand-era R Inspect / T Reset mapping is still visible")

	root.free()
	return failures

func _collect_text(node: Node) -> String:
	var output := ""
	if node is Label:
		output += (node as Label).text + "\n"
	if node is Button:
		output += (node as Button).text + "\n"
	for child in node.get_children():
		output += _collect_text(child)
	return output
