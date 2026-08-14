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
	_test_damped_bond_load(script, failures)
	_test_pull_quality(script, failures)
	return failures

func _model(script):
	return script.new({"base_adhesion": 10.0, "release_increment": 0.12, "speed_gain": 0.04, "angle_gain": 0.25, "bond_response": 7.0, "bond_relaxation": 4.0, "safe_pull_speed": 5.0, "tear_pull_speed": 12.0, "residue_gain": 0.12})

func _test_below_threshold(script, failures: Array[String]) -> void:
	var model = _model(script)
	var result: Dictionary = model.step(5.0, 0.0, 0.5, 0.016)
	if not is_equal_approx(result.progress, 0.0):
		failures.append("below-threshold tension advanced peel progress")

func _test_above_threshold_and_monotonic(script, failures: Array[String]) -> void:
	var model = _model(script)
	var first: Dictionary = {}
	for _i in range(12):
		first = model.step(20.0, 1.0, 1.0, 0.016)
	if first.progress <= 0.0:
		failures.append("sustained above-threshold tension did not advance progress")
	var before: float = first.progress
	var second: Dictionary = model.step(0.0, 0.0, 0.0, 0.016)
	if second.progress < before:
		failures.append("peel progress regressed after release")
	if second.progress < 0.0 or second.progress > 1.0:
		failures.append("peel progress escaped [0,1]")

func _test_completion_once(script, failures: Array[String]) -> void:
	var model = _model(script)
	var completion_events := 0
	for _i in range(96):
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
	for key in ["progress", "integrity", "residue", "bond_load"]:
		var value := float(result.get(key, NAN))
		if is_nan(value) or is_inf(value):
			failures.append("extreme input produced NaN/INF %s" % key)

func _test_damped_bond_load(script, failures: Array[String]) -> void:
	var model = _model(script)
	var spike: Dictionary = model.step(22.0, 1.0, 0.8, 0.004)
	if float(spike.get("progress", 1.0)) > 0.0:
		failures.append("RED: a brief force spike should not instantly release adhesive")
	if float(spike.get("bond_load", 0.0)) <= 0.0:
		failures.append("RED: force should build a visible internal bond load")
	var before_relax := float(spike.get("bond_load", 0.0))
	var relaxed: Dictionary = model.step(0.0, 0.0, 0.0, 0.05)
	if float(relaxed.get("bond_load", before_relax)) >= before_relax:
		failures.append("RED: bond load should relax when the player eases off")

func _test_pull_quality(script, failures: Array[String]) -> void:
	var gentle = _model(script)
	var rough = _model(script)
	for _i in range(36):
		gentle.step(18.0, 3.0, 0.9, 0.016)
		rough.step(42.0, 24.0, 0.9, 0.016)
	var gentle_integrity := float(gentle.get_integrity())
	var rough_integrity := float(rough.get_integrity())
	var gentle_residue := float(gentle.get_residue())
	var rough_residue := float(rough.get_residue())
	if rough_integrity >= gentle_integrity:
		failures.append("RED: excessive pull speed/force should reduce label integrity")
	if rough_residue <= gentle_residue:
		failures.append("RED: excessive pull speed/force should leave more residue")
	gentle.reset()
	if gentle.get_integrity() != 1.0 or gentle.get_residue() != 0.0 or gentle.get_bond_load() != 0.0:
		failures.append("RED: reset must restore integrity/residue/bond load")
