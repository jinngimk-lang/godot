extends SceneTree

const EXPECTED_IDS := ["coffee_shop","sauce_jar","tin_can","yuzu_bottle","lemon_can"]
const EXPECTED_KINDS := ["paper_cup","sauce_jar","tin_can","clear_bottle","soda_can"]
const EXPECTED_VENUES := ["cafe_window","pantry_jar","pantry_tin","market_coldcase","market_can"]

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load("res://scenes/peel_lab/peel_lab.tscn") as PackedScene
	if packed == null:
		_fail("peel lab scene failed to load")
		return
	var scene := packed.instantiate()
	root.add_child(scene)
	for _i in range(5): await process_frame

	var label := scene.get_node_or_null("PeelLabel") as LabelVisual
	var hud := scene.get_node_or_null("HUD/Instructions") as Label
	var cup := scene.get_node_or_null("Cup") as MeshInstance3D
	var lid := scene.get_node_or_null("Lid") as MeshInstance3D
	var venue := scene.get_node_or_null("VenuePresentation") as VenuePresentation
	var product := scene.get_node_or_null("ProductPresentation") as ProductPresentation
	var residue := scene.get_node_or_null("ResidueVisual") as ResidueVisual
	var session = scene.get("_session")
	if label == null or hud == null or cup == null or lid == null or venue == null or product == null or residue == null or session == null:
		_fail("object-only runtime contract missing",scene)
		return

	var controls: Dictionary = scene.call("get_control_contract")
	var expected_controls := {"peel":"LMB","rotate":"RMB","zoom":"Wheel","reset":"R","scenes":"1/2/3/4/5","pause":"Esc"}
	for key in expected_controls.keys():
		if String(controls.get(key,"")) != String(expected_controls[key]):
			_fail("control %s must map to %s" % [key,expected_controls[key]],scene)
			return

	for i in range(5):
		scene.call("debug_select_variant",i)
		for _f in range(3): await process_frame
		var variant: Dictionary = session.current_variant()
		if String(variant.get("id","")) != EXPECTED_IDS[i]:
			_fail("scene %d selected wrong variant" % (i+1),scene); return
		if venue.get_active_profile_id() != EXPECTED_VENUES[i] or product.get_active_kind() != EXPECTED_KINDS[i]:
			_fail("scene %d venue/product bundle mismatch" % (i+1),scene); return
		if not label.visible:
			_fail("scene %d reset must restore the attached label" % (i+1),scene); return
		var paper := i == 0
		if cup.visible != paper or lid.visible != paper:
			_fail("only Coffee Shop may expose the base paper cup/lid" ,scene); return
		var controller = scene.get("_controller")
		if controller == null or String(controller.get_state_name()) != "IDLE" or float(controller.get_progress()) != 0.0:
			_fail("scene %d must enter with a fresh IDLE peel controller" % (i+1),scene); return
		if absf(label.rotation.y)>0.001 or absf(residue.rotation.y)>0.001:
			_fail("scene selection must clear inspection yaw",scene); return

	# Detach accounting is exact-once and scene-independent.
	scene.call("debug_select_variant",1)
	await process_frame
	var before_clean := int(session.get_clean_peels())
	scene.call("_handle_detached_label")
	scene.call("_handle_detached_label")
	if int(session.get_clean_peels()) != before_clean+1:
		_fail("duplicate detach must record exactly one completed label",scene); return

	# Esc visibly pauses/resumes without changing the chosen scene.
	var escape := InputEventKey.new(); escape.pressed = true; escape.keycode = KEY_ESCAPE
	scene.call("_unhandled_key_input",escape)
	if not bool(scene.get("_paused")) or not hud.text.contains("PAUSED"):
		_fail("Esc must enter visible pause",scene); return
	scene.call("_unhandled_key_input",escape)
	if bool(scene.get("_paused")):
		_fail("second Esc must resume",scene); return

	# R resets the current label and tactile state but preserves completion history.
	var reset_key := InputEventKey.new(); reset_key.pressed = true; reset_key.keycode = KEY_R
	scene.call("_unhandled_key_input",reset_key)
	var reset_controller = scene.get("_controller")
	if String(reset_controller.get_state_name()) != "IDLE" or float(reset_controller.get_progress()) != 0.0:
		_fail("R must reset current peel controller",scene); return
	if int(session.get_clean_peels()) != before_clean+1 or session.get_variant_index() != 1:
		_fail("R must not erase progression or switch scenes",scene); return
	if not label.visible:
		_fail("R must restore attached label visibility",scene); return

	print("PASS: five object bundles + exact-once detach + Esc pause + R reset")
	scene.queue_free()
	await process_frame
	quit(0)

func _fail(message: String, scene: Node = null) -> void:
	push_error("RESET_SMOKE: %s" % message)
	if scene != null: scene.queue_free()
	await process_frame
	quit(1)
