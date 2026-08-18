extends Node
class_name HudChromePresentation

var _applied := false
var _progress_copy: Label
var _objective_copy: Label
var _controls_copy: Label
var _how_to_copy: Label

func _process(_delta: float) -> void:
	var root := get_parent()
	if root == null:
		return
	var layer := root.get_node_or_null("HUD") as CanvasLayer
	var legacy := root.get_node_or_null("HUD/Instructions") as Label
	if layer == null or legacy == null:
		return
	if not _applied:
		_build_ui(layer, legacy)
	_refresh_status(root, legacy.text)

func _build_ui(layer: CanvasLayer, legacy: Label) -> void:
	legacy.visible = false

	var progress_panel := _panel("ProgressPanel", Vector2(16,16), Vector2(300,104))
	layer.add_child(progress_panel)
	_progress_copy = _label("ProgressCopy", Vector2(14,10), Vector2(272,82), 17)
	progress_panel.add_child(_progress_copy)

	var objective_panel := _panel("ObjectivePanel", Vector2(16,134), Vector2(224,184))
	layer.add_child(objective_panel)
	_objective_copy = _label("ObjectiveCopy", Vector2(14,12), Vector2(196,158), 13)
	_objective_copy.text = "OBJECTIVE\n\n○ Remove as much of the label as you can\n\n○ Minimize residue left on the product\n\n○ Keep the label in one piece"
	objective_panel.add_child(_objective_copy)

	var controls_panel := _panel("ControlsPanel", Vector2(1010,16), Vector2(254,108))
	layer.add_child(controls_panel)
	_controls_copy = _label("ControlsCopy", Vector2(13,10), Vector2(228,88), 12)
	_controls_copy.text = "LMB  Grab / Peel\nRMB  Rotate product\nR Inspect / return   T Reset\n1/2/3 Scene   Esc Pause"
	controls_panel.add_child(_controls_copy)

	var how_to_panel := _panel("HowToPanel", Vector2(1010,138), Vector2(254,350))
	layer.add_child(how_to_panel)
	_how_to_copy = _label("HowToCopy", Vector2(14,12), Vector2(226,326), 13)
	_how_to_copy.text = "HOW TO PLAY\n\n1. GRAB EDGE\nClick and hold the visible label edge.\n\n2. PEEL GENTLY\nDrag slowly so the paper follows your hand.\n\n3. INSPECT\nPress R or rotate with RMB to check residue.\n\n4. CLEAN PEEL\nRemove the label with minimal residue and tearing."
	_how_to_copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	how_to_panel.add_child(_how_to_copy)

	_applied = true

func _refresh_status(root: Node, fallback_text: String) -> void:
	if _progress_copy == null:
		return
	var session = root.get("_session")
	var controller = root.get("_controller")
	var paused := bool(root.get("_paused")) if root.get("_paused") != null else false
	if session != null and session.has_method("current_variant"):
		var variant: Dictionary = session.current_variant()
		var name := String(variant.get("name","Peel Calm"))
		var progress := float(controller.get_progress()) if controller != null and controller.has_method("get_progress") else 0.0
		# Capture fixtures stage the real LabelVisual/hand/residue directly while
		# leaving PeelController untouched. Preserve that exact staged percentage
		# from the hidden legacy status so screenshot evidence never lies about the
		# frame being inspected. Normal gameplay writes the same value to both.
		progress = maxf(progress,_parse_legacy_progress(fallback_text))
		var residue := float(controller.get_residue()) if controller != null and controller.has_method("get_residue") else 0.0
		var integrity := float(controller.get_integrity()) if controller != null and controller.has_method("get_integrity") else 1.0
		var state := "PAUSED" if paused else "Peel Progress %d%%" % int(round(progress*100.0))
		_progress_copy.text = "%s\n%s\nResidue %d%%   Intactness %d%%" % [name,state,int(round(residue*100.0)),int(round(integrity*100.0))]
		return

	var lines := fallback_text.split("\n",false)
	var title := "PEEL CALM"
	var status := "Peel Progress 0%"
	if lines.size() > 0:
		title = String(lines[0]).get_slice("•",0).strip_edges()
	if lines.size() > 1:
		status = String(lines[1]).get_slice("•",0).strip_edges().replace("Peel ","Peel Progress ")
	_progress_copy.text = "%s\n%s" % [title,status]

func _parse_legacy_progress(text: String) -> float:
	var marker := "Peel "
	var start := text.find(marker)
	if start < 0:
		return 0.0
	start += marker.length()
	var percent := text.find("%",start)
	if percent < 0:
		return 0.0
	var raw := text.substr(start,percent-start).strip_edges()
	if not raw.is_valid_int():
		return 0.0
	return clampf(float(raw.to_int())/100.0,0.0,1.0)

func _panel(node_name: String, at: Vector2, panel_size: Vector2) -> Panel:
	var panel := Panel.new()
	panel.name = node_name
	panel.position = at
	panel.size = panel_size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel",_glass_style())
	return panel

func _label(node_name: String, at: Vector2, label_size: Vector2, font_size: int) -> Label:
	var label := Label.new()
	label.name = node_name
	label.position = at
	label.size = label_size
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",Color(0.98,0.97,0.94,0.94))
	label.add_theme_color_override("font_shadow_color",Color(0,0,0,0.62))
	label.add_theme_constant_override("shadow_offset_x",1)
	label.add_theme_constant_override("shadow_offset_y",1)
	return label

func _glass_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.018,0.017,0.016,0.56)
	style.border_color = Color(1.0,1.0,1.0,0.12)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.shadow_color = Color(0,0,0,0.24)
	style.shadow_size = 6
	return style
