extends SceneTree

func _init() -> void:
	var required := "res://scripts/peel/peel_model.gd"
	if not ResourceLoader.exists(required):
		push_error("RED: missing production peel contract: %s" % required)
		quit(1)
		return

	var failures: Array[String] = []
	var peel_suite = load("res://tests/test_peel_model.gd").new()
	failures.append_array(peel_suite.run())

	if failures.is_empty():
		print("PASS: deterministic peel contract")
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	quit(1)
