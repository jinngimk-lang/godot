extends Sprite3D
class_name ReferenceBackdrop

const TEXTURES := {
	"cafe_window":"res://art/reference_backdrops/cafe_backdrop.jpg",
	"night_bar":"res://art/reference_backdrops/bar_backdrop.jpg",
	"market_coldcase":"res://art/reference_backdrops/market_backdrop.jpg"
}

var _active_id := ""

func _ready() -> void:
	name = "ReferenceBackdrop"
	centered = true
	pixel_size = 0.0098
	position = Vector3(0.0,0.72,-1.43)
	shaded = false
	double_sided = true
	alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED
	_apply("cafe_window")
	call_deferred("_mask_blockout_geometry")

func _process(_delta: float) -> void:
	var venue := get_parent().get_node_or_null("VenuePresentation")
	if venue == null or not venue.has_method("get_active_profile_id"):
		return
	var next_id := String(venue.call("get_active_profile_id"))
	if next_id != _active_id:
		_apply(next_id)
	_mask_blockout_geometry()

func get_active_profile_id() -> String:
	return _active_id

func _apply(profile_id: String) -> void:
	if profile_id not in TEXTURES:
		profile_id = "cafe_window"
	_active_id = profile_id
	var loaded := load(String(TEXTURES[profile_id])) as Texture2D
	if loaded != null:
		texture = loaded
	if profile_id == "market_coldcase":
		modulate = Color(0.96,0.96,0.96,1.0)
	elif profile_id == "night_bar":
		# The dedicated plate is already warm/dark; keep its practical highlights
		# instead of crushing it through the old café-recolor multiplier.
		modulate = Color(0.92,0.84,0.76,1.0)
	else:
		modulate = Color(0.91,0.88,0.84,1.0)

func _mask_blockout_geometry() -> void:
	var venue := get_parent().get_node_or_null("VenuePresentation")
	if venue == null:
		return
	for root_name in ["CafeWindows","BarBackShelf","MarketCooler"]:
		var root := venue.get_node_or_null(root_name) as Node3D
		if root == null:
			continue
		for child in root.get_children():
			if child is VisualInstance3D or child is Light3D:
				(child as Node3D).visible = false
