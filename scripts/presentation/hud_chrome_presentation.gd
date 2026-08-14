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

	# Keep the final player-facing copy input-neutral whenever PeelLab refreshes it.
	if label.text.contains("LMB Peel anywhere"):
		label.text = label.text.replace("LMB Peel anywhere","Mouse / touch peel anywhere")

	if _applied:
		return
	var panel := Panel.new()
	panel.name = "ReferenceHudPanel"
	panel.position = Vector2(16,14)
	panel.size = Vector2(650,104)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.018,0.017,0.016,0.38)
	style.border_color = Color(1.0,1.0,1.0,0.055)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.shadow_color = Color(0,0,0,0.18)
	style.shadow_size = 5
	panel.add_theme_stylebox_override("panel",style)
	layer.add_child(panel)
	layer.move_child(panel,0)
	label.position = Vector2(28,22)
	label.size = Vector2(900,104)
	label.add_theme_font_size_override("font_size",14)
	label.add_theme_color_override("font_color",Color(0.97,0.96,0.93,0.92))
	label.add_theme_color_override("font_shadow_color",Color(0,0,0,0.62))
	label.add_theme_constant_override("shadow_offset_x",1)
	label.add_theme_constant_override("shadow_offset_y",1)
	_applied = true
