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
		var required_height := 2.0*ray_distance*tan(deg_to_rad(48.0*0.5))*1.04
		var camera_up := Vector3.RIGHT.cross(forward).normalized()
		var half_fov := deg_to_rad(48.0*0.5)
		var bottom_ray := (forward*cos(half_fov)-camera_up*sin(half_fov)).normalized()
		var top_ray := (forward*cos(half_fov)+camera_up*sin(half_fov)).normalized()
		var bottom_y := camera_position.y+bottom_ray.y*((backdrop_z-camera_position.z)/bottom_ray.z)
		var top_y := camera_position.y+top_ray.y*((backdrop_z-camera_position.z)/top_ray.z)
		for profile_id in backdrop.PROFILES:
			var profile: Dictionary = backdrop.PROFILES[profile_id]
			var world_width := float(profile.get("world_width",0.0))
			var offset: Vector2 = profile.get("offset",Vector2.ZERO)
			var horizontal_cover := world_width*0.5-absf(offset.x)
			var vertical_cover := (world_width/(16.0/9.0))*0.5-absf(offset.y)
			if horizontal_cover < required_width*0.5:
				failures.append("VENUE_RED: %s backdrop exposes a side wedge at the widest supported camera" % profile_id)
			if vertical_cover < required_height*0.5:
				failures.append("VENUE_RED: %s backdrop exposes a flat environment band above or below the plate" % profile_id)
			var profile_center_y: float = float(backdrop.BASE_POSITION.y)+offset.y
			var half_height: float = world_width/(16.0/9.0)*0.5
			if profile_center_y-half_height > bottom_y:
				failures.append("VENUE_RED: %s plate lower edge does not cover the tilted camera bottom ray" % profile_id)
			if profile_center_y+half_height < top_y:
				failures.append("VENUE_RED: %s plate upper edge does not cover the tilted camera top ray" % profile_id)
		backdrop.free()
	return failures
