extends RefCounted
class_name SessionModel

const VARIANTS := [
	{
		"id":"warm_paper",
		"name":"Window Café Cup",
		"drink":"COCOA CLOUD",
		"base_adhesion":10.8,
		"release_increment":0.038,
		"speed_gain":0.018,
		"angle_gain":0.30,
		"bond_response":10.0,
		"bond_relaxation":4.2,
		"safe_pull_speed":5.0,
		"tear_pull_speed":12.0,
		"residue_gain":0.16,
		"label_width":0.68,
		"label_height":0.58,
		"label_y":0.18,
		"label_profile":{
			"substrate":"thermal_paper",
			"roughness":0.94,
			"thickness_scale":0.92,
			"fiber_scale":0.82,
			"edge_tint":Color(0.78,0.74,0.64),
			"adhesive_trace":0.16,
			"adhesive_tint":Color(0.84,0.78,0.62),
			"fiber_tint":Color(0.92,0.88,0.78),
			"fiber_gain":0.86
		},
		"cup_color":Color(0.95,0.935,0.895),
		"cup_shell":"paper",
		"cup_dimensions":{"top_radius":0.49,"bottom_radius":0.415,"height":1.40},
		"container_profile":{"kind":"paper_cup","body_color":Color(0.95,0.935,0.895),"lid_color":Color(0.022,0.021,0.020),"roughness":0.95,"top_radius":0.49,"bottom_radius":0.415,"height":1.40,"paper_fiber_strength":0.022},
		"scene_profile":{"id":"cafe_window","table_color":Color(0.20,0.095,0.040),"table_roughness":0.48,"ambient_color":Color(0.20,0.15,0.11),"accent_color":Color(1.0,0.70,0.38),"light_energy":1.18},
		"post_peel_action":"crumple",
		"crumple_profile":{"rigidity":0.04,"dent_gain":0.0042,"max_compression":0.22},
		"contents_profile":{"type":"none"},
		"reward_theme":"warm",
		"hint":"peel anywhere • slow pull keeps the paper clean"
	},
	{
		"id":"silky_long",
		"name":"Amber Bar Bottle",
		"drink":"RIDGE PALE",
		"base_adhesion":12.2,
		"release_increment":0.033,
		"speed_gain":0.020,
		"angle_gain":0.27,
		"bond_response":8.4,
		"bond_relaxation":3.2,
		"safe_pull_speed":4.2,
		"tear_pull_speed":9.0,
		"residue_gain":0.24,
		"label_width":0.90,
		"label_height":0.35,
		"label_y":0.00,
		"label_profile":{
			"substrate":"uncoated_fiber",
			"roughness":0.88,
			"thickness_scale":1.22,
			"fiber_scale":1.35,
			"edge_tint":Color(0.62,0.48,0.32),
			"adhesive_trace":0.24,
			"adhesive_tint":Color(0.82,0.70,0.48),
			"fiber_tint":Color(0.90,0.82,0.68),
			"fiber_gain":1.25
		},
		"cup_color":Color(0.34,0.10,0.022),
		"cup_shell":"amber_glass",
		"cup_dimensions":{"top_radius":0.345,"bottom_radius":0.325,"height":1.48},
		"container_profile":{"kind":"amber_bottle","body_color":Color(0.38,0.11,0.024),"glass_alpha":0.36,"neck_radius":0.175,"roughness":0.048},
		"scene_profile":{"id":"night_bar","table_color":Color(0.052,0.027,0.015),"table_roughness":0.25,"ambient_color":Color(0.055,0.028,0.018),"accent_color":Color(1.0,0.34,0.055),"light_energy":1.18},
		"post_peel_action":"inspect",
		"crumple_profile":{"rigidity":0.025,"dent_gain":0.0052,"max_compression":0.28},
		"contents_profile":{"type":"none"},
		"reward_theme":"amber",
		"hint":"fibrous label • fast pulls leave torn backing"
	},
	{
		"id":"crisp_seal",
		"name":"Market Citrus Bottle",
		"drink":"YUZU SPARKLING",
		"base_adhesion":13.4,
		"release_increment":0.041,
		"speed_gain":0.014,
		"angle_gain":0.39,
		"bond_response":9.2,
		"bond_relaxation":4.8,
		"safe_pull_speed":5.4,
		"tear_pull_speed":11.5,
		"residue_gain":0.19,
		"label_width":0.88,
		"label_height":0.38,
		"label_y":-0.02,
		"label_profile":{
			"substrate":"coated_citrus",
			"roughness":0.66,
			"thickness_scale":0.72,
			"fiber_scale":0.58,
			"edge_tint":Color(0.82,0.86,0.72),
			"adhesive_trace":0.11,
			"adhesive_tint":Color(0.78,0.86,0.66),
			"fiber_tint":Color(0.90,0.92,0.82),
			"fiber_gain":0.65
		},
		"cup_color":Color(0.84,0.95,0.94),
		"cup_shell":"clear_glass",
		"cup_dimensions":{"top_radius":0.335,"bottom_radius":0.315,"height":1.52},
		"container_profile":{"kind":"clear_bottle","body_color":Color(0.94,0.985,0.98),"glass_alpha":0.16,"neck_radius":0.17,"liquid_color":Color(0.91,0.93,0.70),"roughness":0.040},
		"scene_profile":{"id":"market_coldcase","table_color":Color(0.76,0.77,0.75),"table_roughness":0.38,"ambient_color":Color(0.60,0.67,0.72),"accent_color":Color(0.70,0.90,1.0),"light_energy":1.02},
		"post_peel_action":"inspect",
		"crumple_profile":{"rigidity":0.055,"dent_gain":0.0035,"max_compression":0.18},
		"contents_profile":{"type":"ice","count":3,"cube_size":0.145,"motion_gain":0.55,"max_center_y":0.34,"layout":"glass_cluster"},
		"reward_theme":"crisp",
		"hint":"cool glass • inspect residue and ice from every angle"
	}
]

var _variant_index := 0
var _clean_peels := 0
var _total_score := 0
var _unlocked_count := 1

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
	var before := _unlocked_count
	_clean_peels += 1
	_unlocked_count = _unlock_count_for(_clean_peels)
	return {"unlocked_new":_unlocked_count > before,"unlocked_count":_unlocked_count,"clean_peels":_clean_peels,"total_score":_total_score}

func record_clean_peel(score: int) -> Dictionary:
	_total_score += maxi(score,0)
	return record_ritual_complete()

func advance_item() -> Dictionary:
	_variant_index = (_variant_index+1) % _unlocked_count
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
	_unlocked_count = 1

func _unlock_count_for(clean_peels: int) -> int:
	# The showcase is a short three-scene tactile sequence, not a grind gate.
	# One clean completion unlocks the next scene so Continue always moves the
	# player forward: Café -> Bar -> Market -> Café.
	if clean_peels >= 2: return 3
	if clean_peels >= 1: return 2
	return 1
