extends RefCounted

func run() -> Array[String]:
	var failures: Array[String] = []
	var script = load("res://scripts/presentation/hud_chrome_presentation.gd")
	if script == null:
		failures.append("HudChromePresentation script did not load")
		return failures

	var root := Node.new()
	var layer := CanvasLayer.new()
	layer.name = "HUD"
	root.add_child(layer)
	var label := Label.new()
	label.name = "Instructions"
	label.text = "AMBER BAR  •  Amber Bar Bottle\nPeel 48%  •  Quality B  •  residue 12%\nsteady pull\nlegacy controls"
	layer.add_child(label)

	var chrome = script.new()
	root.add_child(chrome)
	chrome._process(0.0)

	for node_name in ["ProgressPanel","ObjectivePanel","ControlsPanel","HowToPanel"]:
		if layer.get_node_or_null(node_name) == null:
			failures.append("HUD_RED: unified HUD missing %s" % node_name)

	var how_to := layer.get_node_or_null("HowToPanel") as Control
	if how_to != null:
		var copy := _collect_text(how_to).to_upper()
		for required in ["GRAB EDGE","PEEL GENTLY","INSPECT","CLEAN PEEL"]:
			if not copy.contains(required):
				failures.append("HUD_RED: how-to panel missing %s" % required)

	var controls := layer.get_node_or_null("ControlsPanel") as Control
	if controls != null:
		var control_copy := _collect_text(controls)
		for required in ["LMB", "RMB", "R Inspect", "T Reset", "1/2/3", "Esc"]:
			if not control_copy.contains(required):
				failures.append("HUD_RED: control legend missing %s" % required)

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
