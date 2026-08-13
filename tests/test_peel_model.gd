extends RefCounted

func run() -> Array[String]:
	var failures: Array[String] = []
	var script = load("res://scripts/peel/peel_model.gd")
	if script == null:
		failures.append("PeelModel script did not load")
		return failures
	_test_below_threshold(script, failures)
	_test_above_threshold_and_monotonic(script, failures)
	_test_completion_once(script, failures)
	_test_extreme_input_stays_finite(script, failures)
	return failures

func _model(script):
	return script.new({"base_adhesion": 10.0, "release_increment": 0.12, "speed_gain": 0.04, "angle_gain": 0.25})

func _test_below_threshold(script, failures: Array[String]) -> void:
	var model = _model(script)
	var result: Dictionary = model.step(5.0, 0.0, 0.5, 0.016)
	if not is_equal_approx(result.progress, 0.0):
		failures.append("below-threshold tension advanced peel progress")

func _test_above_threshold_and_monotonic(script, failures: Array[String]) -> void:
	var model = _model(script)
	var first: Dictionary = model.step(20.0, 1.0, 1.0, 0.016)
	if first.progress <= 0.0:
		failures.append("above-threshold tension did not advance progress")
	var before: float = first.progress
	var second: Dictionary = model.step(0.0, 0.0, 0.0, 0.016)
	if second.progress < before:
		failures.append("peel progress regressed after release")
	if second.progress < 0.0 or second.progress > 1.0:
		failures.append("peel progress escaped [0,1]")

func _test_completion_once(script, failures: Array[String]) -> void:
	var model = _model(script)
	var completion_events := 0
	for _i in range(64):
		var result: Dictionary = model.step(100.0, 10.0, 1.2, 0.016)
		if result.completed_now:
			completion_events += 1
	if not is_equal_approx(model.get_progress(), 1.0):
		failures.append("high-tension sequence did not clamp progress at 1")
	if not model.is_complete():
		failures.append("model did not report complete at progress 1")
	if completion_events != 1:
		failures.append("completion event count expected 1, got %d" % completion_events)

func _test_extreme_input_stays_finite(script, failures: Array[String]) -> void:
	var model = _model(script)
	var result: Dictionary = model.step(1.0e30, 1.0e30, 1.0e30, 1.0e30)
	var p: float = result.progress
	if is_nan(p) or is_inf(p):
		failures.append("extreme input produced NaN/INF progress")
	if p < 0.0 or p > 1.0:
		failures.append("extreme input escaped [0,1]")
