extends Node
class_name CursorPresentation

const CURSOR_TEXTURE := "res://assets/ui/peel_cursor.svg"
const CURSOR_SIZE := Vector2(28.0,28.0)
const HOTSPOT := Vector2(11.0,3.0)

var _cursor: TextureRect
var _rub_badge: Label
var _debug_override := false
var _debug_position := Vector2.ZERO

func _ready() -> void:
	call_deferred("_bind")

func _exit_tree() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _process(_delta: float) -> void:
	if _cursor == null:
		_bind()
	if _cursor == null:
		return
	var pointer := _debug_position if _debug_override else get_viewport().get_mouse_position()
	_cursor.position = pointer-HOTSPOT
	_cursor.visible = true
	_update_scrub_feedback(pointer)

func set_debug_position(position: Vector2) -> void:
	_debug_override = true
	_debug_position = position
	if _cursor != null:
		_cursor.position = position-HOTSPOT
		_cursor.visible = true

func clear_debug_position() -> void:
	_debug_override = false

func get_cursor_node() -> TextureRect:
	return _cursor

func is_scrub_feedback_visible() -> bool:
	return _rub_badge != null and _rub_badge.visible

func _bind() -> void:
	var parent := get_parent()
	if parent == null:
		return
	var layer := parent.get_node_or_null("HUD") as CanvasLayer
	if layer == null:
		return
	if _cursor == null:
		_cursor = TextureRect.new()
		_cursor.name = "PeelCursor"
		_cursor.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_cursor.size = CURSOR_SIZE
		_cursor.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_cursor.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_cursor.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		_cursor.z_index = 100
		var texture := load(CURSOR_TEXTURE) as Texture2D
		_cursor.texture = texture
		layer.add_child(_cursor)
		_rub_badge = Label.new()
		_rub_badge.name = "RubBadge"
		_rub_badge.text = "RUB  ↔"
		_rub_badge.size = Vector2(62,22)
		_rub_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_rub_badge.z_index = 99
		_rub_badge.add_theme_font_size_override("font_size",11)
		_rub_badge.add_theme_color_override("font_color",Color(1.0,0.72,0.18,0.96))
		_rub_badge.add_theme_color_override("font_shadow_color",Color(0,0,0,0.92))
		_rub_badge.add_theme_constant_override("shadow_offset_x",1)
		_rub_badge.add_theme_constant_override("shadow_offset_y",1)
		_rub_badge.visible = false
		layer.add_child(_rub_badge)
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _update_scrub_feedback(pointer: Vector2) -> void:
	var lab := get_parent()
	var lifecycle = lab.get("_lifecycle") if lab != null else null
	var scrub = lab.get("_scrub_model") if lab != null else null
	var scrub_ready: bool = lifecycle != null and lifecycle.has_method("is_resolved") and lifecycle.is_resolved() and scrub != null and not scrub.is_complete()
	var intensity := float(scrub.get_rub_intensity()) if scrub_ready and scrub.has_method("get_rub_intensity") else 0.0
	if scrub_ready:
		var pulse := sin(float(Time.get_ticks_msec())*0.028)*intensity
		_cursor.rotation = pulse*0.18
		_cursor.scale = Vector2.ONE*(1.0+0.09*intensity)
		_cursor.modulate = Color(1.0,0.88+0.10*intensity,0.70+0.24*intensity,1.0)
	else:
		_cursor.rotation = 0.0
		_cursor.scale = Vector2.ONE
		_cursor.modulate = Color.WHITE
	if _rub_badge != null:
		_rub_badge.position = pointer+Vector2(17,9)
		_rub_badge.visible = scrub_ready
