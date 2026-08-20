extends RefCounted

func run() -> Array[String]:
	var failures: Array[String] = []
	var path := "res://scripts/presentation/venue_presentation.gd"
	if not ResourceLoader.exists(path):
		return ["VENUE_RED: missing VenuePresentation"]
	var venue = load(path).new()
	var ids := ["cafe_window","pantry_jar","pantry_tin","market_coldcase","market_can"]
	for id in ids:
		venue.apply_profile({"id":id,"table_color":Color(0.28,0.22,0.18),"table_roughness":0.55})
		if venue.get_active_profile_id() != id:
			failures.append("VENUE_RED: venue should activate %s" % id)
		var count_before: int = int(venue.get_child_count())
		venue.apply_profile({"id":id,"table_color":Color(0.28,0.22,0.18),"table_roughness":0.55})
		if venue.get_child_count() != count_before:
			failures.append("VENUE_RED: %s application must be idempotent" % id)
	if venue.get_node_or_null("ReferenceEnvironment") == null:
		failures.append("VENUE_RED: venue must own one reference environment")
	venue.apply_profile({"id":"unknown"})
	if venue.get_active_profile_id() != "cafe_window":
		failures.append("VENUE_RED: unknown venue ids should fall back to cafe_window")
	venue.free()

	var lighting_path := "res://scripts/presentation/reference_lighting.gd"
	if not ResourceLoader.exists(lighting_path):
		failures.append("VENUE_LIGHT_RED: missing ReferenceLighting")
	else:
		var lighting = load(lighting_path).new()
		if not lighting.has_method("lighting_contract_for_venue"):
			failures.append("VENUE_LIGHT_RED: lighting needs a pure per-venue contract so color-direction regressions are testable")
		else:
			var cold: Dictionary = lighting.call("lighting_contract_for_venue","market_coldcase")
			var can: Dictionary = lighting.call("lighting_contract_for_venue","market_can")
			var cold_key: Color = cold.get("key_color",Color.WHITE)
			var can_key: Color = can.get("key_color",Color.WHITE)
			var can_fill: Color = can.get("fill_color",Color.WHITE)
			var can_ambient: Color = can.get("ambient_color",Color.WHITE)
			if cold_key.b <= cold_key.r:
				failures.append("VENUE_LIGHT_RED: Yuzu supermarket should retain cool refrigerated key light")
			var key_span := maxf(can_key.r,maxf(can_key.g,can_key.b))-minf(can_key.r,minf(can_key.g,can_key.b))
			if minf(can_key.r,minf(can_key.g,can_key.b)) < 0.94 or key_span > 0.06:
				failures.append("VENUE_LIGHT_RED: aluminum key light must be near-neutral; warmth belongs in ambient/rim, not painted across the can")
			if can_fill.b > can_fill.r + 0.05:
				failures.append("VENUE_LIGHT_RED: Can fill may be slightly cool but must not repaint aluminum cyan")
			if can_ambient.b > can_ambient.r:
				failures.append("VENUE_LIGHT_RED: Can ambient must stay warm-neutral and distinct from supermarket coldcase")
		lighting.free()

	var backdrop_path := "res://scripts/presentation/reference_backdrop.gd"
	if not ResourceLoader.exists(backdrop_path):
		failures.append("VENUE_RED: reference backdrop presentation must exist")
	else:
		var backdrop = load(backdrop_path).new()
		var camera_position := Vector3(0.0,0.80,3.55)
		var camera_focus := Vector3(0.0,0.15,0.0)
		var backdrop_z := -1.43
		var forward := (camera_focus-camera_position).normalized()
		var ray_distance := (backdrop_z-camera_position.z)/forward.z
		var required_width := 2.0*ray_distance*tan(deg_to_rad(48.0*0.5))*(16.0/9.0)*1.04
		if backdrop.TARGET_WORLD_WIDTH < required_width:
			failures.append("VENUE_RED: reference backdrop must cover 48-degree camera with overscan")
		backdrop.free()
	return failures
