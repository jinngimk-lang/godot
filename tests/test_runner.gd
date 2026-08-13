extends SceneTree

func _init() -> void:
	var required := "res://scripts/peel/peel_model.gd"
	if not ResourceLoader.exists(required):
		push_error("RED: missing production peel contract: %s" % required)
		quit(1)
		return

	var failures: Array[String] = []
	for suite_path in [
		"res://tests/test_peel_model.gd",
		"res://tests/test_pointer_state.gd",
		"res://tests/test_pointer_adapter.gd",
		"res://tests/test_score_model.gd",
		"res://tests/test_peel_controller.gd",
		"res://tests/test_label_visual_geometry.gd",
		"res://tests/test_label_lifecycle.gd",
		"res://tests/test_label_visual_v2.gd",
		"res://tests/test_label_print_contract.gd",
		"res://tests/test_hand_visual.gd",
		"res://tests/test_authored_hand_asset.gd",
		"res://tests/test_peel_foley_router.gd",
		"res://tests/test_session_model.gd"
	]:
		if ResourceLoader.exists(suite_path):
			var suite = load(suite_path).new()
			failures.append_array(suite.run())

	if failures.is_empty():
		print("PASS: all deterministic tests")
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	quit(1)
