extends RefCounted

func run() -> Array[String]:
	var failures: Array[String] = []
	var required := "res://scripts/presentation/venue_presentation.gd"
	if not ResourceLoader.exists(required):
		failures.append("RED: missing contextual VenuePresentation")
		return failures

	var venue = load(required).new()
	var cafe := {
		"id": "cafe_window",
		"table_color": Color(0.24, 0.16, 0.11),
		"table_roughness": 0.82,
		"ambient_color": Color(0.18, 0.16, 0.14),
		"accent_color": Color(1.0, 0.72, 0.46),
		"light_energy": 1.1
	}
	var bar := cafe.duplicate(true)
	bar["id"] = "night_bar"
	bar["table_color"] = Color(0.08, 0.065, 0.055)
	var market := cafe.duplicate(true)
	market["id"] = "market_coldcase"
	market["table_color"] = Color(0.72, 0.73, 0.70)

	venue.apply_profile(cafe)
	if venue.get_active_profile_id() != "cafe_window":
		failures.append("cafe profile should activate cafe_window")
	if not _only_visible(venue, "CafeVenue"):
		failures.append("cafe profile should expose only CafeVenue")

	venue.apply_profile(bar)
	if venue.get_active_profile_id() != "night_bar":
		failures.append("bar profile should activate night_bar")
	if not _only_visible(venue, "BarVenue"):
		failures.append("bar profile should expose only BarVenue")

	venue.apply_profile(market)
	if venue.get_active_profile_id() != "market_coldcase":
		failures.append("market profile should activate market_coldcase")
	if not _only_visible(venue, "MarketVenue"):
		failures.append("market profile should expose only MarketVenue")

	venue.apply_profile({"id": "unknown-place"})
	if venue.get_active_profile_id() != "cafe_window":
		failures.append("unknown scene ids should fall back to cafe_window")
	if not _only_visible(venue, "CafeVenue"):
		failures.append("fallback should expose only CafeVenue")

	return failures

func _only_visible(venue: Node, expected_name: String) -> bool:
	for name in ["CafeVenue", "BarVenue", "MarketVenue"]:
		var root := venue.get_node_or_null(name) as Node3D
		if root == null:
			return false
		if root.visible != (name == expected_name):
			return false
	return true
