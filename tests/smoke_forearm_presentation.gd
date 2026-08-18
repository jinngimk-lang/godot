extends SceneTree

const MAX_IDLE_PEEL_EDGE_GAP := 0.10
const MIN_CINEMATIC_FOREARM_SPAN := 0.55
const MAX_CINEMATIC_FOREARM_SPAN := 1.35
const MIN_REALTIME_DETAIL_BUDGET := 20000

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load("res://scenes/peel_lab/peel_lab.tscn") as PackedScene
	if packed == null:
		_fail("peel lab scene failed to load")
		return
	var scene := packed.instantiate()
	root.add_child(scene)
	for _frame in range(8):
		await process_frame

	var cinematic := scene.get_node_or_null("CinematicHandPresentation") as Node
	if cinematic == null:
		_fail("missing CinematicHandPresentation runtime layer",scene)
		return
	if int(cinematic.call("get_ready_hand_count")) != 2:
		_fail("cinematic presentation must bind both hands",scene)
		return
	if not cinematic.has_method("get_visible_realtime_shell_count"):
		_fail("cinematic presentation missing realtime-shell authority contract",scene)
		return
	if int(cinematic.call("get_visible_realtime_shell_count")) != 2:
		_fail("both smooth realtime hand shells must be visible",scene)
		return
	if int(cinematic.call("get_visible_authored_hand_mesh_count")) != 0:
		_fail("faceted authored XR meshes must be hidden from the viewport",scene)
		return
	if int(cinematic.call("get_visible_primitive_shell_mesh_count")) != 0:
		_fail("retired bead/capsule CinematicShell must stay hidden",scene)
		return

	for hand_name in ["RightHand","LeftHand"]:
		var hand := scene.get_node_or_null(hand_name) as HandVisual
		if hand == null:
			_fail("missing %s" % hand_name,scene)
			return
		if not hand.is_using_realtime_shell():
			_fail("%s is not using the smooth realtime hand shell" % hand_name,scene)
			return
		if hand.get_realtime_shell_vertex_count() < MIN_REALTIME_DETAIL_BUDGET:
			_fail("%s realtime hand detail budget is too low: %d" % [hand_name,hand.get_realtime_shell_vertex_count()],scene)
			return
		var realtime_shell := hand.get_node_or_null("RealtimeHandShell") as Node3D
		if realtime_shell == null or not realtime_shell.visible:
			_fail("%s realtime presentation shell must be visible" % hand_name,scene)
			return
		var authored := hand.get_node_or_null("AuthoredHand") as Node3D
		if authored == null:
			_fail("%s must retain hidden authored skeleton as pose authority" % hand_name,scene)
			return
		if _count_visible_meshes(authored) != 0:
			_fail("%s authored low-poly render mesh leaked into viewport" % hand_name,scene)
			return
		var cinematic_forearm := hand.get_node_or_null("CinematicForearm") as MeshInstance3D
		if cinematic_forearm == null or not cinematic_forearm.visible:
			_fail("%s must use the short cinematic forearm" % hand_name,scene)
			return
		var span := float(cinematic.call("get_cinematic_forearm_span",hand_name))
		if span < MIN_CINEMATIC_FOREARM_SPAN or span > MAX_CINEMATIC_FOREARM_SPAN:
			_fail("%s cinematic forearm span %.3f outside reference bounds" % [hand_name,span],scene)
			return
		var legacy_forearm := hand.get_node_or_null("ForearmNatural") as MeshInstance3D
		if legacy_forearm == null or legacy_forearm.visible:
			_fail("%s legacy tube forearm must stay hidden" % hand_name,scene)
			return
		var legacy_sleeve := hand.get_node_or_null("AuthoredHand/WristSleeve") as MeshInstance3D
		if legacy_sleeve == null or legacy_sleeve.visible:
			_fail("%s duplicate authored wrist sleeve must stay hidden" % hand_name,scene)
			return
		var legacy_cuff := hand.get_node_or_null("AuthoredHand/WristCuff") as MeshInstance3D
		if legacy_cuff != null and legacy_cuff.visible:
			_fail("%s duplicate authored wrist cuff must stay hidden" % hand_name,scene)
			return

	# The idle peel hand must still be grounded on the actual label edge, so the
	# visual rebuild cannot silently sever the gameplay contact contract.
	scene.call("debug_select_variant",1)
	await process_frame
	await process_frame
	var choreography := scene.get_node_or_null("HandChoreographyPresentation") as Node
	if choreography == null:
		_fail("missing HandChoreographyPresentation",scene)
		return
	for _step in range(12):
		choreography.call("_process",0.1)
	var right := scene.get_node("RightHand") as HandVisual
	var label := scene.get_node("PeelLabel") as LabelVisual
	var edge_world := label.to_global(label.get_front_position(0.0))
	var idle_gap := right.get_pinch_world_position().distance_to(edge_world)
	if idle_gap > MAX_IDLE_PEEL_EDGE_GAP:
		_fail("idle peel pinch must stay at real label edge, gap %.3f > %.3f" % [idle_gap,MAX_IDLE_PEEL_EDGE_GAP],scene)
		return

	var left := scene.get_node("LeftHand") as HandVisual
	var cup := scene.get_node("Cup") as MeshInstance3D
	var before_support := left.position
	cup.rotation.y = 0.55
	choreography.call("_process",0.1)
	if left.position.distance_to(before_support) < 0.025:
		_fail("glass support hand must follow inspected vessel yaw",scene)
		return

	# Bar and market have bare forearms in the supplied concepts; Café keeps a
	# dark sleeve. Verify scene changes preserve that material split.
	for hand_name in ["RightHand","LeftHand"]:
		var bar_forearm := scene.get_node("%s/CinematicForearm" % hand_name) as MeshInstance3D
		if bar_forearm.material_override == null or bar_forearm.material_override.resource_name != "CinematicHandSkin":
			_fail("bar %s cinematic forearm must be natural skin" % hand_name,scene)
			return
	scene.call("debug_select_variant",2)
	await process_frame
	await process_frame
	for hand_name in ["RightHand","LeftHand"]:
		var market_forearm := scene.get_node("%s/CinematicForearm" % hand_name) as MeshInstance3D
		if market_forearm.material_override == null or market_forearm.material_override.resource_name != "CinematicHandSkin":
			_fail("market %s cinematic forearm must stay natural skin" % hand_name,scene)
			return

	print("PASS: smooth realtime hands own the viewport, hidden XR assets keep pose authority, short forearms and contact anchors stay coherent")
	scene.queue_free()
	await process_frame
	quit(0)

func _count_visible_meshes(node: Node) -> int:
	if node == null:
		return 0
	var count := 0
	if node is MeshInstance3D and (node as MeshInstance3D).visible:
		count += 1
	for child in node.get_children():
		count += _count_visible_meshes(child)
	return count

func _fail(message: String, scene: Node = null) -> void:
	push_error("FOREARM_RED: %s" % message)
	if scene != null:
		scene.queue_free()
	await process_frame
	quit(1)
