extends RefCounted

func run() -> Array[String]:
	var failures: Array[String] = []
	var path := "res://scripts/peel/residue_scrub_model.gd"
	if not ResourceLoader.exists(path):
		failures.append("SCRUB_RED: missing post-peel residue scrub model")
		return failures
	var scrub = load(path).new({
		"required_travel":240.0,
		"reversal_bonus":0.45,
		"grid_columns":12,
		"grid_rows":6,
		"brush_radius":0.18
	})
	var region := Rect2(400,220,280,230)

	if not scrub.has_method("get_cleanup_field") or not scrub.has_method("get_cleanup_grid_size") or not scrub.has_method("get_local_cleanliness") or not scrub.has_method("get_coverage_progress"):
		failures.append("SPATIAL_SCRUB_RED: residue scrub must expose a deterministic local cleanup field")
		return failures

	# Hovering, holding still, or dragging elsewhere must never clean adhesive.
	scrub.update(false,Vector2(500,300),Vector2(48,0),region,1.0/60.0)
	scrub.update(true,Vector2(500,300),Vector2.ZERO,region,1.0/60.0)
	scrub.update(true,Vector2(760,300),Vector2(48,0),region,1.0/60.0)
	if scrub.get_progress() > 0.0001 or scrub.get_coverage_progress() > 0.0001:
		failures.append("SCRUB_RED: cleanup needs pressed movement inside the visible residue region")

	# Rubbing one local patch must clean that patch before untouched space. It
	# must not globally erase the whole label footprint from one repeated motion.
	var left_position := Vector2(region.position.x+region.size.x*0.22,region.get_center().y)
	for i in range(28):
		var relative := Vector2(16 if i % 2 == 0 else -16,2 if i % 4 < 2 else -2)
		left_position += relative
		left_position.x = clampf(left_position.x,region.position.x+18.0,region.position.x+region.size.x*0.38)
		scrub.update(true,left_position,relative,region,1.0/60.0)
	var left_clean: float = float(scrub.get_local_cleanliness(Vector2(region.position.x+region.size.x*0.23,region.get_center().y),region))
	var right_clean: float = float(scrub.get_local_cleanliness(Vector2(region.position.x+region.size.x*0.82,region.get_center().y),region))
	if left_clean < 0.35:
		failures.append("SPATIAL_SCRUB_RED: rubbed region must become locally clean; got %.3f" % left_clean)
	if right_clean > 0.12:
		failures.append("SPATIAL_SCRUB_RED: untouched region must stay dirty while another patch is rubbed; got %.3f" % right_clean)
	if scrub.is_complete():
		failures.append("SPATIAL_SCRUB_RED: repeatedly rubbing one small patch must not complete the entire residue pass")
	if scrub.get_coverage_progress() >= 0.72:
		failures.append("SPATIAL_SCRUB_RED: one local patch must not report broad footprint coverage")

	# A deliberate raster-like sweep across the footprint should clean all cells.
	# Each cell gets short reversal strokes so this remains rubbing, not one fling.
	var grid_size: Vector2i = scrub.get_cleanup_grid_size()
	if grid_size.x < 8 or grid_size.y < 4:
		failures.append("SPATIAL_SCRUB_RED: cleanup field needs enough cells for visibly local clearing")
	for row in range(grid_size.y):
		for column in range(grid_size.x):
			var cell_center := Vector2(
				region.position.x+region.size.x*(float(column)+0.5)/float(grid_size.x),
				region.position.y+region.size.y*(float(row)+0.5)/float(grid_size.y)
			)
			for stroke in range(4):
				var relative := Vector2(12 if stroke % 2 == 0 else -12,2 if stroke < 2 else -2)
				scrub.update(true,cell_center+relative*0.25,relative,region,1.0/60.0)
	if not scrub.is_complete() or scrub.get_progress() < 0.999 or scrub.get_coverage_progress() < 0.92:
		failures.append("SPATIAL_SCRUB_RED: broad back-and-forth coverage must reach clean")
	if not scrub.consume_completed_event():
		failures.append("SCRUB_RED: completion must emit one clean-result event")
	if scrub.consume_completed_event():
		failures.append("SCRUB_RED: clean-result event must be exactly once")

	var field: PackedFloat32Array = scrub.get_cleanup_field()
	if field.size() != grid_size.x*grid_size.y:
		failures.append("SPATIAL_SCRUB_RED: exported cleanup field size must match its grid dimensions")

	scrub.reset()
	if scrub.get_progress() != 0.0 or scrub.get_coverage_progress() != 0.0 or scrub.is_complete():
		failures.append("SCRUB_RED: reset must restore an untouched residue pass")
	return failures
