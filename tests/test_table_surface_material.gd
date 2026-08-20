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
	if "plank_contrast" not in code or "plank_count" not in code:
		failures.append("TABLE_DEPTH_RED: wood target needs readable plank-to-plank value breakup, not one flat brown slab")
	if "specular_variation" not in code:
		failures.append("TABLE_DEPTH_RED: foreground surface needs directional roughness/specular variation")
	if "varying vec3 local_pos" not in code or "local_pos = VERTEX" not in code:
		failures.append("TABLE_PROJECTION_RED: table grain must use object-space projection so BoxMesh UVs cannot collapse the visible wood target")

	var presentation = load("res://scripts/presentation/table_surface_presentation.gd").new()
	if not presentation.has_method("profile_parameters"):
		failures.append("RED: table presentation needs a pure profile_parameters helper so material contracts can be verified without renderer-owned scene fixtures")
	else:
		var market: Dictionary = presentation.call("profile_parameters","market_coldcase")
		var stone_value = market.get("stone_mode",0.0)
		var stone_mode: float = stone_value if typeof(stone_value) in [TYPE_FLOAT,TYPE_INT] else 0.0
		if stone_mode < 0.75:
			failures.append("RED: market counter must use stone/speckle mode instead of wood-wave mode")
		var base := market.get("base_color",Vector3.ZERO) as Vector3
		if base.x < 0.84 or base.y < 0.85 or base.z < 0.84:
			failures.append("MARKET_COUNTER_RED: Yuzu target needs a bright clean refrigerated counter")
		var grain := float(market.get("grain_strength",1.0))
		if grain > 0.010:
			failures.append("MARKET_COUNTER_RED: supermarket counter is too mottled/noisy; grain %.3f" % grain)
		var bump_value = market.get("grain_bump_strength",0.0)
		var bump: float = bump_value if typeof(bump_value) in [TYPE_FLOAT,TYPE_INT] else 0.0
		if bump < 0.003 or bump > 0.012:
			failures.append("MARKET_COUNTER_RED: supermarket micro-bump should be restrained; got %.3f" % bump)
		if float(market.get("specular_variation",1.0)) > 0.020:
			failures.append("MARKET_COUNTER_RED: supermarket counter should read clean, not patchy")
		var cafe: Dictionary = presentation.call("profile_parameters","cafe_window")
		var bar: Dictionary = presentation.call("profile_parameters","night_bar")
		var cafe_stone_value = cafe.get("stone_mode",1.0)
		var bar_stone_value = bar.get("stone_mode",1.0)
		var cafe_stone: float = cafe_stone_value if typeof(cafe_stone_value) in [TYPE_FLOAT,TYPE_INT] else 1.0
		var bar_stone: float = bar_stone_value if typeof(bar_stone_value) in [TYPE_FLOAT,TYPE_INT] else 1.0
		if cafe_stone > 0.25 or bar_stone > 0.25:
			failures.append("wood café/bar profiles must remain directional wood rather than stone")
		if float(cafe.get("plank_contrast",0.0)) < 0.08:
			failures.append("TABLE_DEPTH_RED: cafe walnut needs visible plank value separation")
		if float(cafe.get("specular_variation",0.0)) < 0.05:
			failures.append("TABLE_DEPTH_RED: cafe walnut needs grain-following highlight breakup")
		if float(cafe.get("plank_count",0.0)) < 4.0:
			failures.append("TABLE_DEPTH_RED: cafe foreground should show several broad wood planks")
	presentation.free()
	return failures
