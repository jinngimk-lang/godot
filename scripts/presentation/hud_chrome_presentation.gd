extends Node
class_name HudChromePresentation

var _applied := false

func _process(_delta: float) -> void:
	var root := get_parent()
	if root == null:
		return
	var layer := root.get_node_or_null("HUD") as CanvasLayer
	var label := root.get_node_or_null("HUD/Instructions") as Label
	if layer == null or label == null:
		return

	# PeelLab owns the state-dependent copy; this presentation layer keeps the
	# final player-facing affordance input-neutral whenever that copy refreshes.
	if label.text.contains("LMB Peel anywhere"):
		label.text = label.text.replace("LMB Peel anywhere","Mouse / touch peel anywhere")

	if _applied:
		return
	var panel := Panel.new()
	panel.name = "ReferenceHudPanel"
	panel.position = Vector2(18,14)
	panel.size = Vector2(760,126)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025,0.022,0.020,0.54)
	style.border_color = Color(1.0,1.0,1.0,0.09)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 9
	style.corner_radius_top_right = 9
	style.corner_radius_bottom_left = 9
	style.corner_radius_bottom_right = 9
	style.shadow_color = Color(0,0,0,0.24)
	style.shadow_size = 7
	panel.add_theme_stylebox_override("panel",style)
	layer.add_child(panel)
	layer.move_child(panel,0)
	label.position = Vector2(32,24)
	label.add_theme_color_override("font_shadow_color",Color(0,0,0,0.70))
	label.add_theme_constant_override("shadow_offset_x",1)
	label.add_theme_constant_override("shadow_offset_y",2)
	_applied = true
