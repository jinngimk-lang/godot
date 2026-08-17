extends Node
class_name GuidedJourneyPresentation

signal scene_requested(index: int)

const SCENE_NAMES := ["WINDOW CAFÉ", "AMBER BAR", "MARKET COOLER"]

var _built := false
var _active_scene_index := 0
var _action_text := "PEEL THE LABEL"
var _scene_status: Label
var _action: Label
var _buttons: Array[Button] = []
var _rail: Panel
var _rail_visible := true
var _inspection_active := false
var _parent_connected := false
var _reward: Label
var _continue_button: Button

func _ready() -> void:
	_ensure_ui()
	_connect_parent_navigation()

func _process(_delta: float) -> void:
	_ensure_ui()
	_connect_parent_navigation()
	_pull_runtime_state()
	_refresh_existing_hud()

func set_state(scene_index: int, phase_name: String, post_action: String, peel_progress: float, detached: bool) -> void:
	_ensure_ui()
	_active_scene_index = clampi(scene_index, 0, SCENE_NAMES.size() - 1)
	var progress := clampf(peel_progress if is_finite(peel_progress) else 0.0, 0.0, 1.0)
	var phase := phase_name.to_upper()
	var post := post_action.to_lower()
	var post_interaction := detached or phase in ["DETACHING", "HELD", "PEEL_SETTLE", "CRUMPLE_READY", "CRUMPLING", "RITUAL_COMPLETE"]

	if post_interaction:
		if post == "crumple":
			_action_text = "LABEL OFF  •  OPTIONAL SQUEEZE  •  CONTINUE"
		else:
			_action_text = "LABEL OFF  •  INSPECT RESIDUE  •  CONTINUE"
	elif progress > 0.001:
		_action_text = "PEEL THE LABEL  •  %d%%" % int(round(progress * 100.0))
	else:
		_action_text = "PEEL THE LABEL  •  CLICK / DRAG"

	# Keep target-like interaction moments visually quiet while preserving scene
	# navigation before engagement, after detach, and between active rituals.
	_rail_visible = not ((progress > 0.001 and not post_interaction) or phase == "CRUMPLING")
	# Fixed reference-frame inspection is staged by directly applying product yaw
	# while the guide process is frozen. Treat that visible yaw as inspection
	# evidence so capture and live RMB inspection share the same quiet UI contract.
	var lab := get_parent()
	var cup := lab.get_node_or_null("Cup") as Node3D if lab != null else null
	if cup != null and absf(cup.rotation.y) > 0.001:
		_inspection_active = true
	_apply_state_to_ui()

func set_inspection_active(active: bool) -> void:
	_inspection_active = active
	_apply_state_to_ui()

func get_active_scene_index() -> int:
	return _active_scene_index

func get_action_text() -> String:
	return _action_text

func _pull_runtime_state() -> void:
	var lab := get_parent()
	if lab == null:
		return
	var session = lab.get("_session")
	if session == null or not session.has_method("current_variant"):
		return
	var variant: Dictionary = session.current_variant()
	var index := int(session.get_variant_index()) if session.has_method("get_variant_index") else 0
	var controller = lab.get("_controller")
	var progress := float(controller.get_progress()) if controller != null and controller.has_method("get_progress") else 0.0
	var lifecycle = lab.get("_lifecycle")
	var ritual = lab.get("_ritual")
	var lifecycle_phase := String(lifecycle.get_phase_name()) if lifecycle != null and lifecycle.has_method("get_phase_name") else "PEEL"
	var ritual_phase := String(ritual.get_phase_name()) if ritual != null and ritual.has_method("get_phase_name") else "PEEL"
	var phase := ritual_phase if ritual_phase != "PEEL" else lifecycle_phase
	var detached := bool(lab.get("_detach_reward_recorded"))
	set_state(index, phase, String(variant.get("post_peel_action", "inspect")), progress, detached)
	var inspection = lab.get("_inspection")
	set_inspection_active(inspection != null and inspection.has_method("is_active") and bool(inspection.is_active()))

func _connect_parent_navigation() -> void:
	if _parent_connected:
		return
	var lab := get_parent()
	if lab == null or not lab.has_method("_select_showcase"):
		return
	var callback := Callable(lab, "_select_showcase")
	if not scene_requested.is_connected(callback):
		scene_requested.connect(callback)
	_parent_connected = true

func _ensure_ui() -> void:
	if _built:
		return
	var lab := get_parent()
	if lab == null:
		return
	var layer := lab.get_node_or_null("HUD") as CanvasLayer
	if layer == null:
		return

	_reward = layer.get_node_or_null("Reward") as Label
	_continue_button = layer.get_node_or_null("Continue") as Button
	_style_existing_hud()

	var guide := Panel.new()
	guide.name = "JourneyGuide"
	guide.anchor_left = 0.0
	guide.anchor_top = 0.0
	guide.anchor_right = 0.0
	guide.anchor_bottom = 0.0
	guide.offset_left = 14.0
	guide.offset_top = 68.0
	guide.offset_right = 332.0
	guide.offset_bottom = 120.0
	guide.mouse_filter = Control.MOUSE_FILTER_IGNORE
	guide.add_theme_stylebox_override("panel", _panel_style(Color(0.016, 0.015, 0.014, 0.28), Color(1.0, 1.0, 1.0, 0.05), 7))
	layer.add_child(guide)

	_scene_status = Label.new()
	_scene_status.name = "SceneStatus"
	_scene_status.position = Vector2(12, 7)
	_scene_status.size = Vector2(294, 17)
	_scene_status.add_theme_font_size_override("font_size", 10)
	_scene_status.add_theme_color_override("font_color", Color(0.98, 0.97, 0.94, 0.86))
	guide.add_child(_scene_status)

	_action = Label.new()
	_action.name = "Action"
	_action.position = Vector2(12, 26)
	_action.size = Vector2(294, 18)
	_action.add_theme_font_size_override("font_size", 11)
	_action.add_theme_color_override("font_color", Color(1.0, 0.91, 0.72, 0.96))
	guide.add_child(_action)

	_rail = Panel.new()
	_rail.name = "JourneyRail"
	_rail.anchor_left = 0.5
	_rail.anchor_top = 1.0
	_rail.anchor_right = 0.5
	_rail.anchor_bottom = 1.0
	_rail.offset_left = -294.0
	_rail.offset_top = -62.0
	_rail.offset_right = 294.0
	_rail.offset_bottom = -12.0
	_rail.mouse_filter = Control.MOUSE_FILTER_PASS
	_rail.add_theme_stylebox_override("panel", _panel_style(Color(0.014, 0.013, 0.012, 0.32), Color(1.0, 1.0, 1.0, 0.045), 9))
	layer.add_child(_rail)

	for i in range(SCENE_NAMES.size()):
		var button := Button.new()
		button.name = "Scene%d" % i
		button.text = "%d  %s" % [i + 1, SCENE_NAMES[i]]
		button.position = Vector2(7.0 + float(i) * 193.0, 7.0)
		button.size = Vector2(187.0, 36.0)
		button.focus_mode = Control.FOCUS_NONE
		button.toggle_mode = true
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.add_theme_font_size_override("font_size", 10)
		button.add_theme_color_override("font_color", Color(0.92, 0.91, 0.88, 0.82))
		button.add_theme_color_override("font_hover_color", Color(1.0, 0.96, 0.88, 0.98))
		button.add_theme_color_override("font_pressed_color", Color(1.0, 0.90, 0.66, 1.0))
		button.add_theme_stylebox_override("normal", _button_style(Color(1.0, 1.0, 1.0, 0.025), Color(1.0, 1.0, 1.0, 0.045)))
		button.add_theme_stylebox_override("hover", _button_style(Color(1.0, 0.83, 0.58, 0.08), Color(1.0, 0.87, 0.66, 0.18)))
		button.add_theme_stylebox_override("pressed", _button_style(Color(0.91, 0.56, 0.22, 0.18), Color(1.0, 0.82, 0.56, 0.34)))
		button.pressed.connect(_request_scene.bind(i))
		_rail.add_child(button)
		_buttons.append(button)

	_built = true
	_apply_state_to_ui()
	_refresh_existing_hud()

func _style_existing_hud() -> void:
	# JourneyGuide owns completion state and next-action copy. Keep the legacy
	# Reward node alive for compatibility, but remove its duplicate visual chrome
	# so it cannot compete with the guide or overlap the scene rail.
	if _reward != null:
		_reward.visible = false
	if _continue_button != null:
		_continue_button.anchor_left = 0.5
		_continue_button.anchor_top = 1.0
		_continue_button.anchor_right = 0.5
		_continue_button.anchor_bottom = 1.0
		_continue_button.offset_left = 302.0
		_continue_button.offset_top = -62.0
		_continue_button.offset_right = 494.0
		_continue_button.offset_bottom = -12.0
		_continue_button.add_theme_font_size_override("font_size", 11)
		_continue_button.add_theme_stylebox_override("normal", _button_style(Color(0.10, 0.075, 0.045, 0.76), Color(1.0, 0.84, 0.60, 0.18)))
		_continue_button.add_theme_stylebox_override("hover", _button_style(Color(0.20, 0.13, 0.065, 0.86), Color(1.0, 0.86, 0.61, 0.34)))
		_continue_button.add_theme_stylebox_override("pressed", _button_style(Color(0.26, 0.15, 0.065, 0.92), Color(1.0, 0.88, 0.63, 0.46)))

func _refresh_existing_hud() -> void:
	if _reward == null or _continue_button == null:
		var lab := get_parent()
		var layer := lab.get_node_or_null("HUD") as CanvasLayer if lab != null else null
		if layer != null:
			_reward = layer.get_node_or_null("Reward") as Label
			_continue_button = layer.get_node_or_null("Continue") as Button
			_style_existing_hud()
	if _reward != null:
		_reward.visible = false

func _request_scene(index: int) -> void:
	scene_requested.emit(clampi(index, 0, SCENE_NAMES.size() - 1))

func _apply_state_to_ui() -> void:
	if not _built or _scene_status == null or _action == null:
		return
	_scene_status.text = "SCENE %d / %d  •  %s" % [_active_scene_index + 1, SCENE_NAMES.size(), SCENE_NAMES[_active_scene_index]]
	_action.text = _action_text
	if _rail != null:
		_rail.visible = _rail_visible and not _inspection_active
	for i in range(_buttons.size()):
		_buttons[i].button_pressed = i == _active_scene_index

func _panel_style(bg: Color, border: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(1)
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.shadow_color = Color(0, 0, 0, 0.12)
	style.shadow_size = 3
	return style

func _button_style(bg: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(1)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	return style
