extends SubViewport
class_name LabelPrint

var _order_label: Label
var _drink_label: Label

func _ready() -> void:
	size = Vector2i(512, 256)
	transparent_bg = false
	render_target_update_mode = SubViewport.UPDATE_ALWAYS
	gui_disable_input = true
	_build_print()
	set_order("A17", "OAT LATTE")

func set_order(order_code: String, drink_name: String) -> void:
	if _order_label == null or _drink_label == null:
		return
	_order_label.text = "ORDER  %s" % order_code.strip_edges().to_upper()
	_drink_label.text = drink_name.strip_edges().to_upper()

func _build_print() -> void:
	var root := Control.new()
	root.name = "PrintRoot"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var paper := ColorRect.new()
	paper.color = Color(0.965, 0.95, 0.88, 1.0)
	paper.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(paper)

	var top_rule := ColorRect.new()
	top_rule.color = Color(0.12, 0.115, 0.105, 0.20)
	top_rule.position = Vector2(26, 22)
	top_rule.size = Vector2(458, 3)
	root.add_child(top_rule)

	_order_label = Label.new()
	_order_label.position = Vector2(30, 38)
	_order_label.size = Vector2(450, 70)
	_order_label.add_theme_font_size_override("font_size", 42)
	_order_label.add_theme_color_override("font_color", Color(0.075, 0.07, 0.065, 1.0))
	root.add_child(_order_label)

	_drink_label = Label.new()
	_drink_label.position = Vector2(30, 100)
	_drink_label.size = Vector2(330, 76)
	_drink_label.add_theme_font_size_override("font_size", 45)
	_drink_label.add_theme_color_override("font_color", Color(0.075, 0.07, 0.065, 1.0))
	root.add_child(_drink_label)

	var note := Label.new()
	note.text = "PICKUP"
	note.position = Vector2(32, 178)
	note.size = Vector2(180, 42)
	note.add_theme_font_size_override("font_size", 22)
	note.add_theme_color_override("font_color", Color(0.15, 0.14, 0.13, 0.78))
	root.add_child(note)

	var barcode_x := 360.0
	for i in range(18):
		var bar := ColorRect.new()
		bar.color = Color(0.08, 0.075, 0.07, 0.9)
		bar.position = Vector2(barcode_x, 169)
		var bar_width := 2.0 if i % 3 == 0 else 1.0
		bar.size = Vector2(bar_width, 48.0 - float((i * 7) % 11))
		root.add_child(bar)
		barcode_x += 5.0 + float(i % 2)
