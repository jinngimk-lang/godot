extends Node
class_name GuidedJourneyPresentation

signal scene_requested(index: int)

const SCENE_NAMES := ["COFFEE SHOP","JAR","TIN CAN","SUPERMARKET","CAN"]
const GOLD := Color(1.0,0.66,0.08,1.0)

var _built := false
var _active_scene_index := 0
var _action_text := "PEEL THE LABEL"
var _buttons: Array[Button] = []
var _rail: Panel
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

func set_state(scene_index: int, phase_name: String, _post_action: String, peel_progress: float, detached: bool) -> void:
	_ensure_ui()
	_active_scene_index = clampi(scene_index,0,SCENE_NAMES.size()-1)
	var progress := clampf(peel_progress if is_finite(peel_progress) else 0.0,0.0,1.0)
	var phase := phase_name.to_upper()
	if detached or phase in ["DETACHING","HELD","SETTLING","RESOLVED","PEEL_SETTLE","RITUAL_COMPLETE"]:
		_action_text = "LABEL OFF  •  HOLD LMB + RUB RESIDUE"
	elif progress>0.001:
		_action_text = "PEEL THE LABEL  •  %d%%" % int(round(progress*100.0))
	else:
		_action_text = "PEEL THE LABEL  •  CLICK / DRAG"
	_apply_state_to_ui()

func set_inspection_active(_active: bool) -> void:
	# The owner-approved mockup keeps the scene rail visible while rotating and
	# zooming; inspection is object motion, not a separate full-screen mode.
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
	var phase := String(lifecycle.get_phase_name()) if lifecycle != null and lifecycle.has_method("get_phase_name") else "PEEL"
	var detached_value = lab.get("_detach_reward_recorded")
	var detached := bool(detached_value) if detached_value != null else false
	set_state(index,phase,String(variant.get("post_peel_action","inspect")),progress,detached)
	var scrub = lab.get("_scrub_model")
	if phase == "RESOLVED" and scrub != null and scrub.has_method("get_progress"):
		var clean_progress := float(scrub.get_progress())
		_action_text = "RESIDUE CLEAN  •  %d%%  •  %s" % [int(round(clean_progress*100.0)),"CONTINUE" if scrub.is_complete() else "RUB ↔"]

func _connect_parent_navigation() -> void:
	if _parent_connected:
		return
	var lab := get_parent()
	if lab == null or not lab.has_method("_select_showcase"):
		return
	var callback := Callable(lab,"_select_showcase")
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

	_rail = Panel.new()
	_rail.name = "JourneyRail"
	_rail.position = Vector2(36,650)
	_rail.size = Vector2(1208,56)
	_rail.mouse_filter = Control.MOUSE_FILTER_PASS
	_rail.add_theme_stylebox_override("panel",_panel_style(Color(0.014,0.013,0.012,0.72),Color(1.0,0.80,0.45,0.13),9))
	layer.add_child(_rail)

	for i in range(SCENE_NAMES.size()):
		var button := Button.new()
		button.name = "Scene%d" % i
		button.text = "%d   %s" % [i+1,SCENE_NAMES[i]]
		button.position = Vector2(8.0+float(i)*240.0,8.0)
		button.size = Vector2(232.0,40.0)
		button.focus_mode = Control.FOCUS_NONE
		button.toggle_mode = true
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.add_theme_font_size_override("font_size",12)
		button.add_theme_color_override("font_color",Color(0.90,0.89,0.86,0.86))
		button.add_theme_color_override("font_pressed_color",Color(1.0,0.88,0.54,1.0))
		button.add_theme_stylebox_override("normal",_button_style(Color(1,1,1,0.025),Color(1,1,1,0.05)))
		button.add_theme_stylebox_override("hover",_button_style(Color(1.0,0.70,0.20,0.10),Color(1.0,0.78,0.36,0.28)))
		button.add_theme_stylebox_override("pressed",_button_style(Color(0.44,0.24,0.05,0.55),GOLD))
		button.pressed.connect(_request_scene.bind(i))
		_rail.add_child(button)
		_buttons.append(button)
	_built = true
	_apply_state_to_ui()
	_refresh_existing_hud()

func _style_existing_hud() -> void:
	if _reward != null:
		_reward.visible = false
	if _continue_button != null:
		_continue_button.anchor_left = 0.5
		_continue_button.anchor_top = 1.0
		_continue_button.anchor_right = 0.5
		_continue_button.anchor_bottom = 1.0
		_continue_button.offset_left = 355.0
		_continue_button.offset_top = -126.0
		_continue_button.offset_right = 495.0
		_continue_button.offset_bottom = -82.0
		_continue_button.add_theme_font_size_override("font_size",11)
		_continue_button.add_theme_stylebox_override("normal",_button_style(Color(0.10,0.075,0.045,0.80),Color(1.0,0.84,0.60,0.20)))

func _refresh_existing_hud() -> void:
	if _reward != null:
		_reward.visible = false

func _request_scene(index: int) -> void:
	scene_requested.emit(clampi(index,0,SCENE_NAMES.size()-1))

func _apply_state_to_ui() -> void:
	if not _built:
		return
	if _rail != null:
		_rail.visible = true
	for i in range(_buttons.size()):
		_buttons[i].button_pressed = i == _active_scene_index

func _panel_style(bg: Color, border: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(1)
	style.corner_radius_top_left = radius; style.corner_radius_top_right = radius; style.corner_radius_bottom_left = radius; style.corner_radius_bottom_right = radius
	style.shadow_color = Color(0,0,0,0.20); style.shadow_size = 4
	return style

func _button_style(bg: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(1)
	style.corner_radius_top_left = 6; style.corner_radius_top_right = 6; style.corner_radius_bottom_left = 6; style.corner_radius_bottom_right = 6
	return style
