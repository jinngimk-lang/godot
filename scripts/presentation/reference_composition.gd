extends Node
class_name ReferenceComposition

const FOV_BY_KIND := {
	"paper_cup":35.5,
	"sauce_jar":36.5,
	"tin_can":36.5,
	"clear_bottle":41.5,
	"soda_can":36.5
}
const FOCUS_Y_BY_KIND := {
	"paper_cup":0.06,
	"sauce_jar":0.02,
	"tin_can":0.02,
	"clear_bottle":0.42,
	"soda_can":0.03
}

var _last_kind := ""
var _last_target := -1.0

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
	camera.position = Vector3(0.0,1.02,3.55)
	camera.fov = target_fov_for_kind("paper_cup")
	camera.look_at(Vector3(0.0,float(FOCUS_Y_BY_KIND["paper_cup"]),0.0),Vector3.UP)
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
	var offset_value = root.get("_zoom_fov_offset")
	var offset := float(offset_value) if offset_value != null else 0.0
	var target := clampf(target_fov_for_kind(kind)+offset,32.0,48.0)
	var focus_y := float(FOCUS_Y_BY_KIND.get(kind,0.04))
	if kind != _last_kind:
		camera.position = Vector3(0.0,1.02,3.55)
		camera.look_at(Vector3(0.0,focus_y,0.0),Vector3.UP)
	if kind == _last_kind and absf(target-_last_target) <= 0.001 and absf(camera.fov-target) <= 0.001:
		return
	camera.fov = target
	_last_kind = kind
	_last_target = target

static func target_fov_for_kind(kind: String) -> float:
	return float(FOV_BY_KIND.get(kind,36.5))
