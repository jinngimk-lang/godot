extends RefCounted
class_name SessionModel

const VARIANTS := [
	{
		"id": "warm_paper",
		"name": "Warm Paper",
		"drink": "OAT LATTE",
		"base_adhesion": 10.8,
		"release_increment": 0.038,
		"speed_gain": 0.018,
		"angle_gain": 0.30,
		"label_width": 1.20,
		"label_height": 0.42,
		"cup_color": Color(0.89, 0.84, 0.74),
		"cup_shell": "paper",
		"cup_dimensions": {"top_radius": 0.54, "bottom_radius": 0.45, "height": 1.48},
		"crumple_profile": {"rigidity": 0.04, "dent_gain": 0.018, "max_compression": 0.22},
		"contents_profile": {"type": "none"},
		"reward_theme": "warm",
		"hint": "soft paper • balanced adhesive"
	},
	{
		"id": "silky_long",
		"name": "Silky Long",
		"drink": "VANILLA FLAT",
		"base_adhesion": 8.6,
		"release_increment": 0.031,
		"speed_gain": 0.024,
		"angle_gain": 0.22,
		"label_width": 1.46,
		"label_height": 0.46,
		"cup_color": Color(0.80, 0.86, 0.82),
		"cup_shell": "paper",
		"cup_dimensions": {"top_radius": 0.52, "bottom_radius": 0.44, "height": 1.52},
		"crumple_profile": {"rigidity": 0.025, "dent_gain": 0.024, "max_compression": 0.28},
		"contents_profile": {"type": "none"},
		"reward_theme": "silky",
		"hint": "long peel • lighter glue"
	},
	{
		"id": "crisp_seal",
		"name": "Crisp Seal",
		"drink": "COCOA CLOUD",
		"base_adhesion": 13.4,
		"release_increment": 0.047,
		"speed_gain": 0.014,
		"angle_gain": 0.39,
		"label_width": 1.06,
		"label_height": 0.38,
		"cup_color": Color(0.86, 0.78, 0.70),
		"cup_shell": "paper",
		"cup_dimensions": {"top_radius": 0.55, "bottom_radius": 0.46, "height": 1.42},
		"crumple_profile": {"rigidity": 0.055, "dent_gain": 0.014, "max_compression": 0.18},
		"contents_profile": {"type": "none"},
		"reward_theme": "crisp",
		"hint": "firmer catch • crisp releases"
	}
]

var _variant_index := 0
var _clean_peels := 0
var _total_score := 0
var _unlocked_count := 1

func current_variant() -> Dictionary:
	return VARIANTS[_variant_index].duplicate(true)

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
	return {
		"unlocked_new": _unlocked_count > before,
		"unlocked_count": _unlocked_count,
		"clean_peels": _clean_peels,
		"total_score": _total_score
	}

func record_clean_peel(score: int) -> Dictionary:
	_total_score += maxi(score, 0)
	return record_ritual_complete()

func advance_item() -> Dictionary:
	_variant_index = (_variant_index + 1) % _unlocked_count
	return current_variant()

func restart_run() -> void:
	_variant_index = 0
	_clean_peels = 0
	_total_score = 0
	_unlocked_count = 1

func _unlock_count_for(clean_peels: int) -> int:
	if clean_peels >= 5:
		return 3
	if clean_peels >= 2:
		return 2
	return 1
