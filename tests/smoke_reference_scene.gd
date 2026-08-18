extends SceneTree

const EXPECTED := [
	["cafe_window","paper_cup","CupPaperDetails"],
	["pantry_jar","sauce_jar","JarGlass"],
	["pantry_tin","tin_can","TinCanBody"],
	["market_coldcase","clear_bottle","BottleOuterGlass"],
	["market_can","soda_can","SodaCanBody"]
]

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load("res://scenes/peel_lab/peel_lab.tscn") as PackedScene
	if packed == null:
		_fail("reference scene did not load")
		return
	var scene := packed.instantiate()
	root.add_child(scene)
	for _i in range(6):
		await process_frame

	for path in ["Camera","Cup","Lid","PeelLabel","LabelPrint","PointerAdapter","PeelAudio","HUD","VenuePresentation","ProductPresentation","ResidueVisual","GuidedJourneyPresentation","ReferenceBackdrop"]:
		if scene.get_node_or_null(path) == null:
			_fail("missing integrated object-only node: %s" % path,scene)
			return
	for forbidden in ["LeftHand","RightHand","CinematicHandPresentation","HandChoreographyPresentation","ForearmPresentation","CrumpleHandStaging"]:
		if scene.get_node_or_null(forbidden) != null:
			_fail("obsolete hand-era node still exists: %s" % forbidden,scene)
			return

	var venue := scene.get_node("VenuePresentation") as VenuePresentation
	var product := scene.get_node("ProductPresentation") as ProductPresentation
	var guide := scene.get_node("GuidedJourneyPresentation") as GuidedJourneyPresentation
	var label := scene.get_node("PeelLabel") as LabelVisual
	var cup := scene.get_node("Cup") as MeshInstance3D
	var lid := scene.get_node("Lid") as MeshInstance3D
	var edge := scene.get_node("PeelEdge") as MeshInstance3D
	var rail := scene.get_node_or_null("HUD/JourneyRail") as Control
	if rail == null or not rail.visible:
		_fail("five-scene JourneyRail must be visible immediately",scene)
		return
	if edge.visible:
		_fail("legacy gold hotspot must remain hidden",scene)
		return
	var environment := venue.get_node_or_null("ReferenceEnvironment") as WorldEnvironment
	if environment == null or environment.environment == null:
		_fail("reference venue environment missing",scene)
		return

	for hud_path in ["HUD/ProgressPanel","HUD/ControlsPanel","HUD/HowToPanel","HUD/JourneyRail"]:
		if scene.get_node_or_null(hud_path) == null:
			_fail("approved HUD missing %s" % hud_path,scene)
			return
	var control_copy := _collect_text(scene.get_node("HUD/ControlsPanel"))
	for required in ["LMB","RMB","Wheel","R","1 2 3 4 5","Esc"]:
		if not control_copy.contains(required):
			_fail("approved HUD missing control affordance: %s" % required,scene)
			return
	var how_to_copy := _collect_text(scene.get_node("HUD/HowToPanel")).to_upper()
	for required in ["GRAB EDGE","PEEL GENTLY","INSPECT","CLEAN PEEL"]:
		if not how_to_copy.contains(required):
			_fail("approved HUD missing interaction step: %s" % required,scene)
			return

	for i in range(EXPECTED.size()):
		var button := scene.get_node_or_null("HUD/JourneyRail/Scene%d" % i) as Button
		if button == null:
			_fail("JourneyRail missing scene %d button" % (i+1),scene)
			return
		label.visible = false
		button.emit_signal("pressed")
		for _f in range(3):
			await process_frame
		var expected_scene := String(EXPECTED[i][0])
		var expected_kind := String(EXPECTED[i][1])
		var expected_node := String(EXPECTED[i][2])
		if venue.get_active_profile_id() != expected_scene:
			_fail("scene %d must activate venue %s" % [i+1,expected_scene],scene)
			return
		if product.get_active_kind() != expected_kind:
			_fail("scene %d must activate product %s" % [i+1,expected_kind],scene)
			return
		if guide.get_active_scene_index() != i:
			_fail("scene rail must highlight index %d" % i,scene)
			return
		if not label.visible:
			_fail("scene %d must restore a fresh attached label" % (i+1),scene)
			return
		if product.get_node_or_null(expected_node) == null:
			_fail("scene %d missing hero semantic node %s" % [i+1,expected_node],scene)
			return
		var paper := expected_kind == "paper_cup"
		if cup.visible != paper or lid.visible != paper:
			_fail("base interaction cup/lid visibility must only be owned by Coffee Shop",scene)
			return

	print("PASS: persistent five-scene object-only reference journey and HUD")
	scene.queue_free()
	await process_frame
	quit(0)

func _collect_text(node: Node) -> String:
	var output := ""
	if node is Label:
		output += (node as Label).text+"\n"
	if node is Button:
		output += (node as Button).text+"\n"
	for child in node.get_children():
		output += _collect_text(child)
	return output

func _fail(message: String, scene: Node = null) -> void:
	push_error(message)
	if scene != null:
		scene.queue_free()
	await process_frame
	quit(1)
