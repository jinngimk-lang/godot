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
		"label_width":1.14,
		"label_height":0.38,
		"label_y":0.20,
		"cup_color":Color(0.91,0.87,0.78),
		"cup_shell":"paper",
		"cup_dimensions":{"top_radius":0.54,"bottom_radius":0.45,"height":1.48},
		"container_profile":{"kind":"paper_cup","body_color":Color(0.91,0.87,0.78),"lid_color":Color(0.025,0.024,0.022),"roughness":0.90},
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
		"label_width":1.06,
		"label_height":0.44,
		"label_y":0.10,
		"cup_color":Color(0.19,0.065,0.020),
		"cup_shell":"amber_glass",
		"cup_dimensions":{"top_radius":0.43,"bottom_radius":0.43,"height":1.34},
		"container_profile":{"kind":"amber_bottle","body_color":Color(0.20,0.065,0.018),"glass_alpha":0.76,"neck_radius":0.21,"roughness":0.09},
		"scene_profile":{"id":"night_bar","table_color":Color(0.055,0.028,0.015),"table_roughness":0.26,"ambient_color":Color(0.055,0.028,0.018),"accent_color":Color(1.0,0.34,0.055),"light_energy":1.34},
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
		"label_width":1.12,
		"label_height":0.50,
		"label_y":0.06,
		"cup_color":Color(0.78,0.90,0.88),
		"cup_shell":"clear_glass",
		"cup_dimensions":{"top_radius":0.42,"bottom_radius":0.42,"height":1.38},
		"container_profile":{"kind":"clear_bottle","body_color":Color(0.88,0.97,0.96),"glass_alpha":0.28,"neck_radius":0.20,"liquid_color":Color(0.91,0.91,0.66),"roughness":0.07},
		"scene_profile":{"id":"market_coldcase","table_color":Color(0.75,0.75,0.72),"table_roughness":0.40,"ambient_color":Color(0.60,0.67,0.72),"accent_color":Color(0.70,0.90,1.0),"light_energy":1.02},
		"post_peel_action":"inspect",
		"crumple_profile":{"rigidity":0.055,"dent_gain":0.0035,"max_compression":0.18},
		"contents_profile":{"type":"ice","count":3,"cube_size":0.145,"motion_gain":0.55},
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
	if clean_peels >= 5: return 3
	if clean_peels >= 2: return 2
	return 1
