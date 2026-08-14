extends RefCounted

func run() -> Array[String]:
	var failures: Array[String] = []
	var path := "res://scripts/presentation/venue_presentation.gd"
	if not ResourceLoader.exists(path):
		failures.append("RED: missing contextual VenuePresentation")
		return failures
	var venue = load(path).new()
	var profiles := [
		{"id":"cafe_window", "table_color":Color(0.24,0.16,0.11), "table_roughness":0.72, "ambient_color":Color(0.18,0.16,0.14), "accent_color":Color(1.0,0.72,0.46), "light_energy":1.1},
		{"id":"night_bar", "table_color":Color(0.07,0.045,0.03), "table_roughness":0.48, "ambient_color":Color(0.04,0.025,0.02), "accent_color":Color(1.0,0.38,0.08), "light_energy":1.28},
		{"id":"market_coldcase", "table_color":Color(0.72,0.73,0.70), "table_roughness":0.54, "ambient_color":Color(0.62,0.68,0.72), "accent_color":Color(0.70,0.90,1.0), "light_energy":0.95}
	]
	var expected := ["CafeWindows", "BarBackShelf", "MarketCooler"]
	for i in range(profiles.size()):
		venue.apply_profile(profiles[i])
		if venue.get_active_profile_id() != String(profiles[i].id):
			failures.append("venue should activate %s" % String(profiles[i].id))
		if venue.get_node_or_null(expected[i]) == null:
			failures.append("%s must expose landmark %s" % [String(profiles[i].id), expected[i]])
		var count_before := venue.get_child_count()
		venue.apply_profile(profiles[i])
		if venue.get_child_count() != count_before:
			failures.append("venue profile application must be idempotent")
	venue.apply_profile({"id":"unknown"})
	if venue.get_active_profile_id() != "cafe_window":
		failures.append("unknown venue ids should fall back to cafe_window")
	return failures
