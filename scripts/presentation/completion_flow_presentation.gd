extends Node
class_name CompletionFlowPresentation

const PANEL_RECT := Rect2(24,468,330,112)
const PAPER_COLOR := Color(0.91,0.87,0.76,0.96)

var _built := false
var _panel: Panel
var _stage_label: Label
var _detail_label: Label
var _paper_chip: Panel

func _ready() -> void:
	call_deferred("_ensure_ui")

func _process(_delta: float) -> void:
	_ensure_ui()
	var lab := get_parent()
	if lab == null or _panel == null:
		return
	var lifecycle = lab.get("_lifecycle")
	if lifecycle == null or not lifecycle.has_method("get_phase_name"):
		_panel.visible = false
		return
	var phase := String(lifecycle.call("get_phase_name"))
	var settle := float(lifecycle.call("get_release_settle_alpha")) if lifecycle.has_method("get_release_settle_alpha") else 0.0
	var state := state_for_phase(phase,settle)
	_apply_state(lab,state,settle)

func state_for_phase(phase_name: String, settle_alpha: float) -> Dictionary:
	var phase := phase_name.to_upper()
	var settle := clampf(settle_alpha if is_finite(settle_alpha) else 0.0,0.0,1.0)
	match phase:
		"SETTLING":
			return {
				"visible":true,
				"stage":"RELEASED",
				"allow_inspect":true,
				"allow_continue":true,
				"hero_occlusion":0.0,
				"settle":settle
			}
		"RESOLVED":
			# Collection is a transient acknowledgement, not a permanent panel.
			# Once the label is gone the next authored state is the bare-object toy,
			# so clear the tray and hand visual priority back to the hero product.
			return {
				"visible":false,
				"stage":"COLLECTED",
				"allow_inspect":true,
				"allow_continue":true,
				"hero_occlusion":0.0,
				"settle":1.0
			}
		_:
			return {
				"visible":false,
				"stage":"",
				"allow_inspect":false,
				"allow_continue":false,
				"hero_occlusion":0.0,
				"settle":0.0
			}

func layout_contract() -> Dictionary:
	return {
		"region":"lower_left",
		"left":PANEL_RECT.position.x,
		"top":PANEL_RECT.position.y,
		"right":PANEL_RECT.end.x,
		"bottom":PANEL_RECT.end.y
	}

func _ensure_ui() -> void:
	if _built:
		return
	var lab := get_parent()
	if lab == null:
		return
	var layer := lab.get_node_or_null("HUD") as CanvasLayer
	if layer == null:
		return
	_panel = Panel.new()
	_panel.name = "CompletionTray"
	_panel.position = PANEL_RECT.position
	_panel.size = PANEL_RECT.size
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_theme_stylebox_override("panel",_panel_style())
	layer.add_child(_panel)

	_paper_chip = Panel.new()
	_paper_chip.name = "CollectedLabelChip"
	_paper_chip.position = Vector2(18,24)
	_paper_chip.size = Vector2(56,64)
	_paper_chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_paper_chip.add_theme_stylebox_override("panel",_paper_style())
	_panel.add_child(_paper_chip)

	_stage_label = Label.new()
	_stage_label.name = "CompletionStage"
	_stage_label.position = Vector2(92,19)
	_stage_label.size = Vector2(214,28)
	_stage_label.add_theme_font_size_override("font_size",15)
	_stage_label.add_theme_color_override("font_color",Color(1.0,0.76,0.28,1.0))
	_stage_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(_stage_label)

	_detail_label = Label.new()
	_detail_label.name = "CompletionDetail"
	_detail_label.position = Vector2(92,48)
	_detail_label.size = Vector2(218,52)
	_detail_label.add_theme_font_size_override("font_size",13)
	_detail_label.add_theme_color_override("font_color",Color(0.96,0.95,0.92,0.96))
	_detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(_detail_label)
	_panel.visible = false
	_built = true

func _apply_state(lab: Node,state: Dictionary,settle_alpha: float) -> void:
	_panel.visible = bool(state.get("visible",false))
	if not _panel.visible:
		return
	var stage := String(state.get("stage",""))
	var controller = lab.get("_controller")
	var residue := float(controller.get_residue()) if controller != null and controller.has_method("get_residue") else 0.0
	if stage == "RELEASED":
		_stage_label.text = "LABEL RELEASED"
		_detail_label.text = "Paper settling…   RMB inspect residue"
		var t := clampf(settle_alpha,0.0,1.0)
		_paper_chip.rotation = lerpf(-0.14,0.07,t)
		_paper_chip.position = Vector2(18.0+20.0*t,16.0+24.0*t)
		_paper_chip.modulate.a = lerpf(1.0,0.72,t)
	else:
		_stage_label.text = "LABEL COLLECTED"
		_detail_label.text = "Residue %d%%   •   Inspect or Continue" % int(round(residue*100.0))
		_paper_chip.rotation = 0.07
		_paper_chip.position = Vector2(38,42)
		_paper_chip.modulate.a = 0.72

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.018,0.017,0.016,0.80)
	style.border_color = Color(1.0,0.72,0.22,0.32)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.shadow_color = Color(0,0,0,0.30)
	style.shadow_size = 6
	return style

func _paper_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = PAPER_COLOR
	style.border_color = Color(0.42,0.33,0.22,0.85)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 2
	style.corner_radius_top_right = 1
	style.corner_radius_bottom_left = 1
	style.corner_radius_bottom_right = 3
	return style
