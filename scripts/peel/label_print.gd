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
	if drink.contains("RIDGE") or drink.contains("PALE"):
		_apply_standard_layout()
		_apply_bar_theme()
	elif drink.contains("YUZU"):
		_apply_standard_layout()
		_apply_market_theme()
	else:
		_apply_cafe_receipt_layout()
		_apply_cafe_theme(order_code.strip_edges().to_upper())

func _build_print() -> void:
	var root := Control.new()
	root.name = "PrintRoot"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	_paper = ColorRect.new()
	_paper.name = "Paper"
	_paper.color = Color(0.965,0.95,0.88,1.0)
	_paper.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(_paper)

	_top_rule = ColorRect.new()
	_top_rule.name = "TopRule"
	root.add_child(_top_rule)

	_order_label = Label.new()
	_order_label.name = "OrderLabel"
	root.add_child(_order_label)

	_drink_label = Label.new()
	_drink_label.name = "DrinkLabel"
	root.add_child(_drink_label)

	_note = Label.new()
	_note.name = "Note"
	root.add_child(_note)

	_accent = Label.new()
	_accent.name = "Accent"
	_accent.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_accent.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	root.add_child(_accent)

	for i in range(14):
		var bar := ColorRect.new()
		bar.name = "Barcode%02d" % i
		root.add_child(bar)
		_bars.append(bar)

	_apply_standard_layout()

func _apply_cafe_receipt_layout() -> void:
	size = Vector2i(448, 384)
	_top_rule.position = Vector2(28, 24)
	_top_rule.size = Vector2(392, 2)
	_order_label.position = Vector2(30, 52)
	_order_label.size = Vector2(388, 64)
	_order_label.add_theme_font_size_override("font_size", 38)
	_drink_label.position = Vector2(32, 126)
	_drink_label.size = Vector2(360, 46)
	_drink_label.add_theme_font_size_override("font_size", 24)
	_note.position = Vector2(34, 194)
	_note.size = Vector2(250, 82)
	_note.add_theme_font_size_override("font_size", 18)
	_accent.position = Vector2(300, 188)
	_accent.size = Vector2(112, 58)
	_accent.add_theme_font_size_override("font_size", 16)
	_layout_bars(318.0, 286.0, 58.0, 5.0)

func _apply_standard_layout() -> void:
	size = Vector2i(512, 256)
	_top_rule.position = Vector2(26,22)
	_top_rule.size = Vector2(458,3)
	_order_label.position = Vector2(30,38)
	_order_label.size = Vector2(450,58)
	_order_label.add_theme_font_size_override("font_size",34)
	_drink_label.position = Vector2(30,94)
	_drink_label.size = Vector2(430,72)
	_drink_label.add_theme_font_size_override("font_size",42)
	_note.position = Vector2(32,174)
	_note.size = Vector2(260,42)
	_note.add_theme_font_size_override("font_size",20)
	_accent.position = Vector2(300,151)
	_accent.size = Vector2(76,76)
	_accent.add_theme_font_size_override("font_size",58)
	_layout_bars(392.0, 170.0, 44.0, 5.0)

func _layout_bars(start_x: float, y: float, height: float, spacing: float) -> void:
	var x := start_x
	for i in range(_bars.size()):
		var bar := _bars[i]
		var bar_width := 2.0 if i % 3 == 0 else 1.0
		bar.position = Vector2(x,y)
		bar.size = Vector2(bar_width,maxf(20.0,height-float((i*7)%9)))
		x += spacing+float(i%2)

func _apply_bar_theme() -> void:
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

func _apply_market_theme() -> void:
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

func _apply_cafe_theme(order_code: String) -> void:
	_paper.color = Color(0.975,0.958,0.885,1.0)
	_top_rule.color = Color(0.095,0.085,0.073,0.24)
	_order_label.text = "COCOA CLOUD"
	_order_label.add_theme_font_size_override("font_size",38)
	_order_label.add_theme_color_override("font_color",Color(0.070,0.064,0.056,1.0))
	_drink_label.text = "MOCHA LATTE"
	_drink_label.add_theme_font_size_override("font_size",24)
	_drink_label.add_theme_color_override("font_color",Color(0.095,0.084,0.071,0.96))
	_note.text = "SMALL  •  OAT MILK\n$4.75"
	_note.add_theme_color_override("font_color",Color(0.13,0.115,0.098,0.82))
	_accent.text = "ORDER %s" % order_code
	_accent.add_theme_color_override("font_color",Color(0.15,0.13,0.11,0.62))
	_set_bar_color(Color(0.075,0.068,0.060,0.86))

func _set_bar_color(color: Color) -> void:
	for bar in _bars:
		bar.color = color
