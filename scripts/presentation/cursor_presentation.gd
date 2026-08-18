extends Node
class_name CursorPresentation

const CURSOR_TEXTURE := "res://assets/ui/peel_cursor.svg"
const CURSOR_SIZE := Vector2(28.0,28.0)
const HOTSPOT := Vector2(11.0,3.0)

var _cursor: TextureRect
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
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
