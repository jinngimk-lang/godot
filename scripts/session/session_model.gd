extends RefCounted
class_name SessionModel

const VARIANTS := [
	{
		"id":"coffee_shop",
		"name":"Coffee Shop",
		"drink":"COCOA CLOUD",
		"base_adhesion":10.8,
		"release_increment":0.014,
		"speed_gain":0.018,
		"angle_gain":0.30,
		"bond_response":10.0,
		"bond_relaxation":4.2,
		"safe_pull_speed":5.0,
		"tear_pull_speed":12.0,
		"residue_gain":0.16,
		"peel_feel":{"motion_pixels_per_release":3.25,"breakaway_multiplier":1.24,"bend_band_ratio":0.12,"backing_thickness":0.0034},
		"label_width":0.76,
		"label_height":0.60,
		"label_y":0.16,
		"label_profile":{"substrate":"thermal_paper","roughness":0.94,"thickness_scale":0.92,"fiber_scale":0.82,"edge_tint":Color(0.78,0.74,0.64),"adhesive_trace":0.16,"adhesive_tint":Color(0.84,0.78,0.62),"fiber_tint":Color(0.92,0.88,0.78),"fiber_gain":0.86},
		"cup_color":Color(0.95,0.935,0.895),
		"cup_shell":"paper",
		"cup_dimensions":{"top_radius":0.49,"bottom_radius":0.415,"height":1.40},
		"container_profile":{"kind":"paper_cup","body_color":Color(0.95,0.935,0.895),"lid_color":Color(0.022,0.021,0.020),"roughness":0.95,"top_radius":0.49,"bottom_radius":0.415,"height":1.40,"paper_fiber_strength":0.022},
		"scene_profile":{"id":"cafe_window","table_color":Color(0.20,0.095,0.040),"table_roughness":0.48,"ambient_color":Color(0.20,0.15,0.11),"accent_color":Color(1.0,0.70,0.38),"light_energy":1.18},
		"post_peel_action":"inspect",
		"crumple_profile":{"rigidity":0.04,"dent_gain":0.0042,"max_compression":0.22},
		"contents_profile":{"type":"none"},
		"reward_theme":"warm",
		"hint":"grab the lifted corner • slow pulls keep the paper clean"
	},
	{
		"id":"sauce_jar","name":"Jar","drink":"TOMATO BASIL SAUCE",
		"base_adhesion":11.6,"release_increment":0.0135,"speed_gain":0.019,"angle_gain":0.32,"bond_response":9.4,"bond_relaxation":3.8,"safe_pull_speed":4.8,"tear_pull_speed":10.4,"residue_gain":0.21,
		"peel_feel":{"motion_pixels_per_release":4.10,"breakaway_multiplier":1.34,"bend_band_ratio":0.09,"backing_thickness":0.0052},
		"label_width":0.84,"label_height":0.72,"label_y":-0.01,
		"label_profile":{"substrate":"rustic_jar_paper","roughness":0.90,"thickness_scale":1.06,"fiber_scale":1.08,"edge_tint":Color(0.72,0.61,0.45),"adhesive_trace":0.22,"adhesive_tint":Color(0.78,0.68,0.52),"fiber_tint":Color(0.90,0.82,0.68),"fiber_gain":1.04},
		"cup_color":Color(0.88,0.94,0.95),"cup_shell":"glass_jar","cup_dimensions":{"top_radius":0.385,"bottom_radius":0.405,"height":1.28},
		"container_profile":{"kind":"sauce_jar","body_color":Color(0.92,0.97,0.98),"glass_alpha":0.16,"liquid_color":Color(0.56,0.075,0.035),"lid_color":Color(0.29,0.20,0.13),"roughness":0.06},
		"scene_profile":{"id":"pantry_jar","table_color":Color(0.31,0.22,0.15),"table_roughness":0.58,"ambient_color":Color(0.46,0.39,0.31),"accent_color":Color(0.92,0.56,0.24),"light_energy":1.05},
		"post_peel_action":"inspect","crumple_profile":{"rigidity":0.05,"dent_gain":0.0038,"max_compression":0.20},"contents_profile":{"type":"none"},"reward_theme":"pantry","hint":"paper sticks harder to cool glass • keep the pull angle shallow"
	},
	{
		"id":"tin_can","name":"Tin Can","drink":"GOLDEN PEACHES",
		"base_adhesion":12.0,"release_increment":0.013,"speed_gain":0.020,"angle_gain":0.29,"bond_response":9.0,"bond_relaxation":3.4,"safe_pull_speed":4.5,"tear_pull_speed":9.5,"residue_gain":0.24,
		"peel_feel":{"motion_pixels_per_release":3.55,"breakaway_multiplier":1.22,"bend_band_ratio":0.11,"backing_thickness":0.0042},
		"label_width":0.88,"label_height":0.86,"label_y":-0.04,
		"label_profile":{"substrate":"grocery_wrap_paper","roughness":0.86,"thickness_scale":1.16,"fiber_scale":1.22,"edge_tint":Color(0.70,0.55,0.34),"adhesive_trace":0.27,"adhesive_tint":Color(0.80,0.68,0.43),"fiber_tint":Color(0.93,0.80,0.58),"fiber_gain":1.18},
		"cup_color":Color(0.66,0.68,0.70),"cup_shell":"tin","cup_dimensions":{"top_radius":0.405,"bottom_radius":0.398,"height":1.34},
		"container_profile":{"kind":"tin_can","body_color":Color(0.64,0.67,0.70),"roughness":0.31,"metallic":0.86},
		"scene_profile":{"id":"pantry_tin","table_color":Color(0.25,0.19,0.14),"table_roughness":0.62,"ambient_color":Color(0.42,0.36,0.30),"accent_color":Color(0.95,0.66,0.30),"light_energy":1.00},
		"post_peel_action":"inspect","crumple_profile":{"rigidity":0.06,"dent_gain":0.0034,"max_compression":0.18},"contents_profile":{"type":"none"},"reward_theme":"grocery","hint":"the wrap can tear • peel steadily around the metal body"
	},
	{
		"id":"yuzu_bottle","name":"Supermarket","drink":"YUZU SPARKLING",
		"base_adhesion":13.4,"release_increment":0.015,"speed_gain":0.014,"angle_gain":0.39,"bond_response":9.2,"bond_relaxation":4.8,"safe_pull_speed":5.4,"tear_pull_speed":11.5,"residue_gain":0.19,
		"peel_feel":{"motion_pixels_per_release":2.75,"breakaway_multiplier":1.12,"bend_band_ratio":0.15,"backing_thickness":0.0028},
		"label_width":0.92,"label_height":0.62,"label_y":-0.04,
		"label_profile":{"substrate":"coated_citrus","roughness":0.66,"thickness_scale":0.72,"fiber_scale":0.58,"edge_tint":Color(0.82,0.86,0.72),"adhesive_trace":0.11,"adhesive_tint":Color(0.78,0.86,0.66),"fiber_tint":Color(0.90,0.92,0.82),"fiber_gain":0.65},
		"cup_color":Color(0.84,0.95,0.94),"cup_shell":"clear_glass","cup_dimensions":{"top_radius":0.335,"bottom_radius":0.315,"height":1.52},
		"container_profile":{"kind":"clear_bottle","body_color":Color(0.94,0.985,0.98),"glass_alpha":0.18,"neck_radius":0.17,"liquid_color":Color(0.91,0.93,0.70),"roughness":0.045},
		"scene_profile":{"id":"market_coldcase","table_color":Color(0.76,0.77,0.75),"table_roughness":0.38,"ambient_color":Color(0.60,0.67,0.72),"accent_color":Color(0.70,0.90,1.0),"light_energy":1.02},
		"post_peel_action":"inspect","crumple_profile":{"rigidity":0.055,"dent_gain":0.0035,"max_compression":0.18},"contents_profile":{"type":"none"},"reward_theme":"crisp","hint":"coated paper lifts cleanly • inspect the translucent adhesive trace"
	},
	{
		"id":"lemon_can","name":"Can","drink":"LEMON SPARKLING SODA",
		"base_adhesion":12.7,"release_increment":0.014,"speed_gain":0.016,"angle_gain":0.35,"bond_response":9.7,"bond_relaxation":4.1,"safe_pull_speed":5.1,"tear_pull_speed":10.8,"residue_gain":0.18,
		"peel_feel":{"motion_pixels_per_release":2.40,"breakaway_multiplier":1.08,"bend_band_ratio":0.19,"backing_thickness":0.0022},
		"label_width":0.90,"label_height":0.88,"label_y":-0.03,
		"label_profile":{"substrate":"thin_can_wrap","roughness":0.58,"thickness_scale":0.62,"fiber_scale":0.42,"edge_tint":Color(0.88,0.83,0.61),"adhesive_trace":0.14,"adhesive_tint":Color(0.86,0.80,0.55),"fiber_tint":Color(0.95,0.90,0.70),"fiber_gain":0.48},
		"cup_color":Color(0.74,0.76,0.78),"cup_shell":"aluminum_can","cup_dimensions":{"top_radius":0.385,"bottom_radius":0.402,"height":1.42},
		"container_profile":{"kind":"soda_can","body_color":Color(0.74,0.77,0.80),"roughness":0.25,"metallic":0.92},
		"scene_profile":{"id":"market_can","table_color":Color(0.43,0.38,0.31),"table_roughness":0.42,"ambient_color":Color(0.48,0.44,0.39),"accent_color":Color(1.0,0.72,0.26),"light_energy":1.08},
		"post_peel_action":"inspect","crumple_profile":{"rigidity":0.07,"dent_gain":0.0030,"max_compression":0.16},"contents_profile":{"type":"none"},"reward_theme":"citrus","hint":"thin wrap follows the can closely • keep the lifted sheet smooth"
	}
]

var _variant_index := 0
var _clean_peels := 0
var _total_score := 0
var _unlocked_count := VARIANTS.size()

func current_variant() -> Dictionary:
	return VARIANTS[_variant_index].duplicate(true)

func get_variant_index() -> int:
	return _variant_index

func get_clean_peels() -> int:
	return _clean_peels

func get_total_score() -> int:
	return _total_score

func get_unlocked_count() -> int:
	return _unlocked_count

func record_ritual_complete() -> Dictionary:
	_clean_peels += 1
	return {"unlocked_new":false,"unlocked_count":_unlocked_count,"clean_peels":_clean_peels,"total_score":_total_score}

func record_clean_peel(score: int) -> Dictionary:
	_total_score += maxi(score,0)
	return record_ritual_complete()

func advance_item() -> Dictionary:
	_variant_index = (_variant_index+1) % VARIANTS.size()
	return current_variant()

func select_variant(index: int) -> Dictionary:
	_variant_index = posmod(index,VARIANTS.size())
	return current_variant()

func select_relative(direction: int) -> Dictionary:
	return select_variant(_variant_index+direction)

func restart_run() -> void:
	_variant_index = 0
	_clean_peels = 0
	_total_score = 0
	_unlocked_count = VARIANTS.size()
