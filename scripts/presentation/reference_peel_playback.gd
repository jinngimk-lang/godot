extends CanvasLayer
class_name ReferencePeelPlayback

const FRAME_SIZE := Vector2i(552,300)
const FRAME_PATHS := [
	"res://art/reference_motion/cafe_reference_frame_00.gd",
	"res://art/reference_motion/cafe_reference_frame_05.gd",
	"res://art/reference_motion/cafe_reference_frame_12.gd",
]

var _texture_rect: TextureRect
var _textures: Array[Texture2D] = []
var _label: LabelVisual
var _venue: VenuePresentation
var _active_index := -1
var _decode_failures: Array[String] = []

func _ready() -> void:
	layer = 100
	_build_overlay()
	_load_reference_textures()
	call_deferred("_bind")

func _process(_delta: float) -> void:
	if _label == null or _venue == null:
		_bind()
	if _texture_rect == null:
		return
	_texture_rect.position = Vector2.ZERO
	_texture_rect.size = get_viewport().get_visible_rect().size
	var cafe := _venue == null or _venue.get_active_profile_id() == "cafe_window"
	var label_visible := _label != null and _label.visible
	var ready := _textures.size() == FRAME_PATHS.size() and _decode_failures.is_empty()
	_texture_rect.visible = cafe and label_visible and ready
	if not _texture_rect.visible:
		return
	var progress := float(_label.get("_last_progress"))
	_set_frame_for_progress(progress)

func frame_index_for_progress(progress: float) -> int:
	var p := clampf(progress if is_finite(progress) else 0.0,0.0,1.0)
	return clampi(int(round(p * float(FRAME_PATHS.size()-1))),0,FRAME_PATHS.size()-1)

func frame_path_for_progress(progress: float) -> String:
	return String(FRAME_PATHS[frame_index_for_progress(progress)])

func get_reference_frame_count() -> int:
	return FRAME_PATHS.size()

func get_reference_frame_size() -> Vector2i:
	return FRAME_SIZE

func get_loaded_texture_count() -> int:
	return _textures.size()

func get_active_frame_index() -> int:
	return _active_index

func is_reference_visible() -> bool:
	return _texture_rect != null and _texture_rect.visible

func get_decode_failures() -> Array[String]:
	return _decode_failures.duplicate()

func _bind() -> void:
	var parent := get_parent()
	if parent == null:
		return
	_label = parent.get_node_or_null("PeelLabel") as LabelVisual
	_venue = parent.get_node_or_null("VenuePresentation") as VenuePresentation

func _build_overlay() -> void:
	_texture_rect = TextureRect.new()
	_texture_rect.name = "ReferenceMotionFrame"
	_texture_rect.position = Vector2.ZERO
	_texture_rect.size = get_viewport().get_visible_rect().size
	_texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_texture_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_texture_rect.visible = false
	add_child(_texture_rect)

func _load_reference_textures() -> void:
	_textures.clear()
	_decode_failures.clear()
	for path_value in FRAME_PATHS:
		var path := String(path_value)
		var source := load(path) as Script
		if source == null:
			_decode_failures.append("missing %s" % path)
			continue
		var constants := source.get_script_constant_map()
		var encoded := String(constants.get("DATA",""))
		if encoded.is_empty():
			_decode_failures.append("empty DATA in %s" % path)
			continue
		var raw := Marshalls.base64_to_raw(encoded)
		var image := Image.new()
		var error := image.load_jpg_from_buffer(raw)
		if error != OK or image.is_empty():
			_decode_failures.append("jpeg decode failed for %s (%d)" % [path,error])
			continue
		if image.get_size() != FRAME_SIZE:
			_decode_failures.append("unexpected frame size %s for %s" % [str(image.get_size()),path])
			continue
		_textures.append(ImageTexture.create_from_image(image))

func _set_frame_for_progress(progress: float) -> void:
	if _textures.is_empty():
		return
	var next_index := frame_index_for_progress(progress)
	if next_index == _active_index and _texture_rect.texture != null:
		return
	_active_index = next_index
	_texture_rect.texture = _textures[next_index]
