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

	# PeelLab owns authoritative gameplay state. This presentation layer keeps
	# only the player-facing essentials visible so the reference photography
	# remains primary instead of reading like a debug overlay.
	label.text = _compact_hud_text(label.text)

	if _applied:
		return
	var panel := Panel.new()
	panel.name = "ReferenceHudPanel"
	panel.position = Vector2(14,12)
	panel.size = Vector2(430,50)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.018,0.017,0.016,0.23)
	style.border_color = Color(1.0,1.0,1.0,0.032)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 7
	style.corner_radius_top_right = 7
	style.corner_radius_bottom_left = 7
	style.corner_radius_bottom_right = 7
	style.shadow_color = Color(0,0,0,0.10)
	style.shadow_size = 3
	panel.add_theme_stylebox_override("panel",style)
	layer.add_child(panel)
	layer.move_child(panel,0)
	label.position = Vector2(22,16)
	label.size = Vector2(408,42)
	label.add_theme_font_size_override("font_size",10)
	label.add_theme_color_override("font_color",Color(0.97,0.96,0.93,0.88))
	label.add_theme_color_override("font_shadow_color",Color(0,0,0,0.52))
	label.add_theme_constant_override("shadow_offset_x",1)
	label.add_theme_constant_override("shadow_offset_y",1)
	_applied = true

func _compact_hud_text(source: String) -> String:
	if source.is_empty():
		return source
	var normalized := source.replace("LMB Peel anywhere","Mouse / touch peel")
	var lines := normalized.split("\n",false)
	if lines.is_empty():
		return normalized

	var first := String(lines[0]).strip_edges()
	if first.contains("PAUSED"):
		var venue := first.get_slice("•",0).strip_edges()
		return "%s  •  PAUSED\nEsc Resume  •  R Reset" % venue

	# Already-compacted copy is intentionally idempotent across process frames.
	if lines.size() <= 2 and not normalized.contains("Quality") and not normalized.contains("residue"):
		return normalized

	var venue_name := first.get_slice("•",0).strip_edges()
	var progress_text := ""
	if lines.size() >= 2:
		var status := String(lines[1]).strip_edges()
		if status.begins_with("Peel "):
			progress_text = status.get_slice("•",0).strip_edges()

	var hint := ""
	if lines.size() >= 3:
		hint = _short_hint(String(lines[2]).strip_edges())
	if hint.is_empty():
		hint = "slow pull feels cleaner"

	var header := venue_name
	if not progress_text.is_empty():
		header += "  •  %s" % progress_text
	header += "  •  %s" % hint
	return "%s\nMouse / touch peel  •  RMB inspect  •  Q/E scene  •  Esc Pause  •  R Reset" % header

func _short_hint(hint: String) -> String:
	var lower := hint.to_lower()
	if lower.contains("last adhesive"):
		return "last fibers releasing"
	if lower.contains("label released"):
		return "label released"
	if lower.contains("steady pull"):
		return "steady pull"
	if lower.contains("re-grab"):
		return "re-grab anywhere"
	if lower.contains("optional squeeze"):
		return "optional squeeze"
	if lower.contains("inspect residue"):
		return "inspect residue"
	return hint
