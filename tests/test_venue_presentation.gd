extends RefCounted

func run() -> Array[String]:
	var failures: Array[String] = []
	var path := "res://scripts/presentation/venue_presentation.gd"
	if not ResourceLoader.exists(path):
		failures.append("RED: missing contextual VenuePresentation")
		return failures
	var venue = load(path).new()
	var profiles := [
		{"id":"cafe_window","table_color":Color(0.24,0.16,0.11),"table_roughness":0.72,"ambient_color":Color(0.18,0.16,0.14),"accent_color":Color(1.0,0.72,0.46),"light_energy":1.1},
		{"id":"night_bar","table_color":Color(0.07,0.045,0.03),"table_roughness":0.48,"ambient_color":Color(0.04,0.025,0.02),"accent_color":Color(1.0,0.38,0.08),"light_energy":1.28},
		{"id":"market_coldcase","table_color":Color(0.72,0.73,0.70),"table_roughness":0.54,"ambient_color":Color(0.62,0.68,0.72),"accent_color":Color(0.70,0.90,1.0),"light_energy":0.95}
	]
	var expected := ["CafeWindows","BarBackShelf","MarketCooler"]
	for i in range(profiles.size()):
		venue.apply_profile(profiles[i])
		if venue.get_active_profile_id() != String(profiles[i].id): failures.append("venue should activate %s" % String(profiles[i].id))
		if venue.get_node_or_null(expected[i]) == null: failures.append("%s must expose landmark %s" % [String(profiles[i].id),expected[i]])
		var count_before: int = venue.get_child_count()
		venue.apply_profile(profiles[i])
		if venue.get_child_count() != count_before: failures.append("venue profile application must be idempotent")
	venue.apply_profile({"id":"unknown"})
	if venue.get_active_profile_id() != "cafe_window": failures.append("unknown venue ids should fall back to cafe_window")
	venue.free()

	# Reference backdrop must cover the widest live reference camera, not only the
	# original 39-degree cafe framing.  At 48 degrees the current camera reaches
	# farther laterally at the backdrop plane; include 4% overscan so raster edge
	# rounding cannot reveal world-clear black wedges in bottle scenes.
	var backdrop_path := "res://scripts/presentation/reference_backdrop.gd"
	if not ResourceLoader.exists(backdrop_path):
		failures.append("reference backdrop presentation must exist")
	else:
		var backdrop = load(backdrop_path).new()
		var camera_position := Vector3(0.0,0.80,3.55)
		var camera_focus := Vector3(0.0,0.15,0.0)
		var backdrop_z := -1.43
		var forward := (camera_focus-camera_position).normalized()
		var ray_distance := (backdrop_z-camera_position.z)/forward.z
		var aspect := 16.0/9.0
		var half_horizontal_tan := tan(deg_to_rad(48.0*0.5))*aspect
		var required_width := 2.0*ray_distance*half_horizontal_tan*1.04
		if backdrop.TARGET_WORLD_WIDTH < required_width:
			failures.append("bottle reference backdrop must cover 48-degree camera with overscan (%.3f < %.3f)" % [backdrop.TARGET_WORLD_WIDTH,required_width])
		backdrop.free()
	return failures
