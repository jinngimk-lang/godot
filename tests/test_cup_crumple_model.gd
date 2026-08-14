extends RefCounted

func run() -> Array[String]:
	var failures: Array[String] = []
	var required := "res://scripts/cup/cup_crumple_model.gd"
	if not ResourceLoader.exists(required):
		failures.append("RED: missing deterministic cup crumple model")
		return failures

	var model = load(required).new({"rigidity": 0.04, "dent_gain": 0.018, "max_compression": 0.22})
	if model.get_progress() != 0.0 or model.is_complete():
		failures.append("fresh crumple model should start uncompressed")

	var no_owner: Dictionary = model.apply_drag(30.0)
	if bool(no_owner.get("changed", true)) or model.get_progress() != 0.0:
		failures.append("drag without fresh crumple gesture must not create progress")

	model.begin_gesture(-100.0, 0.0)
	var left_outward: Dictionary = model.apply_drag(-25.0)
	if bool(left_outward.get("changed", true)) or model.get_progress() != 0.0:
		failures.append("left-side outward drag must not dent the cup")
	var left_inward: Dictionary = model.apply_drag(25.0)
	if not bool(left_inward.get("changed", false)) or float(left_inward.get("delta", 0.0)) <= 0.0:
		failures.append("left-side inward drag should add bounded crumple progress")
	var after_left: float = float(model.get_progress())
	if after_left <= 0.0:
		failures.append("real inward squeeze should persist crumple progress")
	var event_strength: float = float(model.consume_crumple_event())
	if event_strength <= 0.0 or event_strength > 1.0:
		failures.append("real inward squeeze should emit one bounded crumple event")
	if model.consume_crumple_event() != 0.0:
		failures.append("crumple event must be exact-once until new deformation")

	model.end_gesture()
	var after_end: Dictionary = model.apply_drag(80.0)
	if bool(after_end.get("changed", true)) or not is_equal_approx(float(model.get_progress()), after_left):
		failures.append("ended gesture must require a fresh begin before more deformation")

	model.begin_gesture(100.0, 0.0)
	var right_outward: Dictionary = model.apply_drag(20.0)
	if bool(right_outward.get("changed", true)):
		failures.append("right-side outward drag must not dent the cup")
	var right_inward: Dictionary = model.apply_drag(-25.0)
	if not bool(right_inward.get("changed", false)) or float(model.get_progress()) <= after_left:
		failures.append("right-side inward drag should add progress without erasing prior dents")
	var after_right: float = float(model.get_progress())
	model.apply_drag(0.0)
	model.apply_drag(NAN)
	model.apply_drag(INF)
	if not is_equal_approx(float(model.get_progress()), after_right):
		failures.append("stationary/non-finite input must not change crumple progress")

	# A physical gesture must not feel different merely because the OS/device
	# sampled the same movement as one coarse packet or many fine packets.
	var sampling_profile := {"rigidity": 0.055, "dent_gain": 0.0035, "max_compression": 0.18}
	var coarse = load(required).new(sampling_profile)
	var fine = load(required).new(sampling_profile)
	coarse.begin_gesture(-100.0, 0.0)
	fine.begin_gesture(-100.0, 0.0)
	coarse.apply_drag(20.0)
	for _i in range(20):
		fine.apply_drag(1.0)
	var coarse_progress := float(coarse.get_progress())
	var fine_progress := float(fine.get_progress())
	if coarse_progress <= 0.0:
		failures.append("sampling-invariance fixture must produce real coarse crumple progress")
	if absf(coarse_progress - fine_progress) > 0.0001:
		failures.append("RED: equal 20px inward gesture must be sampling-invariant; coarse=%.4f fine=%.4f" % [coarse_progress, fine_progress])

	# Rigidity also exists to absorb pointer jitter. Repeated subpixel motion that
	# returns to the exact gesture start has zero net inward depth and must never
	# accumulate enough positive half-cycles to synthesize a dent.
	var jitter = load(required).new(sampling_profile)
	jitter.begin_gesture(-100.0, 0.0)
	for _i in range(12):
		jitter.apply_drag(0.2)
		jitter.apply_drag(-0.2)
	if float(jitter.get_progress()) > 0.000001:
		failures.append("RED: zero-net subpixel jitter must remain inside rigidity deadzone; progress=%.6f" % jitter.get_progress())

	for _i in range(20):
		model.apply_drag(-100.0)
	if float(model.get_progress()) < 0.999 or float(model.get_progress()) > 1.0:
		failures.append("repeated squeeze should accumulate monotonically to bounded full progress")
	if not model.is_complete():
		failures.append("crumple should become complete after crossing its completion threshold")
	var compression: float = float(model.get_compression())
	if compression < 0.0 or compression > 0.2201:
		failures.append("cup compression must remain bounded by profile max_compression")

	model.reset()
	if model.get_progress() != 0.0 or model.get_compression() != 0.0 or model.is_complete() or model.consume_crumple_event() != 0.0:
		failures.append("reset should clear crumple progress, completion and pending events")

	return failures
