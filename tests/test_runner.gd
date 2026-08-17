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
		"res://tests/test_peel_entry_guidance.gd",
		"res://tests/test_tactile_peel_pacing.gd",
		"res://tests/test_label_visual_geometry.gd",
		"res://tests/test_label_lifecycle.gd",
		"res://tests/test_label_visual_v2.gd",
		"res://tests/test_cafe_receipt_readability.gd",
		"res://tests/test_peel_flap_arc.gd",
		"res://tests/test_label_backing_material.gd",
		"res://tests/test_label_print_contract.gd",
		"res://tests/test_hand_visual.gd",
		"res://tests/test_authored_hand_asset.gd",
		"res://tests/test_peel_foley_router.gd",
		"res://tests/test_peel_audio_mix.gd",
		"res://tests/test_session_model.gd",
		"res://tests/test_post_peel_progression.gd",
		"res://tests/test_ritual_flow.gd",
		"res://tests/test_cup_crumple_model.gd",
		"res://tests/test_crumple_hand_staging.gd",
		"res://tests/test_reference_profiles.gd",
		"res://tests/test_inspection_controller.gd",
		"res://tests/test_venue_presentation.gd",
		"res://tests/test_product_presentation.gd",
		"res://tests/test_cafe_hero_product.gd",
		"res://tests/test_cafe_sleeve_fabric.gd",
		"res://tests/test_residue_visual.gd",
		"res://tests/test_table_surface_material.gd",
		"res://tests/test_hud_chrome_presentation.gd",
		"res://tests/test_guided_journey_presentation.gd"
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
