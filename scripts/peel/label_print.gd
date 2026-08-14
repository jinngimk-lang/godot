extends SubViewport
class_name LabelPrint

var _paper: ColorRect
var _top_rule: ColorRect
var _order_label: Label
var _drink_label: Label
var _note: Label
var _accent: Label
var _bars: Array[ColorRect] = []

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
	var drink := drink_name.strip_edges().to_upper()
	_order_label.text = "ORDER  %s" % order_code.strip_edges().to_upper()
	_drink_label.text = drink
	_apply_theme_for_drink(drink)

func _build_print() -> void:
	var root := Control.new()
	root.name = "PrintRoot"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	_paper = ColorRect.new()
	_paper.color = Color(0.965,0.95,0.88,1.0)
	_paper.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(_paper)

	_top_rule = ColorRect.new()
	_top_rule.position = Vector2(26,22)
	_top_rule.size = Vector2(458,3)
	root.add_child(_top_rule)

	_order_label = Label.new()
	_order_label.position = Vector2(30,38)
	_order_label.size = Vector2(450,58)
	_order_label.add_theme_font_size_override("font_size",34)
	root.add_child(_order_label)

	_drink_label = Label.new()
	_drink_label.position = Vector2(30,94)
	_drink_label.size = Vector2(430,72)
	_drink_label.add_theme_font_size_override("font_size",42)
	root.add_child(_drink_label)

	_note = Label.new()
	_note.position = Vector2(32,174)
	_note.size = Vector2(260,42)
	_note.add_theme_font_size_override("font_size",20)
	root.add_child(_note)

	_accent = Label.new()
	_accent.position = Vector2(300,151)
	_accent.size = Vector2(76,76)
	_accent.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_accent.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_accent.add_theme_font_size_override("font_size",58)
	root.add_child(_accent)

	var barcode_x := 392.0
	for i in range(14):
		var bar := ColorRect.new()
		bar.position = Vector2(barcode_x,170)
		var bar_width := 2.0 if i % 3 == 0 else 1.0
		bar.size = Vector2(bar_width,44.0-float((i*7)%9))
		root.add_child(bar)
		_bars.append(bar)
		barcode_x += 5.0+float(i%2)

func _apply_theme_for_drink(drink: String) -> void:
	if drink.contains("RIDGE") or drink.contains("PALE"):
		_paper.color = Color(0.105,0.090,0.070,1.0)
		_top_rule.color = Color(0.78,0.49,0.20,0.82)
		_order_label.text = "MOUNTAIN RIDGE"
		_order_label.add_theme_font_size_override("font_size",31)
		_order_label.add_theme_color_override("font_color",Color(0.90,0.70,0.38,1.0))
		_drink_label.text = "PALE ALE"
		_drink_label.add_theme_font_size_override("font_size",45)
		_drink_label.add_theme_color_override("font_color",Color(0.95,0.84,0.58,1.0))
		_note.text = "BOTTLED SMALL BATCH"
		_note.add_theme_color_override("font_color",Color(0.78,0.63,0.40,0.84))
		_accent.text = "◆"
		_accent.add_theme_color_override("font_color",Color(0.84,0.50,0.18,0.70))
		_set_bar_color(Color(0.84,0.64,0.36,0.72))
	elif drink.contains("YUZU"):
		_paper.color = Color(0.965,0.965,0.915,1.0)
		_top_rule.color = Color(0.32,0.50,0.18,0.55)
		_order_label.text = "SPARKLING CITRUS"
		_order_label.add_theme_font_size_override("font_size",28)
		_order_label.add_theme_color_override("font_color",Color(0.30,0.46,0.17,1.0))
		_drink_label.text = "YUZU"
		_drink_label.add_theme_font_size_override("font_size",54)
		_drink_label.add_theme_color_override("font_color",Color(0.36,0.54,0.19,1.0))
		_note.text = "CITRUS • 330 ml"
		_note.add_theme_color_override("font_color",Color(0.27,0.40,0.16,0.82))
		_accent.text = "●"
		_accent.add_theme_color_override("font_color",Color(0.93,0.77,0.16,0.94))
		_set_bar_color(Color(0.30,0.42,0.20,0.78))
	else:
		_paper.color = Color(0.965,0.95,0.88,1.0)
		_top_rule.color = Color(0.12,0.115,0.105,0.20)
		_order_label.add_theme_font_size_override("font_size",34)
		_order_label.add_theme_color_override("font_color",Color(0.075,0.07,0.065,1.0))
		_drink_label.add_theme_font_size_override("font_size",42)
		_drink_label.add_theme_color_override("font_color",Color(0.075,0.07,0.065,1.0))
		_note.text = "PICKUP"
		_note.add_theme_color_override("font_color",Color(0.15,0.14,0.13,0.78))
		_accent.text = ""
		_set_bar_color(Color(0.08,0.075,0.07,0.90))

func _set_bar_color(color: Color) -> void:
	for bar in _bars:
		bar.color = color
