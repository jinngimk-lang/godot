extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load("res://scenes/peel_lab/peel_lab.tscn") as PackedScene
	if packed == null:
		_fail("peel lab scene failed to load")
		return
	var scene := packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	var right_hand := scene.get_node_or_null("RightHand") as Node3D
	var label := scene.get_node_or_null("PeelLabel") as LabelVisual
	var hud := scene.get_node_or_null("HUD/Instructions") as Label
	var cup := scene.get_node_or_null("Cup") as MeshInstance3D
	var lid := scene.get_node_or_null("Lid") as MeshInstance3D
	var contents: Node = scene.get_node_or_null("CupContentsPresentation")
	var venue: Node = scene.get_node_or_null("VenuePresentation")
	var product: Node = scene.get_node_or_null("ProductPresentation")
	var residue: Node3D = scene.get_node_or_null("ResidueVisual") as Node3D
	var session = scene.get("_session")
	var ritual = scene.get("_ritual")
	var crumple = scene.get("_crumple")
	if right_hand == null or label == null or hud == null or cup == null or lid == null or contents == null or venue == null or product == null or residue == null or session == null or ritual == null or crumple == null:
		_fail("runtime mixed-container contract missing",scene)
		return
	if scene.get("_contents_presentation") != contents:
		_fail("runtime must keep the production CupContentsPresentation reference",scene)
		return

	# Fresh café state: paper cup, closed lid, no ice, touch-safe onboarding.
	if String(session.current_variant().get("id","")) != "warm_paper":
		_fail("fresh run must start at warm_paper",scene)
		return
	if venue.call("get_active_profile_id") != "cafe_window" or product.call("get_active_kind") != "paper_cup":
		_fail("fresh run must present the window café paper cup",scene)
		return
	if int(contents.call("get_content_count")) != 0 or not lid.visible:
		_fail("fresh café paper cup must be closed and ice-free",scene)
		return
	var onboarding := hud.text.to_lower()
	if not onboarding.contains("mouse") or not onboarding.contains("touch") or onboarding.contains("hold left mouse"):
		_fail("onboarding must make mouse and touch equally valid",scene)
		return

	# Reset must re-seat the interaction hand on the fresh label without changing progression.
	if not right_hand.has_method("get_pinch_world_position") or not right_hand.has_method("snap_to"):
		_fail("RightHand missing pinch/reset contract",scene)
		return
	var expected_grip_world := label.to_global(label.get_front_position(0.0))
	var displaced := right_hand.position+Vector3(0.82,0.31,0.47)
	right_hand.call("snap_to",displaced)
	scene.call("_reset_session")
	var pinch_world := right_hand.call("get_pinch_world_position") as Vector3
	if pinch_world.distance_to(expected_grip_world) > 0.035:
		_fail("reset must return pinch to fresh label surface",scene)
		return
	await process_frame

	# Paper ritual preserves V5 exact-once and no-timer settle behavior.
	scene.call("_handle_detached_label")
	scene.call("_handle_detached_label")
	if session.get_clean_peels() != 1 or session.get_total_score() != 0:
		_fail("duplicate paper detach must record exactly one score-independent ritual",scene)
		return
	if ritual.get_phase_name() != "PEEL_SETTLE":
		_fail("paper detach must enter PEEL_SETTLE",scene)
		return
	var escape := InputEventKey.new()
	escape.pressed = true
	escape.keycode = KEY_ESCAPE
	scene.call("_unhandled_key_input",escape)
	if not bool(scene.get("_paused")) or not hud.text.contains("PAUSED"):
		_fail("Esc must enter visible pause state",scene)
		return
	scene.call("_process",1.0)
	if ritual.get_phase_name() != "PEEL_SETTLE":
		_fail("pause must freeze paper post-peel settle",scene)
		return
	scene.call("_unhandled_key_input",escape)
	if bool(scene.get("_paused")):
		_fail("second Esc must resume play",scene)
		return

	var reset_key := InputEventKey.new()
	reset_key.pressed = true
	reset_key.keycode = KEY_R
	scene.call("_unhandled_key_input",reset_key)
	if ritual.get_phase_name() != "PEEL" or crumple.get_progress() != 0.0 or session.get_clean_peels() != 1:
		_fail("paper next/reset must clear tactile transients without erasing progression",scene)
		return

	# Direct scene navigation is a comfort/showcase affordance and must switch the
	# complete vessel + venue bundle, not only recolor the same paper cup.
	scene.call("debug_select_variant",1)
	await process_frame
	if String(session.current_variant().get("id","")) != "silky_long":
		_fail("showcase 2 must select silky_long",scene)
		return
	if venue.call("get_active_profile_id") != "night_bar" or product.call("get_active_kind") != "amber_bottle":
		_fail("showcase 2 must be an amber bottle in the bar",scene)
		return
	if bool(scene.call("_uses_crumple")) or lid.visible or int(contents.call("get_content_count")) != 0:
		_fail("amber glass bottle must inspect rather than crumple and must not inherit ice/lid",scene)
		return

	# Glass completion remains score-independent but never enters the paper crush ritual.
	var before_glass := int(session.get_clean_peels())
	scene.call("_handle_detached_label")
	scene.call("_handle_detached_label")
	if session.get_clean_peels() != before_glass+1:
		_fail("amber bottle detach must still record exactly one completed ritual",scene)
		return
	if ritual.get_phase_name() != "PEEL":
		_fail("glass bottle must not enter paper PEEL_SETTLE/CRUMPLE flow",scene)
		return

	# Market vessel preserves V6 deterministic contents while adopting clear glass.
	scene.call("debug_select_variant",2)
	await process_frame
	if venue.call("get_active_profile_id") != "market_coldcase" or product.call("get_active_kind") != "clear_bottle":
		_fail("showcase 3 must be the clear citrus bottle in the market cooler",scene)
		return
	if bool(scene.call("_uses_crumple")) or lid.visible:
		_fail("market glass bottle must remain inspect-only with no paper lid",scene)
		return
	if int(contents.call("get_content_count")) != 3:
		_fail("market bottle must preserve exactly three deterministic V6 ice cubes",scene)
		return
	if product.get_node_or_null("BottleLiquid") == null:
		_fail("market clear bottle must keep the visible liquid core",scene)
		return
	var cup_mesh := cup.mesh as CylinderMesh
	if cup_mesh == null or cup_mesh.cap_top:
		_fail("iced market vessel must expose the contents opening",scene)
		return

	# Inspection yaw must keep vessel, label, residue and ice in one coherent assembly.
	scene.call("_apply_inspection_yaw",0.42)
	if absf(cup.rotation.y-0.42) > 0.001 or absf(label.rotation.y-0.42) > 0.001 or absf(residue.rotation.y-0.42) > 0.001 or absf((contents as Node3D).rotation.y-0.42) > 0.001:
		_fail("inspection yaw must rotate cup/label/residue/contents coherently",scene)
		return

	# Full restart restores the quiet café baseline and removes every market transient.
	var restart := InputEventKey.new()
	restart.pressed = true
	restart.keycode = KEY_R
	restart.shift_pressed = true
	scene.call("_unhandled_key_input",restart)
	await process_frame
	if session.get_clean_peels() != 0 or session.get_total_score() != 0 or session.get_unlocked_count() != 1:
		_fail("Shift+R must restart progression cleanly",scene)
		return
	if String(session.current_variant().get("id","")) != "warm_paper" or venue.call("get_active_profile_id") != "cafe_window" or product.call("get_active_kind") != "paper_cup":
		_fail("full restart must restore the café paper-cup bundle",scene)
		return
	if int(contents.call("get_content_count")) != 0 or not lid.visible:
		_fail("full restart must remove ice and restore the paper lid",scene)
		return
	if absf(cup.rotation.y) > 0.001 or absf(label.rotation.y) > 0.001 or absf(residue.rotation.y) > 0.001 or absf((contents as Node3D).rotation.y) > 0.001:
		_fail("full restart must clear inspection rotation",scene)
		return
	if ritual.get_phase_name() != "PEEL" or crumple.get_progress() != 0.0:
		_fail("full restart must clear ritual/crumple state",scene)
		return
	if float(scene.get("_reset_timer")) >= 0.0 or bool(scene.get("_advance_after_reset")):
		_fail("restart must leave no stale automatic next transition",scene)
		return
	scene.call("_process",3.0)
	if String(session.current_variant().get("id","")) != "warm_paper" or session.get_clean_peels() != 0 or ritual.get_phase_name() != "PEEL":
		_fail("idle time after restart must not resurrect stale state",scene)
		return

	print("PASS: café paper ritual -> amber inspect -> iced market inspect -> quiet full restart")
	scene.queue_free()
	await process_frame
	quit(0)

func _fail(message: String, scene: Node = null) -> void:
	push_error("RESET_SMOKE: %s" % message)
	if scene != null:
		scene.queue_free()
	await process_frame
	quit(1)
