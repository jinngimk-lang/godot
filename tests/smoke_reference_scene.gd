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

	for path: String in ["Camera","Cup","Lid","PeelLabel","LabelPrint","LeftHand","RightHand","PointerAdapter","PeelAudio","HUD","VenuePresentation","ProductPresentation","ResidueVisual"]:
		if scene.get_node_or_null(path) == null:
			_fail("missing integrated node: %s" % path,scene)
			return

	var venue: Node = scene.get_node("VenuePresentation")
	var product: Node = scene.get_node("ProductPresentation")
	var hud: Label = scene.get_node("HUD/Instructions") as Label
	var edge: MeshInstance3D = scene.get_node("PeelEdge") as MeshInstance3D
	if venue.call("get_active_profile_id") != "cafe_window":
		_fail("initial scene should be cafe_window",scene)
		return
	if product.call("get_active_kind") != "paper_cup":
		_fail("initial product should be paper_cup",scene)
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
	if hud == null or not hud.text.contains("LMB Peel anywhere") or not hud.text.contains("RMB Inspect") or not hud.text.contains("Q/E Scene"):
		_fail("reference HUD is missing peel/inspect/navigation affordances",scene)
		return

	scene.call("debug_select_variant",1)
	await process_frame
	if venue.call("get_active_profile_id") != "night_bar" or product.call("get_active_kind") != "amber_bottle":
		_fail("variant 2 must switch to amber bottle bar",scene)
		return
	if venue.get_node_or_null("BarBackShelf") == null or not (venue.get_node("BarBackShelf") as Node3D).visible:
		_fail("bar landmark should be visible after direct navigation",scene)
		return
	var lid: MeshInstance3D = scene.get_node("Lid") as MeshInstance3D
	if lid == null or lid.visible:
		_fail("glass bottle should not keep paper-cup lid visible",scene)
		return

	scene.call("debug_select_variant",2)
	await process_frame
	if venue.call("get_active_profile_id") != "market_coldcase" or product.call("get_active_kind") != "clear_bottle":
		_fail("variant 3 must switch to clear market bottle",scene)
		return
	if venue.get_node_or_null("MarketCooler") == null or not (venue.get_node("MarketCooler") as Node3D).visible:
		_fail("market landmark should be visible after direct navigation",scene)
		return
	if product.get_node_or_null("BottleLiquid") == null:
		_fail("clear market bottle should expose visible liquid core",scene)
		return

	scene.call("debug_select_variant",0)
	await process_frame
	if venue.call("get_active_profile_id") != "cafe_window" or product.call("get_active_kind") != "paper_cup":
		_fail("navigation back to cafe should restore paper cup",scene)
		return

	print("PASS: reference café/bar/market vertical slice smoke")
	scene.queue_free()
	await process_frame
	quit(0)

func _fail(message: String, scene: Node = null) -> void:
	push_error(message)
	if scene != null:
		scene.queue_free()
	await process_frame
	quit(1)
