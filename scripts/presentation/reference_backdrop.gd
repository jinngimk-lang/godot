extends Sprite3D
class_name ReferenceBackdrop

const TARGET_WORLD_WIDTH := 8.40
const BASE_POSITION := Vector3(0.0,0.72,-1.43)
const PROFILES := {
	"cafe_window":{
		"texture":"res://art/reference_backdrops/cafe_backdrop.jpg",
		"world_width":8.40,
		"offset":Vector2(0.0,0.00),
		"modulate":Color(0.94,0.90,0.84,1.0)
	},
	"pantry_jar":{
		# Bright warm grocery/food-prep crop. The realtime pale stone counter and
		# sauce jar make this read as pantry/kitchen rather than another café.
		"texture":"res://art/reference_backdrops/market_backdrop.jpg",
		"world_width":6.10,
		"offset":Vector2(-0.92,0.13),
		"modulate":Color(1.00,0.88,0.72,1.0)
	},
	"pantry_tin":{
		# Tighter neutral shelving/bar-stock crop gives the metal can a darker,
		# industrial grocery identity distinct from the bright supermarket.
		"texture":"res://art/reference_backdrops/bar_backdrop.jpg",
		"world_width":6.25,
		"offset":Vector2(0.56,0.08),
		"modulate":Color(0.82,0.82,0.78,1.0)
	},
	"market_coldcase":{
		"texture":"res://art/reference_backdrops/market_backdrop.jpg",
		"world_width":8.40,
		"offset":Vector2(0.0,0.02),
		"modulate":Color(0.98,0.99,1.00,1.0)
	},
	"market_can":{
		# Window-heavy cool crop reads as a brighter beverage/patio counter and no
		# longer shares the dark bar plate used by the tin/pantry scene.
		"texture":"res://art/reference_backdrops/cafe_backdrop.jpg",
		"world_width":5.75,
		"offset":Vector2(-1.18,0.16),
		"modulate":Color(0.72,0.90,0.88,1.0)
	}
}

var _active_id := ""

func _ready() -> void:
	name = "ReferenceBackdrop"
	centered = true
	position = BASE_POSITION
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

func profile_visual_signature(profile_id: String) -> String:
	var id := profile_id if profile_id in PROFILES else "cafe_window"
	var profile: Dictionary = PROFILES[id]
	var offset: Vector2 = profile.get("offset",Vector2.ZERO)
	var tint: Color = profile.get("modulate",Color.WHITE)
	return "%s|%.2f|%.2f,%.2f|%.2f,%.2f,%.2f" % [
		String(profile.get("texture","")),
		float(profile.get("world_width",TARGET_WORLD_WIDTH)),
		offset.x,offset.y,
		tint.r,tint.g,tint.b
	]

func _apply(profile_id: String) -> void:
	if profile_id not in PROFILES:
		profile_id = "cafe_window"
	_active_id = profile_id
	var profile: Dictionary = PROFILES[profile_id]
	var loaded := load(String(profile.get("texture",""))) as Texture2D
	if loaded != null:
		texture = loaded
		pixel_size = float(profile.get("world_width",TARGET_WORLD_WIDTH))/maxf(float(loaded.get_width()),1.0)
	var offset: Vector2 = profile.get("offset",Vector2.ZERO)
	position = BASE_POSITION+Vector3(offset.x,offset.y,0.0)
	var tint_value = profile.get("modulate",Color.WHITE)
	modulate = tint_value if tint_value is Color else Color.WHITE

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
