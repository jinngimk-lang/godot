extends Node
class_name CompletionFlowPresentation

const PANEL_SIZE := Vector2(252,92)
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
			return {
				"visible":true,
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
	_panel.anchor_left = 1.0
	_panel.anchor_top = 1.0
	_panel.anchor_right = 1.0
	_panel.anchor_bottom = 1.0
	_panel.offset_left = -284.0
	_panel.offset_top = -232.0
	_panel.offset_right = -32.0
	_panel.offset_bottom = -140.0
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_theme_stylebox_override("panel",_panel_style())
	layer.add_child(_panel)

	_paper_chip = Panel.new()
	_paper_chip.name = "CollectedLabelChip"
	_paper_chip.position = Vector2(14,18)
	_paper_chip.size = Vector2(48,54)
	_paper_chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_paper_chip.add_theme_stylebox_override("panel",_paper_style())
	_panel.add_child(_paper_chip)

	_stage_label = Label.new()
	_stage_label.name = "CompletionStage"
	_stage_label.position = Vector2(76,14)
	_stage_label.size = Vector2(160,24)
	_stage_label.add_theme_font_size_override("font_size",14)
	_stage_label.add_theme_color_override("font_color",Color(1.0,0.78,0.30,1.0))
	_stage_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(_stage_label)

	_detail_label = Label.new()
	_detail_label.name = "CompletionDetail"
	_detail_label.position = Vector2(76,39)
	_detail_label.size = Vector2(166,44)
	_detail_label.add_theme_font_size_override("font_size",12)
	_detail_label.add_theme_color_override("font_color",Color(0.92,0.91,0.88,0.92))
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
		_detail_label.text = "Settling paper…\nRMB inspect residue"
		var t := clampf(settle_alpha,0.0,1.0)
		_paper_chip.rotation = lerpf(-0.10,0.08,t)
		_paper_chip.position = Vector2(14.0+18.0*t,10.0+26.0*t)
		_paper_chip.modulate.a = lerpf(1.0,0.72,t)
	else:
		_stage_label.text = "LABEL COLLECTED"
		_detail_label.text = "Residue %d%%\nInspect or Continue" % int(round(residue*100.0))
		_paper_chip.rotation = 0.08
		_paper_chip.position = Vector2(34,36)
		_paper_chip.modulate.a = 0.62

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.018,0.017,0.016,0.78)
	style.border_color = Color(1.0,0.72,0.22,0.22)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 9
	style.corner_radius_top_right = 9
	style.corner_radius_bottom_left = 9
	style.corner_radius_bottom_right = 9
	style.shadow_color = Color(0,0,0,0.28)
	style.shadow_size = 5
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
