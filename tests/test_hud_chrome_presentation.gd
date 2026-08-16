extends RefCounted

func run() -> Array[String]:
	var failures: Array[String] = []
	var script = load("res://scripts/presentation/hud_chrome_presentation.gd")
	if script == null:
		failures.append("HudChromePresentation script did not load")
		return failures

	var methods: Array[String] = []
	for method in script.get_script_method_list():
		methods.append(String(method.get("name", "")))
	if not methods.has("_compact_hud_text"):
		failures.append("RED: reference HUD must expose compact player-facing copy")
		return failures

	var root := Node.new()
	var layer := CanvasLayer.new()
	layer.name = "HUD"
	root.add_child(layer)
	var label := Label.new()
	label.name = "Instructions"
	layer.add_child(label)
	label.text = "AMBER BAR  •  Amber Bar Bottle\nPeel 48%  •  Quality A  •  residue 0%\nsteady pull • ease off if the paper starts to tear\nLMB Peel anywhere  •  RMB Inspect  •  Q/E Scene  •  1/2/3  •  Esc Pause  •  R Reset"

	var chrome = script.new()
	root.add_child(chrome)
	chrome._process(0.0)

	var panel := layer.get_node_or_null("ReferenceHudPanel") as Panel
	if panel == null:
		failures.append("reference HUD panel was not created")
	else:
		if panel.size.y > 68.0:
			failures.append("RED: reference HUD panel must stay <= 68 px tall, got %.1f" % panel.size.y)
		if panel.size.x > 560.0:
			failures.append("RED: reference HUD panel must stay <= 560 px wide, got %.1f" % panel.size.x)

	var lines := label.text.split("\n", false)
	if lines.size() > 2:
		failures.append("RED: normal reference HUD must use at most two persistent lines, got %d" % lines.size())
	for debug_fragment in ["Quality", "residue", "1/2/3", "Q/E Scene"]:
		if label.text.contains(debug_fragment):
			failures.append("RED: reference HUD must not persist debug/control-wall fragment: %s" % debug_fragment)
	if not label.text.contains("Peel 48%"):
		failures.append("compact HUD must preserve peel progress")
	if not label.text.contains("Mouse / touch peel"):
		failures.append("compact HUD must preserve input-neutral peel discoverability")
	if not label.text.contains("RMB inspect"):
		failures.append("compact HUD must preserve inspect discoverability")
	if not label.text.contains("Esc Pause") or not label.text.contains("R Reset"):
		failures.append("compact HUD must preserve pause and reset affordances")

	root.free()
	return failures
