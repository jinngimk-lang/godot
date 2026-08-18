extends Node
class_name ReferenceComposition

const CAFE_FOV := 39.0
const BOTTLE_FOV := 43.0

var _last_kind := ""

func _ready() -> void:
	call_deferred("_apply")

func _process(_delta: float) -> void:
	_sync_variant_framing()

func _apply() -> void:
	var root := get_parent()
	if root == null:
		return
	var camera := root.get_node_or_null("Camera") as Camera3D
	if camera == null:
		return
	camera.position = Vector3(0.0,0.80,3.55)
	camera.fov = CAFE_FOV
	camera.look_at(Vector3(0.0,0.15,0.0),Vector3.UP)
	_sync_variant_framing()

func _sync_variant_framing() -> void:
	var root := get_parent()
	if root == null:
		return
	var camera := root.get_node_or_null("Camera") as Camera3D
	var product := root.get_node_or_null("ProductPresentation") as ProductPresentation
	if camera == null or product == null:
		return
	var kind := product.get_active_kind()
	var target_fov := target_fov_for_kind(kind)
	if kind == _last_kind and absf(camera.fov-target_fov) <= 0.001:
		return
	camera.fov = target_fov
	_last_kind = kind

static func target_fov_for_kind(kind: String) -> float:
	return CAFE_FOV if kind == "paper_cup" else BOTTLE_FOV
