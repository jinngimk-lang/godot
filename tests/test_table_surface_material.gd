extends RefCounted

func run() -> Array[String]:
	var failures: Array[String] = []
	var shader_path := "res://art/shaders/reference_table.gdshader"
	if not ResourceLoader.exists(shader_path):
		failures.append("RED: missing reference table shader")
		return failures
	var shader := load(shader_path) as Shader
	if shader == null:
		failures.append("reference table shader did not load")
		return failures
	var code := shader.code
	if "NORMAL_MAP" not in code or "NORMAL_MAP_DEPTH" not in code:
		failures.append("RED: foreground table needs deterministic procedural micro-normal response instead of a flat color plane")
	if "grain_bump_strength" not in code:
		failures.append("RED: table shader needs a bounded micro-bump control per venue")

	var presentation = load("res://scripts/presentation/table_surface_presentation.gd").new()
	if not presentation.has_method("profile_parameters"):
		failures.append("RED: table presentation needs a pure profile_parameters helper so material contracts can be verified without renderer-owned scene fixtures")
	else:
		var market: Dictionary = presentation.call("profile_parameters","market_coldcase")
		var stone_value = market.get("stone_mode",0.0)
		var stone_mode: float = stone_value if typeof(stone_value) in [TYPE_FLOAT,TYPE_INT] else 0.0
		if stone_mode < 0.75:
			failures.append("RED: market counter must use stone/speckle mode instead of wood-wave mode")
		var bump_value = market.get("grain_bump_strength",0.0)
		var bump: float = bump_value if typeof(bump_value) in [TYPE_FLOAT,TYPE_INT] else 0.0
		if bump < 0.015 or bump > 0.12:
			failures.append("RED: market micro-bump must stay subtle but nonzero; got %.3f" % bump)
		var cafe: Dictionary = presentation.call("profile_parameters","cafe_window")
		var bar: Dictionary = presentation.call("profile_parameters","night_bar")
		var cafe_stone_value = cafe.get("stone_mode",1.0)
		var bar_stone_value = bar.get("stone_mode",1.0)
		var cafe_stone: float = cafe_stone_value if typeof(cafe_stone_value) in [TYPE_FLOAT,TYPE_INT] else 1.0
		var bar_stone: float = bar_stone_value if typeof(bar_stone_value) in [TYPE_FLOAT,TYPE_INT] else 1.0
		if cafe_stone > 0.25 or bar_stone > 0.25:
			failures.append("wood café/bar profiles must remain directional wood rather than stone")
	presentation.free()
	return failures
