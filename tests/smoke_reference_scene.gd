extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed: PackedScene = load("res://scenes/peel_lab/peel_lab.tscn") as PackedScene
	if packed == null:
		_fail("reference scene did not load")
		return
	var scene: Node = packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	for path: String in ["Camera","Cup","Lid","PeelLabel","LabelPrint","LeftHand","RightHand","PointerAdapter","PeelAudio","HUD","VenuePresentation","ProductPresentation","ResidueVisual","CupContentsPresentation","CupCrumplePresentation"]:
		if scene.get_node_or_null(path) == null:
			_fail("missing integrated node: %s" % path,scene)
			return

	var venue: Node = scene.get_node("VenuePresentation")
	var product: Node = scene.get_node("ProductPresentation")
	var contents: Node = scene.get_node("CupContentsPresentation")
	var crumple: Node = scene.get_node("CupCrumplePresentation")
	var label := scene.get_node("PeelLabel") as LabelVisual
	var cup := scene.get_node("Cup") as MeshInstance3D
	var hud: Label = scene.get_node("HUD/Instructions") as Label
	var edge: MeshInstance3D = scene.get_node("PeelEdge") as MeshInstance3D

	if venue.call("get_active_profile_id") != "cafe_window":
		_fail("initial scene should be cafe_window",scene)
		return
	if product.call("get_active_kind") != "paper_cup":
		_fail("initial product should be paper_cup",scene)
		return
	if not cup.visible or not label.visible:
		_fail("fresh café must show both paper cup and attached label",scene)
		return
	if not bool(crumple.call("is_enabled_for_profile")):
		_fail("paper café must own the optional crumple presentation",scene)
		return
	if int(contents.call("get_content_count")) != 0:
		_fail("initial cafe cup should not contain ice",scene)
		return
	if venue.get_node_or_null("CafeWindows") == null:
		_fail("cafe landmark root missing",scene)
		return
	var environment: WorldEnvironment = venue.get_node_or_null("ReferenceEnvironment") as WorldEnvironment
	if environment == null or environment.environment == null:
		_fail("reference venue environment missing",scene)
		return
	if edge == null or edge.visible:
		_fail("legacy gold hotspot must remain hidden",scene)
		return
	var hud_text := hud.text.to_lower() if hud != null else ""
	if hud == null or not hud_text.contains("mouse") or not hud_text.contains("touch") or not hud_text.contains("rmb inspect") or not hud_text.contains("q/e scene"):
		_fail("reference HUD is missing touch-safe peel/inspect/navigation affordances",scene)
		return

	# Reproduce the visual-capture failure mode: a completed presentation stage
	# may temporarily hide the label. Fresh item selection must always restore it.
	label.visible = false
	scene.call("debug_select_variant",1)
	await process_frame
	if venue.call("get_active_profile_id") != "night_bar" or product.call("get_active_kind") != "amber_bottle":
		_fail("variant 2 must switch to amber bottle bar",scene)
		return
	if not label.visible:
		_fail("fresh amber bottle must restore attached label visibility",scene)
		return
	if cup.visible:
		_fail("amber bottle must keep the simple interaction cylinder hidden",scene)
		return
	if bool(crumple.call("is_enabled_for_profile")):
		_fail("amber glass bottle must not let paper crumple presentation own visibility",scene)
		return
	var crumpled := crumple.get_node_or_null("CrumpledCup") as MeshInstance3D
	if crumpled != null and crumpled.visible:
		_fail("amber glass bottle must not show paper crumple shell",scene)
		return
	var outer_glass := product.get_node_or_null("BottleOuterGlass") as MeshInstance3D
	if outer_glass == null or not outer_glass.visible:
		_fail("amber bottle must render the continuous glass shell",scene)
		return
	if venue.get_node_or_null("BarBackShelf") == null or not (venue.get_node("BarBackShelf") as Node3D).visible:
		_fail("bar landmark should be visible after direct navigation",scene)
		return
	var lid: MeshInstance3D = scene.get_node("Lid") as MeshInstance3D
	if lid == null or lid.visible:
		_fail("glass bottle should not keep paper-cup lid visible",scene)
		return
	if int(contents.call("get_content_count")) != 0:
		_fail("amber bar bottle should not inherit market ice",scene)
		return

	label.visible = false
	scene.call("debug_select_variant",2)
	await process_frame
	if venue.call("get_active_profile_id") != "market_coldcase" or product.call("get_active_kind") != "clear_bottle":
		_fail("variant 3 must switch to clear market bottle",scene)
		return
	if not label.visible:
		_fail("fresh market bottle must restore attached label visibility",scene)
		return
	if cup.visible or bool(crumple.call("is_enabled_for_profile")):
		_fail("clear market bottle must keep paper interaction/crumple rendering hidden",scene)
		return
	outer_glass = product.get_node_or_null("BottleOuterGlass") as MeshInstance3D
	if outer_glass == null or not outer_glass.visible:
		_fail("market bottle must render the continuous clear glass shell",scene)
		return
	if venue.get_node_or_null("MarketCooler") == null or not (venue.get_node("MarketCooler") as Node3D).visible:
		_fail("market landmark should be visible after direct navigation",scene)
		return
	if product.get_node_or_null("BottleLiquid") == null:
		_fail("clear market bottle should expose visible liquid core",scene)
		return
	if int(contents.call("get_content_count")) != 3:
		_fail("market bottle must preserve the V6 three-ice contents contract",scene)
		return

	label.visible = false
	scene.call("debug_select_variant",0)
	await process_frame
	if venue.call("get_active_profile_id") != "cafe_window" or product.call("get_active_kind") != "paper_cup":
		_fail("navigation back to cafe should restore paper cup",scene)
		return
	if not label.visible or not cup.visible or not bool(crumple.call("is_enabled_for_profile")):
		_fail("navigation back to café must restore paper cup/label/crumple ownership",scene)
		return
	if int(contents.call("get_content_count")) != 0:
		_fail("navigation back to cafe must clear market ice",scene)
		return

	print("PASS: reference café/bar/market visibility ownership + V6 contents smoke")
	scene.queue_free()
	await process_frame
	quit(0)

func _fail(message: String, scene: Node = null) -> void:
	push_error(message)
	if scene != null:
		scene.queue_free()
	await process_frame
	quit(1)
