extends Node
class_name HudChromePresentation

const GOLD := Color(1.0,0.66,0.08,1.0)

var _applied := false
var _progress_copy: Label
var _progress_bar: ProgressBar
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
		_build_ui(layer,legacy)
	_refresh_status(root,legacy.text)

func _build_ui(layer: CanvasLayer, legacy: Label) -> void:
	legacy.visible = false

	var progress_panel := _panel("ProgressPanel",Vector2(24,22),Vector2(318,118))
	layer.add_child(progress_panel)
	_progress_copy = _label("ProgressCopy",Vector2(14,10),Vector2(288,54),18)
	_progress_copy.add_theme_font_size_override("font_size",18)
	progress_panel.add_child(_progress_copy)
	_progress_bar = ProgressBar.new()
	_progress_bar.name = "ProgressBar"
	_progress_bar.position = Vector2(14,78)
	_progress_bar.size = Vector2(288,16)
	_progress_bar.min_value = 0.0
	_progress_bar.max_value = 100.0
	_progress_bar.value = 0.0
	_progress_bar.show_percentage = false
	_progress_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_progress_bar.add_theme_stylebox_override("background",_bar_track_style())
	_progress_bar.add_theme_stylebox_override("fill",_bar_fill_style())
	progress_panel.add_child(_progress_bar)

	var controls_panel := _panel("ControlsPanel",Vector2(24,158),Vector2(268,278))
	layer.add_child(controls_panel)
	_controls_copy = _label("ControlsCopy",Vector2(16,14),Vector2(236,248),16)
	_controls_copy.text = "LMB     Peel\n\nRMB     Rotate\n\nWheel   Zoom\n\nR       Reset\n\n1 2 3 4 5   Change Scene\n\nEsc     Pause / Menu"
	controls_panel.add_child(_controls_copy)

	var how_to_panel := _panel("HowToPanel",Vector2(982,22),Vector2(274,520))
	layer.add_child(how_to_panel)
	_how_to_copy = _label("HowToCopy",Vector2(16,14),Vector2(242,490),15)
	_how_to_copy.text = "HOW TO PLAY\n\n1   GRAB EDGE\nMove the cursor to a corner or edge of the label.\n\n2   PEEL GENTLY\nClick and drag slowly. The real label follows the cursor.\n\n3   INSPECT\nRMB drag to rotate. Use Wheel to zoom and inspect residue.\n\n4   CLEAN PEEL\nRemove the label with minimal residue and tearing."
	_how_to_copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	how_to_panel.add_child(_how_to_copy)
	_applied = true

func _refresh_status(root: Node, fallback_text: String) -> void:
	if _progress_copy == null:
		return
	var session = root.get("_session")
	var controller = root.get("_controller")
	var paused_value = root.get("_paused")
	var paused := bool(paused_value) if paused_value != null else false
	var progress := 0.0
	var scene_name := "COFFEE SHOP"
	if session != null and session.has_method("current_variant"):
		var variant: Dictionary = session.current_variant()
		scene_name = String(variant.get("name","Coffee Shop")).to_upper()
		progress = float(controller.get_progress()) if controller != null and controller.has_method("get_progress") else 0.0
		progress = maxf(progress,_parse_legacy_progress(fallback_text))
	else:
		progress = _parse_legacy_progress(fallback_text)
	var percent := int(round(progress*100.0))
	_progress_copy.text = "SCENE: %s\n%s" % [scene_name,"PAUSED" if paused else "Peel Progress %d%%" % percent]
	if _progress_bar != null:
		_progress_bar.value = float(percent)

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
	label.add_theme_color_override("font_color",Color(0.985,0.975,0.95,0.97))
	label.add_theme_color_override("font_shadow_color",Color(0,0,0,0.70))
	label.add_theme_constant_override("shadow_offset_x",1)
	label.add_theme_constant_override("shadow_offset_y",1)
	return label

func _glass_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.018,0.017,0.016,0.68)
	style.border_color = Color(1.0,0.86,0.64,0.14)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.shadow_color = Color(0,0,0,0.28)
	style.shadow_size = 6
	return style

func _bar_track_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08,0.075,0.07,0.94)
	style.corner_radius_top_left = 8; style.corner_radius_top_right = 8; style.corner_radius_bottom_left = 8; style.corner_radius_bottom_right = 8
	return style

func _bar_fill_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = GOLD
	style.corner_radius_top_left = 8; style.corner_radius_top_right = 8; style.corner_radius_bottom_left = 8; style.corner_radius_bottom_right = 8
	return style
