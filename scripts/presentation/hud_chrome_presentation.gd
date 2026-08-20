extends Node
class_name HudChromePresentation

const GOLD := Color(1.0,0.66,0.08,1.0)

var _applied := false
var _progress_copy: Label
var _progress_bar: ProgressBar

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

	var progress_panel := _panel("ProgressPanel",Vector2(52,36),Vector2(262,96))
	layer.add_child(progress_panel)
	_progress_copy = _label("ProgressCopy",Vector2(12,8),Vector2(238,48),16)
	progress_panel.add_child(_progress_copy)
	_progress_bar = ProgressBar.new()
	_progress_bar.name = "ProgressBar"
	_progress_bar.position = Vector2(12,68)
	_progress_bar.size = Vector2(238,14)
	_progress_bar.min_value = 0.0
	_progress_bar.max_value = 100.0
	_progress_bar.value = 0.0
	_progress_bar.show_percentage = false
	_progress_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_progress_bar.add_theme_stylebox_override("background",_bar_track_style())
	_progress_bar.add_theme_stylebox_override("fill",_bar_fill_style())
	progress_panel.add_child(_progress_bar)

	var controls_panel := _panel("ControlsPanel",Vector2(52,205),Vector2(170,318))
	layer.add_child(controls_panel)
	var controls := [
		["LMB","Peel / Rub"],
		["RMB","Rotate"],
		["Wheel","Zoom"],
		["R","Reset"],
		["1 2 3 4 5","Change Scene"],
		["Esc","Pause / Menu"]
	]
	for row_index in range(controls.size()):
		_add_control_row(controls_panel,row_index,String(controls[row_index][0]),String(controls[row_index][1]))

	var how_to_panel := _panel("HowToPanel",Vector2(970,44),Vector2(278,524))
	layer.add_child(how_to_panel)
	var how_to_title := _label("HowToTitle",Vector2(18,14),Vector2(242,34),21)
	how_to_title.text = "HOW TO PLAY"
	how_to_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	how_to_panel.add_child(how_to_title)
	var separator := ColorRect.new()
	separator.name = "TitleRule"
	separator.position = Vector2(18,56)
	separator.size = Vector2(242,1)
	separator.color = Color(1.0,0.87,0.68,0.20)
	separator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	how_to_panel.add_child(separator)
	var tutorial_steps := [
		["GRAB EDGE","Move the cursor to a corner or edge of the label."],
		["PEEL GENTLY","Click and drag slowly; the paper follows the cursor."],
		["INSPECT","RMB drag to rotate. Use Wheel to inspect residue."],
		["RUB RESIDUE","After release, hold LMB and rub the glue marks clean."]
	]
	for step_index in range(tutorial_steps.size()):
		_add_tutorial_step(how_to_panel,step_index+1,String(tutorial_steps[step_index][0]),String(tutorial_steps[step_index][1]))
	_applied = true

func _add_control_row(panel: Control, row_index: int, key_text: String, action_text: String) -> void:
	var row := Control.new()
	row.name = "ControlRow%d" % row_index
	row.position = Vector2(10,14+float(row_index)*49.0)
	row.size = Vector2(150,42)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(row)
	var key := _label("Key",Vector2(0,6),Vector2(54,30),12)
	key.text = key_text
	key.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	key.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	key.add_theme_stylebox_override("normal",_keycap_style())
	row.add_child(key)
	var action := _label("Action",Vector2(64,4),Vector2(86,34),13)
	action.text = action_text
	action.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	action.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(action)

func _add_tutorial_step(panel: Control, step_index: int, title_text: String, body_text: String) -> void:
	var row := Control.new()
	row.name = "Step%d" % step_index
	row.position = Vector2(18,74+float(step_index-1)*106.0)
	row.size = Vector2(242,96)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(row)
	_add_step_preview(row,step_index)
	var badge := _label("Number",Vector2(78,2),Vector2(28,28),14)
	badge.text = str(step_index)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.add_theme_color_override("font_color",Color(0.08,0.055,0.02,1.0))
	badge.add_theme_stylebox_override("normal",_number_badge_style())
	row.add_child(badge)
	var title := _label("Title",Vector2(114,0),Vector2(128,27),13)
	title.text = title_text
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(title)
	var body := _label("Body",Vector2(114,31),Vector2(126,61),11)
	body.text = body_text
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_color_override("font_color",Color(0.90,0.88,0.83,0.88))
	row.add_child(body)

func _add_step_preview(row: Control, step_index: int) -> void:
	var preview := Panel.new()
	preview.name = "Preview"
	preview.position = Vector2(0,4)
	preview.size = Vector2(68,78)
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview.add_theme_stylebox_override("panel",_preview_style())
	row.add_child(preview)
	var vessel := ColorRect.new()
	vessel.name = "Vessel"
	vessel.position = Vector2(8,8)
	vessel.size = Vector2(52,62)
	vessel.color = Color(0.34,0.30,0.26,1.0)
	vessel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview.add_child(vessel)
	if step_index <= 2:
		var paper := ColorRect.new()
		paper.name = "Paper"
		paper.position = Vector2(11,28)
		paper.size = Vector2(46,27)
		paper.color = Color(0.86,0.82,0.72,1.0)
		paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
		preview.add_child(paper)
		for line_index in range(2):
			var print_line := ColorRect.new()
			print_line.position = Vector2(15,34+line_index*7)
			print_line.size = Vector2(22+line_index*8,1)
			print_line.color = Color(0.18,0.15,0.12,0.68)
			print_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
			preview.add_child(print_line)
		var flap := Polygon2D.new()
		flap.name = "Flap"
		if step_index == 1:
			flap.polygon = PackedVector2Array([Vector2(49,28),Vector2(57,28),Vector2(57,39)])
		else:
			flap.polygon = PackedVector2Array([Vector2(39,28),Vector2(57,28),Vector2(57,56),Vector2(46,50)])
		flap.color = Color(0.97,0.94,0.86,1.0)
		preview.add_child(flap)
	else:
		var patch_count := 5 if step_index == 3 else 2
		for patch_index in range(patch_count):
			var residue := Polygon2D.new()
			residue.name = "Residue%d" % patch_index
			var px := 13.0+float((patch_index*9)%36)
			var py := 29.0+float((patch_index*13)%25)
			residue.polygon = PackedVector2Array([Vector2(px,py),Vector2(px+7,py-2),Vector2(px+9,py+8),Vector2(px+2,py+10)])
			residue.color = Color(0.83,0.78,0.64,0.64 if step_index == 3 else 0.28)
			preview.add_child(residue)

func _refresh_status(root: Node, fallback_text: String) -> void:
	if _progress_copy == null:
		return
	var session = root.get("_session")
	var controller = root.get("_controller")
	var paused_value = root.get("_paused")
	var paused := bool(paused_value) if paused_value != null else false
	var progress := 0.0
	var cleanup_progress := 0.0
	var cleaning := false
	var scene_name := "COFFEE SHOP"
	if session != null and session.has_method("current_variant"):
		var variant: Dictionary = session.current_variant()
		scene_name = String(variant.get("name","Coffee Shop")).to_upper()
		progress = float(controller.get_progress()) if controller != null and controller.has_method("get_progress") else 0.0
		progress = maxf(progress,_parse_legacy_progress(fallback_text))
		var lifecycle = root.get("_lifecycle")
		var scrub = root.get("_scrub_model")
		cleaning = lifecycle != null and lifecycle.has_method("is_resolved") and lifecycle.is_resolved() and scrub != null
		cleanup_progress = float(scrub.get_progress()) if cleaning and scrub.has_method("get_progress") else 0.0
	else:
		progress = _parse_legacy_progress(fallback_text)
	var percent := int(round((cleanup_progress if cleaning else progress)*100.0))
	var status_copy := "Residue Clean %d%%" % percent if cleaning else "Peel Progress %d%%" % percent
	_progress_copy.text = "SCENE: %s\n%s" % [scene_name,"PAUSED" if paused else status_copy]
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

func _keycap_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.02,0.019,0.018,0.76)
	style.border_color = Color(1.0,0.88,0.68,0.34)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 6; style.corner_radius_top_right = 6; style.corner_radius_bottom_left = 6; style.corner_radius_bottom_right = 6
	return style

func _number_badge_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = GOLD
	style.corner_radius_top_left = 14; style.corner_radius_top_right = 14; style.corner_radius_bottom_left = 14; style.corner_radius_bottom_right = 14
	return style

func _preview_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06,0.055,0.050,0.86)
	style.border_color = Color(1.0,0.88,0.68,0.18)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 8; style.corner_radius_top_right = 8; style.corner_radius_bottom_left = 8; style.corner_radius_bottom_right = 8
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
